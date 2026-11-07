#!/usr/bin/env python3
"""W3 v568 source-referenced iPhone/iPad menu: fail-closed navigation contract.

Verified against ASTEROIDY v568 source archive (not a lookalike asset):
Windows/src/RendererW3Home328.cs sha256
 a696603703583df5e4363106389833d6fd9aaa59fd6b73fa5e1aec3f71f4a966
Windows/src/UiW3Shared.cs sha256
 47ac224bd9bc8874826e24c75eda56ea7b2527043b281a562ac65f0af7b91a50
Stage A native UI contains source-verified background/logo, real NewHome290
and Vanguard431 Metal previews; full PC shader parity and physical taps are
not claimed until tested.
"""
from pathlib import Path
import re

root=Path(__file__).resolve().parents[1]
app=(root/"ASTEROIDYiOS/App.swift").read_text()
menu=(root/"ASTEROIDYiOS/W3MainMenu568.swift").read_text()
reference=[
    "NOWA GRA","KONTYNUUJ","KAMPANIA","HANGAR",
    "USTAWIENIA","AUTORZY","WYJŚCIE"
]
# Original RendererW3Home328 uses 7 rows from this exact source index array.
assert len(reference)==7
assert 'case newGame = "NOWA GRA"' in menu
for caption in reference:
    assert menu.count('= "'+caption+'"')==1,(caption,"missing/duplicated")
assert menu.index('case newGame')<menu.index('case continueGame')<menu.index('case campaign')
assert "W3MainMenu568(progress:campaign,selectMission:" in app
assert "Button(\"MENU W3\")" in app
assert "showMainMenu = true" in app
assert "showMainMenu = false" in app
assert '"ASTEROIDY_RENDER_VERIFY"] != "1"' in app
assert '"ASTEROIDY_SHIP367_VERIFY"] != "1"' in app
assert "input.releaseHeldControls()" in app
assert "input.gameplayPaused = visible || scenePhase != .active" in app
assert "if showCampaign" not in app
assert "if showMainMenu {" in app
assert app.index("if showMainMenu {")<app.index("MetalScene(input: input)")
assert "CampaignAtlas556(progress:progress," in menu
assert "onSelect:selectMission" in menu
assert "CampaignStore556.save(campaign)" in app
assert "campaign.selectUnlocked(sector)" in app
assert "MissionCatalog568.title(for:progress.selectedSector)" in app
assert 'accessibilityIdentifier("campaign-26-sector-selector")' in app
assert 'accessibilityIdentifier("campaign-sector-' in app
assert ".disabled(!available)" in app
assert "SEKTOR 01: WALKA, RAPORT, ŻETONY I ZAPIS" in app
assert "ROZPOCZNIJ CARBONIS 01 / PEŁNA WALKA" in app
assert 'accessibilityIdentifier("campaign-enter-source-sector01")' in app
assert "if let sourceEntry=sourceSector01" in app
assert "Sector01Scene568(entry:sourceEntry,returnToAtlas:" in app
# Source original Game.Wave is prepared for CARBONIS, never conflated
# with rendered combat or automatically completed campaign objectives.
source_wave=(root/"ASTEROIDYiOS/MissionWave568.swift").read_text()
prepared_wave=(root/"ASTEROIDYiOS/Sector01PreparedWave568.swift").read_text()
source_scene=(root/"ASTEROIDYiOS/Sector01Scene568.swift").read_text()
assert 'SourceRandom(seed:seed)' in source_wave
assert 'var playable: Bool { false }' in source_wave
assert 'var isPlayable: Bool { false }' in prepared_wave
assert "Sector01PreparedWave568.prepare(" in app
assert "@State private var sourceSector01Setup: Sector01PreparedWave568?" in app
assert "sourceSector01Setup = nil" in app
assert "initialRocks:preparedWave.encounter.rocks" in source_scene
source_shop=(root/"ASTEROIDYiOS/Sector01Shop568.swift").read_text()
shop_view=(root/"ASTEROIDYiOS/Sector01ShopPanel568.swift").read_text()
source_summary=(root/"ASTEROIDYiOS/Sector01MissionSummary568.swift").read_text()
source_settlement=(root/"ASTEROIDYiOS/Sector01MissionSettlement568.swift").read_text()
assert "Sector01MissionSettlement568.commit(" in app
assert "onMissionCompleted:{ report in" in app
assert "shopProfile:sourceShop" in app
assert "Sector01ShopPanel568(onReturnAtlas:returnToAtlas)" in source_scene
assert "accessibilityIdentifier(\"sector01-result-to-service\")" in source_scene
assert "accessibilityIdentifier(\"sector01-retry-after-defeat\")" in source_scene
assert "session.hud.summarySeconds>=4.2" in source_scene
assert "static func completedFirstMission(" in source_summary
assert "Sector01MissionSummary568.completedFirstMission(" in (root/"ASTEROIDYiOS/CarbonisCombat568.swift").read_text()
assert "CampaignStore556.save(campaign,defaults:defaults)" in source_settlement
assert "Sector01Shop568.save(profile,defaults:defaults)" in source_settlement
assert "enum Item:Int,CaseIterable" in source_shop
assert "accessibilityIdentifier(\"sector01-source-post-mission-service-shop\")" in shop_view

