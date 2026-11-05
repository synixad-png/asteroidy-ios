import Foundation
@main struct RunTests {
    static func main() {
        var g = GameCore()
        precondition(g.rocks.count == 9 && g.hull == 3)
        let initial = g.ship
        for _ in 0..<120 { g.tick(FlightCommand(throttle: 1, fire: true), dt: 1.0 / 60) }
        precondition(g.ship != initial)
        precondition(g.bolts.count <= 9)
        precondition(g.rocks.count == 9)
        precondition(g.hull >= 1 && g.hull <= 3)
        for _ in 0..<3000 { g.tick(FlightCommand(turn: 0.7, throttle: 0.9, fire: true), dt: 1.0 / 60) }
        precondition(g.rocks.count == 9 && g.bolts.count < 20)
        print("PASS: 3120 fixed-step updates, motion, shooting, rock replenishment, hull invariants")
    }
}
