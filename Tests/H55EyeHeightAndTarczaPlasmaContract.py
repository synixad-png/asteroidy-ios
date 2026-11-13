#!/usr/bin/env python3
"""Contract: original H55 camera height is configurable without altering walking,
and the active source Tarcza145 produces a real world-space plasma shell.
"""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
ios=root/"ASTEROIDYiOS"
eye=(ios/"H55EyeHeight580.swift").read_text()
hangar=(ios/"H55ScenePage580.swift").read_text()
walker=(ios/"H55Walk580.swift").read_text()
settings=(ios/"CarbonisVisualSettingsPanel568.swift").read_text()
shield=(ios/"SourceShieldShell145.swift").read_text()
metal=(ios/"SourceShieldShell145.metal").read_text()
renderer=(ios/"Sector01CarbonisPreview568.swift").read_text()
# SourceTarcza145 moved unchanged into CombatTarcza145.swift (commit 78b5f6a).
ability=(ios/"SourcePickupAbilities586.swift").read_text()+(ios/"CombatTarcza145.swift").read_text()
combat=(ios/"CarbonisCombat568.swift").read_text()

# Original PC HubWalk375: eye 1.80m, bodyRadius .34, bodyHeight 2.
assert 'static let eyes:Float=1.80, bodyRadius:Float=0.34, bodyHeight:Float=2' in walker
assert 'static let original:Float = H55Walk580.eyes' in eye
assert 'static let minimum:Float = 1.55' in eye
assert 'static let maximum:Float = 2.15' in eye
assert 'private static let key="ASTEROIDY_H55_EYE_HEIGHT_580"' in eye
assert 'return feet+target' in eye
assert 'if clear(feet+test) {return feet+test}' in eye
assert 'return feet+base' in eye
assert 'eyeHeight580=H55EyeHeight580.load()' in hangar
assert 'func setEyeHeight580(_ value:Float)' in hangar
assert 'func refreshEyeHeight580()' in hangar
assert 'H55EyeHeight580.safeY(' in hangar
assert 'physical.cameraClear406(movement.x,height,movement.z,' in hangar
assert 'movement.cameraFeet+H55Walk580.eyes+bounce' not in hangar
assert 'movement.step(dt:dt,' in hangar
assert 'movement.y+H55Walk580.eyes' in hangar  # NPC eye remains source
assert 'loader.refreshEyeHeight580()' in hangar
assert 'Slider(value:$h55Eyes,' in settings
assert 'H55EyeHeight580.save(eyes)' in settings
assert 'fpsLoader?.setEyeHeight580(eyes)' in settings
assert 'h55-settings-eye-height-reset' in settings
assert 'case 9: hangarPage580' in settings

# Authentic manually held shield: original drain, impact and no gameplay
# mutation. The effect uses EXACT same ship transform as source Vanguard.
for source in ('static let maximum:Float = 100','static let initial:Float = 60',
               'static let drainPerSecond:Float = 12',
               'static let impactCost:Float = 35',
               'flash=0.37'):
    assert source in ability,source
# PC608 full-bar reserves (commit a869566) pass the reserve count.
assert 'tarcza145.step(dt:dt,held:shieldHeld,playing:true,\n                       reserve:&shieldCharges)' in combat
assert 'if tarcza145.absorb(invincible:&invincible,\n                            reserve:&shieldCharges) {return}' in combat
# Commit 623a876: the mission loads the equipped ship (KESTREL, VANGUARD or
# BASTION) into one parsed mesh; the shield shell still uses that same mesh.
assert 'let parsed:SourceBakedShipMesh' in renderer
assert 'shieldShell145=try SourceShieldShell145(' in renderer
assert 'sourceMesh:parsed.vertices' in renderer
assert 'if session.game.tarcza145.active,' in renderer
assert 'let source=session.game.tarcza145' in renderer
assert 'shipMatrix:shipMatrix' in renderer
assert 'energy:source.energy,' in renderer
assert 'flash:source.flash)' in renderer
assert 'encoder.setDepthStencilState(noDepthWrite)' in renderer
assert 'encoder.setDepthStencilState(depth)' in renderer
assert 'encoder.drawPrimitives(type:.triangle,vertexStart:0,' in shield
assert 'device.makeRenderPipelineState(descriptor:spec)' in shield
assert 'sourceMesh:Data' in shield
assert 'static let vertexCount=48*24*6' in shield
assert 'original source GPU mesh' in shield.lower() or 'source GPU mesh' in shield
assert 'sourceRGBBlendFactor = .sourceAlpha' in shield
assert 'destinationRGBBlendFactor = .oneMinusSourceAlpha' in shield
assert 'shieldShellVertex145(' in metal
assert 'shieldShellFragment145(' in metal
assert 'energy=clamp(u.state.x,0.0f,1.0f)' in metal
assert 'float impact=clamp(u.state.y/0.37f' in metal
assert 'float veins=pow(' in metal
assert 'float transverse=pow(' in metal
assert 'cameraTime' in metal and 'centerRadius' in metal
assert 'HudPlasmaBridge600' not in renderer
assert 'game.shieldCharges' not in shield
assert 'flight.position=' not in shield and 'flight.velocity=' not in shield
assert 'tarcza145.energy=' not in shield
print("PASS PC602 H55 1.80m configurable visual eyes with clearance; true held Tarcza145 draws one native source-sized plasma dome without changing gameplay")
