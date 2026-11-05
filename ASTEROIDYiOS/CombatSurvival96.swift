import Foundation

/// Isolated port of the verified, unblocked collision branch:
/// BossTunnelGame.ApplyHit96 / HitByBoss and Game.Damage, ASTEROIDY v556.
/// Original guardian, Tarcza145, talent absorbs, co-op down and developer
/// guards must be handled by their OWN modules before calling this reducer.
/// Unlike the v21 three-hit sandbox, this is the actual v556 lives/shield
/// transition. It is intentionally not yet coupled to the prototype HUD.
struct CombatSurvival96 {
    enum Hit: Equatable {
        case ignored
        case shieldAbsorbed(remaining:Int, cause:String)
        case lifeLost(remaining:Int, respawnProtection:Float, cause:String)
        case gameOver(cause:String)
    }
    var lives: Int=3
    var shieldCharges: Int=0
    var invincible: Float=0
    var playing: Bool=true
    var currentDown: Bool=false
    var sceneBusy: Bool=false
    var bossArrival: Bool=false
    private(set) var latestCause:String?=nil

    static func collisionDamage(level:Int,difficulty:CombatBalance556.Difficulty) -> Int {
        if level<=2 {return 18}
        if level<=4 {return 22}
        if level<=8 {return 26}
        switch difficulty {
        case .easy: return 27
        case .normal: return 32
        case .hard: return 38
        }
    }
    static func respawnProtection(level:Int,difficulty:CombatBalance556.Difficulty) -> Float {
        if level<=4 { return 4.5 }
        switch difficulty {
        case .easy: return 4
        case .normal: return 3
        case .hard: return 2
        }
    }

    mutating func advance(dt:Float) {
        invincible=max(0,invincible-max(0,dt))
    }

    /// Game.Step, flat rock collision: the purchased shield is checked
    /// BEFORE Damage(), only for asteroid contacts. Other unblocked
    /// damage bypasses this branch and resets shield charges on death.
    mutating func absorbPurchasedRockContact(cause:String) -> Hit? {
        guard lives>0 && playing && !sceneBusy && !bossArrival &&
              !currentDown && invincible<=0 && shieldCharges>0
        else { return nil }
        shieldCharges -= 1
        invincible=0.8
        latestCause=cause
        return .shieldAbsorbed(remaining:shieldCharges,cause:cause)
    }

    /// BossTunnelGame.HitByBoss(): when an incoming ApplyHit96 event
    /// reaches this branch, ANY damage cause may consume a purchased shield.
    /// This grants 1s immunity. It is different from the flat-only asteroid
    /// contact interception (.8s and different physical knockback).
    mutating func absorbPurchasedHitByBoss(cause:String) -> Hit? {
        guard lives>0 && playing && !sceneBusy && !bossArrival &&
              !currentDown && invincible<=0 && shieldCharges>0
        else { return nil }
        shieldCharges -= 1
        invincible=1
        latestCause=cause
        return .shieldAbsorbed(remaining:shieldCharges,cause:cause)
    }

    /// Only for collisions not caught by guardian/Tarcza/talent/co-op guards.
    /// This function cannot silently assume those unported systems are absent.
    mutating func applyUnblockedCollision(
        level:Int,difficulty:CombatBalance556.Difficulty,
        cause:String,damage:Int) -> Hit {
        guard lives>0 && playing && !sceneBusy && !bossArrival &&
              !currentDown && invincible<=0 && damage>0
        else {return .ignored}
        latestCause=cause
        // Original Game.Damage explicitly clears shield charges on an
        // unblocked hit. It does not automatically consume one charge.
        shieldCharges=0
        lives -= 1
        if lives<=0 {
            playing=false  // Game.Damage transitions Mode to GameOver.
            return .gameOver(cause:cause)
        }
        let protection=Self.respawnProtection(level:level,difficulty:difficulty)
        invincible=protection
        return .lifeLost(remaining:lives,
                         respawnProtection:protection,cause:cause)
    }
}
