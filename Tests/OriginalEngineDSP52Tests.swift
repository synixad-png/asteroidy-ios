import Foundation
@main struct OriginalEngineDSP52Tests {
    static func main() {
        var a=OriginalEngineDSP52(), b=OriginalEngineDSP52()
        var energy:Double=0,stereo:Double=0
        for i in 0..<44100 {
            let power:Float = i<22050 ? 0.16:1.0
            let (l,r)=a.render(engine:power,flame:0,effectsVolume:1)
            let (l2,r2)=b.render(engine:power,flame:0,effectsVolume:1)
            precondition(l.isFinite && r.isFinite && abs(l)<=0.99 && abs(r)<=0.99)
            precondition(l==l2 && r==r2,"source seed must stay deterministic")
            energy+=Double(l*l+r*r)
            stereo+=Double(abs(l-r))
        }
        precondition(energy>0.01 && stereo>0.001)
        var muted=OriginalEngineDSP52()
        for _ in 0..<44100 {
            let (l,r)=muted.render(engine:0,flame:0,effectsVolume:0)
            precondition(l==0 && r==0)
        }
        var flame=OriginalEngineDSP52()
        var torchEnergy:Double=0
        for _ in 0..<44100 {
            let (l,r)=flame.render(engine:0,flame:1,effectsVolume:1)
            torchEnergy+=Double(l*l+r*r)
        }
        precondition(torchEnergy>0.001)
        print("PASS original engine52 deterministic dual-channel noise, spool and flame DSP")
    }
}
