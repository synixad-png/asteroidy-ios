import Foundation
@main struct SphereAsteroids556Tests {
    static func close(_ a: Float, _ b: Float, tol: Float = 0.015) {
        precondition(abs(a-b) <= tol, "Unexpected: \(a) != \(b)")
    }
    static func main() {
        let p=Vec2(x:1277,y:370)
        var rock=SphereAsteroid556(position:p,velocity:Vec2(x:120,y:12),radius:20)
        let firstSpeed=sqrt(rock.velocity.lengthSquared)
        let step: Float=1.0/120
        var traveled: Float=0
        for _ in 0..<1200 {
            let previous=rock.position
            rock.advance(dt:step)
            traveled += sqrt(Sphere67.delta(target:rock.position,origin:previous).lengthSquared)
            close(sqrt(rock.velocity.lengthSquared),firstSpeed,tol:0.04)
            precondition(rock.position.x >= 0 && rock.position.x < 1280)
            precondition(rock.position.y >= 0 && rock.position.y <= 720)
        }
        close(traveled,firstSpeed*10,tol:0.6)
        var seam=SphereAsteroid556(position:Vec2(x:1279,y:360),velocity:Vec2(x:0,y:0),radius:10)
        precondition(seam.surfaceDistance(to:Vec2(x:1,y:360)) < 3)
        precondition(seam.touches(Vec2(x:1,y:360),otherRadius:1))
        seam.advance(dt:1/60)
        close(seam.position.x,1279,tol:0.001)
        var pole=SphereAsteroid556(position:Vec2(x:400,y:3),velocity:Vec2(x:0,y:-90),radius:10)
        for _ in 0..<240 { pole.advance(dt:1/120) }
        precondition(pole.position.x >= 0 && pole.position.x < 1280)
        precondition(pole.position.y >= 0 && pole.position.y <= 720)
        close(SphereAsteroid556.startingSpeed(baseRandomSpeed:48,level:1,tier:0,dangerSpeed:1),26.4,tol:0.001)
        close(SphereAsteroid556.startingSpeed(baseRandomSpeed:78,level:26,tier:3,dangerSpeed:1),(78+18*3.2)*0.88*0.55,tol:0.003)
        close(SphereAsteroid556.incomingSpeed(baseRandomSpeed:100,dangerSpeed:1.25),68.75,tol:0.001)
        close(SphereAsteroid556.fragmentScale(parentSize:3),0.49,tol:0.0001)
        close(SphereAsteroid556.fragmentScale(parentSize:2),0.39,tol:0.0001)
        print("PASS: 1200 spherical asteroid frames, tangent-speed conservation, geodesic seam/pole tests, v556 speed and fragment multipliers")
    }
}
