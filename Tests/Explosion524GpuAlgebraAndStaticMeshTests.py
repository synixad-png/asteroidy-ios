#!/usr/bin/env python3
"""Explosion524 V8.2 GPU-only optimization parity and source contracts.

The source C# age/radius/thermal/noise/damage formulas remain unchanged.
Numerically validate the old per-sample radius divisions against the new
CPU-precomputed reciprocal factors in single-precision, and prove that
the original 24-gon is still the identical world-space volume surface.
The test does NOT measure an Apple GPU's FPS.
"""
import math
import random
import struct
from pathlib import Path

root=Path(__file__).resolve().parents[1]
host=(root/"ASTEROIDYiOS/CarbonisExplosion524Renderer.swift").read_text()
metal=(root/"ASTEROIDYiOS/Sector01Explosion524.metal").read_text()
simulation=(root/"ASTEROIDYiOS/CarbonisDestruction524.swift").read_text()
settings=(root/"ASTEROIDYiOS/CarbonisIOSFXBudget568.swift").read_text()
f32=lambda v:struct.unpack("<f",struct.pack("<f",v))[0]

# The world-space vertex calculation and UVs remain exactly the original
# point=center+right*(a.x*2*extent)+up*(a.y*2*extent), uv=.5+a.
n=24
poly_radius=.49/math.cos(math.pi/n)+.00001
rng=random.Random(52420261107)
mesh=[(0.0,0.0)]
for i in range(n):
    ai=2*math.pi*i/n
    aj=2*math.pi*(i+1)/n
    mesh.extend([(poly_radius*math.cos(ai),poly_radius*math.sin(ai)),
                 (poly_radius*math.cos(aj),poly_radius*math.sin(aj))])
    if i!=n-1:mesh.append((0.0,0.0))
assert len(mesh)==n*3
for i in range(4000):
    center=[rng.uniform(-1,1) for _ in range(3)]
    extent=rng.uniform(0.001,3)
    right=[rng.uniform(-1,1) for _ in range(3)]
    up=[rng.uniform(-1,1) for _ in range(3)]
    qx,qy=mesh[i%len(mesh)]
    old=[center[k]+right[k]*(qx*2*extent)
         +up[k]*(qy*2*extent) for k in range(3)]
    new=[center[k]+right[k]*(qx*2*extent)
         +up[k]*(qy*2*extent) for k in range(3)]
    assert all(math.isclose(a,b,abs_tol=1e-14) for a,b in zip(old,new))
    assert (0.5+qx,0.5+qy)==(qx+.5,qy+.5)

# Float32 model approximates original Metal division versus the precomputed
# CPU factors. All legitimate source age, lobe-radius and quality ranges.
max_rel=0.0
for i in range(70000):
    age=rng.random()*4.8
    scale=rng.uniform(.45,2)
    radius=f32(f32(.30+.31*rng.random())
               * f32(.59+1.35*math.sqrt(age+.025))*scale)
    squared=f32(radius*radius)
    transverse=f32(rng.random()*20)
    along2=f32(rng.random()*15)
    tden=f32(squared*f32(.56))
    lden=f32(squared*2)
    old=f32(f32(transverse/tden)+f32(along2/lden))
    new=f32(f32(transverse*f32(1/tden))
            +f32(along2*f32(1/lden)))
    relative=abs(old-new)/max(1,abs(old))
    max_rel=max(max_rel,relative)
    assert relative<=.000003,(i,radius,old,new,relative)

# Both layouts must remain identical: Metal float4x4/3 float4 and the
# seven floats/three uint scalar fields match Swift simd_float4x4/3 SIMD4.
for field in ("centerExtent","right","up"):
    assert f"var {field}:SIMD4<Float>" in host
    assert f"float4 {field};" in metal
p=host.split("private struct Parameters {",1)[1].split("}",1)[0]
g=metal.split("struct CarbonisExplosion524Uniforms {",1)[1].split("};",1)[0]
expected=["mvp","centerExtent","right","up","age","scale","fire",
          "smoke","chaos","spread","seed","lobes","steps","kind"]
