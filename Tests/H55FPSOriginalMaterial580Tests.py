#!/usr/bin/env python3
"""Actual original PC580 GLB material rules, not generated test lookalikes."""
from pathlib import Path
import json
import struct
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"Tools"))
from materialize_pc586_original_resources import load_originals

assets=load_originals(Path("SourceResources/PC586"))
def material_names(name):
    raw=assets[name]
    assert raw[:4] == b"glTF"
    size,kind=struct.unpack_from("<I4s",raw,12)
    assert kind == b"JSON"
    scene=json.loads(raw[20:20+size])
    return scene["materials"],scene

tripo,_=material_names("gloves_parted.glb")
monolit,_=material_names("gloves_combined.glb")
gun,_=material_names("EXP01_SOURCE_v601.glb")
assert len(tripo)==1 and tripo[0].get("doubleSided") is True
assert tripo[0].get("alphaMode","OPAQUE")=="OPAQUE"
assert len(monolit)==1 and monolit[0].get("doubleSided") is False
assert monolit[0].get("alphaMode","OPAQUE")=="OPAQUE"
assert len(gun)==25
decals=[m for m in gun if m.get("name","").startswith("DECAL_")]
assert len(decals)==6
assert all(m.get("alphaMode")=="BLEND" and m.get("doubleSided") is True
           for m in decals)
assert all(m.get("alphaMode","OPAQUE")=="OPAQUE"
           for m in gun if m not in decals)
assert all(m.get("doubleSided") is False for m in gun if m not in decals)
print("PASS PC580 glTF: TRIPO double-sided opaque; MONOLIT single-sided opaque;")
print("PASS PC580 EXP-01: 19 source opaque, 6 alpha BLEND decal materials")
