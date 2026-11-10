import Foundation

/// Exact PC v584 CombatSupplyDrops rules, using the existing .NET Random
/// implementation. This independent stream must never touch the mission
/// random state used by asteroid layouts, splits, AI, visual FX or tokens.
struct SourceCombatSupply586 {
    private var random:MissionWave568.SourceRandom

    init(missionSeed:Int32) {
        random=MissionWave568.SourceRandom(
            seed:missionSeed ^ Int32(bitPattern:0x4A63B291))
    }

    /// Single roll per killed target; bomb window first, energy second.
    /// Nil means no drop. The caller owns the shared pickup list and gates.
    mutating func decide(enemy:Bool,asteroidSize:Int,
                         currentBombs:Int,currentIonAmmo:Int,
                         pickupsCount:Int,lootEnabled:Bool)->SourcePickupModels586.Kind? {
        guard lootEnabled,pickupsCount<96 else{return nil}
        let bombChance:Double=enemy ? 0.055 :
            asteroidSize>=3 ? 0.065 : asteroidSize==2 ? 0.025 : 0.008
        let energyChance:Double=enemy ? 0.155 :
            asteroidSize>=3 ? 0.17 : asteroidSize==2 ? 0.09 : 0.025
        let roll=random.unit()
        if currentBombs<3 && roll<bombChance {return .bomb}
        if currentIonAmmo<300 && roll<bombChance+energyChance {return .energy}
        return nil
    }

    /// Called only when a drop was actually spawned, like the second
    /// combatSupplyRandom.NextDouble() in Windows CombatSupplyDrops.cs.
    mutating func velocity()->Vec2 {
        let angle=Float(random.unit()*(2*Double.pi))
        return Vec2(x:cos(angle)*17,y:sin(angle)*17)
    }

    static func collected(_ kind:SourcePickupModels586.Kind,
                          ionAmmo:inout Int,bombs:inout Int)->Bool {
        switch kind {
        case .energy:
            let gain=min(40,max(0,300-ionAmmo))
            guard gain>0 else{return false}
            ionAmmo+=gain
            return true
        case .bomb:
            guard bombs<3 else{return false}
            bombs=min(3,bombs+1)
            return true
        case .shield,.boost:
            // Never create an inert imitation of unported source abilities.
            return false
        }
    }
}
