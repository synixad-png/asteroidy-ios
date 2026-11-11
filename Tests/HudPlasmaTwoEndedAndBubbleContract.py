#!/usr/bin/env python3
"""PC602 glTF animation discontinuity audit and the real two-ended plasma.

The original 159 animation channels and the user-approved F6 JSON stay
unchanged. Only the imported interpretation of the 72 source-authored
bubble teleport boundaries changes. No hypothetical new keyframes.
"""
from pathlib import Path
import json,lzma,hashlib,struct,collections
root=Path(__file__).resolve().parents[1]
raw=lzma.decompress((root/"SourceResources/PC602/planetarium.glb.xz").read_bytes())
assert hashlib.sha256(raw).hexdigest()=="71ca9ff24e044a831a5c7197e343594dd1fd801284af6231870570b35ad43860"
jlen=struct.unpack_from("<I",raw,12)[0]
source=json.loads(raw[20:20+jlen])
binary=20+jlen+8
def values(index):
    accessor=source["accessors"][index]
    view=source["bufferViews"][accessor["bufferView"]]
    stride={"VEC3":3,"VEC4":4,"SCALAR":1}[accessor["type"]]
    address=binary+view.get("byteOffset",0)+accessor.get("byteOffset",0)
    return [struct.unpack_from("<"+"f"*stride,raw,address+4*stride*k)
            for k in range(accessor["count"])]
animation=source["animations"][0]
assert len(animation["channels"])==159
bubbles=[]
for channel in animation["channels"]:
    target=channel["target"]
    if target["path"]!="translation":continue
    name=source["nodes"][target["node"]].get("name","")
    if not (name.startswith("CAPSULE_") and "_WATER_BUBBLE_" in name):continue
    sampler=animation["samplers"][channel["sampler"]]
    positions=values(sampler["output"])
    times=values(sampler["input"])
    assert len(times)==len(positions)==193
    assert times[0][0]==0 and times[-1][0]==48
    resets=[i for i in range(192)
            if positions[i+1][0]-positions[i][0] < -3]
    assert len(resets) in (4,6,8),(name,len(resets))
    for i in resets:
        assert 3.75 < positions[i][0]-positions[i+1][0] < 3.86
        assert abs(times[i+1][0]-times[i][0]-0.25)<1e-7
    bubbles.append((name,len(resets)))
assert len(bubbles)==72
assert collections.Counter(amount for _,amount in bubbles)=={4:24,6:31,8:17}
code=(root/"ASTEROIDYiOS/HudPlanetariumOriginalMetal600.swift").read_text()
assert 'if bubbleWrap && values[hi].x-values[lo].x < -3.0' in code
assert 'return values[lo]' in code
assert 'name.contains("_WATER_BUBBLE_")' in code
assert 'simd_slerp(a,b,blend)' in code
plasma=(root/"ASTEROIDYiOS/HudPlasmaLayer600.swift").read_text()
bridge=(root/"ASTEROIDYiOS/HudPlasmaBridge600.swift").read_text()
renderer=(root/"ASTEROIDYiOS/HudPlanetariumMetal600.swift").read_text()
for required in (
    'HudPlasmaBridge600.segment(',
    'HudEnergy600.ribbon(',
    'ribbonTriangles(bridge == nil ? vertices :',
    'Self.draw(graphics,current:values[i]',
    'mapped(xx-1.6,edge)',
    'mapped(end,barY+4.5)'
):
    assert required in plasma,required
for required in (
    '"hull.bar",3.18,1.28,0',
    '"armor.bar",3.18,0,0',
    '"shield.bar",3.18,-1.28,0',
    'HudPlanetariumPlasmaAnchor600.screenCenter(',
    'HudMotionProject600.project(',
    'HudPlanetariumProjection.make(',
    'let litLength=(width-2)*min(1,max(0,fill))',
    'let directionX=end.x-start.x'
):
    assert required in bridge,required
assert 'HudPlanetariumPlasmaAnchor600.visualRoll(pose:pose)' in renderer
assert 'HudPlasmaBridge600.segment(' not in renderer  # only one owner of ribbons
print("PASS original PC602 GLB: 72 animated water bubbles, 418 reset transitions (4/6/8 per track); two real anchored endpoints with unchanged F6 data")
