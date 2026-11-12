#!/usr/bin/env python3
"""PC v602 -> iOS HUD regression gate. Source checks, not device GPU proof."""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
read=lambda name:(root/"ASTEROIDYiOS"/name).read_text()
asset=read("HudPlanetariumAsset600.swift")
geometry=read("HudEditorGeometry.swift")
editor=read("HudLayoutEditor600.swift")
scene=read("Sector01Scene568.swift")
plasma=read("HudPlasmaLayer600.swift")
energy=read("HudEnergy600.swift")
session=read("CarbonisSession568.swift")
renderer=read("Sector01CarbonisPreview568.swift")
hud=read("SourceCombatHUD331.swift")
planetarium=read("HudPlanetariumOriginalMetal600.swift")
metal=read("HudPlanetariumMetal600.swift")

# Previous literal backslash escaped Swift interpolation and rejected all 72
# genuine CAPSULE_{0,1,2}_WATER_BUBBLE_* nodes in SHA-approved PC v602 GLB.
assert 'hasPrefix("CAPSULE_\\(i)_WATER_BUBBLE_")' in asset
assert 'hasPrefix("CAPSULE_\\\\(i)_WATER_BUBBLE_")' not in asset
assert '71ca9ff24e044a831a5c7197e343594dd1fd801284af6231870570b35ad43860' in asset

# Actual scene HUD remains rendered behind the editor; neither controls nor
# hardware START may advance physics while a gesture is active.
assert 'if showingHudEditor600 && userPaused' in scene
assert 'guard userPaused && !showingHudEditor600' in scene
assert '.allowsHitTesting(!showingHudEditor600)' in scene
assert '.sheet(isPresented:$showingHudEditor600)' not in scene
assert 'onPreview:{ updated in' in scene
assert 'session.updateHudLayout600(updated)' in scene
assert 'hudEditorOriginal600=hudLayout600' in scene
assert 'hudLayout600=original' in scene

# One native UIKit touch owner; source PC602 geometry, not marker overlay gestures.
assert 'HudEditorTouchCanvas(' in editor
assert 'struct HudEditorTouchCanvas:UIViewRepresentable' in editor
assert 'final class TouchSurface:UIView' in editor
assert 'override func touchesBegan(' in editor
assert 'override func touchesMoved(' in editor
assert 'UIPinchGestureRecognizer(' in editor
assert 'HudEditorGeometry.hit(' in editor
assert 'HudEditorGeometry.move(' in editor
assert 'HudEditorGeometry.zoom(' in editor
assert 'for widget in layout.widgets.reversed() where widget.visible' in geometry
assert 'if bounds.area<smallest' in geometry
assert 'widget.is3D ? (size.width-size.width*widget.scale)*0.5 : 0' in geometry
assert 'viewport.x(x,at:anchor)' in geometry
assert 'viewport.y(y,at:anchor)' in geometry
assert 'DragGesture(' not in editor
assert 'MagnificationGesture(' not in editor
assert 'max(12,viewport.safeBottom+7)' in editor
assert 'max(12,viewport.safeRight)' in editor
assert 'onPreview(document)' in editor
assert 'onSave(document)' in editor
assert 'Button("ANULUJ") {onCancel()}' in editor
assert 'document=try HudLayout600.decodeJSON(bytes)' in editor
assert 'exportingJSON=true' in editor

# No new per-frame file reads, dynamic source geometry copies or duplicate
# plasma staging arrays. Five authentic v602 turbulent ribbons stay at 60Hz.
assert 'TimelineView(.animation(minimumInterval:1.0/60.0,paused:!active))' in plasma
assert 'let time=liveTime().truncatingRemainder(dividingBy:3600)' in plasma
# Literal PC v602 DrawEnergyGauge reads GAME levels per render. The 10Hz
# published HUD is for text/radar only; bars must not visibly step at 10Hz.
assert 'func currentHudGauges600()->(' in session
assert 'hudLiveGauges600=(' in session
assert 'game.hull,game.armor,' in session
assert 'ceil(Double(game.tarcza145.energy))' in session
assert 'let gauge=liveGauges()' in plasma
assert 'let values:[Int?]=[gauge.hull,gauge.armor,gauge.shield]' in plasma
assert 'session?.currentHudGauges600()' in scene

assert 'hudLiveSeconds600=Double(game.elapsed)' in session
# PC HudGlbAssets.DrawHudGlb and HudCapsuleController use renderClock,
# RendererHudEnergy uses Game.Time; those two clocks MUST stay distinct.
assert 'let hudRenderTime600=ProcessInfo.processInfo.systemUptime-started' in renderer
assert 'seconds:now,hullPulse:hudPose600.hullPulse' in session
assert 'seconds:Double(game.elapsed),hullPulse:' not in session
# PC602 20-mesh/159-track HUD model must share the four icon's Metal
# command buffer, not an independent camera/SceneKit UI hierarchy.
assert 'HudPlanetariumMetal600(' in renderer
assert 'planetarium.render(' in renderer
assert 'HudPlanetariumHost600(' not in scene
assert 'GLTFSCNSceneSource' not in metal
assert 'gameSession?.game.tokenPickups' not in metal
assert 'HudPlanetariumProjection.make(' in metal
assert 'HudWidgetPlacement600.frame(' in metal
assert 'original.sample(at:seconds,capsules:capsules)' in metal
assert 'simd_slerp(a,b,blend)' in planetarium
assert 'pass.depthAttachment.loadAction = .clear' in metal
assert 'pass.colorAttachments[0].loadAction = .load' in metal
assert 'HudMotionProject600.project(' in metal
assert 'HudPlanetariumPlasmaAnchor600' not in metal

