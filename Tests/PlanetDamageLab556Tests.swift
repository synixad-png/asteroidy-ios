import Foundation

@main struct PlanetDamageLab556Tests {
    static func create() -> (SphereSector556,SphereFlight67) {
        let balance=CombatBalance556(level:1,difficulty:.normal,spherical:true)!
        let rock=SphereAsteroid556(position:Vec2(x:655,y:360),
                                   velocity:Vec2(x:0,y:0),radius:15,mass:8)
        var flight=SphereFlight67()
        flight.position=Vec2(x:640,y:360)
        flight.velocity=Vec2(x:15,y:0)
        flight.camera=SphereCamera67(at:flight.position)
        return (SphereSector556(balance:balance,diagnosticAsteroids:[rock]),flight)
    }
    static func contact(_ sector:inout SphereSector556,
                        _ flight:inout SphereFlight67) -> Int {
        let result=sector.tick(dt:1/120,playerPosition:flight.position,
            playerRadius:11.2,playerVelocity:flight.velocity,shipMass:2.4,
            useLegacyHull:false)
        if let result {
            flight.position=result.position
            flight.velocity=result.velocity
        }
        return result?.contacts ?? 0
    }
    static func freshImpact(_ sector:inout SphereSector556,
                            _ flight:inout SphereFlight67,
                            _ lab:inout PlanetDamageLab556) -> CombatVerifiedHit556.Outcome {
        let rock=SphereAsteroid556(position:Vec2(x:655,y:360),
            velocity:Vec2(x:0,y:0),radius:15,mass:8)
        sector.installRespawnWorld(rocks:[rock],shots:sector.bolts)
        flight.position=Vec2(x:640,y:360)
        flight.velocity=Vec2(x:15,y:0)
        let hits=contact(&sector,&flight)
        precondition(hits==1,"Real Sphere67 collision required for a damage event")
        return lab.advance(dt:1/120,contacts:hits,sector:&sector,flight:&flight)
    }
    static func main() {
        var (sector,flight)=create()
        var lab=PlanetDamageLab556()
        sector.fire(from:Vec2(x:500,y:360),direction:Vec2(x:1,y:0))
        precondition(sector.bolts.count == 1)
        let first=freshImpact(&sector,&flight,&lab)
        precondition(first == .talentAbsorbed)
        precondition(lab.lives==3 && lab.hull==60 && lab.armor==7)
        precondition(lab.deathCount==0)
        precondition(sector.hull==3,"Legacy three-hit counter stays isolated")
        for n in 2...15 {
            _=lab.advance(dt:5,contacts:0,sector:&sector,flight:&flight)
            let result=freshImpact(&sector,&flight,&lab)
            let damageTier=(n-1)%5
            if damageTier==4 {
                let remaining=3-n/5
                if remaining>0 {
                    precondition(result == .applied(.lifeLost(
                        remaining:remaining,respawnProtection:4.5,
                        cause:"ASTEROIDA")))
                    precondition(lab.lives==remaining)
                    precondition(lab.armor==25 && lab.hull==60)
                    precondition(sector.bolts.isEmpty)
                    precondition(flight.position==Vec2(x:640,y:360))
                    precondition(flight.velocity.lengthSquared==0)
                    precondition(abs(flight.heading+Float.pi/2)<0.001)
                    let distance=sqrt(Sphere67.delta(
                        target:sector.asteroids[0].position,
                        origin:flight.position).lengthSquared)
                    precondition(abs(distance-220)<0.6)
                } else {
                    precondition(result == .applied(.gameOver(cause:"ASTEROIDA")))
                    precondition(lab.gameOver && lab.lives==0)
                }
            } else {
                precondition(result == .talentAbsorbed)
                precondition(lab.lives==3-(n-1)/5)
            }
        }
        precondition(lab.deathCount==2)
        _=lab.advance(dt:6,contacts:1,sector:&sector,flight:&flight)
        precondition(lab.lives==0)
        var (shieldSector,shieldFlight)=create()
        var shieldLab=PlanetDamageLab556(startingShieldCharges:1)
        let shieldContact=contact(&shieldSector,&shieldFlight)
        precondition(shieldContact==1)
        let shieldHit=shieldLab.advance(dt:1/120,contacts:shieldContact,
            sector:&shieldSector,flight:&shieldFlight)
        precondition(shieldHit == .applied(
            .shieldAbsorbed(remaining:0,cause:"ASTEROIDA")))
        precondition(shieldLab.lives==3 && shieldLab.deathCount==0)
        precondition(shieldLab.survival.invincible==1)
        precondition(shieldLab.armor==25 && shieldLab.hull==60)
        var (guardSector,guardFlight)=create()
        var guardLab=PlanetDamageLab556(guardianOwned:true)
        let guardContact=contact(&guardSector,&guardFlight)
        precondition(guardContact==1)
        let intercepted=guardLab.advance(dt:1/120,contacts:guardContact,
            sector:&guardSector,flight:&guardFlight)
        precondition(intercepted == .guardianAbsorbed)
        precondition(guardLab.guardian.charges==0)
        precondition(guardLab.lives==3 && guardLab.armor==25 &&
                     guardLab.hull==60)
        precondition(guardLab.survival.invincible==1.2)
        // Original Windows Game.cs:240: the held Tarcza145 input
        // activates BEFORE StepSolids68. Its 12/s drain and 35-point
        // impact cost must apply inside the already playable Boreas
        // diagnostic, without touching lives, armor or hull.
        var (domeSector,domeFlight)=create()
        var domeLab=PlanetDamageLab556()
        let domeContact=contact(&domeSector,&domeFlight)
        precondition(domeContact==1)
        let domeHit=domeLab.advance(dt:1/120,contacts:domeContact,
            sector:&domeSector,flight:&domeFlight,tarczaHeld:true)
        precondition(domeHit == .activeTarczaAbsorbed)
        precondition(domeLab.tarczaActive)
        precondition(abs(domeLab.tarczaEnergy-24.9)<0.002)
        precondition(domeLab.survival.invincible >= 0.28)
        precondition(domeLab.armor==25 && domeLab.hull==60)
        precondition(domeLab.lives==3 && domeLab.deathCount==0)
        _=domeLab.advance(dt:1/120,contacts:0,
            sector:&domeSector,flight:&domeFlight,tarczaHeld:false)
        precondition(!domeLab.tarczaActive)
        precondition(abs(domeLab.tarczaEnergy-24.9)<0.002)
        let stillSafe=domeLab.advance(dt:5,contacts:0,
            sector:&domeSector,flight:&domeFlight,tarczaHeld:false)
        precondition(stillSafe == .ignored)
        precondition(domeLab.lives==3 && domeLab.armor==25 &&
                     domeLab.hull==60)
        // Held until exhausted, then no ghost interception: later real
        // contact must fall through to original armor/hull protection.
        _=domeLab.advance(dt:5,contacts:0,
            sector:&domeSector,flight:&domeFlight,tarczaHeld:true)
        precondition(domeLab.tarczaEnergy==0 && !domeLab.tarczaActive)
        let afterExhaust=freshImpact(&domeSector,&domeFlight,&domeLab)
        precondition(afterExhaust == .talentAbsorbed)
        precondition(domeLab.armor==7 && domeLab.hull==60 &&
                     domeLab.lives==3)

        print("PASS: Boreas live Physics68 collision -> source 25 armor/60 hull -> 3 lives -> 4.5s respawn -> game over; purchased shield")
    }
}
