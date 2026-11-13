#!/usr/bin/env python3
"""Verify actual embedded PC609 ship assets in sources or unsigned IPA.

Never treat presence of Swift loader code as proof that the asset was shipped.
Hangar H55 remains separately imported at user request.
"""
import argparse, hashlib, zipfile
from pathlib import Path

SHIPS = {
    "KESTREL_PC609.kestrel": (2617283, "5d3598b655f362f284550261c4cbfe14775d1568885f1ce22b2baaa1c2c288a2"),
    "BASTION_PC609.bastion": (2472062, "d18d651aab74bebdb2215940c0774c8aa3f0aff9101c0b7122c336110b3f5e7c"),
}
BOREAS = {
    "Boreas556.as3d": (2243704, "0a18d88a734906811fc6421d79d68a56a2ae4bd7dd7a622fc89c46a4cd5fbf9b"),
    "Boreas556.asmo": (2274488, "33c7bec0a53fe8a63e0c351658155ee74fc364cddef8ec261af15d6675a103a6"),
    "Boreas556.asnt": (21218, "bdf22733cfe6a1314517537e2400019a97c3a83507b8f654fd1307dbf9809edc"),
    "BoreasMorphBinding556.json": (406, "f5f099707a1e63582934dc2bd26155e739225db26f3d358fd4a100fff9e50593"),
}

def check_bytes(name, data, expected):
    size, digest = expected
    actual = hashlib.sha256(data).hexdigest()
    assert len(data) == size and actual == digest, (
        f"{name}: size/SHA256 mismatch. Expected {size} {digest}; got {len(data)} {actual}")
    print(f"PASS {name}: {size} bytes SHA256 {actual}")

def verify_assets(root, required):
    for name, expected in required.items():
        p = root / name
        assert p.is_file(), f"Missing required repo asset: {p}"
        check_bytes(name, p.read_bytes(), expected)

def verify_ipa(path, required):
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None, "Bad IPA ZIP CRC"
        for name, expected in required.items():
            matched = [n for n in z.namelist()
                       if n.startswith("Payload/") and ".app/" in n and n.endswith("/" + name)]
            assert len(matched) == 1, f"{name}: expected exactly one embedded IPA asset, got {matched}"
            check_bytes(name, z.read(matched[0]), expected)
        print("PASS all required models are embedded in IPA and byte-identical to PC609")

def main():
    p = argparse.ArgumentParser()
    mode = p.add_mutually_exclusive_group(required=True)
    mode.add_argument("--assets", type=Path)
    mode.add_argument("--ipa", type=Path)
    p.add_argument("--boreas", action="store_true")
    a = p.parse_args()
    required = dict(SHIPS)
    if a.boreas:
        required.update(BOREAS)
    if a.assets:
        verify_assets(a.assets, required)
    else:
        verify_ipa(a.ipa, required)

if __name__ == "__main__":
    main()
