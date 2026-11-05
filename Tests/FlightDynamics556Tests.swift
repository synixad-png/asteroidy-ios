import Foundation
@main struct FlightTest {
    static func main() {
        let step: Float = 1/120
        var f = FlightDynamics556()
        var v = Vec2(x:0,y:0)
        let desired = Vec2(x:0,y:f.configuration.cruiseSpeed)
        let a = f.motion(velocity:&v,desired:desired,inputLength:1,dt:step)
        let expected = desired.y*(1-exp(-3*step))
        precondition(abs(v.y-expected)<0.000001,"DirectMotion298 exponential response mismatch")
        precondition(a.y>0 && f.visualPower>0)
        for _ in 1..<120 { _ = f.motion(velocity:&v,desired:desired,inputLength:1,dt:step) }
        precondition(abs(v.y-desired.y*(1-exp(-3)))<0.00003,"One-second response mismatch")
        let before = v.y
        _ = f.motion(velocity:&v,desired:.init(x:0,y:0),inputLength:0,dt:step)
        precondition(v.y<before && v.y>0,"Coasting should smoothly decay")
        f.attitude(angle:0,velocity:v,acceleration:.init(x:0,y:0),dt:step)
        let old = f.visualHeading
        f.attitude(angle:Float.pi/2,velocity:v,acceleration:.init(x:0,y:0),dt:step)
        precondition(f.visualHeading > old && f.visualHeading < Float.pi/2,"Hull should lag immediate combat aim")
        precondition(abs(f.angularVelocity)<=6.2+0.00001)
        precondition(abs(f.visualBank)<=39 && abs(f.visualPitch)<=17)
        precondition(abs(FlightDynamics556.wrapAngle(3.5)-(3.5-Float.pi*2))<0.00001)
        var g = GameCore(); let direction = g.angle
        for _ in 0..<30 { g.tick(FlightCommand(turn:1,throttle:1,fire:true),dt:step) }
        precondition(g.angle != direction && g.flight.visualInitialized)
        print("PASS: v556 FlightDynamics298 exponential rise/coast, attitude lag, bank/pitch caps, integrated update")
    }
}
