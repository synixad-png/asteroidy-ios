import Foundation

@main struct CombatRespawn556Tests {
    static func near(_ a:Float,_ b:Float,_ tol:Float=0.04) {
        precondition(abs(a-b)<tol,"Expected \\(b), got \\(a)")
    }
    static func body() -> CombatBody68 {
        CombatBody68(position:Vec2(x:730,y:450),
                     velocity:Vec2(x:44,y:20),mass:2.4,radius:11)
    }
    static func rock(_ x:Float,_ y:Float,_ vx:Float) -> SphereAsteroid556 {
        SphereAsteroid556(position:Vec2(x:x,y:y),
                          velocity:Vec2(x:vx,y:0),radius:12,
                          size:3,tier:1,health:3,mass:8,spin:0.25)
    }
    static func main() {
        var ship=body(),heading:Float=0.5
        var rocks=[rock(640,360,80),rock(670,360,30),rock(1000,360,50)]
        let originalFar=rocks[2].position
        var shots=[SphereBolt556(position:Vec2(x:700,y:400),
                                 velocity:Vec2(x:50,y:0),life:1),
                   SphereBolt556(position:Vec2(x:720,y:400),
                                 velocity:Vec2(x:50,y:0),life:1)]
        var samplerCalls=0
        let action=CombatRespawn556.apply(.lifeLost(
            remaining:2,respawnProtection:3,cause:"ASTEROIDA"),
            ship:&ship,heading:&heading,rocks:&rocks,shots:&shots) { index in
                samplerCalls += 1
                return index==0 ? Float(0) : Float.pi/2
            }
        precondition(action == .respawned(removedShots:2,relocatedRocks:2))
        precondition(samplerCalls==2 && shots.isEmpty)
        precondition(ship.position == Vec2(x:640,y:360))
        precondition(ship.velocity.lengthSquared==0)
        near(heading,-Float.pi/2)
        for i in 0..<2 {
            let distance=sqrt(Sphere67.delta(target:rocks[i].position,
                                  origin:ship.position).lengthSquared)
            near(distance,220,0.3)
            precondition(rocks[i].health==3 && rocks[i].mass==8 && rocks[i].spin==0.25)
        }
        near(sqrt(rocks[0].velocity.lengthSquared),80)
        near(sqrt(rocks[1].velocity.lengthSquared),30)
        precondition(rocks[2].position == originalFar)
        precondition(rocks[2].velocity.x==50)

        var deadShip=body(),deadHeading:Float=1
        var deadRocks=[rock(640,360,15)]
        let deadRockBefore=deadRocks[0].position
        var deadShots=[SphereBolt556(position:deadShip.position,
                                    velocity:Vec2(x:20,y:0),life:0.5)]
        let deadAction=CombatRespawn556.apply(.gameOver(cause:"BOSS"),
            ship:&deadShip,heading:&deadHeading,
            rocks:&deadRocks,shots:&deadShots) {_ in
                fatalError("Game over must not consume random scatter")
            }
        precondition(deadAction == .gameOver(removedShots:1))
        precondition(deadShip.position == Vec2(x:730,y:450))
        precondition(deadRocks[0].position==deadRockBefore)
        precondition(deadShots.isEmpty)
        print("PASS: source Game.Damage respawn center, shot clear, 160/220 geodesic rock safety, speed and game-over branch")
    }
}
