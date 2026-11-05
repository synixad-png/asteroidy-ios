import Foundation

/// Original Windows/src/Intro41.cs (v568 reference) 16-second camera,
/// and Windows/src/OrbitWorld51.cs 820 legacy seeded belt placements.
/// Pure-source tests do not assert Metal rendering or a full mission.
@main struct IntroOrbit41Tests {
    static func near(_ a:Float,_ b:Float,_ epsilon:Float=0.001) {
        precondition(a.isFinite && b.isFinite && abs(a-b)<epsilon,
                     "Original IntroScene41 coordinate/parity mismatch")
    }
    static func near3(_ a:SphereVector3,_ b:SphereVector3,_ epsilon:Float=0.001) {
        near(a.x,b.x,epsilon);near(a.y,b.y,epsilon);near(a.z,b.z,epsilon)
    }
    static func main() {
        near(IntroOrbit41.duration,16)
        near(IntroOrbit41.approachStart,8.4)
        near(IntroOrbit41.arrivalTime,15.2)
        near(IntroOrbit41.introPlanetScale,0.24)
        near(IntroOrbit41.radiusNormalization,1/144.19674,
             0.0000001)
        near3(IntroOrbit41.planetCenter,
              .init(x:-38,y:4,z:-56))
        near3(IntroOrbit41.ship(0),.init(x:0,y:0,z:42))
        near3(IntroOrbit41.camera(0),.init(x:0,y:5,z:55))
        near3(IntroOrbit41.ship(8.4),
              .init(x:0,y:sin(8.4*0.6)*0.25,z:42-6.7*8.4),
              0.00001)
        near3(IntroOrbit41.ship(15.2),IntroOrbit41.arrivalPoint)
        near3(IntroOrbit41.ship(16),IntroOrbit41.arrivalPoint)

        // Independent first camera fixture from IntroScene41.View:
        // f=(0,-5,-13)/sqrt(194), right=(1,0,0), up=(0,13,-5)/sqrt(194)
        let f=IntroOrbit41.frame(0)
        let h:Float=sqrt(194)
        near3(f.eye,.init(x:0,y:5,z:55))
        near3(f.right,.init(x:1,y:0,z:0))
        near3(f.up,.init(x:0,y:13/h,z:-5/h))
        near3(f.back,.init(x:0,y:5/h,z:13/h))
        let m=f.viewColumnMajor
        precondition(m.count==16)
        near(m[0],1)
        near(m[4],0)
        near(m[8],0)
        near(m[12],0)
        near(m[14],(-5*5/h-13*55/h)*IntroOrbit41.radiusNormalization,
             0.00001)
        for t in stride(from:Float(0),through:16,by:0.2) {
            let frame=IntroOrbit41.frame(t)
            let origin=frame.cameraSpace(IntroOrbit41.ship(t))
            near(origin.x,0,0.00003)
            near(origin.y,0,0.00003)
            precondition(origin.z < 0)
            near(frame.right.length,1,0.0002)
            near(frame.up.length,1,0.0002)
            near(frame.back.length,1,0.0002)
            near(SphereVector3.dot(frame.right,frame.up),0,0.0002)
            // Source IntroScene41.View must drive the SAME basis into
            // original GpuIntro41 sky projections (deep planets/clouds,
            // black hole and the five rays), not sphere-combat camera.
            let sky=IntroOrbit41.skyCamera(time:t)
            near3(sky.focus,frame.back * -1,0.00001)
            near3(sky.right,frame.right,0.00001)
            near3(sky.up,frame.up,0.00001)
            near(SphereVector3.dot(sky.right,sky.focus),0,0.0002)
        }
        let belt=IntroOrbit41.belt
        precondition(belt.count==820)
        near(belt[0].seed,0)
        near(belt[1].seed,0.73)
        near(belt[819].seed,819*0.73,0.0001)
        for (i,s) in belt.enumerated() {
            precondition(s.size >= 0.22 && s.size < 1.97001)
            precondition(s.center.length.isFinite)
            precondition(s.seed.isFinite)
            near(s.seed,Float(i)*0.73,0.0002)
        }
        // Windows GpuIntro41.CinematicIntro41: whole belt rotates at
        // exactly time*0.2 degrees around the original planet center.
        near(IntroOrbit41.beltRotationDegrees(time:0),0)
        near(IntroOrbit41.beltRotationDegrees(time:10),2)
        near(IntroOrbit41.beltRotationDegrees(time:16),3.2)
        let reference=belt[0]
        near3(IntroOrbit41.beltWorldPosition(reference,time:0),
              IntroOrbit41.planetCenter+reference.center,0.00005)
        let theta=Float.pi*2/180
        let referenceAt10=IntroOrbit41.beltWorldPosition(reference,time:10)
        near(referenceAt10.x,
             IntroOrbit41.planetCenter.x+
             cos(theta)*reference.center.x+sin(theta)*reference.center.z,
             0.00005)
        near(referenceAt10.y,
             IntroOrbit41.planetCenter.y+reference.center.y,0.00005)
        near(referenceAt10.z,
             IntroOrbit41.planetCenter.z-
             sin(theta)*reference.center.x+cos(theta)*reference.center.z,
             0.00005)
        precondition((referenceAt10-reference.world).length>0.05)
        // Consistent camera-space culling must use the rotated center,
        // never the stationary original world position.
        for moment in [Float(0),4,8,12,16] {
            let frame=IntroOrbit41.frame(moment)
            for stone in belt.prefix(30) {
                let world=IntroOrbit41.beltWorldPosition(stone,time:moment)
                precondition((world-IntroOrbit41.planetCenter).length.isFinite)
                _ = IntroOrbit41.visible(stone,time:moment,in:frame)
            }
        }
        near(IntroOrbit41.planetRotationDegrees(level:1,time:0),29)
        near(IntroOrbit41.planetRotationDegrees(level:1,time:10),51)
        // The legacy flat arena and its physics do not appear in this pure scene.
        print("PASS: 16-second source v568 IntroScene41 ship/camera, original")
        print("      normalized world matrix, 820 seeded legacy asteroid coordinates,")
        print("      source planet scale, no invented campaign completion")
        print("LIMITATION: visual iOS Metal, actual NewHome290 terrain mode and")
        print("            original per-seed detailed rock meshes are not verified")
    }
}
