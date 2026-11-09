import Foundation

/// Windows PC v580 GpuHub90.cs:110-112,220-225 and Hub90.StepHub90.
/// Presentation-only coordinates: H05 spawn and H06 physics unchanged.
enum H55DockingPresentation580 {
    static let duration:Float=H55Entry580.arrivalSeconds
    static let delay:Float=0.62
    static let shipArrival:Float=2.63
    static let spinDegreesPerSecond:Float=20 // HangarShipSpin551.DefaultSpeed

    private static func smooth(_ t:Float)->Float {
        let x=max(0,min(1,t))
        return x*x*(3-2*x)
    }
    static func camera(time:Float)->(x:Float,y:Float,z:Float) {
        let t=time.isFinite ? max(0,time) : 0
        let d=smooth(t/duration)
        return (0,6.8+(1-d),31+9*(1-d))
    }
    static func ship(time:Float)->(x:Float,y:Float,z:Float,yaw:Float) {
        let t=time.isFinite ? max(0,time) : 0
        let a=smooth((t-delay)/shipArrival)
        let spin=(t*spinDegreesPerSecond).truncatingRemainder(dividingBy:360)
        return (0,1.05+a,-11.5*(1-a),((1-a)*23+spin)*Float.pi/180)
    }
}
