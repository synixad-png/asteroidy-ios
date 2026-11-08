#!/usr/bin/env python3
"""A real 30 FPS iPhone with 4.1ms GPU requires draw-callback pacing evidence.

Pure source-route contract, not an on-device measurement. Preserve the
already-working iPad and full original visual/audio/gameplay paths.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
read=lambda name:(root/name).read_text()
scene=read("ASTEROIDYiOS/Sector01CarbonisPreview568.swift")
perf=read("ASTEROIDYiOS/SourcePerformance568.swift")
cadence=read("ASTEROIDYiOS/PhoneFrameCadence568.swift")
ui=read("ASTEROIDYiOS/CarbonisVisualSettingsPanel568.swift")
audio=read("ASTEROIDYiOS/OriginalAudioAV568.swift")

assert "let adaptivePhoneCombat568=gameSession != nil &&" in scene
assert "UIDevice.current.userInterfaceIdiom == .phone" in scene
phone_branch=scene.split("if adaptivePhoneCombat568,let session=gameSession {",1)[1]
assert "SourcePerformance568.shared.recordPhoneDrawCallback(at:entered)" in phone_branch.split(
    "let activeShot=session.shooting",1)[0]
assert scene.count("SourcePerformance568.shared.recordPhoneDrawCallback")==1
assert "SourcePerformance568.shared.recordPhoneDrawCallback" not in read(
    "ASTEROIDYiOS/MetalRenderer.swift")
assert "view.preferredFramesPerSecond=gameSession == nil ? 30 : 60" in scene
assert "if !adaptivePhoneCombat568 {fxStream568.beginFrame()}" in scene
assert "if !adaptivePhoneCombat568 {" in scene
assert "PhoneFrameCadence568()" in perf
assert "func recordPhoneDrawCallback(at now:TimeInterval)" in perf
assert "if sampling {phoneFrameCadence.drawCallback(at:now)}" in perf
assert "phoneFrameCadence.takeSample(" in perf
assert "private func completedFrame(gpuMs:Double?)" in perf
assert "completed.gpuStartTime" in perf and "completed.gpuEndTime" in perf
assert "String(format:\"\\nDRAW %.0f/s" in perf
assert "phoneCadence.map {" in perf
assert "late24:" in cadence and "late40:" in cadence
assert "if delta<=0 || delta>0.50" in cadence
assert "intervals.sorted()" in cadence
assert "lastCallback=nil" in cadence
for forbidden in ("UIScreen","CADisplayLink(","preferredFramesPerSecond",
                  "AVAudioPlayer","CarbonisCombat568","drawableSize"):
    assert forbidden not in cadence, forbidden
assert "w3-source-show-performance-006" in ui
assert "invalidateSuspendedEffects568()" in audio
assert "CarbonisProjectileFX69.indexedVertices(" in scene
assert "CarbonisExplosion524Meshes.vertices(" in scene
print("PASS iPhone real draw callbacks measured independently of GPU completed FPS")
print("PASS original iPad MTKView path/overlay, FPS option, audio and FX unaffected")
print("LIMIT: physical iPhone 30fps cause remains unconfirmed without new telemetry")
