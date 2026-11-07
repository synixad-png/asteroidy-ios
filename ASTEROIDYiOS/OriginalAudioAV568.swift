import Foundation
import AVFoundation
import SwiftUI

/// Source Windows/src/Renderer.cs option indices 8 and 9:
/// MusicPercent 56, EffectsPercent 100, both 0...100, steps of 5.
struct OriginalAudioSettings568: Codable, Equatable {
    static let key = "ASTEROIDY.v568.Original.MusicPercent.EffectsPercent"
    var musicPercent = 56
    var effectsPercent = 100

    mutating func setMusic(_ raw: Int) {
        musicPercent = max(0, min(100, Int((Double(raw)/5).rounded())*5))
    }
    mutating func setEffects(_ raw: Int) {
        effectsPercent = max(0, min(100, Int((Double(raw)/5).rounded())*5))
    }
    func save(_ defaults: UserDefaults = .standard) {
        if let bytes = try? JSONEncoder().encode(self) {
            defaults.set(bytes, forKey: Self.key)
        }
        NotificationCenter.default.post(name: .originalAudioSettings568, object: nil)
    }
    static func load(_ defaults: UserDefaults = .standard) -> Self {
        guard let bytes = defaults.data(forKey: key),
              var result = try? JSONDecoder().decode(Self.self, from: bytes)
        else { return Self() }
        result.setMusic(result.musicPercent)
        result.setEffects(result.effectsPercent)
        return result
    }
}

extension Notification.Name {
    static let originalAudioSettings568 = Notification.Name("ASTEROIDY.originalAudioSettings568")
    static let originalMusicPreview568 = Notification.Name("ASTEROIDY.originalMusicPreview568")
    static let originalMusicStop568 = Notification.Name("ASTEROIDY.originalMusicStop568")
    static let originalMusicReplay568 = Notification.Name("ASTEROIDY.originalMusicReplay568")
    static let originalMusicRestore568 = Notification.Name("ASTEROIDY.originalMusicRestore568")
}

/// Original Windows MusicSynth.cs: 15 tracks, including menu tracks 0 and 1.
/// C# source is archived without modifications under SourceExact568 in repo.
/// The native Swift port synthesizes the original v568 music at EVERY launch.
/// No Music0..14 AAC resources are bundled in IPA; the PCM WAV output is temporary.
enum OriginalAudioCatalog568 {
    static let names = ["Astral Gate", "Orbital Pulse", "Crystal Hive",
                        "Nyx Protocol", "Event Horizon", "Solar Serpent",
                        "Prismatic Drive", "Quantum Lotus", "Alien Resonance",
                        "Neon Shaman", "Helix Reactor", "Plasma Garden",
                        "Fractal Voyager", "Moon Circuit", "Stellar Bloom"]
    static let bpm = [128,140,144,146,148,140,140,140,140,140,140,140,140,140,140]
    static func missionTrack(_ level: Int) -> Int {
        1 + (max(1, level)-1) % (names.count-1) // MusicMix.TrackFor
    }
    static let startupSounds =
        Array(10...14).flatMap { code in (0...2).map { (code, $0) } } +
        Array(20...22).flatMap { code in (0...2).map { (code, $0) } } +
        (0...2).map { (30, $0) } +
        Array(40...45).map { ($0, 0) } + [(60, 0)]
    static func resource(_ stem: String) -> URL? {
        // XcodeGen's folder resource may place assets beneath 'Audio568' or
        // 'Assets/Audio568', depending on project mode. Verify actual file.
        for dir in ["Audio568", "Assets/Audio568"] {
            if let url = Bundle.main.url(forResource: stem,
                          withExtension: "m4a", subdirectory: dir) {
                return url
            }
        }
        return Bundle.main.url(forResource: stem, withExtension: "m4a")
    }
}

/// Audible implementation: native source-equivalent 15-track synthesis on a
/// background worker at launch, using original PCM mastering and temporary WAV.
/// No substitute melodies and no generation on audio/render/touch threads.
/// Original SFX variations use MusicMix.variation++ modulo 3.
private final class SourceBackgroundMusicGate568 {
    private let condition=NSCondition()
    private var allowed=true
    func setAllowed(_ yes:Bool) {
        condition.lock()
        allowed=yes
        if yes { condition.broadcast() }
        condition.unlock()
    }
    func awaitAllowed() {
        condition.lock()
        while !allowed { condition.wait() }
        condition.unlock()
    }
}

