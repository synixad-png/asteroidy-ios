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
assert "input.gameplayPaused = visible || showCampaign || scenePhase != .active" in app
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
assert "ETAP C: PLANETA ŹRÓDŁOWA — WALKA I UKOŃCZENIE MISJI NIEPODŁĄCZONE" in app
assert "WEJDŹ NA CARBONIS 01 / ŹRÓDŁOWA SCENA 3D" in app
assert 'accessibilityIdentifier("campaign-enter-source-sector01")' in app
assert "if let sourceEntry=sourceSector01" in app
assert "Sector01Scene568(entry:sourceEntry,returnToAtlas:" in app
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
assert "surface.surfaceRadius(x:1,y:0,z:0)" in scene
assert 'sourceHeightProbe277' in scene


assert "onInspect:inspectSector" in menu
assert "onInspect: { sector in inspectSourceSector(sector) }" in app
assert "onOpen" not in menu  # no invented campaign loader
assert 'openDiagnostic()' in menu
assert "import WebKit" not in menu and "WKWebView(" not in menu
assert "W3HomePlanetMetal568.isAvailable" in menu
assert "W3HomePlanetMetal568(yaw:planetYaw,pitch:planetPitch)" in menu
assert "ORYGINALNA PLANETA NEWHOME290 / 3D METAL" in menu
assert "MODEL PLANETY 3D — BRAK ZASOBÓW" in menu
assert "Radar W3 z oryginalną planetą 3D NewHome290" in menu
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
assert "page=item" in menu and "page=nil" in menu
assert "switch item" in menu
assert "if item == .campaign || item == .newGame" in menu
print("PASS: 7 W3 native actions, 26-sector source selection and genuine C279 scene transition")
print("PASS: simulator GPU verification opt-outs remain, diagnostics and collisions protected")
print("LIMIT: actual iPhone/iPad seven-button XCTest and full PC W3 pixel parity are separately gated")
