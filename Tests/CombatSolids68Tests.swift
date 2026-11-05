import Foundation
@main struct CombatSolids68Tests {
    static func body(_ x:Float,_ y:Float=360,_ radius:Float=11,
                     _ mass:Float=2.4,_ vx:Float=0) -> CombatBody68 {
        CombatBody68(position:Vec2(x:x,y:y),velocity:Vec2(x:vx,y:0),
                     mass:mass,radius:radius)
    }
    static func rock(_ x:Float,_ radius:Float=12) -> SphereAsteroid556 {
        SphereAsteroid556(position:Vec2(x:x,y:360),velocity:Vec2(x:0,y:0),
                          radius:radius,mass:8)
    }
    static func main() {
        precondition(CombatSolids68.shipMass(type:0,customShipType:7,
            heavyShipType:8,transportShipType:9,miningDetached:false)==2.4)
        precondition(CombatSolids68.shipMass(type:2,customShipType:7,
            heavyShipType:8,transportShipType:9,miningDetached:false)==5)
        precondition(CombatSolids68.shipMass(type:7,customShipType:7,
            heavyShipType:8,transportShipType:9,miningDetached:false)==6.2)
        precondition(CombatSolids68.shipMass(type:8,customShipType:7,
            heavyShipType:8,transportShipType:9,miningDetached:false)==10)
        precondition(CombatSolids68.shipMass(type:9,customShipType:7,
            heavyShipType:8,transportShipType:9,miningDetached:false)==12.5)
        precondition(CombatSolids68.shipMass(type:9,customShipType:7,
            heavyShipType:8,transportShipType:9,miningDetached:true)==1.5)
        precondition(CombatSolids68.shipMass(type:4,customShipType:7,
            heavyShipType:8,transportShipType:9,miningDetached:false)==3.4)

        // One class of contact at a time; no fabricated AI in the adapter.
        do {
            var ship=body(640,360,11,2.4,70), rocks=[rock(660)],
                bugs=[CombatBody68](), boss:CombatBody68?=nil,
                partner:CombatBody68?=nil
            let ev=CombatSolids68.step(ship:&ship,rocks:&rocks,bugs:&bugs,
                                       boss:&boss,partner:&partner)
            precondition(ev==[.shipRock(0)] && ship.velocity.x<70)
        }
        do {
            var ship=body(640),rocks=[SphereAsteroid556](),
                bugs=[body(660,360,15,3)],boss:CombatBody68?=nil,
                partner:CombatBody68?=nil
            let ev=CombatSolids68.step(ship:&ship,rocks:&rocks,bugs:&bugs,
                                       boss:&boss,partner:&partner)
            precondition(ev==[.shipBug(0)])
        }
        do {
            var ship=body(640),rocks=[SphereAsteroid556](),
                bugs=[CombatBody68](),boss:CombatBody68?=body(670,360,25,80),
                partner:CombatBody68?=nil
            let ev=CombatSolids68.step(ship:&ship,rocks:&rocks,bugs:&bugs,
                                       boss:&boss,partner:&partner)
            precondition(ev==[.shipBoss])
        }
        do {
            var ship=body(100),rocks=[rock(660)],
                bugs=[body(640,360,15,3)],boss:CombatBody68?=nil,
                partner:CombatBody68?=nil
            let ev=CombatSolids68.step(ship:&ship,rocks:&rocks,bugs:&bugs,
                                       boss:&boss,partner:&partner)
            precondition(ev==[.bugRock(0,0)])
        }
        do {
            var ship=body(100),rocks=[SphereAsteroid556](),
                bugs=[body(640,360,15,3),body(662,360,15,3)],
                boss:CombatBody68?=nil,partner:CombatBody68?=nil
            let ev=CombatSolids68.step(ship:&ship,rocks:&rocks,bugs:&bugs,
                                       boss:&boss,partner:&partner)
            precondition(ev==[.bugBug(0,1)])
        }
        do {
            var ship=body(100),rocks=[rock(670)],
                bugs=[CombatBody68](),boss:CombatBody68?=body(640,360,25,80),
                partner:CombatBody68?=nil
            let ev=CombatSolids68.step(ship:&ship,rocks:&rocks,bugs:&bugs,
                                       boss:&boss,partner:&partner)
            precondition(ev==[.bossRock(0)])
        }
        do {
            var ship=body(100),rocks=[SphereAsteroid556](),
                bugs=[body(670,360,13,3)],
                boss:CombatBody68?=body(640,360,25,80),
                partner:CombatBody68?=nil
            let ev=CombatSolids68.step(ship:&ship,rocks:&rocks,bugs:&bugs,
                                       boss:&boss,partner:&partner)
            precondition(ev==[.bossBug(0)])
        }
        do {
            var ship=body(640),rocks=[SphereAsteroid556](),
                bugs=[CombatBody68](),boss:CombatBody68?=nil,
                partner:CombatBody68?=body(659)
            let ev=CombatSolids68.step(ship:&ship,rocks:&rocks,bugs:&bugs,
                                       boss:&boss,partner:&partner)
            precondition(ev==[.coopShip])
        }
        do {
            var ship=body(640),rocks=[rock(660)],
                bugs=[CombatBody68](),boss:CombatBody68?=nil,
                partner:CombatBody68?=body(659)
            let ev=CombatSolids68.step(ship:&ship,rocks:&rocks,bugs:&bugs,
                                       boss:&boss,partner:&partner,
                                       shipDown:true,partnerDown:false)
            // Physics68.WithSecond62 still processes the active partner.
            precondition(ev == [.partnerRock(0)])
        }
        // Physics68.cs:31-45 Contact68 computes friction but never
        // applies it to angular velocity. ONLY RockContacts68:57 does.
        // Ship/rock, bug/rock and boss/rock must preserve rock.spin.
        do {
            var ship=CombatBody68(position:Vec2(x:640,y:360),
                velocity:Vec2(x:75,y:23),mass:2.4,radius:11)
            var rockState=SphereAsteroid556(position:Vec2(x:659,y:360),
                velocity:Vec2(x:-40,y:0),radius:15,mass:8,spin:0.7)
            precondition(CombatSolids68.collisionWithRock(
                &ship,&rockState,restitution:0.42))
            precondition(rockState.spin==0.7)
        }
        do {
            var bug=CombatBody68(position:Vec2(x:640,y:360),
                velocity:Vec2(x:75,y:23),mass:3,radius:15)
            var rocks=[SphereAsteroid556(position:Vec2(x:661,y:360),
                velocity:Vec2(x:-40,y:0),radius:15,mass:8,spin:0.7)]
            var ship=body(100),bugs=[bug],
                boss:CombatBody68?=nil,partner:CombatBody68?=nil
            let events=CombatSolids68.step(ship:&ship,rocks:&rocks,
                bugs:&bugs,boss:&boss,partner:&partner)
            precondition(events.contains(.bugRock(0,0)))
            precondition(rocks[0].spin==0.7)
        }

        print("PASS: all six v556 ShipMass68 variants, seven source rigid collision categories, co-op and down guards")
    }
}
