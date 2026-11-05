import Foundation

// Port of ASTEROIDY v556 Windows/src/Physics68.cs SegmentHit68.
// Original uses Sphere67.Delta/WorldDelta67, while this mobile prototype
// supplies periodic 2D relative positions. Full sphere topology is NOT ported.
enum CombatCollision556 {
    static func segmentHit(delta: Vec2, travel: Vec2, radius: Float) -> Float {
        let len = travel.lengthSquared
        let c = delta.lengthSquared-radius*radius
        if c <= 0 { return 0 }
        if len < 0.0000001 { return 2 }
        let d = delta.x*travel.x+delta.y*travel.y
        let disc = d*d-len*c
        if disc < 0 { return 2 }
        let hit = (d-sqrt(disc))/len
        return hit >= 0 && hit <= 1 ? hit : 2
    }
    // Search all 9 copies of the periodic arena and return the FIRST contact.
    // Use relative travel to account for moving asteroids.
    static func firstPeriodicHit(from a:Vec2,to b:Vec2,rockFrom c:Vec2,rockTo d:Vec2,radius:Float,extent:Float) -> Float {
        let relative = (b-a)-(d-c)
        var first: Float = 2
        for sx in -1...1 { for sy in -1...1 {
            let offset = Vec2(x:Float(sx)*2*extent,y:Float(sy)*2*extent)
            let delta = c+offset-a
            first = min(first,segmentHit(delta:delta,travel:relative,radius:radius))
        }}
        return first
    }
}


// Common, pure combat decision core shared by the flat and spherical iOS
// test sectors. Values follow Windows/src/Game.cs Rock.Health and Game.Split.
// Caller still owns the geometry, fragment generation and visuals.
enum CombatDamage556 {
    struct RockResult: Equatable {
        let health: Int
        let destroyed: Bool
        let removedShard: Bool
        let score: Int
    }

    static func rockScore(size:Int,originalHealth:Int,tier:Int) -> Int {
        (size == 3 ? 20 : size == 2 ? 50 : 100)
          + (originalHealth - 1) * 30 + tier * 10
    }
    static func hitRock(health:Int,shardLife:Float,amount:Int,
                        size:Int,originalHealth:Int,tier:Int) -> RockResult {
        guard amount > 0 else {
            return RockResult(health:health,destroyed:false,
                              removedShard:false,score:0)
        }
        if shardLife > 0 {
            return RockResult(health:health,destroyed:false,
                              removedShard:true,score:0)
        }
        let remaining=health-amount
        if remaining > 0 {
            return RockResult(health:remaining,destroyed:false,
                              removedShard:false,score:0)
        }
        return RockResult(health:remaining,destroyed:true,
                          removedShard:false,
                          score:rockScore(size:size,originalHealth:originalHealth,tier:tier))
    }

    /// Compare contact times, not array iteration order. The reference game
    /// tests each candidate and updates the winner only on STRICTLY earlier
    /// intersection. Equal-time hits keep the first candidate.
    static func prefer(candidateTime:Float,candidateIndex:Int,
                       bestTime:Float,bestIndex:Int?) -> Bool {
        candidateTime >= 0 && candidateTime <= 1 &&
        (bestIndex == nil || candidateTime < bestTime)
    }
}


// Shared collision-damage response for the two iOS diagnostic arenas.
// The full Game.ApplyHit96 armor/shield/co-op pipeline is a separate port.
// This reducer deliberately never heals or restarts the player.
enum CombatHull556 {
    static func applyContact(hull:inout Int,cooldown:inout Float,
                             damage:Int=1,invulnerability:Float=1.3) -> Bool {
        guard hull>0 && cooldown<=0 && damage>0 else { return false }
        hull=max(0,hull-damage)
        cooldown=invulnerability
        return true
    }
    static func advance(cooldown:inout Float,dt:Float) {
        cooldown=max(0,cooldown-max(0,dt))
    }
}
