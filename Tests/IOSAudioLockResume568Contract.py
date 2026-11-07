#!/usr/bin/env python3
"""Regression contract for audio playback after iPad lock -> unlock.

Checks *real* iOS AVAudioSession, AVAudioPlayer and AVAudioEngine paths. These
assertions complement Xcode compilation; only a physical iPad can prove
audible output after lock. They never substitute music, samples or DSP.
"""
from pathlib import Path

root=Path(__file__).resolve().parents[1]
audio=(root/"ASTEROIDYiOS/OriginalAudioAV568.swift").read_text()
engine=(root/"ASTEROIDYiOS/OriginalEnginePlayback52.swift").read_text()
app=(root/"ASTEROIDYiOS/App.swift").read_text()

def segment(source, begin, end):
    assert source.count(begin)==1, f"Missing/duplicate {begin}"
    start=source.index(begin)
    assert end in source[start:], f"Missing next segment {end}"
    return source[start:source.index(end,start)]

assert '.onChange(of: scenePhase) { phase in' in app
assert 'audio.sceneIsActive(phase == .active)' in app
assert 'interruptionObserver = NotificationCenter.default.addObserver(' in audio
assert 'AVAudioSession.interruptionNotification' in audio
assert 'handleSystemAudioInterruption568(note)' in audio
assert 'restoreObserver,interruptionObserver' in audio

reactivate=segment(audio,'    private func reactivateAudioSession568() -> Bool {',
                   '    private func handleSystemAudioInterruption568(')
assert 'setCategory(.ambient,mode:.default)' in reactivate
assert 'setActive(true)' in reactivate
assert 'return false' in reactivate

interrupt=segment(audio,'    private func handleSystemAudioInterruption568(',
                  '    private func restoreAudioAfterActivation568() {')
assert 'case .began:' in interrupt and 'case .ended:' in interrupt
assert 'audioInterrupted=true' in interrupt and 'audioInterrupted=false' in interrupt
assert 'enginePlayback52.stop()' in interrupt
assert 'intro43Player?.pause()' in interrupt and 'music?.pause()' in interrupt
assert 'AVAudioSessionInterruptionWasSuspendedKey' in interrupt
assert 'if wasSuspended {' in interrupt # never steal active calls
assert 'DispatchQueue.main.async' in interrupt  # delayed iOS suspension signal
assert 'if !suspended {restoreAudioAfterActivation568()}' in interrupt

restore=segment(audio,'    private func restoreAudioAfterActivation568() {',
                '    func sceneIsActive(')
assert 'guard !suspended, reactivateAudioSession568() else {return}' in restore
assert restore.index('reactivateAudioSession568()')<restore.index('intro43Player?.play()')
assert restore.index('reactivateAudioSession568()')<restore.index('enginePlayback52.start()')
assert restore.index('reactivateAudioSession568()')<restore.index('current.play()')
assert 'introMissionSector568 != nil' in restore and 'return' in restore
assert 'AVAudioPlayer(contentsOf:file)' in restore # recreate original intro
assert 'prewarmedMusic.removeValue(forKey:index)' in restore
assert 'playTrack(index,resumeAt:offset)' in restore
assert 'current.isPlaying {return}' in restore # repeated foreground no restart
assert 'if current.play() {return}' in restore
assert 'guard settings.musicPercent>0 else {return}' in restore
assert 'if !previewStopped {' in restore
assert 'OriginalAudioCatalog568.missionTrack(sector)' in restore

lifecycle=segment(audio,'    func sceneIsActive(_ active: Bool) {',
                  '    func sourceEnginePower(')
assert 'suspended = !active' in lifecycle
assert 'musicGate.setAllowed(active && missionPhase != .playing)' in lifecycle
for needle in ('enginePlayback52.stop()','intro43Player?.pause()',
               'music?.pause()','effects.forEach { $0.pause() }'):
    assert needle in lifecycle
assert 'restoreAudioAfterActivation568()' in lifecycle
assert 'music?.play()' not in lifecycle # session must reactivate FIRST

assert 'resumeAt:TimeInterval=0' in audio
assert 'player.currentTime=max(0,resumeAt)' in audio
assert 'OriginalMusicSynth568.generate(track:index' in audio
assert 'for index in 2..<OriginalAudioCatalog568.names.count {' in audio
assert 'qos:.utility' in audio
assert 'private let enginePlayback52=OriginalEnginePlayback52()' in audio

start=segment(engine,'    func start() {','    func stop() {')
assert 'self.audio.isRunning && self.player.isPlaying' in start
assert 'self.player.stop()' in start and 'self.audio.stop()' in start
assert 'self.running=false' in start
assert start.index('self.audio.isRunning')<start.index('try self.audio.start()')
assert 'for _ in 0..<4 {self.schedule()}' in start
assert 'dsp.render(engine:target,flame:flame,effectsVolume:volume)' in engine

print("PASS iOS audio lock/unlock: session-first resume, interrupted music/Intro43/engine, original source preserved")
