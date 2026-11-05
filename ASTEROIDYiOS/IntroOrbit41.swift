import Foundation

/// Source-coordinate timeline from real Windows/src/Intro41.cs:50–81 and
/// Windows/src/GpuIntro41.cs:490–493 (ASTEROIDY PC reference).
/// Pure Swift: reproducible tests on Linux, no UIKit/Metal dependency.
/// This is a visual scene only; it does NOT start or complete missions.
enum IntroOrbit41 {
    typealias V = SphereVector3
    static let duration: Float = 16
    static let approachStart: Float = 8.4
    static let arrivalTime: Float = 15.2
    static let arrivalRadius: Float = 34
    static let planetCenter = V(x:-38,y:4,z:-56)
    static let arrivalNormal = V(x:0.62,y:0.18,z:0.765).normalized
    static let arrivalPoint = planetCenter + arrivalNormal * arrivalRadius

    // GpuPlanetGltf463.MissionPlanetScale523(24): the real outside
    // radius of the v556 port is 100*1.4419674, so the same factor
    // 1.4419674 cancels and the rendered 24-unit scene radius is .24.
    static let radiusNormalization: Float = 1/(100*1.4419674)
    static let introPlanetScale: Float = 24/100

    private static func clamped(_ value:Float,_ low:Float,_ high:Float)->Float {
        min(high,max(low,value))
    }
    static func smooth(_ t:Float)->Float {
        let q=clamped(t,0,1)
        return q*q*(3-2*q)
    }
    static func orbitalShip(_ time:Float)->V {
        V(x:0,y:sin(time*0.6)*0.25,z:42-6.7*time)
    }
    static func ship(_ t:Float)->V {
        let t=clamped(t,0,duration)
        if t<=approachStart { return orbitalShip(t) }
        let u=min(1,(t-approachStart)/(arrivalTime-approachStart))
        let v=1-u
        let a=orbitalShip(approachStart)
        let b=a+V(x:0,y:0.15,z:-6.7*(arrivalTime-approachStart)/3)
        let c=arrivalPoint+arrivalNormal*5
        return a*(v*v*v) + b*(3*v*v*u) + c*(3*v*u*u) + arrivalPoint*(u*u*u)
    }
    static func forward(_ t:Float)->V {
        if t>=arrivalTime-0.02 { return arrivalNormal * -1 }
        return (ship(t+0.02)-ship(max(0,t-0.02))).normalized
    }
    static func camera(_ t:Float)->V {
        let phase=smooth(t/approachStart)
        let yaw=phase*Float.pi*2
        let distance:Float=13+7*sin(phase*Float.pi)
        let height:Float=5+7*sin(phase*Float.pi)
        let orbit=V(x:sin(yaw)*distance,y:height,z:cos(yaw)*distance)
        let blend=smooth((t-approachStart)/2.4)
        let up=(ship(t)-planetCenter).normalized
        let follow=forward(t)*(-11)+up*4
        return ship(t)+orbit*(1-blend)+follow*blend
    }
    // Windows/src/Intro41.cs:77–80 — craft orientation with local
    // X=right, local Y=forward, local Z=up (the source 3D mesh convention).
    static func craftOrientationColumns(_ time:Float)->[Float] {
        let f=forward(time)
        let r=V.cross(f,V(x:0,y:1,z:0)).normalized
        let u=V.cross(r,f).normalized
        return [
            r.x,r.y,r.z,0,
            f.x,f.y,f.z,0,
            u.x,u.y,u.z,0,
            0,0,0,1
        ]
    }
    struct Frame {
        let eye: V
        let right: V
        let up: V
        let back: V
        // Exactly the source IntroScene41.View(eye, ship, introView)
        // column-major frame, but using the SAME normalized units as
        // the Boreas and Vanguard meshes in the Metal renderer.
        var viewColumnMajor: [Float] {
            let f=back * -1
            let k=IntroOrbit41.radiusNormalization
            return [
                right.x,up.x,back.x,0,
                right.y,up.y,back.y,0,
                right.z,up.z,back.z,0,
                -V.dot(right,eye)*k,-V.dot(up,eye)*k,V.dot(f,eye)*k,1
            ]
        }
        var eyeNormalized: V { eye * IntroOrbit41.radiusNormalization }
        func cameraSpace(_ world:V)->V {
            let d=world-eye
            return V(x:V.dot(right,d),y:V.dot(up,d),z:V.dot(back,d))
        }
    }
    // Windows GpuIntro41.IntroSky / SkyProject55 projects the same
    // sky directions against IntroScene41.View(eye,ship), not the
    // separate spherical-combat camera. Reuse the existing source
    // projections/textures by supplying exact live intro axes.
    static func skyCamera(time:Float)->SphereCamera67 {
        let basis=frame(time)
        var camera=SphereCamera67(at:Vec2(x:0,y:360))
        camera.focus=basis.back * -1
        camera.right=basis.right
        camera.up=basis.up
        return camera
    }

    static func frame(_ time:Float)->Frame {
        let eye=camera(time)
        let f=(ship(time)-eye).normalized
        let r=V.cross(f,V(x:0,y:1,z:0)).normalized
        let u=V.cross(r,f)
        return Frame(eye:eye,right:r,up:u,back:f * -1)
    }

