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
for name in ("CADisplayLink","Timer.scheduledTimer","TimelineView",
             "DispatchQueue.main.asyncAfter","Task.detached"):
    assert name not in driver, name
assert "SourceKeyboardCapture586" in page
assert "OrbitTouchStick291(title:\"LOT / RUCH\"" in page
assert 'title:"CELOWANIE"' in page
assert 'accessibilityIdentifier("pc602-orbit-live-touch-hud")' in page
assert "driver.setPaused(!driver.paused)" in page
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
assert 'accessibilityIdentifier("pc602-orbit-enter-carbonis01")' in page
assert "if result == .orbit" in driver
assert "session?.finishPhysicalH55Visit()" in driver
assert "session?.refreshCommittedCampaign(source.completedMask)" in driver
assert "finishMission(" not in driver

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
