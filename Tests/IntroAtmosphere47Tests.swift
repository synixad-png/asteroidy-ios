import Foundation

/// Numerically checks the actual Windows GpuPlanet.AtmosphereVertex
/// and DrawAtmosphere47 24x96 source dome, not a screen-space halo.
/// No Apple GPU / simulator is available in this Swift/Linux test.
@main struct IntroAtmosphere47Tests {
    static func near(_ x:Float,_ y:Float,_ tol:Float=0.0001) {
        precondition(x.isFinite && y.isFinite && abs(x-y)<=tol,
                     "Source atmosphere mismatch")
    }
    static func nearV(_ x:SphereVector3,_ y:SphereVector3,
                      _ tolerance:Float=0.0001) {
        near(x.x,y.x,tolerance)
        near(x.y,y.y,tolerance)
        near(x.z,y.z,tolerance)
    }
    static func main() {
        near(IntroAtmosphere47.outerRadius,1.34)
        precondition(IntroAtmosphere47.rings==24)
        precondition(IntroAtmosphere47.segments==96)
        near(IntroAtmosphere47.red,149/255)
        near(IntroAtmosphere47.green,219/255)
        near(IntroAtmosphere47.blue,1)
        let dome=IntroAtmosphere47.geometry()
        precondition(dome.vertices.count==24*96*6)
        precondition(dome.indices.count==dome.vertices.count)
        precondition(dome.indices.last==UInt32(dome.vertices.count-1))
        near(IntroAtmosphere47.haze(radius:0),0.058,0.0001)
        near(IntroAtmosphere47.haze(radius:1.055),0.388,0.0001)
        near(IntroAtmosphere47.haze(radius:1.34),0)
        nearV(IntroAtmosphere47.point(radius:0,angle:0),
              .init(x:0,y:0,z:1.34))
        nearV(IntroAtmosphere47.point(radius:1.34,angle:0),
              .init(x:1.34,y:0,z:0))
        let first=dome.vertices[0]
        near(first.position.x,0)
        near(first.position.y,0)
        near(first.position.z,1.34)
        near(first.color.x,149/255)
        near(first.color.y,219/255)
        near(first.color.z,1)
        near(first.color.w,IntroAtmosphere47.haze(radius:0))
        let second=dome.vertices[1]
        near(second.position.x,1.34/24)
        near(second.position.y,0)
        let third=dome.vertices[2]
        near(third.position.x,(1.34/24)*cos(Float.pi/48))
        near(third.position.y,(1.34/24)*sin(Float.pi/48))
        let last=dome.vertices.last!
        near(last.color.w,IntroAtmosphere47.haze(
            radius:Float(23)*1.34/24),0.0002)

        for eye in [
            SphereVector3(x:0,y:0,z:1),
            SphereVector3(x:0,y:1,z:0),
            SphereVector3(x:0,y:-1,z:0),
            SphereVector3(x:0.71,y:0.16,z:0.55)
        ] {
            let basis=IntroAtmosphere47.basis(
                center:SphereVector3(x:0,y:0,z:0),eye:eye)
            near(basis.x.length,1)
            near(basis.y.length,1)
            near(basis.z.length,1)
            near(SphereVector3.dot(basis.x,basis.y),0)
            near(SphereVector3.dot(basis.y,basis.z),0)
            near(SphereVector3.dot(basis.x,basis.z),0)
            nearV(SphereVector3.cross(basis.x,basis.y),basis.z)
        }
        print("PASS: actual GpuPlanet.cs 24x96 translucent dome,")
        print("      full original 13,824 RGBA vertices and source haze profile,")
        print("      Boreas level-5 #95DBFF tint, robust eye-facing 3D basis")
        print("LIMIT: source geometry verified; Metal depth blending and FPS untested")
    }
}
