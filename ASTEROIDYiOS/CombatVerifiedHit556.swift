import Foundation

/// Verified orchestration of the Windows v556 ApplyHit96 -> HitByBoss ->
/// Game.Damage sequence. Guardian298 and AbsorbDamage78 remain owned by
/// separate modules: callers must explicitly state their verified result.
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
                    vitals:CombatTalentVitals78?=nil) -> Outcome {
        // ApplyHit96 guard precedes every defensive side effect.
        guard survival.playing && !survival.sceneBusy &&
              !survival.bossArrival && !survival.currentDown &&
              survival.invincible<=0 && survival.lives>0
        else {return .ignored}
        // HitByBoss first handles developer invulnerability, then active
        // energy dome, then purchased one-hit shields.
        if developerInfinite {
            survival.invincible=0.8
            return .developerProtected
        }
        if dome.absorb(invincible:&survival.invincible) {
            return .activeTarczaAbsorbed
        }
        let damage=CombatSurvival96.collisionDamage(level:level,
                                                     difficulty:difficulty)
        // BossTunnelGame.HitByBoss absorbs any ApplyHit96 collision with
        // a purchased shield before entering Game.Damage(). Invulnerability
        // lasts 1s and lives stay unchanged; Game.Damage only clears charges
        // when no shield intercepted the hit.
        if let absorbed=survival.absorbPurchasedHitByBoss(cause:cause) {
            return .applied(absorbed)
        }
        // Game.Damage checks guardian, then talents, then TryDown65.
        // Tarcza145 has just been checked by HitByBoss, so with no state
        // mutation between the calls its second check cannot succeed.
        switch guardian {
        case .unverified:return .requiresGuardianVerification
        case .absorbed:return .guardianAbsorbed
        case .clear:break
        }
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
            level:level,difficulty:difficulty,cause:cause,damage:damage)
        // Game.Damage ResetVitals78 runs on life loss AND GameOver.
        switch lost {
        case .lifeLost, .gameOver: vitals?.reset()
        case .ignored, .shieldAbsorbed: break
        }
        return .applied(lost)
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
                    vitalsSecond:CombatTalentVitals78?=nil) -> [TeamOutcome] {
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
                    guardian:guardianFirst,talent:talentFirst,vitals:vitalsFirst)
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
                    guardian:guardianSecond,talent:talentSecond,vitals:vitalsSecond)
                second=ship
                result.append(TeamOutcome(player:.second,outcome:outcome))
            }
        }
        return result
    }
}
