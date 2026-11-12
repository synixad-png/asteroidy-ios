#!/usr/bin/env python3
"""Source contract for iOS touch interruption, not an on-device touch test."""
from pathlib import Path
import re
s = Path("ASTEROIDYiOS/App.swift").read_text(encoding="utf-8")
release = re.search(r"func releaseHeldControls\(\) \{([^}]+)\}", s)
assert release, "No centralized held-touch cancellation"
body = release.group(1)
for assignment in ("thrust = 0", "steer = 0", "shooting = false", "tarczaHeld = false"):
    assert assignment in body, f"Interrupted input persists: {assignment}"
assert "@Environment(\\.scenePhase) private var scenePhase" in s
# Both original touch-pad inputs and the separate pre-mission cinematic
# must release held controls. The old single-line exact-string check
# was overly restrictive after the source Intro41 implementation.
assert "if phase != .active {" in s
assert "input.releaseHeldControls()" in s.split(
    "if phase != .active {",1)[1].split("}",1)[0]
assert "missionIntroInput568.releaseHeldControls()" in s.split(
    "if phase != .active {",1)[1].split("}",1)[0]
# Verify actual input cancellation inside the menu visibility branch,
# allowing proper multiline formatting and the new orbital cancel action.
menu_visibility = re.search(r"if\s+visible\s*\{(?P<body>[^}]+)\}",s)
assert menu_visibility, "Missing menu visibility interruption guard"
assert "input.releaseHeldControls()" in menu_visibility.group("body")
assert "homeWorld291.setSuspended(true)" in menu_visibility.group("body")
assert ".onEnded { _ in input.shooting = false }" in s
assert ".onEnded { _ in input.tarczaHeld = false }" in s
assert "input.steer = 0; input.thrust = 0" in s
print("PASS: source touch-hold state resets on foreground interruption and unified W3 menu")

renderer = Path("ASTEROIDYiOS/MetalRenderer.swift").read_text(encoding="utf-8")
assert "@Published var gameplayPaused = false" in s
assert "input.gameplayPaused = phase != .active || showMainMenu" in s
assert "input.gameplayPaused = visible || scenePhase != .active" in s
assert "let elapsed = input.gameplayPaused ? 0.0 : frameElapsed" in renderer
assert renderer.index("lastTime = now") < renderer.index("let elapsed = input.gameplayPaused")
assert "fixedClock.advance(elapsed:elapsed)" in renderer
assert "introTime41+Float(elapsed)" in renderer
print("PASS: W3 menu/background pauses simulation and cinematic clock without a catch-up")
print("LIMIT: source contract only; requires native iOS touch interruption test")

# CARBONIS C279 uses its own session and two invisible half-screen zones.
# Interrupted right-side aiming must never leave the ship firing indefinitely.
sector = Path("ASTEROIDYiOS/Sector01Scene568.swift").read_text(encoding="utf-8")
session = Path("ASTEROIDYiOS/CarbonisSession568.swift").read_text(encoding="utf-8")
assert "SourceCombatTouchZones568(" in sector
assert 'onMove:{session.input(move:$0)}' in sector
assert 'onAim:{session.input(aim:$0)}' in sector
assert 'onFire:{session.input(shooting:$0)}' in sector
touch=Path("ASTEROIDYiOS/SourceCombatTouchZones568.swift").read_text(encoding="utf-8")
assert 'Float(value.translation.width)/110' in touch
assert 'Float(value.translation.width)/100' in touch
assert 'onFire(true)' in touch and 'onFire(false)' in touch
assert 'onMove(Vec2(x:0,y:0))' in touch
assert 'onAim(Vec2(x:0,y:0))' in touch
assert "private var fireGesture" not in sector
assert 'Text("OGIEŃ")' not in sector
assert ".onChange(of:scenePhase)" in sector
assert "session.release()" in sector
assert "if phase != .active" in sector
assert "func release()" in session and "shooting=false" in session
print("PASS: CARBONIS right touch starts sustained fire, drag keeps aiming, lift/background cancels fire; separate left flight unchanged")
print("LIMIT: actual simultaneous two-finger touch requires iPhone/iPad test")
