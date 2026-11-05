import Foundation
@main struct RunCombat556 {
    static func main() {
        func p(_ x:Float,_ y:Float) -> Vec2 { Vec2(x:x,y:y) }
        let z=p(0,0)
        let t=CombatCollision556.segmentHit(delta:p(1,0),travel:p(2,0),radius:0.1)
        precondition(abs(t-0.45)<0.000001,"Exact quadratic hit fraction")
        precondition(CombatCollision556.segmentHit(delta:p(0,0),travel:p(1,0),radius:0.1)==0,"Origin inside obstacle")
        precondition(CombatCollision556.segmentHit(delta:p(1,1),travel:p(2,0),radius:0.1)==2,"Miss sentinel")
        precondition(CombatCollision556.segmentHit(delta:p(1,0),travel:z,radius:0.1)==2,"Static miss")
        let seam=CombatCollision556.firstPeriodicHit(from:p(1.32,0),to:p(1.38,0),rockFrom:p(-1.32,0),rockTo:p(-1.32,0),radius:0.07,extent:1.35)
        precondition(seam>=0 && seam<=1,"Periodic boundary hit")
        let moving=CombatCollision556.firstPeriodicHit(from:p(-1,0),to:p(1,0),rockFrom:p(0.5,0),rockTo:p(-0.5,0),radius:0.04,extent:1.35)
        precondition(moving<=1,"Moving target hit")
        print("PASS: v556 SegmentHit68 quadratic, hit-time ordering, moving rock, periodic seam")
    }
}
