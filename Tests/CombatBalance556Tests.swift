import Foundation

@main struct CombatBalance556Tests {
    static func main() {
        var checked = 0
        for level in 1...26 {
            for difficulty in CombatBalance556.Difficulty.allCases {
                for spherical in [false, true] {
                    guard let balance = CombatBalance556(level: level, difficulty: difficulty, spherical: spherical) else { fatalError("valid level") }
                    let waves = level >= 13 ? 12 + min(8, (level - 13) * 2 / 3) : 8 + level / 2
                    let modifier = difficulty == .easy ? -2 : difficulty == .hard ? 3 : 0
                    let rocks = max(4, Int((Double(max(6, waves + modifier) * (spherical ? 2 : 1)) * 0.8).rounded(.toNearestOrEven)))
                    let quota = level < 3 ? 0 : difficulty == .easy ? (level >= 6 ? 1 : 0) : min(5, 2 + level / 8) + (difficulty == .hard ? 1 : 0)
                    precondition(balance.waveCount == waves && balance.sectorRockCount == rocks && balance.reinforcementQuota == quota)
                    precondition(balance.tier(at: -1) == nil && balance.tier(at: rocks) == nil)
                    let tiers = (0..<rocks).map { balance.tier(at: $0)! }
                    if level >= 13 { precondition(tiers.enumerated().allSatisfy { $0.element == ($0.offset % 3 == 0 ? 4 : $0.offset % 3 == 1 ? 3 : 2) }) }
                    else { precondition(tiers.allSatisfy { (0...3).contains($0) }) }
                    checked += 1
                }
            }
        }
        precondition(CombatBalance556(level: 0, difficulty: .normal, spherical: false) == nil)
        precondition(CombatBalance556(level: 27, difficulty: .normal, spherical: false) == nil)
        precondition(CombatBalance556(level: 1, difficulty: .normal, spherical: false)!.sectorRockCount == 6)
        precondition(CombatBalance556(level: 13, difficulty: .normal, spherical: true)!.tier(at: 0) == 4)
        print("PASS: \(checked) combat-balance scenarios (26 levels x 3 difficulties x 2 geometries)")
    }
}
