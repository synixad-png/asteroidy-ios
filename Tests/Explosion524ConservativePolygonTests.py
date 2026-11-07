#!/usr/bin/env python3
"""Prove new indexed 24-gon explosion quad covers all source-visible pixels.

The source bound shader stops all volume opacity at r>=.98*bound.
Outside r>=.98*bound the source flash alpha is below .012 for every
original size slider 45..170% and fire max 200%. No quality change.
This is a geometric (not physical-device FPS) performance test.
"""
import math,random,pathlib
rng=random.Random(52469)
N=24
r=.49/math.cos(math.pi/N)+.00001
def inside_convex_polygon(x,y):
    for k in range(N):
        a=2*math.pi*k/N;b=2*math.pi*(k+1)/N
        ax=r*math.cos(a);ay=r*math.sin(a)
        bx=r*math.cos(b);by=r*math.sin(b)
        cross=(bx-ax)*(y-ay)-(by-ay)*(x-ax)
        if cross < -1e-8:return False
    return True
samples=0
for _ in range(250000):
    a=rng.random()*2*math.pi
    rho=.49*math.sqrt(rng.random())
    x,y=rho*math.cos(a),rho*math.sin(a)
    assert inside_convex_polygon(x,y),"lost nonzero source fragment"
    samples+=1
for source_scale in (.45,.8,1,1.7):
    for spread in (.4,1.25,2):
        for age in (0,.05,.5,1.5,3.0,4.8):
            bound=min(5.1,max(2.6,1.9+age*1.55*spread))*source_scale
            active=bound*.98
            flash=math.exp(-age*24)*2.0*1.25
            far_alpha=flash*math.exp(-active*active*12)*.8
            assert far_alpha<.012,(source_scale,age,far_alpha)
source_square=1.0
polygon_area=N/2 * r*r*math.sin(2*math.pi/N)
fraction_saved=1-polygon_area/source_square
assert .22<fraction_saved<.26,(fraction_saved,polygon_area)
root=pathlib.Path(__file__).resolve().parents[1]
shader=(root/"ASTEROIDYiOS/Sector01Explosion524.metal").read_text()
host=(root/"ASTEROIDYiOS/CarbonisExplosion524Renderer.swift").read_text()
assert "if(pixelRadius2>=activeRadius*activeRadius)discard_fragment();" in shader
assert "float activeRadius=bound*0.98f;" in shader
assert "float reach2=activeRadius*activeRadius-pixelRadius2;" in shader
assert "static let sourceDiscSides=24" in host
assert "vertexCount:Self.sourceDiscSides*3" in host
# The polygon is now immutable and GPU-resident. The vertex shader
# constructs precisely the same camera-facing world points from event
# center/right/up (the previous per-frame CPU pointA formula).
assert "private static let sourceDiscMesh:[SIMD2<Float>]" in host
assert "encoder.setVertexBuffer(discVertexBuffer,offset:0,index:0)" in host
assert "u.right.xyz*(offset.x*2.0f*u.centerExtent.w)" in shader
assert "u.up.xyz*(offset.y*2.0f*u.centerExtent.w)" in shader
assert "o.uv=offset+0.5f;" in shader
print(f"PASS {samples} original source nonzero pixels retained by exact-bound 24-gon")
print(f"PASS source alpha discard proof; {100*fraction_saved:.2f}% fewer raster pixels per large explosion bound")
print("LIMIT: analytical raster-area reduction, NOT a measured device FPS increase")
