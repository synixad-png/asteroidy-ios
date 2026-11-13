import json
import re
from pathlib import Path

root=Path(__file__).resolve().parents[1]
approved=json.loads((root/"ASTEROIDYiOS/Assets/hud/default-layout.json").read_text())
code=(root/"ASTEROIDYiOS/HudLayout600.swift").read_text()
editor=(root/"ASTEROIDYiOS/HudLayoutEditor600.swift").read_text()
document=(root/"ASTEROIDYiOS/HudLayoutDocument600.swift").read_text()
scene=(root/"ASTEROIDYiOS/Sector01Scene568.swift").read_text()
hud=(root/"ASTEROIDYiOS/SourceCombatHUD331.swift").read_text()
renderer=(root/"ASTEROIDYiOS/Sector01CarbonisPreview568.swift").read_text()
match=re.search(r'private static let approvedJSON = #"""\s*(.*?)\s*"""#',code,re.S)
assert match, "no immutable PC v600 JSON in native executable"
assert json.loads(match.group(1))==approved,"embedded defaults differ from PC v600"
assert len(approved["widgets"])==46
for symbol in ("ZAPISZ","PRZYWRÓĆ CAŁY UKŁAD PC v602",
               "PRZYWRÓĆ TEN ELEMENT","WIDOCZNY",
               'axis("YAW"','axis("PITCH"','axis("ROLL"'):
    assert symbol in editor,symbol
assert "HudLayoutEditor600(" in scene
assert "initial:hudEditorOriginal600 ?? hudLayout600" in scene
assert "viewport:combatHUDLayout" in scene
assert "onPreview:{ updated in" in scene
assert ".sheet(isPresented:$showingHudEditor600)" not in scene
assert "guard userPaused && !showingHudEditor600" in scene
# The common pause overlay is gated separately from settings, save slots and
# the live HUD editor. Preserve those exclusions instead of matching whitespace.
assert re.search(r"if userPaused && session\.hud\.phase == \.playing &&\s*"
                 r"!showingService && !showingHudEditor600 &&\s*"
                 r"!showingMissionSettings568 && !showingSaveSlots61",scene)
geometry=(root/"ASTEROIDYiOS/HudEditorGeometry.swift").read_text()
assert 'struct HudLayoutEditor600:View' in editor
assert 'HudEditorTouchCanvas(' in editor
assert 'struct HudEditorTouchCanvas:UIViewRepresentable' in editor
assert 'final class TouchSurface:UIView' in editor
assert 'override func touchesBegan(' in editor
assert 'override func touchesMoved(' in editor
assert 'UIPinchGestureRecognizer(' in editor
assert 'func updateUIView(_ view:TouchSurface' in editor
assert 'HudEditorGeometry.hit(' in editor
assert 'HudEditorGeometry.move(' in editor
assert 'HudEditorGeometry.zoom(' in editor
assert 'for widget in layout.widgets.reversed() where widget.visible' in geometry
assert 'if bounds.area<smallest' in geometry
assert 'viewport.x(x,at:anchor)' in geometry
assert 'viewport.y(y,at:anchor)' in geometry
assert 'max(12,viewport.safeBottom+7)' in editor
assert 'max(12,viewport.safeRight)' in editor
assert 'onPreview(document)' in editor
assert 'DragGesture(' not in editor
assert 'MagnificationGesture(' not in editor
assert "session.updateHudLayout600(updated)" in scene
assert 'HudPlanetariumHost600(' not in scene
assert 'HudWidgetPlacement600.frame(' in (root/"ASTEROIDYiOS/HudPlanetariumMetal600.swift").read_text()
for marker in ('layout600:HudLayout600','widgetContext(','"radar"',
               'names[i]+".label"','namesGLB[i]+".icon"',
               'namesGLB[i]+".value"'):
    assert marker in hud,marker
assert "session.currentHudRenderState600()" in renderer
assert "widget.visible" in renderer
assert "widget:widget" in renderer
for marker in ('FileDocument','static var readableContentTypes:[UTType]',
               'HudLayout600.decodeJSON(bytes)','layout.encodeJSON()'):
    assert marker in document, "missing validated native Files JSON exchange: "+marker
for marker in ('"EKSPORTUJ UKŁAD JSON"','"IMPORTUJ UKŁAD JSON"',
               '.fileImporter(','.fileExporter(',
               'document=try HudLayout600.decodeJSON(bytes)'):
    assert marker in editor, "missing user-accessible JSON exchange: "+marker
assert '"ion.icon":"energy"' in code and '"hud.planetarium":"planetarium"' in code
print("PASS iOS HUD v600: exact 46-widget PC layout, native import/export, GLB key gate, touch editor and live native Metal")
