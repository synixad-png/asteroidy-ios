#!/usr/bin/env python3
"""Source-bound W3 JPEG/PNG staging regression; no fabricated graphics."""
from pathlib import Path
import importlib.util
import tempfile
import zipfile
import json
import hashlib
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location(
    "original_w3_images",ROOT/"Tools/prepare_v568_w3_original_assets.py")
stage=importlib.util.module_from_spec(spec)
spec.loader.exec_module(stage)
assert set(stage.FILES)=={"W3Background568.jpg","W3Logo568.png"}
assert stage.FILES["W3Background568.jpg"]==(
    806519,"a8aa28883084657f0c38900dbb011de09e2b0fd461704d370a68858be0178145")
assert stage.FILES["W3Logo568.png"]==(
    50257,"cab4198b953640c787975c5a8436a0fdeaa82502b40e000077ff055cc0709e09")
menu=(ROOT/"ASTEROIDYiOS/W3MainMenu568.swift").read_text()
assert 'SourceW3Images568.pair' in menu
assert "SHA256.hash(data:bytes)" in menu
assert "Image(uiImage:images.background)" in menu
assert "Image(uiImage:image)" in menu
assert 'verified("W3Background568Original","dat",' in menu
assert 'verified("W3Logo568Original","dat",' in menu
assert "UIImage(data:bytes)" in menu
assert '"hasOriginalW3BackgroundImage": SourceW3Images568.pair != nil' in menu
assert '"hasOriginalW3LogoImage": SourceW3Images568.pair != nil' in menu
with tempfile.TemporaryDirectory() as temp:
    root=Path(temp)
    dest=root/"Assets"
    assert stage.prepare(root,dest,required=False) is False
    assert not dest.exists()
    try:
        stage.prepare(root,dest,required=True)
    except ValueError:pass
    else:raise AssertionError("Required original assets falsely accepted")
    with zipfile.ZipFile(root/stage.ARCHIVE,"w") as z:
        for name,(size,digest) in stage.FILES.items():
            z.writestr(name,b"WRONG_SOURCE_IMAGE")
        z.writestr("MANIFEST_SHA256.json",json.dumps({}))
        z.writestr("CZYTAJ.txt","test")
    try:
        stage.prepare(root,dest,required=True)
    except ValueError:pass
    else:raise AssertionError("Unverified image accepted")
    assert not dest.exists()
# This CI checkout may not yet include the original user-uploaded archive.
if (ROOT/stage.ARCHIVE).is_file():
    with tempfile.TemporaryDirectory() as tmp:
        dest=Path(tmp)/"Assets"
        assert stage.prepare(ROOT,dest,required=True)
        with zipfile.ZipFile(ROOT/stage.ARCHIVE) as original:
            for name,stored in (
                ("W3Background568.jpg","W3Background568Original.dat"),
                ("W3Logo568.png","W3Logo568Original.dat")):
                assert (dest/stored).read_bytes()==original.read(name)
                assert hashlib.sha256((dest/stored).read_bytes()).hexdigest()==stage.FILES[name][1]
        assert not (dest/"W3Logo568.png").exists()
        assert not (dest/"W3Background568.jpg").exists()
print("PASS: missing W3 sources remain explicitly incomplete, forged sources rejected")
print("PASS: native menu reads only shared source SHA256-verified W3 JPEG/PNG")
