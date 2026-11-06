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
/// The deterministic C# generates PCM at build time. The iOS runtime loads
/// AAC transcodes in the same 2-phase order and does not invent any audio.
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

/// Audible implementation backed by ACTUAL original v568 C# output.
/// No substitute melodies, no file generation on render/audio thread.
/// Original SFX variations use MusicMix.variation++ modulo 3.
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
    private var fadeTimer:Timer?
    private var fadeStart:TimeInterval=0
    private var effects: [AVAudioPlayer] = []
    // Original MusicAudio.cs: voice announcements interrupt one another.
    private var spokenVoices:[AVAudioPlayer]=[]
    private var musicDuck:Float=1
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
    private var activeMusicIndex: Int?
    private var urls: [Int:URL] = [:]
    private var sounds: [String:URL] = [:]
    private let worker = DispatchQueue(label: "synixad.asteroidy.audio568.source-pack",
                                       qos: .userInitiated)
    private var settingsObserver: NSObjectProtocol?
    private var previewObserver: NSObjectProtocol?
    private var stopObserver: NSObjectProtocol?
    private var replayObserver: NSObjectProtocol?
    private var restoreObserver: NSObjectProtocol?
    private var lastPreviewIndex=1
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
    }
    deinit {
        for observer in [settingsObserver,previewObserver,stopObserver,
                         replayObserver,restoreObserver] {
            if let observer {NotificationCenter.default.removeObserver(observer)}
        }
    }
    private func reloadSettings() {
        settings = OriginalAudioSettings568.load()
        if fadeTimer != nil {updateMusicFade()}
        else {music?.volume=masterMusicVolume}
        enginePlayback52.setPower(engineLevel52,
            effectsVolume:Float(settings.effectsPercent)/100)
        // Original MusicMix uses a live value, not a one-time volume at start.
        // Restoring volume from zero must start the selected source track,
        // unless the real MusicLibrary STOP action is active.
        if settings.musicPercent>0 && music == nil && startupComplete && !suspended {
            switch context {
            case .menu:
                if !previewStopped {playTrack(0)}
            case .mission(let sector):playTrack(OriginalAudioCatalog568.missionTrack(sector))
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
            var menu: [Int:URL] = [:]
            for index in 0...1 {
                if let file = OriginalAudioCatalog568.resource("Music\(index)") {
                    menu[index] = file
                } else { missing.append("Music\(index)") }
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
            // Original background phase: remaining tracks 2...14 are
            // prepared only after menu startup, never block menu/gameplay.
            for index in 2..<OriginalAudioCatalog568.names.count {
                guard let file = OriginalAudioCatalog568.resource("Music\(index)")
                else { continue }
                // This work runs on the background audio queue after W3
                // has opened: prebuffer track, not just save its URL.
                let preparedTrack=try? AVAudioPlayer(contentsOf:file)
                preparedTrack?.numberOfLoops = -1
                preparedTrack?.prepareToPlay()
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.urls[index] = file
                    if let preparedTrack { self.prewarmedMusic[index]=preparedTrack }
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
    private func playTrack(_ index: Int) {
        guard startupComplete, !suspended, settings.musicPercent>0,
              let url = urls[index] else { return }
        if activeMusicIndex==index, music?.isPlaying==true { return }
        finishMusicFade()
        let outgoing = music?.isPlaying==true ? music : nil
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient,mode:.default)
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try prewarmedMusic[index] ?? AVAudioPlayer(contentsOf:url)
            player.currentTime=0
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
    func returnToMenu() {
        previewStopped=false
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
        previewStopped=false
        pendingPreviewIndex=nil
        musicDuck=1
        context = .mission(sector)
        // MusicAudio.cs:79 idle power .16, full thrust 1.0, no audio
        // generation in the Metal render loop.
        engineLevel52=0.16
        if !suspended {
            enginePlayback52.setPower(engineLevel52,
                effectsVolume:Float(settings.effectsPercent)/100)
            enginePlayback52.start()
            playTrack(OriginalAudioCatalog568.missionTrack(sector))
        }
    }
    // MusicAudio.cs MusicMix.TrackFor: Victory and GameOver return
    // to song 0; GameOver attenuates music to 40%. A replay restores
    // the normal current-level track and live engine audio.
    func missionPhase568(_ phase:CarbonisCombat568.Phase) {
        guard case .mission(let sector) = context else {return}
        switch phase {
        case .playing:
            musicDuck=1
            engineLevel52=0.16
            if !suspended {
                enginePlayback52.setPower(engineLevel52,
                    effectsVolume:Float(settings.effectsPercent)/100)
                enginePlayback52.start()
                playTrack(OriginalAudioCatalog568.missionTrack(sector))
            }
        case .victory,.defeat:
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
        engineLevel52=0
        enginePlayback52.stop()
        context = .diagnostic
        musicDuck=1
        finishMusicFade()
        music?.stop(); activeMusicIndex = nil
        effects.removeAll()
    }
    func sceneIsActive(_ active: Bool) {
        suspended = !active
        if !active {
            enginePlayback52.stop()
            // iOS backgrounding must not leave an outgoing track playing.
            finishMusicFade()
            music?.pause()
            effects.forEach { $0.pause() }
        } else {
            if case .mission = context {
                enginePlayback52.setPower(engineLevel52,
                    effectsVolume:Float(settings.effectsPercent)/100)
                enginePlayback52.start()
            }
            if music != nil, activeMusicIndex != nil { music?.play() }
            else {
                switch context {
                case .menu:
                    if !previewStopped {playTrack(pendingPreviewIndex ?? 0)}
                case .mission(let sector):
                    playTrack(OriginalAudioCatalog568.missionTrack(sector))
                case .diagnostic: break
                }
            }
        }
    }
    func sourceEnginePower(_ raw:Float) {
        engineLevel52=max(0,min(1,raw))
        if case .mission = context, !suspended {
            enginePlayback52.setPower(engineLevel52,
                effectsVolume:Float(settings.effectsPercent)/100)
        }
    }
    func sourceEffect(_ code: Int) {
        guard !suspended, settings.effectsPercent>0 else { return }
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
            effects.removeAll { !$0.isPlaying }
            if effects.count>=16 { effects.removeFirst().stop() }
            effects.append(player)
            if (50...57).contains(code) {spokenVoices.append(player)}
            player.play()
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
        pendingPreviewIndex=nil
        if !suspended {playTrack(0)}
    }
}