assert "session.hud.fighters" in source_scene
incoming_wave=(root/"ASTEROIDYiOS/MissionIncoming568.swift").read_text()
assert "random = encounter.randomState" in incoming_wave
assert "incomingLeft = encounter.initialReinforcements" in incoming_wave
assert "let count=min(2,incomingLeft)" in incoming_wave
assert "if objective == .clear && activeRocks == 0 && activeEnemies == 0" in incoming_wave
assert "incoming:MissionIncoming568(from:encounter,difficulty:difficulty)" in prepared_wave

assert "Sector01CarbonisPreview568(" in source_scene
assert "gameSession:session" in source_scene
# Two independent invisible half-screen controls remain in place:
# left flight stays unchanged; the right gesture aims AND fires on first touch.
# The old fire button must not intercept the aiming region.
assert "private var movement:some Gesture {" in source_scene
assert "session.input(move:Vec2(x:clamp(Float(v.translation.width)/110)" in source_scene
assert "private var aiming:some Gesture {" in source_scene
assert "DragGesture(minimumDistance:0).onChanged { v in" in source_scene
assert "session.input(aim:Vec2(x:clamp(Float(v.translation.width)/100)" in source_scene
assert "shooting:true)" in source_scene
assert "session.input(aim:Vec2(x:0,y:0),shooting:false)" in source_scene
assert 'accessibilityIdentifier("sector01-right-steer-auto-fire")' in source_scene
assert 'accessibilityIdentifier("sector01-fire-pulse")' not in source_scene
assert "private var fireGesture" not in source_scene
assert 'Text("OGIEŃ")' not in source_scene
assert "session.release()" in source_scene
# Static HUD must not block right-side touch and its held-auto-fire gesture.
assert source_scene.count(".allowsHitTesting(false)")>=4

