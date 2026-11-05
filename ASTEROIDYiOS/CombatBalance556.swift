import Foundation

/// Deterministic sector quantities ported from ASTEROIDY v556:
/// Windows/src/Game.cs and Windows/src/Action38.cs.
/// This is not yet integrated into the playable combat loop.
struct CombatBalance556 {
    enum Difficulty: Int, CaseIterable { case easy = 0, normal = 1, hard = 2 }
    let level: Int
    let difficulty: Difficulty
    let spherical: Bool

    init?(level: Int, difficulty: Difficulty, spherical: Bool) {
        guard (1...26).contains(level) else { return nil }
        self.level = level
        self.difficulty = difficulty
        self.spherical = spherical
    }

    var waveCount: Int { level >= 13 ? 12 + min(8, (level - 13) * 2 / 3) : 8 + level / 2 }
    var heavyCount: Int { level < 10 ? 0 : 1 + (level - 10) / 2 }
    var denseCount: Int { level < 7 ? 0 : 1 + (level - 7) / 2 }
    var armoredCount: Int { level < 3 ? 0 : min(4, 1 + (level - 3) / 2) }

    var sectorRockCount: Int {
        let modifier = difficulty == .easy ? -2 : difficulty == .hard ? 3 : 0
        let base = max(6, waveCount + modifier) * (spherical ? 2 : 1)
        return max(4, Int((Double(base) * 0.8).rounded(.toNearestOrEven)))
    }
    var reinforcementQuota: Int {
        if level < 3 { return 0 }
        if difficulty == .easy { return level >= 6 ? 1 : 0 }
        return min(5, 2 + level / 8) + (difficulty == .hard ? 1 : 0)
    }

    func tier(at index: Int) -> Int? {
        let count = sectorRockCount
        guard (0..<count).contains(index) else { return nil }
        let heavy = min(4, heavyCount)
        let dense = min(3, denseCount)
        let armored = max(0, min(armoredCount, count - heavy - dense - 2))
        if level >= 13 { return index % 3 == 0 ? 4 : index % 3 == 1 ? 3 : 2 }
        return index < heavy ? 3 : index < heavy + dense ? 2 : index < heavy + dense + armored ? 1 : 0
    }
}
