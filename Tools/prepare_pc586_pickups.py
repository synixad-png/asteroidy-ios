#!/usr/bin/env python3
"""Stage SHA-locked original PC v586 pickup GLBs into the existing iOS Assets target.

All input files are checked before changing the destination. Original geometry,
UV, embedded JPEG and material are preserved; no second runtime importer.
"""
import argparse
import hashlib
import os
import struct
import tempfile
import zipfile
from pathlib import Path

ARCHIVE_SHA = "8fad7f8444321ff91b77bd0dc7bdf50491cad65870df794151ffc586e27c06ff"
MODELS = {
    "shield.glb": (478320, "531f1d49ea9782a2c40ce6870cd308d067461cc5f80cfaefc659f3db4ffe5a62"),
    "boost.glb": (502996, "6f7a083b493b029f4907988b55dbf9cdc49c7d5d187e023fa20521319b494362"),
    "energy.glb": (506076, "df9c3a85ef45d55d3ce08d9d82ec9ec1f0ec1b8c2cdf06fb35550eb96aa3aca1"),
    "bomb.glb": (483424, "e8787ce4b11c8b44b6b710a93419b0c8cc263cafe27c35e580b0c4cb8bffaaee"),
}

def sha256(data):
    return hashlib.sha256(data).hexdigest()

def validate(name, data):
    length, expected = MODELS[name]
    if len(data) != length or sha256(data) != expected:
        raise ValueError(name + ": size/SHA mismatch; no replacement allowed")
    if (len(data) < 20 or data[:4] != b"glTF"
            or struct.unpack_from("<I", data, 4)[0] != 2
            or struct.unpack_from("<I", data, 8)[0] != len(data)):
        raise ValueError(name + ": invalid GLB2 header")

def read_archive(archive):
    if sha256(archive.read_bytes()) != ARCHIVE_SHA:
        raise ValueError("PC v586 source ZIP differs from the approved archive")
    result = {}
    with zipfile.ZipFile(archive) as zipped:
        if zipped.testzip() is not None:
            raise ValueError("PC source archive CRC failed")
        for name in MODELS:
            result[name] = zipped.read("Shared/assets/pickups/" + name)
            validate(name, result[name])
    return result

def verify(destination):
    for name in MODELS:
        validate(name, (destination / name).read_bytes())
    print("PASS: four original PC586 GLBs in existing iOS Assets target")

def stage(archive, destination):
    payloads = read_archive(archive)
    destination.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=destination) as temp:
        temporary = Path(temp)
        for name, data in payloads.items():
            (temporary / name).write_bytes(data)
        for name in MODELS:
            validate(name, (temporary / name).read_bytes())
        for name in MODELS:
            os.replace(temporary / name, destination / name)
    verify(destination)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", type=Path)
    parser.add_argument("--destination", type=Path, required=True)
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()
    if args.verify_only:
        verify(args.destination)
    else:
        if args.archive is None:
            parser.error("--archive required unless --verify-only")
        stage(args.archive, args.destination)

if __name__ == "__main__":
    main()
