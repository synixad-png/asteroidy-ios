import Foundation

@main struct SphereSector556Tests {
    static func main() {
        let config = CombatBalance556(level: 1, difficulty: .normal, spherical: true)!
        var sector = SphereSector556(balance: config)
        precondition(sector.asteroids.count == config.sectorRockCount)
        precondition(sector.shipContacts == 0 && sector.elapsed == 0)
        let initial = sector.asteroids.map { $0.position }
        let speeds = sector.asteroids.map { sqrt($0.velocity.lengthSquared) }
        for _ in 0..<1200 {
            sector.tick(dt:1/120,playerPosition:Vec2(x:0,y:360),playerRadius:0)
        }
        precondition(abs(sector.elapsed - 10) < 0.001)
        precondition(sector.asteroids.count == initial.count)
        var moved = 0
        for (i, rock) in sector.asteroids.enumerated() {
            let speed = sqrt(rock.velocity.lengthSquared)
            precondition(abs(speed-speeds[i]) < 0.03, "Sphere tangent speed drift")
            if sqrt(Sphere67.delta(target:rock.position,origin:initial[i]).lengthSquared) > 1 { moved += 1 }
            precondition(rock.position.x >= 0 && rock.position.x < 1280)
            precondition(rock.position.y >= 0 && rock.position.y <= 720)
        }
        precondition(moved == initial.count)
        // One contact event per entry, never 120 events per second.
        sector.tick(dt:1/120,playerPosition:Vec2(x:0,y:360),playerRadius:1000)
        precondition(sector.shipContacts == 1)
        for _ in 0..<120 { sector.tick(dt:1/120,playerPosition:Vec2(x:0,y:360),playerRadius:1000) }
        precondition(sector.shipContacts == 1)
        sector.tick(dt:1/120,playerPosition:Vec2(x:0,y:360),playerRadius:0)
        sector.tick(dt:1/120,playerPosition:Vec2(x:0,y:360),playerRadius:1000)
        precondition(sector.shipContacts == 2)
        // Flat GameCore remains an independent sandbox with unchanged nine-rock baseline.
        let flat = GameCore()
        precondition(flat.rocks.count == 9)
        print("PASS: spherical sector asteroid count, 1200 frames, tangent speed, movement, contact de-bounce and legacy flat arena")
    }
}
