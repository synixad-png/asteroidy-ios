#!/usr/bin/env python3
"""PC v602 real orbital UI / W3 / H55 / source-plasma integration contract.

These checks run on source, not Apple GPU pixels. They deliberately check the
real app routing rather than an unused helper or a screenshot of a mock UI.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
def source(name):
    return (root/"ASTEROIDYiOS"/name).read_text()

app=source("App.swift")
menu=source("W3MainMenu568.swift")
page=source("PC602HomeWorldPage291.swift")
driver=source("PC602HomeWorldDriver291.swift")
world=source("PC602HomeScene291.swift")
h55=source("H55ScenePage580.swift")
ship=source("SourceHomeVanguard431.swift")
plasma=source("PC602HomePlasma491.metal")
flight=source("PC602HomeFlight291.swift")
session=source("PC602HomeWorldSession291.swift")
weapons=source("PC602HomeWeaponTest292.swift")
shot_geometry=source("PC602HomeShotGeometry292.swift")
shot_renderer=source("SourceHomeShots292.swift")
shot_shader=source("PC602HomeShots292.metal")
atlas=source("PC602OrbitHud330.swift")


# Explicit real user action in W3 CAMPAIGN. All seven existing W3 pages stay.
assert 'case newGame = "NOWA GRA"' in menu
assert 'case exit = "WYJŚCIE"' in menu
assert "let openOrbit:()->String?" in menu
assert "onEnterOrbit:openOrbit" in menu
assert 'Button("WEJDŹ DO ORBITY 3D / PC v602")' in app
assert "PC602HomeWorldDriver291.resourcesInstalled" in app
assert 'accessibilityIdentifier("campaign-enter-original-orbit291")' in app

# A source state is initialized from the existing completed campaign ONLY.
assert "try homeWorld291.start(progress:campaign)" in app
assert "CampaignProgress556" in driver
assert "completedMask:progress.completedMask" in driver
assert "SourceControls586.Profile.load()" in driver
assert "PC602HomeWorldPage291(" in app
assert "PC602HomeScene291(" in page
# No duplicate sky layers: actual HomeScene291 uses the existing source
# IntroSky GpuIntro41 pipeline already exercised by Carbonis 01.
assert "let originalSky:SourceCombatSky568" in world
assert "originalSky=try SourceCombatSky568(device:device)" in world
assert "originalSky.draw(encoder:encoder," in world
assert world.index("originalSky.draw") < world.index("encoder.drawPrimitives(type:.triangle,vertexStart:0,")
assert "PC602HomeWorldSession291" in driver
assert "PC602HomeFlightInput291.read(" in session
assert "SourceHardwareInput586.shared.snapshot()" in driver

# One MTKView timer, no simultaneous 60Hz SwiftUI TimelineView.
assert "var onFrame:((TimeInterval)->PC602HomeFlight291?)?" in world
assert "onFrame?(step) ?? flight" in world
assert "min(elapsed,0.05)" in world
assert "elapsed<=0.15" in world
assert "func frame(dt:TimeInterval)->PC602HomeFlight291?" in driver
assert "lastUIUpdate>=0.125" in driver
assert "NSLock()" in driver
# Full-line documentation comments must not trigger this real-code gate.
# Check that the driver does not CREATE another timer/executor.
executable_driver = "\n".join(line for line in driver.splitlines()
    if not line.lstrip().startswith("//"))
for name in ("CADisplayLink","Timer.scheduledTimer","TimelineView",
             "DispatchQueue.main.asyncAfter","Task.detached"):
    assert name not in executable_driver, name
assert "SourceKeyboardCapture586" in page
assert "SourceCombatTouchZones568(" in page
assert "OrbitTouchStick291" not in page
assert "SourceCombatTouchZones568(" in source("Sector01Scene568.swift")
assert "private var movement:some Gesture" not in source("Sector01Scene568.swift")
assert 'source-combat-left-touch-zone' in source("SourceCombatTouchZones568.swift")
assert 'accessibilityIdentifier("pc602-orbit-live-touch-hud")' not in page
assert 'accessibilityIdentifier("pc602-orbit-pause")' in page
assert 'accessibilityIdentifier("pc602-orbit-open-atlas330")' in page
assert "driver.setPaused(true)" in page
assert "driver.setPaused(previouslyPausedOptions291)" in page
# One fully interactive PAUZA panel for touch/keyboard/pad and iPad screen lock.
assert 'Button("PAUZA") {openOrbitOptions291()}' in page
assert 'accessibilityIdentifier("pc602-orbit-pause")' in page
assert 'accessibilityIdentifier("pc602-orbit-options291")' not in page
assert 'exitID:"pc602-orbit-return-w3"' in page
assert 'SourcePauseMenu568(' in page
assert 'SourcePauseMenu568(' in source("Sector01Scene568.swift")
assert 'exitID:"pc602-orbit-return-w3"' in page
assert 'slotsID:"pc602-orbit-save61"' in page
assert 'onEditOrbitHud:{openOrbitHUDEditor291()}' in page
assert 'openSaves61(load:false,' in page
assert "driver.setSuspended(phase != .active)" in page
assert "if !driver.presentingH55 {" in page
assert "previouslyPausedOptions291=false" in page
assert "showingOrbitPause317" not in page
assert "orbitPausePanel317" not in page
assert "pauseAction317" not in page
assert "driver.setPaused(previouslyPausedOptions291)" in page
assert "key==keys[9]" in page and "key==keys[27]" in page
assert "pressedOrbitCommands291.insert(key).inserted" in page
assert "padOnly.held(9,profile:session.controls)" in driver
assert "padOnly.held(27,profile:session.controls)" in driver
assert "buttons:snapshot.buttons,axes:snapshot.axes" in driver
assert "triggerPausePad=pauseDown && !pausePadHeld" in driver
assert "triggerOptionsPad=optionsDown && !optionsPadHeld" in driver
assert ".onChange(of:driver.pausePadPresses)" in page
assert ".onChange(of:driver.optionsPadPresses)" in page
assert 'Button("PAUZA") {openOrbitOptions291()}' in page
assert 'exitID:"pc602-orbit-return-w3"' in page
assert "onExitToW3()" in page
assert "onExitToW3()" in page
assert "let onExitToMainMenu:()->Void" in source("Sector01Scene568.swift")
assert "onExitToMainMenu()" in source("Sector01Scene568.swift")
assert "},onExitToMainMenu:{" in app
assert "driver.setSuspended(phase != .active)" in page

# Real H55 only after source geometry-derived <= 43.2 m, SAME SceneKit.
assert "session?.requestDock(context:.init(" in driver
assert "planetHub:true,orbitMode:true" in driver
assert "H55ScenePage580(dismiss:{driver.exitH55()}" in page
assert 'exitTitle:"POWRÓT NA ORBITĘ"' in page
assert 'exitTitle:String="WYJDŹ DO MENU"' in h55
assert 'pauseButton(exitTitle)' in h55
assert 'H55ScenePage580(dismiss:{navigateW3(nil)})' in menu

# The only actually playable mission is original CARBONIS 01. All others
# keep authored location/unlock but no fabricated enemy/credits/finish.
assert "canEnterAuthoredMissionArea==1" in driver
assert "guard level==1,sourceSector01==nil" in app
assert "Sector01Entry568.open(" in app
assert "Sector01MissionSettlement568.commit(" in app
assert "homeWorld291.refreshCampaign(campaign)" in app
assert "returnHomeWorldAfterCarbonis291" in app
assert "onEnterMission:enterOrbitMission291" in app
assert 'accessibilityIdentifier("pc602-orbit-enter-context")' in page
assert "driver.hud.canDock" in page and "driver.requestAuthoredMission()" in page
assert "if result == .orbit" in driver
assert "session?.finishPhysicalH55Visit()" in driver
assert "session?.refreshCommittedCampaign(source.completedMask)" in driver
assert "finishMission(" not in driver

# Source Game.StepHomeWeaponTest292 is real, non-hostile and uses the
# player's actual original saved C279 shop, never fabricated gun ownership.
assert "PC602HomeWeaponTest292" in session
assert "weapons.step(ship:flight.flight,dt:dt" in session
assert "snapshot.held(6,profile:controls)" in session
assert "Sector01Shop568.load()" in driver
assert "shop.weapon.rawValue" in driver
assert "shop.upgradeLevel" in driver and "shop.rapidLevel" in driver
assert "touchFire:touchFire,dt:Float(dt)" in driver
assert "func setFiring(_ firing:Bool)" in driver
assert "onFire:{driver.setFiring($0)}" in page
assert "onAim:{driver.setTouch(aim:$0)}" in page
assert "onMove:{driver.setTouch(move:$0)}" in page
assert "touchFire=false" in driver
assert "HomeShotPass292" in weapons or "StepHomeWeaponTest292" in weapons
assert "Sphere67.advance(bullet.position," in weapons
assert "Sphere67.transport(world,from:sourceNormal" in weapons
assert "projectiles.count<=140" in weapons
assert "case pulse=0,twin=1,scatter=2,rail=3,swarm=4" in weapons
assert "PC602HomeShotGeometry292.build(" in shot_renderer
assert "let ribbonVertices=PC602HomeShotGeometry292.build(" in shot_renderer
assert "triply" in shot_renderer or "triple" in shot_renderer
assert "DispatchSemaphore(value:3)" in shot_renderer
assert "command.addCompletedHandler" in shot_renderer
assert "ribbonSegments=6" in shot_geometry and "ribbonLayers=3" in shot_geometry
assert "orbVerticesPerShot=(32+28+24)*6" in shot_geometry
assert "sourceRGBBlendFactor = .sourceAlpha" in shot_renderer
assert "discs.colorAttachments[0].sourceRGBBlendFactor = .one" in shot_renderer
assert "PC602HomeShipPose291.originalWorldScale" in shot_geometry
assert "let sideRaw=cross(b-a,camera-middle)" in shot_geometry
assert "pc602HomeShotVertex292" in shot_shader
assert "pc602HomeShotFragment292" in shot_shader
assert "originalShots=try SourceHomeShots292(device:device)" in world
assert "originalShots.draw(encoder:encoder,command:command," in world
assert "onProjectiles:{driver.readProjectiles()}" in page

# Source OrbitHud330 (not a made-up mini-map) and the same 26 real PC
# campaign bits/unlocks have functional large touch targets.
assert "enum PC602OrbitHud330" in atlas
assert "let row=n.y>1/3 ? 1:n.y < -1/3 ? 2:0" in atlas
assert "source.orbitDistance<12" in atlas
assert "source.home.surface(p)" in atlas
assert "PC602OrbitHud330.measure(flight)" in driver
assert "selectedUnlocked:source330?.unlocked" in driver
assert "completedMask:flight.completedMask" in driver
assert "CampaignStore556.save(saved)" in driver
assert "driver.selectMission(level)" in page
# PC602 Windows/src/Orbit50.cs:92 OrbitClick51: compact atlas tiles
# are clickable, select only available missions, never complete them.
# The large modal remains the accessible alternative on phone.
compact = page.split("private func compactAtlas330(",1)[1].split(
    "private func statusText(",1)[0]
assert "ForEach(0..<4,id:\\.self)" in compact
assert "ForEach(0..<8,id:\\.self)" in compact
assert "let sector=row*8+column+1" in compact
assert "if sector<=26 {" in compact
assert "driver.selectMission(sector)" in compact
assert ".disabled(!available || driver.paused)" in compact
assert 'pc602-orbit-compact-sector-' in compact
assert ".allowsHitTesting(false)" not in compact
assert ".accessibilityHidden(true)" not in compact
assert "driver.selectMission(level)" in page

assert "ForEach(1...26,id:\\.self)" in page
assert 'accessibilityIdentifier("pc602-orbit-original-26-tile-atlas330")' in page
assert "driver.hud.courseDegrees" in page
assert "PC602OrbitNavigation50.arrow(" in page
assert "routeDirection(_ source:PC602HomeFlight291)" in atlas
assert "func enterOrbit602()" in source("OriginalAudioAV568.swift")
assert "audio.enterOrbit602()" in app
assert "Audio" not in source("SourceCombatTouchZones568.swift")
assert "guard SourceNewGame568.create(choice)" in app
assert "showingHomeWorld291=true" in app
assert 'Button("WEJDŹ")' in page
assert "driver.hud.altitude" in page
assert "driver.hud.zone" in page

# Actual, source-socketed v491 plasma. No visual replacement for any of the
# original six ship types. Engine effects are visibly rendered, not a stub.
assert "SourceVanguardMesh431(data:originalMesh)" in ship
assert "baked.engines.count==2" in ship
assert "pc602HomePlasmaVertex491" in ship
assert "pc602HomePlasmaFragment491" in ship
assert "flight.flight.flight.visualPower" in ship
assert "flight.sideThrust" in ship
assert "vertexCount:1728" in ship
assert "vertexStart:1728" in ship
assert "timePowerSideSize" in plasma
assert "engine0" in plasma and "engine1" in plasma
assert "const uint engineVertices=3u*layerVertices;" in plasma
assert "uint segment=slot/6u;" in plasma
assert "sin(t*11-time*11" in plasma
assert "pow(max(.035f,1.0f-t),.58f)" in plasma
assert "float plume=.17f+power*1.47f;" in plasma
assert "float g=layer==2u ? .96f-.19f*t" in plasma
assert "float b=layer==2u ? .49f*(1.0f-t):.035f;" in plasma
assert "sourceRGBBlendFactor = .sourceAlpha" in ship
assert "destinationRGBBlendFactor = .one" in ship

print("PASS source PC602: live W3 -> original Metal H290 -> H55 -> orbit,")
print("     only real Carbonis01 mission entry, same 60Hz flight/renderer clock,")
print("     saved PC586 remapping, source Vanguard 2-engine plasma and pause.")
print("LIMIT: actual iPhone/iPad GPU image, all 26 missions, weapons,")
print("       complete PC HUD and installable IPA not certified by this test.")
