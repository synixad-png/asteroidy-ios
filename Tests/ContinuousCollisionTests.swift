import Foundation
@main struct RunContinuousTests {
    static func main() {
        let z = Vec2(x:0,y:0)
        func p(_ x:Float,_ y:Float) -> Vec2 { .init(x:x,y:y) }
        precondition(GameCore.sweptHit(from:p(-1,0),to:p(1,0),rockFrom:z,rockTo:z,radius:0.05,extent:1.35),"Crossing hit missed")
        precondition(!GameCore.sweptHit(from:p(-1,0.2),to:p(1,0.2),rockFrom:z,rockTo:z,radius:0.05,extent:1.35),"False hit")
        precondition(GameCore.sweptHit(from:p(1.32,0),to:p(1.38,0),rockFrom:p(-1.32,0),rockTo:p(-1.32,0),radius:0.07,extent:1.35),"Seam hit missed")
        precondition(GameCore.sweptHit(from:p(-1,0),to:p(1,0),rockFrom:p(0.5,0),rockTo:p(-0.5,0),radius:0.04,extent:1.35),"Moving target missed")
        precondition(!GameCore.sweptHit(from:p(-0.3,0.4),to:p(0.3,0.4),rockFrom:z,rockTo:z,radius:0.1,extent:1.35),"Distant collision")
        var a = GameCore(), b = GameCore()
        let cmd = FlightCommand(turn:0.42,throttle:0.9,fire:true)
        for _ in 0..<12000 { a.tick(cmd,dt:1.0/120); b.tick(cmd,dt:1.0/120) }
        precondition(a.ship == b.ship && a.score == b.score && a.hull == b.hull,"Non-deterministic replay")
        precondition(a.rocks.count == 9 && a.bolts.count < 30,"Unbounded entities")
        print("PASS: swept crossing, seam, moving target, no false positives, 12000-step deterministic replay")
    }
}
