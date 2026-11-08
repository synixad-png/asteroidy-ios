#!/usr/bin/env python3
"""Source contract for deferred iPhone-only Metal drawable acquisition.

The test guards routing and original FX shape/call arguments; this cannot
replace an interactive GPU measurement on physical iPhone and iPad.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
read=lambda p:(root/p).read_text(encoding="utf-8")
scene=read("ASTEROIDYiOS/Sector01CarbonisPreview568.swift")
stream=read("ASTEROIDYiOS/CarbonisFXStreamingBuffers568.swift")
perf=read("ASTEROIDYiOS/SourcePerformance568.swift")
phone=read("ASTEROIDYiOS/PhoneCombatResolution568.swift")
audio=read("ASTEROIDYiOS/OriginalAudioAV568.swift")
physics=read("ASTEROIDYiOS/CarbonisCombat568.swift")
shot=read("ASTEROIDYiOS/CarbonisProjectileFX69.swift")
explosion=read("ASTEROIDYiOS/CarbonisExplosion524Meshes.swift")

# iPad and menu must retain their unchanged native Metal framebuffer setup;
# the new path is gated by BOTH physical phone idiom AND active mission.
assert "let adaptivePhoneCombat568=gameSession != nil &&" in scene
assert "UIDevice.current.userInterfaceIdiom == .phone" in scene
assert "view.preferredFramesPerSecond=gameSession == nil ? 30 : 60" in scene
assert "if adaptivePhoneCombat568,let session=gameSession {" in scene
assert "if !adaptivePhoneCombat568 {fxStream568.beginFrame()}" in scene
assert "if !adaptivePhoneCombat568 {" in scene
assert "session.frame(at:now)" in scene  # existing iPad step preserved

# The iPhone executes the complete ORIGINAL source geometry functions after
# simulation and BEFORE the first call to CAMetalLayer.nextDrawable.
draw=scene.split("func draw(in view:MTKView) {",1)[1]
phone_prep=draw.split("if adaptivePhoneCombat568,let session=gameSession {",1)[1]
before=phone_prep.split("let requestedDrawable=view.currentDrawable",1)[0]
for name in (
    "session.frame(at:physicsStart)",
    "CarbonisProjectileFX69.indexedGroundLights(",
    "CarbonisProjectileFX69.indexedVertices(",
    "CarbonisProjectileFX69.muzzleFlashes(",
    "Self.warningVertices(session.game.shooters)",
    "Self.tokenVertices(session.game.tokenPickups)",
    "CarbonisExplosion524Meshes.vertices(",
    "phoneFX=PhonePreparedFX568(",
    "fxStream568.beginFrame()",
):
    assert name in before,name
assert before.index("session.frame(at:physicsStart)") < before.index(
    "CarbonisProjectileFX69.indexedGroundLights(")
assert before.index("CarbonisProjectileFX69.indexedVertices(") < before.index(
    "CarbonisExplosion524Meshes.vertices(")
assert "phoneFX?.projectileMs" in draw
assert "phoneFX?.destructionMs" in draw
assert "if let prepared=phoneFX {" in draw
assert draw.count("if let prepared=phoneFX {")==3
assert "ground=CarbonisProjectileFX69.indexedGroundLights(" in before
assert "glow:fxBudget.drawBulletGlow" in before
assert "drawableHeight:Float(screenSize.height)" in before
assert "aspect:frameAspect" in before
assert "settings:visualSettings,budget:fxBudget" in before
assert "let requestedDrawable=view.currentDrawable" in draw
assert "let drawableReady=ProcessInfo.processInfo.systemUptime" in draw
assert "let phoneDrawableWaitMs=(drawableReady-drawableRequestStart)*1000" in draw
assert "let phoneCommandSetupMs=(acquired-drawableReady)*1000" in draw
assert "let phoneStreamWaitMs" not in draw or "var phoneStreamWaitMs" in draw
assert "phoneStreamWaitMs+phoneDrawableWaitMs" in draw
assert "if adaptivePhoneCombat568 {fxStream568.abortFrame()}" in draw
assert "fxStream568.completeFrame(command)" in draw
assert "command.commit()" in draw

# Missing drawable must not leave the stream-slot semaphore permanently held.
assert "func abortFrame() {" in stream
assert "guard slot>=0 else {return}" in stream
assert stream.count("inFlight.signal()")>=2
assert "private let inFlight=DispatchSemaphore(value:3)" in stream
assert "command.addCompletedHandler { [inFlight] _ in inFlight.signal() }" in stream

# The live FPS display retains old source options and identical iPad format.
assert "drawableWaitMs:Double?=nil,streamWaitMs:Double?=nil" in perf
assert "if let drawableWaitMs,let streamWaitMs {" in perf
assert "phoneWaitSamples+=1" in perf
assert "phoneWait=[drawableWaitTotal/pn,streamWaitTotal/pn]" in perf
assert 'String(format:"\\nWAIT drawable %.1f / stream %.1f ms"' in perf
assert 'let phoneText=phoneWait.map {' in perf
assert 'let newText=' in perf
assert "drawableWaitMs:adaptivePhoneCombat568" in scene
assert "streamWaitMs:adaptivePhoneCombat568" in scene
assert "case .native:return 1.0" in phone
assert "case .balanced:return 0.84" in phone
assert "case .performance:return 0.74" in phone

# No regression in critical cross-device original sample or ballistics.
assert "invalidateSuspendedEffects568()" in audio
assert "guard phase == .playing else{return}" in physics
assert "static func indexedGroundLights(" in shot
assert "static func indexedVertices(" in shot
assert "static func vertices(" in explosion
print("PASS iPhone source geometry built before drawable, genuine split waits and emergency semaphore release")
print("PASS iPad 100% native framebuffer + old simulation/render paths gated off from iPhone change")
print("PASS v568 shot/explosion geometry and #141 audio intact, #142 iPhone resolution tiers preserved")
print("LIMIT iPhone/iPad hardware FPS not measured by static contract")
