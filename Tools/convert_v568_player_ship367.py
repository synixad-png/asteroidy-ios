#!/usr/bin/env python3
"""Convert original ASTEROIDY v568 PlayerShip363/367 gzip mesh into GPU float32 packets.

This is faithful to Windows/src/PlayerShip363.cs: expected binary marker 3671,
engine sockets, twelve-float triangle corners, and face table. The source
StandardSize369=.714 applies ONLY to xyz positions, sockets, and face xyz.
Normals, colors, and UVs stay bitwise identical. This converter does NOT
automatically enable the ship in the iOS runtime.
"""
import argparse
import gzip
import hashlib
import io
import json
import math
from pathlib import Path
import struct
import sys

MESH_SHA256="b7a0229fa1da3bbd22e956d1f2bcda418569d34403185f8ca0f8f7ec355a57f1"
TEXTURE_SHA256="9ed4fe25c25566f40b0ca401185c6280aa219e2ecb186d160ed3254d14eeb111"
STANDARD_SIZE369=0.714
MAX_RAW=32_000_000

def sha(data):
    return hashlib.sha256(data).hexdigest()

def convert(compressed):
    if sha(compressed)!=MESH_SHA256:
        raise ValueError("Wrong v568 original player_ship367.mesh.gz SHA256")
    with gzip.GzipFile(fileobj=io.BytesIO(compressed)) as stream:
        raw=stream.read(MAX_RAW+1)
        if len(raw)>MAX_RAW or stream.read(1):
            raise ValueError("Unbounded gzip payload")
    if len(raw)<16:
        raise ValueError("Truncated source")
    version,engines=struct.unpack_from("<ii",raw)
    if version!=3671 or not (1<=engines<=8):
        raise ValueError("Unexpected source format or engine count")
    pos=8
    sockets=[]
    for _ in range(engines):
        if pos+12>len(raw):raise ValueError("Truncated sockets")
        xyz=struct.unpack_from("<3f",raw,pos);pos+=12
        if not all(map(math.isfinite,xyz)):raise ValueError("Nonfinite socket")
        sockets.append([v*STANDARD_SIZE369 for v in xyz])
    if pos+4>len(raw):raise ValueError("Truncated vertex count")
    floats=struct.unpack_from("<i",raw,pos)[0];pos+=4
    if not (0<floats<=60_000_000 and floats%12==0):
        raise ValueError("Invalid source float count")
    end=pos+floats*4
    if end+4>len(raw):raise ValueError("Truncated vertices")
    source=memoryview(raw)[pos:end]
    gpu=bytearray(len(source))
    for i in range(0,len(source),48):
        xyz=struct.unpack_from("<3f",source,i)
        if not all(map(math.isfinite,xyz)):
            raise ValueError("Nonfinite vertex")
        struct.pack_into("<3f",gpu,i,*(v*STANDARD_SIZE369 for v in xyz))
        gpu[i+12:i+48]=source[i+12:i+48]
    faces=struct.unpack_from("<i",raw,end)[0]
    start=end+4
    if not (0<faces<=200000) or start+faces*36!=len(raw):
        raise ValueError("Face table truncated or trailing source bytes")
    face_stream=bytearray(faces*36)
    for i in range(0,len(face_stream),12):
        xyz=struct.unpack_from("<3f",raw,start+i)
        if not all(map(math.isfinite,xyz)):
            raise ValueError("Nonfinite source face")
        struct.pack_into("<3f",face_stream,i,*(v*STANDARD_SIZE369 for v in xyz))
    info={
        "source":"v568 Windows/src/PlayerShip363.cs",
        "format":"v568.PlayerShip367.GPUVertex12Float.v1",
        "meshSHA256":MESH_SHA256,"textureSHA256":TEXTURE_SHA256,
        "sourceVersion":version,
        "sizeScale":STANDARD_SIZE369,
        "vertexCount":floats//12,
        "triangleCount":floats//36,
        "faceCount":faces,
        "engineCenters":sockets,
        "gpuVertexBytes":len(gpu),
        "gpuVerticesSHA256":sha(gpu),
        "scaledFacesSHA256":sha(face_stream),
        "runtimeIntegrated":False
    }
    return bytes(gpu),bytes(face_stream),info

def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mesh",type=Path,required=True)
    parser.add_argument("--skin",type=Path,required=True)
    parser.add_argument("--out",type=Path,required=True)
    args=parser.parse_args(argv)
    if sha(args.skin.read_bytes())!=TEXTURE_SHA256:
        raise ValueError("Wrong original v568 PlayerShip363 base JPG")
    gpu,faces,info=convert(args.mesh.read_bytes())
    args.out.mkdir(parents=True,exist_ok=True)
    (args.out/"PlayerShip367OriginalGPU.bin").write_bytes(gpu)
    (args.out/"PlayerShip367OriginalFaces.bin").write_bytes(faces)
    (args.out/"PlayerShip367Source.json").write_text(
        json.dumps(info,indent=2,sort_keys=True)+"\n",encoding="utf-8")
    print(json.dumps({"result":"PASS","vertexCount":info["vertexCount"],
         "sourceFaces":info["faceCount"],"gpuSHA256":info["gpuVerticesSHA256"],
         "integratedIntoMetal":False},sort_keys=True))

if __name__=="__main__":
    try:raise SystemExit(main())
    except (OSError,EOFError,ValueError,struct.error) as err:
        print("FAIL: "+str(err),file=sys.stderr)
        raise SystemExit(1)
