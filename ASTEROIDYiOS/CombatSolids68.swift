import Foundation

// Physics68.StepSolids68 contact adapter. The geometry is the actual Sphere67
// tangent plane, but AI motion, robot constraints and bosses are owned by
// their future modules and must supply their bodies. No enemies are invented.
struct CombatBody68 {
    var position: Vec2
    var velocity: Vec2
    var mass: Float
    var radius: Float
}

enum CombatSolidEvent68: Equatable {
    case bugRock(Int, Int), bugBug(Int, Int)
    case bossRock(Int), bossBug(Int)
    case shipRock(Int), shipBug(Int), shipBoss
    case partnerRock(Int), partnerBug(Int), partnerBoss
    case coopShip
}

enum CombatSolids68 {
    // Actual Game.Physics68 ShipMass68 selection.
    static func shipMass(type:Int,customShipType:Int,heavyShipType:Int,
                         transportShipType:Int,miningDetached:Bool) -> Float {
        if type == 0 { return 2.4 }
        if type == 2 { return 5 }
        if type == customShipType { return 6.2 }
        if type == heavyShipType { return 10 }
        if type == transportShipType { return miningDetached ? 1.5 : 12.5 }
        return 3.4
    }

    @discardableResult
    static func contact(_ a:inout CombatBody68,_ b:inout CombatBody68,
                        restitution:Float) -> Bool {
        var rockA=SphereAsteroid556(position:a.position,velocity:a.velocity,
                                    radius:a.radius,mass:a.mass)
        var rockB=SphereAsteroid556(position:b.position,velocity:b.velocity,
                                    radius:b.radius,mass:b.mass)
        guard SphereRockContact68.resolve(&rockA,&rockB,restitution:restitution)
        else {return false}
        a.position=rockA.position
        a.velocity=rockA.velocity
        b.position=rockB.position
        b.velocity=rockB.velocity
        return true
    }
    static func collisionWithRock(_ a:inout CombatBody68,
                                  _ r:inout SphereAsteroid556,
                                  restitution:Float) -> Bool {
        var rockA=SphereAsteroid556(position:a.position,velocity:a.velocity,
                                    radius:a.radius,mass:a.mass)
        guard SphereRockContact68.resolve(&rockA,&r,restitution:restitution)
        else { return false }
        a.position=rockA.position
        a.velocity=rockA.velocity
        return true
    }

    private static func resolveShipContacts(_ player:inout CombatBody68,
                 rocks:inout [SphereAsteroid556],
                 bugs:inout [CombatBody68],
                 boss:inout CombatBody68?,
                 events:inout [CombatSolidEvent68],
                 second:Bool) {
        for ri in rocks.indices {
            var rock=rocks[ri]
            if collisionWithRock(&player,&rock,restitution:0.42) {
                rocks[ri]=rock
                events.append(second ? .partnerRock(ri) : .shipRock(ri))
            }
        }
        for bi in bugs.indices {
            var bug=bugs[bi]
            if contact(&player,&bug,restitution:0.35) {
                bugs[bi]=bug
                events.append(second ? .partnerBug(bi) : .shipBug(bi))
            }
        }
        if var active=boss,contact(&player,&active,restitution:0.30) {
            boss=active
            events.append(second ? .partnerBoss : .shipBoss)
        }
    }

    // StepSolids68 order: rock/rock -> bug/rock -> bug/bug -> boss/rock ->
    // boss/bug -> primary ship contacts -> second ship contacts -> ship pair.
    // RobotContacts70 and SeparateBoss71 are intentionally not guessed here.
    static func step(ship:inout CombatBody68,
                     rocks:inout [SphereAsteroid556],
                     bugs:inout [CombatBody68],
                     boss:inout CombatBody68?,
                     partner:inout CombatBody68?,
                     shipDown:Bool=false,partnerDown:Bool=false)
                     -> [CombatSolidEvent68] {
        var events:[CombatSolidEvent68]=[]
        _ = SphereRockContact68.solve(&rocks)
        for bi in bugs.indices {
            for ri in rocks.indices {
                var bug=bugs[bi],rock=rocks[ri]
                if collisionWithRock(&bug,&rock,restitution:0.45) {
                    events.append(.bugRock(bi,ri))
                    bugs[bi]=bug
                    rocks[ri]=rock
                }
            }
        }
        if bugs.count>1 {
            for bi in 0..<(bugs.count-1) {
                for bj in (bi+1)..<bugs.count {
                    var a=bugs[bi],b=bugs[bj]
                    if contact(&a,&b,restitution:0.30) {
                        bugs[bi]=a;bugs[bj]=b
                        events.append(.bugBug(bi,bj))
                    }
                }
            }
        }
        if var active=boss {
            for ri in rocks.indices {
                var rock=rocks[ri]
                if collisionWithRock(&active,&rock,restitution:0.45) {
                    rocks[ri]=rock
                    events.append(.bossRock(ri))
                }
            }
            for bi in bugs.indices {
                var bug=bugs[bi]
                if contact(&active,&bug,restitution:0.35) {
                    bugs[bi]=bug
                    events.append(.bossBug(bi))
                }
            }
            boss=active
        }
        if !shipDown {
            resolveShipContacts(&ship,rocks:&rocks,bugs:&bugs,
                                boss:&boss,events:&events,second:false)
        }
        // Original Physics68.StepSolids68 uses WithSecond62(ShipContacts68):
        // the partner gets ALL asteroid, bug and boss contacts independently.
        // It must still collide when only the first player is down.
        if !partnerDown, var second=partner {
            resolveShipContacts(&second,rocks:&rocks,bugs:&bugs,
                                boss:&boss,events:&events,second:true)
            partner=second
        }
        if !shipDown && !partnerDown, var active=partner {
            if contact(&ship,&active,restitution:0.12) {
                partner=active
                events.append(.coopShip)
            }
        }
        return events
    }
}
