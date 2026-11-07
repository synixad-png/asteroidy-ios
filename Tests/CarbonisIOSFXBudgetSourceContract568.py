#!/usr/bin/env python3
"""Review verified iOS effects routing against real PC renderer and W3 menu."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
read=lambda x:(root/x).read_text()
budget=read("ASTEROIDYiOS/CarbonisIOSFXBudget568.swift")
volume=read("ASTEROIDYiOS/CarbonisExplosion524Renderer.swift")
mesh=read("ASTEROIDYiOS/CarbonisExplosion524Meshes.swift")
proj=read("ASTEROIDYiOS/CarbonisProjectileFX69.swift")
scene=read("ASTEROIDYiOS/Sector01CarbonisPreview568.swift")
ui=read("ASTEROIDYiOS/CarbonisVisualSettingsPanel568.swift")
preview=read("ASTEROIDYiOS/CarbonisExplosion524Preview568.swift")
combat=read("ASTEROIDYiOS/CarbonisCombat568.swift")
assert "static let original=Self(reduced:false)" in budget
assert "static let reducedDefault=Self(reduced:true)" in budget
assert "static let explosionKey=" in budget and "static let projectileKey=" in budget
assert "defaults.object(forKey:key) as? Bool ?? true" in budget
assert "volumeCount(_ original:Int)" in budget and "(original+2)/3" in budget
assert "raySamples(_ original:Int)" in budget and "(original*10+11)/22" in budget
assert "gasLobes(_ original:Int)" in budget and "(original+1)/2" in budget
assert "explosionDuration(_ original:Float)" in budget and "original*0.45" in budget
assert "budget.volumeCount(settings.simultaneousVolumes)" in volume
assert "budget.raySamples(settings.raySamples)" in volume
assert "budget.gasLobes(settings.value(1))" in volume
assert "budget.explosionDuration(settings.explosionDuration)" in volume
assert "budget.particleLimit(state.particles.count)" in mesh
assert "budget.shardLimit(settings.shardCount)" in mesh
assert "for layer in budget.groundLightLayers" in proj
assert "budget.groundSlices(slices[layer])" in proj
assert "CarbonisIOSFXBudget568.load()" in scene
assert "nextVisualReload=now+0.25" in scene
assert "visualSettings=CarbonisVisualSettings568.load()" in scene
assert "fxBudget=CarbonisIOSFXBudget568.load()" in scene
assert "budget:fxBudget,into:encoder" in scene
assert "glow:fxBudget.drawBulletGlow" in scene
assert "settings:visualSettings,budget:fxBudget))" in scene
assert "budget:iosFX" in ui
assert "budget:budget,into:encoder" in preview
# No combined toggle left in GRAFIKA. Each section owns its own option.
graphics=ui.split("private var sourceGraphicsPage:some View {")[1].split(
    "private var unavailableSourceCategory:some View {")[0]
explosions=ui.split("private var explosionPage:some View {")[1].split(
    "private func explosionValue")[0]
projectiles=ui.split("private var projectilePage:some View {")[1].split(
    "private var planetPage")[0]
assert "iosFX" not in graphics, "no extra effect controls in GRAFIKA"
assert "ios-explosions-reduced" in explosions and "ios-projectiles-reduced" not in explosions
assert "ios-projectiles-reduced" in projectiles and "ios-explosions-reduced" not in projectiles
assert "iosFX.explosionsReduced=enabled" in ui
assert "iosFX.projectilesReduced=enabled" in ui
assert "CarbonisIOSFXBudget568" not in combat
print("PASS W3 category ownership, real renderer + Metal preview consume live iOS budgets; original physics unchanged")
