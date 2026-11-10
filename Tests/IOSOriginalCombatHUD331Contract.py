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
plasma=(root/"ASTEROIDYiOS/HudPlasmaLayer600.swift").read_text()
session=(root/"ASTEROIDYiOS/CarbonisSession568.swift").read_text()
combat=(root/"ASTEROIDYiOS/CarbonisCombat568.swift").read_text()
pickup=(root/"ASTEROIDYiOS/Sector01CarbonisPreview568.swift").read_text()
interface=(root/"ASTEROIDYiOS/CarbonisVisualSettingsPanel568.swift").read_text()
gloveLight=(root/"ASTEROIDYiOS/H55FPSLighting580.swift").read_text()

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
    "titles[i],values[i],191,y)",
    "let cx:CGFloat=91,cy:CGFloat=612,r:CGFloat=69",
    "for i in 0..<32",
    "920+100*i",
    "let namesDisplay=[\"JON\",\"BOMBY\",\"OSŁONY\",\"DOPALACZ\"]",
    "\"SEKTOR 01 / 26\"",
    "\"SYNIXAD / WALKA 3D\"",
    ".allowsHitTesting(false)",
    ".accessibilityIdentifier(\"sector01-source-w3-hud331\")",
),"hud331")
expect_all(plasma,(
    "HudEnergy600.ribbon(",
    "TimelineView(.animation(minimumInterval:1.0/60.0",
    "let gauge=liveGauges()",
    "let maxima=[gauge.maxHull,gauge.maxArmor,100]",
    "for layer in 0..<5",
    "for k in 0..<7",
), "v600 animated plasma renderer")
# Source PC v602 DrawCoin is a gold, filled, spinning ellipse with engraving.
# The legacy geodesic ring remains, but it cannot replace the money sprite.
expect_all(pickup,(
    "private static func appendMoneyCoin568(",
    "radius*abs(cos(token.angle+time*2.4))",
    "ellipse(width+edge,radius+edge",
    "ellipse(width,radius",
    "outline(width,radius",
    "if token.sourceKind == nil {",
    "appendMoneyCoin568(token,scale:scale,time:time,",
    "time:session.game.elapsed))",
), "original PC v602 source money coin")
assert 'sourceKind:SourcePickupModels586.Kind? = nil' in combat
# Same shared photometric calibration in BOTH FPS preview and gameplay.
expect_all(gloveLight,(
    "private static let sceneKitLightGain:CGFloat=0.35",
    "let gain:CGFloat = mode == .gloves ? sceneKitLightGain : 1",
    "?.light?.intensity=220*gain",
    "?.light?.intensity=spec.2*gain",
), "hangar gloves light-clipping fix")
fpsScene=(root/"ASTEROIDYiOS/H55ScenePage580.swift").read_text()
fpsPreview=(root/"ASTEROIDYiOS/H55FPSPreview580.swift").read_text()
assert 'H55FPSLighting580.configure(scene:fpsOverlayScene,mode:mode)' in fpsScene
assert 'H55FPSLighting580.configure(scene:fpsScene,mode:fpsMode)' in fpsScene
assert 'H55FPSLighting580.configure(scene:scene,mode:settings.mode)' in fpsPreview
# Gameplay OPTIONS must open the full W3 settings panel, not an inert pause.
expect_all(scene,(
    'Button("OPCJE / USTAWIENIA")',
    'showingMissionSettings568=true',
    'missionSettingsScreen568(compact:compact)',
    'initialTab:4,',
    'onEditHud:{',
), "mission settings entry")
expect_all(interface,(
    'case 4: interfacePage600',
    'Button("EDYTUJ UKŁAD HUD (46 ELEMENTÓW)")',
    'HudMotionSettingsPanel600 { value in',
), "W3 Interface HUD settings")

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
    "tarczaEnergy=max(0,Int(ceil(Double(game.tarcza145.energy))))",
    "maxHull=game.maxHull;maxArmor=game.maxArmor",
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
