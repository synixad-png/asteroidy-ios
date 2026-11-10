from pathlib import Path

root=Path(__file__).resolve().parents[1]
renderer=(root/"ASTEROIDYiOS/Sector01CarbonisPreview568.swift").read_text()
scene=(root/"ASTEROIDYiOS/Sector01Scene568.swift").read_text()
session=(root/"ASTEROIDYiOS/CarbonisSession568.swift").read_text()
hud=(root/"ASTEROIDYiOS/SourceCombatHUD331.swift").read_text()
model=(root/"ASTEROIDYiOS/HudPickupTransform600.swift").read_text()

for marker in (
    "private var pickupModels586:[SourcePickupModels586.Kind:SourcePickupMetal586]=[:]",
    "private var hudIconsAvailable600=false",
    "hudIconsAvailable600 = pickupPipeline586 != nil && pickupModels586.count==4",
    "gameSession?.setHUD3DIconsReady600(true)",
    "if let session=gameSession,",
    "hudIconsAvailable600,",
    "let screen=session.currentHudRenderState600()",
    "viewport:viewport",
    "pose:screen.pose,",
    "HudPickupTransform600.sample(",
    "HudPickupTransform600.mvp(",
    "encoder.setVertexBuffer(asset.triangles,offset:0,index:0)",
    "encoder.setFragmentTexture(asset.skin,index:0)",
    "encoder.setDepthStencilState(hudIconDepth600)",
):
    assert marker in renderer, marker
assert renderer.count("SourcePickupMetal586(")==1, "HUD must not load extra texture/model copies"
assert "render3DIcons:session.hud3DIconsReady600" in scene
assert "if !renderModel,let icon {" in hud
assert "hud3DIconsReady600=false" in session
assert "static let order:[SourcePickupModels586.Kind]" in model
assert "import SceneKit" not in model, "shared resources must stay in Metal"
assert "session.hud3DIconsReady600," not in renderer, "don't read @Published readiness from GPU render thread"
print("PASS HUD v600: original pickup GPU resources shared with world, 4 model identities, UI fallback and no second upload")
