#!/usr/bin/env python3
"""Stage two exact original W3 v568 source images if the optional ZIP exists.

The user-uploaded menu assets have their own SHA256 gate; NEVER use an
unverified lookalike. A missing ZIP is reported as SKIP and native SwiftUI
falls back to labelled source-guided geometry, not a fake source image.
No IPA is created by this script.
"""
import argparse
import hashlib
from pathlib import Path
import sys
import zipfile

ARCHIVE="ASTEROIDY_v568_W3_ORIGINAL_MENU_ASSETS.zip"
FILES={
    "W3Background568.jpg": (
        806519,"a8aa28883084657f0c38900dbb011de09e2b0fd461704d370a68858be0178145"
    ),
    "W3Logo568.png": (
        50257,"cab4198b953640c787975c5a8436a0fdeaa82502b40e000077ff055cc0709e09"
    ),
}
def sha(data):
    return hashlib.sha256(data).hexdigest()

def prepare(root,destination,required=False):
    archive=root/ARCHIVE
    if not archive.exists():
        if required:
            raise ValueError("Original W3 menu asset archive not uploaded")
        print("SKIP: original W3 v568 JPG/PNG absent; no source-image parity claimed")
        return False
    with zipfile.ZipFile(archive) as z:
        if z.testzip() is not None:
            raise ValueError("Original W3 ZIP CRC mismatch")
        names=[i.filename for i in z.infolist()]
        required_names=set(FILES)|{"MANIFEST_SHA256.json","CZYTAJ.txt"}
        if set(names)!=required_names or len(names)!=len(required_names):
            raise ValueError("Unexpected or missing original W3 asset ZIP members")
        payload={}
        for name,(size,digest) in FILES.items():
            b=z.read(name)
            if len(b)!=size or sha(b)!=digest:
                raise ValueError("Original W3 source asset SHA256/size mismatch: "+name)
            payload[name]=b
    destination.mkdir(parents=True,exist_ok=True)
    # Xcode may recompress PNG resource files (and alter their SHA-256).
    # Preserve the exact original JPEG/PNG *bytes* in extension-neutral blobs.
    # UIImage(data:) still decodes original formats without any approximation.
    output_names={
        "W3Background568.jpg":"W3Background568Original.dat",
        "W3Logo568.png":"W3Logo568Original.dat",
    }
    for name,data in payload.items():
        path=destination/output_names[name]
        if path.exists():
            if sha(path.read_bytes())!=sha(data):
                raise ValueError("Refusing overwrite of different W3 asset: "+name)
        else:
            path.write_bytes(data)
    print("PASS: source-identical W3 v568 shared background and logo")
    return True

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--root",type=Path,default=Path.cwd())
    p.add_argument("--destination",type=Path,default=Path("ASTEROIDYiOS/Assets"))
    p.add_argument("--required",action="store_true")
    a=p.parse_args()
    try:prepare(a.root,a.destination,a.required)
    except (ValueError,OSError,zipfile.BadZipFile) as exc:
        print("FAIL W3 source image staging: "+str(exc),file=sys.stderr)
        return 1
    return 0

if __name__=="__main__":
    raise SystemExit(main())
