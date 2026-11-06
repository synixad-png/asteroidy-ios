import Foundation

@main struct OriginalMusicTransition568Tests {
    static func main() {
        precondition(OriginalMusicTransition568.fadeFrames==88200)
        precondition(OriginalMusicTransition568.duration==2)
        let atStart=OriginalMusicTransition568.gains(seconds:0)
        precondition(abs(atStart.incoming)<0.000001)
        precondition(abs(atStart.outgoing-1)<0.000001)
        let half=OriginalMusicTransition568.gains(seconds:1)
        precondition(abs(half.incoming-0.70710678)<0.00001)
        precondition(abs(half.outgoing-0.70710678)<0.00001)
        let finish=OriginalMusicTransition568.gains(seconds:2)
        precondition(abs(finish.incoming-1)<0.000001)
        precondition(abs(finish.outgoing)<0.000001)
        for i in 0...200 {
            let g=OriginalMusicTransition568.gains(seconds:Double(i)/100)
            let power=g.incoming*g.incoming+g.outgoing*g.outgoing
            precondition(abs(power-1)<0.000001)
        }
        print("PASS source Windows MusicMix 88200f / 44.1kHz equal-power fade")
    }
}
