#!/usr/bin/env python3
"""Source-faithful B82S decoder for ASTEROIDY v568's campaign boss type 4.

Windows/src/GpuBossGallery82.cs:203-259 selects alien_scout_173.b82
for activeCampaignBoss83==4, reads B82S, 88 parts, 49 frames, 10 clips.
Each part has 10 float32 per GPU vertex (xyz,nxyz,RGBA) followed by
10*49 matrices of 16 float32. Preserve float32 bytes and part boundaries.
This does NOT silently replace or activate a boss in the iOS game.
"""
from pathlib import Path
import argparse
import gzip
import hashlib
import io
import json
import math
import struct
import sys

SHA256_GZIP="2f95d6b1b9631aa0d08a890025e88aaecb8c5429003f47ef5767f15f9bc54385"
MAGIC=b"B82S"
PARTS=88
FRAMES=49
CLIPS=10
VERTEX_FLOATS=10
EXPECTED_VERTICES=339240
EXPECTED_RAW_BYTES=16329648
MAX_RAW_BYTES=18*1024*1024

def checksum(data):
    return hashlib.sha256(data).hexdigest()

def parse_blob(compressed):
    if checksum(compressed)!=SHA256_GZIP:
        raise ValueError("Not the original source v568 alien_scout_173.b82.gz")
    with gzip.GzipFile(fileobj=io.BytesIO(compressed)) as src:
        raw=src.read(MAX_RAW_BYTES+1)
        if len(raw)>MAX_RAW_BYTES or src.read(1):
            raise ValueError("Oversized B82S gzip payload")
    if len(raw)!=EXPECTED_RAW_BYTES or raw[:4]!=MAGIC:
        raise ValueError("B82S header or length mismatch")
    part_count,frame_count,clip_count=struct.unpack_from("<iii",raw,4)
    if (part_count,frame_count,clip_count)!=(PARTS,FRAMES,CLIPS):
        raise ValueError("Wrong original B82S clips or part count")
    offset=16
    gpu=bytearray()
    pose=bytearray()
    table=[]
    for part in range(PARTS):
        if offset+4>len(raw):
            raise ValueError("Truncated B82S part")
        vertices=struct.unpack_from("<i",raw,offset)[0]
        offset+=4
        if not (3<=vertices<=150000) or vertices%3:
            raise ValueError("Invalid B82S triangle vertex count")
        byte_count=vertices*VERTEX_FLOATS*4
        matrix_count=CLIPS*FRAMES*16
        matrix_bytes=matrix_count*4
        if offset+byte_count+matrix_bytes>len(raw):
            raise ValueError("Truncated original geometry/animation")
        vertex_data=raw[offset:offset+byte_count]
        offset+=byte_count
        matrices=raw[offset:offset+matrix_bytes]
        offset+=matrix_bytes
        # Imported geometry and pose values must be finite, never synthesize values.
        for (value,) in struct.iter_unpack("<f",vertex_data):
            if not math.isfinite(value):
                raise ValueError("Nonfinite source vertex float")
        for (value,) in struct.iter_unpack("<f",matrices):
            if not math.isfinite(value):
                raise ValueError("Nonfinite original animation matrix float")
        table.append({
            "index":part,"firstVertex":len(gpu)//40,
            "vertexCount":vertices,
            "firstAnimationByte":len(pose),
            "animationByteCount":matrix_bytes,
            "frames":FRAMES,"clips":CLIPS
        })
        gpu.extend(vertex_data)
        pose.extend(matrices)
    if offset!=len(raw) or len(gpu)//40!=EXPECTED_VERTICES:
        raise ValueError("Unexpected trailing B82S data or wrong source vertex count")
    manifest={
        "source":"ASTEROIDY v568 Windows/src/GpuBossGallery82.cs, boss type 4",
        "asset":"Shared/Assets_Boss82_GZ/alien_scout_173.b82.gz",
        "format":"B82S","floatLayout":"XYZ,normalXYZ,colorRGBA",
        "partCount":PARTS,"clipCount":CLIPS,"framesPerClip":FRAMES,
        "vertexCount":EXPECTED_VERTICES,"triangles":EXPECTED_VERTICES//3,
        "sourceGzipSHA256":SHA256_GZIP,"sourceRawSHA256":checksum(raw),
        "gpuSHA256":checksum(gpu),"animationsSHA256":checksum(pose),
        "gpuBytes":len(gpu),"animationBytes":len(pose),
        "parts":table,
        "runtimeIntegrated":False,
        "note":"Part matrices and vertex packets unchanged; requires original articulated hierarchy for runtime."
    }
    return bytes(gpu),bytes(pose),manifest

def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source",type=Path,required=True)
    parser.add_argument("--out",type=Path,required=True)
    args=parser.parse_args(argv)
    vertices,animation,meta=parse_blob(args.source.read_bytes())
    args.out.mkdir(parents=True,exist_ok=True)
    (args.out/"AlienScout173SourceVertices.bin").write_bytes(vertices)
    (args.out/"AlienScout173SourceAnimation.bin").write_bytes(animation)
    (args.out/"AlienScout173Source.json").write_text(
        json.dumps(meta,sort_keys=True,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({"result":"PASS","parts":PARTS,"vertices":EXPECTED_VERTICES,
        "clips":CLIPS,"frames":FRAMES,"sourceOnly":True},sort_keys=True))

if __name__=="__main__":
    try:raise SystemExit(main())
    except (ValueError,OSError,EOFError,struct.error) as exc:
        print("FAIL B82S: "+str(exc),file=sys.stderr)
        raise SystemExit(1)
