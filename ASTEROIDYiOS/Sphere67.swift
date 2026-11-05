import Foundation

// Adaptation of Windows/src/SphereCombat67.cs (ASTEROIDY v556).
// Coordinate units: original world W=1280, H=720, sphere radius=H/pi.
// No UIKit/Metal dependencies; can be regression-tested on Linux.
struct SphereVector3: Equatable {
    var x: Float; var y: Float; var z: Float
    static func +(a: Self, b: Self) -> Self { .init(x:a.x+b.x,y:a.y+b.y,z:a.z+b.z) }
    static func -(a: Self, b: Self) -> Self { .init(x:a.x-b.x,y:a.y-b.y,z:a.z-b.z) }
    static func *(a: Self, b: Float) -> Self { .init(x:a.x*b,y:a.y*b,z:a.z*b) }
    static func /(a: Self, b: Float) -> Self { a * (1/b) }
    static func dot(_ a: Self, _ b: Self) -> Float { a.x*b.x+a.y*b.y+a.z*b.z }
    static func cross(_ a: Self, _ b: Self) -> Self { .init(x:a.y*b.z-a.z*b.y,y:a.z*b.x-a.x*b.z,z:a.x*b.y-a.y*b.x) }
    var length: Float { sqrt(Self.dot(self,self)) }
    var normalized: Self { let n=length; return n > 1e-12 ? self/n : .init(x:0,y:0,z:0) }
}

// Surface coordinates are the same 1280x720 coordinates as the C# game.
enum Sphere67 {
    static let width: Float = 1280
    static let height: Float = 720
    static let radius: Float = height / .pi
    private static func mod(_ x: Float, _ n: Float) -> Float { (x.truncatingRemainder(dividingBy:n)+n).truncatingRemainder(dividingBy:n) }

    static func canonical(_ p: Vec2) -> Vec2 {
        // Pole reflection translates longitude by half a revolution.
        var y=mod(p.y,2*height), x=p.x
        if y > height { y=2*height-y; x += width/2 }
        return Vec2(x:mod(x,width),y:y)
    }
    static func normal(_ point: Vec2) -> SphereVector3 {
        let p=canonical(point)
        let lon=p.x*2*Float.pi/width, lat=Float.pi/2-p.y*Float.pi/height, c=cos(lat)
        return .init(x:c*cos(lon),y:sin(lat),z:c*sin(lon))
    }
    static func coordinates(_ input: SphereVector3) -> Vec2 {
        let n=input.normalized
        let longitude=atan2(n.z,n.x)
        let latitude=atan2(n.y,sqrt(n.x*n.x+n.z*n.z))
        return canonical(Vec2(x:longitude*width/(2*Float.pi),y:(Float.pi/2-latitude)*radius))
    }
    static func basis(_ point: Vec2) -> (east: SphereVector3, south: SphereVector3) {
        let p=canonical(point); let lon=p.x*2*Float.pi/width
        let east=SphereVector3(x:-sin(lon),y:0,z:cos(lon))
        return (east,SphereVector3.cross(normal(p),east).normalized)
    }
    static func vector(_ point: Vec2, _ components: Vec2) -> SphereVector3 {
        let b=basis(point)
        return b.east*components.x+b.south*components.y
    }
    static func components(_ point: Vec2, _ v: SphereVector3) -> Vec2 {
        let b=basis(point)
        return Vec2(x:SphereVector3.dot(v,b.east),y:SphereVector3.dot(v,b.south))
    }
    // Rodrigues rotation takes a tangent vector from one normal to another.
    static func transport(_ v: SphereVector3, from: SphereVector3, to: SphereVector3) -> SphereVector3 {
        let axis=SphereVector3.cross(from,to), length=axis.length
        if length < 1e-6 { return v-to*SphereVector3.dot(v,to) }
        let unit=axis/length, theta=atan2(length,SphereVector3.dot(from,to))
        return v*cos(theta)+SphereVector3.cross(unit,v)*sin(theta)+unit*(SphereVector3.dot(unit,v)*(1-cos(theta)))
    }
    static func offset(_ origin: Vec2, by displacement: Vec2) -> Vec2 {
        let length=sqrt(displacement.lengthSquared)
        if length < 1e-6 { return canonical(origin) }
        let n=normal(origin),t=vector(origin,displacement)/length,angle=length/radius
        return coordinates(n*cos(angle)+t*sin(angle))
    }
    // Log map: shortest arc and direction measured in the origin's tangent plane.
    static func delta(target: Vec2, origin: Vec2) -> Vec2 {
        let a=normal(target),b=normal(origin),dot=max(-1,min(1,SphereVector3.dot(a,b)))
        let tangent=a-b*dot, len=tangent.length
        if len < 1e-6 { return dot>0 ? Vec2(x:0,y:0) : Vec2(x:Float.pi*radius,y:0) }
        let distance=atan2(len,dot)*radius
        return components(origin,tangent*(distance/len))
    }
    static func advance(_ point: Vec2, velocity: inout Vec2, dt: Float) -> Vec2 {
        let destination=offset(point,by:velocity*dt)
        let speed=sqrt(velocity.lengthSquared)
        if speed > 1e-6 {
            let moved=transport(vector(point,velocity),from:normal(point),to:normal(destination))
            velocity=components(destination,moved)
            let newSpeed=sqrt(velocity.lengthSquared)
            if newSpeed > 1e-6 { velocity=velocity*(speed/newSpeed) }
        }
        return destination
    }
}

