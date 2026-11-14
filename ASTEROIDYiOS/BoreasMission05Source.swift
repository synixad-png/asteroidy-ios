import Foundation

/// Source-verified mission 05 preparation. This is the same Wave568,
/// MissionStart261 and campaign state used by CARBONIS 01; no parallel
/// random wave generator, fabricated unlock or side-effectful preview.
enum BoreasMission05Source {
    static let sector = AnimatedPlanetTestSlot556.sector

    static func prepare(
        campaign: CampaignProgress556,
        verifiedAssets: Bool,
        difficulty: CombatBalance556.Difficulty,
        seed: Int32,
        currentLives: Int,
        startingLives: Int,
        shopProfile: Sector01Shop568.State
    ) -> Sector01PreparedWave568? {
        guard sector == 5,
              campaign.selectedSector == sector,
              campaign.unlocked(sector),
              verifiedAssets else { return nil }
        let preparation = MissionStart261.prepare(
            sector: sector,
            unlocked: true,
            sceneBusy: false,
            hasOriginalScene: true,
            currentLives: currentLives,
            startingLives: startingLives)
        guard case let .success(reset) = preparation,
              let encounter = MissionWave568.generate(
                  level: sector,
                  difficulty: difficulty,
                  seed: seed,
                  ship: Vec2(x: 640, y: 360)),
              encounter.sector == sector,
              encounter.objective == .defend else { return nil }

        // Preserve the original generated robots: dropping them would
        // silently change the mission's actual victory conditions.
        return Sector01PreparedWave568(
            reset: reset,
            encounter: encounter,
            incoming: MissionIncoming568(
                from: encounter, difficulty: difficulty),
            difficulty: difficulty,
            isReplay: campaign.completed(sector),
            shopProfile: shopProfile,
            combatSupplySeed: seed)
    }

    /// A complete mission requires native enemy and RobotSnake runtimes
    /// attached to its one authoritative combat state, not a GLB preview.
    static func requiresRobotRuntime(_ prepared: Sector01PreparedWave568) -> Bool {
        prepared.reset.level == sector && !prepared.encounter.robots.isEmpty
    }
}
