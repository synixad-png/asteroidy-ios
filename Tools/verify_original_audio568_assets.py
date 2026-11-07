#!/usr/bin/env python3
"""Inspect 43 bundled original SFX/voice/intro assets and reject recorded
music files. The source-native Swift synthesis generates all 15 tracks at run time.
Physical Apple hardware playback remains unverified.
"""
from pathlib import Path
import argparse
import struct

def expected():
    sounds=[f"SFX{code}_{v}.m4a" for code in (*range(10,15),*range(20,23),30) for v in range(3)]
    sounds += [f"SFX{code}_0.m4a" for code in (*range(40,46),60)]
    sounds += [f"Voice{i}.m4a" for i in (0,1,2,3,4,6,7)]
    sounds += ["Intro43.m4a","SYNTH_LICENSES.txt"]
    assert len(sounds)==43 and len(set(sounds))==43
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
assert sorted(x.name for x in root.iterdir() if x.is_file())==sorted(expected()),"unexpected files"
assert not list(root.glob("Music*.m4a")),"Bundled recordings instead of runtime synthesis"
native=Path("ASTEROIDYiOS/OriginalMusicSynth568.swift")
assert native.is_file() and "embeddedZigBase64" in native.read_text() and "static let count=15" in native.read_text()
print("PASS 43 bundled SFX/voice/intro assets; 15 original music tracks generated at runtime (no AAC in IPA)")
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
    assert not list(app.rglob("Music*.m4a")),"Xcode app still contains prerecordings"
    print("PASS Xcode .app bundles 43 audio resources and no prerecorded music")