final class OriginalAudioAV568: ObservableObject {
    @Published private(set) var sourceStatus = "PRZYGOTOWYWANIE EFEKTÓW"
    @Published private(set) var stage = 0
    @Published private(set) var readyMenuTracks = 0
    @Published private(set) var startupComplete = false
    @Published private(set) var backgroundPrepared = 0
    @Published private(set) var missingAssets: [String] = []

    private enum Context { case menu, mission(Int), diagnostic }
    private var context: Context = .menu
    private var settings = OriginalAudioSettings568.load()
    private var music: AVAudioPlayer?
    private var previousMusic:AVAudioPlayer?
    // Original MusicAudio.TrackFor(Mode.Intro) is the separate 16s
    // IntroMusic43.Track=15, not an ordinary synthesized mission song.
    private var intro43Player:AVAudioPlayer?
    private var introMissionSector568:Int?
    private var fadeTimer:Timer?
    private var fadeStart:TimeInterval=0
    private var effects: [AVAudioPlayer] = []
    // Original MusicAudio.cs: voice announcements interrupt one another.
    private var spokenVoices:[AVAudioPlayer]=[]
    private var musicDuck:Float=1
    // Windows/src/BossTunnelGame.cs PausedFrom=Playing is independent
    // of iOS background suspension. MusicAudio.cs ducks music to 55%.
    private var missionUserPaused=false
    private var missionPhase:CarbonisCombat568.Phase = .playing
    private var masterMusicVolume:Float {
        Float(settings.musicPercent)/100*0.8*musicDuck
    }
    private var prewarmedEffects: [String:[AVAudioPlayer]] = [:]
    private var prewarmedMusic: [Int:AVAudioPlayer] = [:]
    private let enginePlayback52=OriginalEnginePlayback52()
    private var engineLevel52:Float=0
    private var variant = 0
    private var started = false
    private var suspended = false
    // iOS deactivates an audio session when locking/suspending the app.
    // Audio playback must be restored explicitly after the scene is active.
    private var audioInterrupted = false
    private var activeMusicIndex: Int?
    private var urls: [Int:URL] = [:]
    private var sounds: [String:URL] = [:]
    // Track 0/1 keep their original startup priority; the other
    // 13 tracks NEVER compete with gameplay at userInitiated priority.
    private let worker=DispatchQueue(label:"synixad.asteroidy.audio568.source-pack",
                                     qos:.userInitiated)
    private let backgroundMusicWorker=DispatchQueue(
        label:"synixad.asteroidy.audio568.background-music",
        qos:.utility)
    private let musicGate=SourceBackgroundMusicGate568()
    private var settingsObserver: NSObjectProtocol?
    private var previewObserver: NSObjectProtocol?
    private var stopObserver: NSObjectProtocol?
    private var replayObserver: NSObjectProtocol?
    private var restoreObserver: NSObjectProtocol?
    private var interruptionObserver: NSObjectProtocol?
    private var lastPreviewIndex=1
    private var previewActive=false
    private var pendingPreviewIndex:Int?
    private var previewStopped=false

