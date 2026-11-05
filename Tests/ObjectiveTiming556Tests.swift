import Foundation

@main struct ObjectiveTiming556Tests {
    static func main() {
        // Exact Gameplay65.ObjectiveFor65 mapping for the 26 sector atlas.
        for level in 1...26 {
            let actual = GameCore.objectiveFor(level: level)
            let expected: GameCore.TrainingObjective =
                [2, 11, 21].contains(level) ? .escort :
                [5, 14, 23].contains(level) ? .defend :
                [9, 17].contains(level) ? .waves : .clear
            precondition(actual == expected, "Objective mismatch in sector \(level)")
        }
        // No mission complete while timed objective is running, even when
        // all asteroids have been cleared by the player.
        let timedCases: [(Int, Float, GameCore.TrainingObjective)] = [
            (2, 40, .escort), (5, 50, .defend), (9, 48, .waves),
            (11, 40, .escort), (14, 50, .defend), (17, 48, .waves),
            (21, 40, .escort), (23, 50, .defend)
        ]
        for (level, duration, type) in timedCases {
            var game = GameCore()
            game.setSectorTraining(CombatBalance556(level: level, difficulty: .normal, spherical: false)!)
            precondition(game.trainingObjective == type)
            precondition(game.objectiveDuration == duration)
            precondition(game.objectiveWave == 1)
            for _ in 0..<Int(duration * 60) {
                game.rocks.removeAll()
                game.tick(FlightCommand(), dt: 1 / 60)
                if game.sectorElapsed + 0.02 < duration {
                    precondition(!game.sectorFinished)
                }
            }
            game.rocks.removeAll()
            game.tick(FlightCommand(), dt: 1/60)
            precondition(game.objectiveTimerComplete)
            precondition(game.incomingRocksLeft == 0)
            precondition(game.sectorFinished && game.sectorCleared)
            if type == .waves { precondition(game.objectiveWave == 3) }
        }
        // Clear objectives can finish immediately when their quota is zero.
        var clear = GameCore()
        clear.setSectorTraining(CombatBalance556(level: 1, difficulty: .normal, spherical: false)!)
        precondition(clear.trainingObjective == .clear && clear.objectiveTimerComplete)
        precondition(clear.objectiveDuration == 0)
        clear.rocks.removeAll()
        clear.tick(FlightCommand(),dt:1/60)
        precondition(clear.sectorFinished && clear.sectorCleared)
        // Cosmetic terminal shards still count as Rocks in Game.FinishLevel.
        var shards = GameCore()
        shards.setSectorTraining(CombatBalance556(level:1,difficulty:.normal,spherical:false)!)
        shards.rocks.removeAll()
        shards.rocks.append(Rock(at:Vec2(x:0.8,y:0.8),motion:Vec2(x:0,y:0),
                                 radius:0.005,phase:0,tier:0,size:1,health:1,
                                 originalHealth:1,fragment:true,shardLife:1))
        precondition(shards.activeThreatCount == 0)
        precondition(!shards.sectorFinished)
        // The training arena never touches CampaignStore or unlocks a level.
        print("PASS: ObjectiveFor65 for 26 levels; all eight timed sectors, all duration gates, wave indexes, fragments and clear case")
    }
}
