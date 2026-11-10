#!/usr/bin/env python3
"""PC v600 available mission status only; do not fake 25 missing iOS sectors."""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
hud=(root/"ASTEROIDYiOS/SourceCombatHUD331.swift").read_text()
gate=(root/"ASTEROIDYiOS/HudMissionGate600.swift").read_text()
combat=(root/"ASTEROIDYiOS/CarbonisCombat568.swift").read_text()
session=(root/"ASTEROIDYiOS/CarbonisSession568.swift").read_text()
assert "HudMissionGate600.nextMessage(" in hud
assert "remainingRocks:hud.rocks" in hud and "remainingFighters:hud.fighters" in hud
assert 'id:"mission.next",baseX:410,baseY:310' in hud
assert "hud.phase == .playing" in hud
assert '"OCZYSZCZONA ORBITA"' in gate
assert "remainingRocks==0,remainingFighters==0" in gate
assert "guard playing" in gate
assert "rocks=game.rocks.count;fighters=game.shooters.count" in session
assert "enum Phase: Equatable { case playing, victory, defeat }" in combat
for fake in ("BOSS NADLATUJE","COOP P1 / P2","MISSION_BOSS_HP",
             "FAKE_BOSS","FAKE_OBJECTIVE"):
    assert fake not in hud and fake not in gate,fake
assert '"boss.panel"' not in hud
assert '"coop.status"' not in hud
assert '"flame.bar"' not in hud
assert '"objective.info"' not in hud
print("PASS iOS HUD PC v600: source mission.next only, real actor counts, no invented boss/coop/flame telemetry")
