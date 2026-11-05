import Foundation
@main struct SphereShipRigidContact556Tests {
    static func main() {
        let cfg=CombatBalance556(level:1,difficulty:.normal,spherical:true)!
        let ship=Vec2(x:640,y:360)
        let rock=SphereAsteroid556(position:Vec2(x:654,y:360),
                                   velocity:Vec2(x:-10,y:0),radius:18,
                                   size:3,tier:0,mass:8)
        var sector=SphereSector556(balance:cfg,diagnosticAsteroids:[rock])
        guard let response=sector.tick(dt:1/120,playerPosition:ship,
                                      playerRadius:11.2,detectContacts:true,
                                      playerVelocity:Vec2(x:60,y:0),shipMass:2.4)
        else { fatalError("Expected live rigid contact response") }
        precondition(response.contacts==1)
        precondition(sector.hull==2 && sector.damageEvents==1)
        precondition(response.velocity.x<60)
        precondition(sector.asteroids[0].velocity.x > -10)
        let distance=sqrt(Sphere67.delta(target:sector.asteroids[0].position,
                                         origin:response.position).lengthSquared)
        precondition(distance>20)
        precondition(response.position.x.isFinite && response.position.y.isFinite)
        // Next step outside contact does not apply damage.
        let clear=SphereShipContact556(position:Vec2(x:0,y:0),
                                      velocity:Vec2(x:0,y:0),contacts:0)
        precondition(clear.contacts==0)
        // Pure position-only diagnostic mode remains backward-compatible.
        var diagnostic=SphereSector556(balance:cfg,diagnosticAsteroids:[rock])
        let result=diagnostic.tick(dt:1/120,playerPosition:ship,
                                   playerRadius:1000,detectContacts:true)
        precondition(result == nil)
        precondition(diagnostic.hull==2)
        print("PASS: spherical ship-rock rigid impact mass 2.4, restitution .42, impulse, hull and legacy contact mode")
    }
}
