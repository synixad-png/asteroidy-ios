import Foundation
import AVFoundation

/// Real-time native playback of the original Windows MusicMix engine DSP.
/// Four 2048-frame buffers (44.1 kHz) are queued on a serial worker;
/// no allocations, source synthesis or file I/O on the game-render thread.
final class OriginalEnginePlayback52 {
    private let queue=DispatchQueue(label:"synixad.asteroidy.sourceEngine52",qos:.userInitiated)
    private let audio=AVAudioEngine()
    private let player=AVAudioPlayerNode()
    private let format=AVAudioFormat(standardFormatWithSampleRate:44100,channels:2)!
    private var dsp=OriginalEngineDSP52()
    private var target:Float=0
    private var flame:Float=0
    private var volume:Float=1
    private var running=false

    init() {
        audio.attach(player)
        audio.connect(player,to:audio.mainMixerNode,format:format)
    }
    func setPower(_ engine:Float,flame:Float=0,effectsVolume:Float) {
        queue.async { [weak self] in
            self?.target=max(0,min(1,engine))
            self?.flame=max(0,min(1,flame))
            self?.volume=max(0,min(1,effectsVolume))
        }
    }
    func start() {
        queue.async { [weak self] in
            guard let self, !self.running else{return}
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient,mode:.default)
                try AVAudioSession.sharedInstance().setActive(true)
                try self.audio.start()
                self.running=true
                for _ in 0..<4 {self.schedule()}
                self.player.play()
            } catch {
                self.running=false
            }
        }
    }
    func stop() {
        queue.async { [weak self] in
            guard let self else{return}
            self.running=false
            self.player.stop()
            self.audio.stop()
        }
    }
    private func schedule() {
        guard running,let buffer=AVAudioPCMBuffer(pcmFormat:format,frameCapacity:2048),
              let channels=buffer.floatChannelData else{return}
        buffer.frameLength=2048
        for i in 0..<Int(buffer.frameLength) {
            let (l,r)=dsp.render(engine:target,flame:flame,effectsVolume:volume)
            channels[0][i]=l
            channels[1][i]=r
        }
        player.scheduleBuffer(buffer,completionCallbackType:.dataConsumed) {
            [weak self] _ in
            self?.queue.async { [weak self] in self?.schedule() }
        }
    }
}
