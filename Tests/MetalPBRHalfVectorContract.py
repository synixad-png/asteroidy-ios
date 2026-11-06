#!/usr/bin/env python3
"""Numerical/structural safety regression of the original iOS PBR BRDF.

Does NOT certify pixel parity or GPU execution on a physical Apple device.
"""
from pathlib import Path
import math

shader=Path("ASTEROIDYiOS/Ship.metal").read_text(encoding="utf-8")
frag=shader.split("fragment float4 sceneFragment(",1)[1].split("// Windows/src/GpuShip.cs",1)[0]
assert "const float3 sumVL = V + L;" in frag
assert "const float sumVL2 = dot(sumVL,sumVL);" in frag
assert "sumVL2 > 1.0e-10f" in frag
assert "sumVL * rsqrt(sumVL2) : N" in frag
assert "const float3 H = normalize(V + L);" not in frag
assert "const float roughness = clamp(in.material.y, 0.04, 1.0);" in frag
assert "const float coat = clamp(in.material.z, 0.0, 1.0);" in frag

def norm(v):
    d=math.sqrt(sum(x*x for x in v))
    return [x/d for x in v]

L=norm((0.48,0.68,0.56))
N=norm((0.1,0.9,0.2))
for delta in (0,1e-9,1e-7,1e-5,1e-3,0.02,1):
    V=norm(tuple(-x for x in L[:2])+( -L[2]+delta,))
    half=[V[i]+L[i] for i in range(3)]
    squared=sum(x*x for x in half)
    H=[x/math.sqrt(squared) for x in half] if squared>1e-10 else N
    assert all(math.isfinite(x) for x in H),f"NaN halfway vector at {delta}"
    assert abs(sum(x*x for x in H)-1)<1e-5
assert "float4(clamp(shaded * coatAttenuation + coatSpecular" in frag
print("PASS: PBR halfway-vector safety for opposing and nearby view/light directions")
print("LIMIT: numeric source regression only; Apple Metal GPU and visual tests pending")
