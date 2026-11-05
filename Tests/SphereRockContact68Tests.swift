import Foundation
@main struct SphereRockContact68Tests {
    static func near(_ a:Float,_ b:Float,_ t:Float=0.20) {
        precondition(abs(a-b)<t,"Expected \(b) got \(a)")
    }
    static func main() {
        let aPos=Vec2(x:1279,y:360)
        let bPos=Vec2(x:1,y:360)
        var a=SphereAsteroid556(position:aPos,velocity:Vec2(x:50,y:0),
                                radius:18,size:3,tier:0)
        var b=SphereAsteroid556(position:bPos,velocity:Vec2(x:-50,y:0),
                                radius:18,size:3,tier:0)
        near(a.mass,8,0.001)
        near(SphereAsteroid556(position:aPos,velocity:Vec2(x:0,y:0),
                               radius:10,size:2).mass,4,0.001)
        near(SphereAsteroid556(position:aPos,velocity:Vec2(x:0,y:0),
                               radius:10,size:1,shardLife:1.5).mass,0.09,0.001)
        precondition(SphereRockContact68.resolve(&a,&b))
        let separation = sqrt(Sphere67.delta(target:b.position,origin:a.position).lengthSquared)
        precondition(separation > 30 && separation < 36.1)
        precondition(a.velocity.x < 0 && b.velocity.x > 0)
        near(a.velocity.x,-31,0.4)
        near(b.velocity.x,31,0.4)
        let av=sqrt(a.velocity.lengthSquared)
        let bv=sqrt(b.velocity.lengthSquared)
        precondition(av.isFinite && bv.isFinite)

        let far=SphereAsteroid556(position:Vec2(x:640,y:360),
                                 velocity:Vec2(x:0,y:0),radius:5)
        let nearA=SphereAsteroid556(position:aPos,velocity:Vec2(x:0,y:0),radius:18)
        let nearB=SphereAsteroid556(position:bPos,velocity:Vec2(x:0,y:0),radius:18)
        var group=[nearA,nearB,far]
        precondition(SphereRockContact68.solve(&group)==1)
        precondition(Sphere67.delta(target:group[1].position,origin:group[0].position).lengthSquared > 30*30)
        precondition(group[2].position == far.position)
        precondition(SphereRockContact68.solve(&group) <= 1)
        var distant=[far,SphereAsteroid556(position:Vec2(x:0,y:360),
                                          velocity:Vec2(x:0,y:0),radius:8)]
        precondition(SphereRockContact68.solve(&distant)==0)
        print("PASS: source Physics68 masses, geodesic seam impulse, restitution .62, displacement, 216-cell pair broadphase")
    }
}
