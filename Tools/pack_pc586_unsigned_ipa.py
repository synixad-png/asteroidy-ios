#!/usr/bin/env python3
"""Inject the FOUR original PC586 pickup GLBs + source meshes/JPEG into an UNSIGNED IPA.

The program binary, H55/H71, all original resources and the W3 HUD remain
byte-for-byte unchanged. Refuse signed/ambiguous apps or unverified assets.
"""
import argparse
import hashlib
import json
import plistlib
import struct
import sys
import zipfile
from pathlib import Path

ORIGINALS = {
    "shield": (478320, "531f1d49ea9782a2c40ce6870cd308d067461cc5f80cfaefc659f3db4ffe5a62", 27567,
               "706a39a504ade3f6b51ffa49f439c25e737ee42d92173cc23029d3bb573a7c2e", "1612ebb5d9d8c79f0232f885fbbc52483ab6df8f5b22743b0ac2253b01713964"),
    "boost": (502996, "6f7a083b493b029f4907988b55dbf9cdc49c7d5d187e023fa20521319b494362", 27837,
              "087de160a554328b975306decf7527f0c9aa7b44f459135e2ccf360214b8f67e", "ae87f82d0bee71adaaa480ed5a520977a777ba1c1a09275a2d2947354d384bd2"),
    "energy": (506076, "df9c3a85ef45d55d3ce08d9d82ec9ec1f0ec1b8c2cdf06fb35550eb96aa3aca1", 28692,
               "9795e046475988c504159b41f54c4600499bf250c479c181094759940d481663", "5457560331a6f61a3a9af518c595a2ecc03b8c8a74980b4f044c9cfed9266a6c"),
    "bomb": (483424, "e8787ce4b11c8b44b6b710a93419b0c8cc263cafe27c35e580b0c4cb8bffaaee", 27750,
             "c6eb907b60b28889220be4d97076aa93a87f14d4ef701541a0afae6062ef7c58", "4228a05eee0cd83c6e36bd3cdbed67ff661129d4550f2a22089c5c28196481ff"),
}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def verify_resources(directory):
    assets = {}
    for name, (size, glb_hash, count, mesh_hash, jpeg_hash) in ORIGINALS.items():
        glb, mesh, image = ((directory / (name + "." + ext)).read_bytes()
                            for ext in ("glb", "mesh", "jpg"))
        if len(glb) != size or digest(glb) != glb_hash:
            raise ValueError(name + ": unverified original GLB")
        if glb[:4] != b"glTF" or struct.unpack_from("<II", glb, 4) != (2, len(glb)):
            raise ValueError(name + ": invalid GLB2 header")
        if len(mesh) != 40 + count * 48 or digest(mesh) != mesh_hash:
            raise ValueError(name + ": invalid original triangle stream")
        if mesh[:4] != b"P586" or struct.unpack_from("<I", mesh, 4)[0] != count:
            raise ValueError(name + ": wrong Metal stream header")
        if mesh[8:40] != bytes.fromhex(glb_hash):
            raise ValueError(name + ": wrong stream source identity")
        if digest(image) != jpeg_hash or image[:2] != b"\xff\xd8":
            raise ValueError(name + ": unverified original JPEG")
        assets.update({name + ".glb": glb, name + ".mesh": mesh, name + ".jpg": image})
    return assets


def pack(source_path, resources_path, output_path):
    if source_path.resolve() == output_path.resolve():
        raise ValueError("The original IPA must never be overwritten")
    assets = verify_resources(resources_path)
    with zipfile.ZipFile(source_path) as original:
        if original.testzip() is not None:
            raise ValueError("Source IPA CRC failure")
        entries = original.namelist()
        if len(entries) != len(set(entries)):
            raise ValueError("Duplicate original IPA paths")
        roots = {p.split(".app/", 1)[0] + ".app/" for p in entries
                 if p.startswith("Payload/") and ".app/" in p}
        if len(roots) != 1:
            raise ValueError("Expected one application in IPA Payload")
        root = roots.pop()
        if root + "Info.plist" not in entries:
            raise ValueError("App Info.plist not present")
        info = plistlib.loads(original.read(root + "Info.plist"))
        if info.get("CFBundleIdentifier") != "com.synixad.asteroidyios":
            raise ValueError("This is not the expected ASTEROIDYiOS app")
        if any(p.startswith(root + "_CodeSignature/") for p in entries):
            raise ValueError("Cannot mutate an already signed IPA")
        if any(root + p in entries for p in assets):
            raise ValueError("Source IPA already contains PC586 pickup assets")
        with zipfile.ZipFile(output_path, "w") as target:
            for entry in original.infolist():
                target.writestr(entry, original.read(entry))
            for name in sorted(assets):
                target.writestr(root + name, assets[name],
                                compress_type=zipfile.ZIP_DEFLATED, compresslevel=6)

    with zipfile.ZipFile(source_path) as original, zipfile.ZipFile(output_path) as target:
        if target.testzip() is not None:
            raise ValueError("Final IPA CRC failure")
        if len(target.namelist()) != len(entries) + len(assets):
            raise ValueError("Unexpected number of final IPA resources")
        for name, expected in assets.items():
            if target.read(root + name) != expected:
                raise ValueError("Source pickup was corrupted in IPA: " + name)
        for path in entries:
            if not path.endswith("/") and target.read(path) != original.read(path):
                raise ValueError("Existing application resource changed: " + path)
    print(json.dumps({"status": "PASS", "bundle_id": info["CFBundleIdentifier"],
                      "embedded_resources": len(assets),
                      "output_sha256": digest(output_path.read_bytes())}, indent=2))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--ipa", type=Path, required=True)
    parser.add_argument("--resources", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        pack(args.ipa, args.resources, args.output)
    except (OSError, ValueError, zipfile.BadZipFile) as error:
        sys.exit("FAIL: " + str(error))


if __name__ == "__main__":
    main()
