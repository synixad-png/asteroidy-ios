#!/usr/bin/env python3
"""Keep independently animated PC602 HUD and gameplay motion segregated."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
session=(r/"ASTEROIDYiOS/CarbonisSession568.swift").read_text()
renderer=(r/"ASTEROIDYiOS/Sector01CarbonisPreview568.swift").read_text()
source=(r/"ASTEROIDYiOS/HudPlanetariumOriginalMetal600.swift").read_text()
metal=(r/"ASTEROIDYiOS/HudPlanetariumMetal600.swift").read_text()
scene=(r/"ASTEROIDYiOS/Sector01Scene568.swift").read_text()
hud=(r/"ASTEROIDYiOS/SourceCombatHUD331.swift").read_text()
placement=(r/"ASTEROIDYiOS/HudWidgetPlacement600.swift").read_text()
icons=(r/"ASTEROIDYiOS/HudPickupTransform600.swift").read_text()
for marker in ("private var hudLivePose600=HudMotion600.Pose()",
               "hudLiveCapsules600=hudCapsules600.snapshot",
               "hudLivePose600=hudPose600",
               "hudMotion600.update(motionSample,at:now,",
               "if now-lastHUD > 0.10 {"):
    assert marker in session,marker
assert "hud.motion=active ? livePose() : HudMotion600.Pose()" in hud
assert "TimelineView(.animation(minimumInterval:1.0/60.0,paused:!active))" in hud
assert "let hudRenderTime600=ProcessInfo.processInfo.systemUptime-started" in renderer
assert "let screen=session.currentHudRenderState600()" in renderer
assert "pose:screen.pose," in renderer
assert "let visual=session.currentHudVisual600()" in renderer
assert "seconds:hudRenderTime600,capsules:visual.capsules" in renderer
assert "seconds:visual.seconds,capsules:visual.capsules" not in renderer
assert renderer.index("let hudRenderTime600=ProcessInfo.processInfo.systemUptime-started") < renderer.index("planetarium.render(")
assert "let time=liveTime().truncatingRemainder(dividingBy:3600)" in (r/"ASTEROIDYiOS/HudPlasmaLayer600.swift").read_text()
assert "func currentHudVisual600()->(" in session
assert "return (hudLivePose600,hudLiveCapsules600,hudLiveSeconds600)" in session
assert "HudPickupTransform600.sample(" in renderer
assert "pose:snapshot.pose" in renderer
assert "HudPlanetariumPlasmaAnchor600" not in metal
assert "HudMotionProject600.project(" in metal
assert "widget:widget.id" in metal
assert "pose.roll*pose.weight(widget.id)" in metal
assert "HudPlanetariumMetal600(" in renderer
assert "HudPlanetariumHost600(" not in scene
assert "HudMotionProject600.project(" in metal
assert "livePose" not in metal
assert "gameSession?.game.tokenPickups" not in metal
assert "simd_slerp(a,b,blend)" in source
assert "SIMD3(value.x,value.y,value.z)" in source
assert "HudWidgetPlacement600.frame(" in metal
assert "ScreenLeft = X + (Width - Width*Scale)/2" in placement
assert "widget.x+sourceWidth/2" in placement
assert "HudWidgetPlacement600.frame(" in icons
assert "HudLayout600.defaults() not in renderer.split('func draw(in view:MTKView)')[1]" not in renderer
print("PASS original HUD: icon movement remains independent, planetarium uses glTF animation only and stays screen anchored")
