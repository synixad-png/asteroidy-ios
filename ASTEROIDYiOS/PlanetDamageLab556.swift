import Foundation

/// Explicit, playable Boreas diagnostic for the verified v556 ship-hit
/// transition. It uses the source-verified Guardian37, Talents78,
/// Tarcza145 and Damage/respawn modules. This diagnostic does not
/// complete campaign missions or replace the full planetary controller.
struct PlanetDamageLab556 {
    private(set) var survival=CombatSurvival96()
    private(set) var dome=CombatTarcza145()
    private(set) var vitals=CombatTalentVitals78()
    private(set) var guardian:CombatGuardian37
    private var rescue=CombatRescue65()
    private var scatterSeed:UInt32=0x556A9805
    private(set) var lastOutcome:CombatVerifiedHit556.Outcome = .ignored
    private(set) var relocatedRocks=0
    private(set) var deathCount=0

    init(startingShieldCharges:Int=0,guardianOwned:Bool=false) {
        survival.shieldCharges=max(0,startingShieldCharges)
        guardian=CombatGuardian37(owned:guardianOwned)
    }

    var lives:Int {survival.lives}
    var hull:Int {vitals.hull}
    var armor:Int {vitals.armor}
    var tarczaEnergy:Float {dome.energy}
    var tarczaActive:Bool {dome.active}
    var gameOver:Bool {!survival.playing}

    /// Ship/rock impulses have already been resolved by SphereSector556;
    /// this phase applies the original ApplyHit96 -> HitByBoss -> Damage
    /// policy and, when needed, relocates rocks and resets active shots.
    mutating func advance(dt:Float,contacts:Int,
                          sector:inout SphereSector556,
                          flight:inout SphereFlight67,
                          tarczaHeld:Bool=false,
                          level:Int=1,
                          difficulty:CombatBalance556.Difficulty = .normal)
                          -> CombatVerifiedHit556.Outcome {
        guard dt>0 else {return .ignored}
        survival.advance(dt:dt)
        vitals.advance(dt:dt,playing:survival.playing,
                       shipDown:survival.currentDown)
        // Windows/src/Game.cs:240 StepTarcza145(dt,input.Tarcza145)
        // precedes player collision (Game.cs:248). The held input is
        // momentary and consumes original 12 energy/s + 35/impact.
        dome.tick(dt:dt,held:tarczaHeld,
                  playing:survival.playing,shipDown:survival.currentDown,
                  reserve:&survival.shieldCharges)
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
            guardian:.unverified,talent:.unverified,vitals:vitals,
            guardianState:guardian)
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
