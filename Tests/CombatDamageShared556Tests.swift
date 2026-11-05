import Foundation

@main struct CombatDamageShared556Tests {
    static func main() {
        for size in 1...3 {
            for tier in 0...4 {
                let hp=Rock.healthFor(size:size,tier:tier)
                let partial=CombatDamage556.hitRock(
                    health:hp,shardLife:0,amount:max(0,hp-1),
                    size:size,originalHealth:hp,tier:tier)
                precondition(partial.health==hp-max(0,hp-1))
                precondition(!partial.destroyed && partial.score==0)
                let destroyed=CombatDamage556.hitRock(
                    health:hp,shardLife:0,amount:hp,
                    size:size,originalHealth:hp,tier:tier)
                precondition(destroyed.destroyed)
                precondition(destroyed.score == (size==3 ? 20 : size==2 ? 50 : 100)+(hp-1)*30+tier*10)
            }
        }
        let shard=CombatDamage556.hitRock(
            health:1,shardLife:0.9,amount:10,size:1,originalHealth:1,tier:0)
        precondition(shard.removedShard && !shard.destroyed && shard.score==0)
        let noHit=CombatDamage556.hitRock(
            health:7,shardLife:0,amount:0,size:3,originalHealth:7,tier:3)
        precondition(noHit.health==7 && !noHit.destroyed)

        // Flat: the nearer rock is at index 1, while a farther rock occupies
        // index 0. Contact selection must not depend on array iteration order.
        let a=Vec2(x:-0.9,y:0)
        let boltEnd=Vec2(x:0.95,y:0)
        let points=[Vec2(x:0.70,y:0),Vec2(x:-0.30,y:0)]
        var first:Float=2
        var best:Int?=nil
        for (idx,position) in points.enumerated() {
            let hit=CombatCollision556.firstPeriodicHit(
                from:a,to:boltEnd,rockFrom:position,rockTo:position,
                radius:0.10,extent:1.35)
            if CombatDamage556.prefer(candidateTime:hit,candidateIndex:idx,
                                      bestTime:first,bestIndex:best) {
                first=hit
                best=idx
            }
        }
        precondition(best==1 && first < 0.5)

        // Sphere: shortest-arc nearest hit must also win when inserted last.
        let near=SphereAsteroid556(position:Vec2(x:655,y:360),
            velocity:Vec2(x:0,y:0),radius:8,size:3,tier:0)
        let far=SphereAsteroid556(position:Vec2(x:695,y:360),
            velocity:Vec2(x:0,y:0),radius:8,size:3,tier:0)
        let start=Vec2(x:635,y:360),velocity=Vec2(x:520,y:0)
        let tFar=SphereSector556.sweptBoltTime(start:start,velocity:velocity,
                                               rock:far,dt:0.2)
        let tNear=SphereSector556.sweptBoltTime(start:start,velocity:velocity,
                                                rock:near,dt:0.2)
        precondition(tNear >= 0 && tNear < tFar && tFar <= 1)
        let balance=CombatBalance556(level:1,difficulty:.normal,spherical:true)!
        var sector=SphereSector556(balance:balance,diagnosticAsteroids:[far,near])
        sector.fire(from:Vec2(x:600,y:360),direction:Vec2(x:1,y:0))
        sector.tick(dt:0.2,playerPosition:Vec2(x:600,y:360),
                    playerRadius:0,detectContacts:false)
        // Only the NEAR asteroid can disappear; the far asteroid must remain.
        precondition(sector.destroyedRocks == 1)
        precondition(sector.asteroids.contains { $0.size==3 && $0.health==1 &&
                                                 abs($0.position.x-695)<1.0 })
        print("PASS: 15 shared armor/score cases, terminal shards, no-op damage, flat/sphere earliest swept contact")
    }
}
