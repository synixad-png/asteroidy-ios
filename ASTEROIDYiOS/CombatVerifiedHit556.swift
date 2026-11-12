import Foundation

/// Verified orchestration of the Windows v556 ApplyHit96 -> HitByBoss ->
/// Game.Damage sequence. Source Campaign37 guardian interception and
/// Talents78 gauges may be supplied as real state by the owning controller.
/// The drone's active AI and other unported defenses remain external.
/// No unknown defense is silently interpreted as inactive.
enum CombatVerifiedHit556 {
    enum GuardResult:Equatable {
        case unverified, clear, absorbed
    }
    enum Outcome:Equatable {
        case ignored
        case requiresGuardianVerification
        case requiresTalentVerification
        case guardianAbsorbed
        case talentAbsorbed
        case developerProtected
        case activeTarczaAbsorbed
        case downForRescue
        case applied(CombatSurvival96.Hit)
    }
    struct TeamOutcome:Equatable {
        let player:CombatContactRouter96.Player?
        let outcome:Outcome
    }

    static func hit(cause:String,level:Int,
                    difficulty:CombatBalance556.Difficulty,
                    player:CombatRescue65.Player,
                    survival:inout CombatSurvival96,
                    body:inout CombatBody68,
                    dome:inout CombatTarcza145,
                    rescue:inout CombatRescue65,
                    cooperative:Bool,developerInfinite:Bool,
                    guardian:GuardResult,talent:GuardResult,
                    vitals:CombatTalentVitals78?=nil,
                    guardianState:CombatGuardian37?=nil) -> Outcome {
        // ApplyHit96 guard precedes every defensive side effect.
        guard survival.playing && !survival.sceneBusy &&
              !survival.bossArrival && !survival.currentDown &&
              survival.invincible<=0 && survival.lives>0
        else {return .ignored}
        // Windows Game.Damage v609 guards in source order:
        // TryGuardian, developer infinite, active Tarcza145, armor/hull.
        // Spare OSŁONY bars cannot intercept individual hits.
        if let guardianState {
            if guardianState.absorb(invincible:&survival.invincible) {
                return .guardianAbsorbed
            }
        } else {
            switch guardian {
            case .unverified:return .requiresGuardianVerification
            case .absorbed:return .guardianAbsorbed
            case .clear:break
            }
        }
        if developerInfinite {
            survival.invincible=0.8
            return .developerProtected
        }
        if dome.absorb(invincible:&survival.invincible,
                       reserve:&survival.shieldCharges) {
            return .activeTarczaAbsorbed
        }
        let damage=CombatSurvival96.collisionDamage(level:level,
                                                     difficulty:difficulty)
        if let vitals {
            // v556 Game.Damage AbsorbDamage78: the actual armor/hull gauges
            // decide whether the hit was absorbed, before TryDown65.
            if vitals.absorb(damage:damage,cause:cause,difficulty:difficulty,
                             invincible:&survival.invincible) {
                return .talentAbsorbed
            }
        } else {
            // If no real gauges were provided, the external Talent78 status
            // must be verified rather than silently assumed absent.
            switch talent {
            case .unverified:return .requiresTalentVerification
            case .absorbed:return .talentAbsorbed
            case .clear:break
            }
        }
        if rescue.beginDown(player,cooperative:cooperative,playing:survival.playing,
                            developerInfinite:developerInfinite,rescueDamage:false,
                            survival:&survival,body:&body) {
            return .downForRescue
        }
        let lost=survival.applyUnblockedCollision(
            level:level,difficulty:difficulty,cause:cause,damage:damage,
            allowCurrentImpact:vitals != nil)
        // Game.Damage ResetVitals78 runs on life loss AND GameOver.
        switch lost {
        case .lifeLost, .gameOver: vitals?.reset()
        case .ignored, .shieldAbsorbed: break
        }
        return .applied(lost)
    }

