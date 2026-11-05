import Foundation

// Adaptation of ASTEROIDY v556 Windows/src/FlightDynamics298.cs.
// The v556 *response equations* and visual attitude smoothing are retained.
// Units/world topology are deliberately normalized for the iOS prototype:
// NOT equivalent to the original spherical Sphere67 flight and ScreenVector67.
struct FlightDynamics556 {
    struct Configuration {
        var control: Float = 1
        var coastMassFactor: Float = 1
        var stabilizerLevel: Float = 0
        var cruiseSpeed: Float = 0.92
        var visualTurnRate: Float = 6.2
        var visualResponse: Float = 5.8
    }
    var configuration = Configuration()
    var visualHeading: Float = 0
    var visualBank: Float = 0
    var visualPitch: Float = 0
    var visualPower: Float = 0
    var angularVelocity: Float = 0
    var visualInitialized = false

    static func wrapAngle(_ value: Float) -> Float {
        var v = value.truncatingRemainder(dividingBy: Float.pi * 2)
        if v > Float.pi { v -= Float.pi * 2 }
        if v < -Float.pi { v += Float.pi * 2 }
        return v
    }
    static func response(rate: Float, dt: Float) -> Float {
        1 - exp(-min(0.05, max(0, dt)) * rate)
    }
    // Mirrors DirectMotion298's exponential velocity response and visualPower.
    // `desired` replaces the v556 ScreenVector67(move)*limit calculation.
    mutating func motion(velocity: inout Vec2, desired: Vec2, inputLength: Float, dt: Float) -> Vec2 {
        guard dt > 0 else { return .init(x:0,y:0) }
        let length = max(0, min(1, inputLength))
        let previous = velocity
        let rate: Float = length > 0.01 ? 3 * configuration.control : 1.55 * (1 + configuration.stabilizerLevel * 0.16) * configuration.coastMassFactor
        velocity = velocity + (desired - velocity) * Self.response(rate:rate,dt:dt)
        let powerTarget: Float = length > 0.01 ? 0.48 + 0.52 * length : min(0.38, sqrt(velocity.lengthSquared)/max(0.001,configuration.cruiseSpeed) * 0.38)
        visualPower += (powerTarget - visualPower) * (1 - exp(-dt * (length > 0.01 ? 7 : 3.5)))
        return (velocity - previous) * (1/max(0.00001,dt))
    }
    // DirectAttitude298 adapted to a flat XY camera (original moves over a sphere).
    // `angle` is combat/shot heading, which must never be delayed by hull animation.
    mutating func attitude(angle: Float, velocity: Vec2, acceleration: Vec2, dt: Float) {
        guard dt > 0 else { return }
        let old = visualHeading
        if !visualInitialized { visualHeading = angle; visualInitialized = true }
        let error = Self.wrapAngle(angle-visualHeading)
        let maxRate = configuration.visualTurnRate
        let step = max(-maxRate*dt,min(maxRate*dt,error*(1-exp(-dt*configuration.visualResponse))))
        visualHeading = Self.wrapAngle(visualHeading+step)
        angularVelocity = max(-maxRate,min(maxRate,Self.wrapAngle(visualHeading-old)/dt))
        let facing = Vec2(x:-sin(visualHeading),y:cos(visualHeading))
        let right = Vec2(x:-facing.y,y:facing.x)
        let speed = max(1,configuration.cruiseSpeed)
        let lateral = (acceleration.x*right.x+acceleration.y*right.y)/speed
        let slip = (velocity.x*right.x+velocity.y*right.y)/speed
        let targetBank = max(-39,min(39,-angularVelocity*6.3-lateral*27-slip*9))
        let rollRate: Float = abs(targetBank)>abs(visualBank) ? 6.3 : 3.8
        visualBank += (targetBank-visualBank)*(1-exp(-dt*rollRate))
        let longitudinal = (acceleration.x*facing.x+acceleration.y*facing.y)/speed
        let targetPitch = max(-17,min(17,-longitudinal*32))
        visualPitch += (targetPitch-visualPitch)*(1-exp(-dt*4.8))
    }
}
