import Foundation

@main struct FlatEscort556Tests {
    static func approx(_ a: Float, _ b: Float, eps: Float = 0.00025) {
        precondition(abs(a - b) <= eps, "Expected \(b), got \(a)")
    }
    static func main() {
        // Gameplay65.StepObjective65 original flat course:
        // P=(180+920*t, 530-310*t+sin(PI*t)*45), t in [0,1].
        let scale: Float = 2.7 / 1280
        let points: [(Float, Float, Float)] = [(0,180,530),(10,410,530-77.5+sin(.pi/4)*45),
                                                        (20,640,420),(30,870,530-232.5+sin(3 * .pi/4)*45),
                                                        (40,1100,220),(80,1100,220)]
        for (seconds, x, y) in points {
            let p = GameCore.escortPosition(at: seconds)
            approx(p.x, (x-640)*scale)
            approx(p.y, (360-y)*scale)
        }
        var escort = GameCore()
        escort.setSectorTraining(CombatBalance556(level:2,difficulty:.normal,spherical:false)!)
        precondition(escort.trainingObjective == .escort)
        approx(escort.objectivePosition.x, (180-640)*scale)
        for _ in 0..<1200 { escort.tick(FlightCommand(),dt:1/60) }
        approx(escort.objectivePosition.x, 0, eps:0.001)
        approx(escort.objectivePosition.y, (360-420)*scale, eps:0.001)
        // Action38.StepAction uses Rocks.Count, not "active threats" excluding
        // fragments, to decide whether to force an immediate reinforcement.
        var count = GameCore()
        count.setSectorTraining(CombatBalance556(level:2,difficulty:.normal,spherical:false)!)
        precondition(count.incomingRocksLeft == 3)
        count.rocks.removeAll()
        for _ in 0..<5 {
            count.rocks.append(Rock(at:Vec2(x:1,y:1),motion:Vec2(x:0,y:0),radius:0.001,
                                    phase:0,tier:0,size:1,health:1,originalHealth:1,
                                    fragment:true,shardLife:90))
        }
        precondition(count.activeThreatCount == 0 && count.rocks.count == 5)
        count.tick(FlightCommand(),dt:1/60)
        precondition(count.incomingRocksLeft == 3 && count.rocks.count == 5,
                     "No early spawn with five cosmetic Rocks in original game")
        count.rocks.removeLast()
        count.tick(FlightCommand(),dt:1/60)
        precondition(count.incomingRocksLeft == 1 && count.rocks.count == 6,
                     "Arrival starts once total Rocks.Count drops to four")
        print("PASS: original escort 0/10/20/30/40/80s coordinates and raw Rocks.Count arrival gating")
    }
}