    // Windows/src/OrbitWorld51.cs:3–10, historical seeded .NET
    // subtractive Random. This reproduces the source LEGACY belt
    // (NewHome290.Enabled changes terrain placement in v568; that
    // branch must be ported separately using the actual terrain).
    struct Stone {
        let center: V // local to planetCenter, original PC world units
        let size: Float
        let seed: Float
        var world: V { center+IntroOrbit41.planetCenter }
    }
    private struct DotNetRandom {
        private let mbig=2147483647
        private var values = [Int](repeating:0,count:56)
        private var inext=0
        private var inextp=21
        init(seed:Int) {
            let mj0=161803398-abs(seed)
            var mj=mj0
            values[55]=mj
            var mk=1
            for i in 1...54 {
                let ii=(21*i)%55
                values[ii]=mk
                mk=mj-mk
                if mk<0 {mk+=mbig}
                mj=values[ii]
            }
            for _ in 0..<4 {
                for i in 1...55 {
                    values[i] -= values[1+(i+30)%55]
                    if values[i]<0 {values[i]+=mbig}
                }
            }
        }
        mutating func nextDouble()->Double {
            inext += 1
            if inext>=56 {inext=1}
            inextp += 1
            if inextp>=56 {inextp=1}
            var ret=values[inext]-values[inextp]
            if ret==mbig {ret -= 1}
            if ret<0 {ret += mbig}
            values[inext]=ret
            return Double(ret)/Double(mbig)
        }
    }

    static let beltStoneCount=820

    // OrbitWorld51.BuildBelt51 evaluates the SAME 81 source samples
    // for every stone and every reposition attempt. Cache just those
    // camera/ship segments once: still the exact C# coordinates,
    // with far fewer first-frame trigonometric operations on iOS.
    static let corridorSamples:[(eye:V,line:V)] = (0...80).map { sample in
        let time=Float(sample)*0.2
        let eye=camera(time)
        return (eye,ship(time)-eye)
    }
    static let belt: [Stone] = {
        var rng=DotNetRandom(seed:4109)
        var rocks:[Stone]=[]
        rocks.reserveCapacity(beltStoneCount)
        for i in 0..<beltStoneCount {
            let angle=Float(i)*2.399963
            let radius:Float=52+Float(rng.nextDouble())*16
            let y:Float=(Float(rng.nextDouble())-0.5)*8
            var origin=V(x:cos(angle)*radius,y:y,z:sin(angle)*radius)
            let world=origin+planetCenter
            if abs(world.x)<3.6 && abs(world.y)<3 && world.z > -42 && world.z < 24 {
                origin.y += (world.y < 0 ? -1 : 1)*6
            }
            let randomSize=rng.nextDouble()
            let size:Float=0.22+Float(randomSize*randomSize*randomSize)*1.75
            let seed=Float(i)*0.73
            // Keep the source camera's flight corridor empty, exactly as
            // OrbitWorld51.BuildBelt51 does over 81 samples, four attempts.
            for _ in 0..<4 {
                var blocked=false
                for (eye,line) in corridorSamples {
                    let point=origin+planetCenter-eye
                    let projection=clamped(V.dot(point,line)/max(0.001,V.dot(line,line)),0,1)
                    if (point-line*projection).length<size+3.2 {
                        blocked=true
                        break
                    }
                }
                if !blocked {break}
                origin.y += (i%2==0 ? 1 : -1)*(8+size)
            }
            rocks.append(Stone(center:origin,size:size,seed:seed))
        }
        return rocks
    }()
    // Windows/src/GpuIntro41.cs:491: the source belt is local to
    // PlanetCenter and rotates with shipRotate(time*.2f,0,1,0).
    // Rotate the COMPLETE rock, not its origin alone; the matching
    // GPU model matrix is T(PlanetCenter) * Ry(degrees) * T(local).
    static func beltRotationDegrees(time:Float)->Float { time*0.2 }

    static func rotatedLocalBeltPosition(_ local:V,time:Float)->V {
        let angle=beltRotationDegrees(time:time)*Float.pi/180
        let cosine=cos(angle),sine=sin(angle)
        // Matches OpenGL's positive right-handed Y rotation.
        return V(x:cosine*local.x+sine*local.z,
                 y:local.y,
                 z:-sine*local.x+cosine*local.z)
    }

    static func beltWorldPosition(_ rock:Stone,time:Float)->V {
        planetCenter+rotatedLocalBeltPosition(rock.center,time:time)
    }

    // Original CinematicIntro41 draws the whole belt without an
    // orbital-only MultiDrawIntro135 frustum optimization. Mobile
    // culling here is deliberately conservative (expanded bounds)
    // and MUST use the same animated world position as the GPU.
    static func visible(_ rock:Stone,time:Float,in f:Frame)->Bool {
        let p=f.cameraSpace(beltWorldPosition(rock,time:time))
        let depth = -p.z
        let radius=rock.size*1.9+1
        if depth+radius<0.4 || depth-radius>1600 {return false}
        let limit=max(depth,0.4)+radius
        return abs(p.x)<=limit*0.888889+radius &&
               abs(p.y)<=limit*0.5+radius
    }
    // GpuPlanet.PlanetRotation(level, t, true) in v568.
    static func planetRotationDegrees(level:Int,time:Float)->Float {
        Float(level)*29+time*2.2
    }
}
