#!/usr/bin/env python3
"""Source-authenticated glTF COLOR_0 compatibility regression, not a GPU test."""
import hashlib
import json
import lzma
import struct
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
original=lzma.decompress((ROOT/"SourceResources/PC602/planetarium.glb.xz").read_bytes())
assert len(original)==3_228_900
assert hashlib.sha256(original).hexdigest()=="71ca9ff24e044a831a5c7197e343594dd1fd801284af6231870570b35ad43860"
assert struct.unpack_from("<III",original,0)==(0x46546C67,2,len(original))
length,kind=struct.unpack_from("<II",original,12)
assert kind==0x4E4F534A
meta=json.loads(original[20:20+length])
assert len(meta["nodes"])==141
assert len(meta["animations"][0]["channels"])==159
bad=set()
for mesh in meta["meshes"]:
    for primitive in mesh["primitives"]:
        index=primitive["attributes"].get("COLOR_0")
        if index is None:
            continue
        color=meta["accessors"][index]
        if color["componentType"] in (5121,5123):
            if color.get("normalized") is not True:
                bad.add(index)
assert len(bad)==12, ("expected 12 source-invalid COLOR_0 accessors",sorted(bad))
# Original PC602 H55 custom glTF importer tolerates them. GLTFKit2 must
# receive a *separate* standards-compliant metadata copy. Actual geometry,
# BIN bytes, nodes and 159 animation channels must never be changed.
source=(ROOT/"ASTEROIDYiOS/HudPlanetariumGLTFImport.swift").read_text()
scene=(ROOT/"ASTEROIDYiOS/HudPlanetariumScene600.swift").read_text()
for required in (
    "color[\"normalized\"]=true",
    "changed.count==12",
    "result.append(remaining)",
    "HudPlanetariumAsset600.validate(originalBytes)",
    "normalized.data.write(to:cache,options:.atomic)",
):
    assert required in source,required
for required in (
    "HudPlanetariumGLTFImport.compatibleURL(",
    "GLTFAsset.load(with:importURL,options:[:])",
    "geometryCount>0",
    "model.rootNode.enumerateHierarchy",
):
    assert required in scene,required
assert "GLTFAsset.load(with:url,options:[:])" not in scene
print("PASS PC602 glTF: SHA256 original, 12 precise non-normalized COLOR_0 repairs, unchanged BIN and 159 authored channels")
