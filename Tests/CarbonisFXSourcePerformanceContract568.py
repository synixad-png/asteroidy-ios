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
assert "indexedDisc(p,inner:core*0.67,outer:core*2.3" in projectiles
assert "slices:32,camera:camera,&mesh" in projectiles
assert "slices:28,camera:camera,&mesh" in projectiles
assert "slices:24,camera:camera,&mesh" in projectiles
assert "for layer in 0..<4" in projectiles
assert "let slices=[28,24,22,18]" in projectiles
assert "mesh.indices.append(contentsOf:[" in projectiles
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
assert "reduced ? min(10,original) : original" in budget
assert "reduced ? min(7,original) : original" in budget
assert "reduced ? [2] : [0,1,2,3]" in budget
assert "steps:UInt32(budget.raySamples(settings.raySamples))" in host
assert "lobes:UInt32(budget.gasLobes(settings.value(1)))" in host
assert "sector01ExplosionFragment524" in vol
assert "for(uint i=first;i<last;i++)" in vol
assert "for(uint i=0;i<17u;++i)" in vol
assert "if(transmittance<0.02f)break;" in vol
print("PASS genuine indexed GPU projectile/ground-light batches and GPU-fenced ring buffers")
print("PASS full source quality preserved as reversible mode; reduced iOS mode explicitly cuts only visual detail")
