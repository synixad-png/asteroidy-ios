import Foundation

@main struct RockCombat556Tests {
    static func main() {
        var cases = 0
        for size in 1...3 {
            for tier in 0...4 {
                let hp = Rock.healthFor(size: size, tier: tier)
                let expected = tier == 0 ? 1 : size == 3 ? 1 + tier * 2 : size == 2 ? 1 + tier : 1 + (tier + 1) / 2
                precondition(hp == expected && Rock.radiusFor(size: size) > 0)
                cases += 1
            }
        }
        var g = GameCore()
        let sector = CombatBalance556(level: 13, difficulty: .normal, spherical: false)!
        g.setSectorTraining(sector, objective: .clear)
        precondition(g.rocks[0].tier == 4 && g.rocks[0].health == 9)
        let original = g.rocks.count
        g.rocks[0].at = Vec2(x: 0.9, y: 0.9)
        g.rocks[0].motion = Vec2(x: 0, y: 0)
        for i in 1..<g.rocks.count {
            g.rocks[i].at = Vec2(x: -1.1, y: -1.1)
            g.rocks[i].motion = Vec2(x: 0, y: 0)
        }
        for strike in 1...9 {
            g.bolts.append(Bolt(at: Vec2(x: 0.9, y: 0.9), motion: Vec2(x:0,y:0), life:1))
            g.tick(FlightCommand(),dt:1.0/120)
            if strike < 9 {
                precondition(g.rocks[0].health == 9-strike)
                precondition(g.rocks.count == original && g.score == 0)
            }
        }
        precondition(g.score == 20 + 8*30 + 4*10 && g.destroyedRocks == 1)
        precondition(g.rocks.count == original+1)
        precondition(g.rocks[original-1].size == 2 && g.rocks[original].size == 2)
        precondition(g.rocks[original-1].tier == 3 && g.rocks[original].tier == 3)
        precondition(g.rocks[original-1].health == 4)
        var easy = GameCore()
        easy.setSectorTraining(CombatBalance556(level:1,difficulty:.normal,spherical:false)!)
        precondition(easy.incomingRocksLeft == 0)
        easy.rocks.removeAll()
        easy.tick(FlightCommand(),dt:1.0/120)
        precondition(easy.rocks.isEmpty && easy.sectorCleared && easy.sectorFinished)
        var wave = GameCore()
        wave.setSectorTraining(CombatBalance556(level:7,difficulty:.normal,spherical:false)!,objective:.waves)
        precondition(wave.incomingRocksLeft == 3)
        let start = wave.rocks.count
        for _ in 0..<900 { wave.tick(FlightCommand(),dt:1.0/60) }
        precondition(wave.incomingRocksLeft == 3)
        for _ in 0..<65 { wave.tick(FlightCommand(),dt:1.0/60) }
        precondition(wave.incomingRocksLeft == 1 && wave.rocks.count >= start+2)
        wave.setSectorTraining(nil)
        precondition(wave.trainingBalance == nil && wave.rocks.count == 9 && wave.incomingRocksLeft == 0)
        print("PASS: 15 rock HP cases, nine pulse hits, splits/score, waves and arena restoration")
    }
}
