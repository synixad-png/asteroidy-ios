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
