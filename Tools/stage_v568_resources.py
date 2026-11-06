#!/usr/bin/env python3
"""Verify the 4 audited ASTEROIDY v568 archives; stage separately, never into Xcode assets.

Verification binds each ZIP to the byte-identical v568 audit and each extracted
file to its SHA256 manifest. Neither mode enables models in the iOS renderer.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import sys
import tempfile
import zipfile

PARTS = (
    ("ASTEROIDY_v568_ZASOBY_DO_GITHUB_CZESC_01_z_04.zip",19173754,
     "65df75fd5993e83c180b2d3e70347d7f27b8477846ec1d743dfbcfbeafc6eadd"),
    ("ASTEROIDY_v568_ZASOBY_DO_GITHUB_CZESC_02_z_04.zip",19151187,
     "4e90f6ead14fa40b95d4e53e0c76ed5c8fe775d30c8b721ab3086f6c3a20e870"),
    ("ASTEROIDY_v568_ZASOBY_DO_GITHUB_CZESC_03_z_04.zip",19399287,
     "50615c94012e5685883bd15d44ee8d8ee703a6bb02ba47da5db43c747cfb2ed6"),
    ("ASTEROIDY_v568_ZASOBY_DO_GITHUB_CZESC_04_z_04.zip",8623321,
     "0b8ac2582013b2af0d62821e0a9354ce427af5c859c8c07bd58358651687145a"),
)
MANIFEST = "MANIFEST_SHA256_ALL_FILES.txt"
EXPECTED_FILES = 90
MAX_FILE_BYTES = 25*1024*1024
MAX_TOTAL_BYTES = 160*1024*1024
CHUNK = 1024*1024

class VerificationError(ValueError):
    pass

def digest_stream(stream):
    h=hashlib.sha256()
    while True:
        block=stream.read(CHUNK)
        if not block:
            return h.hexdigest()
        h.update(block)

def safe_member(name):
    if not name or "\\" in name or "\x00" in name or name.startswith("/"):
        raise VerificationError("Unsafe ZIP path: "+repr(name))
    parts=name.split("/")
    if any(part in ("",".","..") for part in parts) or ":" in parts[0]:
        raise VerificationError("Unsafe ZIP path: "+repr(name))
    if parts[0] not in ("PortingResources","PortingReferenceCode") and len(parts)!=1:
        raise VerificationError("Unexpected ZIP root: "+name)
    if len(parts)==1 and not name.endswith((".txt",".csv")):
        raise VerificationError("Unexpected top-level file: "+name)
    return PurePosixPath(*parts)

def verify_archive_set(root):
    archives=[]
    entries={}
    total=0
    for name, size, hash_ in PARTS:
        path=root/name
        if not path.is_file() or path.stat().st_size!=size:
            raise VerificationError("Missing or wrong-sized v568 archive: "+name)
        with path.open("rb") as f:
            if digest_stream(f)!=hash_:
                raise VerificationError("Wrong v568 archive SHA256: "+name)
        z=zipfile.ZipFile(path)
        archives.append(z)
        for info in z.infolist():
            safe_member(info.filename)
            if info.is_dir() or stat.S_ISLNK(info.external_attr>>16):
                raise VerificationError("Unsupported ZIP entry: "+info.filename)
            if info.filename in entries:
                raise VerificationError("Duplicate ZIP entry: "+info.filename)
            if info.file_size>MAX_FILE_BYTES:
                raise VerificationError("Oversized ZIP entry: "+info.filename)
            total+=info.file_size
            if total>MAX_TOTAL_BYTES:
                raise VerificationError("Untrusted ZIP payload exceeds size limit")
            entries[info.filename]=(z,info)
    if len(entries)!=EXPECTED_FILES or MANIFEST not in entries:
        raise VerificationError("Expected 90 audited files including SHA256 manifest")
    z,info=entries[MANIFEST]
    expected={}
    for line in z.read(info).decode("utf-8").splitlines():
        if not line.strip():
            continue
        match=re.fullmatch(r"([0-9a-f]{64})  (.+)",line)
        if not match:
            raise VerificationError("Malformed SHA256 manifest")
        hash_,name=match.groups()
        safe_member(name)
        if name in expected or name==MANIFEST:
            raise VerificationError("Duplicate/self-referential manifest path")
        expected[name]=hash_
    if set(expected)!=set(entries)-{MANIFEST}:
        raise VerificationError("Manifest does not exactly cover 89 payload files")
    for name, hash_ in sorted(expected.items()):
        z,info=entries[name]
        with z.open(info) as f:
            if digest_stream(f)!=hash_:
                raise VerificationError("Original v568 payload SHA256 mismatch: "+name)
    return archives,entries,expected,total

def stage(entries,destination):
    if destination.exists():
        raise VerificationError("Refusing to overwrite: "+str(destination))
    destination.parent.mkdir(parents=True,exist_ok=True)
    temporary=Path(tempfile.mkdtemp(prefix=".v568-verified-",dir=destination.parent))
    try:
        for name,(z,info) in sorted(entries.items()):
            target=temporary.joinpath(*PurePosixPath(name).parts)
            target.parent.mkdir(parents=True,exist_ok=True)
            with z.open(info) as src,target.open("xb") as dst:
                count=0
                while True:
                    block=src.read(CHUNK)
                    if not block:
                        break
                    count+=len(block)
                    if count>info.file_size or count>MAX_FILE_BYTES:
                        raise VerificationError("Unbounded entry: "+name)
                    dst.write(block)
                if count!=info.file_size:
                    raise VerificationError("Truncated ZIP entry: "+name)
        os.rename(temporary,destination)
    finally:
        if temporary.exists():
            shutil.rmtree(temporary)

def main(argv=None):
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--root",type=Path,default=Path.cwd())
    choice=p.add_mutually_exclusive_group(required=True)
    choice.add_argument("--verify-only",action="store_true")
    choice.add_argument("--destination",type=Path)
    args=p.parse_args(argv)
    archives=[]
    try:
        archives,entries,expected,total=verify_archive_set(args.root)
        if args.destination:
            stage(entries,args.destination)
        print(json.dumps({"result":"PASS","v568Archives":4,
            "sha256VerifiedFiles":len(expected),"manifestFiles":len(entries),
            "payloadBytes":total,"mode":"stage" if args.destination else "verify-only",
            "iosRuntimeModelsIntegrated":False},sort_keys=True))
        return 0
    except (OSError,ValueError,zipfile.BadZipFile,UnicodeError) as exc:
        print("FAIL v568: "+str(exc),file=sys.stderr)
        return 1
    finally:
        for z in archives:
            z.close()

if __name__=="__main__":
    raise SystemExit(main())
