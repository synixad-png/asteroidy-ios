import Foundation

/// Windows/src/MusicAudio.cs MusicMix.Render:
/// fadeLength=88200 PCM frames, rate=44100, equal-power sin/cos.
enum OriginalMusicTransition568 {
    static let sampleRate:Double=44100
    static let fadeFrames:Int=88200
    static let duration:TimeInterval=Double(fadeFrames)/sampleRate
    static func gains(seconds elapsed:TimeInterval)->(incoming:Float,outgoing:Float) {
        let progress=max(0,min(1,elapsed/duration))
        return (Float(sin(progress*Double.pi/2)),
                Float(cos(progress*Double.pi/2)))
    }
}
