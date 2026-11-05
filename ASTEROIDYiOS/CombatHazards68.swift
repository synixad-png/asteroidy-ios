import Foundation

// Port of Windows/src/Physics68.cs ProjectileCover68 and Explosion68.
// These are pure combat geometry/physics APIs: the enemy and boss modules
// must supply their actual projectile and actor state when available.
enum CombatHazards68 {
    /// A rock blocks an enemy projectile unless a player is hit STRICTLY
    /// sooner. In a tie, the rock acts as cover, matching ProjectileCover68.
    static func coveringRock(origin:Vec2,travel:Vec2,projectileRadius:Float,
                             rocks:[SphereAsteroid556],
                             playerPositions:[Vec2],
                             playerRadius:Float) -> Int? {
        var hit:Int?=nil
        var first:Float=2
        for i in rocks.indices {
            let delta=Sphere67.delta(target:rocks[i].position,origin:origin)
            let t=CombatCollision556.segmentHit(delta:delta,travel:travel,
                                                radius:rocks[i].radius+projectileRadius)
            if t<first {
                first=t
                hit=i
            }
        }
        guard let result=hit else {return nil}
        for ship in playerPositions {
            let t=CombatCollision556.segmentHit(
                delta:Sphere67.delta(target:ship,origin:origin),
                travel:travel,radius:projectileRadius+playerRadius)
            if t<first {return nil}
        }
        return result
    }

    // Physics68 ProjectileCover68 transfers 2.5% of the incoming shot
    // velocity into the rock's tangent plane, divided by rock mass.
    static func applyCoveredShot(_ rock:inout SphereAsteroid556,
                                 origin:Vec2,velocity:Vec2) {
        guard rock.mass>0 else {return}
        let converted=Sphere67.components(rock.position,Sphere67.transport(
            Sphere67.vector(origin,velocity),
            from:Sphere67.normal(origin),
            to:Sphere67.normal(rock.position)))
        rock.velocity=rock.velocity+converted*(0.025/rock.mass)
    }

    private static func radial(origin:Vec2,target:Vec2) -> (direction:Vec2,distance:Float) {
        let d=Sphere67.delta(target:target,origin:origin)
        let distance=sqrt(d.lengthSquared)
        return (distance>0.00001 ? d*(1/distance) : Vec2(x:1,y:0),distance)
    }
    private static func transported(origin:Vec2,target:Vec2,radial:Vec2) -> Vec2 {
        Sphere67.components(target,Sphere67.transport(
            Sphere67.vector(origin,radial),
            from:Sphere67.normal(origin),to:Sphere67.normal(target)))
    }

    /// Physics68.Explosion68 momentum; leaves hit points unchanged.
    /// Full bomb/flame damage and particle effects belong to the weapons
    /// module, not to this physics impulse operation.
    static func explosion(origin:Vec2,radius:Float,impulse:Float,
                          rocks:inout [SphereAsteroid556],
                          bugs:inout [CombatBody68],
                          pickups:inout [CombatBody68],
                          boss:inout CombatBody68?) {
        guard radius>0 && impulse>0 else {return}
        for i in rocks.indices {
            let r=radial(origin:origin,target:rocks[i].position)
            guard r.distance<radius && rocks[i].mass>0 else {continue}
            let d=transported(origin:origin,target:rocks[i].position,
                               radial:r.direction)
            rocks[i].velocity=rocks[i].velocity +
                d*(impulse*(1-r.distance/radius)/rocks[i].mass)
        }
        for i in bugs.indices {
            let r=radial(origin:origin,target:bugs[i].position)
            guard r.distance<radius else {continue}
            let d=transported(origin:origin,target:bugs[i].position,
                               radial:r.direction)
            bugs[i].velocity=bugs[i].velocity +
                d*(impulse*(1-r.distance/radius)/2)
        }
        for i in pickups.indices {
            let r=radial(origin:origin,target:pickups[i].position)
            guard r.distance<radius else {continue}
            let d=transported(origin:origin,target:pickups[i].position,
                               radial:r.direction)
            pickups[i].velocity=pickups[i].velocity +
                d*(impulse*(1-r.distance/radius))
        }
        if var target=boss {
            let r=radial(origin:origin,target:target.position)
            if r.distance<radius {
                let d=transported(origin:origin,target:target.position,
                                  radial:r.direction)
                target.velocity=target.velocity +
                    d*(impulse*(1-r.distance/radius)/80)
                boss=target
            }
        }
    }
}
