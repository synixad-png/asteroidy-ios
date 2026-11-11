#!/usr/bin/env python3
"""Stage byte-verified PC v602 NewHome290 world assets from the GitHub archives.

The ASTEROIDY v602 original uses the SAME H290 mesh, base JPEG and 293
combined lava glow that the existing four SHA-pinned v568 GitHub ZIP parts
contain. Verify every byte instead of substituting a procedural sphere.
The 512x256 source collision height map is also extracted; the existing W3
preview intentionally omitted that physical data. No gameplay is claimed.
"""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import struct
import sys
import zipfile

import stage_v568_resources as archives
import convert_v568_w3_home_planet290 as converter

ASSETS = "PortingResources/v568/Shared/assets/"
ORIGINAL = {
    "home290.mesh.gz": "025a3ad626de24e666bb0c697aa1a8e855401965869ded96f7eee109f0ece278",
    "home290.texture.jpg": "4987f35cd6f021fd98794f406c641f4853c538a82b10625e6b79e860c8a787c0",
    "home293.glow.png": "6f1debd175f52b7ce1fbc687e9977597335ee432858d7d6d6e47cf66b5f9aa39",
}
HEIGHT_SHA = "12d56a99634e4fc28ded9e03bcac34de05020750cc18e86d1086db8542b2d18d"
HEIGHT_BYTES = 512 * 256 * 4
SOURCE_ARCHIVE_SHA = "359abd889544c846faa9426fd291df8528951ed2253fe67c47dbb9e9d9f2103b"


def digest(value):
    return hashlib.sha256(value).hexdigest()


def read_from_github_archives(root):
    opened = []
    try:
        opened, entries, manifest, _ = archives.verify_archive_set(root)
        original = {}
        for name, expected in ORIGINAL.items():
            path = ASSETS + name
            if path not in entries or manifest.get(path) != expected:
                raise ValueError("Missing or nonmatching GitHub original: " + path)
            z, info = entries[path]
            data = z.read(info)
            if digest(data) != expected:
                raise ValueError("Wrong GitHub original SHA256: " + name)
            original[name] = data
        return original
    finally:
        for z in opened:
            z.close()


def read_from_v602_archive(path):
    # Optional independent comparison with the user's original v602 ZIP.
    if digest(path.read_bytes()) != SOURCE_ARCHIVE_SHA:
        raise ValueError("PC602 source ZIP SHA256 mismatch")
    with zipfile.ZipFile(path) as z:
        original = {}
        for name, expected in ORIGINAL.items():
            key = "Shared/assets/" + name
            blob = z.read(key)
            if digest(blob) != expected:
                raise ValueError("Original PC602 asset SHA256 mismatch: " + key)
            original[name] = blob
        return original


def height_bytes(compressed):
    if digest(compressed) != ORIGINAL["home290.mesh.gz"]:
        raise ValueError("NewHome290 is not the approved original H290")
    raw = gzip.decompress(compressed)
    if len(raw) != converter.RAW_BYTES or digest(raw) != converter.RAW_SHA:
        raise ValueError("Wrong decompressed H290 source")
    magic, materials = struct.unpack_from("<Ii", raw, 0)
    if (magic, materials) != (0x30393248, 2):
        raise ValueError("Wrong H290 material groups")
    counts = tuple(struct.unpack_from("<ii", raw, 8 + 8*k) for k in range(2))
    if counts != converter.COUNTS:
        raise ValueError("Wrong H290 vertex/index counts")
    cursor = 8 + 8*materials
    cursor += sum(unique * 48 for count, unique in counts)
    cursor += sum(count * 4 for count, unique in counts)
    width, height = struct.unpack_from("<ii", raw, cursor)
    cursor += 8
    if (width, height) != (512, 256) or cursor + HEIGHT_BYTES != len(raw):
        raise ValueError("Missing exact 512x256 physical planet surface")
    heights = raw[cursor:]
    if digest(heights) != HEIGHT_SHA:
        raise ValueError("PC602 home height-map SHA256 mismatch")
    return heights


def stage(root, destination, source_zip=None):
    original = (read_from_v602_archive(source_zip) if source_zip
                else read_from_github_archives(root))
    gpu, meta = converter.decode(original["home290.mesh.gz"])
    heights = height_bytes(original["home290.mesh.gz"])
    meta.update({
        "referenceVersion": "PC v602",
        "worldGameMode": "NewHome290 / HomeFlight291",
        "heightMapSHA256": HEIGHT_SHA,
        "physicalWorldIntegrated": False,
        "verifiedAgainstV602": True,
    })
    files = {
        "W3HomePlanet290OriginalGPU.bin": gpu,
        "W3HomePlanet290Base.dat": original["home290.texture.jpg"],
        "W3HomePlanet293Glow.dat": original["home293.glow.png"],
        "PC602Home290HeightMap.bin": heights,
        "PC602Home290Source.json": (json.dumps(meta, sort_keys=True, indent=2)+"\n").encode(),
    }
    destination.mkdir(parents=True, exist_ok=True)
    for name, payload in files.items():
        target = destination / name
        if target.exists():
            if digest(target.read_bytes()) != digest(payload):
                raise ValueError("Refusing to overwrite unrelated asset: "+str(target))
            continue
        temp = target.with_name(target.name + ".tmp")
        try:
            with temp.open("xb") as out:
                out.write(payload)
            temp.replace(target)
        finally:
            temp.unlink(missing_ok=True)
    return {"status": "PASS", "source": "PC602 byte-verified H290",
            "triangles": meta["triangleCount"], "heightMap": [512, 256],
            "heightSHA256": HEIGHT_SHA,
            "allRequiredRuntimeAssetsDerivedFromGitHub": source_zip is None,
            "physicalWorldIntegrated": False}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    p.add_argument("--destination", type=Path)
    p.add_argument("--source-zip", type=Path)
    args = p.parse_args()
    destination = args.destination or (args.root/"ASTEROIDYiOS/Assets")
    try:
        print(json.dumps(stage(args.root, destination, args.source_zip), sort_keys=True))
    except (OSError, ValueError, EOFError, KeyError, struct.error, zipfile.BadZipFile) as error:
        print("FAIL PC602 NewHome290: " + str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
