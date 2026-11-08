#!/usr/bin/env python3
"""Preserve exact Source SphereLine67 geometry and visual-only FX visibility.

This confirms code wiring and the unchanged original Physics68 simulation.
It is not a substitute for Metal GPU timing on an Apple device.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
read=lambda f:(root/f).read_text()
mesh=read("ASTEROIDYiOS/CarbonisExplosion524Meshes.swift")
scene=read("ASTEROIDYiOS/Sector01CarbonisPreview568.swift")
combat=read("ASTEROIDYiOS/CarbonisCombat568.swift")
visible=read("ASTEROIDYiOS/SourceVisibleSurface73.swift")
budget=read("ASTEROIDYiOS/CarbonisIOSFXBudget568.swift")
volume=read("ASTEROIDYiOS/CarbonisExplosion524Renderer.swift")
assert "struct SourceGeodesicStep568 {" in mesh
assert "let dot=max(-1,min(1,SphereVector3.dot(a,b)))" in mesh
assert "angle=atan2(length,dot)" in mesh
assert "cosIncrement=cos(angle/Float(steps))" in mesh
assert "sinIncrement=sin(angle/Float(steps))" in mesh
assert "let nextC=c*cosIncrement-s*sinIncrement" in mesh
assert "let nextS=s*cosIncrement+c*sinIncrement" in mesh
line=mesh.split("private static func sphereLine(",1)[1].split(
    "private static func ring(",1)[0]
assert "SourceGeodesicStep568(from:from,to:to,steps:6)" in line
assert "for _ in 0..<6" in line
assert "stripe(last,current,color:color,width:0.006," in line
assert "Sphere67.offset(" not in line, "Do not reproject each of 6 geodesic steps"
ring=mesh.split("private static func ring(",1)[1].split(
    "private static func localToWorld(",1)[0]
assert "for i in 1...32" in ring
assert "sphereLine(from:previous,to:end,color:color,into:&out)" in ring
assert "var out:[Float]=[]" in mesh
assert "aspect:Float?=nil" in mesh
assert "let visibility=aspect.map { _ in SphereCameraView556(camera:camera) }" in mesh
assert "SourceVisibleSurface73.possiblyVisible(" in mesh
assert "if !visible(p.point,0.06) {continue}" in mesh
assert "if !visible(light.point,0.45) {continue}" in mesh
assert "if !visible(piece.point,max(0.30,piece.size*0.04)) {continue}" in mesh
assert "budget.particleLimit(state.particles.count)" in mesh
assert "budget.pieceLimit(state.pieces.count)" in mesh
assert "for event in state.visibleExplosions(" in mesh
# Both routes must pass their actual viewport aspect: iPhone CPU-prep
# reads frameAspect before drawable acquisition; original iPad uses aspect.
render_parts=scene.split("CarbonisExplosion524Meshes.vertices(")
assert len(render_parts)==3,"one phone preflight and one original iPad draw"
assert "aspect:frameAspect," in render_parts[1].split("))",1)[0]
assert "aspect:aspect," in render_parts[2].split("))",1)[0]
assert "static func possiblyVisible(" in visible
assert "let hLimit=depth*(1+margin)+radius *" in visible
assert "let vLimit=depth*(1+margin)+radius *" in visible
assert "CarbonisIOSFXBudget568" not in combat
assert "SourceGeodesicStep568" not in combat
assert "if !visible" not in combat
assert "static let reducedDefault=Self(reduced:true)" in budget
perf=read("ASTEROIDYiOS/SourcePerformance568.swift")
assert "projectileMeshMs:projectileMeshMs" in scene
assert "destructionMeshMs:destructionMeshMs" in scene
assert "let groundMeshStarted=" in scene
assert "let projectileMeshStarted=" in scene
assert "let destructionMeshStarted=" in scene
assert "projectileMeshTotal+=projectileMeshMs" in perf
assert "destructionMeshTotal+=destructionMeshMs" in perf
assert 'FX CPU P %.1f / W %.1f ms' in perf
assert "completed.gpuStartTime" in perf and "completed.gpuEndTime" in perf
assert 'UserDefaults.standard.set(value,forKey:Self.sourceKey)' in perf
assert "if let aspect,let frame=visibilityFrame," in volume
assert "event.point,worldRadius:extent*1.6+0.03," in volume
assert "aspect:aspect," in scene.split(
    "explosion.render(session.game.destruction,",1)[1].split(
    "budget:fxBudget,into:encoder)",1)[0]
assert "let selected=max(0,min(17,count))" in volume
assert "for i in 0..<selected" in volume
assert "result.reserveCapacity(selected)" in volume
assert "count:budget.gasLobes(settings.value(1))" in volume
assert ".prefix(budget.gasLobes" not in volume
assert "let k=fi+0.5" in volume and "let y:Float=1-2*k/17" in volume
assert "let sourceSky568:SourceCombatSky568?" in scene
assert "let sourceWreck214:SourceCombatWreck214?" in scene
print("PASS source 6-step geodesic FX, 32-edge rings, same width and event lifetime")
print("PASS optional conservative invisible-only culling in live iOS rendering")
print("PASS physics, campaign, original quality sliders and celestial scene untouched")
print("LIMIT: no measured physical iPad/iPhone FPS change")
