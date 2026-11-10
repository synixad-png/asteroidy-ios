#!/usr/bin/env python3
"""PC v602 -> iOS HUD regression gate. Source checks, not device GPU proof."""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
read=lambda name:(root/"ASTEROIDYiOS"/name).read_text()
asset=read("HudPlanetariumAsset600.swift")
marker=read("HudLayoutMarker600.swift")
editor=read("HudLayoutEditor600.swift")
scene=read("Sector01Scene568.swift")
plasma=read("HudPlasmaLayer600.swift")
energy=read("HudEnergy600.swift")
session=read("CarbonisSession568.swift")

# Previous literal backslash escaped Swift interpolation and rejected all 72
# genuine CAPSULE_{0,1,2}_WATER_BUBBLE_* nodes in SHA-approved PC v602 GLB.
assert 'hasPrefix("CAPSULE_\\(i)_WATER_BUBBLE_")' in asset
assert 'hasPrefix("CAPSULE_\\\\(i)_WATER_BUBBLE_")' not in asset
assert '71ca9ff24e044a831a5c7197e343594dd1fd801284af6231870570b35ad43860' in asset

# Actual scene HUD remains rendered behind the editor; neither controls nor
# hardware START may advance physics while a gesture is active.
assert 'if showingHudEditor600 && userPaused' in scene
assert 'guard userPaused && !showingHudEditor600' in scene
assert '.allowsHitTesting(!showingHudEditor600)' in scene
assert '.sheet(isPresented:$showingHudEditor600)' not in scene
assert 'onPreview:{ updated in' in scene
assert 'session.updateHudLayout600(updated)' in scene
assert 'hudEditorOriginal600=hudLayout600' in scene
assert 'hudLayout600=original' in scene

# F6-approved four-anchor coordinate transform, not centered synthetic canvas.
assert 'viewport.originX(for:group)' in editor
assert 'viewport.originY(for:group)' in editor
assert 'HudLayoutMarker600(' in editor
assert 'MagnificationGesture(minimumScaleDelta:0.005)' in marker
assert 'onScale(original*Double(pinch))' in marker
assert 'selected:$selected' in editor
assert 'onPreview(document)' in editor
assert 'onSave(document)' in editor
assert 'Button("ANULUJ") {onCancel()}' in editor
assert 'document=try HudLayout600.decodeJSON(bytes)' in editor
assert 'exportingJSON=true' in editor

# No new per-frame file reads, dynamic source geometry copies or duplicate
# plasma staging arrays. Five authentic v602 turbulent ribbons stay at 60Hz.
assert 'TimelineView(.animation(minimumInterval:1.0/60.0,paused:!active))' in plasma
assert 'let time=liveTime().truncatingRemainder(dividingBy:3600)' in plasma
assert 'hudLiveSeconds600=Double(game.elapsed)' in session
assert 'var polygon=[Point](repeating:' in energy
assert 'return top+Array(bottom.reversed())' not in energy
assert 'vertices.map{CGPoint' not in plasma
assert 'for layer in 0..<5' in plasma and 'for k in 0..<7' in plasma
print("PASS PC v602 iOS HUD source: planetarium interpolation, live paused touch editing, plasma memory and gameplay gates")
