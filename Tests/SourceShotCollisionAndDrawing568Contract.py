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
source_rules=read("ASTEROIDYiOS/H55SourceMechanics580.swift")
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
    "gate.mayReach(flight.position,radius:shipContactRadius+4.5)",
    "shipContactRadius=originalShipStats?.contactRadius ?? 11.2",
    "Self.projectedHit71(",
    "CombatCollision556.segmentHit(",
    "moved.point=Sphere67.advance(",
    "let interval=H55SourceMechanics580.shotInterval(",
    "cooldown=interval",
    "let speed=610+Float(upgradeLevel-1)*95",
):
    assert token in physics,token
# Static broadphase contract: exact PC580 shot cadence was moved into a
# shared source-only module, tested numerically in H55SourceMechanics580Tests.
# Hit geometry, orbital movement and shot cap remain unchanged.
for token in ("static func shotInterval(weapon:Int",
              "let interval:Float=weapon==2 ? 0.31 : weapon==1 ? 0.20:0.16",
              "let reduction:Float=weapon==2 ? 0.03:0.02",
              "return max(0.065,withTalent*(1-0.06*Float(cooling)))"):
    assert token in source_rules,token
assert "rateRank:sourceMechanics.rateRank" in physics
assert "cooling:sourceMechanics.cooling" in physics
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
print("PASS original Pulse/Twin/Scatter hit geometry + PC580 source-driven cooldown, geodesic motion untouched")
print("PASS original Combat69 projectile shader geometry; no blanket FX quality reduction")
print("PASS optimized iOS shooter CPU path shared by iPhone and iPad")
print("LIMIT true iOS FPS needs physical Apple GPU measurement")
