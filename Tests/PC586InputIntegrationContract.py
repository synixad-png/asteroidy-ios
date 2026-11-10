#!/usr/bin/env python3
"""Architectural regression gate for live PC586 60-action input integration.

This is NOT a substitute for native iPhone UI tests or a GPU FPS measurement.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
src=lambda name:(root/"ASTEROIDYiOS"/name).read_text(encoding="utf-8")
controls=src("SourceControls586.swift")
router=src("SourceControlRouter586.swift")
hardware=src("SourceHardwareInput586.swift")
settings=src("SourceControlSettings586.swift")
visual=src("CarbonisVisualSettingsPanel568.swift")
mission=src("Sector01Scene568.swift")
session=src("CarbonisSession568.swift")
hangar=src("H55ScenePage580.swift")
assert "static let actionCount=60" in controls
assert "static let rowCount=65" in controls
assert "case 11,12,59:return .hangar" in controls
assert "static func importPCText" in controls and "importFlight67Text" in controls
assert "case 0...7,9,21,33,34,35,44...47:return .combat" in controls
assert "boundAnalog(33,profile:profile)" in controls
assert "boundAnalog(34,profile:profile)" in controls
assert "case .other:return" in settings or "case .other:return" in visual
assert "LazyVStack(" in settings and "ForEach(0..<SourceControls586.actionCount" in settings
assert "optionTitle(60)" in settings and "optionTitle(64)" in settings
assert "allowsMultipleSelection:true" in settings
assert "SourceControls586.Profile.importPCText" in settings
assert "SourceControls586.Profile.importFlight67Text" in settings
assert "case 2: SourceControlSettings586(compact:compact)" in visual
assert "GCController.controllers()" in hardware and "SourceKeyboardCapture586" in hardware
assert "pressesBegan(" in hardware and "pressesEnded(" in hardware
assert "UIKeyboardHIDUsage" in hardware or "key.keyCode.rawValue" in hardware
assert "GameController" in hardware and "CADisplayLink" not in hardware
assert "SourceHardwareInput586.shared.snapshot()" in hangar
assert "controlRouter586.readHangar(" in hangar
assert "sprint:input.sprintHeld && !showingWorkshop" in hangar
assert "movement.step(dt:dt" in hangar
assert "setMove(forward:Float,right:Float)" in hangar
assert "if input.jumpPressed {jump()}" in hangar
assert "if input.interactPressed {interact()}" in hangar
assert "SourceKeyboardCapture586" in hangar
assert "SourceKeyboardCapture586" in mission
assert "onPauseRequested" in mission
assert "SourceHardwareInput586.shared.clearKeyboard()" in mission
assert "controlRouter586.read(" in session
assert "game.setShieldHeld(touchShieldHeld586 || sourceInput.continuous.shield)" in session
assert "_=useBomb()" in session and "_=useBoost71()" in session
assert "game.step(move:effectiveMove,aim:effectiveAim," in session
assert "effectiveFire=shooting || sourceInput.continuous.shooting" in session
assert "struct SourceControlRouter586" in router
assert "bombPressed:c.bomb && !previousBomb" in router
assert "pausePressed:c.pause && !previousPause" in router
assert "let right:Float = (a(1) ? 1 : 0) - (a(0) ? 1 : 0)" in router
assert "SourceCombatHUD331(hud:session.hud,insets:missionSafeInsets568)" in mission
# H55 existing real physics and session body remain canonical; no new solver.
for forbidden in ("class NewPhysics", "struct DuplicateCombatSim",
                  "WebView", "UIWebView", "Timer.scheduledTimer"):
    assert forbidden not in hardware+router+settings+session+hangar
print("PASS: native W3 65-row settings and real, edge-safe PC586 hardware routing into existing CARBONIS/H55 gameplay")
print("UNTESTED: external hardware keyboard/pad focus on physical iOS device; runtime GPU FPS")
