#!/usr/bin/env python3
"""PC v600 corona parity guard: no decorative ring around the panel/capsules."""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
corona=(root/"ASTEROIDYiOS/HudPlanetariumCorona600.swift").read_text()
scene=(root/"ASTEROIDYiOS/HudPlanetariumScene600.swift").read_text()
checks={
    'SPHERE_OUTER_DOTTED_SKIN':"exact original outer glTF node",
    'originalSphereRadius:Float = 2.1958':"authored outer sphere radius",
    'start:-45,sweep:172,thickness:3.6':"first original energy arc",
    'start:149,sweep:152,thickness:3.1':"second original energy arc",
    'for i in 0..<flames.count':"11 independently animated rays",
    'let base=(Double(i)+0.35)*Double.pi*2/11':"authored ray orbit seed",
    '0.075*sin(t*0.43+Double(i)*1.41)':"authored irregular motion",
    '3.0+6.5*pulse':"authored source flame reach",
    'index==2 || index==7':"two amber original rays",
    'presentation.convertPosition(':"world-space reference from imported sphere",
    'root.position=center':"sphere-relative center",
    'let factor=radius/100':"globe-relative scaling",
    'geometry(points:':"create geometry only at init",
}
for fragment,meaning in checks.items():
    assert fragment in corona,f"Missing {meaning}: {fragment}"
assert "HudPlanetariumCorona600(scene:rendered,nodes:source.nodes)" in scene
assert "corona?.advance(at:liveGameTime?() ?? 0)" in scene
assert "root.isHidden=true" in corona
routine=corona.split('func advance(at time:TimeInterval)')[1]
for banned in ('SCNGeometry(', 'SCNGeometrySource(', 'Data(contentsOf:',
               'makeTexture(', 'SCNMaterial('):
    assert banned not in routine, f"No per-frame GPU allocation: {banned}"
assert "SPHERE_OUTER_DOTTED_SKIN" not in scene, "single owner for the source node name"
print("PASS PC v600 corona: original globe center/radius, 2 arcs, 11 tongues, exact temporal formulas, no per-frame geometry")
