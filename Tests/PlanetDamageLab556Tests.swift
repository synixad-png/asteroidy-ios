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
    static func main() {
        var (sector,flight)=create()
        var lab=PlanetDamageLab556()
        sector.fire(from:Vec2(x:500,y:360),direction:Vec2(x:1,y:0))
        precondition(sector.bolts.count == 1)
        let firstContact=contact(&sector,&flight)
        precondition(firstContact>0)
        let first=lab.advance(dt:1/120,contacts:firstContact,sector:&sector,flight:&flight)
        precondition(first == .applied(.lifeLost(remaining:2,
                                               respawnProtection:4.5,cause:"ASTEROIDA")))
        precondition(lab.lives==2 && lab.deathCount==1)
        precondition(sector.hull==3, "Legacy three-hit counter must stay isolated")
        precondition(flight.position == Vec2(x:640,y:360))
        precondition(flight.velocity.lengthSquared==0)
        precondition(abs(flight.heading + Float.pi/2)<0.001)
        precondition(sector.bolts.isEmpty)
        let safe=sqrt(Sphere67.delta(target:sector.asteroids[0].position,
                                    origin:flight.position).lengthSquared)
        precondition(abs(safe-220)<0.6)
        let rocksAfterRespawn=sector.asteroids[0].position
        let ignored=lab.advance(dt:0.5,contacts:1,sector:&sector,flight:&flight)
        precondition(ignored == .ignored && lab.lives==2)
        precondition(sector.asteroids[0].position==rocksAfterRespawn)
        for expected in [1,0] {
            _=lab.advance(dt:5,contacts:0,sector:&sector,flight:&flight)
            let fresh=SphereAsteroid556(position:Vec2(x:655,y:360),
                velocity:Vec2(x:0,y:0),radius:15,mass:8)
            sector.installRespawnWorld(rocks:[fresh],shots:[])
            let count=contact(&sector,&flight)
            precondition(count>0)
            let result=lab.advance(dt:1/120,contacts:count,
                sector:&sector,flight:&flight)
            precondition(lab.lives==expected)
            if expected==0 {
                precondition(result == .applied(.gameOver(cause:"ASTEROIDA")))
                precondition(lab.gameOver)
                let final=lab.advance(dt:6,contacts:1,sector:&sector,flight:&flight)
                precondition(final == .ignored)
                precondition(lab.lives==0)
            } else {
                precondition(result == .applied(.lifeLost(remaining:1,
                    respawnProtection:4.5,cause:"ASTEROIDA")))
            }
        }
        // HitByBoss purchased shields protect spherical rock contacts for
        // exactly 1 s; the flat only branch instead grants 0.8 s.
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
        print("PASS: live Boreas no-guardian v556 shield, 3-life respawn, 160/220 rock safety, 4.5s immunity, cleared projectiles and game over")
    }
}