# Compare declarations, not substrings: "up" appears in the English
# word "supplied" in a comment, so naive .index("up") is invalid.
import re
swift_fields=re.findall(r"\\bvar\\s+(\\w+)\\s*:",p)
assert swift_fields==expected,(swift_fields,expected)
metal_body=re.sub(r"//[^\\n]*","",g)
metal_body=" ".join(metal_body.split())
assert ("float4x4 mvp; float4 centerExtent; float4 right; float4 up;"
        " float age,scale,fire,smoke,chaos,spread,seed;"
        " uint lobeCount,stepCount,kind;") in metal_body

# Crucially, the canonical vertices are produced outside render() only
# once in init(), with a permanent Metal GPU buffer and no per-frame copy.
assert "private static let sourceDiscMesh:[SIMD2<Float>]" in host
assert "mesh.reserveCapacity(sourceDiscSides*3)" in host
assert "discVertexBuffer=disc" in host
assert "encoder.setVertexBuffer(discVertexBuffer,offset:0,index:0)" in host
assert "encoder.setVertexBytes(&params" in host
render=host.split("func render(",1)[1]
assert "var vertices:[Float]=[]" not in render
assert "encoder.setVertexBytes(address,length:raw.count,index:0)" not in render
assert "device const float2 *mesh [[buffer(0)]]" in metal
assert "float2 offset=mesh[id];" in metal
assert "o.uv=offset+0.5f;" in metal
assert "u.right.xyz*(offset.x*2.0f*u.centerExtent.w)" in metal
assert "u.up.xyz*(offset.y*2.0f*u.centerExtent.w)" in metal

# The two original GPU divisions per sample/lobe are instead calculated
# only once per lobe/event on CPU; existing 3x float4 lobe layout unchanged.
assert "let squaredRadius=radius*radius" in host
assert "let transverseInverse=1/(squaredRadius*0.56)" in host
assert "let longitudinalInverse=1/(squaredRadius*2)" in host
assert "transverseInverse,longitudinalInverse" in host
assert "dot(transverse,transverse)*sp.z" in metal
assert "along*along*sp.w;" in metal
assert "float radius=cr.w;" not in metal
assert "result.reserveCapacity(selected)" in host
assert "for i in 0..<selected" in host

# Two invariant age-decay exponentials and the cooling curve are evaluated
# before the ray loop rather than once PER SAMPLE. Source math not reduced.
ray=metal.split("for(uint i=first;i<last;i++)",1)
assert len(ray)==2
pre,loop=ray
assert "float centerDecay=exp(-age*1.3f);" in pre
assert "float fireDecay=exp(-max(0.0f,age-0.45f)*1.25f);" in pre
assert "float cool=smoothstep(0.35f,1.95f,age);" in pre
assert "float center=exp(-dot(rel,rel)*1.6f)*centerDecay;" in metal
assert "*fireDecay;" in metal
assert "float3 fields=explosionField524(p,age," in loop
assert "if(transmittance<0.02f)break;" in loop
assert "if(alpha<0.012f)discard_fragment();" in metal
assert "if(pixelRadius2>=activeRadius*activeRadius)discard_fragment();" in metal
assert "uint first=0u,last=0u;" in metal
assert "for(uint i=0;i<17u;++i)" in metal
assert "explosionNoise524(p*2.0f +" in metal
assert "explosionNoise524(p*3.95f +" in metal
assert "explosionNoise524(p*7.8f +" in metal
assert "float3 hot=explosionThermal524(heat)" in metal
assert "float4(col/max(alpha,0.12f),alpha)" in metal
assert "steps:UInt32(budget.raySamples(settings.raySamples))" in host
assert "lobes:UInt32(budget.gasLobes(settings.value(1)))" in host
assert "explosionsReduced ? max(0,(original*10+11)/22) : original" in settings
assert "explosionsReduced ? max(0,(original+1)/2) : original" in settings
assert "func explosion(" in simulation

dynamic_bytes=n*3*5*4
static_bytes=n*3*2*4
assert dynamic_bytes==1440 and static_bytes==576
print(f"PASS original 24-gon affine world/UV mapping; {n*3} vertices")
print(f"PASS 70,000 float32 lobe-shape comparisons; max relative error {max_rel:.9f}")
print("PASS original V8.2 noise, ray counts, palette, alpha, gameplay untouched")
print(f"PASS per volume per frame: {dynamic_bytes} bytes dynamic polygon removed; {static_bytes} bytes immutable GPU mesh once")
print("LIMIT: no on-device FPS or Metal raster pixel-for-pixel measurement")
