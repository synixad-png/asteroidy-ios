#!/usr/bin/env python3
"""Golden tests for actual v568 alien scout campaign boss (type 4), B82S."""
from pathlib import Path
import importlib.util
import io
import gzip
import struct

ROOT=Path(__file__).resolve().parents[1]
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,ROOT/path)
    out=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(out)
    return out
stage=module("stagev568scout","Tools/stage_v568_resources.py")
scout=module("decodev568scout","Tools/convert_v568_alien_scout_b82s.py")
archives=[]
try:
    archives,entries,expected,_=stage.verify_archive_set(ROOT)
    path="PortingResources/v568/Shared/Assets_Boss82_GZ/alien_scout_173.b82.gz"
    z,info=entries[path]
    packed=z.read(info)
    assert scout.checksum(packed)==expected[path]==scout.SHA256_GZIP
    source="PortingReferenceCode/v568/Windows/src/GpuBossGallery82.cs"
    zz,ii=entries[source]
    cs=zz.read(ii).decode("utf-8-sig")
    assert 'activeCampaignBoss83==4' in cs
    assert 'scout173?"alien_scout_173.b82"' in cs
    assert 'string expected175=scout173?"B82S"' in cs
    assert 'for(int clip173=0;clip173<clipCount173;clip173++)' in cs
    assert 'part.scoutClips173[clip173][f]=matrix;' in cs
    gpu,poses,meta=scout.parse_blob(packed)
    assert meta["partCount"]==88
    assert meta["vertexCount"]==339240
    assert meta["clipCount"]==10 and meta["framesPerClip"]==49
    assert meta["sourceRawSHA256"]=="59169b3bbb8200f985d4efa836ad94cea47f9523bff6e409e599ecbe3133b8c3"
    assert meta["gpuSHA256"]=="21e602b4db46716ef72e447c09e0c2b8faf083c1872c45af537caf20056d81c3"
    assert meta["animationsSHA256"]=="0ca71aeb3751e65ffe1772129ddb39bc29cd193e5d3ad5edefdf5d0565b9c505"
    assert len(gpu)==13569600 and len(poses)==2759680
    assert sum(p["vertexCount"] for p in meta["parts"])==339240
    assert len(meta["parts"])==88 and all(p["vertexCount"]%3==0 for p in meta["parts"])
    assert meta["runtimeIntegrated"] is False
    raw=gzip.decompress(packed)
    offset=16
    for i,p in enumerate(meta["parts"]):
        assert p["index"]==i
        n=struct.unpack_from("<i",raw,offset)[0]
        assert n==p["vertexCount"]
        offset+=4
        begin=p["firstVertex"]*40
        assert gpu[begin:begin+n*40]==raw[offset:offset+n*40]
        offset+=n*40
        begin=p["firstAnimationByte"]
        amount=p["animationByteCount"]
        assert poses[begin:begin+amount]==raw[offset:offset+amount]
        offset+=amount
    assert offset==len(raw)
    for corrupt in (packed[:-1],packed+b"extra",b"not gzip"):
        try:
            scout.parse_blob(corrupt)
        except ValueError:
            pass
        else:
            raise AssertionError("Wrong or corrupt boss mesh was accepted")
finally:
    for z in archives:z.close()
print("PASS: source-referenced v568 boss type 4 B82S, 88 original rigid parts, 339240 vertices")
print("PASS: all 10 animation clips, 49 frames, exact float32 bytes and golden SHA256")
print("LIMIT: source asset decoder only; animated boss drawing and attack AI not yet ported")
