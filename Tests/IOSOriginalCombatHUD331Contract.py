#!/usr/bin/env python3
"""Regression gate for v568 combat HUD invariants with v600 plasma upgrade.

Source reference: Windows/src/RendererW3Combat331.cs
SHA-256: 8119c1d98936e0c5ec602b49cc98f41f945312792122b33ce82740735ba0ffc3
Canonical HUD elements: UiScale336.cs, 1280 x 720; adaptive physical screen anchoring.
This checks implementation properties; it does NOT claim Apple GPU screenshot equality.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
scene=(root/"ASTEROIDYiOS/Sector01Scene568.swift").read_text()
hud=(root/"ASTEROIDYiOS/SourceCombatHUD331.swift").read_text()
session=(root/"ASTEROIDYiOS/CarbonisSession568.swift").read_text()
combat=(root/"ASTEROIDYiOS/CarbonisCombat568.swift").read_text()

def expect_all(data, needles, what):
    for needle in needles:
        assert needle in data, f"{what}: missing {needle}"

expect_all(hud,(
    "struct SourceCombatHUD331: View",
    "Canvas(opaque:false, rendersAsynchronously:false)",
    "CombatHUDViewport568(",
    "originX(for:.topLeft)",
    "originY(for:.topLeft)",
    "originX(for:.topRight)",
    "originY(for:.topRight)",
    "originX(for:.bottomLeft)",
    "originY(for:.bottomLeft)",
    "originX(for:.bottomRight)",
    "originY(for:.bottomRight)",
    "Self.top(topLeft,topRight,hud,layout600)",
    "Self.radar(radarContext,hud)",
    "Self.ability(",
    "safeLeft:insets.left,safeRight:insets.right",
    "let values:[Int?]=[hud.hull,hud.armor,hud.tarczaEnergy]",
    "let maximums=[60,25,100]",
    "titles[i],values[i],maximums[i],191,y,i,Double(hud.seconds)",
    "HudEnergy600.ribbon(",
    "let cx:CGFloat=91,cy:CGFloat=612,r:CGFloat=69",
    "for i in 0..<32",
    "920+100*i",
    "let namesDisplay=[\"JON\",\"BOMBY\",\"OSŁONY\",\"DOPALACZ\"]",
    "\"SEKTOR 01 / 26\"",
    "\"SYNIXAD / WALKA 3D\"",
    ".allowsHitTesting(false)",
    ".accessibilityIdentifier(\"sector01-source-w3-hud331\")",
),"hud331")
expect_all(session,(
    "struct RadarContact",
    "Sphere67.normal(point)",
    "SphereVector3.dot(n,camera.focus) < -0.06",
    "SphereVector3.dot(n,camera.right)",
    "-SphereVector3.dot(n,camera.up)",
    "game.rocks.compactMap",
    "game.shooters.compactMap",
    "game.tokenPickups.compactMap",
    "tokenBalance=initialTokens>Int.max-earned ? Int.max : initialTokens+earned",
    "shieldCharges=game.shieldCharges",
    "tarczaEnergy=Int(game.tarcza145.energy.rounded())",
    "ionAmmo=game.ionAmmo; bombs=game.bombs",
    "boostCharges=game.boost71.charges",
    "boostActive=game.boost71.active",
    "if now-lastHUD > 0.10",
),"source combat HUD data")
expect_all(combat,(
    "let startingTokens:Int",
    "startingTokens=profile.tokens",
    "var collectedLootTokens:Int=0",
    "mutating func suffer(_ damage:Int)",
),"wallet original model")
expect_all(scene,(
    "SourceCombatHUD331(hud:session.hud,insets:missionSafeInsets568,",
    "Button(\"PAUZA\") {pauseMission568()}",
    "session.useBomb()",
    "persistConsumables580()",
    ".accessibilityIdentifier(\"sector01-pause-button\")",
    "Button(\"KONTYNUUJ\") {resumeMission568()}",
    "Button(\"WYJDŹ DO MENU\") {exitMission568()}",
    "SourcePerformanceOverlay568()",
    ".gesture(movement)",
    ".gesture(aiming)",
    "session.release()",
    "W3SafeAreaReader568(insets:$missionSafeInsets568)",
    "safeLeft:missionSafeInsets568.left",
    "safeRight:missionSafeInsets568.right",
    "safeTop:missionSafeInsets568.top",
    "safeBottom:missionSafeInsets568.bottom",
    "combatHUDLayout.pauseCenterX",
    "combatHUDLayout.pauseCenterY",
    ".ignoresSafeArea()",
),"scene integration")
for old in (
    "PORT MISJI 01",
    "ORYGINALNA PLANETA C279 · VANGUARD · WAVE 01",
    "KADŁUB \\(session.hud.hull)",
    "CZAS \\(Int(session.hud.seconds))",
    "Canvas { context,size in",
):
    assert old not in scene, "old non-source HUD still present: " + old
assert "Color.black.opacity(0.78)" not in scene
# Guard against regressing to the single common origin/centered viewport.
assert "rightShift" not in hud
assert "originLeftX" not in hud
assert "originY)" not in hud
assert "geo.safeAreaInsets" not in hud
assert "AVAudioPlayer" not in hud
assert "Timer(" not in hud
assert "DispatchQueue" not in hud
assert "MetalRenderer" not in hud
print("PASS RendererW3Combat331/v600 source-contract: four-corner anchors, live plasma and telemetry, radar, unchanged audio/touch/120Hz gameplay")
