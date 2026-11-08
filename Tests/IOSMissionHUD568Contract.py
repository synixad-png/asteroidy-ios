#!/usr/bin/env python3
"""Contract for real mission HUD state, touch, screen and 60 FPS protections.
Visual equivalence with original PC HUD is NOT claimed without original skin.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
scene=(root/"ASTEROIDYiOS/Sector01Scene568.swift").read_text()
hud=(root/"ASTEROIDYiOS/Sector01MissionHUD568.swift").read_text()
session=(root/"ASTEROIDYiOS/CarbonisSession568.swift").read_text()
game=(root/"ASTEROIDYiOS/CarbonisCombat568.swift").read_text()
audio=(root/"ASTEROIDYiOS/OriginalAudioAV568.swift").read_text()

assert "Sector01MissionHUD568(hud:session.hud,compact:compact)" in scene
assert "let compact=geo.size.height<550" in scene
assert "sector01-live-enemy-radar" in hud
assert "sector01-source-data-mission-hud" in hud
assert "var shieldCharges:Int" in session
assert "shieldCharges=game.shieldCharges" in session
assert "var shieldCharges:Int=0" in game
for field in ("hull", "armor", "lives", "score", "seconds",
              "rocks", "fighters", "collectedTokens", "tokenPickups",
              "hazards", "targets", "shieldCharges"):
    assert "hud."+field in hud, field
for source_value in ('meter("KADŁUB",value:hud.hull,maximum:60',
                     'meter("PANCERZ",value:hud.armor,maximum:25',
                     'stat("TARCZE",String(hud.shieldCharges)'):
    assert source_value in hud,source_value
assert "if now-lastHUD > 0.10" in session, "HUD snapshots stay 10 Hz"
assert "game.step(move:move,aim:aim,shooting:shooting,dt:dt)" in session
assert 'sector01-right-steer-auto-fire' in scene
assert "shooting:true" in scene and "shooting:false" in scene
assert 'Button("PAUZA") {pauseMission568()}' in scene
assert "OriginalShotSFXWorker568()" in audio, "audio 60 FPS fix retained"
assert "allow" not in hud.lower() or "allowsHitTesting(false)" in hud
assert "AVAudioPlayer" not in hud
assert "Timer.scheduledTimer" not in hud
assert "GeometryReader" in hud
print("PASS: live iPhone/iPad mission HUD; shield state, combat input and audio are preserved")
