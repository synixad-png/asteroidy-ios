#!/usr/bin/env python3
"""Regression gate: original v568 scale is visual-only in gameplay and source UI."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def read(path):return (root/path).read_text(encoding="utf-8")
ui=read("ASTEROIDYiOS/CarbonisVisualSettingsPanel568.swift")
main=read("ASTEROIDYiOS/Sector01CarbonisPreview568.swift")
preview=read("ASTEROIDYiOS/MetalRenderer.swift")
scale=read("ASTEROIDYiOS/SourceShipScale472.swift")
for field in ("w3-ship-mission-scale-slider-472","w3-ship-orbit-scale-slider-472",
              "w3-ship-mission-scale-value-472","w3-ship-orbit-scale-value-472"):
    assert field in ui,("missing source ship UI",field)
assert 'tabButton("STATEK",index:5)' in ui
assert 'in:70...150,step:5' in ui and ui.count("in:70...150,step:5")==2
assert "shipScale472.missionFactor" in main
assert "Self.craftModel(session.game.flight) *" in main
assert "mvp:worldView*shipMatrix" in main
assert "mvp:worldView*shipMatrix" in main[main.index("if let enginePipeline=craftEnginePipeline491"):]
assert "Self.scale(shipScale472.missionFactor)" in preview
assert "missionPercent = 100" in scale and "orbitPercent = 100" in scale
assert "static let minimum = 70" in scale and "static let maximum = 150" in scale
assert "var orbitFactor: Float" in scale
# No rewriting of physical collisions: visual GPU matrix only, never GameCore/physics.
assert "ShipContactRadius =" not in main
assert "ShipContactRadius =" not in preview
assert "OrbitShipScale472" not in main  # separate orbit option must not affect CARBONIS mission
print("PASS original v568 ship scale 472: UI, independent defaults, craft/exhaust transform, diagnostic, physical separation")
