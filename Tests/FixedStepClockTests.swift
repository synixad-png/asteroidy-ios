import Foundation
@main struct RunClockTests {
  static func main() {
    var slow = FixedStepClock(), fast = FixedStepClock()
    var g60 = GameCore(), g120 = GameCore()
    let input = FlightCommand(turn:0.35,throttle:0.8,fire:true)
    let dt = Float(1.0 / 120.0)
    for _ in 0..<600 { slow.advance(elapsed:1.0/60.0) { g60.tick(input,dt:dt) } }
    for _ in 0..<1200 { fast.advance(elapsed:1.0/120.0) { g120.tick(input,dt:dt) } }
    precondition(slow.stepsTotal == 1200 && fast.stepsTotal == 1200)
    precondition(g60.ship == g120.ship && g60.score == g120.score && g60.hull == g120.hull)
    var stalled = FixedStepClock()
    var ticks = 0
    stalled.advance(elapsed:100) { ticks += 1 }
    precondition(ticks == 8, "Unbounded catch-up")
    stalled.advance(elapsed:Double.nan) { ticks += 1 }
    precondition(ticks == 8, "Non-finite clock input")
    print("PASS: 60/120 Hz identical 1200 physics steps, catch-up bound, NaN guard")
  }
}
