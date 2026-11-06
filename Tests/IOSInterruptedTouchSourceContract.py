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
assert "if phase != .active { input.releaseHeldControls() }" in s
assert "if visible { input.releaseHeldControls() }" in s
assert ".onEnded { _ in input.shooting = false }" in s
assert ".onEnded { _ in input.tarczaHeld = false }" in s
assert "input.steer = 0; input.thrust = 0" in s
print("PASS: source touch-hold state resets on foreground interruption and campaign overlay")

renderer = Path("ASTEROIDYiOS/MetalRenderer.swift").read_text(encoding="utf-8")
assert "@Published var gameplayPaused = false" in s
assert "input.gameplayPaused = phase != .active || showCampaign" in s
assert "input.gameplayPaused = visible || showMainMenu || scenePhase != .active" in s
assert "let elapsed = input.gameplayPaused ? 0.0 : frameElapsed" in renderer
assert renderer.index("lastTime = now") < renderer.index("let elapsed = input.gameplayPaused")
assert "fixedClock.advance(elapsed:elapsed)" in renderer
assert "introTime41+Float(elapsed)" in renderer
print("PASS: campaign/background pauses simulation and cinematic clock without a catch-up")
print("LIMIT: source contract only; requires native iOS touch interruption test")
