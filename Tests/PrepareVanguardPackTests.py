#!/usr/bin/env python3
"""Protect the original-compressed-source to real Xcode Assets handoff.

No fabricated or damaged source archive may become app resources.
This test runs without access to the user's large private binary ZIP.
"""
import pathlib
import sys
import tempfile
import zipfile

root=pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/"Tools"))
import prepare_vanguard431_assets as importer

with tempfile.TemporaryDirectory() as folder:
    temp=pathlib.Path(folder)
    assets=temp/"Assets"
    absent=temp/"missing.zip"
    assert importer.install(absent,assets) is False
    assert not assets.exists()

    invalid=temp/"invalid.zip"
    with zipfile.ZipFile(invalid,"w") as z:
        z.writestr("wrong-name.mesh",b"not-original")
    try:
        importer.install(invalid,assets)
    except ValueError as error:
        assert "exact member" in str(error)
    else:
        raise AssertionError("Accepted source ZIP missing original mesh")
    assert not assets.exists()

    counterfeit=temp/"counterfeit.zip"
    with zipfile.ZipFile(counterfeit,"w",
                         compression=zipfile.ZIP_DEFLATED) as z:
        z.writestr(
            "ASTEROIDYiOS/Assets/Vanguard431Source.mesh",
            b"X"*9721408)
        z.writestr(
            "ASTEROIDYiOS/Assets/Vanguard431Base.jpg",
            b"J"*1275318)
    try:
        importer.install(counterfeit,assets)
    except ValueError as error:
        assert "SHA256" in str(error)
    else:
        raise AssertionError("Accepted substituted Vanguard mesh and JPEG")
    assert not assets.exists(), "Should not write either resource before verification"

# The user now uploaded BOTH exact source binaries to the repository,
# so the real default path MUST succeed without a redundant ZIP.
with tempfile.TemporaryDirectory() as folder:
    fake_archive=pathlib.Path(folder)/"absent.zip"
    direct_originals=root/"ASTEROIDYiOS"/"Assets"
    assert importer.install(fake_archive,direct_originals) is True
    partial=pathlib.Path(folder)/"partial"
    partial.mkdir()
    (partial/"Vanguard431Source.mesh").write_bytes(
        (direct_originals/"Vanguard431Source.mesh").read_bytes())
    try:
        importer.install(fake_archive,partial)
    except ValueError as error:
        assert "Incomplete direct Vanguard431 upload" in str(error)
    else:
        raise AssertionError("Accepted incomplete direct Vanguard431 upload")
    assert not (partial/"Vanguard431Base.jpg").exists()

manual=(root/".github/workflows/build-ios-iphone-ipad-manual.yml").read_text()
assert "Tools/prepare_vanguard431_assets.py" in manual
assert "Tools/verify_original_vanguard_resources.py --assets ASTEROIDYiOS/Assets" in manual
assert manual.index("Tools/prepare_vanguard431_assets.py") < manual.index(
    "Tools/verify_original_vanguard_resources.py --assets ASTEROIDYiOS/Assets")
assert "--require-vanguard-original" in manual

print("PASS: compact original asset bundle importer fails closed on")
print("      absent members, corrupted bytes and substituted materials;")
print("      direct original assets load without the optional ZIP; partial uploads fail")
print("      future manual iPhone+iPad IPA verifies original sources in bundle")
