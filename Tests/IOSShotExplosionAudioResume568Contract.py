#!/usr/bin/env python3
"""Regression against user-reported silence after locking an iPad in CARBONIS.

This is a source-flow contract; audible playback still requires an iPad test.
Original Windows v568 sound variants and per-code gain must stay identical.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
audio=(root/"ASTEROIDYiOS/OriginalAudioAV568.swift").read_text()
worker=(root/"ASTEROIDYiOS/OriginalShotSFXWorker568.swift").read_text()
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
assert "SFX\(code)_\((10...30).contains(code) ? variation % 3 : 0)" in audio
assert "let volume=Float(settings.effectsPercent)/100 * gain" in audio
assert "OriginalMusicSynth568.generate(track:index" in audio

# The previous iPad lock/unlock audio repair is preserved, but its audio
# players are now exclusively owned by the serial SFX worker.
reset=segment("    private func invalidateSuspendedEffects568() {",
              "    private func reactivateAudioSession568() -> Bool {")
assert "combatSFX568.stopAll(invalidate:true)" in reset
assert "private let combatSFX568=OriginalShotSFXWorker568()" in audio
assert "self.combatSFX568.install(prepared)" in audio
assert "self.sounds = found" in audio

lifecycle=segment("    func sceneIsActive(_ active: Bool) {",
                  "    func sourceEnginePower(_ raw:Float) {")
assert "invalidateSuspendedEffects568()" in lifecycle
assert "effects.forEach { $0.pause() }" not in lifecycle
assert lifecycle.index("invalidateSuspendedEffects568()")<lifecycle.index(
    "restoreAudioAfterActivation568(rebuildPlayer:wasSuspended)")
interrupt=segment("    private func handleSystemAudioInterruption568(",
                  "    private func restoreAudioAfterActivation568(")
assert "case .began:" in interrupt
assert "invalidateSuspendedEffects568()" in interrupt
assert "case .ended:" in interrupt

# New evidence: real iPhone DRAW ~40/s with 4.3ms GPU, but SFX=0 restores
# 60 FPS. Do not block main with prepareToPlay/play/stop/isPlaying or new
# AVAudioPlayer allocation. Retain the original variation/gain and voice cap.
effects=segment("    func sourceEffect(_ code: Int) {",
                "    func preview(_ index:Int) {")
for needle in (
    "guard !suspended, !audioInterrupted, !missionUserPaused,",
    "guard let file = sounds[stem] else { return }",
    "let variation = variant",
    "variant += 1",
    "let gain:Float = (50...57).contains(code) ? 0.84",
    "combatSFX568.play(stem:stem,file:file,code:code,volume:volume)",
):
    assert needle in effects,needle
for forbidden in ("AVAudioPlayer(contentsOf:","prepareToPlay(", ".play()",
                  ".stop()", ".isPlaying", "effects.removeAll"):
    assert forbidden not in effects,forbidden
assert "DispatchQueue.main.async" not in effects
assert "combatSFX568.stopAll(invalidate:false)" in audio

# Source-exact cold warm bank (two per sample) and original four-per-stem
# expansion, global 16 simultaneous voices, failure retry from exact M4A.
for needle in (
    "private let audioQueue=DispatchQueue(",
    "qos:.userInitiated",
    "audioQueue.async { [self] in",
    "func install(_ prepared:[String:[AVAudioPlayer]])",
    "prewarmedEffects=prepared",
    "func stopAll(invalidate:Bool)",
    "effects.forEach {$0.stop()}",
    "effects.removeAll(keepingCapacity:true)",
    "spokenVoices.forEach {$0.stop()}",
    "spokenVoices.removeAll(keepingCapacity:true)",
    "prewarmedEffects.removeAll(keepingCapacity:true)",
    "let pool=prewarmedEffects[stem] ?? []",
    "pool.first(where:{!$0.isPlaying})",
    "pool.count<4",
    "let new=try AVAudioPlayer(contentsOf:file)",
    "new.prepareToPlay()",
    "player.currentTime=0",
    "player.volume=volume",
    "if !player.play() {",
    "let fresh=try AVAudioPlayer(contentsOf:file)",
    "fresh.prepareToPlay()",
    "guard fresh.play() else {",
    "prewarmedEffects[stem]?.removeAll {$0 === player}",
    "prewarmedEffects[stem,default:[]].append(fresh)",
    "effects.removeAll {!$0.isPlaying}",
    "if effects.count>=16 {effects.removeFirst().stop()}",
    "effects.append(audiblePlayer)",
    "spokenVoices.append(audiblePlayer)",
):
    assert needle in worker,needle
assert worker.count("player.prepareToPlay()")==0,"no repeated reprepare on every shot"
assert "AVAudioSession.sharedInstance()" not in worker,"session stays on main"
assert "DispatchQueue.main.async" in worker,"publish only real error on main"
assert worker.index("if !player.play() {")<worker.index("effects.append(audiblePlayer)")
assert 'onError("IOS SFX \(code) — NIE MOŻNA ODTWORZYĆ")' in worker
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

print("PASS iPhone fire/explosion AVAudioPlayer off main; original 16 voices, variants, PCM and gain preserved")
print("PASS iPad lock/unlock: invalidate stale voices on worker, retry exact original file, fast music-first resume")
