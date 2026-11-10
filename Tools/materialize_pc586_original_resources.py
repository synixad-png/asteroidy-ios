#!/usr/bin/env python3
"""Verify GitHub-tracked PC586 originals and embed them in an unsigned iOS app.

No Drive, ChatGPT, network, Git LFS or local external scene is needed.
Three large H55 GLBs are stored in ordered immutable Git blobs and rebuilt
byte-for-byte using the single checked-in manifest. The huge hangar_h55.glb
is deliberately excluded and must still be imported via Files on-device.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import plistlib
import tempfile
from pathlib import Path


PICKUPS = ("shield", "boost", "energy", "bomb")
H55 = ("gloves_parted.glb", "gloves_combined.glb", "EXP01_SOURCE_v601.glb")
REQUIRED = frozenset(name + "." + ext for name in PICKUPS for ext in ("glb", "mesh", "jpg")) | frozenset(H55)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_originals(source: Path) -> dict[str, bytes]:
    manifest = json.loads((source / "manifest.json").read_text(encoding="utf-8"))
    if manifest.get("version") != "PC586-ORIGINAL-15":
        raise ValueError("Unknown original-resource manifest version")
    if manifest.get("excluded") != ["hangar_h55.glb"]:
        raise ValueError("hangar_h55.glb MUST be explicitly excluded")
    rows = manifest.get("files", [])
    if len(rows) != 15 or {x.get("name") for x in rows} != REQUIRED:
        raise ValueError("Expected exactly seven original GLB, four Metal meshes and four JPEG")
    if len({x["name"] for x in rows}) != 15:
        raise ValueError("Duplicate original-resource names")
    parts = manifest.get("large_models_parts", [])
    if len(parts) != 14 or {x.get("model") for x in parts} != set(H55):
        raise ValueError("Expected exactly the original 14 H55 chunk records")
    expected_files = REQUIRED - set(H55)
    if {p.name for p in (source / "originals").iterdir() if p.is_file()} != expected_files:
        raise ValueError("Missing or unexpected small source resource")
    expected_parts = {p["part"] for p in parts}
    if len(expected_parts) != 14 or {p.name for p in (source / "chunks").iterdir() if p.is_file()} != expected_parts:
        raise ValueError("Missing, duplicated or unexpected large-model chunk")
    if any(p.name == "hangar_h55.glb" for p in source.rglob("*")):
        raise ValueError("The external hangar_h55.glb may not be tracked here")

    assets: dict[str, bytes] = {}
    for row in rows:
        name = row["name"]
        if name in H55:
            model_parts = [p for p in parts if p["model"] == name]
            expected_order = [f"{name}.part{i:02d}" for i in range(len(model_parts))]
            if [p["part"] for p in model_parts] != expected_order:
                raise ValueError(f"Nonconsecutive/out-of-order model parts: {name}")
            result = bytearray()
            for part in model_parts:
                segment = (source / "chunks" / part["part"]).read_bytes()
                if len(segment) != part["bytes"] or sha256(segment) != part["sha256"]:
                    raise ValueError(f"GitHub model chunk corrupted: {part['part']}")
                result.extend(segment)
            original = bytes(result)
        else:
            original = (source / "originals" / name).read_bytes()
        if len(original) != row["bytes"] or sha256(original) != row["sha256"]:
            raise ValueError(f"GitHub original asset differs from source: {name}")
        if name.endswith(".glb") and original[:4] != b"glTF":
            raise ValueError(f"Wrong GLB header: {name}")
        if name.endswith(".jpg") and original[:2] != b"\xff\xd8":
            raise ValueError(f"Wrong JPEG header: {name}")
        assets[name] = original
    return assets


def embed(app: Path, originals: dict[str, bytes]) -> str:
    info_file = app / "Info.plist"
    if not info_file.is_file():
        raise FileNotFoundError(f"Built iOS .app missing Info.plist: {app}")
    info = plistlib.loads(info_file.read_bytes())
    if info.get("CFBundleIdentifier") != "com.synixad.asteroidyios":
        raise ValueError("Unexpected app Bundle ID")
    if (app / "_CodeSignature").exists():
        raise ValueError("Refusing to alter a signed app")
    binary = app / info["CFBundleExecutable"]
    if not binary.is_file():
        raise FileNotFoundError("Compiled ARM64 iOS executable missing")
    binary_sha = sha256(binary.read_bytes())
    if (app / "hangar_h55.glb").exists():
        raise ValueError("Do not bundle the excluded 126MB hangar")
    for name, data in originals.items():
        target = app / name
        if target.exists():
            if sha256(target.read_bytes()) != sha256(data):
                raise ValueError(f"App already contains a different version of {name}")
            continue
        descriptor, tmpname = tempfile.mkstemp(prefix=".asset-", dir=app)
        try:
            with os.fdopen(descriptor, "wb") as handle:
                handle.write(data)
            os.replace(tmpname, target)
        finally:
            if os.path.exists(tmpname):
                os.unlink(tmpname)
    for name, data in originals.items():
        if sha256((app / name).read_bytes()) != sha256(data):
            raise ValueError(f"Bundled resource checksum mismatch: {name}")
    if sha256(binary.read_bytes()) != binary_sha:
        raise RuntimeError("Embedding resources unexpectedly changed the ARM64 app binary")
    return binary_sha


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=Path("SourceResources/PC586"))
    parser.add_argument("--app", type=Path, help="Unsigned Release-iphoneos *.app (omit for verify-only)")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    assets = load_originals(args.source)
    binary_sha = embed(args.app, assets) if args.app else None
    report = {"result": "PASS", "source": str(args.source), "count": len(assets),
              "files": {k: {"bytes": len(v), "sha256": sha256(v)} for k, v in assets.items()},
              "excluded": ["hangar_h55.glb"], "app_binary_sha256": binary_sha}
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: GitHub original PC586 resources {len(assets)}/15, "
          f"{sum(len(data) for data in assets.values())} bytes, "
          f"hangar_h55.glb excluded" + ("; embedded in unsigned app" if args.app else "; source verified"))


if __name__ == "__main__":
    main()
