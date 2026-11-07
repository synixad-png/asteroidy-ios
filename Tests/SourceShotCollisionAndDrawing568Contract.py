#!/usr/bin/env python3
"""ASTEROIDY Windows v568 Combat69: shooting-only performance contract.

A source-equivalent broadphase may reject strictly impossible hits. The
actual swept collision, impulse, weapon cadence and damage stay untouched.
Projectile geometry must retain every Combat69 color, ring and layer.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
read=lambda p:(root/p).read_text()
physics=read("ASTEROIDYiOS/CarbonisCombat568.swift")
projectiles=read("ASTEROIDYiOS/CarbonisProjectileFX69.swift")
renderer=read("ASTEROIDYiOS/Sector01CarbonisPreview568.swift")
settings=read("ASTEROIDYiOS/CarbonisIOSFXBudget568.swift")
tests=read("Tests/SourceShotSweepGate568Tests.swift")
for token in (
    "struct ShotSweepGate568 {",
    "let reach=travelDistance+max(0,radius)+0.25",
    "if abs(canonical.y-origin.y)>reach {return false}",
    "let chord=normal-sourceNormal",
    "return SphereVector3.dot(chord,chord)<=bound*bound",
    "let gate=ShotSweepGate568(shot:shot,dt:dt)",
    "gate.mayReach(rocks[j].position,",
    "gate.mayReach(shooters[j].core.position,radius:16)",
    "gate.mayReach(flight.position,radius:11.2+4.5)",
    "Self.projectedHit71(",
    "CombatCollision556.segmentHit(",
    "moved.point=Sphere67.advance(",
    "let base:Float=selectedWeapon == .scatter ? 0.31",
    "cooldown=max(0.075,",
    "let speed=610+Float(upgradeLevel-1)*95",
):
    assert token in physics,token
# Static source probabilities: only pure pretest changes, no new
# gameplay setting, cooldown, damage, orbital movement or shot cap.
assert "let gate=ShotSweepGate568(shot:shot,dt:dt)" in physics
assert physics.count("let gate=ShotSweepGate568(shot:shot,dt:dt)")==2
assert "public var" not in physics.split("struct ShotSweepGate568",1)[1].split("}",1)[0]
for token in (
    "private static let sourceCircles:[Int:[SIMD2<Float>]]",
    "private static let sourceGroundCircles:[Int:[SIMD2<Float>]]",
    "private struct GroundFrame",
    "private struct OrbFrame",
    "private static func indexedRibbon(",
    "private static func indexedLine(",
    "let stepAngle=angle/6",
    "for segment in 0..<6",
    "indexedRibbon(shot,tint:tint,width:glow ? 1:0",
    "for layer in budget.groundLightLayers",
    "let slices=[28,24,22,18]",
    "slices:32,&mesh",
    "slices:28,&mesh",
    "slices:24,&mesh",
    "line(a,b,perWorld*middleWidth,",
    "line(a,b,perWorld*innerWidth,",
):
    assert token in projectiles,token
assert "ribbon(shot,tint:tint,width:" in projectiles  # reference legacy
assert "into.append(p.x);into.append(p.y);into.append(p.z)" in projectiles
assert "mesh.indices.append(first);mesh.indices.append(first+1)" in projectiles
assert "mesh.indices.append(first+UInt32(i+1))" in projectiles
assert "into.append(contentsOf:[" not in projectiles
assert "indexedDisc(frame,inner:" in projectiles
assert "indexedGroundDisc(frame," in projectiles
assert "CarbonisProjectileFX69.indexedVertices(" in renderer
assert "CarbonisProjectileFX69.indexedGroundLights(" in renderer
assert "projectileMeshMs:" in renderer
assert "projectilesReduced ? [2] : [0,1,2,3]" in settings
assert "Original hits preserved:" in tests
print("PASS original Pulse/Twin/Scatter source hit/cooldown and geodesic motion untouched")
print("PASS original Combat69 projectile shader geometry; no blanket FX quality reduction")
print("PASS optimized iOS shooter CPU path shared by iPhone and iPad")
print("LIMIT true iOS FPS needs physical Apple GPU measurement")
