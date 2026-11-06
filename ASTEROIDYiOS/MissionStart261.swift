import Foundation

/// Source: Windows v568 Orbit50.cs, Game.StartHubMission261 lines 58-78.
/// Reset preparation ONLY; Wave() and BeginLevelIntro() remain unported.
/// No fake mission completion, unlock or playable state is created here.
struct MissionStart261 {
    enum Failure: Error, Equatable {
        case invalidMission, lockedMission, busyScene, missingOriginalScene
    }
    struct Snapshot: Equatable {
        let level: Int
        let hubMission: Bool
        let resetVitals: Bool
        let resetFlightMotion: Bool
        let resetBossSpecial: Bool
        let resetMissionTrophies: Bool
        let resetSphereCamera: Bool
        let resetPadHeading: Bool
        let clearRocks: Bool
        let clearBugs: Bool
        let clearBullets: Bool
        let clearPickups: Bool
        let clearBossProjectiles: Bool
        let clearTunnelState: Bool
        let clearShopArrival: Bool
        let bossHealth: Int
        let bossLevel: Int
        let bossDefeatedAt: Int
        let bossSpawned: Bool
        let bossDefeated: Bool
        let shipXFraction: Float
        let shipYFraction: Float
        let shipAngleRadians: Float
        let resetVelocity: Bool
        let resetLevelTime: Bool
        let resetSectorTime: Bool
        let resetCooldown: Bool
        let visualReady: Bool
        let invincibleSeconds: Float
        let lives: Int
    }
    static func prepare(sector: Int, unlocked: Bool, sceneBusy: Bool,
                        hasOriginalScene: Bool, currentLives: Int,
                        startingLives: Int) -> Result<Snapshot, Failure> {
        guard (1...26).contains(sector) else { return .failure(.invalidMission) }
        guard unlocked else { return .failure(.lockedMission) }
        guard !sceneBusy else { return .failure(.busyScene) }
        guard hasOriginalScene else { return .failure(.missingOriginalScene) }
        let state = Snapshot(
            level:sector, hubMission:true,
            resetVitals:true, resetFlightMotion:true, resetBossSpecial:true,
            resetMissionTrophies:true, resetSphereCamera:true, resetPadHeading:true,
            clearRocks:true, clearBugs:true, clearBullets:true,
            clearPickups:true, clearBossProjectiles:true,
            clearTunnelState:true, clearShopArrival:true,
            bossHealth:0, bossLevel:0, bossDefeatedAt:0,
            bossSpawned:false, bossDefeated:false,
            shipXFraction:0.5, shipYFraction:0.5,
            shipAngleRadians:-Float.pi/2, resetVelocity:true,
            resetLevelTime:true, resetSectorTime:true, resetCooldown:true,
            visualReady:false, invincibleSeconds:sector<=4 ? 4.5 : 3,
            lives:currentLives<=0 ? startingLives : currentLives)
        return .success(state)
    }
    /// All three are required by source start and must be implemented before
    /// routing the campaign into the playable mission instead of planet preview.
    static func canEnterPlaying(hasSourceWave: Bool, hasSourceIntro: Bool,
                                hasFlightAndCombatRuntime: Bool) -> Bool {
        hasSourceWave && hasSourceIntro && hasFlightAndCombatRuntime
    }
}
