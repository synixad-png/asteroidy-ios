#!/usr/bin/env python3
"""Stage real v568 CARBONIS Level 01 source mesh, UV and textures for native iOS.

Extracts ORIGINAL C279 (Carbonis277.cs) indexed GPU data without geometric
approximation, without a lookalike GLB, and without the 38.9 MB expanded
triangle stream. 137067 unique source 12-float vertices plus 810747 original
uint32 indices = 9.82 MB of actual GPU mesh data. Both source material groups,
all UVs, original height map and textures remain byte-for-byte identical.
"""
from pathlib import Path
import argparse
import gzip
import hashlib
import importlib.util
import json
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
FOLDER = "PortingResources/v568/Shared/assets/"
FILES = {
  "carbonis279.mesh.gz":"27dfc67667b1605b57cfd3146993fecc1c62bbcc38037237fbdd050db16f8d84",
  "carbonis277.base.jpg":"8a9d5d2ad53d1c5bc8681f9ff17b83a3375fb7e16f58a3ed083a9157bcc58424",
  "carbonis277.emissive.png":"cc32669e8e31dbf0942fa0db54fd04582af9bfbd02e7248932a04e7eb78646b3",
  "carbonis288.irradiance.png":"b1cc566768c655e643c450b1eba73cf718765b918e54d7f7a1ac6045d685"
}
RAW_SHA = "2f5a704efb5fb21e196b47f2950be21f157af80157ce2b5a255779cb1a9dc59c"
VERTEX_SHA = "b35318d059b9c4f180d03f36e52a6c4eea1225a484e339d3f117e5df9d7634bd"
INDEX_SHA = "e542a65a0ddf0767d982b573da037becea7872cc8a6e0d5d1e1851cd90730bef"
HEIGHT_SHA = "3ce9a0456d23a5b88de718e7fd8fe6560cb53cd112a31ecc876e6200a762cb39"
GROUPS = (803712,7035)
UNIQUE = 137067
TRIANGLES = 270249

def sha(data):
    return hashlib.sha256(data).hexdigest()

def decode(blob):
    if sha(blob) != FILES["carbonis279.mesh.gz"]:
        raise ValueError("Not the exact original v568 Carbonis C279 mesh")
    raw = gzip.decompress(blob)
    if sha(raw) != RAW_SHA:
        raise ValueError("Unexpected C279 raw source mesh bytes")
    if len(raw) != 10346520 or struct.unpack_from("<II",raw,0) != (0x39373243,2):
        raise ValueError("C279 mesh magic, material count or size mismatch")
    groups = struct.unpack_from("<ii",raw,8)
    unique = struct.unpack_from("<i",raw,16)[0]
    if groups != GROUPS or unique != UNIQUE or sum(groups) != TRIANGLES*3:
        raise ValueError("C279 original vertex and material counts mismatch")
    a=20
    b=a+unique*48
    c=b+sum(groups)*4
    vertices=raw[a:b]
    indices=raw[b:c]
    heights=raw[c:]
    if sha(vertices)!=VERTEX_SHA or sha(indices)!=INDEX_SHA or sha(heights)!=HEIGHT_SHA:
        raise ValueError("C279 original source indexed vertex/UV/height bytes mismatch")
    if struct.unpack_from("<ii",heights,0)!=(512,256):
        raise ValueError("Wrong C279 source 512x256 collision map")
    for (idx,) in struct.iter_unpack("<I",indices):
        if idx>=unique:
            raise ValueError("C279 source index out of range")
    meta={
      "source":"Windows/src/Carbonis277.cs; original v568",
      "level":1,"planet":"CARBONIS / PBR","format":"C279",
      "triangleCount":TRIANGLES,"uniqueVertexCount":UNIQUE,
      "indexedGpuBytes":len(vertices)+len(indices),
      "expandedEquivalentBytes":TRIANGLES*3*48,
      "originalVertexStride":48,"attributes":"float32 XYZ,normalXYZ,RGBA,UV",
      "materialGroups":[
        {"index":0,"firstIndex":0,"indexCount":groups[0]},
        {"index":1,"firstIndex":groups[0],"indexCount":groups[1]}
      ],
      "heightMap":[512,256],
      "sourceMeshSHA256":FILES["carbonis279.mesh.gz"],
      "vertexSHA256":VERTEX_SHA,"indexSHA256":INDEX_SHA,"heightSHA256":HEIGHT_SHA,
      "emissiveSHA256":FILES["carbonis277.emissive.png"],
      "irradianceSHA256":FILES["carbonis288.irradiance.png"],
      "baseSHA256":FILES["carbonis277.base.jpg"],
      "nativeSector01GameplayIntegrated":False
    }
    return vertices,indices,heights,meta

def stage(root,destination):
    spec=importlib.util.spec_from_file_location(
        "v568_archive",ROOT/"Tools/stage_v568_resources.py")
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    streams=[]
    try:
        streams,entries,manifest,_=module.verify_archive_set(root)
        blobs={}
        for name,digest in FILES.items():
            archivepath=FOLDER+name
            z,info=entries[archivepath]
            blob=z.read(info)
            if sha(blob)!=digest or manifest[archivepath]!=digest:
                raise ValueError("Original source C279 asset mismatch: "+name)
            blobs[name]=blob
        vertices,indices,heights,meta=decode(blobs["carbonis279.mesh.gz"])
        out={
          "Sector01CarbonisVertices.bin":vertices,
          "Sector01CarbonisIndices.bin":indices,
          "Sector01CarbonisHeightMap.dat":heights,
          "Sector01CarbonisBase.dat":blobs["carbonis277.base.jpg"],
          "Sector01CarbonisEmissive.dat":blobs["carbonis277.emissive.png"],
          "Sector01CarbonisIrradiance.dat":blobs["carbonis288.irradiance.png"],
          "Sector01CarbonisSource.json":(json.dumps(meta,indent=2,sort_keys=True)+"\n").encode()
        }
        destination.mkdir(parents=True,exist_ok=True)
        for name,blob in out.items():
            path=destination/name
            if path.exists() and sha(path.read_bytes())!=sha(blob):
                raise ValueError("Refusing overwrite different original CARBONIS: "+name)
            if not path.exists():
                path.write_bytes(blob)
        print(json.dumps({"result":"PASS","planet":"CARBONIS","triangles":TRIANGLES,
            "indexedGpuBytes":len(vertices)+len(indices),
            "groups":list(groups) if False else list(GROUPS),
            "sourceGeometryUnchanged":True,
            "nativeMissionPlayable":False},sort_keys=True))
    finally:
        for z in streams:
            z.close()

if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root",type=Path,default=ROOT)
    parser.add_argument("--destination",type=Path,default=ROOT/"ASTEROIDYiOS/Assets")
    args=parser.parse_args()
    try:
        stage(args.root,args.destination)
    except (OSError,ValueError,KeyError,EOFError,struct.error) as exc:
        print("FAIL source v568 Carbonis C279: "+str(exc),file=sys.stderr)
        raise SystemExit(1)
