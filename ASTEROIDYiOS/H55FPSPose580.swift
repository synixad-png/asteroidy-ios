import Foundation

/// 1:1 PC v580 GpuGloves417.GloveWalkOffsets430,
/// GpuWeapon470.WeaponWalkOffsets470 and FingerPose425 math.
/// Pure source rules, tested without SceneKit or Metal.
enum H55FPSPose580 {
    static let gloveFieldOfView:Float=64
    static let weaponScale:Float=0.52

    static func gloveWalk(phase:Float,movement:Float,
                          visualIntensity:Float,hand:Int)
       ->(x:Float,y:Float,yawDegrees:Float) {
        let strength=max(0,min(1.4,movement))*max(0,min(1,visualIntensity))
        let alternating=phase+(hand==0 ? 0:Float.pi)
        return (sin(alternating)*0.019*strength,
                sin(alternating*2)*0.011*strength,
                sin(alternating)*1.35*strength)
    }

    static func weaponWalk(phase:Float,movement:Float,
                           visualIntensity:Float)
        ->(x:Float,y:Float,yawDegrees:Float) {
        let strength=max(0,min(1.4,movement))*max(0,min(1,visualIntensity))
        return (sin(phase)*0.023*strength,
                sin(phase*2)*0.0125*strength,
                sin(phase)*1.9*strength)
    }

    static func idle(time:Float,hand:Int,enabled:Bool)->Float {
        guard enabled else{return 0}
        return sin(time*0.82+Float(hand)*1.3)*0.003
    }
    static func weaponIdle(time:Float,enabled:Bool)->Float {
        enabled ? sin(time*0.82)*0.004 : 0
    }

    private static func ease(_ x:Float)->Float {
        let v=max(0,min(1,x))
        return v*v*(3-2*v)
    }
    static func fingers(time:Float,period:Float=8.5,intensity:Float=0.72,
                        hand:Int)->[Float] {
        let value=(time+Float(hand)*0.81)/max(2,period)
        let cycle=value-floor(value)
        let amplitude:[Float]=[0.72,0.89,1,0.95,0.78]
        let delay:[Float]=[0.040,0.015,0,0.022,0.049]
        return (0..<5).map { finger in
            let shift=delay[finger]
            let closing=ease((cycle-(0.34+shift))/0.16)
            let opening=ease((cycle-(0.62+shift*0.35))/0.22)
            let grip=closing*(1-opening)
            let idle:Float=0.025+0.020*sin(time*(0.42+Float(finger)*0.07)
                                         +Float(finger)*1.7+Float(hand)*0.8)
            return max(0,min(1,(grip*amplitude[finger]+idle*(1-grip))*intensity))
        }
    }
}
