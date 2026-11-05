import Foundation

/// Regression of Windows/src/GpuShip.cs:19–63, true v491 engine
/// exhaust. The GPU code separately duplicates these equations:
/// this test is an independent CPU oracle, not a rendered device test.
@main struct IntroEnginePlasma491Tests {
    typealias V=SphereVector3
    static func near(_ a:Float,_ b:Float,_ tolerance:Float=0.00002) {
        precondition(a.isFinite && b.isFinite && abs(a-b)<tolerance,
                     "Source v491 engine plasma numerical mismatch")
    }
    static func main() {
        let fx=IntroEnginePlasma491.self
        precondition(fx.engineCenters.count==2)
        precondition(fx.vertexCount==2*3*3*16*6)
        precondition(fx.vertexCount==1728)
        near(fx.visualSize,1.06)
        // Real two sockets from 4311 mesh header, NOT guessed
        // from model boundaries or the obsolete v490 flat wedges.
        let one=fx.engineCenters[0],two=fx.engineCenters[1]
        near(one.x,-0.44299396872520447,0.0000001)
        near(one.y,-1.5887130498886108,0.0000001)
        near(one.z,-0.1674797236919403,0.0000001)
        near(two.x,0.44578471779823303,0.0000001)
        near(two.y,-1.5894304513931274,0.0000001)
        near(two.z,-0.18300314247608185,0.0000001)

        // GpuShip: power=1 => length=0.17+1.47=1.64 units.
        // Outer 3D sheets at root: +/-1.06*0.12 = +/-0.1272.
        let rootPlus=fx.vertex(id:0,time:0)
        let rootMinus=fx.vertex(id:1,time:0)
        near(rootPlus.position.x,one.x+0.1272)
        near(rootMinus.position.x,one.x-0.1272)
        near(rootPlus.position.y,one.y)
        near(rootPlus.position.z,one.z)
        near(rootPlus.color.x,1)
        near(rootPlus.color.y,0.27)
        near(rootPlus.color.z,0.035)
        near(rootPlus.color.w,0.21*0.83)

        // Each source quad is six vertices in C# painter order:
        // [u0+,u0-,u1+, u1+,u0-,u1-].
        let nextRoot=fx.vertex(id:4,time:0)
        near(nextRoot.position.x,rootMinus.position.x)
        near(nextRoot.position.y,rootMinus.position.y)
        let tip=fx.vertex(id:16*6-1,time:0)
        near(tip.position.y,one.y-1.64)
        near(tip.color.w,0)
        // Warm-white core and secondary orange layer at root.
        let middle=fx.vertex(id:3*16*6,time:0)
        let core=fx.vertex(id:2*3*16*6,time:0)
        near(middle.color.y,0.65)
        near(core.color.y,0.96)
        near(core.color.z,0.49)
        near(core.color.w,0.82*0.83)
        // Independent second engine at the exact compiled mesh socket.
        let second=fx.vertex(id:3*3*16*6,time:0)
        near(second.position.x,two.x+0.1272)
        near(second.position.y,two.y)
        near(second.position.z,two.z)

        // Flight animation: the exhaust root stays fixed and the
        // traveling sine waves affect only its downstream geometry.
        for t in [Float(0),0.5,3,8.4,15.2,16] {
            let first=fx.vertex(id:0,time:t)
            near(first.position.x,one.x+0.1272*(1+0.11*sin(-t*21)))
            near(first.position.y,one.y)
            for id in stride(from:0,to:fx.vertexCount,by:7) {
                let v=fx.vertex(id:id,time:t)
                precondition(v.position.x.isFinite && v.position.y.isFinite)
                precondition(v.position.z.isFinite)
                precondition(v.color.x>=0 && v.color.x<=1)
                precondition(v.color.y>=0 && v.color.y<=1)
                precondition(v.color.z>=0 && v.color.z<=1)
                precondition(v.color.w>=0 && v.color.w<=0.82)
            }
        }
        // Idle and full throttle retain different source plume lengths.
        let idle=fx.vertex(id:16*6-1,time:1,power:0)
        let thrust=fx.vertex(id:16*6-1,time:1,power:1)
        near(idle.position.y,one.y-0.17)
        near(thrust.position.y,one.y-1.64)
        print("PASS: exact v491 dual-engine 1728 triangle vertices,")
        print("      actual source mesh nozzle origins, warm/ember colours,")
        print("      three layers/planes, 16 dynamic segments, additive alpha")
        print("LIMIT: Metal GPU vertex parity and native iPhone/iPad unverified")
    }
}
