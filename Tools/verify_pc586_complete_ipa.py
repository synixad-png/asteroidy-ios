#!/usr/bin/env python3
"""Prove that one unsigned ARM64 IPA actually CONTAINS PC580+PC586 originals.

Source Swift compiling successfully is not enough: verify 15 exact models,
ARM64 Mach-O, iOS bundle metadata, and compiled Metal pickup shader symbols.
"""
import argparse
import hashlib
import json
import plistlib
import struct
import sys
import zipfile
from pathlib import Path

from pack_h55_original_models_ipa import MODELS as H55
from pack_pc586_unsigned_ipa import ORIGINALS as PICKUPS


def sha256(raw):
    return hashlib.sha256(raw).hexdigest()


def verify(path):
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:
            raise ValueError("Corrupt IPA ZIP/CRC")
        names=archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError("Duplicate IPA entry")
        apps={n.split(".app/",1)[0]+".app/" for n in names
              if n.startswith("Payload/") and ".app/" in n}
        if len(apps) != 1:
            raise ValueError("Expected one app")
        root=apps.pop()
        if root + "Info.plist" not in names:
            raise ValueError("No top-level Info.plist")
        bundle=plistlib.loads(archive.read(root + "Info.plist"))
        if bundle.get("CFBundleIdentifier") != "com.synixad.asteroidyios":
            raise ValueError("Unexpected bundle identifier")
        executable=bundle.get("CFBundleExecutable")
        if not executable or root+executable not in names:
            raise ValueError("App executable missing")
        binary=archive.read(root+executable)
        if len(binary)<32:
            raise ValueError("Mach-O binary truncated")
        magic,cputype=struct.unpack_from("<II",binary,0)
        if magic!=0xFEEDFACF or cputype!=0x0100000C:
            raise ValueError("Expected thin arm64 Mach-O app executable")
        shaders=archive.read(root+"default.metallib")
        names_586=["sector01PickupVertex586","sector01PickupFragment586"]
        for symbol in names_586:
            if symbol.encode("ascii") not in shaders:
                raise ValueError("Actual compiled Metal shader missing: "+symbol)
        if any(x.startswith(root+"_CodeSignature/") for x in names):
            raise ValueError("The delivered test IPA must remain unsigned")

        verified={}
        for name,(expected_bytes,expected_sha) in H55.items():
            body=archive.read(root+name)
            if len(body)!=expected_bytes or sha256(body)!=expected_sha:
                raise ValueError("H55 original GLB hash mismatch: "+name)
            verified[name]=expected_sha
        for kind,(size,glbhash,count,meshhash,jpghash) in PICKUPS.items():
            files={"glb":glbhash,"mesh":meshhash,"jpg":jpghash}
            for extension,expected in files.items():
                name=kind+"."+extension
                body=archive.read(root+name)
                if sha256(body)!=expected:
                    raise ValueError("PC586 resource SHA mismatch: "+name)
                if extension=="glb":
                    if len(body)!=size:
                        raise ValueError("Source GLB wrong size: "+name)
                elif extension=="mesh":
                    if len(body)!=40+48*count:
                        raise ValueError("Mesh vertices mismatch: "+name)
                verified[name]=expected
        if len(verified)!=15:
            raise RuntimeError("Not all 15 source resources validated")
    result={"result":"PASS","ipa":str(path),"bytes":path.stat().st_size,
            "sha256":sha256(path.read_bytes()),"bundle_id":bundle["CFBundleIdentifier"],
            "app_arch":"arm64","original_resource_count":len(verified),
            "metal_shader_symbols":names_586}
    print(json.dumps(result,indent=2,ensure_ascii=False))
    return result


if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("ipa",type=Path)
    opts=parser.parse_args()
    try:
        verify(opts.ipa)
    except (ValueError,KeyError,FileNotFoundError,zipfile.BadZipFile,struct.error) as exc:
        sys.exit("FAIL: "+str(exc))
