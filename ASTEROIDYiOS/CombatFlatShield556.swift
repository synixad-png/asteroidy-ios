import Foundation

/// Flat-arena branch of Game.cs collision defense in ASTEROIDY v556.
/// This is the source's rock push/velocity policy, not a replacement for
/// external TarczaAbsorb145/guardian/talent/co-op decisions.
enum CombatFlatShield556 {
    struct RockResponse: Equatable {
        var position:Vec2
        var velocity:Vec2
        var remainingCharges:Int
        var invincibility:Float
    }
    enum Outcome:Equatable {
        case defenseUnverified
        case tarczaAbsorbed(RockResponse)
        case purchasedShieldAbsorbed(RockResponse)
        case applyDamage
    }
    static func collide(ship:Vec2,angle:Float,
                        rockPosition:Vec2,rockVelocity:Vec2,rockRadius:Float,
                        purchasedShieldCharges:Int,
                        tarczaAbsorbed:Bool?) -> Outcome {
        // nil is unknown: this must NOT be silently treated as a Tarcza miss.
        guard let tarczaAbsorbed else { return .defenseUnverified }
        let delta=rockPosition-ship
        let distance=sqrt(delta.lengthSquared)
        let backwards=Vec2(x:cos(angle+.pi),y:sin(angle+.pi))
        let direction=distance>0.1 ? delta*(1/distance) : backwards
        let speed=sqrt(rockVelocity.lengthSquared)
        if tarczaAbsorbed {
            return .tarczaAbsorbed(RockResponse(
                position:ship+direction*(rockRadius+52),
                velocity:direction*max(65,speed),
                remainingCharges:max(0,purchasedShieldCharges),
                invincibility:0))
        }
        if purchasedShieldCharges>0 {
            return .purchasedShieldAbsorbed(RockResponse(
                position:ship+direction*(rockRadius+32),
                velocity:direction*max(55,speed),
                remainingCharges:purchasedShieldCharges-1,
                invincibility:0.8))
        }
        return .applyDamage
    }
}
