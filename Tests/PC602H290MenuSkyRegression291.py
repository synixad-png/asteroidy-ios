#!/usr/bin/env python3
"""PC602 H290 source regression for options, mission exit, source stars.
This does not imply on-device GPU verification.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
read=lambda p:(root/"ASTEROIDYiOS"/p).read_text()
app=read("App.swift")
page=read("PC602HomeWorldPage291.swift")
mission=read("Sector01Scene568.swift")
sky=read("SourceCombatSky568.swift")
world=read("PC602HomeScene291.swift")
source=read("Sphere67.swift")
view=read("PC602HomeWorldView291.swift")
for required in (
    'Button("PAUZA") {openOrbitOptions291()}',
    '.frame(minWidth:100,minHeight:44)',
    'Button("POWRÓT DO MENU GŁÓWNEGO")',
    'accessibilityIdentifier("pc602-orbit-return-w3")',
    'if showingOrbitOptions291 {orbitOptionsPanel291(screen:screen)}',
    'CarbonisVisualSettingsPanel568(',
    'driver.setPaused(previouslyPausedOptions291)',
    'onExitToW3()',
):
    assert required in page, required
# Entering save/load from OPCJE must not leave the pilot frozen.
# The single interactive pause must also be used after iPad locks.
assert 'orbitPausePanel317' not in page
assert 'if !driver.presentingH55 && !showingOrbitOptions291' in page
assert 'openOrbitOptions291()' in page
assert 'previouslyPausedOptions291=false' in page
assert 'restorePaused:previouslyPausedOptions291' in page
assert 'previouslyPaused61=restorePaused ?? driver.paused' in page
assert 'driver.setPaused(previouslyPaused61)' in page
assert 'let onExitToMainMenu:()->Void' in mission
assert 'self.onExitToMainMenu=onExitToMainMenu' in mission
exit_body=mission.split('private func exitMission568() {',1)[1].split(
    '/// The authoritative W3 settings panel',1)[0]
for required in ('persistConsumables580()','onSurvivalChanged(',
                 'onExitToMainMenu()'):
    assert required in exit_body, required
assert 'returnToAtlas()' not in exit_body
assert 'Button("WYJDŹ DO MENU") {exitMission568()}' in mission
assert 'Sector01ShopPanel568(onReturnAtlas:returnToAtlas)' in mission
menu_body=app.split('},onExitToMainMenu:{',1)[1].split(
    '},onMissionCompleted:',1)[0]
for required in ('sourceSector01=nil','sourceSector01Setup=nil',
                 'returnHomeWorldAfterCarbonis291=false',
                 'showingHomeWorld291=false','homeWorld291.stop()',
                 'showMainMenu=true','audio.returnToMenu()'):
    assert required in menu_body, required
orbit_exit=app.split('onExitToW3:{',1)[1].split('onEnterMission:',1)[0]
for required in ('_=homeWorld291.captureResume61()',
                 'homeWorld291.stop()',
                 'showingHomeWorld291=false','showMainMenu=true'):
    assert required in orbit_exit,required
# From actual PC v602: sphere 900, orbit eye 400 (not combat 310).
assert 'static let cameraRadius:Float=400' in view
assert 'static let originalSkyRadius: Float = 900' in source
assert 'static let originalPlanetOuterRadius: Float = 100 * 1.4419674' in source
assert 'worldEye:frame.eye' in world
assert 'worldScale:SphereCameraView556.originalPlanetOuterRadius' in world
assert 'let skyEye=worldEye ??' in sky
assert 'let skyMVP=vp*Self.translation(skyEye.x,skyEye.y,skyEye.z)*skyScale' in sky
assert 'starCount=stars.1.count' in sky
assert 'worldScale:Float=1' in sky # Carbonis default unmodified
outer=100*1.4419674
assert abs(900/outer*outer-900)<1e-4
assert 'guard level==1,sourceSector01==nil' in app
assert 'craft:.vanguard' in app
print("PASS PC602: H290 options->W3, paused Carbonis01->W3, "
      "independent service/atlas return; original 900-unit sky")
