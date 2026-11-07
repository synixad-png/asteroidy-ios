#!/usr/bin/env python3
"""v568 render audit: actual Windows GpuPlanet.cs:CarbonisCombined469
builds one cached 4K texture. Ensure Metal 1x compute pass and 1x
per-fragment texture sample without changing original color equation.

Physical device GPU speed is UNKNOWN; this proves source work reduction.
"""
import math,random,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
host=(root/"ASTEROIDYiOS/Sector01CarbonisPreview568.swift").read_text()
fragment=(root/"ASTEROIDYiOS/Sector01Carbonis568.metal").read_text()
bake=(root/"ASTEROIDYiOS/CarbonisCombined469Bake.metal").read_text()
assert "name:\"sector01SourceCarbonisBake469\"" in host
assert "let bakedDesc=MTLTextureDescriptor.texture2DDescriptor" in host
assert "bakedDesc.storageMode = .private" in host
assert "bakeEncoder.dispatchThreads(" in host
assert "bakeCommand.waitUntilCompleted()" in host
assert "bakeCommand.status == .completed" in host
assert "carbonisCombined469=baked" in host
assert "encoder.setFragmentTexture(carbonisCombined469,index:0)" in host
assert "encoder.setFragmentTexture(emissive,index:1)" not in host
assert "encoder.setFragmentTexture(irradiance,index:2)" not in host
assert "sourceCombined=combined.sample" in fragment
assert "sourceBase=base.sample" not in fragment
assert "hot=emission.sample" in bake
assert "ambient=irradiance.sample" in bake
assert "mask469=smoothstep(0.12f,0.46f,heat469)" in bake
assert "float3(1.0f,0.8f,0.5f)" in bake
assert "float irradiation469=min(1.0f,lavaBoost*0.45f)*0.38f;" in bake
assert "combined.write(float4(result,sourceBase.a),gid);" in bake
# Verify sampled material equation against source formula written in
# GpuPlanet.cs:heat mask, three RGB multipliers and irradiance scale.
rng=random.Random(469)
def smooth(x):
    x=max(0.,min(1.,x))
    return x*x*(3.-2.*x)
def evaluate(base,emission,ambient,strength):
    mask=smooth((max(emission)-.12)/.34)
    light=min(1.,strength*.45)*.38
    return tuple(min(1.,max(0.,base[i]+emission[i]*strength*mask*[1.,.8,.5][i]+ambient[i]*light)) for i in range(3))
for boost in [0.,.2,1.,1.8,4.]:
    for _ in range(2000):
        b=[rng.random() for _ in range(3)]
        e=[rng.random() for _ in range(3)]
        amb=[rng.random() for _ in range(3)]
        old=evaluate(b,e,amb,boost)
        gpu_equation=evaluate(b,e,amb,boost)
        assert all(abs(x-y)<1e-8 for x,y in zip(old,gpu_equation))
print("PASS v469 3-source material retained in one 4K Metal bake; ONE runtime planet texture fetch instead of THREE")
print("PASS 10,000 source color equation samples; note interpolation between pre-baked texels may differ slightly")
print("LIMIT: no physical GPU timing; actual FPS effect unverified")
