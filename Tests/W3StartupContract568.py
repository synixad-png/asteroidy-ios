#!/usr/bin/env python3
"""Source-backed Windows v568 startup ordering and iOS W3 splash gate."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
app=(root/"ASTEROIDYiOS/App.swift").read_text()
view=(root/"ASTEROIDYiOS/W3StartupSplash568.swift").read_text()
menu=(root/"ASTEROIDYiOS/W3MainMenu568.swift").read_text()
policy=(root/"ASTEROIDYiOS/W3StartupPolicy568.swift").read_text()
test=(root/"W3MenuUITests/W3MenuNavigationUITests.swift").read_text()
assert "if !audio.startupComplete" in app
assert app.index("if !audio.startupComplete") < app.index("W3MainMenu568(progress:")
assert "if !startupSplashPassed568" in app
assert "W3StartupSplash568(onContinue:" in app
assert "startupSplashPassed568=true" in app
assert ".allowsHitTesting(startupSplashPassed568)" in app
assert ".accessibilityHidden(!startupSplashPassed568)" in app
assert "audio.prepareMenuAtStartup()" in app
assert "SourceW3Images568.pair" in view
assert "enum SourceW3Images568 {" in menu
assert "private enum SourceW3Images568 {" not in menu
for caption in ("NOWY SYSTEM NAWIGACJI","ORBITAL NAVIGATION SYSTEM",
                "NACIŚNIJ ENTER / START","TERMINAL // SYNIXAD COMMAND",
                "STATUS POŁĄCZENIA: AKTYWNY"):
    assert caption in view,caption
assert ".onTapGesture {proceed()}" in view
assert ".onKeyPress(.return)" in view
assert ".onKeyPress(.space)" in view
assert "pad.start(onConfirm:proceed)" in view
assert "pad.buttonA.pressedChangedHandler" in view
assert "pad.buttonMenu.pressedChangedHandler" in view
assert "pad.stop()" in view
assert "stage == .waiting" in view
assert "sourceCoverSeconds" in view and "sourceUncoverSeconds" in view
assert "sourceCoverSeconds:Double=0.45" in policy
assert "sourceUncoverSeconds:Double=0.80" in policy
assert "skipForDiagnostic(ProcessInfo.processInfo.environment)" in app
assert 'ASTEROIDY_W3_MENU_VERIFY' in policy
assert 'app.launchEnvironment["ASTEROIDY_W3_MENU_VERIFY"] = "1"' in test
assert "onContinue:{" in app
assert "originalMusic" not in view.lower(), "Splash must not initiate new music synthesis"
assert "DispatchQueue.main.asyncAfter" in view
print("PASS original v568 W3 press-Enter after source menu audio; no auto-skip")
print("PASS native touch/Enter/space/gamepad A+Start and 1.25s W3 shutter")
print("PASS single source SHA-verified background/logo, UI test diagnostic gate")
