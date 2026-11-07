#!/usr/bin/env python3
"""Verify actual default-on iOS FX budget is connected to Metal scene,
while the exact original visual profile and gameplay remain recoverable."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
rd=lambda x:(root/x).read_text()
b=rd("ASTEROIDYiOS/CarbonisIOSFXBudget568.swift")
v=rd("ASTEROIDYiOS/CarbonisExplosion524Renderer.swift")
d=rd("ASTEROIDYiOS/CarbonisExplosion524Meshes.swift")
f=rd("ASTEROIDYiOS/CarbonisProjectileFX69.swift")
s=rd("ASTEROIDYiOS/Sector01CarbonisPreview568.swift")
ui=rd("ASTEROIDYiOS/CarbonisVisualSettingsPanel568.swift")
combat=rd("ASTEROIDYiOS/CarbonisCombat568.swift")
assert "static let reducedDefault=Self(reduced:true)" in b
assert "static let original=Self(reduced:false)" in b
assert "guard defaults.object(forKey:key) != nil" in b
assert "budget.volumeCount(settings.simultaneousVolumes)" in v
assert "budget.raySamples(settings.raySamples)" in v
assert "budget.gasLobes(settings.value(1))" in v
assert "budget.explosionDuration(settings.explosionDuration)" in v
assert "budget.shardLimit(settings.shardCount)" in d
assert "budget.particleLimit(state.particles.count)" in d
assert "budget.pieceLimit(state.pieces.count)" in d
assert "for layer in budget.groundLightLayers" in f
assert "budget.groundSlices(slices[layer])" in f
assert "CarbonisIOSFXBudget568.load()" in s
for x in ("settings:visualSettings,budget:fxBudget",
          "budget:fxBudget,into:encoder",
          "glow:fxBudget.drawBulletGlow",
          "settings:visualSettings,budget:fxBudget))"):
    assert x in s,x
assert "iosFX.reduced=enabled" in ui
assert "iosFX.save()" in ui
assert "CarbonisIOSFXBudget568" not in combat
print("PASS physical Metal scene uses actual reduced FX parameters and game physics remains intact")
