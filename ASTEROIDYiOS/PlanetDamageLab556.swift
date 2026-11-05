import Foundation

/// Explicit, playable Boreas diagnostic for the verified v556 ship-hit
/// transition. Guardian298 and AbsorbDamage78 have NOT been ported: this
/// isolated test opts into a known no-guardian, no-talent configuration.
/// It never marks campaign sectors completed or replaces the normal arena.
struct PlanetDamageLab556 {
    private(set) var survival=CombatSurvival96()
    private(set) var dome=CombatTarcza145()
    private(set) var vitals=CombatTalentVitals78()
    private var rescue=CombatRescue65()
    private var scatterSeed:UInt32=0x556A9805
    private(set) var lastOutcome:CombatVerifiedHit556.Outcome = .ignored
    private(set) var relocatedRocks=0
    private(set) var deathCount=0

    init(startingShieldCharges:Int=0) {
        survival.shieldCharges=max(0,startingShieldCharges)
    }

    var lives:Int {survival.lives}
    var hull:Int {vitals.hull}
    var armor:Int {vitals.armor}
    var gameOver:Bool {!survival.playing}

    /// Ship/rock impulses have already been resolved by SphereSector556;
    /// this phase applies the original ApplyHit96 -> HitByBoss -> Damage
    /// policy and, when needed, relocates rocks and resets active shots.
    mutating func advance(dt:Float,contacts:Int,
                          sector:inout SphereSector556,
                          flight:inout SphereFlight67,
                          level:Int=1,
                          difficulty:CombatBalance556.Difficulty = .normal)
                          -> CombatVerifiedHit556.Outcome {
        guard dt>0 else {return .ignored}
        survival.advance(dt:dt)
        vitals.advance(dt:dt)
        dome.tick(dt:dt,held:false,playing:survival.playing,shipDown:false)
        guard contacts>0 && survival.playing else {
            lastOutcome = .ignored
            return .ignored
        }
        var body=CombatBody68(position:flight.position,velocity:flight.velocity,
                              mass:2.4,radius:11.2)
        let outcome=CombatVerifiedHit556.hit(cause:"ASTEROIDA",
            level:level,difficulty:difficulty,player:.first,
            survival:&survival,body:&body,dome:&dome,rescue:&rescue,
            cooperative:false,developerInfinite:false,
            guardian:.clear,talent:.clear,vitals:vitals)
        if case .applied(let hit)=outcome {
            var rockState=sector.asteroids
            var shots=sector.bolts
            var direction=flight.heading
            var seed=scatterSeed
            let result=CombatRespawn556.apply(hit,ship:&body,
                heading:&direction,rocks:&rockState,shots:&shots) { _ in
                    seed=seed &* 1664525 &+ 1013904223
                    return Float(seed & 0x00FFFFFF) /
                        Float(0x01000000) * 2 * Float.pi
                }
            scatterSeed=seed
            switch result {
            case .respawned(_,let moved):
                deathCount += 1
                relocatedRocks += moved
                sector.installRespawnWorld(rocks:rockState,shots:shots)
                let configuration=flight.flight.configuration
                flight.position=body.position
                flight.velocity=body.velocity
                flight.heading=direction
                flight.flight=FlightDynamics556()
                flight.flight.configuration=configuration
                flight.camera=SphereCamera67(at:flight.position)
            case .gameOver:
                sector.installRespawnWorld(rocks:rockState,shots:shots)
            case .none:
                break
            }
        }
        lastOutcome=outcome
        return outcome
    }
}
