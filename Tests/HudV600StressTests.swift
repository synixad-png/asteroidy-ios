import Foundation

/// CPU-only source stress test. Does not claim Metal GPU throughput or
/// on-device FPS. Exercises live mission HUD math and all 46 edit hitboxes.
@main enum HudV600StressTests {
    static func verify(_ value:Bool,_ why:String) {
        precondition(value,why)
    }
    static func main() {
        let approved=HudLayout600.defaults()
        verify(approved.isValid,"approved PC layout validates")
        var motion=HudMotion600()
        var sample=HudMotion600.Sample()
        sample.hull=60
        sample.armor=25
        sample.shield=100
        var lastPose=HudMotion600.Pose()
        var checkedVertices=0
        let started=ProcessInfo.processInfo.systemUptime
        for frame in 0..<18_000 {
            let clock=Double(frame)/120
            let phase=Float(frame)*0.014
            sample.turnRate=2.2*sin(phase)
            sample.speed=180+90*sin(phase*0.2)
            sample.bank=25*sin(phase*0.9)
            sample.pitch=14*cos(phase*0.7)
            sample.boost=frame%257<13 ? 1:0
            if frame%16==0 {sample.shots+=1}
            if frame%71==0 {sample.hits+=1}
            if frame%117==0 {sample.pickups+=1}
            if frame%41==0 {
                sample.shield=max(0,sample.shield-0.5)
            }
            let pose=motion.update(sample,at:clock,active:true)
            for value in [pose.x,pose.y,pose.roll,pose.shotPulse,
                          pose.hitPulse,pose.pickupPulse,pose.damagePulse] {
                verify(value.isFinite,"no unbounded HUD impulse or NaN")
            }
            verify(abs(pose.x)<=48 && abs(pose.y)<=8 && abs(pose.roll)<=7,
                   "source movement bounds retained")
            lastPose=pose
            if frame%12==0 {
                let time=Double(frame)/120
                for style in 0..<3 {
                    let fraction=HudEnergy600.fraction(
                        100-frame%101,maximum:100)
                    for layer in 0..<5 {
                        let points=HudEnergy600.ribbon(
                            x:201,y:580,width:146,length:146*fraction,
                            time:time,style:style,layer:layer)
                        verify(points.count<=70,
                               "plasma mesh has source vertex cap")
                        verify(points.allSatisfy{$0.x.isFinite && $0.y.isFinite},
                               "no NaNs in plasma geometry")
                        checkedVertices += points.count
                    }
                }
            }
        }
        verify(lastPose.x.isFinite && checkedVertices>50_000,
               "stress processed all real plasma bands")
        for widget in approved.widgets {
            guard let dims=HudWidgetGeometry600.size(widget.id),
                  let x=HudWidgetGeometry600.xRange(for:widget),
                  let y=HudWidgetGeometry600.yRange(for:widget) else {
                preconditionFailure("missing widget geometry "+widget.id)
            }
            verify(dims.width>0 && dims.height>0,"invalid native hitbox")
            verify(x.contains(widget.x) && y.contains(widget.y),
                   "approved PC F6 coordinate out of bounds")
        }
        let elapsed=ProcessInfo.processInfo.systemUptime-started
        print("PASS HUD v600 CPU stress: 18000 updates, \(checkedVertices) plasma points, 46 layout widgets; macOS CPU \(String(format:"%.3f",elapsed)) seconds (NOT device GPU FPS)")
    }
}
