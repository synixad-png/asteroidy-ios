import Foundation

@main struct SectorSpawn556Tests {
    static func main() {
        let unit: Float = 2.7 / 1280
        var cases = 0
        for level in 1...26 {
            for difficulty in CombatBalance556.Difficulty.allCases {
                guard let balance = CombatBalance556(level: level, difficulty: difficulty, spherical: false) else { fatalError() }
                var game = GameCore()
                game.setSectorTraining(balance)
                precondition(game.rocks.count == balance.sectorRockCount)
                for (i, rock) in game.rocks.enumerated() {
                    precondition(rock.size == 3 && rock.tier == balance.tier(at: i)!)
                    precondition((rock.at - game.ship).lengthSquared >= pow(260 * unit, 2))
                    precondition(abs(rock.at.x) <= 640 * unit && abs(rock.at.y) <= 360 * unit)
                    let speed = sqrt(rock.motion.lengthSquared) / unit
                    let baseMin: Float = 48 + Float(min(level-1, 18)) * 3.2
                    let baseMax: Float = 78 + Float(min(level-1, 18)) * 3.2
                    let armorModifier: Float = rock.tier >= 2 ? 0.88 : 1
                    precondition(speed >= baseMin * armorModifier - 0.005)
                    precondition(speed <= baseMax * armorModifier + 0.005)
                }
                cases += 1
            }
        }
        // Ensure the old demonstration arena has its original deterministic
        // nine-rock initial spawn and remains identical across instances.
        let one = GameCore()
        let two = GameCore()
        precondition(one.rocks.count == 9 && two.rocks.count == 9)
        for i in 0..<9 {
            precondition(one.rocks[i].at == two.rocks[i].at)
            precondition(one.rocks[i].motion == two.rocks[i].motion)
            precondition(one.rocks[i].radius == two.rocks[i].radius)
            precondition(one.rocks[i].phase == two.rocks[i].phase)
        }
        print("PASS: \(cases) original flat sector spawn cases, initial rock speed and 260px safety radius; legacy arena deterministic")
    }
}
