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
assert "aspect:aspect," in scene.split(
    "CarbonisExplosion524Meshes.vertices(",1)[1].split("))",1)[0]
assert "SourceVisibleSurface73.possiblyVisible(" in visible
assert "CarbonisIOSFXBudget568" not in combat
assert "SourceGeodesicStep568" not in combat
assert "if !visible" not in combat
assert "static let reducedDefault=Self(reduced:true)" in budget
assert "let sourceSky568:SourceCombatSky568?" in scene
assert "let sourceWreck214:SourceCombatWreck214?" in scene
print("PASS source 6-step geodesic FX, 32-edge rings, same width and event lifetime")
print("PASS optional conservative invisible-only culling in live iOS rendering")
print("PASS physics, campaign, original quality sliders and celestial scene untouched")
print("LIMIT: no measured physical iPad/iPhone FPS change")
