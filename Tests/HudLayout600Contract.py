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
for symbol in ("ZAPISZ UKŁAD","PRZYWRÓĆ CAŁY UKŁAD PC v600",
               "PRZYWRÓĆ TEN ELEMENT","WIDOCZNY",
               'axis("YAW"','axis("PITCH"','axis("ROLL"'):
    assert symbol in editor,symbol
assert "HudLayoutEditor600 {updated in" in scene
assert "session.updateHudLayout600(updated)" in scene
assert 'planetarium.visible' in scene and 'planetarium.x+125' in scene
for marker in ('layout600:HudLayout600','widgetContext(','"radar"',
               'names[i]+".label"','namesGLB[i]+".icon"',
               'namesGLB[i]+".value"'):
    assert marker in hud,marker
assert "session.currentHudLayout600()" in renderer
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
print("PASS iOS HUD v600: exact 46-widget PC layout, native import/export, GLB key gate, touch editor and live Metal/SceneKit")
