import Foundation

/// Windows v568 Physics68.cs:31-45 Contact68.
/// Independent two-body spherical-arc impulse/correction. All masses,
/// radii, positions and tangential velocities are PC world units.
/// Previous frozen SphereRockContact68 is unchanged by this adapter.
enum CarbonisBodyContact68 {
    struct Body {
        var position:Vec2
        var velocity:Vec2
        var mass:Float
        var radius:Float
    }

    static func transported(_ velocity:Vec2,from:Vec2,to:Vec2)->Vec2 {
        Sphere67.components(to,Sphere67.transport(
            Sphere67.vector(from,velocity),
            from:Sphere67.normal(from),to:Sphere67.normal(to)))
    }
    static func dot(_ a:Vec2,_ b:Vec2)->Float {
        a.x*b.x+a.y*b.y
    }

    /// Returns true for any overlap, even bodies already separating;
    /// this matches source C# (collision damage is gated by invulnerability).
    @discardableResult
    static func resolve(_ a:inout Body,_ b:inout Body,
                        restitution:Float) -> Bool {
        let sum=a.radius+b.radius
        if a.position.y>=0 && a.position.y<=Sphere67.height &&
           b.position.y>=0 && b.position.y<=Sphere67.height &&
           abs(a.position.y-b.position.y)>=sum {
            return false
        }
        let delta=Sphere67.delta(target:b.position,origin:a.position)
        let distance=sqrt(delta.lengthSquared)
        if distance>=sum {return false}
        let normal=distance>0.00001
            ? delta*(1/distance) : Vec2(x:1,y:0)
        var other=transported(b.velocity,from:b.position,to:a.position)
        var own=a.velocity
        let relative=other-own
        let closing=dot(relative,normal)
        let ia:Float=a.mass>0 ? 1/a.mass : 0
        let ib:Float=b.mass>0 ? 1/b.mass : 0
        let total=ia+ib
        if total<=0 {return false}
        if closing<0 {
            let impulse = -(1+restitution)*closing/total
            let tangent=Vec2(x:-normal.y,y:normal.x)
            let tangentSpeed=dot(relative,tangent)
            let friction=max(-impulse*0.12,
                             min(impulse*0.12,-tangentSpeed/total))
            let force=normal*impulse+tangent*friction
            own=own-force*ia
            other=other+force*ib
        }
        b.velocity=transported(other,from:a.position,to:b.position)
        let push=max(0,sum-distance-0.01)*0.92
        let oldA=a.position,oldB=b.position
        a.position=Sphere67.offset(a.position,
                                   by:normal*(-push*ia/total))
        b.position=Sphere67.offset(b.position,
            by:transported(normal,from:oldA,to:oldB)*(push*ib/total))
        a.velocity=transported(own,from:oldA,to:a.position)
        b.velocity=transported(b.velocity,from:oldB,to:b.position)
        return true
    }
}