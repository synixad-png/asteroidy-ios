#!/usr/bin/env python3
"""Regression contract: original PC609 starter fleet, H55 live swap and W3 new game.

The source is PC609 Windows/src/Campaign37.cs and Hub90.cs. This file is
source-only; a physical iPad UI/GPU test must be reported separately.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "ASTEROIDYiOS"

def read(name):
    return (ROOT / name).read_text(encoding="utf-8")

ui=read("W3MainMenu568.swift")
app=read("App.swift")
start=read("SourceNewGame568.swift")
driver=read("PC602HomeWorldDriver291.swift")
h55=read("H55ScenePage580.swift")
fleet=read("H55WorkshopPanel580.swift")
models=read("H55SourceMechanics580.swift")
kestrel=read("SourceKestrel603.swift")
bastion=read("SourceBastion606.swift")
renderer=read("PC602HomeScene291.swift")
orbit=read("PC602HomeWorldPage291.swift")

# Original Campaign37 ShipType 0/1/2 (all pre-owned), exact physical ratios.
assert 'static let ships=["KESTREL","VANGUARD","BASTION"' in read("H55Workshop580.swift")
for coefficient in (
    "[1.18,1,0.82,", "[1.12,1,0.86,", "[1.12,1,0.84,",
    "[0.94,1,1.08,", "[2.4,3.4,5,",
):
    assert coefficient in models,coefficient
assert "shipType == 0 ? -1 : shipType == 2 ? 1 : 0" in start
assert 'ForEach(0..<3,id:\\.self)' in ui
assert 'newShipType568=type' in ui
assert 'shipType:newShipType568' in ui
assert 'w3-new-ship-' in ui
assert 'w3-new-selected-ship-lives' in ui

# W3 must not silently use the selected ship from an OLD campaign for
# the fresh campaign; H290 preflights original chosen assets first.
assert "choice.shipType==selected" not in app
fresh=app.split("private func startNewGameFromW3",1)[1].split("// Windows Program.cs:",1)[0]
assert "forShip:choice.shipType" in fresh
assert "forShip:choice.shipType)" in fresh
assert "freshMechanics.selectedShip=choice.shipType" in fresh
assert "mechanicsOverride:freshMechanics" in fresh
assert "shopOverride:freshShop" in fresh
assert fresh.index("try homeWorld291.start(") < fresh.index("SourceNewGame568.create(choice)")
assert 'SourceNewGame568.create(choice)' in fresh
assert "homeWorld291.stop()" in fresh
assert 'SourceNewGame568.restoreOrbitProfile61(' in app

# H55 changes the real SceneKit node as soon as HubEquipShip369 accepts
# an owned model, not after another dock/scene reload.
assert "onShipEquipped:{loader.refreshEquippedShip()}" in h55
assert "if modeled {onShipEquipped()}" in fleet
assert "func refreshEquippedShip()" in h55
assert "playerShip?.removeFromParentNode()" in h55
assert "playerShip=nil" in h55
assert 'H55PlayerShip580.make()' in h55

# Both new craft must be validated by their original SHA/mesh/JPEG decoder,
# not merely by testing that a file has the expected name.
assert "SourceKestrel603.load() != nil" in models
assert "SourceBastion606.load() != nil" in models
for content in (kestrel,bastion):
    assert "verifiedBundleAsset" in content
    assert "try? decode(bytes)" in content
    assert 'subdirectory:"Assets"' in content
assert "originalShip(shipType" not in renderer
assert "case originalShip(Int,String)" in renderer
assert "pc602-orbit-renderer-recovery" in orbit

print("PASS PC609 starter fleet 0/1/2, live H55 model swap, independent W3 new game, old-profile protection and renderer recovery")
