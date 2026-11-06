#!/usr/bin/env python3
"""Convert the EXACT ASTEROIDY v568 NewHome290 home-planet H290 mesh.

Matches Windows/src/NewHome290.cs byte-for-byte 12-float triangle
corners and the two distinct material groups (terrain/armored shell).
The 512x256 height map is checked but left out of the W3 menu preview.
No approximated sphere or external GLB is substituted.
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

SOURCE_SHA="025a3ad626de24e666bb0c697aa1a8e855401965869ded96f7eee109f0ece278"
BASE_SHA="4987f35cd6f021fd98794f406c641f4853c538a82b10625e6b79e860c8a787c0"
GLOW_SHA="6f1debd175f52b7ce1fbc687e9977597335ee432858d7d6d6e47cf66b5f9aa39"
GPU_SHA="e93a0bbafc9bb50a25726a828ada81f36675bf88d802c5a8f985b89b6dc96c1b"
RAW_SHA="063d27d9ad8f30fb60ad244e902887b7abb7ab8a0fc575777b5d0179d8f2e21d"
COUNTS=((514176,85907),(2448,612))
HEIGHT=(512,256)
RAW_BYTES=6743728
VERTEX_BYTES=24797952

def digest(b):
    return hashlib.sha256(b).hexdigest()

def decode(blob):
    if digest(blob)!=SOURCE_SHA:
        raise ValueError("Not exact original v568 home290.mesh.gz")
    with gzip.GzipFile(fileobj=io.BytesIO(blob)) as stream:
        raw=stream.read(RAW_BYTES+1)
        if len(raw)!=RAW_BYTES or stream.read(1):
            raise ValueError("NewHome290 gzip wrong length")
    if digest(raw)!=RAW_SHA:
        raise ValueError("NewHome290 raw SHA256 mismatch")
    if struct.unpack_from("<Ii",raw,0)!=(0x30393248,2):
        raise ValueError("NewHome290 header must be H290 / 2 materials")
    off=8
    counts=[]
    for _ in range(2):
        counts.append(struct.unpack_from("<ii",raw,off))
        off+=8
    if tuple(counts)!=COUNTS:
        raise ValueError("NewHome290 original part counts mismatch")
    groups=[]
    for count,unique in counts:
        n=unique*12*4
        groups.append(memoryview(raw)[off:off+n])
        off+=n
    vertices=bytearray(VERTEX_BYTES)
    group_offsets=[]
    cursor=0
    for k,(count,unique) in enumerate(counts):
        group_offsets.append({"group":k,"firstVertex":cursor//48,
                              "vertexCount":count,"material":"texture+glow" if k==0 else "armored-color"})
        g=groups[k]
        for _ in range(count):
            idx=struct.unpack_from("<I",raw,off)[0]
            off+=4
            if idx>=unique:
                raise ValueError("Out-of-range original NewHome290 GLB index")
            vertices[cursor:cursor+48]=g[idx*48:(idx+1)*48]
            cursor+=48
    if cursor!=VERTEX_BYTES or digest(vertices)!=GPU_SHA:
        raise ValueError("NewHome290 GPU geometry not byte-identical to original")
    width,height=struct.unpack_from("<ii",raw,off)
    off+=8
    if (width,height)!=HEIGHT or off+width*height*4!=len(raw):
        raise ValueError("Missing actual NewHome290 512x256 source height map")
    # Source C# reads finite collision height floats, not needed in menu draw.
    for (height_value,) in struct.iter_unpack("<f",raw[off:]):
        if not math.isfinite(height_value):
            raise ValueError("Nonfinite original source height")
    meta={"source":"Windows/src/NewHome290.cs and GpuW3HomeReal333.cs",
          "asset":"Shared/assets/home290.mesh.gz",
          "format":"H290","vertexFormat":"float32XYZ,normalXYZ,RGBA,UV",
          "groups":group_offsets,"totalVertices":cursor//48,
          "triangleCount":cursor//144,"heightMapWidth":width,
          "heightMapHeight":height,"sourceMeshSHA256":SOURCE_SHA,
          "expandedGPU_SHA256":GPU_SHA,"originalBaseSHA256":BASE_SHA,
          "originalGlowSHA256":GLOW_SHA,
          "renderedInW3":False}
    return bytes(vertices),meta

def main(argv=None):
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--mesh",type=Path,required=True)
    p.add_argument("--base",type=Path,required=True)
    p.add_argument("--glow",type=Path,required=True)
    p.add_argument("--out",type=Path,required=True)
    args=p.parse_args(argv)
    for file,expected in ((args.base,BASE_SHA),(args.glow,GLOW_SHA)):
        if digest(file.read_bytes())!=expected:
            raise ValueError("Wrong source NewHome290 texture: "+file.name)
    data,meta=decode(args.mesh.read_bytes())
    args.out.mkdir(parents=True,exist_ok=True)
    output={
        "W3HomePlanet290OriginalGPU.bin":data,
        "W3HomePlanet290Base.dat":args.base.read_bytes(),
        "W3HomePlanet293Glow.dat":args.glow.read_bytes(),
        "W3HomePlanet290Source.json":(json.dumps(meta,indent=2,sort_keys=True)+"\n").encode()
    }
    for name,blob in output.items():
        path=args.out/name
        if path.exists() and digest(path.read_bytes())!=digest(blob):
            raise ValueError("Existing original W3 planet asset differs: "+name)
        if not path.exists():
            path.write_bytes(blob)
    print(json.dumps({"result":"PASS","vertices":meta["totalVertices"],
        "triangles":meta["triangleCount"],"sourceSHA":SOURCE_SHA,
        "gpuSHA":GPU_SHA,"nativeW3RenderingTested":False},sort_keys=True))

if __name__=="__main__":
    try:raise SystemExit(main())
    except (OSError,ValueError,EOFError,struct.error) as exc:
        print("FAIL NewHome290: "+str(exc),file=sys.stderr)
        raise SystemExit(1)
