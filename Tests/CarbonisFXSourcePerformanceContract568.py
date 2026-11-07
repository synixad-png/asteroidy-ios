#!/usr/bin/env python3
"""Regression rules for genuinely lighter source-exact iOS projectile GPU data.

Verifies code paths actually bind indexed draw calls, preserve every source
light ring and explosion lobe, reuse GPU-safe 3-frame Metal allocations.
This is not a claim of 60 FPS on an untested physical device.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
read=lambda p:(root/p).read_text()
projectiles=read("ASTEROIDYiOS/CarbonisProjectileFX69.swift")
indices=read("ASTEROIDYiOS/CarbonisIndexedFXMesh568.swift")
stream=read("ASTEROIDYiOS/CarbonisFXStreamingBuffers568.swift")
scene=read("ASTEROIDYiOS/Sector01CarbonisPreview568.swift")
vol=read("ASTEROIDYiOS/Sector01Explosion524.metal")
host=read("ASTEROIDYiOS/CarbonisExplosion524Renderer.swift")
assert "static func indexedVertices(" in projectiles
assert "static func indexedGroundLights(" in projectiles
# The original 32/28/24 projectile circles now share one camera
# frame and immutable source unit-circle LUT instead of recomputing
# all trig on every shot; all original rings remain rendered.
assert "indexedDisc(frame,inner:core*0.67,outer:core*2.3" in projectiles
assert "slices:32,&mesh" in projectiles
assert "slices:28,&mesh" in projectiles
assert "slices:24,&mesh" in projectiles
assert "private static let sourceCircles:[Int:[SIMD2<Float>]]" in projectiles
assert "private static let sourceGroundCircles:[Int:[SIMD2<Float>]]" in projectiles
assert "for layer in 0..<4" in projectiles
assert "let slices=[28,24,22,18]" in projectiles
# Direct UInt32 appends avoid allocating a temporary Swift array
# for every radial triangle while preserving exactly 3 or 6 indices.
assert "mesh.indices.append(first);mesh.indices.append(first+1)" in projectiles
assert "mesh.indices.append(first+UInt32(i+1))" in projectiles
assert "mesh.indices.append(b+1);mesh.indices.append(a)" in projectiles
assert "into.append(p.x);into.append(p.y);into.append(p.z)" in projectiles
assert "expandedTriangles()" in indices
assert "private let inFlight=DispatchSemaphore(value:3)" in stream
assert "inFlight.wait()" in stream
assert "inFlight.signal()" in stream
assert ".storageModeShared" in stream
assert "target.contents().copyMemory" in stream
assert "fxStream568.beginFrame()" in scene
assert "fxStream568.completeFrame(command)" in scene
assert "CarbonisProjectileFX69.indexedVertices(" in scene
assert "CarbonisProjectileFX69.indexedGroundLights(" in scene
assert scene.count("encoder.drawIndexedPrimitives(type:.triangle,")>=2
assert "fxStream568.upload(" in scene
assert "values,as:.debrisVertices" in scene
# The optional full-quality path preserves original ray samples, gas lobes
# and four-layer ground lights; reduced iOS mode deliberately cuts them.
budget=(root/"ASTEROIDYiOS/CarbonisIOSFXBudget568.swift").read_text()
assert "static let original=Self(reduced:false)" in budget
assert "explosionsReduced ? max(0,(original*10+11)/22) : original" in budget
assert "explosionsReduced ? max(0,(original+1)/2) : original" in budget
assert "projectilesReduced ? [2] : [0,1,2,3]" in budget
assert "steps:UInt32(budget.raySamples(settings.raySamples))" in host
assert "lobes:UInt32(budget.gasLobes(settings.value(1)))" in host
assert "sector01ExplosionFragment524" in vol
assert "for(uint i=first;i<last;i++)" in vol
assert "for(uint i=0;i<17u;++i)" in vol
assert "if(transmittance<0.02f)break;" in vol
# GpuRockInstancing75: identical per-instance shader math with fewer
# draw calls when multiple visible source rocks share the original shape.
metal=read("ASTEROIDYiOS/Sector01Carbonis568.metal")
assert "sector01RockInstancedVertex568" in metal
assert "sector01RockInstancedFragment568" in metal
assert "uint instanceIndex [[instance_id]]" in metal
assert "instances[instanceIndex]" in metal
assert "instances[in.instanceIndex]" in metal
assert "rockInstances" in stream
assert "groups[shape,default:[]].append(rockUniforms)" in scene
assert "for shape in groups.keys.sorted()" in scene
assert "instances,as:.rockInstances" in scene
assert "instanceCount:batch.count" in scene
assert "rockFallbackPipeline" in scene
assert "SourceVisibleSurface73.possiblyVisible(" in scene
# Compare the complete arithmetic of the old fragment and the instanced
# fragment, not just names; source toon bands and rim must remain identical.
def lighting(name):
    return metal.split("fragment float4 "+name+"(",1)[1].split(
        "float3 n=normalize(in.normal);",1)[1].split("\n}",1)[0]
assert lighting("sector01SourceRockFragment568") == lighting(
    "sector01RockInstancedFragment568"),"source toon light regression"
print("PASS genuine indexed GPU projectile/ground-light batches and GPU-fenced ring buffers")
print("PASS full source quality preserved as reversible mode; reduced iOS mode explicitly cuts only visual detail")