    init() {
        settingsObserver = NotificationCenter.default.addObserver(
            forName: .originalAudioSettings568, object: nil, queue: .main
        ) { [weak self] _ in self?.reloadSettings() }
        previewObserver = NotificationCenter.default.addObserver(
            forName: .originalMusicPreview568, object: nil, queue: .main
        ) { [weak self] notification in
            if let index = notification.object as? Int { self?.preview(index) }
        }
        stopObserver = NotificationCenter.default.addObserver(
            forName:.originalMusicStop568,object:nil,queue:.main
        ) { [weak self] _ in self?.stopMusicPreview() }
        replayObserver = NotificationCenter.default.addObserver(
            forName:.originalMusicReplay568,object:nil,queue:.main
        ) { [weak self] _ in self?.replayMusicPreview() }
        restoreObserver = NotificationCenter.default.addObserver(
            forName:.originalMusicRestore568,object:nil,queue:.main
        ) { [weak self] _ in self?.restoreMenuMusic() }
        interruptionObserver = NotificationCenter.default.addObserver(
            forName:AVAudioSession.interruptionNotification,
            object:AVAudioSession.sharedInstance(),queue:.main
        ) { [weak self] note in self?.handleSystemAudioInterruption568(note) }
    }
    deinit {
        for observer in [settingsObserver,previewObserver,stopObserver,
                         replayObserver,restoreObserver,interruptionObserver] {
            if let observer {NotificationCenter.default.removeObserver(observer)}
        }
    }
    private func reloadSettings() {
        settings = OriginalAudioSettings568.load()
        if fadeTimer != nil {updateMusicFade()}
        else {music?.volume=masterMusicVolume}
        intro43Player?.volume=masterMusicVolume
        enginePlayback52.setPower(engineLevel52,
            effectsVolume:Float(settings.effectsPercent)/100)
        // Original MusicMix uses a live value, not a one-time volume at start.
        // Restoring volume from zero must start the selected source track,
        // unless the real MusicLibrary STOP action is active.
        if settings.musicPercent>0 && music == nil && startupComplete && !suspended {
            switch context {
            case .menu:
                if !previewStopped {playTrack(previewActive ? (pendingPreviewIndex ?? lastPreviewIndex) : 0)}
            case .mission(let sector):
                playTrack(missionPhase == .playing ? OriginalAudioCatalog568.missionTrack(sector) : 0)
            case .diagnostic:break
            }
        }
        // Preserve per-sound source gain, and only scale new voices.
    }
    func prepareMenuAtStartup() {
        guard !started else { return }
        started = true
        // Source MusicBank.Prepare: effects first, then track0, then track1.
        worker.async { [weak self] in
            guard let self else { return }
            var found: [String:URL] = [:]
            var missing: [String] = []
            for (code, variation) in OriginalAudioCatalog568.startupSounds {
                let stem = "SFX\(code)_\(variation)"
                if let file = OriginalAudioCatalog568.resource(stem) {
                    found[stem] = file
                } else { missing.append(stem) }
            }
            for kind in [0,1,2,3,4,6,7] {
                let stem = "Voice\(kind)"
                if let file = OriginalAudioCatalog568.resource(stem) {
                    found[stem] = file
                } else { missing.append(stem) }
            }
            // Original CombatSound.Prepare creates the entire SFX bank
            // BEFORE menu music. Warm two voices per variant so rapid
            // pulses, overlapping impacts and sounds don't read from
            // disk inside touch/render/shot callbacks.
            var prepared: [String:[AVAudioPlayer]] = [:]
            for (stem,file) in found {
                var voices:[AVAudioPlayer]=[]
                for _ in 0..<2 {
                    if let p=try? AVAudioPlayer(contentsOf:file) {
                        p.prepareToPlay()
                        voices.append(p)
                    }
                }
                if voices.isEmpty { missing.append(stem) }
                prepared[stem]=voices
            }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.sounds = found
                self.prewarmedEffects = prepared
                self.stage = 1
                self.sourceStatus = "ASTRAL GATE — PIERWSZY UTWÓR MENU"
            }
            // The original MusicBank creates a private temporary PCM bank
            // on every application launch. Remove previous crash leftovers;
            // these files are not packaged with the app and never persist
            // as a permanent downloaded soundtrack.
            let tmp=FileManager.default.temporaryDirectory
            let fm=FileManager.default
            let outputDirectory=tmp.appendingPathComponent(
                "Asteroidy-music31-\(UUID().uuidString)",isDirectory:true)
            do {
                for item in try fm.contentsOfDirectory(at:tmp,
                     includingPropertiesForKeys:nil) where
                     item.lastPathComponent.hasPrefix("Asteroidy-music31-") {
                    try? fm.removeItem(at:item)
                }
                try fm.createDirectory(at:outputDirectory,
                    withIntermediateDirectories:true)
            } catch { missing.append("Katalog PCM: \(error.localizedDescription)") }
            var menu: [Int:URL] = [:]
            for index in 0...1 {
                let file:URL?
                do {
                    file=try OriginalMusicSynth568.generate(track:index,
                        destination:outputDirectory.appendingPathComponent("Music\(index).wav")) {
                        [weak self] message in
                        DispatchQueue.main.async { [weak self] in
                            self?.sourceStatus="\(OriginalAudioCatalog568.names[index]): \(message)"
                        }
                    }
                } catch {
                    file=nil
                    missing.append("Music\(index): \(error.localizedDescription)")
                }
                if let file {menu[index]=file}
                let completed = index+1
                let readyCount = menu.count
                let menuSnapshot = menu
                let preparedTrack=menu[index].flatMap { url in
                    try? AVAudioPlayer(contentsOf:url)
                }
                preparedTrack?.numberOfLoops = -1
                preparedTrack?.prepareToPlay()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    if let preparedTrack { self.prewarmedMusic[index]=preparedTrack }
                    self.readyMenuTracks = readyCount
                    self.urls.merge(menuSnapshot, uniquingKeysWith: { _, new in new })
                    self.stage = completed+1
                    self.sourceStatus = index==0 ?
                        "ORBITAL PULSE — DRUGI UTWÓR MENU" :
                        "MUZYKA MENU PRZYGOTOWANA"
                }
            }
            let missingSnapshot = missing
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.missingAssets = missingSnapshot
                self.startupComplete = true
                if !missingSnapshot.isEmpty {
                    self.sourceStatus = "BRAKUJE \(missingSnapshot.count) ORYGINALNYCH ZASOBÓW AUDIO"
                }
                if !self.suspended {
                    if case .menu = self.context { self.playTrack(0) }
                    if case .mission(let sector) = self.context {
                        self.playTrack(OriginalAudioCatalog568.missionTrack(sector))
                    }
                }
            }
            self.backgroundMusicWorker.async { [weak self] in
                guard let self else{return}
                // Original MusicBank.Prepare(false): synthesizes remaining 13
                // tracks after menu is ready; pause preparation during combat.
                // Avoid decoding 13 long WAVs into RAM: open only on demand.
                for index in 2..<OriginalAudioCatalog568.names.count {
                    self.musicGate.awaitAllowed()
                    let file:URL
                    do {
                        file=try OriginalMusicSynth568.generate(track:index,
                            destination:outputDirectory.appendingPathComponent("Music\(index).wav"),
                            checkpoint:{ [weak self] in
                                // Pause inside real synthesis/reverb/mastering
                                // chunks, not only every eight arrangement bars.
                                // Keep original PCM and all 15 tracks unchanged.
                                self?.musicGate.awaitAllowed()
                            }) { [weak self] message in
                            self?.musicGate.awaitAllowed()
                            DispatchQueue.main.async { [weak self] in
                                self?.sourceStatus="\(OriginalAudioCatalog568.names[index]): \(message)"
                            }
                        }
                    } catch {
                        DispatchQueue.main.async { [weak self] in
                            self?.missingAssets.append("Music\(index): \(error.localizedDescription)")
                        }
                        continue
                    }
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.urls[index] = file
                        self.backgroundPrepared += 1
                        if !self.suspended,
                           case .menu = self.context,
                           self.pendingPreviewIndex == index,
                           !self.previewStopped {
                            self.pendingPreviewIndex=nil
                            self.playTrack(index)
                        }
                        if !self.suspended,
                           case .mission(let sector) = self.context,
                           self.activeMusicIndex != OriginalAudioCatalog568.missionTrack(sector) {
                            self.playTrack(OriginalAudioCatalog568.missionTrack(sector))
                        }
                    }
                }
            }
        }
    }
    // MusicAudio.cs MusicMix.Render fades equal-power for 88200
    // samples at 44100 Hz (2 seconds) between real 0...14 tracks.
    // Source cinematic Intro43 uses separate rates and is not mixed here.
    private func finishMusicFade() {
        fadeTimer?.invalidate()
        fadeTimer=nil
        previousMusic?.stop()
        previousMusic=nil
        music?.volume=masterMusicVolume
    }
    private func updateMusicFade() {
        guard previousMusic != nil else {finishMusicFade();return}
        let elapsed=ProcessInfo.processInfo.systemUptime-fadeStart
        let gains=OriginalMusicTransition568.gains(seconds:elapsed)
        let master=masterMusicVolume
        music?.volume=master*gains.incoming
        previousMusic?.volume=master*gains.outgoing
        if elapsed>=OriginalMusicTransition568.duration {finishMusicFade()}
    }
    private func playTrack(_ index: Int,resumeAt:TimeInterval=0) {
        guard introMissionSector568 == nil, startupComplete,
              !suspended, settings.musicPercent>0,
              let url = urls[index] else { return }
        if activeMusicIndex==index, music?.isPlaying==true { return }
        finishMusicFade()
        let outgoing = music?.isPlaying==true ? music : nil
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient,mode:.default)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try prewarmedMusic[index] ?? AVAudioPlayer(contentsOf:url)
            player.currentTime=max(0,resumeAt)
            player.numberOfLoops = -1
            player.volume = outgoing == nil ? masterMusicVolume : 0
            player.prepareToPlay()
            guard player.play() else {return}
            music=player
            activeMusicIndex=index
            if let outgoing, outgoing !== player {
                previousMusic=outgoing
                fadeStart=ProcessInfo.processInfo.systemUptime
                updateMusicFade()
                fadeTimer=Timer.scheduledTimer(withTimeInterval:1.0/60.0,
                    repeats:true) { [weak self] _ in
                    self?.updateMusicFade()
                }
            }
            sourceStatus="ODTWARZANIE: \(OriginalAudioCatalog568.names[index])"
        } catch {
            sourceStatus="ORYGINALNY UTWÓR \(index) — BŁĄD: \(error)"
            music=nil
            activeMusicIndex=nil
            finishMusicFade()
        }
    }
    /// Windows Intro41.BeginLevelIntro / MusicAudio.TrackFor:
    /// play the AUTHENTIC 16-second Intro43 PCM converted to M4A, not
    /// song 1 and not a synthetic cinematic approximation.
    func beginMissionIntro568(sector:Int) {
        guard (1...26).contains(sector) else {return}
        intro43Player?.stop()
        intro43Player=nil
        introMissionSector568=sector
        context = .mission(sector)
        missionUserPaused=false
        missionPhase = .playing
        musicGate.setAllowed(false)
        previewStopped=false
        previewActive=false
        pendingPreviewIndex=nil
        musicDuck=1
        engineLevel52=0
        enginePlayback52.stop()
        finishMusicFade()
        music?.stop()
        music=nil
        activeMusicIndex=nil
        if let file=OriginalAudioCatalog568.resource("Intro43") {
            do {
                let player=try AVAudioPlayer(contentsOf:file)
                player.numberOfLoops=0
                player.volume=masterMusicVolume
                player.prepareToPlay()
                intro43Player=player
                if !suspended && settings.musicPercent>0 {
                    player.play()
                }
            } catch {
                sourceStatus="INTRO43 ORYGINALNE — BŁĄD: \(error)"
            }
        } else {
            sourceStatus="BRAK ORYGINALNEGO INTRO43"
        }
    }

    /// Original FinishIntro -> MusicMix.TrackFor(Mode.Playing).
    /// Called exactly once, on automatic 16s completion or Skip.
    func finishMissionIntro568(sector:Int) {
        guard introMissionSector568==sector else {return}
        intro43Player?.stop()
        intro43Player=nil
        introMissionSector568=nil
        enterMission(sector)
    }

    func returnToMenu() {
        intro43Player?.stop()
        intro43Player=nil
        introMissionSector568=nil
        missionUserPaused=false
        musicGate.setAllowed(!suspended)
        previewStopped=false
        previewActive=false
        pendingPreviewIndex=nil
        musicDuck=1
        engineLevel52=0
        enginePlayback52.stop()
        context = .menu
        effects.forEach {$0.stop()}
        effects.removeAll()
        spokenVoices.removeAll()
        if !suspended { playTrack(0) }
    }
    func enterMission(_ sector: Int) {
        guard (1...26).contains(sector) else { return }
        missionUserPaused=false
        musicGate.setAllowed(false)
        previewStopped=false
        previewActive=false
        pendingPreviewIndex=nil
        musicDuck=1
        missionPhase = .playing
        context = .mission(sector)
        // MusicAudio.cs:79 idle power .16, full thrust 1.0, no audio
        // generation in the Metal render loop.
        engineLevel52=0.16
        if !suspended {
            // Keep session activation on the main thread BEFORE starting
            // original DSP; never race two competing category changes.
            if reactivateAudioSession568() {
                enginePlayback52.setPower(engineLevel52,
                    effectsVolume:Float(settings.effectsPercent)/100)
                enginePlayback52.start()
                playTrack(OriginalAudioCatalog568.missionTrack(sector))
            }
        }
    }
    // MusicAudio.cs MusicMix.TrackFor: Victory and GameOver return
    // to song 0; GameOver attenuates music to 40%. A replay restores
    // the normal current-level track and live engine audio.
    func missionPhase568(_ phase:CarbonisCombat568.Phase) {
        // A pending retry's old SwiftUI onChange may arrive just after
        // Intro41 starts. It must NOT restart the battle song or engine
        // underneath the original Intro43 soundtrack.
        guard introMissionSector568 == nil else {return}
        guard case .mission(let sector) = context else {return}
        missionPhase=phase
        switch phase {
        case .playing:
            musicGate.setAllowed(false)
            musicDuck=missionUserPaused ? 0.55 : 1
            engineLevel52=missionUserPaused ? 0 : 0.16
            if !suspended && !missionUserPaused {
                if reactivateAudioSession568() {
                    enginePlayback52.setPower(engineLevel52,
                        effectsVolume:Float(settings.effectsPercent)/100)
                    enginePlayback52.start()
                    playTrack(OriginalAudioCatalog568.missionTrack(sector))
                }
            }
        case .victory,.defeat:
            missionUserPaused=false
            musicGate.setAllowed(!suspended)
            musicDuck = phase == .defeat ? 0.4 : 1
            engineLevel52=0
            enginePlayback52.stop()
            if !suspended {
                playTrack(0)
                if fadeTimer != nil {updateMusicFade()}
                else {music?.volume=masterMusicVolume}
            }
        }
    }
    func stopForDiagnostic() {
        missionUserPaused=false
        intro43Player?.stop()
        intro43Player=nil
        introMissionSector568=nil
        engineLevel52=0
        enginePlayback52.stop()
        context = .diagnostic
        musicDuck=1
        finishMusicFade()
        music?.stop(); activeMusicIndex = nil
        effects.removeAll()
    }
    /// Short one-shot sounds must never be resumed mid-impact after iOS
    /// suspended the app. More importantly, AVAudioPlayer.prepareToPlay()
    /// from before a lock does not guarantee its decoder/queue still works.
    /// Drop all such players; rebuild only the SAME original M4A on the
    /// next shot/explosion, with no resynthesis or FPS-heavy full bank reload.
    private func invalidateSuspendedEffects568() {
        effects.forEach { $0.stop() }
        effects.removeAll(keepingCapacity:true)
        spokenVoices.forEach { $0.stop() }
        spokenVoices.removeAll(keepingCapacity:true)
        prewarmedEffects.removeAll(keepingCapacity:true)
    }
    // Apple may deactivate an AVAudioSession while the iPad is locked.
    // Calling AVAudioPlayer.play() alone on the previously paused player
    // does not reliably restore the underlying audio route/session.
    private func reactivateAudioSession568() -> Bool {
        do {
            let session=AVAudioSession.sharedInstance()
            try session.setCategory(.ambient,mode:.default)
            try session.setActive(true)
            audioInterrupted=false
            return true
        } catch {
            sourceStatus="SESJA AUDIO IOS — WZNOWIENIE: \(error.localizedDescription)"
            return false
        }
    }
    private func handleSystemAudioInterruption568(_ note:Notification) {
        guard let raw=note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type=AVAudioSession.InterruptionType(rawValue:raw) else {return}
        switch type {
        case .began:
            audioInterrupted=true
            // Even an interruption without scenePhase backgrounding may
            // invalidate short SFX queues (Control Center/Siri/call).
            invalidateSuspendedEffects568()
            guard !suspended else {return}
            enginePlayback52.stop()
            intro43Player?.pause()
            finishMusicFade()
            music?.pause()
            // iOS may deliver a "began" for a PAST app suspension only
            // after unlock. Recover this case on the main queue, but never
            // steal audio during a real incoming call/Siri interruption.
            let wasSuspended=(note.userInfo?[AVAudioSessionInterruptionWasSuspendedKey]
                              as? Bool) == true
            if wasSuspended {
                DispatchQueue.main.async { [weak self] in
                    guard let self, !self.suspended, self.audioInterrupted else {return}
                    self.restoreAudioAfterActivation568(rebuildPlayer:true)
                }
            }
        case .ended:
            audioInterrupted=false
            if !suspended {restoreAudioAfterActivation568(rebuildPlayer:true)}
        @unknown default: break
        }
    }
    private func restoreAudioAfterActivation568(rebuildPlayer:Bool=false) {
        guard !suspended, reactivateAudioSession568() else {return}
        if introMissionSector568 != nil {
            // Preserve the original Intro43 instead of starting menu/mission
            // music beneath the still-active 16-second cinematic.
            guard settings.musicPercent>0 else {return}
            if intro43Player?.play() != true,
               let file=OriginalAudioCatalog568.resource("Intro43"),
               let replacement=try? AVAudioPlayer(contentsOf:file) {
                let position=intro43Player?.currentTime ?? 0
                replacement.currentTime=max(0,position)
                replacement.numberOfLoops=0
                replacement.volume=masterMusicVolume
                replacement.prepareToPlay()
                intro43Player=replacement
                _=replacement.play()
            }
            return
        }
        // Resume music first. Starting the 44.1 kHz engine allocates and
        // primes DSP buffers; defer this until the source song is started
        // to minimise the brief silence after unlocking the iPad.
        defer {
            if case .mission = context, missionPhase == .playing &&
                !missionUserPaused && introMissionSector568 == nil {
                enginePlayback52.setPower(engineLevel52,
                    effectsVolume:Float(settings.effectsPercent)/100)
                enginePlayback52.start()
            }
        }
        // Never undo MusicLibrary STOP or a user-selected 0% volume.
        guard settings.musicPercent>0 else {return}
        if let current=music,let index=activeMusicIndex {
            if rebuildPlayer,let file=urls[index] {
                // Give the paused original player an immediate chance to
                // sound after AVAudioSession activation, BEFORE reopening
                // the same WAV. This overlaps decoder preparation with
                // existing audio, reducing the audible unlock gap. Still
                // replace it: iOS may report isPlaying=true while silent.
                _=current.play()
                do {
                    let replacement=try AVAudioPlayer(contentsOf:file)
                    replacement.numberOfLoops = -1
                    replacement.currentTime=max(0,current.currentTime)
                    replacement.volume=masterMusicVolume
                    replacement.prepareToPlay()
                    if replacement.play() {
                        current.stop()
                        music=replacement
                        prewarmedMusic[index]=replacement
                        return
                    }
                } catch {
                    sourceStatus="IOS AUDIO / WAV \(index): \(error.localizedDescription)"
                }
            }
            if current.isPlaying {return}
            if current.play() {return} // continue at the old PCM position
            // The AVAudioPlayer may have been invalidated by suspension.
            // Reopen the SAME already-synthesized original WAV at its
            // previous offset; no new synthesizer work or substitute track.
            let offset=current.currentTime
            current.stop()
            music=nil
            activeMusicIndex=nil
            prewarmedMusic.removeValue(forKey:index)
            playTrack(index,resumeAt:offset)
        } else {
            switch context {
            case .menu:
                if !previewStopped {
                    playTrack(previewActive ? (pendingPreviewIndex ?? lastPreviewIndex) : 0)
                }
            case .mission(let sector):
                playTrack(missionPhase == .playing ?
                    OriginalAudioCatalog568.missionTrack(sector) : 0)
            case .diagnostic: break
            }
        }
    }
    /// Source Windows/src/BossTunnelGame.cs: Game.Pause/Resume.
    /// Windows/src/MusicAudio.cs:79: music duck .55, engineLevel=0,
    /// unchanged underlying mission track (PausedFrom=Mode.Playing).
    func missionUserPause568(_ paused:Bool) {
        guard case .mission = context, introMissionSector568 == nil,
              missionPhase == .playing else {return}
        missionUserPaused=paused
        // Original MusicBank.AllowPreparation becomes true in Mode.Paused.
        musicGate.setAllowed(paused && !suspended)
        musicDuck=paused ? 0.55 : 1
        if fadeTimer != nil {updateMusicFade()}
        else {music?.volume=masterMusicVolume}
        if paused {
            engineLevel52=0
            enginePlayback52.stop()
        } else {
            engineLevel52=0.16
            // After a normal manual PAUZA, the active song never stopped:
            // do NOT reopen a long PCM WAV on every KONTYNUUJ (gap).
            // Real iOS screen suspension already triggers rebuildPlayer:true
            // in sceneIsActive and in the interruption recovery path.
            restoreAudioAfterActivation568(rebuildPlayer:false)
        }
    }
    func sceneIsActive(_ active: Bool) {
        let wasSuspended=suspended
        suspended = !active
        switch context {
        case .mission:
            musicGate.setAllowed(active && missionPhase != .playing)
        case .menu,.diagnostic:
            musicGate.setAllowed(active)
        }
        if !active {
            enginePlayback52.stop()
            intro43Player?.pause()
            // iOS backgrounding must not leave an outgoing track playing.
            finishMusicFade()
            music?.pause()
            invalidateSuspendedEffects568()
        } else {
            // Lock -> unlock: the app is foreground again, but AVAudioSession
            // may still be deactivated. Restore it BEFORE any player/engine.
            restoreAudioAfterActivation568(rebuildPlayer:wasSuspended)
        }
    }
    func sourceEnginePower(_ raw:Float) {
        engineLevel52=missionUserPaused ? 0 : max(0,min(1,raw))
        if case .mission = context, !suspended {
            enginePlayback52.setPower(engineLevel52,
                effectsVolume:Float(settings.effectsPercent)/100)
        }
    }
    func sourceEffect(_ code: Int) {
        guard !suspended, !audioInterrupted, !missionUserPaused,
              settings.effectsPercent>0 else { return }
        // MusicMix.AddEffect uses one voice event per volley and 16 slots.
        let variation = variant
        variant += 1
        let stem: String
        if (50...57).contains(code) { stem = "Voice\(code-50)" }
        else { stem = "SFX\(code)_\((10...30).contains(code) ? variation % 3 : 0)" }
        guard let file = sounds[stem] else { return }
        if (50...57).contains(code) {
            // Source MusicMix.AddEffect: stop previous Polish announcement
            // without silencing any playing gun or explosion.
            spokenVoices.forEach {$0.stop()}
            spokenVoices.removeAll()
        }
        do {
            // First two players for every exact source sample were
            // prepared at application startup; allocate only when the
            // same effect exceeds its two-voice source budget.
            let pool = prewarmedEffects[stem] ?? []
            let player:AVAudioPlayer
            if let available=pool.first(where:{!$0.isPlaying}) {
                player=available
            } else if pool.count<4 {
                let new=try AVAudioPlayer(contentsOf:file)
                new.prepareToPlay()
                prewarmedEffects[stem,default:[]].append(new)
                player=new
            } else {
                player=pool[0]
                player.stop()
            }
            player.currentTime=0
            let gain:Float = (50...57).contains(code) ? 0.84 :
                             code==60 ? 0.38 : (40...45).contains(code) ? 0.32 : 0.55
            player.volume = Float(settings.effectsPercent)/100 * gain
            player.prepareToPlay()
            // Never ignore a failed .play(). A cached SFX queue may have
            // gone stale after a real iOS interruption even when its
            // isPlaying flag looked usable. Reopen the SAME bundled sample.
            var audiblePlayer=player
            if !player.play() {
                let fresh=try AVAudioPlayer(contentsOf:file)
                fresh.currentTime=0
                fresh.volume=player.volume
                fresh.prepareToPlay()
                guard fresh.play() else {
                    prewarmedEffects[stem]?.removeAll { $0 === player }
                    sourceStatus="IOS SFX \(code) — NIE MOŻNA ODTWORZYĆ"
                    return
                }
                prewarmedEffects[stem]?.removeAll { $0 === player }
                prewarmedEffects[stem,default:[]].append(fresh)
                audiblePlayer=fresh
            }
            effects.removeAll { !$0.isPlaying }
            if effects.count>=16 { effects.removeFirst().stop() }
            effects.append(audiblePlayer)
            if (50...57).contains(code) {spokenVoices.append(audiblePlayer)}
        } catch {
            sourceStatus = "SFX \(code) — BŁĄD ORYGINALNEGO PLIKU"
        }
    }
    func preview(_ index:Int) {
        guard OriginalAudioCatalog568.names.indices.contains(index),
              case .menu = context else { return }
        // Source MusicLibrary.PlaySelectedMusic selects a particular
        // original track. STOP / REPLAY operate on this selection only.
        lastPreviewIndex=index
        previewActive=true
        previewStopped=false
        if urls[index] == nil {
            // Original MusicBank.Request(track): keep selection pending,
            // start playback only when original background track is ready.
            pendingPreviewIndex=index
            finishMusicFade()
            music?.stop()
            music=nil
            activeMusicIndex=nil
            sourceStatus="PRZYGOTOWYWANIE: \(OriginalAudioCatalog568.names[index])"
        } else {
            pendingPreviewIndex=nil
            playTrack(index)
        }
    }
    func stopMusicPreview() {
        guard case .menu = context else {return}
        // Original MusicLibrary.MusicPreview=-2: STOP mutes the preview.
        previewStopped=true
        pendingPreviewIndex=nil
        finishMusicFade()
        music?.stop()
        music=nil
        activeMusicIndex=nil
    }
    func replayMusicPreview() {
        guard case .menu = context else {return}
        // MusicLibrary.W3SelectMusic355(16): restart selected song at 0.
        previewStopped=false
        finishMusicFade()
        music?.stop()
        music=nil
        activeMusicIndex=nil
        preview(lastPreviewIndex)
    }
    func restoreMenuMusic() {
        guard case .menu = context else {return}
        // MusicLibrary.CloseMusic returns to Game.Mode.Menu track 0.
        previewStopped=false
        previewActive=false
        pendingPreviewIndex=nil
        if !suspended {playTrack(0)}
    }
}
