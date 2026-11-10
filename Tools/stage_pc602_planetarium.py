#!/usr/bin/env python3
"""Stage EXACT ASTEROIDY PC v602 HUD planetarium GLB for native iOS packaging.

The byte-for-byte approved asset is checked into GitHub in lossless XZ form.
No external downloads, procedural substitutes, or silent fallback assets.
"""
import argparse
import hashlib
import json
import lzma
import os
from pathlib import Path
import struct
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "SourceResources/PC602/planetarium.glb.xz"
TARGET = ROOT / "ASTEROIDYiOS/Assets/planetarium.glb"
SIZE = 3_228_900
SHA256 = "71ca9ff24e044a831a5c7197e343594dd1fd801284af6231870570b35ad43860"
CLIP = "HUD_PLANETARIUM_PREMIUM_48S_LOOP"


def verified_bytes() -> bytes:
    if not SOURCE.is_file():
        raise RuntimeError(f"Original PC v602 planetarium missing: {SOURCE}")
    with lzma.open(SOURCE, "rb") as stream:
        data = stream.read(SIZE + 1)
        if stream.read(1):
            raise RuntimeError("Unexpected trailing uncompressed bytes")
    if len(data) != SIZE:
        raise RuntimeError(f"PC v602 planetarium wrong size: {len(data)}")
    actual = hashlib.sha256(data).hexdigest()
    if actual != SHA256:
        raise RuntimeError(f"PC v602 planetarium SHA256 mismatch: {actual}")
    if len(data) < 28:
        raise RuntimeError("GLB header is incomplete")
    magic, version, total, length, json_magic = struct.unpack_from("<5I", data)
    if (magic, version, total, json_magic) != (0x46546C67, 2, SIZE, 0x4E4F534A):
        raise RuntimeError("The approved source is not the original glTF 2.0 GLB")
    if length <= 0 or length > SIZE - 28:
        raise RuntimeError("Invalid GLB JSON length")
    doc = json.loads(data[20:20 + length].decode("utf-8"))
    nodes = doc.get("nodes", [])
    animations = doc.get("animations", [])
    if len(nodes) != 141 or len(animations) != 1:
        raise RuntimeError("Wrong original glTF node or clip count")
    if (animations[0].get("name") != CLIP or
            len(animations[0].get("channels", [])) != 159):
        raise RuntimeError("Original 159-channel planetarium clip missing")
    names = [node.get("name", "") for node in nodes]
    for i in range(3):
        if sum(name.startswith(f"CAPSULE_{i}_WATER_BUBBLE_") for name in names) != 24:
            raise RuntimeError(f"PC v602 capsule {i} bubble tracks missing")
    required = {"SPHERE_OUTER_DOTTED_SKIN", "DAMAGE_HULL_FLASH_SOCKET",
                "DAMAGE_ARMOR_FLASH_SOCKET", "DAMAGE_SHIELD_FLASH_SOCKET"}
    if not required.issubset(set(names)):
        raise RuntimeError("PC v602 planetarium named nodes missing")
    return data


def stage(data: bytes) -> None:
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    if TARGET.exists() and TARGET.read_bytes() == data:
        print(f"PASS already staged: {TARGET.relative_to(ROOT)}")
        return
    fd, temp = tempfile.mkstemp(prefix="planetarium_pc602_", suffix=".glb",
                                dir=str(TARGET.parent))
    try:
        with os.fdopen(fd, "wb") as output:
            output.write(data)
        os.replace(temp, TARGET)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)
    if hashlib.sha256(TARGET.read_bytes()).hexdigest() != SHA256:
        raise RuntimeError("Unpacked destination does not match PC v602 SHA256")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--verify-only", action="store_true")
    args = ap.parse_args()
    data = verified_bytes()
    if not args.verify_only:
        stage(data)
    print(f"PASS original PC v602 planetarium GLB: {len(data)} bytes; SHA256 {SHA256}; 141 nodes; 159 channels")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, ValueError, lzma.LZMAError) as error:
        print(f"FAIL PC602 planetarium staging: {error}", file=sys.stderr)
        sys.exit(1)
