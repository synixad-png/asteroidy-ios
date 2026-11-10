import Foundation

/// Direct port of Windows/src/HudMotion.cs HudIconMotion.
/// Four persistent per-model spring states (energy, bomb, shield, boost).
/// The authored GLB and F6 yaw/pitch/roll are never mutated. This produces
/// short, lagged movements; NOT endless 360-degree icon spinning.
struct HudIconMotion600 {
    struct Pose {
        var yaw:Float=0
        var pitch:Float=0
        var roll:Float=0
        var floatY:Float=0
    }
    private struct Style {
        let speed:Double,phase:Double
        let yaw:Float,pitch:Float,roll:Float,lift:Float
        let response:Float,lag:Float
    }
    private struct State {
        var yaw:Float=0,pitch:Float=0,roll:Float=0,lift:Float=0
        var lastTime:Double=0
        var started=false
    }
    private static let styles:[Style]=[
        Style(speed:1.6,phase:0.3,yaw:4.2,pitch:2.4,roll:1.3,
              lift:1,response:1,lag:0.18),
        Style(speed:0.9,phase:2.2,yaw:2.1,pitch:1.3,roll:1.1,
              lift:0.5,response:0.65,lag:0.33),
        Style(speed:1.2,phase:4.3,yaw:3,pitch:1.8,roll:1,
              lift:0.8,response:0.7,lag:0.25),
        Style(speed:1.95,phase:1.4,yaw:4.6,pitch:2.6,roll:1.9,
              lift:1.25,response:1.12,lag:0.14)
    ]
    private var states=Array(repeating:State(),count:4)
    mutating func reset() {states=Array(repeating:State(),count:4)}
    private static func bound(_ x:Float,_ limit:Float)->Float {
        max(-limit,min(limit,x))
    }
    mutating func evaluate(index:Int,seconds:Double,motion:HudMotion600.Pose)->Pose? {
        guard (0..<4).contains(index) else{return nil}
        guard motion.iconStrength>0,seconds.isFinite else {
            states[index]=State()
            return Pose()
        }
        let style=Self.styles[index]
        let strength=min(1.6,motion.iconStrength)
        let drift=Self.bound(motion.x/48,1)
        let bank=Self.bound(motion.roll/7,1)
        let climb=Self.bound(motion.y/8,1)
        let angle=seconds*style.speed+style.phase
        // Keep trigonometric sampling separate from the Float spring.
        // Swift must not split infix operators across expression lines.
        let yawWave=Float(sin(angle))
        let pitchWave=Float(cos(angle*0.83+style.phase*0.35))
        let rollWave=Float(sin(angle*0.71+style.phase))
        let liftWave=Float(sin(angle*0.66+style.phase*0.5))
        let targetYaw=strength*(style.yaw*yawWave+drift*3*style.response)
        let targetPitch=strength*(style.pitch*pitchWave-climb*2.2*style.response)
        let targetRoll=strength*(style.roll*rollWave+bank*1.7*style.response)
        let targetLift=strength*style.lift*liftWave
        var state=states[index]
        if !state.started || seconds<state.lastTime ||
           seconds-state.lastTime>0.5 {
            state.yaw=targetYaw
            state.pitch=targetPitch
            state.roll=targetRoll
            state.lift=targetLift
            state.started=true
        } else {
            let dt=Float(max(0,seconds-state.lastTime))
            let alpha=1-Float(exp(-Double(dt)/Double(style.lag)))
            state.yaw+=(targetYaw-state.yaw)*alpha
            state.pitch+=(targetPitch-state.pitch)*alpha
            state.roll+=(targetRoll-state.roll)*alpha
            state.lift+=(targetLift-state.lift)*alpha
        }
        state.lastTime=seconds
        states[index]=state
        return Pose(yaw:Self.bound(state.yaw,9),
                    pitch:Self.bound(state.pitch,7),
                    roll:Self.bound(state.roll,5),
                    floatY:Self.bound(state.lift,2))
    }
}
