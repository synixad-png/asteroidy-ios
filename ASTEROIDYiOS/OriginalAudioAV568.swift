import Foundation
import AVFoundation
import SwiftUI

/// Playback of source PCM only. Never creates stand-in notes or sound clips.
private final class OriginalAudioPCMOutput568 {
    private let engine=AVAudioEngine()
    private let musicNode=AVAudioPlayerNode()
    private var effectNodes:[String:AVAudioPlayerNode]=[:]
    private var effects:[String:OriginalPCM568]=[:]

    init() {engine.attach(musicNode)}
    private func makePCM(_ clip:OriginalPCM568) throws -> AVAudioPCMBuffer {
        guard clip.isValid,
              let format=AVAudioFormat(commonFormat:.pcmFormatFloat32,
                  sampleRate:clip.sampleRate,
                  channels:AVAudioChannelCount(clip.channels),
                  interleaved:false),
              clip.interleavedFloat32.count/clip.channels <= Int(UInt32.max)
        else {throw OriginalAudioSourceError568.invalidOriginalAudio(clip.sourceId)}
        let frames=clip.interleavedFloat32.count/clip.channels
        guard let buffer=AVAudioPCMBuffer(pcmFormat:format,
                  frameCapacity:AVAudioFrameCount(frames)),
              let channelData=buffer.floatChannelData
        else {throw OriginalAudioSourceError568.invalidOriginalAudio(clip.sourceId)}
        buffer.frameLength=AVAudioFrameCount(frames)
        for frame in 0..<frames {
            for channel in 0..<clip.channels {
                channelData[channel][frame]=clip.interleavedFloat32[
                    frame*clip.channels+channel]
            }
        }
        return buffer
    }
    private func ensureSession() throws {
        try AVAudioSession.sharedInstance().setCategory(.ambient,mode:.default)
        try AVAudioSession.sharedInstance().setActive(true)
    }
    func playMusic(_ clip:OriginalPCM568) throws {
        let buffer=try makePCM(clip)
        musicNode.stop()
        if engine.isRunning {engine.stop()}
        engine.connect(musicNode,to:engine.mainMixerNode,format:buffer.format)
        try ensureSession()
        try engine.start()
        musicNode.scheduleBuffer(buffer,at:nil,
            options:clip.loops ? [.loops] : [],completionHandler:nil)
        musicNode.play()
    }
    func enterMission(_ bank:OriginalMissionAudio568) throws {
        effects=bank.effectsBySourceId
        if let music=bank.music {try playMusic(music)}
        else {musicNode.stop()}
    }
    /// Exact original source event IDs only, once the generator is ported.
    func playEffect(_ exactSourceId:String) throws {
        guard let clip=effects[exactSourceId] else {return}
        let buffer=try makePCM(clip)
        let node:AVAudioPlayerNode
        if let existing=effectNodes[exactSourceId] {
            node=existing;node.stop()
        } else {
            node=AVAudioPlayerNode()
            effectNodes[exactSourceId]=node
            engine.attach(node)
        }
        engine.connect(node,to:engine.mainMixerNode,format:buffer.format)
        try ensureSession()
        if !engine.isRunning {try engine.start()}
        node.scheduleBuffer(buffer,at:nil,options:[],completionHandler:nil)
        node.play()
    }
    func stop() {
        musicNode.stop()
        for node in effectNodes.values {node.stop()}
    }
}

/// Connected to GameView at launch and CARBONIS mission entry. The current
/// GitHub source archive lacks the ORIGINAL Windows audio generator and
/// intro43.pcm.gz, so NO substitute soundtrack is played.
final class OriginalAudioAV568:ObservableObject {
    @Published private(set) var sourceStatus="ORYGINALNE AUDIO: SPRAWDZANIE ŹRÓDEŁ"
    private let output=OriginalAudioPCMOutput568()
    private let lifecycle=OriginalAudioLifecycle568()
    private var currentSector:Int?
    private var suspended=false
    private var inDiagnostic=false

    init() {
        lifecycle.onEvent={ [weak self] event in
            guard let self, !self.suspended else {return}
            switch event {
            case .menuReady(let clip):
                do {
                    try self.output.playMusic(clip)
                    self.sourceStatus="MUZYKA MENU v568: GOTOWA"
                } catch {
                    self.sourceStatus="BŁĄD ORYGINALNEGO AUDIO: \(error)"
                }
            case .missionReady(_,let bank):
                do {
                    try self.output.enterMission(bank)
                    self.sourceStatus="AUDIO MISJI v568: GOTOWE"
                } catch {
                    self.sourceStatus="BŁĄD ORYGINALNEGO AUDIO: \(error)"
                }
            case .unavailable(let reason):
                self.output.stop()
                self.sourceStatus="AUDIO v568 NIEDOSTĘPNE: \(reason)"
            }
        }
    }
    func prepareMenuAtStartup() {
        inDiagnostic=false
        currentSector=nil
        suspended=false
        lifecycle.prepareAtStartup()
    }
    func returnToMenu() {
        inDiagnostic=false
        currentSector=nil
        output.stop()
        if !suspended {lifecycle.openMenu()}
    }
    func enterMission(_ sector:Int) {
        inDiagnostic=false
        currentSector=sector
        output.stop()
        if !suspended {lifecycle.openMission(sector:sector)}
    }
    func stopForDiagnostic() {
        inDiagnostic=true
        currentSector=nil
        output.stop()
    }
    func sceneIsActive(_ active:Bool) {
        suspended = !active
        if !active || inDiagnostic {output.stop()}
        else if let currentSector {lifecycle.openMission(sector:currentSector)}
        else {lifecycle.openMenu()}
    }
    func sourceEffect(_ exactSourceId:String) {
        guard !suspended else {return}
        try? output.playEffect(exactSourceId)
    }
}
