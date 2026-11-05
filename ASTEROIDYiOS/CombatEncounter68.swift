import Foundation

/// Physics-only collision phase of the v556 planetary game loop. This joins
/// MovePickup68, StepSolids68, WithSecond62 and ApplyHit96 WITHOUT inventing
/// an enemy AI, a boss state machine, weapon damage, or defense activation.
/// These actor snapshots must be supplied by their eventual owning modules.
struct CombatEncounter68 {
    var first:CombatBody68
    var second:CombatBody68?
    var rocks:[SphereAsteroid556]
    var bugs:[CombatBody68]
    var boss:CombatBody68?
    var pickups:[CombatBody68]
    var firstSurvival:CombatSurvival96
    var secondSurvival:CombatSurvival96
    let level:Int
    let difficulty:CombatBalance556.Difficulty

    struct FrameResult {
        let contacts:[CombatSolidEvent68]
        let damage:[CombatContactRouter96.TeamOutcome]
        let pickupsTrackingSecond:Int
    }

    mutating func contactPhase(dt:Float,firstDown:Bool=false,
                 secondDown:Bool=false,collectorLevel:Int=0,
                 defenseFirst:CombatContactRouter96.Defense = .unverified,
                 defenseSecond:CombatContactRouter96.Defense = .unverified,
                 robotFlags:[Bool]=[]) -> FrameResult {
        guard dt>0 && firstSurvival.playing && !firstSurvival.sceneBusy &&
                !firstSurvival.bossArrival else {
            return FrameResult(contacts:[],damage:[],pickupsTrackingSecond:0)
        }
        firstSurvival.advance(dt:dt)
        secondSurvival.advance(dt:dt)

        // Game.Step processes MovePickup68 before its StepSolids68 pass.
        var partnerTargets=0
        for i in pickups.indices {
            var pickup=pickups[i]
            let followsSecond=CombatPickupPhysics68.advance(&pickup,dt:dt,
                player:first.position,secondPlayer:second?.position,
                coopEnabled:second != nil,playerDown:firstDown,
                secondDown:secondDown,collectorLevel:collectorLevel,
                rocks:&rocks)
            if followsSecond {partnerTargets += 1}
            pickups[i]=pickup
        }

        let contacts=CombatSolids68.step(ship:&first,rocks:&rocks,bugs:&bugs,
            boss:&boss,partner:&second,shipDown:firstDown,
            partnerDown:secondDown)
        let outcomes=CombatContactRouter96.applyTeam(contacts,
            first:&firstSurvival,second:&secondSurvival,
            level:level,difficulty:difficulty,
            defenseFirst:defenseFirst,defenseSecond:defenseSecond,
            isRobot:robotFlags)
        return FrameResult(contacts:contacts,damage:outcomes,
                           pickupsTrackingSecond:partnerTargets)
    }
}
