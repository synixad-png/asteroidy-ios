#!/usr/bin/env python3
"""HUD v600 vs H290: real UIKit taps and one consistent pause/settings/save UI."""
from pathlib import Path
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
               "max(44,r.width)","PC602OrbitHUDLayout291.decodeJSON",
               ".fileImporter(", ".fileExporter(","WIDOCZNY",
               "PRZYWRÓĆ TEN ELEMENT","PRZYWRÓĆ CAŁY UKŁAD PC v602"):
    assert anchor in editor,anchor
for anchor in ("measuredFrames:orbitFrames291",
               "navigationFrame:navigationHitRect291(",
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
print("PASS unified PC602: PAUZA and 3 slots, H290 touch select/drag/pinch, real layout measurements, JSON migration, larger controls")