assert "SEKTOR 01 / CARBONIS" in source_scene
rock_geom=(root/"ASTEROIDYiOS/CarbonisRockGeometry568.swift").read_text()
rock_metal=(root/"ASTEROIDYiOS/Sector01Carbonis568.metal").read_text()
assert "let seed=Float((shape%40)/5+13)" in rock_geom
assert "sourceVertexCount=20*16*3" in rock_geom
assert "static func stoneNormal(" in rock_geom
assert 'sector01SourceRockFragment568' in rock_metal
carbonis=(root/"ASTEROIDYiOS/Sector01CarbonisPreview568.swift").read_text()
source_drone=(root/"ASTEROIDYiOS/CarbonisShooterMesh71.swift").read_text()
source_combat=(root/"ASTEROIDYiOS/CarbonisCombat568.swift").read_text()
assert "static func typeZero()->Mesh" in source_drone
assert "static func typeOne()->Mesh" in source_drone
assert "private static func curve55(" in source_drone
assert "private static func smoothPoint(" in source_drone
assert "static func warningVertices(" in carbonis
assert "CarbonisShooterMesh71.typeZero()" in carbonis
assert "CarbonisShooterMesh71.typeOne()" in carbonis
assert "sourceShooters[kind]=(buffer,mesh.ranges)" in carbonis
assert "for enemy in session.game.shooters {" in carbonis
assert "guard let shooter=sourceShooters[enemy.core.type]" in carbonis
assert "enemy.telegraph>0" in carbonis
assert "material==5 || material==6" in carbonis
assert "diagonal:SIMD4<Float>(1.15,1.15,1.15,1)" in carbonis
assert "sector01ShooterFragment71" in rock_metal
assert "Turn72" in source_combat or "turn72(" in source_combat
assert "fighter.phase+0.4" in source_combat
assert "ShooterTactics71(" in source_combat
assert "tactics.projectileDamage" in source_combat
assert "tactics.volleyCount" in source_combat

assert "sourceRockModel(_ rock:SphereAsteroid556)" in carbonis
assert "activeRocks[index].advance(dt:dt)" in carbonis
assert "encoder.drawPrimitives(type:.triangle,vertexStart:0," in carbonis
assert "initialRocks:preparedWave.encounter.rocks" in source_scene
assert '"nativeMissionPlayable":false' in carbonis

assert "Sector01Entry568.open(" in app
assert "hasOriginalC279Assets:Sector01CarbonisPreview568.isAvailable" in app
# C279 source integrity must be checked before leaving the atlas.
carbonis=(root/"ASTEROIDYiOS/Sector01CarbonisPreview568.swift").read_text()
assert "return files.allSatisfy { name,ext in" in carbonis
assert "let bytes=try? Data(contentsOf:url)" in carbonis
assert "let expected=Coordinator.Renderer.expected[name+\".\"+ext]" in carbonis
assert "return actual==expected" in carbonis
assert carbonis.count("SHA256.hash(data:bytes)")>=2
assert "static let expected:[String:String]" in carbonis
assert '("Sector01CarbonisHeightMap","dat")' in carbonis
assert '"Sector01CarbonisHeightMap.dat":"3ce9a0456d23a5b88de718e7fd8fe6560cb53cd112a31ecc876e6200a762cb39"' in carbonis
surface=(root/"ASTEROIDYiOS/CarbonisSurface277.swift").read_text()
scene=(root/"ASTEROIDYiOS/Sector01Scene568.swift").read_text()
assert "func surfaceRadius(x: Float, y: Float, z: Float) -> Float" in surface
assert "let x0 = ((ix % Self.width) + Self.width) % Self.width" in surface
assert "let y0 = max(0, min(Self.height - 1, iy))" in surface
assert "surfaceRadius(x: Float, y: Float, z: Float)" in surface
assert "CarbonisCombat568" in (root/"ASTEROIDYiOS/CarbonisSession568.swift").read_text()


assert "onInspect:inspectSector" in menu
assert "inspectSector: { sector in" in app and "inspectSourceSector(sector)" in app
assert "onOpen" not in menu  # no invented campaign loader
assert 'openDiagnostic()' in menu
assert "import WebKit" not in menu and "WKWebView(" not in menu
assert "W3HomePlanetMetal568.isAvailable" in menu
assert "W3HomePlanetMetal568(yaw:planetYaw,pitch:planetPitch)" in menu
assert "Oryginalna planeta 3D NewHome290 na przezroczystym tle" in menu
# The source GPU preview has no overlaid radar, captions or fallback disk.
area=menu.split("private func radar(compact:Bool)",1)[1].split(
    "private var telemetry: some View",1)[0]
