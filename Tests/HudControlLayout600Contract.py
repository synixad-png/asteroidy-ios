#!/usr/bin/env python3
"""Native editable functional controls: visual transform == real touch frame.

No migration of approved PC602 46-widget JSON; the additional buttons are
iOS-only, persisted separately, and do not alter flight/physics inputs.
These are source contracts, not a substitute for iPhone interaction tests.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]/"ASTEROIDYiOS"
source=(root/"HudControlLayout600.swift").read_text()
editor=(root/"HudLayoutEditor600.swift").read_text()
scene=(root/"Sector01Scene568.swift").read_text()
layout=(root/"HudLayout600.swift").read_text()
original=(root/"Assets/hud/default-layout.json").read_text()
assert '"hud.planetarium"' in original
assert original.count('"id":')==46
assert 'widgets.count==46' in layout
assert 'Set(controls.map(\\.id))==Set(Self.ids)' in source
assert 'static let ids=["control.pause","control.bomb","control.shield",' in source
assert '"control.boost","control.options"]' in source
assert 'asteroidy.ios.hud.function-controls.v1' in source
for symbol in ("func control(_ id:String)->Control?",
               "static func frame(_ control:Control,viewport:CombatHUDViewport568,",
               "static func hit(x:Double,y:Double,layout:HudControlLayout600,",
               "mutating func move(_ id:String,from original:Control,",
               "mutating func zoom(_ id:String,originalScale:Double,factor:Double,",
               "func save()->Bool"):
    assert symbol in source,symbol
assert "height:h)" in source
assert "width:w,height:h)" in source
for symbol in ("@State private var hudControlLayout600=HudControlLayout600.load()",
               "hudControlOriginal600=hudControlLayout600",
               "initialControls:hudControlOriginal600 ?? hudControlLayout600",
               "onPreviewControls:{ updated in",
               "onSaveControls:{ updated in",
               "hudControlLayout600=original",
               'Button("PAUZA") {pauseMission568()}',
               'Button("BOMBA \\(session.hud.bombs)") {',
               'Text("TARCZA \\(energy)/100")',
               'Button("DOPALACZ \\(session.hud.boostCharges)/3") {',
               # 82e0d31: the CARBONIS 01 pause uses the one shared
               # SourcePauseMenu568; its settings action opens the same
               # mission settings, so no second Options button exists.
               "SourcePauseMenu568(",
               "onSettings:{showingMissionSettings568=true}",
               "shieldFrame.width",
               "shieldFrame.height",
               "shieldFrame.centerX",
               "shieldFrame.centerY",
               "pauseFrame.centerX",
               "bombFrame.centerX",
               "boostFrame.centerX",
               "showingMissionSettings568=true",
               'DragGesture(minimumDistance:0)',
               "session.holdShield145(true)",
               "session.holdShield145(false)"):
    assert symbol in scene,symbol
assert "hudControlLayout600" not in layout
assert "hudControlLayout600" not in (root/"HudPlasmaLayer600.swift").read_text()
assert "HudControlLayout600.frame(" in scene
assert ".position(x:CGFloat(shieldFrame.centerX),y:CGFloat(shieldFrame.centerY))" in scene
assert ".frame(width:CGFloat(shieldFrame.width)," in scene
for symbol in ("@State private var controlDocument:HudControlLayout600",
               "HudControlLayout600.title(control.id)",
               "onPreviewControls(controlDocument)",
               "controlDocument.save()",
               "onSaveControls(controlDocument)",
               "initialControls:HudControlLayout600",
               "HudControlLayout600.hit(",
               "controlDragStart",
               "controlPinchStart",
               "onControlMove?(start.control.id,start.control,",
               "onControlScale?(start.id,start.scale,Double(gesture.scale))",
               "for control in controlLayout.controls",
               "HudControlLayout600.frame(",
               'Button("ANULUJ") {onCancel()}'):
    assert symbol in editor,symbol
assert 'Button("PRZYWRÓĆ CAŁY UKŁAD PC v602")' in editor
assert 'controlDocument=HudControlLayout600.defaults()' in editor
assert 'HudLayout600.decodeJSON(bytes)' in editor
assert 'onPreview(document)' in editor
assert 'UIPinchGestureRecognizer(' in editor
assert 'override func touchesBegan(' in editor
assert 'override func touchesMoved(' in editor
assert 'onMove?(start.widget.id,start.widget,' in editor
print("PASS 46 PC602 widgets unchanged + 5 independently editable real iOS touch controls: drag, pinch, held shield, pause options and persistence")
