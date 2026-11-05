import Foundation

// Diagnostic bridge between the verified v556 flat sector configuration and
// Sphere67 surface movement. Not an implementation of original planet missions.
struct SphereSector556 {
    private(set) var asteroids: [SphereAsteroid556] = []
    private(set) var shipContacts = 0
    private var inContact = false
    private(set) var elapsed: Float = 0
    private static let unit: Float = 2.7 / 1280

    init(balance: CombatBalance556) {
        var flat = GameCore()
        flat.setSectorTraining(balance)
        asteroids = flat.rocks.map { rock in
            let speedScale: Float = 0.55
            let p = Vec2(x: 640 + rock.at.x / Self.unit,
                         y: 360 - rock.at.y / Self.unit)
            let v = Vec2(x: rock.motion.x / Self.unit,
                         y: -rock.motion.y / Self.unit) * speedScale
            return SphereAsteroid556(position: p, velocity: v,
                                     radius: rock.radius / Self.unit)
        }
    }

    // The player position comes from real SphereFlight67, not the flat arena.
    // Contact is reported only on entry to the collision region, avoiding
    // artificially accumulating damage every 120-Hz frame.
    mutating func tick(dt: Float, playerPosition: Vec2, playerRadius: Float = 26) {
        guard dt > 0 else { return }
        elapsed += dt
        for i in asteroids.indices { asteroids[i].advance(dt: dt) }
        let anyContact = asteroids.contains { $0.touches(playerPosition, otherRadius: playerRadius) }
        if anyContact && !inContact { shipContacts += 1 }
        inContact = anyContact
    }
}
