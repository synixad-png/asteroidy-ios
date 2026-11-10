import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
p = root / "ASTEROIDYiOS/Assets/hud/default-layout.json"
data = json.loads(p.read_text(encoding="utf-8"))
widgets = data["widgets"]
assert data["schema"] == 1
assert len(widgets) == 46, len(widgets)
ids = [w["id"] for w in widgets]
assert len(set(ids)) == 46, "duplicate HUD IDs"
assert all(w["visible"] and w["scale"] > 0 for w in widgets)
planet = next(w for w in widgets if w["id"] == "hud.planetarium")
assert (planet["x"],planet["y"],planet["scale"],planet["pitch"]) == (
    64.7882,553.0863,1.4702,-20)
assert planet["glb"] == "planetarium"
for wid,model in (
    ("ion.icon","energy"),("bomb.icon","bomb"),
    ("shield_charge.icon","shield"),("boost.icon","boost")):
    assert next(w for w in widgets if w["id"] == wid)["glb"] == model
hud = (root / "ASTEROIDYiOS/SourceCombatHUD331.swift").read_text()
assert "HudEnergy600.ribbon(" in hud
for label, style in (("KADŁUB",0),("PANCERZ",1),("TARCZA",2)):
    assert f'"{label}"' in hud
    assert f",{style},Double(hud.seconds))" in hud
assert "let n=14" not in hud, "segmented status bars must be replaced"
motion = (root / "ASTEROIDYiOS/HudMotion600.swift").read_text()
for marker in ("leftSway = 400", "rightSway = 400",
               "func update(", "func weight(", "let settle:Float"):
    assert marker in motion
session = (root / "ASTEROIDYiOS/CarbonisSession568.swift").read_text()
scene = (root / "ASTEROIDYiOS/Sector01Scene568.swift").read_text()
panel = (root / "ASTEROIDYiOS/HudMotionSettingsPanel600.swift").read_text()
for marker in ("motionSample.turnRate=game.flight.flight.angularVelocity",
               "motionSample.bank=game.flight.flight.visualBank",
               "motionSample.pitch=game.flight.flight.visualPitch",
               "motionSample.hull=Float(game.hull)",
               "motionSample.armor=Float(game.armor)",
               "motionSample.shield=game.tarcza145.energy",
               "snapshot.motion=hudPose600"):
    assert marker in session, marker
for marker in ("Self.applyMotion(&topLeft", "Self.applyMotion(&topRight",
               "Self.applyMotion(&bottomLeft", "Self.applyMotion(&bottomRight"):
    assert marker in hud, marker
assert "session.applyHudMotion600(settings)" in scene
assert "HudMotionSettingsPanel600" in scene
for marker in ("\\.strength", "\\.inertia", "\\.impact", "\\.leftSway",
               "\\.rightSway", "settings.parallax", "settings.reactions",
               "settings.profile"):
    assert marker in panel, marker
print("PASS PC v600 HUD: 46 layout, placement, source status ribbons and motion contracts")
