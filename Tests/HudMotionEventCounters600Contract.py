#!/usr/bin/env python3
"""Source-driven PC v600 HUD event telemetry (does not mutate game decisions)."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
game=(root/"ASTEROIDYiOS/CarbonisCombat568.swift").read_text()
session=(root/"ASTEROIDYiOS/CarbonisSession568.swift").read_text()
motion=(root/"ASTEROIDYiOS/HudMotion600.swift").read_text()

assert "private(set) var hudEvents=HUDEvents()" in game
for field in ("shots","hits","pickups"):
    assert f"fileprivate(set) var {field}:Int=0" in game,field
assert game.count("hudEvents.shots += 1")==1,"exactly one event per accepted trigger"
assert game.count("hudEvents.hits += 1")==2,"only real bullet contacts record hit"
assert game.count("hudEvents.pickups += 1")==1,"only original pickup event counts"
trigger=game.split("private mutating func fireSourceWeapon()")[1].split(
    "static func guidedSwarmVelocity(")[0]
assert trigger.index("cooldown=interval") < trigger.index(
    "hudEvents.shots += 1") < trigger.index("for index in 0..<count")
hit=game.split("private mutating func stepShots(dt:Float)")[1]
for marker in ("shooters[j].core.hp-=shot.damage",
               "rocks[j].health-=shot.damage"):
    assert marker in hit
assert "if id==30 {hudEvents.pickups += 1}" in game
assert "if originalAudioEvents568.count<64" in game,"audio queue remains capped"
for prop in ("shots","hits","pickups"):
    assert f"motionSample.{prop}=game.hudEvents.{prop}" in session
assert "motionSample.pickups=max(0,game.collectedLootTokens)" not in session
assert "motionSample.shots=game.bullets.count" not in session
assert "sample.shots>prior.shots" in motion
assert "sample.hits>prior.hits" in motion
assert "sample.pickups>prior.pickups" in motion
print("PASS HUD v600: actual monotonic shot, hit and successful pickup events; no bullet-count fabrication")
