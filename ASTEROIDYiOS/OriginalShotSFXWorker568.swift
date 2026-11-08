import Foundation
import AVFoundation

/// Source MusicMix.AddEffect: play original v568 audio files on a dedicated
/// serial queue. The MetalKit/SwiftUI main thread now only enqueues a short
/// event; AVAudioPlayer.isPlaying/prepareToPlay/play/stop and pool cleanup
/// must never block MTKView's 60-Hz callback or the touch/UI event loop.
///
/// All AVAudioPlayer objects in this pool are exclusively accessed on
/// audioQueue after the startup background worker hands over its warm bank.
/// Music, Intro43, engine DSP and AVAudioSession remain managed by their
/// original main-thread lifecycle, preserving the #141 lock/unlock repair.
final class OriginalShotSFXWorker568 {
    private let audioQueue=DispatchQueue(
        label:"synixad.asteroidy.audio568.combat-sfx",
        qos:.userInitiated)
    private var prewarmedEffects:[String:[AVAudioPlayer]]=[:]
    private var effects:[AVAudioPlayer]=[]
    private var spokenVoices:[AVAudioPlayer]=[]

    /// Startup already prewarms two instances of each original sample on a
    /// background worker. Transfer ownership to this exclusive SFX queue.
    /// Do not rebuild banks during a shot or on the SwiftUI thread.
    func install(_ prepared:[String:[AVAudioPlayer]]) {
        audioQueue.async { [self] in
            prewarmedEffects=prepared
        }
    }

    /// Called from the existing main-thread interruption/background/return
    /// handlers. FIFO queue order ensures pending shot events cannot play
    /// after they have been invalidated by a subsequent suspension.
    func stopAll(invalidate:Bool) {
        audioQueue.async { [self] in
            effects.forEach {$0.stop()}
            effects.removeAll(keepingCapacity:true)
            spokenVoices.forEach {$0.stop()}
            spokenVoices.removeAll(keepingCapacity:true)
            if invalidate {
                // A pre-suspension AVAudioPlayer can hold a stale decoder.
                // Force next shot to open the SAME source file on this
                // worker, never substitute a new tone or change gain.
                prewarmedEffects.removeAll(keepingCapacity:true)
            }
        }
    }

    /// Original variation and gain are selected by OriginalAudioAV568 on
    /// the main thread. Only potentially blocking audio calls occur here.
    func play(stem:String,file:URL,code:Int,volume:Float,
              onError:@escaping (String)->Void) {
        audioQueue.async { [self] in
            if (50...57).contains(code) {
                // Only the previous Polish announcer is interrupted.
                // Original weapon/explosion voices remain audible.
                spokenVoices.forEach {$0.stop()}
                spokenVoices.removeAll(keepingCapacity:true)
            }
            do {
                // Preserve original per-stem four-voice cap, including
                // the two voices prepared at app startup.
                let pool=prewarmedEffects[stem] ?? []
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
                player.volume=volume
                // IMPORTANT: do not call prepareToPlay() every shot.
                // The selected pool voice is already prepared, and that
                // call could stall MetalKit's main-thread callback.
                var audiblePlayer=player
                if !player.play() {
                    // iOS audio interruptions can invalidate decoder
                    // queues. Reopen only this exact bundled original M4A,
                    // off the main thread, then retry once.
                    let fresh=try AVAudioPlayer(contentsOf:file)
                    fresh.currentTime=0
                    fresh.volume=volume
                    fresh.prepareToPlay()
                    guard fresh.play() else {
                        prewarmedEffects[stem]?.removeAll {$0 === player}
                        DispatchQueue.main.async {
                            onError("IOS SFX \(code) — NIE MOŻNA ODTWORZYĆ")
                        }
                        return
                    }
                    prewarmedEffects[stem]?.removeAll {$0 === player}
                    prewarmedEffects[stem,default:[]].append(fresh)
                    audiblePlayer=fresh
                }
                effects.removeAll {!$0.isPlaying}
                if effects.count>=16 {effects.removeFirst().stop()}
                effects.append(audiblePlayer)
                if (50...57).contains(code) {spokenVoices.append(audiblePlayer)}
            } catch {
                DispatchQueue.main.async {
                    onError("SFX \(code) — BŁĄD ORYGINALNEGO PLIKU")
                }
            }
        }
    }
}
