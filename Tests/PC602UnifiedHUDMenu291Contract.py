#!/usr/bin/env python3
"""HUD v600 vs H290: real UIKit taps and one consistent pause/settings/save UI."""
from pathlib import Path
import hashlib
# Explicit source lock requested by the user: changing the working mission
# F6 editor or its game integration requires a SEPARATE authorization.
# Git blob OIDs are captured from the untouched PR #29 source.
MISSION_HUD_LOCK = {
    "ASTEROIDYiOS/HudLayoutEditor600.swift": "249503729d8b9930a22e5cec86fa2119b37f98e5",
    "ASTEROIDYiOS/HudControlLayout600.swift": "5088242f4cde496fa73aea37d5fcef71c80f1273",
    "ASTEROIDYiOS/HudLayout600.swift": "ee92971cda95f6c93e3dd24aad72a996c6afc7e0",
    "ASTEROIDYiOS/HudEditorGeometry.swift": "12bcc2a8216c7e9559f22a198359b519222de388",
    "ASTEROIDYiOS/Sector01Scene568.swift": "7ad47ea68e002c84fbcbc30a72215920d5e73588",
}
for filename, git_oid in MISSION_HUD_LOCK.items():
    data=(Path(__file__).resolve().parents[1]/filename).read_bytes()
    actual=hashlib.sha1(b"blob "+str(len(data)).encode()+b"\0"+data).hexdigest()
    assert actual==git_oid, "MISSION EDITOR READ-ONLY LOCK: "+filename
root=Path(__file__).resolve().parents[1]
read=lambda p:(root/"ASTEROIDYiOS"/p).read_text()
orbit=read("PC602HomeWorldPage291.swift")
mission=read("Sector01Scene568.swift")
pause=read("SourcePauseMenu568.swift")
settings=read("CarbonisVisualSettingsPanel568.swift")
editor=read("PC602OrbitHUDEditor291.swift")
layout=read("PC602OrbitHUDLayout291.swift")
slots=read("PC602SaveSlots61View.swift")
combat_editor=read("HudLayoutEditor600.swift")

for source in (editor,combat_editor):
    for anchor in ("UIPinchGestureRecognizer(","override func touchesBegan(",
                   "override func touchesMoved(","override func touchesCancelled("):
        assert anchor in source,anchor
for anchor in ("OrbitEditorTouchCanvas291(","onSelect?(id)",
               "onMove?(start.element.id","onScale?(start.id",
               "private func hit(_ point:CGPoint)","id.hasPrefix(\"control.\")",
               "PC602OrbitHUDLayout291.hit(",
               "PC602OrbitHUDLayout291.decodeJSON",
               ".fileImporter(", ".fileExporter(","WIDOCZNY",
               "PRZYWRÓĆ TEN ELEMENT","PRZYWRÓĆ CAŁY UKŁAD PC v602"):
    assert anchor in editor,anchor
for anchor in ("measuredFrames:orbitFrames291",
               "navigationFrames:navigationHitRects291(",
               'marker.frame(in:.named("orbitHUD291"))',
               'key:OrbitHUDFramePreference291.self',
               '.onPreferenceChange(OrbitHUDFramePreference291.self)',
               'onEditOrbitHud:{openOrbitHUDEditor291()}',
               'guard showingOrbitOptions291 && showingOrbitSettings291 else{return}'):
    assert anchor in orbit,anchor
assert 'w3-interface-edit-orbit-hud291' in settings
assert 'EDYTUJ HUD / PRZYCISKI H290' not in orbit
assert 'SourcePauseMenu568(' in orbit and 'SourcePauseMenu568(' in mission
for title in ("USTAWIENIA","ZAPISY / 3 SLOTY","KONTYNUUJ","WYJDŹ DO MENU"):
    assert title in pause,title
assert 'minHeight:compact ? 48:58' in pause
assert 'minHeight:compact ? 52:64' in slots
assert 'minHeight:compact ? 52:60' in slots
for name in ("PC602HomeWorldPage291.swift","Sector01Scene568.swift","W3MainMenu568.swift"):
    assert 'PC602SaveSlots61View(' in read(name),name
assert 'slotsReturnToPause291=true' in orbit
assert 'showingMissionSettings568=true' in mission
assert 'missionSettingsScreen568(compact:compact)' in mission
assert 'sector01-settings-planetarium-import' in mission
assert 'minHeight:compact ? 50 : 54' in settings
assert 'visible=try data.decodeIfPresent(Bool.self,forKey:.visible) ?? true' in layout
assert 'static let ids=legacyIDs+[' in layout
assert 'Set(Self.legacyIDs)' in layout
assert 'static func hit(x:Double,y:Double,' in layout
assert 'struct Rect:Equatable' in layout
assert 'PC602OrbitHUDLayout291.hit(' in editor
assert 'Self.scaleRange(for:$0.id).contains($0.scale)' in layout
for key in ("hud.mission.heading","hud.mission.distance","hud.telemetry.speed",
            "hud.dock.status","hud.navigation.label","hud.warning","hud.error"):
    assert key in layout and f'orbitItem291("{key}",screen:screen)' in orbit,key
assert "onMove?(start.element.id" in editor
assert "pinchStart=(selection,layout.item(selection).scale)" in editor
assert "let ordered=PC602OrbitHUDLayout291.ids.filter{$0 != selection}" in editor
assert 'if showingOrbitHUD291 && !id.hasPrefix("hud.navigation")' in orbit
assert 'navigationFrames:navigationHitRects291(' in orbit
assert 'if showingOrbitHUD291 && !id.hasPrefix("hud.navigation")' in orbit
assert 'PC602OrbitHUDLayout291.constrainedDrag(' in editor
assert 'safeInsets:geo.safeAreaInsets' in editor
assert 'start.frame)' in editor
assert 'static func constrainedDrag(' in layout
# Frame tracking has to travel THROUGH the same view transform as the
# actual button, not remain in the original SwiftUI layout slot.
item_section=orbit.split("private func orbitItem291",1)[1].split(
    "private func navigationHitRects291",1)[0]
assert item_section.index(".background {") < item_section.index(".scaleEffect(item.scale)") < item_section.index(".offset(")
assert "guard orbitDraft291.save()," in orbit
assert "PC602OrbitHUDLayout291.load()==orbitDraft291" in orbit
assert "return true" in orbit.split("onSave:{",1)[1].split("onCancel:{",1)[0]
for id in ("control.options","control.atlas","control.next","control.pause","control.enter"):
    assert f'orbitItem291("{id}",screen:screen)' in orbit,id
    assert id in layout,id
assert "range:-1280...1280" in editor and "range:-720...720" in editor
assert "(-1280...1280).contains($0.x)" in layout
assert "(-720...720).contains($0.y)" in layout
print("PASS H290: 5 editable controls, post-transform hit frames, full-screen moves, verified save; mission editor source frozen")
