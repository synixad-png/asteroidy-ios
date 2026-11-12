#!/usr/bin/env python3
"""Verified PC602 replay policy, native H290 HUD and SFX regression contract."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def read(path):return (root/"ASTEROIDYiOS"/path).read_text()
app=read("App.swift")
flight=read("PC602HomeWorldDriver291.swift")
combat=read("CarbonisCombat568.swift")
page=read("PC602HomeWorldPage291.swift")
editor=read("PC602OrbitHUDEditor291.swift")
layout=read("PC602OrbitHUDLayout291.swift")
assert "let current=CampaignStore556.load()" in app
assert "selectedSector:sector,campaign:current" in app
assert "entry:entry,campaign:current" in app
assert "campaign=current" in app
assert "guard !isReplay && rock.shardLife<=0" in combat
assert combat.count("let eligible=phase == .playing")==2
assert "let eligible=phase == .playing && !isReplay" not in combat
assert "tryDropLegacyPickup586" in combat and "tryDropCombatSupply586" in combat
assert flight.count("hud=Self.measure(current.0,frames:current.2,weapons:current.1)")>=3
assert 'for _ in old..<next' in page
assert 'PC602OrbitHUDEditor291(' in page
assert 'guard orbitDraft291.save() else{return}' in page
assert 'orbitLayout291=orbitDraft291' in page
assert 'orbitDraft291=orbitLayout291' in page
assert 'guard showingOrbitOptions291 && showingOrbitSettings291 else{return}' in page
assert 'PC602OrbitHUDLayout291.load()' in page
for id in ("hud.mission","hud.telemetry","hud.atlas-grid","hud.dock",
           "hud.entry-label","hud.navigation","control.options","control.atlas",
           "control.next","control.pause","control.enter"):
    assert id in layout
    assert f'orbitItem291("{id}",screen:screen)' in page,id
assert 'Slider(value:Binding(' in editor
assert 'OrbitEditorTouchCanvas291(' in editor
assert 'UIPinchGestureRecognizer(' in editor
assert 'override func touchesBegan(' in editor
assert 'override func touchesMoved(' in editor
assert 'OrbitHUDFramePreference291' in editor
assert 'measuredFrames:orbitFrames291' in page
assert 'PC602OrbitHUDLayout291.decodeJSON' in editor
assert 'PC602OrbitHUDLayout291.hit(point:point,frames:frames,' in editor
assert 'Self.scaleRange(for:$0.id).contains($0.scale)' in layout
assert 'static let ids=legacyIDs+[' in layout
print("PASS PC602 replay enabled, only money suppressed, shot counter stable and orbit HUD editor state")
