#!/usr/bin/env python3
"""Recover all source-verified iOS game assets in the 2026-11-10 HUD IPA.

The original Release ARM64 application is byte-identical to the already
validated GitHub build. This tool NEVER recompiles, fabricates or modifies a
pre-existing bundle member. Missing v568 and PC586 assets are individually
validated by their source SHA256 inventories. H55's separate 126419336-byte
hangar_h55.glb is intentionally imported through the existing Files workflow.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import plistlib
import sys
import zipfile
from pathlib import Path

from materialize_pc586_original_resources import load_originals, REQUIRED

# Stage these with Tools/prepare_v568_* from the four exact audited v568 ZIPs
# and the SHA-locked W3 menu archive BEFORE calling this packer.
REQUIRED_V568 = (
    "Sector01CarbonisVertices.bin",
    "Sector01CarbonisIndices.bin",
    "Sector01CarbonisHeightMap.dat",
    "Sector01CarbonisBase.dat",
    "Sector01CarbonisEmissive.dat",
    "Sector01CarbonisIrradiance.dat",
    "Sector01CarbonisSource.json",
    "W3HomePlanet290OriginalGPU.bin",
    "W3HomePlanet290Base.dat",
    "W3HomePlanet293Glow.dat",
    "W3HomePlanet290Source.json",
    "PlayerShip367OriginalGPU.bin",
    "PlayerShip363Base.jpg",
    "PlayerShip367Source.json",
    "W3Background568Original.dat",
    "W3Logo568Original.dat",
)
assert len(REQUIRED_V568) == 16

def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def verify_ipa(ipa: Path, base: Path, checks: dict[str, str]) -> dict:
    with zipfile.ZipFile(base) as old, zipfile.ZipFile(ipa) as new:
        assert old.testzip() is None and new.testzip() is None, "IPA CRC failure"
        original = [i for i in old.infolist() if not i.is_dir()]
        names = [i.filename for i in new.infolist() if not i.is_dir()]
        assert len(names) == len(set(names)), "Duplicated bundle members"
        prefixes = {s.split(".app/",1)[0]+".app/" for s in names
                    if s.startswith("Payload/") and ".app/" in s}
        assert len(prefixes) == 1, "Multiple applications"
        root = prefixes.pop()
        plist = plistlib.loads(new.read(root+"Info.plist"))
        assert plist["CFBundleIdentifier"] == "com.synixad.asteroidyios"
        assert set(plist["UIDeviceFamily"]) == {1,2}
        exe = root+plist["CFBundleExecutable"]
        assert old.read(exe) == new.read(exe), "Compiled ARM64 program was modified!"
        assert new.read(exe)[:4] == bytes.fromhex("cffaedfe")
        for item in original:
            assert old.read(item.filename) == new.read(item.filename), (
                "Existing resource changed: "+item.filename)
        for filename,digest in checks.items():
            b = new.read(root+filename)
            assert sha(b) == digest, "Source checksum mismatch: "+filename
        assert not any(n.endswith("/hangar_h55.glb") for n in names), (
            "The 126 MB hangar has a separate verified Files import")
        return {
            "result": "PASS", "source_ipa":str(base), "rebuilt_ipa":str(ipa),
            "source_ipa_sha256":sha(base.read_bytes()),
            "rebuilt_ipa_sha256":sha(ipa.read_bytes()),
            "rebuilt_bytes":ipa.stat().st_size,
            "original_members_preserved":len(original),
            "new_source_verified_assets":len(checks),
            "all_new_source_sha256":checks,
            "compiled_executable_sha256":sha(new.read(exe)),
            "unsigned":not any(n.startswith(root+"_CodeSignature/") for n in names),
            "hangar_h55_glb":"User must import the exact original scene via Files (126419336 bytes)",
        }

def pack(base:Path,staged:Path,source:Path,out:Path) -> dict:
    assert base.is_file() and staged.is_dir() and out.resolve()!=base.resolve()
    originals = load_originals(source)
    assert set(originals) == set(REQUIRED) and len(originals)==15
    additions=dict(originals)
    for name in REQUIRED_V568:
        p=staged/name
        if not p.is_file(): raise FileNotFoundError("Missing verified v568 original: "+name)
        additions[name] = p.read_bytes()
    assert len(additions)==31
    # Initial original v568 material must be produced by validated staging.
    # Detect corrupt/truncated geometry using source-specific metadata.
    for key in ("Sector01CarbonisSource.json", "W3HomePlanet290Source.json",
                "PlayerShip367Source.json"):
        parsed=json.loads(additions[key])
        if not isinstance(parsed,dict): raise ValueError("Invalid source manifest "+key)
    checks={k:sha(v) for k,v in additions.items()}
    with zipfile.ZipFile(base) as original:
        if original.testzip() is not None: raise ValueError("Base IPA CRC failure")
        names=original.namelist()
        roots={n.split(".app/",1)[0]+".app/" for n in names
               if n.startswith("Payload/") and ".app/" in n}
        if len(roots)!=1: raise ValueError("Not exactly one native iOS bundle")
        root=roots.pop()
        if any(n.startswith(root+"_CodeSignature/") for n in names):
            raise ValueError("Refusing to mutate signed iOS app")
        if any(root+name in names for name in additions):
            raise ValueError("Source IPA already contains some additions")
        with zipfile.ZipFile(out,"w") as archive:
            for meta in original.infolist():
                archive.writestr(meta,original.read(meta))
            for name,body in sorted(additions.items()):
                archive.writestr(root+name,body,compress_type=zipfile.ZIP_DEFLATED,
                                 compresslevel=6)
    return verify_ipa(out,base,checks)

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--base-ipa",required=True,type=Path)
    parser.add_argument("--source-resources",default="SourceResources/PC586",type=Path)
    parser.add_argument("--staged-v568",required=True,type=Path)
    parser.add_argument("--output",required=True,type=Path)
    parser.add_argument("--report",required=True,type=Path)
    args=parser.parse_args()
    try:
        record=pack(args.base_ipa,args.staged_v568,args.source_resources,args.output)
        args.report.parent.mkdir(parents=True,exist_ok=True)
        args.report.write_text(json.dumps(record,ensure_ascii=False,indent=2)+"\n")
        print("PASS FULL RESOURCE RESTORATION",
              record["original_members_preserved"],"original members +",
              record["new_source_verified_assets"],"verified game assets;",
              record["rebuilt_bytes"],"bytes")
    except (Exception,) as error:
        raise SystemExit("FAIL: "+str(error)) from error

if __name__=="__main__":
    main()
