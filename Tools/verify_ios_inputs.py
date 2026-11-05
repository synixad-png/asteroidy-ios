#!/usr/bin/env python3
"""Fail-fast audit of original v556 iOS port resources and Xcode inputs.

Only the four immutable binary/JSON resources are verified against the
historical SOURCES_SHA256SUMS.txt. DO NOT compare current Swift source checksums:
the source code is intentionally evolving, and the old manifest is a v18
baseline rather than a current all-file lock.
"""
from __future__ import annotations
import hashlib
import json
import math
import pathlib
import re
import struct
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ASSETS = (
    "ASTEROIDYiOS/Assets/Vanguard556.as3d",
    "ASTEROIDYiOS/Assets/Boreas556.as3d",
    "ASTEROIDYiOS/Assets/Boreas556.asmo",
    "ASTEROIDYiOS/Assets/BoreasMorphBinding556.json",
)


def digest(path: pathlib.Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def historical_asset_hashes() -> dict[str, str]:
    result: dict[str, str] = {}
    text = (ROOT / "SOURCES_SHA256SUMS.txt").read_text(encoding="utf-8")
    for line in text.splitlines():
        m = re.fullmatch(r"([0-9a-f]{64})\s+(.+)", line.strip())
        if not m:
            continue
        path = m.group(2)
        if path in ASSETS:
            if path in result:
                raise ValueError("Repeated asset in historical SHA256 manifest: " + path)
            result[path] = m.group(1)
    if set(result) != set(ASSETS):
        raise ValueError("Historical v556 asset hash manifest incomplete")
    return result


def as3d(path: pathlib.Path) -> tuple[int, int, int]:
    with path.open("rb") as stream:
        header = stream.read(16)
    if len(header) != 16:
        raise ValueError("Short AS3D: " + str(path))
    magic, version, verts, indices = struct.unpack("<4sIII", header)
    if magic != b"AS3D" or version not in (1, 2, 3):
        raise ValueError("Bad AS3D format: " + str(path))
    if not (0 < verts <= 2_000_000 and 0 < indices <= 6_000_000 and indices % 3 == 0):
        raise ValueError("Bad AS3D mesh count: " + str(path))
    size = 16 + verts * (48 if version >= 2 else 32) + indices * 4
    if path.stat().st_size != size:
        raise ValueError("AS3D byte length mismatch: " + str(path))
    return version, verts, indices


def asmo(path: pathlib.Path) -> tuple[int, int, int]:
    with path.open("rb") as stream:
        header = stream.read(20)
    if len(header) != 20:
        raise ValueError("Short ASMO: " + str(path))
    magic, version, vertices, targets, keys = struct.unpack("<4sIIII", header)
    if magic != b"ASMO" or version != 1:
        raise ValueError("Bad ASMO format: " + str(path))
    if not (0 < vertices <= 2_000_000 and 0 < targets <= 16 and 2 <= keys <= 65536):
        raise ValueError("Bad ASMO metadata: " + str(path))
    expected = 20 + 4 * (vertices * 3 * (1 + targets) + keys * (1 + targets))
    if path.stat().st_size != expected:
        raise ValueError("ASMO byte length mismatch: " + str(path))
    return vertices, targets, keys


def main() -> int:
    hashes = historical_asset_hashes()
    for rel in ASSETS:
        path = ROOT / rel
        if not path.is_file():
            raise FileNotFoundError("Required original v556 asset missing: " + rel)
        actual = digest(path)
        if actual != hashes[rel]:
            raise ValueError("Original v556 asset changed without provenance audit: " + rel)
        print("PASS SHA256", rel, actual)

    _, boreas_vertices, _ = as3d(ROOT / ASSETS[1])
    as3d(ROOT / ASSETS[0])
    morph_vertices, targets, keys = asmo(ROOT / ASSETS[2])
    binding = json.loads((ROOT / ASSETS[3]).read_text(encoding="utf-8"))
    if binding.get("format") != "BoreasMorphBinding556.v1":
        raise ValueError("Boreas source morph-binding version changed")
    if (binding.get("staticVertexCount") != boreas_vertices
            or binding.get("vertexCount") != morph_vertices
            or binding.get("firstVertex", -1) + morph_vertices != boreas_vertices
            or not isinstance(binding.get("radius"), (int, float))
            or not math.isfinite(binding["radius"])
            or binding["radius"] <= 0):
        raise ValueError("Boreas source mesh/animation/binding mismatch")
    project = (ROOT / "project.yml").read_text(encoding="utf-8")
    for term in ("IPHONEOS_DEPLOYMENT_TARGET: '17.0'", "platform: iOS",
                 "ASTEROIDYiOS/Assets", "TARGETED_DEVICE_FAMILY: '1,2'"):
        if term not in project:
            raise ValueError("XcodeGen project setting missing: " + term)
    source = (ROOT / "ASTEROIDYiOS" / "Ship.metal").read_text(encoding="utf-8")
    if "sceneVertex" not in source or "sceneFragment" not in source:
        raise ValueError("Metal entrypoints missing")
    print(f"PASS: original v556 assets, {boreas_vertices} Boreas vertices, "
          f"{morph_vertices} morph vertices, {targets} targets, "
          f"{keys} animation keys, XcodeGen iPhone/iPad and Metal sources")
    print("Note: this does not replace native Xcode compilation or an IPA device test.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, FileNotFoundError, OSError) as exc:
        print("FAIL: " + str(exc), file=sys.stderr)
        raise SystemExit(1)
