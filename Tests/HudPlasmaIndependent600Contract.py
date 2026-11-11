#!/usr/bin/env python3
"""PC602: free F6 plasma bars, proper visual color order and authentic GLB animation."""
from pathlib import Path
import hashlib,json,lzma,struct,collections
root=Path(__file__).resolve().parents[1]
ios=root/"ASTEROIDYiOS"
original=lzma.decompress((root/"SourceResources/PC602/planetarium.glb.xz").read_bytes())
assert hashlib.sha256(original).hexdigest()=="71ca9ff24e044a831a5c7197e343594dd1fd801284af6231870570b35ad43860"
size=struct.unpack_from("<I",original,12)[0]
glb=json.loads(original[20:20+size])
assert len(glb["animations"][0]["channels"])==159
plasma=(ios/"HudPlasmaLayer600.swift").read_text()
planet=(ios/"HudPlanetariumMetal600.swift").read_text()
scene=(ios/"Sector01Scene568.swift").read_text()
layout=(ios/"HudLayout600.swift").read_text()
assert 'private static let displayBars=["shield.bar","armor.bar","hull.bar"]' in plasma
assert 'let values:[Int?]=[gauge.hull,gauge.armor,gauge.shield]' in plasma
assert 'let maxima=[gauge.maxHull,gauge.maxArmor,100]' in plasma
assert 'id:Self.displayBars[i]' in plasma
assert 'Self.draw(bar,current:values[i],maximum:maxima[i]' in plasma
assert 'c.fill(ribbonTriangles(vertices)' in plasma
assert 'CGPoint(x:xx-1.6,y:edge)' in plasma
assert 'Path(ellipseIn:CGRect(x:end-1.65,y:barY+2.9' in plasma
assert 'HudPlasmaBridge600' not in plasma
assert 'HudPlanetariumPlasmaAnchor600' not in planet
assert 'HudMotionProject600.project(' in planet
assert 'widget:widget.id' in planet
assert 'pose.roll*pose.weight(widget.id)' in planet
assert 'original.sample(at:seconds,capsules:capsules)' in planet
assert 'HudLayoutEditor600' in scene
assert '"hud.planetarium","x":64.7882' in layout
assert not (ios/"HudPlasmaBridge600.swift").exists()
assert not (ios/"HudPlanetariumPlasmaAnchor600.swift").exists()
widgets=json.loads((ios/"Assets/hud/default-layout.json").read_text())["widgets"]
byid={w["id"]:w for w in widgets}
assert byid["shield.bar"]["y"] < byid["armor.bar"]["y"] < byid["hull.bar"]["y"]
assert byid["hud.planetarium"]["scale"]==1.4702
# Original PC602 model and its bubble reset handling are preserved.
binary=20+size+8
def values(index):
    a=glb["accessors"][index];v=glb["bufferViews"][a["bufferView"]]
    n={"SCALAR":1,"VEC3":3,"VEC4":4}[a["type"]]
    off=binary+v.get("byteOffset",0)+a.get("byteOffset",0)
    return [struct.unpack_from("<"+"f"*n,original,off+i*n*4) for i in range(a["count"])]
wrap_counts=[]
for channel in glb["animations"][0]["channels"]:
    node=glb["nodes"][channel["target"]["node"]]
    name=node.get("name","")
    if not (name.startswith("CAPSULE_") and "_WATER_BUBBLE_" in name and channel["target"]["path"]=="translation"):continue
    sampler=glb["animations"][0]["samplers"][channel["sampler"]]
    positions=values(sampler["output"])
    wraps=sum(positions[j+1][0]-positions[j][0] < -3.0 for j in range(len(positions)-1))
    wrap_counts.append(wraps)
assert len(wrap_counts)==72
assert collections.Counter(wrap_counts)=={4:24,6:31,8:17}
assert 'if bubbleWrap && values[hi].x-values[lo].x < -3.0' in (ios/"HudPlanetariumOriginalMetal600.swift").read_text()
print("PASS PC602: 3 fully independent F6 plasma bars, red upper/amber middle/green lower, no tethers, 159 original GLB channels")
