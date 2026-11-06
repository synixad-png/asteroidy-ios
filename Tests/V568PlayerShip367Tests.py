#!/usr/bin/env python3
"""Tests exact v568 PlayerShip363/367 source conversion (NO IPA).
Uses the four separately uploaded, SHA-pinned v568 ZIPs, not lookalike GLBs.
"""
from pathlib import Path
import importlib.util
import hashlib
import math
import struct
import tempfile

ROOT=Path(__file__).resolve().parents[1]
def load(name,path):
    spec=importlib.util.spec_from_file_location(name,ROOT/path)
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

stage=load("v568_stage","Tools/stage_v568_resources.py")
conv=load("player_ship_367","Tools/convert_v568_player_ship367.py")
files=[]
try:
    files,entries,manifest,_=stage.verify_archive_set(ROOT)
    base="PortingResources/v568/Shared/assets/"
    def extract(name):
        z,info=entries[base+name]
        return z.read(info)
    source=extract("player_ship367.mesh.gz")
    texture=extract("player_ship363.base.jpg")
    assert conv.sha(texture)==conv.TEXTURE_SHA256
    gpu,faces,meta=conv.convert(source)
    assert meta["sourceVersion"]==3671
    assert meta["vertexCount"]==599997
    assert meta["triangleCount"]==199999
    assert meta["faceCount"]==13334
    assert len(gpu)==599997*48
    assert len(faces)==13334*36
    assert len(meta["engineCenters"])==2
    assert meta["gpuVerticesSHA256"]=="932b0a9028404562cfd28db4174f51ded5977e23a90c15580566c69f9c41819a"
    assert meta["runtimeIntegrated"] is False
    import gzip
    source_bytes=gzip.decompress(source)
    source_start=8+len(meta["engineCenters"])*12+4
    for index in (0,1,10,2000,599996):
        offset=index*48
        original=struct.unpack_from("<12f",source_bytes,source_start+offset)
        converted=struct.unpack_from("<12f",gpu,offset)
        for axis in range(3):
            assert math.isclose(converted[axis],original[axis]*.714,rel_tol=1e-6,abs_tol=1e-6)
        assert gpu[offset+12:offset+48]==source_bytes[source_start+offset+12:source_start+offset+48]
    assert manifest[base+"player_ship367.mesh.gz"]==conv.MESH_SHA256
    assert manifest[base+"player_ship363.base.jpg"]==conv.TEXTURE_SHA256
    try:
        conv.convert(source[:-1])
    except ValueError:
        pass
    else:
        raise AssertionError("Accepted forged source")
    with tempfile.TemporaryDirectory() as td:
        p=Path(td)
        (p/"source.gz").write_bytes(source)
        (p/"texture.jpg").write_bytes(texture)
        conv.main(["--mesh",str(p/"source.gz"),"--skin",str(p/"texture.jpg"),
                   "--out",str(p/"out")])
        assert (p/"out/PlayerShip367OriginalGPU.bin").read_bytes()==gpu
        assert (p/"out/PlayerShip367OriginalFaces.bin").read_bytes()==faces
finally:
    for archive in files:
        archive.close()
print("PASS original v568 PlayerShip367: 599997 GPU vertices, 2 original engines, 13334 source faces")
print("PASS exact packet UV/normal/colour bytes, XYZ size scale 0.714 and corrupted-source rejection")
print("LIMIT: decode/export proven; rendering in iOS Metal and device visual parity not yet proven")
