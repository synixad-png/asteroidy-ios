import Foundation

/// Stage-C bridge: original CARBONIS selection produces a real source-driven
/// Game.StartHubMission261 reset snapshot AND an initial Game.Wave() encounter.
/// It deliberately does not start unported flight, enemy AI, or grant rewards.
struct Sector01PreparedWave568 {
    let reset: MissionStart261.Snapshot
    let encounter: MissionWave568.Encounter
    let incoming: MissionIncoming568
    /// Game.BeginRewards57: replay in a selected hub mission grants no
    /// further token rewards. The original completion bit is immutable.
    var isReplay:Bool = false
    var shopProfile:Sector01Shop568.State = Sector01Shop568.State()

    static func prepare(entry: Sector01Entry568,
                        campaign: CampaignProgress556,
                        hasOriginalC279Assets: Bool,
                        difficulty: CombatBalance556.Difficulty,
                        seed: Int32,
                        currentLives: Int = 3,
                        startingLives: Int = 3,
                        shopProfile:Sector01Shop568.State = .init()) -> Self? {
        guard entry.sector == 1,
              entry.stage == .sourcePlanetInspection,
              campaign.selectedSector == entry.sector,
              campaign.unlocked(entry.sector),
              hasOriginalC279Assets else { return nil }
        let resetResult = MissionStart261.prepare(
            sector: entry.sector, unlocked: true, sceneBusy: false,
            hasOriginalScene: true, currentLives: currentLives,
            startingLives: startingLives)
        guard case let .success(reset) = resetResult,
              let encounter = MissionWave568.generate(
                level: entry.sector, difficulty: difficulty, seed: seed,
                ship: Vec2(x:640,y:360)) else { return nil }
        return Self(reset:reset,encounter:encounter,
                    incoming:MissionIncoming568(from:encounter,difficulty:difficulty),
                    isReplay:campaign.completed(1),
                    shopProfile:shopProfile)
    }

    /// Runtime transition remains blocked until wave entities are actually
    /// stepped, rendered, collidable, and connected to mission victory/defeat.
    var isPlayable: Bool { false }
}
