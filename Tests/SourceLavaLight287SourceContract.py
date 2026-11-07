#!/usr/bin/env python3
"""Source-specific, no-invented-planet-effect guard for Windows v568."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
s=(r/"ASTEROIDYiOS/Sector01Carbonis568.metal").read_text()
c=(r/"ASTEROIDYiOS/Sector01CarbonisPreview568.swift").read_text()
h=(r/"ASTEROIDYiOS/W3HomePlanetMetal568.swift").read_text()
p=(r/"ASTEROIDYiOS/CarbonisVisualSettingsPanel568.swift").read_text()
cfg=(r/"ASTEROIDYiOS/SourceLavaLightSettings287.swift").read_text()
assert "float lavaBoost287;" in s
assert "float heat469=max(max(hot.r,hot.g),hot.b);" in s
assert "smoothstep(0.12f,0.46f,heat469)" in s
assert "float3(1.0f,0.8f,0.5f)" in s
assert "min(1.0f,u.lavaBoost287*0.45f)*0.38f" in s
assert "lit=clamp(albedo.rgb,0.0f,1.0f)" in s
assert "uniforms.lavaBoost287=lava287.intensity" in c
assert "glowPower:lava287.intensity" in h
assert '"RĘKAWICE","PLANETY","BROŃ"' in p and "case 7: planetPage" in p
assert 'case 7:return "w3-effects-tab-3"' in p
assert 'accessibilityIdentifier("w3-planet-lava-brightness-287")' in p
assert "in:0...400,step:5" in p
assert "brightnessPercent: Int = 180" in cfg
# A material-2 ship/asteroid/boss must not inherit planetary lava.
assert "if(u.material==0u)" in s
# Explicitly prohibited feature for this user: do not introduce fireflies.
for path in ("ASTEROIDYiOS/CarbonisVisualSettingsPanel568.swift",
             "ASTEROIDYiOS/SourceLavaLightSettings287.swift"):
    assert "firefly" not in (r/path).read_text().lower()
print("PASS: source Carbonis469 single-pass emissive, source NewHome293 glow, real controls, no fireflies")
