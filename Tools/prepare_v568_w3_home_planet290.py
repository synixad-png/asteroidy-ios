#!/usr/bin/env python3
"""Stage exact source NewHome290 geometry and maps from already uploaded v568 ZIPs.

Uses SHA256-validated four existing archive parts. Never rebuilds a
lookalike planet. The shared GPU stream is constructed from the exact
12-float source vertices and indexed triangles, retaining source materials.
No IPA is created.
"""
from pathlib import Path
import argparse
import importlib.util
import json
import hashlib
import sys

ROOT=Path(__file__).resolve().parents[1]
def load(name,relative):
    spec=importlib.util.spec_from_file_location(name,ROOT/relative)
    obj=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(obj)
    return obj
archive=load("exact_v568_archives_w3","Tools/stage_v568_resources.py")
planet=load("source_home290","Tools/convert_v568_w3_home_planet290.py")
BASE="PortingResources/v568/Shared/assets/"
SOURCE={
    "home290.mesh.gz":planet.SOURCE_SHA,
    "home290.texture.jpg":planet.BASE_SHA,
    "home293.glow.png":planet.GLOW_SHA,
}
OUTPUT={
    "W3HomePlanet290OriginalGPU.bin",
    "W3HomePlanet290Base.dat",
    "W3HomePlanet293Glow.dat",
    "W3HomePlanet290Source.json",
}
def stage(original,dest):
    streams=[]
    try:
        streams,entries,manifest,_=archive.verify_archive_set(original)
        blobs={}
        for name,digest in SOURCE.items():
            path=BASE+name
            z,info=entries[path]
            blob=z.read(info)
            if planet.digest(blob)!=digest or manifest[path]!=digest:
                raise ValueError("Original v568 W3 home source mismatch: "+name)
            blobs[name]=blob
        gpu,meta=planet.decode(blobs["home290.mesh.gz"])
        data={
            "W3HomePlanet290OriginalGPU.bin":gpu,
            "W3HomePlanet290Base.dat":blobs["home290.texture.jpg"],
            "W3HomePlanet293Glow.dat":blobs["home293.glow.png"],
            "W3HomePlanet290Source.json":(json.dumps(meta,sort_keys=True,indent=2)+"\n").encode()
        }
        dest.mkdir(parents=True,exist_ok=True)
        for name,payload in data.items():
            path=dest/name
            if path.exists() and hashlib.sha256(path.read_bytes()).digest()!=hashlib.sha256(payload).digest():
                raise ValueError("Refusing to overwrite different original W3 planet: "+name)
            if not path.exists():
                path.write_bytes(payload)
        print("PASS original v568 NewHome290 GLB-derived 172208 triangles, 2 groups, JPEG and lava glow")
        print("LIMIT original world PBR/shader and actual Metal GPU rendering require separate verification")
        return meta
    finally:
        for z in streams:z.close()

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root",type=Path,default=ROOT)
    parser.add_argument("--destination",type=Path,default=ROOT/"ASTEROIDYiOS/Assets")
    args=parser.parse_args()
    try:stage(args.root,args.destination)
    except (OSError,ValueError,EOFError,KeyError) as exc:
        print("FAIL source W3 home planet: "+str(exc),file=sys.stderr)
        raise SystemExit(1)
