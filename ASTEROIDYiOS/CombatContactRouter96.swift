import Foundation

// Bridges verified Physics68 contact events to the original ApplyHit96
// collision/lives policy. Guardian298, Tarcza145, talents78 and co-op65
// are NOT ported here: their owner must explicitly verify the defense result.
// Unverified defense always blocks progression rather than assuming absence.
enum CombatContactRouter96 {
    enum Defense: Equatable {
        case unverified
        case noneAbsorbed
        case guardianAbsorbed
        case tarczaAbsorbed
        case talentAbsorbed
        case coopDown
    }
    enum Outcome: Equatable {
        case ignoredNonPlayer
        case requiresDefenseVerification
        case externalDefenseAbsorbed
        case applied(CombatSurvival96.Hit)
    }

    static func cause(_ event: CombatSolidEvent68,
                      isRobot:[Bool]) -> String? {
        switch event {
        case .shipRock, .partnerRock: return "ASTEROIDA"
        case .shipBug(let index), .partnerBug(let index):
            guard isRobot.indices.contains(index) else { return nil }
            return isRobot[index] ? "ROBOTYCZNY WAZ" : "KOLIZJA ZE STATKIEM"
        case .shipBoss, .partnerBoss: return "ZDERZENIE Z BOSSEM"
        default: return nil
        }
    }

    enum Player: Equatable { case first, second }
    struct TeamOutcome: Equatable {
        let player:Player?
        let outcome:Outcome
    }
    static func player(for event:CombatSolidEvent68) -> Player? {
        switch event {
        case .shipRock, .shipBug, .shipBoss: return .first
        case .partnerRock, .partnerBug, .partnerBoss: return .second
        default: return nil
        }
    }
    private static func process(_ event:CombatSolidEvent68,
                        to survival:inout CombatSurvival96,
                        level:Int,difficulty:CombatBalance556.Difficulty,
                        defense:Defense,isRobot:[Bool]) -> Outcome {
        guard let source=cause(event,isRobot:isRobot) else {
            return .requiresDefenseVerification
        }
        switch defense {
        case .unverified: return .requiresDefenseVerification
        case .guardianAbsorbed, .tarczaAbsorbed, .talentAbsorbed, .coopDown:
            return .externalDefenseAbsorbed
        case .noneAbsorbed:
            let damage=CombatSurvival96.collisionDamage(level:level,
                                                         difficulty:difficulty)
            return .applied(survival.applyUnblockedCollision(
                level:level,difficulty:difficulty,cause:source,damage:damage))
        }
    }

    /// Physics68.WithSecond62 invokes ApplyHit96 with the second player's
    /// state. Keep lives, charges and respawn immunity isolated per player;
    /// no external defense is silently treated as inactive.
    static func applyTeam(_ events:[CombatSolidEvent68],
                          first:inout CombatSurvival96,
                          second:inout CombatSurvival96,
                          level:Int,difficulty:CombatBalance556.Difficulty,
                          defenseFirst:Defense,defenseSecond:Defense,
                          isRobot:[Bool]) -> [TeamOutcome] {
        var result:[TeamOutcome]=[]
        for event in events {
            switch player(for:event) {
            case .first:
                let outcome=process(event,to:&first,level:level,
                                    difficulty:difficulty,
                                    defense:defenseFirst,isRobot:isRobot)
                result.append(TeamOutcome(player:.first,outcome:outcome))
            case .second:
                let outcome=process(event,to:&second,level:level,
                                    difficulty:difficulty,
                                    defense:defenseSecond,isRobot:isRobot)
                result.append(TeamOutcome(player:.second,outcome:outcome))
            case .none:
                result.append(TeamOutcome(player:nil,outcome:.ignoredNonPlayer))
            }
        }
        return result
    }

    static func apply(_ events:[CombatSolidEvent68],
                      to survival:inout CombatSurvival96,
                      level:Int,
                      difficulty:CombatBalance556.Difficulty,
                      defense:Defense,
                      isRobot:[Bool]) -> [Outcome] {
        var outcomes:[Outcome]=[]
        for event in events {
            let isPlayer:Bool
            switch event {
            case .shipRock, .shipBug, .shipBoss: isPlayer=true
            default: isPlayer=false
            }
            if !isPlayer {
                outcomes.append(.ignoredNonPlayer)
                continue
            }
            guard let source=cause(event,isRobot:isRobot) else {
                outcomes.append(.requiresDefenseVerification)
                continue
            }
            switch defense {
            case .unverified:
                outcomes.append(.requiresDefenseVerification)
            case .guardianAbsorbed, .tarczaAbsorbed, .talentAbsorbed, .coopDown:
                // The external module has ALREADY handled the defense;
                // do not consume lives/shields again.
                outcomes.append(.externalDefenseAbsorbed)
            case .noneAbsorbed:
                let damage=CombatSurvival96.collisionDamage(
                    level:level,difficulty:difficulty)
                let hit=survival.applyUnblockedCollision(
                    level:level,difficulty:difficulty,
                    cause:source,damage:damage)
                outcomes.append(.applied(hit))
            }
        }
        return outcomes
    }
}
