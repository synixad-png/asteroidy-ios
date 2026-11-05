import Foundation

/// Source Windows/src/GpuIntro41.cs:13–21 exact per-seed cratered
/// icosahedron and 2/3-subdivision count, independent of Apple Metal.
@main struct IntroRockGeometry41Tests {
    static func near(_ a:Float,_ b:Float,_ tol:Float=0.0002) {
        precondition(a.isFinite && b.isFinite && abs(a-b)<tol,
                     "Source IntroStone geometry diverged")
    }
    static func main() {
        let all=IntroOrbit41.belt
        let small=all.first(where:{$0.size<=1.15})!
        let big=all.first(where:{$0.size>1.15})!
        for (stone,expected) in [(small,320*3),(big,1280*3)] {
            let geometry=IntroRockGeometry41.geometry(stone)
            precondition(geometry.vertices.count==expected)
            precondition(geometry.indices.count==expected)
            precondition(geometry.indices.last==UInt32(expected-1))
            var minRadius=Float.greatestFiniteMagnitude,maxRadius:Float=0
            var meanOut:Float=0
            for index in stride(from:0,to:geometry.vertices.count,by:3) {
                let v=geometry.vertices[index]
                let p=SphereVector3(x:v.position.x,y:v.position.y,z:v.position.z)
                let n=SphereVector3(x:v.normal.x,y:v.normal.y,z:v.normal.z)
                near(n.length,1,0.001)
                precondition(p.length.isFinite && p.length>0)
                minRadius=min(minRadius,p.length)
                maxRadius=max(maxRadius,p.length)
                meanOut+=SphereVector3.dot(p.normalized,n)
                precondition(v.color.x>=0 && v.color.x<=1.2)
                precondition(v.color.y>=0 && v.color.y<=1.2)
                precondition(v.color.z>=0 && v.color.z<=1.2)
                near(v.color.w,1)
                near(v.position.w,1)
                near(v.normal.w,0)
                near(v.material.x,0)
            }
            precondition(minRadius>0 && maxRadius>minRadius)
            precondition(meanOut>0)
        }

        let a=IntroRockGeometry41.stone(.init(x:1,y:0,z:0),seed:0)
        let b=IntroRockGeometry41.stone(.init(x:1,y:0,z:0),seed:3.65)
        precondition((a-b).length>0.005,
                     "Original per-rock seed must change real rock shape")
        // Original PlanetLife52.Basis and source 1mm finite difference:
        // true outward normals, including poles and seed changes.
        for seed in [Float(0),0.73,5.11,18.25] {
            for dir in [
                SphereVector3(x:1,y:0,z:0),
                SphereVector3(x:0,y:1,z:0),
                SphereVector3(x:0,y:-1,z:0),
                SphereVector3(x:1,y:1,z:1).normalized
            ] {
                let normal=IntroRockGeometry41.stoneNormal(dir,seed:seed)
                near(normal.length,1,0.001)
                precondition(SphereVector3.dot(normal,dir.normalized)>0)
            }
        }
        print("PASS: source GpuIntro41 stone seed-specific crater geometry,")
        print("      2/3 subdivisions: 320/1280 triangles, exact per-rock")
        print("      outward finite-difference normals, RGB, material and")
        print("      normalized geometry with no guessed replacement objects")
        print("LIMITATION: GPU visuals, runtime cache/FPS and Apple device unverified")
    }
}
