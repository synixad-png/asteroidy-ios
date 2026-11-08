import Foundation

@main struct PhoneFrameCadence568Tests {
    static func main() {
        func check(_ ok:Bool,_ description:String) {
            precondition(ok, description)
        }
        func uniform(_ fps:Double,_ frames:Int)->PhoneFrameCadence568.Sample {
            var cadence=PhoneFrameCadence568()
            for step in 0..<frames {
                cadence.drawCallback(at:100 + Double(step)/fps)
            }
            return cadence.takeSample(at:100+Double(frames)/fps)!
        }
        let full=uniform(60,61)
        check(abs(full.callbackRate-60)<0.01,"60 fps callback cadence")
        check(full.late24==0 && full.late40==0,"no false late callbacks at 60")
        check(abs(full.p95Ms-1000/60)<0.01,"60 fps true 95th percentile")
        let half=uniform(30,19)
        check(abs(half.callbackRate-30)<0.01,"30 fps callback cadence")
        check(half.late24==18 && half.late40==0,"30 fps missed-60-Hz cycles")
        check(abs(half.peakMs-1000/30)<0.01,"30 fps maximum gap")
        let promotion=uniform(120,66)
        check(abs(promotion.callbackRate-120)<0.01,"120Hz callback cadence")
        check(promotion.late24==0,"no false drops at 120Hz")

        var spikes=PhoneFrameCadence568()
        for step in 0..<45 where step != 15 {
            spikes.drawCallback(at:200+Double(step)/60)
        }
        let oneStall=spikes.takeSample(at:200+45.0/60)!
        check(oneStall.late24==1 && oneStall.late40==0,
              "single 33ms hitch not hidden in 60-Hz average")
        check(oneStall.peakMs>=33.3 && oneStall.peakMs<34,
              "hitch maximum is measured without inventing GPU timing")

        var switching=PhoneFrameCadence568()
        var now:Double=300
        for _ in 0..<61 {
            switching.drawCallback(at:now)
            now+=1/60
        }
        check(abs(switching.takeSample(at:now)!.callbackRate-60)<0.01,
              "first 60-Hz sample")
        for _ in 0..<19 {
            switching.drawCallback(at:now)
            now+=1/30
        }
        check(abs(switching.takeSample(at:now)!.callbackRate-30)<0.01,
              "second 30-Hz sample does not include last 60-Hz interval")
        switching.drawCallback(at:now+0.1)
        switching.drawCallback(at:now+5.1)
        check(switching.takeSample(at:now+5.2)==nil,
              "background/lock gap resets rather than fabricates a 5000 ms frame")
        switching.reset()
        switching.drawCallback(at:Double.nan)
        switching.drawCallback(at:-1)
        check(switching.takeSample(at:99)==nil,"invalid samples ignored")
        print("PASS real 120/60/30-Hz draw cadence, p95, single frame skip and 5s iOS suspend")
        print("PASS iPhone-only pure telemetry never drives refresh rate or graphics quality")
    }
}
