#!/usr/bin/env python3
"""PC v600 HUD visual pose cadence and same-source synchronization."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
session=(root/"ASTEROIDYiOS/CarbonisSession568.swift").read_text()
renderer=(root/"ASTEROIDYiOS/Sector01CarbonisPreview568.swift").read_text()
planetarium=(root/"ASTEROIDYiOS/HudPlanetariumScene600.swift").read_text()
host=(root/"ASTEROIDYiOS/HudPlanetariumHost600.swift").read_text()
scene=(root/"ASTEROIDYiOS/Sector01Scene568.swift").read_text()
placement=(root/"ASTEROIDYiOS/HudWidgetPlacement600.swift").read_text()
icons=(root/"ASTEROIDYiOS/HudPickupTransform600.swift").read_text()
for marker in ('private var hudLivePose600=HudMotion600.Pose()',
               'func currentHudRenderState600()->(',
               'return (hudLayoutSnapshot600,hudSafeInsetsSnapshot600,',
               'hudLivePose600,hudLiveCapsules600)',
               'hudLiveCapsules600=hudCapsules600.snapshot',
               'hudLivePose600=hudPose600',
               'hudMotion600.update(motionSample,at:now,',
               'if now-lastHUD > 0.10 {'):
    assert marker in session,marker
sample=session.index('hudMotion600.update(motionSample,at:now,')
live=session.index('hudLivePose600=hudPose600',sample)
semantic=session.index('if now-lastHUD > 0.10 {',sample)
assert sample<live<semantic, "cheap pose every draw, semantic HUD still 10Hz"
assert 'let screen=session.currentHudRenderState600()' in renderer
assert 'pose:screen.pose,' in renderer
assert 'safeLeft:screen.insets.left' in renderer
assert 'viewport:viewport' in renderer
assert 'pose:session.hud.motion,' not in renderer
assert 'HudPlanetariumHost600(' in scene
assert 'livePose:{ [weak session] in' in host
assert 'session?.currentHudVisual600().pose' in host
assert 'HudMotionProject600.project(' in host
assert 'func currentHudVisual600()->(' in session
assert 'return (hudLivePose600,hudLiveCapsules600,hudLiveSeconds600)' in session
assert 'liveCapsules:{ [weak session] in' in host
assert 'let framePose=livePose?() ?? pose' in planetarium
assert 'didApplyAnimationsAtTime' in planetarium
assert 'framePose.roll' in planetarium
assert 'ScreenLeft = X + (Width - Width*Scale)/2' in placement
assert 'widget.x+sourceWidth/2' in placement and 'widget.y+sourceHeight/2' in placement
assert 'HudWidgetPlacement600.frame(' in icons
assert 'HudLayout600.defaults().widget' not in icons
assert 'private static let defaultLayout600=HudLayout600.defaults()' in icons
assert 'HudLayout600.defaults()' not in renderer.split('func draw(in view:MTKView)')[1], "no HUD JSON decoding inside render callback"
print("PASS live HUD v600: 60Hz Metal/SceneKit pose, 10Hz heavy snapshots, PC-centered GLB and notch-safe pixels")
