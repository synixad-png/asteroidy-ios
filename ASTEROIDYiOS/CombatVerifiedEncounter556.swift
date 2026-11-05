import Foundation

/// Verified collision-only integration harness for ASTEROIDY v556.
/// Supplies actual Tarcza/WithSecond/respawn state transitions and leaves
/// absent guardian, talent, AI, boss and assets unverified, never faked.
struct CombatVerifiedEncounter556 {
    var encounter:CombatEncounter68
    var domeFirst=CombatTarcza145()
    var domeSecond=CombatTarcza145()
    var rescue=CombatRescue65()
    // Optional real v556 defensive state. Nil preserves the older
    // explicitly-unverified collision harness, never inventing ownership.
    var firstGuardian:CombatGuardian37?=nil
    var secondGuardian:CombatGuardian37?=nil
    var firstVitals:CombatTalentVitals78?=nil
    var secondVitals:CombatTalentVitals78?=nil
    var headingFirst:Float = -Float.pi/2
    var headingSecond:Float = -Float.pi/2
    var shots:[SphereBolt556]=[]
    private var scatterSeed:UInt32=0x55600007

    init(encounter:CombatEncounter68) {
        self.encounter=encounter
    }

    struct Result {
        let contacts:[CombatSolidEvent68]
        let hitOutcomes:[CombatVerifiedHit556.TeamOutcome]
        let damageTransitions:[CombatRespawn556.Action]
        let rescueEvent:CombatRescue65.Event
        let pickupsTrackingSecond:Int
    }

    mutating func step(dt:Float,firstDomeHeld:Bool=false,
                       secondDomeHeld:Bool=false,
                       firstFiring:Bool=false,secondFiring:Bool=false,
                       collectorLevel:Int=0,robotFlags:[Bool]=[],
                       developerInfinite:Bool=false,devOpen:Bool=false,
                       guardianFirst:CombatVerifiedHit556.GuardResult = .unverified,
                       guardianSecond:CombatVerifiedHit556.GuardResult = .unverified,
                       talentFirst:CombatVerifiedHit556.GuardResult = .unverified,
                       talentSecond:CombatVerifiedHit556.GuardResult = .unverified) -> Result {
        let noRescue:CombatRescue65.Event = .none
        guard dt>0 else {
            return Result(contacts:[],hitOutcomes:[],damageTransitions:[],
                          rescueEvent:noRescue,pickupsTrackingSecond:0)
        }
        firstVitals?.advance(dt:dt)
        secondVitals?.advance(dt:dt)
        let firstDown=rescue.down(.first),secondDown=rescue.down(.second)
        domeFirst.tick(dt:dt,held:firstDomeHeld,
                       playing:encounter.firstSurvival.playing,shipDown:firstDown)
        domeSecond.tick(dt:dt,held:secondDomeHeld,
                        playing:encounter.secondSurvival.playing,shipDown:secondDown)

        // Use the SAME tested Physics68 contact phase. Its unverified
        // defense mode records contact events but never subtracts lives.
        let frame=encounter.contactPhase(dt:dt,firstDown:firstDown,
            secondDown:secondDown,collectorLevel:collectorLevel,
            defenseFirst:.unverified,defenseSecond:.unverified,
            robotFlags:robotFlags)

        var first=encounter.first, second=encounter.second
        var survivalFirst=encounter.firstSurvival
        var survivalSecond=encounter.secondSurvival
        let hit=CombatVerifiedHit556.applyTeam(frame.contacts,
            level:encounter.level,difficulty:encounter.difficulty,
            first:&first,second:&second,
            survivalFirst:&survivalFirst,survivalSecond:&survivalSecond,
            tarczaFirst:&domeFirst,tarczaSecond:&domeSecond,
            rescue:&rescue,developerInfinite:developerInfinite,
            guardianFirst:guardianFirst,guardianSecond:guardianSecond,
            talentFirst:talentFirst,talentSecond:talentSecond,
            isRobot:robotFlags,
            vitalsFirst:firstVitals,vitalsSecond:secondVitals,
            guardianStateFirst:firstGuardian,guardianStateSecond:secondGuardian)

        // CombatVerifiedHit556 resets actual gauges on life loss/game over;
        // rendered explosions and weapons remain external to this harness.
        var transitions:[CombatRespawn556.Action]=[]
        var rocks=encounter.rocks
        var projectiles=shots
        var seed=scatterSeed
        for event in hit {
            guard case .applied(let damage)=event.outcome else {continue}
            switch event.player {
            case .first:
                let action=CombatRespawn556.apply(damage,
                    ship:&first,heading:&headingFirst,rocks:&rocks,
                    shots:&projectiles) { _ in
                        seed=seed &* 1664525 &+ 1013904223
                        return Float(seed & 0x00FFFFFF)/Float(0x01000000)*2*Float.pi
                    }
                if action != .none {transitions.append(action)}
            case .second:
                if var player=second {
                    let action=CombatRespawn556.apply(damage,
                        ship:&player,heading:&headingSecond,rocks:&rocks,
                        shots:&projectiles) { _ in
                            seed=seed &* 1664525 &+ 1013904223
                            return Float(seed & 0x00FFFFFF)/Float(0x01000000)*2*Float.pi
                        }
                    if action != .none {transitions.append(action)}
                    second=player
                }
            case .none:break
            }
        }
        scatterSeed=seed
        shots=projectiles
        encounter.rocks=rocks

        var rescueEvent:CombatRescue65.Event = .none
        if var partner=second {
            rescueEvent=rescue.tick(dt:dt,playing:survivalFirst.playing,
                sceneBusy:survivalFirst.sceneBusy,devOpen:devOpen,
                bossArrival:survivalFirst.bossArrival,cooperative:true,
                first:&first,second:&partner,firstSurvival:&survivalFirst,
                secondSurvival:&survivalSecond,
                firstFiring:firstFiring,secondFiring:secondFiring)
            second=partner
        }
        encounter.first=first
        encounter.second=second
        encounter.firstSurvival=survivalFirst
        encounter.secondSurvival=survivalSecond
        return Result(contacts:frame.contacts,hitOutcomes:hit,
                      damageTransitions:transitions,rescueEvent:rescueEvent,
                      pickupsTrackingSecond:frame.pickupsTrackingSecond)
    }
}
