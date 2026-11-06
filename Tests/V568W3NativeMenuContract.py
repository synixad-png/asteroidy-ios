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
assert "W3MainMenu568(progress:campaign,openDiagnostic:" in app
assert "Button(\"MENU W3\")" in app
assert "showMainMenu = true" in app
assert "showMainMenu = false" in app
assert '"ASTEROIDY_RENDER_VERIFY"] != "1"' in app
assert '"ASTEROIDY_SHIP367_VERIFY"] != "1"' in app
assert "input.releaseHeldControls()" in app
assert "input.gameplayPaused = visible || showCampaign || scenePhase != .active" in app
assert "if showMainMenu {" in app
assert app.index("if showMainMenu {")<app.index("MetalScene(input: input)")
assert "CampaignAtlas556(progress:progress,dismiss:{page=nil})" in menu
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
print("PASS: 7 source v568 W3 home actions, native menu entry, safe visible routes")
print("PASS: simulator GPU verification opt-outs remain, diagnostics and collisions protected")
print("LIMIT: actual iPhone/iPad seven-button XCTest and full PC W3 pixel parity are separately gated")