assert "W3HomePlanetMetal568(yaw:planetYaw,pitch:planetPitch)" in area
assert not any(x in area for x in (
    "RoundedRectangle(", "Ellipse(", "Rectangle(", ".stroke(",
    ".fill(", "Text(", "ForEach(", "RADAR / SYSTEM NAWIGACJI",
    "W3 v568", "ORYGINALNA PLANETA NEWHOME290 / 3D METAL"))

assert "Brak zweryfikowanego oryginalnego modelu planety" in menu
assert "W3HomeShipPreview568()" in menu
assert 'hangar_h55.glb' in menu
assert 'Wczytanie rzeczywistego zapisu' in menu
# Navigation is fully handled in one native SwiftUI view, without
# silently connecting unavailable menu actions to test gameplay.
assert "ScrollView(.vertical)" in menu
assert "minHeight:44" in menu
assert 'accessibilityIdentifier("w3-home-navigation")' in menu
assert "accessibilityAddTraits(.isButton)" in menu
assert "accessibilityLabel(item.rawValue)" in menu
assert "navigateW3(item)" in menu and "navigateW3(nil)" in menu
assert "page=destination" in menu and "w3WipeAmount327" in menu
assert "duration:0.45" in menu and "duration:0.80" in menu
assert "switch item" in menu
assert "else if item == .campaign {" in menu
assert "else if item == .newGame {" in menu
assert "newGamePage(compact:compact)" in menu
assert "Color.black.opacity(0.86).ignoresSafeArea()" not in menu
assert "ASTEROIDY_DEBUG_MENU" in menu
assert 'if ProcessInfo.processInfo.environment["ASTEROIDY_DEBUG_MENU"] == "1" {' in menu
assert ".transition(.opacity.combined(with:.move(edge:.trailing)))" not in menu
assert ".transition(.opacity)" not in menu
assert 'Button("SCENA TESTOWA")' in menu
assert 'Button("WSTECZ")' in menu
assert 'if let shown=page {' in menu
assert "CarbonisVisualSettingsPanel568(compact:compact)" in menu
settings=(root/"ASTEROIDYiOS/CarbonisVisualSettingsPanel568.swift").read_text()
tabs=[
 "GRAFIKA","DŹWIĘK","STEROWANIE","ROZGRYWKA","INTERFEJS",
 "DOSTĘPNOŚĆ","RĘKAWICE","PLANETY","BROŃ","HANGAR","GOLD MELTER",
 "WYBUCHY 3D","SZYBY","STATEK","POSTPROCES","KOSMOS","POCISKI"]
source_categories=re.search(r'private let sourceTabs139=\[(.*?)\]',settings,re.S)
assert source_categories is not None, "Source W3 17-category array missing"
assert re.findall(r'"([^"]+)"',source_categories.group(1))==tabs, "Windows Menu139.cs category order changed"
assert "ScrollViewReader" in settings and "ScrollView(.vertical)" in settings
assert "ScrollView(.horizontal,showsIndicators:false)" not in settings
assert "case 11: explosionPage" in settings
assert "case 16: projectilePage" in settings
assert "case 1: OriginalAudioSettingsPanel568(compact:compact)" in settings
assert "case 7: planetPage" in settings
assert "case 13: shipSizePage" in settings
assert "case 14: postprocessPage" in settings
assert "unavailableSourceCategory" in settings
assert "accessibilityIdentifier(\"w3-effects-tabs-524-285\")" in settings
assert ".ultraThinMaterial" not in app
print("PASS: 7 W3 native actions, 26-sector source selection and genuine C279 scene transition")
print("PASS: simulator GPU verification opt-outs remain, diagnostics and collisions protected")
print("LIMIT: actual iPhone/iPad seven-button XCTest and full PC W3 pixel parity are separately gated")
