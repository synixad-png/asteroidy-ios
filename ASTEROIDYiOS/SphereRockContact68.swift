import Foundation

/// Source-faithful rigid contact response for two spherical Rocks
/// (Windows/src/Physics68.cs Contact68, restitution .62 for rock pairs).
/// Positions and velocities are atlas-space geodesic coordinates.
enum SphereRockContact68 {
    static func transported(_ velocity:Vec2, from:Vec2, to:Vec2) -> Vec2 {
        Sphere67.components(to,Sphere67.transport(
            Sphere67.vector(from,velocity),
            from:Sphere67.normal(from),to:Sphere67.normal(to)))
    }
    @discardableResult
    static func resolve(_ a:inout SphereAsteroid556,
                        _ b:inout SphereAsteroid556,
                        restitution:Float = 0.62) -> Bool {
        let sum = a.radius+b.radius
        if abs(a.position.y-b.position.y) >= sum { return false }
        let d = Sphere67.delta(target:b.position,origin:a.position)
        let distance = sqrt(d.lengthSquared)
        if distance >= sum { return false }
        let n = distance > 0.00001 ? d*(1/distance) : Vec2(x:1,y:0)
        var other = transported(b.velocity,from:b.position,to:a.position)
        var own = a.velocity
        let relative = other-own
        let closing = relative.x*n.x+relative.y*n.y
        let ia:Float = a.mass > 0 ? 1/a.mass : 0
        let ib:Float = b.mass > 0 ? 1/b.mass : 0
        let total = ia+ib
        guard total > 0 else { return false }
        var contactFriction:Float = 0
        if closing < 0 {
            let impulse = -(1+restitution)*closing/total
            let tangent = Vec2(x:-n.y,y:n.x)
            let tangentSpeed = relative.x*tangent.x+relative.y*tangent.y
            let friction = max(-impulse*0.12,min(impulse*0.12,-tangentSpeed/total))
            contactFriction = friction
            let direction = n*impulse+tangent*friction
            own = own-direction*ia
            other = other+direction*ib
        }
        let oldA=a.position,oldB=b.position
        b.velocity = transported(other,from:oldA,to:oldB)
        let push = max(0,sum-distance-0.01)*0.92
        a.position = Sphere67.offset(oldA,by:n*(-push*ia/total))
        b.position = Sphere67.offset(oldB,by:
            transported(n,from:oldA,to:oldB)*(push*ib/total))
        a.velocity = transported(own,from:oldA,to:a.position)
        b.velocity = transported(b.velocity,from:oldB,to:b.position)
        // RockContacts68 transfers the tangential contact friction into spin.
        if a.mass > 0 && a.radius > 0 {
            a.spin = max(-2,min(2,a.spin-contactFriction/(0.4*a.mass*a.radius)))
        }
        if b.mass > 0 && b.radius > 0 {
            b.spin = max(-2,min(2,b.spin-contactFriction/(0.4*b.mass*b.radius)))
        }
        return true
    }

    static func cell(_ position:Vec2) -> (Int,Int,Int) {
        let n=Sphere67.normal(position)
        func coord(_ v:Float)->Int {
            max(0,min(5,Int((v*Sphere67.radius+Sphere67.radius)/80)))
        }
        return (coord(n.x),coord(n.y),coord(n.z))
    }
    /// 6x6x6 broadphase from Physics68.RockContacts68, checks local cells.
    static func solve(_ rocks:inout [SphereAsteroid556]) -> Int {
        guard rocks.count > 1 else { return 0 }
        var cells = Array(repeating:[Int](),count:216)
        var normals:[SphereVector3] = []
        normals.reserveCapacity(rocks.count)
        for i in rocks.indices {
            let n=Sphere67.normal(rocks[i].position)
            normals.append(n)
            let (x,y,z)=cell(rocks[i].position)
            cells[x+y*6+z*36].append(i)
        }
        var contacts=0
        for i in rocks.indices {
            let (x,y,z)=cell(rocks[i].position)
            for zz in max(0,z-1)...min(5,z+1) {
                for yy in max(0,y-1)...min(5,y+1) {
                    for xx in max(0,x-1)...min(5,x+1) {
                        for j in cells[xx+yy*6+zz*36] where j > i {
                            let bound = (rocks[i].radius+rocks[j].radius)/Sphere67.radius
                            if SphereVector3.dot(normals[i],normals[j]) < 1-bound*bound*0.5 {
                                continue
                            }
                            var a=rocks[i],b=rocks[j]
                            if resolve(&a,&b) {
                                rocks[i]=a
                                rocks[j]=b
                                normals[i]=Sphere67.normal(a.position)
                                normals[j]=Sphere67.normal(b.position)
                                contacts += 1
                            }
                        }
                    }
                }
            }
        }
        return contacts
    }
}
