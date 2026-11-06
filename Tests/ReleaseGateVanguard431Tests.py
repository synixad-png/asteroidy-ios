#!/usr/bin/env python3
"""Offline adversarial tests of the real-vs-fallback release boundary.

The two verified original PC asset binaries are now in GitHub as
ASTEROIDYiOS/Assets/Vanguard431Source.mesh and Vanguard431Base.jpg.
This test proves missing/substituted assets are blocked; positive byte
validation is handled by OriginalVanguard431InstalledAssetsTests.py.
The user's full PC source ZIP is not stored in this repository.
"""
import importlib.util
import pathlib
import sys
import tempfile
import zipfile

root=pathlib.Path(__file__).resolve().parents[1]
script=root/"Tools/verify_original_vanguard_resources.py"
spec=importlib.util.spec_from_file_location("vanguard_source_gate",script)
assert spec is not None and spec.loader is not None
gate=importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)

def rejects(callback,word):
    try:
        callback()
    except (ValueError,FileNotFoundError):
        return
    raise AssertionError("Release gate accepted invalid "+word)

for name,(size,sha) in gate.EXPECTED.items():
    assert len(sha)==64
    assert int(sha,16)>0
    assert size>1000000

rejects(lambda:gate.inspect_assets({}),"missing originals")
rejects(lambda:gate.inspect_assets({
    "Vanguard431Source.mesh":b"fake mesh",
    "Vanguard431Base.jpg":b"fake image",
}),"fake source")
rejects(lambda:gate.jpeg_dimensions(b"not a JPEG"),"invalid jpeg")
rejects(lambda:gate.jpeg_dimensions(b"\xff\xd8\xff\xd9"),
        "jpeg with no dimensions")

with tempfile.TemporaryDirectory() as tmp:
    path=pathlib.Path(tmp)/"not-fully-textured.ipa"
    with zipfile.ZipFile(path,"w") as z:
        z.writestr("Payload/ASTEROIDY iOS.app/Info.plist",b"plist")
        z.writestr("Payload/ASTEROIDY iOS.app/Vanguard431Base.jpg",
                   b"not original")
    rejects(lambda:gate.read_app_ipa(path),
            "IPA missing original mesh (fallback-only IPA)")

manual=(root/".github/workflows/build-ios-iphone-ipad-manual.yml").read_text()
ipa=(root/"Tools/verify_ipa.py").read_text()
assert "default: false" in manual, "original asset gate bypass must not be default"
assert "python3 Tools/verify_original_vanguard_resources.py --assets ASTEROIDYiOS/Assets" in manual
assert "--require-vanguard-original" in manual
assert "--require-vanguard-original" in ipa
assert "compatibility_old_ship" in manual
assert "TARGETED_DEVICE_FAMILY=1,2" in manual
assert "workflow_dispatch:" in manual and "  push:" not in manual
print("PASS: original Vanguard source material is mandatory for textured")
print("      releases; old AS3D fallback requires explicit compatibility")
print("      switch. Missing/malformed/renamed JPEG/mesh IPA rejected.")
print("POSITIVE: exact original source binaries are in GitHub;")
print("          separate source and native compiled-app tests verify them")