    /// Port of Windows/src/Gameplay65.cs FailRescue65 -> Game.Damage
    /// (v556). Unlike HitByBoss/ApplyHit96 this direct call intentionally
    /// bypasses the currentDown and 9999-second rescue immunity guards,
    /// does NOT consume a purchased one-hit shield, and cannot call
    /// TryDown65 again (rescueDamage65 is true in the source).
    /// Source order: TryGuardian -> developer infinite -> Tarcza145 ->
    /// AbsorbDamage78(default 27/32/38) -> lost life/respawn/GameOver.
    /// Unknown external protection must still be verified, never guessed.
    static func failedRescueDamage(level:Int,
                  difficulty:CombatBalance556.Difficulty,
                  survival:inout CombatSurvival96,
                  dome:inout CombatTarcza145,
                  developerInfinite:Bool,
                  guardian:GuardResult,talent:GuardResult,
                  vitals:CombatTalentVitals78?=nil,
                  guardianState:CombatGuardian37?=nil) -> Outcome {
        guard survival.playing && !survival.sceneBusy &&
              !survival.bossArrival && survival.lives>0
        else {return .ignored}
        if let guardianState {
            if guardianState.absorb(invincible:&survival.invincible) {
                return .guardianAbsorbed
            }
        } else {
            switch guardian {
            case .unverified: return .requiresGuardianVerification
            case .absorbed: return .guardianAbsorbed
            case .clear: break
            }
        }
        if developerInfinite {
            survival.invincible=0.8
            return .developerProtected
        }
        if dome.absorb(invincible:&survival.invincible,
                       reserve:&survival.shieldCharges) {
            return .activeTarczaAbsorbed
        }
        if let vitals {
            if vitals.absorb(damage:0,cause:"ZDERZENIE",
                             difficulty:difficulty,
                             invincible:&survival.invincible) {
                return .talentAbsorbed
            }
        } else {
            switch talent {
            case .unverified: return .requiresTalentVerification
            case .absorbed: return .talentAbsorbed
            case .clear: break
            }
        }
        let defaultDamage:Int = difficulty == .easy ? 27 :
                                difficulty == .hard ? 38 : 32
        let result=survival.applyUnblockedCollision(
            level:level,difficulty:difficulty,cause:"ZDERZENIE",
            damage:defaultDamage,allowCurrentImpact:true)
        switch result {
        case .lifeLost, .gameOver: vitals?.reset()
        case .ignored, .shieldAbsorbed: break
        }
        return .applied(result)
    }

    static func applyTeam(_ contacts:[CombatSolidEvent68],
                    level:Int,difficulty:CombatBalance556.Difficulty,
                    first:inout CombatBody68,second:inout CombatBody68?,
                    survivalFirst:inout CombatSurvival96,
                    survivalSecond:inout CombatSurvival96,
                    tarczaFirst:inout CombatTarcza145,
                    tarczaSecond:inout CombatTarcza145,
                    rescue:inout CombatRescue65,
                    developerInfinite:Bool,
                    guardianFirst:GuardResult,guardianSecond:GuardResult,
                    talentFirst:GuardResult,talentSecond:GuardResult,
                    isRobot:[Bool],
                    vitalsFirst:CombatTalentVitals78?=nil,
                    vitalsSecond:CombatTalentVitals78?=nil,
                    guardianStateFirst:CombatGuardian37?=nil,
                    guardianStateSecond:CombatGuardian37?=nil) -> [TeamOutcome] {
        var result:[TeamOutcome]=[]
        for event in contacts {
            guard let player=CombatContactRouter96.player(for:event) else {
                result.append(TeamOutcome(player:nil,outcome:.ignored))
                continue
            }
            guard let cause=CombatContactRouter96.cause(event,isRobot:isRobot) else {
                result.append(TeamOutcome(player:player,
                                          outcome:.requiresGuardianVerification))
                continue
            }
            switch player {
            case .first:
                let outcome=hit(cause:cause,level:level,difficulty:difficulty,
                    player:.first,survival:&survivalFirst,body:&first,
                    dome:&tarczaFirst,rescue:&rescue,
                    cooperative:second != nil,developerInfinite:developerInfinite,
                    guardian:guardianFirst,talent:talentFirst,vitals:vitalsFirst,
                    guardianState:guardianStateFirst)
                result.append(TeamOutcome(player:.first,outcome:outcome))
            case .second:
                guard var ship=second else {
                    result.append(TeamOutcome(player:.second,
                                              outcome:.requiresGuardianVerification))
                    continue
                }
                let outcome=hit(cause:cause,level:level,difficulty:difficulty,
                    player:.second,survival:&survivalSecond,body:&ship,
                    dome:&tarczaSecond,rescue:&rescue,cooperative:true,
                    developerInfinite:developerInfinite,
                    guardian:guardianSecond,talent:talentSecond,vitals:vitalsSecond,
                    guardianState:guardianStateSecond)
                second=ship
                result.append(TeamOutcome(player:.second,outcome:outcome))
            }
        }
        return result
    }
}
