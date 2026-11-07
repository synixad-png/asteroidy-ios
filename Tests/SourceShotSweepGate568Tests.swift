import Foundation

/// Pure CPU property test of the *unchanged* Windows Combat69 swept-hit
/// oracle versus the iOS 568 conservative geodesic gate. The gate may
/// accept extra candidates but MUST NEVER discard any original hit.
@main struct SourceShotSweepGate568Tests {
    static func main() {
        var state:UInt32=0x69e568
        func sample()->Float {
            state=state &* 1664525 &+ 1013904223
            return Float(state & 0x00ffffff)/16777216
        }
        func point()->Vec2 {
            Vec2(x:1280*sample(),y:720*sample())
        }
        var originalHits=0
        var rejected=0
        var candidates=0
        var polarCases=0
        var seamCases=0
        for iteration in 0..<45000 {
            let a=point()
            let velocity=Vec2(x:(sample()-0.5)*2200,
                              y:(sample()-0.5)*2200)
            let shot=CarbonisCombat568.Projectile(
                point:a,velocity:velocity,life:1,
                hostile:false,kind:0)
            let dt:Float=1/120
            let near=iteration%3==0
            // 1/3 of targets are chosen along the actual source swept
            // arc, including high latitudes/pole reflection.
            let b=near ? Sphere67.offset(
                a,by:velocity*(dt*sample())+
                    Vec2(x:(sample()-0.5)*22,
                         y:(sample()-0.5)*22)) : point()
            let target=iteration%5==0
                ? Sphere67.canonical(Vec2(x:b.x+1280,y:b.y)) : b
            let radius:Float=iteration%7==0 ? 16.7 :
                iteration%7==1 ? 2 : 7+sample()*55
            let gate=CarbonisCombat568.ShotSweepGate568(
                shot:shot,dt:dt)
            let quick=gate.mayReach(target,radius:radius)
            let original=CarbonisCombat568.projectedHit71(
                shot,target:target,radius:radius,dt:dt)
            if original != nil {
                originalHits+=1
                precondition(quick,
                    "geodesic gate dropped true source shot collision")
            }
            if !quick {rejected+=1}
            candidates+=1
            if a.y<26 || a.y>694 {polarCases+=1}
            if a.x<35 || a.x>1245 {seamCases+=1}
        }
        precondition(originalHits>7500,"insufficient positive collision proof")
        precondition(rejected>20000,"broadphase skipped no expensive candidates")
        // Additional exact border/pole checks with different wraps.
        for i in 0..<2000 {
            let origin=Vec2(x:i%2==0 ? 1279.8 : 0.2,
                            y:i%3==0 ? 0.05 : 719.95)
            let velocity=Vec2(x:(sample()-0.5)*900,
                              y:(sample()-0.5)*900)
            let shot=CarbonisCombat568.Projectile(
                point:origin,velocity:velocity,life:1,
                hostile:false,kind:2)
            let target=Sphere67.offset(
                origin,by:velocity*(Float(1)/120*sample()))
            let gate=CarbonisCombat568.ShotSweepGate568(
                shot:shot,dt:1/120)
            precondition(gate.mayReach(target,radius:4),
                         "polar/seam source shot wrongfully culled")
        }
        print("PASS 47,000 original source projectile hit gates and polar/seam checks")
        print("Original hits preserved:",originalHits,
              "broadphase discarded:",rejected,"of",candidates,
              "candidate rock/shooter checks")
        print("LIMIT: Linux source simulation is not iPhone/iPad FPS telemetry")
    }
}