struct SphereCamera67 {
    var focus: SphereVector3
    var right: SphereVector3
    var up: SphereVector3
    init(at point: Vec2) {
        let basis=Sphere67.basis(point)
        focus=Sphere67.normal(point)
        right=basis.east
        up=SphereVector3.cross(focus,right).normalized
    }
    mutating func update(target: Vec2, dt: Float) {
        let desired=Sphere67.normal(target)
        let alpha=1-exp(-max(0,dt)*9)
        let previous=focus
        let blended=previous*(1-alpha)+desired*alpha
        focus=blended.length > 0.00001 ? blended.normalized : desired
        right=Sphere67.transport(right,from:previous,to:focus).normalized
        up=SphereVector3.cross(focus,right).normalized
    }
    func screenVector(at point: Vec2, screen: Vec2) -> Vec2 {
        let local=Sphere67.normal(point)
        let r=Sphere67.transport(right,from:focus,to:local)
        let down=Sphere67.transport(up * -1,from:focus,to:local)
        return Sphere67.components(point,r*screen.x+down*screen.y)
    }
}

// Independent v556 spherical flight testbed. Do not replace GameCore until
// platform render projection and v556 combat units have been calibrated.
struct SphereFlight67 {
    var position=Vec2(x:640,y:360)
    var velocity=Vec2(x:0,y:0)
    var heading: Float=0
    var flight=FlightDynamics556()
    var camera=SphereCamera67(at:Vec2(x:640,y:360))
    mutating func tick(move: Vec2, aim: Vec2, dt: Float) {
        guard dt > 0 else { return }
        let inputLength=min(1,sqrt(move.lengthSquared))
        let localMove=camera.screenVector(at:position,screen:move)
        let desired=localMove * (inputLength > 0 ? flight.configuration.cruiseSpeed/max(1e-6,sqrt(localMove.lengthSquared)) : 0)
        let acceleration=flight.motion(velocity:&velocity,desired:desired,inputLength:inputLength,dt:dt)
        let old=position
        let oldHeading=Vec2(x:cos(heading),y:sin(heading))
        let headingWorld=Sphere67.vector(old,oldHeading)
        position=Sphere67.advance(position,velocity:&velocity,dt:dt)
        let movedHeading=Sphere67.components(position,Sphere67.transport(headingWorld,from:Sphere67.normal(old),to:Sphere67.normal(position)))
        heading=atan2(movedHeading.y,movedHeading.x)
        camera.update(target:position,dt:dt)
        let direction=aim.lengthSquared > 0.0225 ? camera.screenVector(at:position,screen:aim) : inputLength > 0.01 ? camera.screenVector(at:position,screen:move) : Vec2(x:cos(heading),y:sin(heading))
        if direction.lengthSquared > 0.0001 { heading=atan2(direction.y,direction.x) }
        flight.attitude(angle:heading,velocity:velocity,acceleration:acceleration,dt:dt)
    }
}
