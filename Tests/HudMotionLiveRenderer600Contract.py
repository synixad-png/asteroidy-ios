#!/usr/bin/env python3
"""PC v600 HUD visual pose cadence and same-source synchronization."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
session=(root/"ASTEROIDYiOS/CarbonisSession568.swift").read_text()
renderer=(root/"ASTEROIDYiOS/Sector01CarbonisPreview568.swift").read_text()
planetarium=(root/"ASTEROIDYiOS/HudPlanetariumScene600.swift").read_text()
host=(root/"ASTEROIDYiOS/HudPlanetariumHost600.swift").read_text()
scene=(root/"ASTEROIDYiOS/Sector01Scene568.swift").read_text()
hud=(root/"ASTEROIDYiOS/SourceCombatHUD331.swift").read_text()
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
# Requested fixed screen position for the original PC v602 HUD planetarium.
# Keep the real 159-channel glTF animation, not a moving SwiftUI container.
assert 'HudPlanetariumProjection.make(' in host
assert 'projection: projection,' in host
assert '.frame(width: CGFloat(viewport.width)' in host
assert 'HudMotion600.Pose' not in host
assert 'HudMotionProject600.project(' not in host
assert 'HudPlanetariumProjection.Transform' in planetarium
assert 'hudAnchor=anchor' in planetarium
assert 'hudScale=scaleNode' in planetarium
assert 'camera.orthographicScale=transform.cameraHalfHeight' in planetarium
assert 'func currentHudVisual600()->(' in session
assert 'return (hudLivePose600,hudLiveCapsules600,hudLiveSeconds600)' in session
assert 'liveCapsules: { [weak session] in' in host
assert 'livePose' not in planetarium
assert 'hud.motion=active ? livePose() : HudMotion600.Pose()' in hud
assert 'TimelineView(.animation(minimumInterval:1.0/60.0,paused:!active))' in hud
assert 'livePose:{ [weak session] in' in scene
assert 'let hudRenderTime600=ProcessInfo.processInfo.systemUptime-started' in renderer
assert 'seconds:now,hullPulse:hudPose600.hullPulse' in session
assert 'corona?.advance(at:liveGameTime?() ?? 0)' in planetarium
assert 'camera.eulerAngles=' not in planetarium
assert 'centered.addChildNode(model.rootNode)' in planetarium
assert 'model.rootNode.addAnimationPlayer(player,forKey:' in planetarium

assert 'didApplyAnimationsAtTime' in planetarium
assert 'rollPivot.eulerAngles.z=roll*Float.pi/180' in planetarium
assert 'ScreenLeft = X + (Width - Width*Scale)/2' in placement
assert 'widget.x+sourceWidth/2' in placement and 'widget.y+sourceHeight/2' in placement
assert 'HudWidgetPlacement600.frame(' in icons
assert 'HudLayout600.defaults().widget' not in icons
assert 'private static let defaultLayout600=HudLayout600.defaults()' in icons
assert 'HudLayout600.defaults()' not in renderer.split('func draw(in view:MTKView)')[1], "no HUD JSON decoding inside render callback"
print("PASS live HUD v600: 60Hz Metal pose, fixed full-screen PC602 GLB, 10Hz heavy snapshots, original 159 glTF channels")
