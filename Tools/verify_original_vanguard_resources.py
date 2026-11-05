#!/usr/bin/env python3
"""Strict ORIGINAL Vanguard431 resource gate for future iOS releases.

The user's PC v568 runtime assets are the only accepted inputs. Prevent
successful but visually unchanged IPA builds when the new UV/texture
renderer silently falls back to the old AS3D asset. No external URLs,
downloaded stand-ins, generated textures or modified source assets.
Standard library only; independently validates original JPEG size.
Usage:
  python3 Tools/verify_original_vanguard_resources.py --assets ASTEROIDYiOS/Assets
  python3 Tools/verify_original_vanguard_resources.py --ipa ASTEROIDY_iPhone_iPad_UNSIGNED.ipa
Missing, damaged or substituted material fails exit code 1.
"""
import argparse
import hashlib
import pathlib
import struct
import sys
import zipfile

EXPECTED = {
    "Vanguard431Source.mesh": (
        9721408,
        "f5d6d0107437fa54c3e8505f9adfbf6143cc877cb970eef687603609e26f9f4a"
    ),
    "Vanguard431Base.jpg": (
        1275318,
        "2945f711a6b559bfb5fdfb79750a2f2f77e2071aa5f3f4173eb450bce81b8b95"
    ),
}
EXPECTED_VERTICES = 194427
EXPECTED_CPU_TRIANGLES = 10802

def jpeg_dimensions(data:bytes):
    if len(data)<4 or data[:2] != b"\xff\xd8":
        raise ValueError("Original BaseColor is not a valid JPEG")
    pos=2
    while pos < len(data)-3:
        if data[pos] != 0xff:
            raise ValueError("Malformed original JPEG segment prefix")
        while pos<len(data) and data[pos] == 0xff:
            pos+=1
        if pos>=len(data):break
        marker=data[pos]
        pos+=1
        if marker in (0xd8,0xd9):
            continue
        if marker in (0xd0,0xd1,0xd2,0xd3,0xd4,0xd5,0xd6,0xd7,0x01):
            continue
        if pos+2>len(data):
            raise ValueError("Truncated original JPEG")
        n=int.from_bytes(data[pos:pos+2],"big")
        if n<2 or pos+n>len(data):
            raise ValueError("Malformed original JPEG segment length")
        if marker in (0xc0,0xc1,0xc2,0xc3,0xc5,0xc6,0xc7,
                      0xc9,0xca,0xcb,0xcd,0xce,0xcf):
            if n<7:raise ValueError("Truncated JPEG SOF")
            height=int.from_bytes(data[pos+3:pos+5],"big")
            width=int.from_bytes(data[pos+5:pos+7],"big")
            return width,height
        pos+=n
    raise ValueError("No original JPEG dimensions")

def inspect_assets(data:dict[str,bytes]):
    for name,(size,digest) in EXPECTED.items():
        if name not in data:
            raise ValueError("MISSING authentic Vanguard source resource: "+
                             name+"; DO NOT publish the old AS3D fallback IPA")
        content=data[name]
        if len(content) != size:
            raise ValueError(f"{name}: source size mismatch {len(content)} != {size}")
        if hashlib.sha256(content).hexdigest() != digest:
            raise ValueError(f"{name}: source SHA256 mismatch (no substitutions)")
    mesh=data["Vanguard431Source.mesh"]
    version,engines=struct.unpack_from("<ii",mesh,0)
    if (version,engines)!=(4311,2):
        raise ValueError("Vanguard source mesh header / engine count mismatch")
    float_count=struct.unpack_from("<i",mesh,32)[0]
    if float_count != EXPECTED_VERTICES*12:
        raise ValueError("Vanguard 12-float original UV/normal stream damaged")
    trailer=36+float_count*4
    faces=struct.unpack_from("<i",mesh,trailer)[0]
    if (faces != EXPECTED_CPU_TRIANGLES or
            len(mesh)!=trailer+4+faces*9*4):
        raise ValueError("Vanguard original CPU preview trailer damaged")
    if jpeg_dimensions(data["Vanguard431Base.jpg"])!=(2048,2048):
        raise ValueError("Original Vanguard BaseColor is not 2048x2048")
    print("PASS: source PC Vanguard431 genuine v4311 GPU vertex stream,")
    print(f"      {EXPECTED_VERTICES} original vertices, {faces} CPU faces,")
    print("      JPEG 2048x2048, required pair and SHA256 integrity")
    return True

def read_app_ipa(path):
    with zipfile.ZipFile(path) as z:
        if z.testzip() is not None:
            raise ValueError("IPA ZIP CRC failed")
        members=z.namelist()
        roots={p.split("/")[1] for p in members if
               p.startswith("Payload/") and ".app/" in p}
        if len(roots)!=1:
            raise ValueError("IPA does not contain exactly one .app")
        root="Payload/"+next(iter(roots))+"/"
        result={}
        for name in EXPECTED:
            matches=[p for p in members if
                     p.startswith(root) and p.endswith("/"+name)]
            if len(matches)!=1:
                raise ValueError("IPA missing original material: "+name)
            result[name]=z.read(matches[0])
        return result

def main():
    p=argparse.ArgumentParser(description=__doc__)
    group=p.add_mutually_exclusive_group(required=True)
    group.add_argument("--assets",type=pathlib.Path)
    group.add_argument("--ipa",type=pathlib.Path)
    args=p.parse_args()
    if args.assets:
        inspect_assets({n:(args.assets/n).read_bytes() for n in EXPECTED
                        if (args.assets/n).is_file()})
    else:
        inspect_assets(read_app_ipa(args.ipa))

if __name__=="__main__":
    try:main()
    except Exception as e:
        print(f"FAIL: source Vanguard431 validation: {e}",file=sys.stderr)
        sys.exit(1)
