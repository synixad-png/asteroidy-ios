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
        // A fresh simulation isolates contact transitions from the 1200-frame
        // movement test; the moving planet may cross the player earlier.
        var contacts = SphereSector556(balance: config)
        contacts.tick(dt:1/120,playerPosition:Vec2(x:0,y:360),playerRadius:1000)
        precondition(contacts.shipContacts == 1)
        precondition(contacts.hull == 2 && contacts.damageEvents == 1)
        for _ in 0..<120 { contacts.tick(dt:1/120,playerPosition:Vec2(x:0,y:360),playerRadius:1000) }
        precondition(contacts.shipContacts == 1 && contacts.hull == 2)
        // North pole is outside rock radii in this deterministic test seed.
        contacts.tick(dt:1/120,playerPosition:Vec2(x:0,y:0),playerRadius:0)
        precondition(contacts.shipContacts == 1)
        contacts.tick(dt:1/120,playerPosition:Vec2(x:0,y:360),playerRadius:1000)
        precondition(contacts.shipContacts == 2)
        precondition(contacts.hull == 2 && contacts.damageEvents == 1,
                     "Second contact within invulnerability must not damage")
        for _ in 0..<165 { contacts.tick(dt:1/120,playerPosition:Vec2(x:0,y:0),playerRadius:0) }
        precondition(contacts.hitCooldown == 0)
        contacts.tick(dt:1/120,playerPosition:Vec2(x:0,y:360),playerRadius:1000)
        precondition(contacts.shipContacts == 3)
        precondition(contacts.hull == 1 && contacts.damageEvents == 2)
        // Hold the contact longer than the cooldown: no repeated damage on a
        // continuous overlap; only a new entry can trigger another hit.
        for _ in 0..<200 { contacts.tick(dt:1/120,playerPosition:Vec2(x:0,y:360),playerRadius:1000) }
        precondition(contacts.hull == 1)
        contacts.tick(dt:1/120,playerPosition:Vec2(x:0,y:0),playerRadius:0)
        contacts.tick(dt:1/120,playerPosition:Vec2(x:0,y:360),playerRadius:1000)
        precondition(contacts.hull == 0 && contacts.damageEvents == 3)
        contacts.tick(dt:1/120,playerPosition:Vec2(x:0,y:0),playerRadius:0)
        for _ in 0..<200 { contacts.tick(dt:1/120,playerPosition:Vec2(x:0,y:0),playerRadius:0) }
        contacts.tick(dt:1/120,playerPosition:Vec2(x:0,y:360),playerRadius:1000)
        precondition(contacts.hull == 0 && contacts.damageEvents == 3)
        // Flat GameCore remains an independent sandbox with unchanged nine-rock baseline.
        let flat = GameCore()
        precondition(flat.rocks.count == 9)
        print("PASS: 1200 sphere frames, contact transitions, three-hit hull, cooldown, no repeat damage, and legacy flat arena")
    }
}
