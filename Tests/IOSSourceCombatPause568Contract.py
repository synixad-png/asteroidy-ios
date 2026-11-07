#!/usr/bin/env python3
"""Source-audited iOS pause regression: original Windows v568 Game/Renderer/MusicAudio.

Verified original:
Windows/src/BossTunnelGame.cs:48-50 Pause, Resume, TogglePause;
Windows/src/Game.cs:235 Mode.Paused returns before Game.Step physics;
Windows/src/RendererW3Pause317.cs:31-49 dim original 3D scene, CONTINUE and MENU;
Windows/src/MusicAudio.cs:18,79 paused track unchanged, duck=.55, engine=0.
Only actions already ported are interactive; Save/Load/Exit/Rankings absent.
"""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
scene=(root/"ASTEROIDYiOS/Sector01Scene568.swift").read_text()
session=(root/"ASTEROIDYiOS/CarbonisSession568.swift").read_text()
audio=(root/"ASTEROIDYiOS/OriginalAudioAV568.swift").read_text()
engine=(root/"ASTEROIDYiOS/OriginalEnginePlayback52.swift").read_text()
app=(root/"ASTEROIDYiOS/App.swift").read_text()

def part(text, beginning, end):
    assert beginning in text and end in text, f"Absent section {beginning}"
    return text.split(beginning,1)[1].split(end,1)[0]
# Real flight/enemy/bullet/reward simulation is frozen by existing session
# gate rather than a new fake clock or HUD-only disabled overlay.
assert "guard let lastFrame, !paused else {return}" in session
assert "game.step(move:move,aim:aim,shooting:shooting,dt:dt)" in session
assert "defer{lastFrame=now}" in session
assert "private var userPaused=false" in scene
pause=part(scene,"    private func pauseMission568() {","    private func resumeMission568() {")
for token in ("session.game.phase == .playing","session.release()",
              "userPaused=true","session.paused=true","onEnginePower(0)",
              "onMissionPause(true)"):
    assert token in pause,token
resume=part(scene,"    private func resumeMission568() {","    private func exitMission568() {")
for token in ("session.release()","userPaused=false",
              "session.paused=scenePhase != .active","onMissionPause(false)",
              "onEnginePower(0.16)"):
    assert token in resume,token
assert "onMissionPause:(Bool)->Void" in scene
assert "Button(\"PAUZA\") {pauseMission568()}" in scene
assert "Button(\"KONTYNUUJ\") {resumeMission568()}" in scene
assert "Button(\"WYJDŹ DO MENU\") {exitMission568()}" in scene
assert "sector01-pause-touch-blocker" in scene
assert "sector01-source-pause-overlay" in scene
assert "session.paused=userPaused" in scene # iOS unlock must not unpause user pause
assert "session.game.phase == .playing && !userPaused" in scene
assert "onMissionPause(false)" in scene
assert "audio.missionUserPause568(paused)" in app
assert "audio.missionPhase568(phase)" in app
# Source music continues with paused .55 gain, suppresses engine and new SFX.
pauseAudio=part(audio,"    func missionUserPause568(_ paused:Bool) {",
                    "    func sceneIsActive(_ active: Bool) {")
for token in ("missionUserPaused=paused",
              "musicDuck=paused ? 0.55 : 1",
              "musicGate.setAllowed(paused && !suspended)",
              "music?.volume=masterMusicVolume",
              "engineLevel52=0","enginePlayback52.stop()",
              "engineLevel52=0.16",
              "restoreAudioAfterActivation568(rebuildPlayer:true)"):
    assert token in pauseAudio,token
assert "guard !suspended, !missionUserPaused" in audio
assert "missionUserPaused ? 0 : max(0,min(1,raw))" in audio
assert "missionPhase == .playing && !missionUserPaused" in audio
assert "let wasSuspended=suspended" in audio
assert "restoreAudioAfterActivation568(rebuildPlayer:wasSuspended)" in audio
assert "if rebuildPlayer,let file=urls[index]" in audio
assert "replacement.currentTime=max(0,current.currentTime)" in audio
assert "prewarmedMusic[index]=replacement" in audio
assert "AVAudioPlayer(contentsOf:file)" in audio
assert "if current.isPlaying {return}" in audio # fallback if reopening failed
assert "self.audio.isRunning && self.player.isPlaying" in engine
assert "try self.audio.start()" in engine
assert "try AVAudioSession.sharedInstance().setActive(true)" not in engine
# Original v568 music/SFX synthesis, world, geometry and gameplay left intact.
assert "OriginalMusicSynth568.generate(track:index" in audio
assert "sourceEffect(_ code: Int)" in audio
assert "for _ in 0..<4 {self.schedule()}" in engine
print("PASS v568: source Game.Paused freezes mission, W3 PAUZA/KONTYNUUJ works, original audio ducks to 55%, iPad playback reopens original WAV")
