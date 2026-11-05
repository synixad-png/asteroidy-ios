import Foundation
@main struct IncomingRocks556Tests {
    static func main() {
        // Game.Action38: a Defend sector with a 5-rock quota immediately
        // admits two reinforcements when the arena is nearly empty.
        var defend = GameCore()
        defend.setSectorTraining(CombatBalance556(level: 5, difficulty: .normal, spherical: false)!)
        precondition(defend.trainingObjective == .defend)
        precondition(defend.incomingRocksLeft == 5)
        defend.rocks.removeAll()
        defend.tick(FlightCommand(), dt: 1/60)
        precondition(defend.rocks.count == 2 && defend.incomingRocksLeft == 3)
        let first = defend.rocks[0]
        let second = defend.rocks[1]
        let xBoundary: Float = (640 - 20) * 2.7 / 1280
        precondition(abs(first.at.x + xBoundary) < 0.01)
        precondition(abs(second.at.x - xBoundary) < 0.01)
        for rock in [first, second] {
            let delta = Vec2(x:0,y:-60 * 2.7 / 1280) - rock.at
            let dot = rock.motion.x * delta.x + rock.motion.y * delta.y
            precondition(dot > 0, "Defend asteroid must move toward objective")
            precondition((rock.at - defend.ship).lengthSquared >= pow(260 * 2.7 / 1280, 2))
        }
        // The 16-second wave timer has priority over the low-asteroid trigger.
        var waves = GameCore()
        waves.setSectorTraining(CombatBalance556(level: 9, difficulty:.normal,spherical:false)!)
        precondition(waves.trainingObjective == .waves)
        let startingQuota = waves.incomingRocksLeft
        waves.rocks.removeAll()
        for _ in 0..<600 { waves.tick(FlightCommand(), dt:1/60) }
        precondition(waves.incomingRocksLeft == startingQuota)
        for _ in 0..<380 { waves.tick(FlightCommand(), dt:1/60) }
        precondition(waves.incomingRocksLeft < startingQuota)
        precondition(waves.objectiveWave == 2)
        print("PASS: alternate spawn sides, 260px ship clearance, defend homing, and timed wave priority")
    }
}
