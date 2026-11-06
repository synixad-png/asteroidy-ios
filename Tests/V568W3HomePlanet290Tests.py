#!/usr/bin/env python3
"""Golden source-identity tests for W3's actual v568 NewHome290 GLB geometry."""
from pathlib import Path
import importlib.util
import tempfile
import json
import hashlib
import struct

ROOT=Path(__file__).resolve().parents[1]
def load(name,file):
    s=importlib.util.spec_from_file_location(name,ROOT/file)
    m=importlib.util.module_from_spec(s)
    s.loader.exec_module(m)
    return m

archives=load("w3_v568_assets","Tools/stage_v568_resources.py")
converter=load("w3_v568_planet_converter","Tools/convert_v568_w3_home_planet290.py")
packer=load("w3_v568_planet_packer","Tools/prepare_v568_w3_home_planet290.py")
handles=[]
try:
    handles,files,hashes,_=archives.verify_archive_set(ROOT)
    base="PortingResources/v568/Shared/assets/"
    def get(name):
        z,entry=files[base+name]
        return z.read(entry)
    for name,expected in packer.SOURCE.items():
        assert hashes[base+name]==expected
        assert hashlib.sha256(get(name)).hexdigest()==expected
    cs="PortingReferenceCode/v568/Windows/src/NewHome290.cs"
    z,entry=files[cs]
    source=z.read(entry).decode("utf-8-sig")
    assert "internal const int TriangleCount=172208" in source
    assert "internal const int Width=512,Height=256" in source
    assert "0x30393248" in source
    assert "PackedVertices=new float[checked(total*12)]" in source
    assert "Array.Copy(unique[k],(int)ix*12,PackedVertices,(Starts[k]+i)*12,12)" in source
    gpu,meta=converter.decode(get("home290.mesh.gz"))
    assert meta["triangleCount"]==172208 and meta["totalVertices"]==516624
    assert meta["format"]=="H290" and meta["heightMapWidth"]==512
    assert meta["heightMapHeight"]==256
    assert len(gpu)==24_797_952
    assert converter.digest(gpu)==converter.GPU_SHA
    assert [(g["firstVertex"],g["vertexCount"]) for g in meta["groups"]]==[
        (0,514176),(514176,2448)]
    assert all(g["vertexCount"]%3==0 for g in meta["groups"])
    # Sample original decompressed H290 unique vertex/index expansion.
    import gzip
    raw=gzip.decompress(get("home290.mesh.gz"))
    unique0=struct.unpack_from("<i",raw,12)[0]
    unique1=struct.unpack_from("<i",raw,20)[0]
    firstUnique=24
    secondUnique=firstUnique+unique0*48
    indexOff=secondUnique+unique1*48
    indexFirst=struct.unpack_from("<I",raw,indexOff)[0]
    assert gpu[:48]==raw[firstUnique+indexFirst*48:firstUnique+(indexFirst+1)*48]
    with tempfile.TemporaryDirectory() as temp:
        target=Path(temp)/"stage"
        result=packer.stage(ROOT,target)
        assert result["expandedGPU_SHA256"]==converter.GPU_SHA
        assert (target/"W3HomePlanet290OriginalGPU.bin").read_bytes()==gpu
        assert (target/"W3HomePlanet290Base.dat").read_bytes()==get("home290.texture.jpg")
        assert (target/"W3HomePlanet293Glow.dat").read_bytes()==get("home293.glow.png")
        assert (target/"W3HomePlanet290Source.json").is_file()
    try:
        converter.decode(get("home290.mesh.gz")[:-1])
    except ValueError:pass
    else:raise AssertionError("Accepted a modified original v568 NewHome290 mesh")
finally:
    for z in handles:z.close()
print("PASS: 172208 original v568 NewHome290 triangles, 2 GLB groups, H290, 512x256 map")
print("PASS: exact 516624 vertices, 24,797,952 GPU bytes and original JPEG/lava-glow SHA256")
print("LIMIT: exact source geometry and materials, not yet Metal pixel-equivalent lighting")
