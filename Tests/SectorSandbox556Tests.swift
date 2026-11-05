import Foundation
@main struct SectorSandbox556Tests {
    static func main() {
        var game = GameCore()
        precondition(game.rocks.count == 9 && game.trainingBalance == nil)
        for level in 1...26 {
            for difficulty in CombatBalance556.Difficulty.allCases {
                guard let config = CombatBalance556(level: level, difficulty: difficulty, spherical: false) else { fatalError() }
                game.setSectorTraining(config)
                precondition(game.targetRockCount == config.sectorRockCount)
                precondition(game.rocks.count == config.sectorRockCount)
                for i in 0..<config.sectorRockCount { precondition(game.rocks[i].tier == config.tier(at: i)) }
                for _ in 0..<30 { game.tick(FlightCommand(turn:0.45,throttle:0.2,fire:true),dt:1.0/120) }
                precondition(game.rocks.count == config.sectorRockCount)
                precondition(game.trainingBalance?.level == level)
            }
        }
        game.setSectorTraining(nil)
        precondition(game.rocks.count == 9 && game.targetRockCount == 9 && game.trainingBalance == nil)
        print("PASS: 78 sector-training configurations, tier assignment and legacy arena restoration")
    }
}
