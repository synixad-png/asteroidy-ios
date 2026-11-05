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
        case .shipRock: return "ASTEROIDA"
        case .shipBug(let index):
            guard isRobot.indices.contains(index) else { return nil }
            return isRobot[index] ? "ROBOTYCZNY WAZ" : "KOLIZJA ZE STATKIEM"
        case .shipBoss: return "ZDERZENIE Z BOSSEM"
        default: return nil
        }
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
