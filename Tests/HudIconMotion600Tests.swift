import Foundation

@main enum HudIconMotion600Tests {
    static func check(_ yes:@autoclosure ()->Bool,_ reason:String) {
        precondition(yes(),"HudIconMotion PC parity: "+reason)
    }
    static func close(_ a:Float,_ b:Float,_ message:String) {
        check(abs(a-b)<0.0002,message)
    }
    static func main() {
        var model=HudIconMotion600()
        var pose=HudMotion600.Pose(iconStrength:1,parallax:true)
        let still=model.evaluate(index:0,seconds:0,motion:.init())!
        check(still.yaw==0 && still.pitch==0 && still.roll==0,
              "static HUD disables visual item animation")
        let t=10.0
        let initial=model.evaluate(index:0,seconds:t,motion:pose)!
        // Windows HudIconMotion: energy style Speed1.6 Phase0.3.
        close(initial.yaw,4.2*Float(sin(t*1.6+0.3)),
              "energy first frame uses source yaw, not invented spin")
        close(initial.pitch,2.4*Float(cos((t*1.6+0.3)*0.83+0.3*0.35)),
              "energy first frame uses source pitch")
        close(initial.roll,1.3*Float(sin((t*1.6+0.3)*0.71+0.3)),
              "energy first frame uses source roll")
        close(initial.floatY,Float(sin((t*1.6+0.3)*0.66+0.3*0.5)),
              "energy first frame uses source float lift")
        let following=model.evaluate(index:0,seconds:t+0.01,motion:pose)!
        var freshModel=HudIconMotion600()
        let fresh=freshModel.evaluate(index:0,seconds:t+0.01,motion:pose)!
        check(abs(following.yaw-initial.yaw) <= abs(fresh.yaw-initial.yaw)+0.0001,
              "per-icon spring lags target rather than snapping")
        let bomb=model.evaluate(index:1,seconds:t,motion:pose)!
        check(abs(bomb.yaw-initial.yaw)>0.1,
              "heavy bomb uses a different independent motion style")
        let shield=model.evaluate(index:2,seconds:t,motion:pose)!
        let boost=model.evaluate(index:3,seconds:t,motion:pose)!
        check(shield.pitch != boost.pitch,"shield/boost styles independent")
        for i in 1...240 {
            pose.x=Float(sin(Double(i)*0.2))*48
            pose.y=Float(cos(Double(i)*0.12))*8
            pose.roll=Float(sin(Double(i)*0.17))*7
            let seconds=t+Double(i)/60
            for j in 0..<4 {
                let p=model.evaluate(index:j,seconds:seconds,motion:pose)!
                check(abs(p.yaw)<=9 && abs(p.pitch)<=7 && abs(p.roll)<=5 &&
                      abs(p.floatY)<=2,"original clamp on all four components")
            }
        }
        check(model.evaluate(index:4,seconds:1,motion:pose)==nil,
              "no fifth fictitious model")
        let afterGap=model.evaluate(index:0,seconds:50,motion:pose)!
        var clean=HudIconMotion600()
        let same=clean.evaluate(index:0,seconds:50,motion:pose)!
        close(afterGap.yaw,same.yaw,"time gap resets original damped state")
        check(model.evaluate(index:0,seconds:51,motion:.init())!.yaw==0,
              "disabled setting resets the spring")
        print("PASS PC HUD v600: 4 source icon styles, inertia, source angles/lift, bounds, reset and no fake models")
    }
}
