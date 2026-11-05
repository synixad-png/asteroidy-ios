import Foundation
@main struct CombatHazards68Tests {
    static func rock(_ x:Float,_ radius:Float=10) -> SphereAsteroid556 {
        SphereAsteroid556(position:Vec2(x:x,y:360),velocity:Vec2(x:0,y:0),
                          radius:radius,mass:8)
    }
    static func body(_ x:Float) -> CombatBody68 {
        CombatBody68(position:Vec2(x:x,y:360),velocity:Vec2(x:0,y:0),
                     mass:3,radius:8)
    }
    static func main() {
        let origin=Vec2(x:640,y:360)
        let travel=Vec2(x:120,y:0)
        // The closest rock is deliberately at array index 1.
        let rocks=[rock(730),rock(660)]
        precondition(CombatHazards68.coveringRock(origin:origin,travel:travel,
            projectileRadius:4,rocks:rocks,playerPositions:[Vec2(x:705,y:360)],
            playerRadius:5)==1)
        precondition(CombatHazards68.coveringRock(origin:origin,travel:travel,
            projectileRadius:4,rocks:rocks,playerPositions:[Vec2(x:645,y:360)],
            playerRadius:5)==nil)
        precondition(CombatHazards68.coveringRock(origin:origin,travel:travel,
            projectileRadius:4,rocks:rocks,playerPositions:[Vec2(x:660,y:360)],
            playerRadius:10)==1) // tie: rock wins
        precondition(CombatHazards68.coveringRock(origin:origin,travel:travel,
            projectileRadius:4,rocks:[],playerPositions:[],playerRadius:5)==nil)
        precondition(CombatHazards68.coveringRock(
            origin:Vec2(x:1270,y:360),travel:Vec2(x:100,y:0),
            projectileRadius:4,rocks:[rock(5)],playerPositions:[],
            playerRadius:5)==0)

        var protected=rock(5)
        CombatHazards68.applyCoveredShot(&protected,
            origin:Vec2(x:1270,y:360),velocity:Vec2(x:160,y:0))
        precondition(abs(protected.velocity.x-0.5)<0.05)

        var explodingRocks=[rock(660),rock(1000)]
        var bugs=[body(670)],pickups=[body(680)]
        var boss:CombatBody68?=body(690)
        CombatHazards68.explosion(origin:origin,radius:100,impulse:80,
                                 rocks:&explodingRocks,bugs:&bugs,
                                 pickups:&pickups,boss:&boss)
        precondition(abs(explodingRocks[0].velocity.x-8)<0.2)
        precondition(explodingRocks[1].velocity.lengthSquared==0)
        precondition(abs(bugs[0].velocity.x-28)<0.4)
        precondition(abs(pickups[0].velocity.x-48)<0.4)
        precondition(abs(boss!.velocity.x-0.5)<0.05)
        let first=explodingRocks[0].velocity
        CombatHazards68.explosion(origin:origin,radius:0,impulse:800,
                                 rocks:&explodingRocks,bugs:&bugs,
                                 pickups:&pickups,boss:&boss)
        precondition(explodingRocks[0].velocity==first)
        var seamRocks=[rock(5)]
        var noBugs=[CombatBody68](), noPickups=[CombatBody68]()
        var noBoss:CombatBody68?=nil
        CombatHazards68.explosion(origin:Vec2(x:1270,y:360),
                                 radius:60,impulse:80,
                                 rocks:&seamRocks,bugs:&noBugs,
                                 pickups:&noPickups,boss:&noBoss)
        precondition(seamRocks[0].velocity.lengthSquared>1)
        print("PASS: Physics68 nearest hostile cover, player preemption/tie, meridian, 2.5% rock impulse, explosion mass falloff for all actor types")
    }
}
