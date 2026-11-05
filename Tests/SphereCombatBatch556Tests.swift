import Foundation

@main struct SphereCombatBatch556Tests {
    static func move(_ sector: inout SphereSector556, count:Int, player:Vec2) {
        for _ in 0..<count { sector.tick(dt:1/120,playerPosition:player,playerRadius:0,detectContacts:false) }
    }
    static func main() {
        let balance = CombatBalance556(level:1,difficulty:.normal,spherical:true)!
        let player=Vec2(x:600,y:360)
        let rock=SphereAsteroid556(position:Vec2(x:640,y:360),
                                   velocity:Vec2(x:0,y:0),radius:35,
                                   size:3,tier:2,health:5)
        var sector = SphereSector556(balance:balance,diagnosticAsteroids:[rock])
        precondition(sector.asteroids.count == 1 && sector.incomingRocksLeft == 0)
        for hit in 1...5 {
            move(&sector,count:19,player:player)
            sector.fire(from:player,direction:Vec2(x:1,y:0))
            sector.tick(dt:1/120,playerPosition:player,playerRadius:0,detectContacts:false)
            if hit < 5 {
                precondition(sector.asteroids.count == 1 && sector.asteroids[0].health == 5-hit)
                precondition(sector.score == 0 && sector.destroyedRocks == 0)
            }
        }
        precondition(sector.destroyedRocks == 1 && sector.score == 160,
                     "v556 size-3 armored hit scoring")
        precondition(sector.asteroids.count == 2)
        precondition(sector.asteroids.allSatisfy { $0.size == 2 && $0.tier == 1 &&
                     $0.health == balance.sphericalRockHealth(size:2,tier:1) &&
                     $0.originalHealth == Rock.healthFor(size:2,tier:1) })
        precondition(!sector.sectorFinished)

        var small = SphereSector556(balance:balance,diagnosticAsteroids:[
            SphereAsteroid556(position:Vec2(x:640,y:360),velocity:Vec2(x:0,y:0),
                              radius:15,size:1,tier:0,health:1)
        ])
        small.fire(from:player,direction:Vec2(x:1,y:0))
        small.tick(dt:1/120,playerPosition:player,playerRadius:0,detectContacts:false)
        precondition(small.destroyedRocks == 1 && small.score == 100)
        precondition(small.asteroids.count == 18)
        precondition(small.asteroids.allSatisfy { $0.shardLife > 0 })
        precondition(!small.sectorFinished)
        move(&small,count:390,player:player)
        precondition(small.asteroids.isEmpty && small.sectorFinished && small.sectorCleared)
        precondition(small.score == 100 && small.destroyedRocks == 1)

        // Projectile crosses the 1280->0 meridian and still hits geodesically.
        var seam = SphereSector556(balance:balance,diagnosticAsteroids:[
            SphereAsteroid556(position:Vec2(x:1,y:360),velocity:Vec2(x:0,y:0),
                              radius:18,size:1,tier:0,health:1)
        ])
        seam.fire(from:Vec2(x:1240,y:360),direction:Vec2(x:1,y:0))
        for _ in 0..<18 {
            seam.tick(dt:1/120,playerPosition:Vec2(x:1240,y:360),playerRadius:0,detectContacts:false)
        }
        precondition(seam.destroyedRocks == 1 && seam.score == 100,
                     "Meridian must not block shots")

        let waveBalance = CombatBalance556(level:9,difficulty:.normal,spherical:true)!
        var wave = SphereSector556(balance:waveBalance)
        precondition(wave.objective == .waves && wave.incomingRocksLeft == 3)
        precondition(wave.asteroids.count == waveBalance.sectorRockCount)
        move(&wave,count:1900,player:Vec2(x:320,y:360))
        precondition(wave.objectiveWave == 1 && wave.incomingRocksLeft == 3)
        move(&wave,count:40,player:Vec2(x:320,y:360))
        precondition(wave.objectiveWave == 2 && wave.incomingRocksLeft == 1)
        precondition(wave.asteroids.count == waveBalance.sectorRockCount+2)
        precondition(!wave.objectiveTimerComplete && !wave.sectorFinished)
        // Timed objective alone cannot clear a sector with surviving rocks.
        var timed = SphereSector556(balance:waveBalance,diagnosticAsteroids:[])
        precondition(timed.objective == .waves && !timed.sectorFinished)
        move(&timed,count:5800,player:Vec2(x:320,y:360))
        precondition(timed.objectiveWave == 3)
        precondition(timed.objectiveTimerComplete && timed.sectorFinished && timed.sectorCleared)
        var defended = SphereSector556(
            balance:CombatBalance556(level:5,difficulty:.normal,spherical:true)!,
            diagnosticAsteroids:[SphereAsteroid556(position:Vec2(x:640,y:360),
                                velocity:Vec2(x:0,y:0),radius:12,size:1,tier:0)])
        move(&defended,count:6200,player:Vec2(x:320,y:360))
        precondition(defended.objectiveTimerComplete && !defended.sectorFinished)
        precondition(!defended.sectorCleared && defended.asteroids.count == 1)
        for level in 1...26 {
            for d in CombatBalance556.Difficulty.allCases {
                let cfg=CombatBalance556(level:level,difficulty:d,spherical:true)!
                let sample=SphereSector556(balance:cfg)
                precondition(sample.asteroids.count == cfg.sectorRockCount)
                precondition(sample.objective == GameCore.objectiveFor(level:level))
            }
        }
        print("PASS: spherical armor, splits, shards, scoring, seam bullets, waves, timed sector-clear gates and 78 configurations")
    }
}
