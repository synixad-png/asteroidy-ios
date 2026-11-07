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
# Verify two INDEPENDENT implementations: the original Windows
# GpuPlanet.cs:207-220 iterates *BGRA integer bytes*, while the
# Metal compute pipeline evaluates RGB Float vectors. Previously
# the test called the same Python function twice, which proved nothing.
rng=random.Random(469)
def source_windows_bgra(base_bgr,emission_bgr,near_bgr,strength):
    """Direct translation of GpuPlanet.cs:207-220, original PArgb bytes."""
    strength=min(4.,max(0.,strength))
    heat=max(emission_bgr)/255.
    mask=min(1.,max(0.,(heat-.12)/.34))
    mask=mask*mask*(3.-2.*mask)
    irradiance=min(1.,strength*.45)
    result=[]
    for j in range(3):
        emission=emission_bgr[j]/255.*strength*mask
        reflected=near_bgr[j]/255.*irradiance*.38
        multiplier=1. if j==2 else (.8 if j==1 else .5)
        value=base_bgr[j]/255.+emission*multiplier+reflected
        result.append(max(0,min(255,int(value*255.+.5))))
    return result

def metal_baked_rgb(base_rgb,emission_rgb,near_rgb,strength):
    """Independent float4 expression from CarbonisCombined469Bake.metal."""
    strength=min(4.,max(0.,strength))
    high=max(emission_rgb)
    fraction=max(0.,min(1.,(high-.12)/(.46-.12)))
    smooth=fraction*fraction*(3.-2.*fraction)
    light=min(1.,strength*.45)*.38
    weights=(1.,.8,.5)
    result=(
        min(1.,max(0.,base_rgb[0]+emission_rgb[0]*strength*smooth*weights[0]+near_rgb[0]*light)),
        min(1.,max(0.,base_rgb[1]+emission_rgb[1]*strength*smooth*weights[1]+near_rgb[1]*light)),
        min(1.,max(0.,base_rgb[2]+emission_rgb[2]*strength*smooth*weights[2]+near_rgb[2]*light))
    )
    return [min(255,max(0,int(x*255.+.5))) for x in result]

samples=0
max_delta=0
for boost in [0.,.2,1.,1.8,4.]:
    for _ in range(2000):
        base=[rng.randrange(256) for _ in range(3)]  # B,G,R
        emission=[rng.randrange(256) for _ in range(3)]
        irradiance=[rng.randrange(256) for _ in range(3)]
        reference=source_windows_bgra(base,emission,irradiance,boost)
        result=metal_baked_rgb(
            [v/255. for v in base[::-1]],
            [v/255. for v in emission[::-1]],
            [v/255. for v in irradiance[::-1]],boost)[::-1]
        max_delta=max(max_delta,max(abs(a-b) for a,b in zip(reference,result)))
        samples+=1
assert samples==10000
assert max_delta<=1,("source vs Metal channel blend",max_delta)
assert "address::clamp_to_edge" in bake, "source irradiance resize must not wrap 1024x512 edges"
assert "rebakeCarbonis469(newLava.intensity)" in host
assert "if newLava != lava287" in host
assert "carbonisBakePipeline469=bakeState" in host
print("PASS source Windows BGRA byte formula vs independent Metal RGB vector formula: 10000 RGB vectors, max channel byte delta",max_delta)
print("PASS 3 original maps baked once and only on brightness change, one texture fetch per planet pixel")
print("LIMIT: no actual iOS GPU render comparison or device FPS timing")
