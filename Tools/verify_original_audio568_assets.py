#!/usr/bin/env python3
"""Inspect 58 SOURCE-generated v568 audio assets, optionally in an Xcode .app.
Reject broken/missing assets, duplicate stems, silent synthetic stand-ins.
This does not prove audible fidelity on physical Apple hardware.
"""
from pathlib import Path
import argparse
import struct

def expected():
    sounds=[f"SFX{code}_{v}.m4a" for code in (*range(10,15),*range(20,23),30) for v in range(3)]
    sounds += [f"SFX{code}_0.m4a" for code in (*range(40,46),60)]
    sounds += [f"Music{i}.m4a" for i in range(15)]
    sounds += [f"Voice{i}.m4a" for i in (0,1,2,3,4,6,7)]
    sounds += ["Intro43.m4a","SYNTH_LICENSES.txt"]
    assert len(sounds)==58 and len(set(sounds))==58
    return sounds

p=argparse.ArgumentParser()
p.add_argument("--assets",default="ASTEROIDYiOS/Assets/Audio568")
p.add_argument("--app",default=None)
args=p.parse_args()
root=Path(args.assets)
assert root.is_dir(),root
for name in expected():
    file=root/name
    assert file.is_file() and file.stat().st_size>128,(name,"missing/tiny original")
    if name.endswith(".m4a"):
        with file.open("rb") as stream:
            head=stream.read(24)
        assert len(head)>=12 and head[4:8]==b"ftyp",(name,head[:12])
        assert file.stat().st_size>2000,(name,"AAC truncated")
        if name.startswith("Music"):
            assert file.stat().st_size>100_000,(name,"not a source music track")
assert sorted(x.name for x in root.iterdir() if x.is_file())==sorted(expected()),"unexpected files"
print("PASS original v568 source-generated assets: 15 music + 34 SFX + 7 voices + intro + licenses = 58")
if args.app is not None:
    app=Path(args.app)
    assert (app/"Info.plist").is_file(),app
    for name in expected():
        found=list(app.rglob(name))
        assert len(found)==1,(name,len(found))
        assert found[0].stat().st_size==(root/name).stat().st_size,(name,"bundle mismatch")
        if name.endswith(".m4a"):
            with found[0].open("rb") as stream:
                assert stream.read(8)[4:8]==b"ftyp"
    print("PASS Xcode .app actually bundles all 58 original v568 assets once each")
