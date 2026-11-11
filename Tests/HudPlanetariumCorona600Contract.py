#!/usr/bin/env python3
"""The PC602 corona reference remains source-authored; do not claim parity
until the 2D effect is rendered by native Metal and tested on device."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
source=(root/"ASTEROIDYiOS/HudPlanetariumCorona600.swift").read_text()
metal=(root/"ASTEROIDYiOS/HudPlanetariumMetal600.swift").read_text()
# Source reference retained for a later source-faithful Metal corona pass:
for s in ("SPHERE_OUTER_DOTTED_SKIN","originalSphereRadius:Float = 2.1958",
          "start:-45,sweep:172,thickness:3.6","start:149,sweep:152,thickness:3.1",
          "for i in 0..<flames.count","3.0+6.5*pulse"):
    assert s in source,s
# Unlike before, no unattached SceneKit corona is passed off as rendered.
assert "HudPlanetariumCorona600(" not in metal
print("PASS source regression: PC602 corona reference retained; native Metal corona remains unimplemented")