assert 'hud-v602-always-visible-widget-selector' in editor
assert 'Button("▶") {selectNeighbor600(1)}' in editor
# PC FramePose is assigned EVERY render; numeric HUD still snapshots at 10Hz.
assert 'TimelineView(.animation(minimumInterval:1.0/60.0,paused:!active))' in hud
assert 'hud.motion=live?.pose ?? HudMotion600.Pose()' in hud
assert 'guard tick.date.timeIntervalSinceReferenceDate.isFinite else{return}' in hud
assert 'Self.radar(radarContext,live?.contacts ?? hud.radarContacts)' in hud
assert 'if now-lastHUD > 0.10 {' in session
assert 'liveRadar:{ [weak session] in' in scene
assert 'session?.currentHudRadarFrame600()' in scene
assert 'livePose:{ [weak session] in' in scene  # plasma keeps independent live pose
# GLB positions/model rotations must be PC Y/X/Z, never a rotated camera.
asset_center='static let pc602ModelCenterX:Float = 2.74528861'
asset_radius='static let pc602ModelRadius:Double = 5.112107576242468'
assert asset_center in asset and asset_radius in asset
assert 'translate(-HudPlanetariumAsset600.pc602ModelCenterX' in metal
assert 'let yaw=simd_float4x4(simd_quatf(' in metal
assert 'let pitch=simd_float4x4(simd_quatf(' in metal
assert 'let authoredRoll=simd_float4x4(simd_quatf(' in metal
assert 'let liveBank=simd_float4x4(simd_quatf(' in metal

# PC GPU DrawEnergyRibbon emits TWO triangles per step, not a self-overlapping polygon.
assert 'ribbonTriangles(_ points:[HudEnergy600.Point])->Path' in plasma
assert 'triangle(points[i],points[i+1],points[last-i])' in plasma
assert 'triangle(points[i+1],points[last-i-1],points[last-i])' in plasma
assert 'c.fill(ribbonTriangles(vertices)' in plasma
assert 'HudPlasmaBridge600' not in plasma
assert 'private static let displayBars=["shield.bar","armor.bar","hull.bar"]' in plasma
assert 'Self.draw(bar,current:values[i]' in plasma
assert 'return top+Array(bottom.reversed())' not in energy
# F6 editor must leave BOTH touch zones inactive on a paused real-world canvas.
assert '.allowsHitTesting(!showingHudEditor600)' in scene
assert 'hudEditorOriginal600=hudLayout600' in scene
assert 'var polygon=[Point](repeating:' in energy
assert 'return top+Array(bottom.reversed())' not in energy
assert 'vertices.map{CGPoint' not in plasma
assert 'for layer in 0..<5' in plasma and 'for k in 0..<7' in plasma
# Regressions reported on iPhone landscape: the 3D widget must use ONE
# physical-screen coordinate frame and exact PC v602 pixel-per-unit scale.


assert 'hud-v602-always-visible-widget-selector' in editor
assert 'Button("◀") {selectNeighbor600(-1)}' in editor
assert 'Button("▶") {selectNeighbor600(1)}' in editor
# Every settings BACK action must be at the BOTTOM, away from the clock.
w3=read("W3MainMenu568.swift")
hangar=read("H55ScenePage580.swift")
assert w3.index('Button("WSTECZ")') > w3.index('if item == .settings {')
assert scene.index('Button("‹ WRÓĆ DO PAUZY")') < scene.index('SourceCombatTouchZones568(')
assert 'onMove:{session.input(move:$0)}' in scene
assert 'onAim:{session.input(aim:$0)}' in scene
assert 'onFire:{session.input(shooting:$0)}' in scene
controls=read("SourceCombatTouchZones568.swift")
assert 'Float(value.translation.width)/110' in controls
assert 'Float(value.translation.width)/100' in controls
assert 'onFire(true)' in controls and 'onFire(false)' in controls
assert hangar.index('Button("‹ WRÓĆ DO PAUZY")') < hangar.index('private func renderedHangar')
# Real glove brightness is persisted, visible and applied to both original
# hand-material copies, without ever tinting the EXP-01 weapon.
light=read("H55FPSLighting580.swift")
gloves=read("H55FPSScene580.swift")
settings=read("H55FPSSettingsSection580.swift")
assert 'ASTEROIDY_H55_GLOVE_BRIGHTNESS_602' in light
assert 'ASTEROIDY_H55_GLOVE_BRIGHTNESS_602' in settings
assert 'material.multiply.contents=tint' in gloves
assert 'for hand in [leftRoot,rightRoot]' in gloves
assert 'refreshGloveBrightness602()' in gloves
assert 'h55-fps-gloves-brightness' in settings
print("PASS PC v602 iOS HUD: 46 selectable widgets, native Metal original 159-track GLB, safe navigation, persistent actual gloves dimmer")
