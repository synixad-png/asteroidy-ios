#!/usr/bin/env python3
"""Structural guard for native PC586 pickup wiring (not a GPU screenshot test)."""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
read=lambda name:(root/name).read_text(encoding="utf-8")
game=read("ASTEROIDYiOS/CarbonisCombat568.swift")
supply=read("ASTEROIDYiOS/SourceCombatSupply586.swift")
registry=read("ASTEROIDYiOS/SourcePickupModels586.swift")
metal=read("ASTEROIDYiOS/Sector01Carbonis568.metal")
renderer=read("ASTEROIDYiOS/Sector01CarbonisPreview568.swift")
models=read("ASTEROIDYiOS/SourcePickupMetal586.swift")
settings=read("ASTEROIDYiOS/SourcePickupVisual586.swift")
menu=read("ASTEROIDYiOS/CarbonisVisualSettingsPanel568.swift")
preparer=read("Tools/prepare_pc586_runtime_resources.py")
ipa=read("Tools/pack_pc586_unsigned_ipa.py")

# Source types are not HUD-only stand-ins. There is one physical list and
# only the existing Ammo/Bombs counters are incremented by real collection.
for name in ("sourceKind:SourcePickupModels586.Kind?", "SourceCombatSupply586.collected(",
             "ionAmmo:&ionAmmo,bombs:&bombs", "tryDropCombatSupply586(",
             "dropSourceRockLoot(removed)", "defeatShooter(at:j)",
             "tokenPickups.append(TokenPickup("):
    assert name in game, "Missing physical pickup link: "+name
assert "var combatSupply586=SourceCombatSupply586" in game
assert "random=prepared.encounter.randomState" in game
assert "combatSupply586=SourceCombatSupply586(missionSeed:prepared.combatSupplySeed)" in game
assert "private var random:MissionWave568.SourceRandom" in game
assert "private var random:MissionWave568.SourceRandom" in supply
assert "random.unit()" in supply
assert "currentBombs<3" in supply and "currentIonAmmo<300" in supply
assert "pickupsCount<96" in supply
assert "min(40,max(0,300-ionAmmo))" in supply

# One SHA-locked original for each source kind, and one resident GPU buffer.
for name in ("shield","boost","energy","bomb"):
    assert f"case .{name}" in registry
    assert name+".glb" not in metal  # no fake per-item shader asset lookup
assert "SourcePickupModels586.verifiedBundledURL(kind)" in models
assert "SourcePickupMetal586(kind:kind,device:device,textures:pickupTextures)" not in renderer
assert "kind:kind,device:device,textures:pickupTextures" in renderer
assert "pickupModels586[kind]=loaded" in renderer
assert "encoder.setVertexBuffer(model.triangles" in renderer
assert "encoder.setFragmentTexture(model.skin" in renderer
assert "sector01PickupVertex586" in metal and "sector01PickupFragment586" in metal

# Both iPhone early geometry preparation and iPad fallback filter out
# models drawn by the genuine textured GLB pass (no overdraw/double model).
assert renderer.count("!hasOriginalPickupMesh586($0)") == 2
assert renderer.count("Self.tokenVertices(") == 2
assert "if let prepared=phoneFX {" in renderer
assert "encoder.setCullMode(.none)" in renderer

# Independent source settings really flow into the LIVE rendering uniforms.
assert "SourcePickupVisual586.load()" in renderer
assert "pickupVisual586.visualFactor(kind)" in renderer
assert "glow:pickupVisual586.addedFill" in renderer
for key in ("brightnessPercent","shieldPercent","boostPercent",
            "energyPercent","bombPercent","moneyPercent"):
    assert f"\\.{key}" in menu, "Missing native saved slider: "+key
    assert key in settings
assert "SourcePickupVisual586.load()" in menu

# Source-to-IPA packaging is SHA-locked and fails closed when resources are
# absent. It does not touch H55, H71, 3D HUD or game mechanics.
for path in (preparer,ipa):
    assert "sha" in path.lower() or "digest" in path
    assert "raise ValueError" in path
assert "original.read(path)" in ipa or "original.read(entry)" in ipa
print("PASS PC586: true shared pickup physics, original GLB Metal path, iPhone/iPad fallback, six native settings and strict IPA packer")
print("LIMIT: source-only contract, no physical iPhone/iPad screenshot or GPU timing")
