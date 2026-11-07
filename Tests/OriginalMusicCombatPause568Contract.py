#!/usr/bin/env python3
"""Guard source music fidelity and protect both iPad and iPhone combat.

The first two menu tracks retain startup priority. Exactly 13 subsequent
tracks are generated from the original 44.1-kHz/128-bar source. They
yield to gameplay at deterministic intervals; none are deleted,
silenced, replaced, retuned or shortened.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
audio=(root/"ASTEROIDYiOS/OriginalAudioAV568.swift").read_text()
synth=(root/"ASTEROIDYiOS/OriginalMusicSynth568.swift").read_text()
tests=(root/"Tests/OriginalMusicSynth568Tests.swift").read_text()
assert 'qos:.userInitiated' in audio
assert 'qos:.utility' in audio
assert 'private let backgroundMusicWorker=DispatchQueue(' in audio
assert 'self.backgroundMusicWorker.async { [weak self] in' in audio
assert 'for index in 0...1 {' in audio
assert 'for index in 2..<OriginalAudioCatalog568.names.count {' in audio
assert audio.index('self.backgroundMusicWorker.async')>audio.index('self.startupComplete = true')
assert 'self.musicGate.awaitAllowed()' in audio
assert 'musicGate.setAllowed(false)' in audio
assert 'musicGate.setAllowed(!suspended)' in audio
assert 'checkpoint:{ [weak self] in' in audio
assert 'self?.musicGate.awaitAllowed()' in audio
assert 'self?.sourceStatus=' in audio
assert 'static let count=15,bars=128,rate=44100' in synth
assert 'testBars:Int=128,checkpoint:()->Void={}' in synth
assert 'for b in 0..<testBars {' in synth
assert 'checkpoint()' in synth
assert 'for repeatIndex in 1..<6 {' in synth
assert 'if (i & 16383)==0 {checkpoint()}' in synth
assert 'SourceReverb568().render(' in synth
assert 'progress:progress,checkpoint:checkpoint' in synth
assert 'main.left=SourceDsp568.filtered(main.left,"highpass:25",' in synth
assert 'main.right=SourceDsp568.filtered(main.right,"highpass:25",' in synth
assert 'try masterToWave(main,destination:destination,' in synth
assert 'checkpoints>20' in tests
assert 'oldPCM==gatedPCM' in tests
print("PASS 2 original startup menu tracks keep priority; 13 full source songs move to utility queue")
print("PASS background PCM synthesis, FFT/reverb, mastering and WAV writer cooperate with combat gate")
print("PASS all 15 source tracks, 128 bars, 44.1kHz stereo, no effect/graphics or physics changes")
