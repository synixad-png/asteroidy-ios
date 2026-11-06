#!/usr/bin/env python3
"""Prepare only source-identical v568 PlayerShip367 for an iOS Xcode build.

Call BEFORE xcodegen generate on a clean GitHub checkout. This stages the
original four archives, validates every archive+manifest hash, then exports
only the audited PlayerShip367 triangle-corner packet and exact source JPEG.
No approximate mesh or arbitrary GLB can enter the app through this route.
"""
from pathlib import Path
import importlib.util
import argparse
import hashlib
import json
import sys

ROOT=Path(__file__).resolve().parents[1]
def load(name,path):
    spec=importlib.util.spec_from_file_location(name,ROOT/path)
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module
stage=load("v568_stage_for_ios","Tools/stage_v568_resources.py")
source=load("v568_player_ship_for_ios","Tools/convert_v568_player_ship367.py")
BASE="PortingResources/v568/Shared/assets/"
ASSETS={
    "PlayerShip367OriginalGPU.bin":source.convert,
}
def main(argv=None):
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--root",type=Path,default=ROOT)
    p.add_argument("--destination",type=Path,default=ROOT/"ASTEROIDYiOS/Assets")
    args=p.parse_args(argv)
    streams=[]
    try:
        streams,entries,manifest,_=stage.verify_archive_set(args.root)
        def original(relative):
            z,info=entries[BASE+relative]
            return z.read(info)
        mesh=original("player_ship367.mesh.gz")
        jpeg=original("player_ship363.base.jpg")
        if source.sha(jpeg)!=source.TEXTURE_SHA256:
            raise ValueError("Missing exact v568 player ship texture")
        gpu,faces,meta=source.convert(mesh)
        desired={
            "PlayerShip367OriginalGPU.bin":gpu,
            "PlayerShip363Base.jpg":jpeg,
            "PlayerShip367Source.json":(
                json.dumps(meta,sort_keys=True,indent=2)+"\n"
            ).encode(),
        }
        args.destination.mkdir(parents=True,exist_ok=True)
        for name,data in desired.items():
            path=args.destination/name
            if path.exists():
                if hashlib.sha256(path.read_bytes()).digest()!=hashlib.sha256(data).digest():
                    raise ValueError("Refusing to overwrite different existing asset: "+name)
                continue
            path.write_bytes(data)
        print("PASS: exactly original v568 PlayerShip367 GPU, source JPEG and source JSON staged")
        print("LIMIT: Xcode compile needed; no IPA generated")
        return 0
    except (ValueError,OSError,KeyError) as exc:
        print("FAIL original PlayerShip367 staging: "+str(exc),file=sys.stderr)
        return 1
    finally:
        for z in streams:
            z.close()

if __name__=="__main__":
    raise SystemExit(main())
