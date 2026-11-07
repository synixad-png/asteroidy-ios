#!/usr/bin/env python3
"""Regression against user-reported silence after locking an iPad in CARBONIS.

This is a source-flow contract; audible playback still requires an iPad test.
Original Windows v568 sound variants and per-code gain must stay identical.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
audio=(root/"ASTEROIDYiOS/OriginalAudioAV568.swift").read_text()
scene=(root/"ASTEROIDYiOS/Sector01Scene568.swift").read_text()
app=(root/"ASTEROIDYiOS/App.swift").read_text()
engine=(root/"ASTEROIDYiOS/OriginalEnginePlayback52.swift").read_text()

def segment(begin,end):
    assert audio.count(begin)==1,(begin,audio.count(begin))
    start=audio.index(begin)
    assert end in audio[start:],end
    return audio[start:audio.index(end,start)]

# Cold-start source samples are never changed, re-synthesized or substituted.
assert "Array(10...14).flatMap" in audio
assert "Array(20...22).flatMap" in audio
assert "SFX\\(code)_\\((10...30).contains(code) ? variation % 3 : 0)" in audio
assert "player.volume = Float(settings.effectsPercent)/100 * gain" in audio
assert "effects.count>=16" in audio
assert "OriginalMusicSynth568.generate(track:index" in audio

# The root regression: prior code only .pause()'d all stale effect players,
# left them inside prewarmedEffects and ignored AVAudioPlayer.play() failure.
reset=segment("    private func invalidateSuspendedEffects568() {",
              "    private func reactivateAudioSession568() -> Bool {")
for needle in ("effects.forEach { $0.stop() }",
               "effects.removeAll(keepingCapacity:true)",
               "spokenVoices.forEach { $0.stop() }",
               "spokenVoices.removeAll(keepingCapacity:true)",
               "prewarmedEffects.removeAll(keepingCapacity:true)"):
    assert needle in reset,needle

lifecycle=segment("    func sceneIsActive(_ active: Bool) {",
                  "    func sourceEnginePower(_ raw:Float) {")
assert "invalidateSuspendedEffects568()" in lifecycle
assert "effects.forEach { $0.pause() }" not in lifecycle
assert lifecycle.index("invalidateSuspendedEffects568()")<lifecycle.index("restoreAudioAfterActivation568(rebuildPlayer:wasSuspended)")
interrupt=segment("    private func handleSystemAudioInterruption568(",
                  "    private func restoreAudioAfterActivation568(")
assert "case .began:" in interrupt
assert "invalidateSuspendedEffects568()" in interrupt
assert "case .ended:" in interrupt

effects=segment("    func sourceEffect(_ code: Int) {",
                "    func preview(_ index:Int) {")
for needle in (
    "guard !suspended, !audioInterrupted, !missionUserPaused,",
    "guard let file = sounds[stem] else { return }",
    "let pool = prewarmedEffects[stem] ?? []",
    "if let available=pool.first(where:{!$0.isPlaying})",
    "let new=try AVAudioPlayer(contentsOf:file)",
    "var audiblePlayer=player",
    "if !player.play() {",
    "let fresh=try AVAudioPlayer(contentsOf:file)",
    "guard fresh.play() else {",
    "prewarmedEffects[stem]?.removeAll { $0 === player }",
    "prewarmedEffects[stem,default:[]].append(fresh)",
    "effects.append(audiblePlayer)",
):
    assert needle in effects,needle
assert effects.index("if !player.play() {")<effects.index("effects.append(audiblePlayer)")
assert "effects.append(player)" not in effects
assert "player.play()\n        } catch" not in effects # do not ignore result
assert 'sourceStatus="IOS SFX \\(code) — NIE MOŻNA ODTWORZYĆ"' in effects
assert "audio.sourceEffect(code)" in app

restore=segment("    private func restoreAudioAfterActivation568(",
                "    func missionUserPause568(_ paused:Bool)")
assert "_=current.play()" in restore # immediate fast resume before new WAV
assert restore.index("_=current.play()")<restore.index("let replacement=try AVAudioPlayer(contentsOf:file)")
assert "defer {" in restore and "enginePlayback52.start()" in restore
assert restore.index("defer {")<restore.index("if rebuildPlayer,let file=urls[index]")
assert "replacement.currentTime=max(0,current.currentTime)" in restore
assert "prewarmedMusic[index]=replacement" in restore
pause=segment("    func missionUserPause568(_ paused:Bool) {",
              "    func sceneIsActive(_ active: Bool) {")
assert "restoreAudioAfterActivation568(rebuildPlayer:false)" in pause
assert "restoreAudioAfterActivation568(rebuildPlayer:true)" not in pause
assert "sceneIsActive(phase == .active)" in app
assert 'onMissionPause:{ paused in' in app
assert "session.paused=userPaused" in scene
assert "try self.audio.start()" in engine
assert "try AVAudioSession.sharedInstance().setActive(true)" not in engine

print("PASS iOS shot/explosion lock: discard invalid SFX pools, lazy exact-sample reprepare, failed play retry, fast music-first resume")
