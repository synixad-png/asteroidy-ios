#!/usr/bin/env python3
"""Live 472 ship scale and 285 projectile light refresh; single lock/pause panel."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
read=lambda f:(root/"ASTEROIDYiOS"/f).read_text()
scale=read("SourceShipScale472.swift")
colors=read("CarbonisVisualSettings568.swift")
home=read("PC602HomeScene291.swift")
lights=read("PC602HomeProjectileLights296.swift")
mission=read("Sector01CarbonisPreview568.swift")
diag=read("MetalRenderer.swift")
page=read("PC602HomeWorldPage291.swift")
assert 'static let revisionKey = "ASTEROIDY.v568.VisualShipScale472.revision"' in scale
assert "defaults.integer(forKey:Self.revisionKey)+1" in scale
assert 'static let revisionKey=sourceKey+".revision"' in colors
assert "defaults.integer(forKey:Self.revisionKey)+1" in colors
assert "private var shipScale472=SourceShipScale472.load()" in mission
assert "if revision != shipScaleRevision472 {" in mission
assert "shipScale472=SourceShipScale472.load()" in mission
assert "private var shipScale472=SourceShipScale472.load()" in diag
assert "if shipScaleRevision != shipScaleRevision472 {" in diag
assert "private var orbitVisualScale:Float" in home
assert "if visualRevision != orbitScaleRevision472 {" in home
assert "orbitVisualScale=SourceShipScale472.load().orbitFactor" in home
assert "private var settings=CarbonisVisualSettings568.load()" in lights
assert "if revision != settingsRevision {" in lights
assert "settings=CarbonisVisualSettings568.load()" in lights
assert "let chosen=CarbonisProjectileFX69.groundTint(source,settings:settings)" in lights
assert "settings.projectileBrightnessFactor" in lights
assert "visualSettings=CarbonisVisualSettings568.load()" in mission
assert 'Button("PAUZA") {openOrbitOptions291()}' in page
assert page.count('Button("PAUZA") {openOrbitOptions291()}')==2
assert 'orbitPausePanel317' not in page and 'showingOrbitPause317' not in page
assert 'if !driver.presentingH55 {' in page
assert 'openOrbitOptions291()' in page
assert 'driver.setPaused(previouslyPausedOptions291)' in page
assert 'SourcePauseMenu568(' in page
assert 'exitID:"pc602-orbit-return-w3"' in page
assert 'onEditOrbitHud:{openOrbitHUDEditor291()}' in page
assert 'openSaves61(load:false,' in page
assert 'orbitDraft291=orbitLayout291' in page
print("PASS source-regression: live ship scale, live projectile lights/colors, one unified interactive H290 PAUZA on touch/lock/pad")
