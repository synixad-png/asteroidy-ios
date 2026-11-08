#!/usr/bin/env python3
"""Guard iPad/PC-source fidelity for the iPhone-only adaptive Metal drawable.

The hardware frame-time cause is NOT established by this static contract.
User-confirmed iPad gameplay and IPA #141 audio are untouched.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
read=lambda name:(root/name).read_text()
scene=read("ASTEROIDYiOS/Sector01CarbonisPreview568.swift")
policy=read("ASTEROIDYiOS/PhoneCombatResolution568.swift")
game=read("ASTEROIDYiOS/CarbonisCombat568.swift")
audio=read("ASTEROIDYiOS/OriginalAudioAV568.swift")
effects=read("ASTEROIDYiOS/CarbonisProjectileFX69.swift")
renderer=read("ASTEROIDYiOS/CarbonisExplosion524Renderer.swift")

# The ONLY entry route to dynamic resolution is a phone with an actual mission.
assert "let adaptivePhoneCombat568=gameSession != nil &&" in scene
assert "UIDevice.current.userInterfaceIdiom == .phone" in scene
assert "gameSession:gameSession,adaptivePhoneCombat568:adaptivePhoneCombat568)" in scene
assert "adaptivePhoneCombat568:Bool=false" in scene
assert "if adaptivePhoneCombat568,let session=gameSession {" in scene
assert "phoneDrawable568.observe(at:entered," in scene
assert "let activeShot=session.shooting ||" in scene
assert "view.autoResizeDrawable=false" in scene
assert "view.drawableSize=wanted" in scene
# The iPad and menu renderer must keep the exact prior MTKView settings.
assert "view.preferredFramesPerSecond=gameSession == nil ? 30 : 60" in scene
assert "view.colorPixelFormat = .bgra8Unorm" in scene
assert "view.depthStencilPixelFormat = .depth32Float" in scene
assert "view.isOpaque=gameplay" in scene
assert "if gameSession == nil && planetFx568.glowEnabled" in scene
assert "let size=view.drawableSize" in scene
assert "let aspect=Float(max(1,size.width)/max(1,size.height))" in scene
assert "MissionViewportFraming568" in scene
# No gameplay or source shader changes: exactly the original projectiles,
# four-layer source ground light settings, explosion and audio callbacks.
assert "CarbonisProjectileFX69.indexedVertices(" in scene
assert "CarbonisProjectileFX69.indexedGroundLights(" in scene
assert "session.game.bullets+session.game.hostileShots" in scene
assert "explosion.render(session.game.destruction," in scene
assert "game.step(move:move,aim:aim,shooting:shooting" not in scene
assert "guard phase == .playing else{return}" in game
assert "static func indexedGroundLights(" in effects
assert "for layer in budget.groundLightLayers" in effects
assert "budget:fxBudget,into:encoder" in scene
assert "originalAudioEvents568" in game
assert "invalidateSuspendedEffects568()" in audio
assert "guard !suspended, !audioInterrupted, !missionUserPaused," in audio
assert "enginePlayback52.start()" in audio
assert "enum Tier:Int,Equatable" in policy
assert "case native=0,balanced=1,performance=2" in policy
assert "case .native:return 1.0" in policy
assert "case .balanced:return 0.84" in policy
assert "case .performance:return 0.74" in policy
assert "projectilesActive && dt>=0.025" in policy
assert "recoveredSeconds>=4.0" in policy
# Pure pixel-layout policy, no new original visual sliders or user settings.
for disallowed in ("UserDefaults","AVAudioSession","AVAudioPlayer",
                   "game.step","CarbonisCombat568"):
    assert disallowed not in policy,disallowed
print("PASS iPhone-only adaptive Metal 100/84/74% drawable; iPad and W3 previews untouched")
print("PASS source fire physics, shot shapes, explosion geometries, audio recovery unchanged")
print("LIMIT: hardware iPhone vs iPad FPS unmeasured; user test required")
