import Foundation

/// A self-contained spherical combat *test sector* built from v556's rock
/// balance and Sphere67 geodesic motion. It does not unlock campaign missions,
/// simulate enemies/bosses, or replace the final planet mission controller.
struct SphereBolt556 {
    var position: Vec2
    var velocity: Vec2
    var life: Float
}

struct SphereSector556 {
    private(set) var asteroids: [SphereAsteroid556] = []
    private(set) var bolts: [SphereBolt556] = []
    private(set) var score = 0
    private(set) var destroyedRocks = 0
    private(set) var shipContacts = 0
    private(set) var hull = 3
    private(set) var hitCooldown: Float = 0
    private(set) var damageEvents = 0
    private var inContact = false
    private(set) var elapsed: Float = 0
    private(set) var incomingRocksLeft = 0
    private(set) var nextIncoming: Float = 0
    private(set) var objectiveWave = 1
    private(set) var sectorCleared = false
    let balance: CombatBalance556
    let objective: GameCore.TrainingObjective
    private var shotCooldown: Float = 0
    private var seed: UInt32 = 0x556A57E
    private var spawnSequence = 0
    private static let unit: Float = 2.7 / 1280

    var objectiveDuration: Float {
        switch objective {
        case .clear: return 0
        case .escort: return 40
        case .defend: return 50
        case .waves: return 48
        }
    }
    var objectiveTimerComplete: Bool { elapsed >= objectiveDuration }
    var sectorFinished: Bool {
        objectiveTimerComplete && incomingRocksLeft == 0 && asteroids.isEmpty
    }

    init(balance: CombatBalance556, diagnosticAsteroids: [SphereAsteroid556]? = nil) {
        self.balance = balance
        self.objective = GameCore.objectiveFor(level:balance.level)
        if let diagnosticAsteroids {
            asteroids = diagnosticAsteroids
            // Explicit fixtures represent a test with no scheduled arrivals.
            incomingRocksLeft = 0
        } else {
            var flat = GameCore()
            flat.setSectorTraining(balance)
            asteroids = flat.rocks.map { rock in
                let p = Vec2(x: 640 + rock.at.x / Self.unit,
                             y: 360 - rock.at.y / Self.unit)
                let v = Vec2(x: rock.motion.x / Self.unit,
                             y: -rock.motion.y / Self.unit) * 0.55
                return SphereAsteroid556(position:p, velocity:v,
                                         radius:rock.radius / Self.unit,
                                         size:rock.size,tier:rock.tier,health:rock.health)
            }
            incomingRocksLeft = flat.incomingRocksLeft
            nextIncoming = objective == .waves ? 16 : 12
        }
    }
    private mutating func random() -> Float {
        seed = seed &* 1664525 &+ 1013904223
        return Float(seed & 0x00FFFFFF) / Float(0x01000000)
    }
    private mutating func spawnArrivals(near player:Vec2) {
        guard incomingRocksLeft > 0 else { return }
        let n = min(2,incomingRocksLeft)
        incomingRocksLeft -= n
        for _ in 0..<n {
            let tier: Int
            if balance.level >= 13 { tier = 2 + Int(random() * 3) }
            else { tier = balance.level >= 10 ? 2 : balance.level >= 5 ? 1 : 0 }
            let side: Float = spawnSequence % 2 == 0 ? 20 : 1260
            spawnSequence += 1
            var candidate = Vec2(x:side,y:360)
            for _ in 0..<128 {
                candidate = Vec2(x:side,y:140 + random() * 520)
                if sqrt(Sphere67.delta(target:candidate,origin:player).lengthSquared) >= 260 { break }
            }
            let heading: Vec2
            if objective == .defend {
                let toTarget = Sphere67.delta(target:Vec2(x:640,y:420),origin:candidate)
                heading = toTarget * (1/max(0.0001,sqrt(toTarget.lengthSquared)))
            } else {
                let a = random() * 2 * Float.pi
                heading = Vec2(x:cos(a),y:sin(a))
            }
            let speed = SphereAsteroid556.incomingSpeed(baseRandomSpeed:60 + random()*40,dangerSpeed:1)
            let radius: Float = Rock.radiusFor(size:3) / Self.unit
            asteroids.append(SphereAsteroid556(position:candidate,velocity:heading*speed,
                                              radius:radius,size:3,tier:tier))
        }
        nextIncoming = elapsed + (objective == .waves ? 16 : 11)
    }

    private mutating func splitRock(_ parent:SphereAsteroid556) {
        guard parent.size > 1 else { return }
        let angle = atan2(parent.velocity.y,parent.velocity.x)
        let originalSpeed = sqrt(parent.velocity.lengthSquared)
        for side: Float in [-1,1] {
            let offsetAngle = angle + side * .pi/2
            let offset = Vec2(x:cos(offsetAngle),y:sin(offsetAngle)) * 8
            let childPosition = Sphere67.offset(parent.position,by:offset)
            let motionAngle = angle + side * 0.75
            let speed = min(175,originalSpeed * 1.17 + 9)
            let tier = max(0,parent.tier-1), size = parent.size-1
            let radius = (size == 2 ? 18 : 10) * 1.12 *
                         SphereAsteroid556.fragmentScale(parentSize:parent.size)
            asteroids.append(SphereAsteroid556(position:childPosition,
                                              velocity:Vec2(x:cos(motionAngle),y:sin(motionAngle))*speed,
                                              radius:radius,size:size,tier:tier,fragment:true))
        }
    }
    private mutating func terminalShards(_ parent:SphereAsteroid556) {
        guard asteroids.count <= 220 else { return }
        for i in 0..<18 {
            let a = 2*Float.pi*Float(i)/18 + random()*0.2-0.1
            let dir = Vec2(x:cos(a),y:sin(a))
            let pos = Sphere67.offset(parent.position,by:dir*(2 + random()*5))
            let speed = 42 + random()*73
            let radius = 10*1.12*(0.10+random()*0.13)
            let life = 1.3+random()*1.2
            asteroids.append(SphereAsteroid556(position:pos,
                                              velocity:parent.velocity+dir*speed,
                                              radius:radius,size:1,tier:0,
                                              health:1,fragment:true,shardLife:life))
        }
    }

    private mutating func damageRock(at index:Int) {
        guard asteroids.indices.contains(index) else { return }
        if asteroids[index].shardLife > 0 {
            asteroids.remove(at:index)
            return
        }
        asteroids[index].health -= 1
        guard asteroids[index].health <= 0 else { return }
        let rock = asteroids.remove(at:index)
        destroyedRocks += 1
        score += (rock.size == 3 ? 20 : rock.size == 2 ? 50 : 100) +
                 (rock.originalHealth-1)*30 + rock.tier*10
        if rock.size > 1 { splitRock(rock) }
        else { terminalShards(rock) }
    }

    /// Spherical aim is in the ship's own tangent plane; separate from flat
    /// arena controls. Shot radius and speed are explicit testbed values.
    mutating func fire(from player:Vec2, direction:Vec2) {
        guard shotCooldown <= 0 && direction.lengthSquared > 0.0001 && hull > 0 else { return }
        let d = direction * (1/sqrt(direction.lengthSquared))
        let start = Sphere67.offset(player,by:d*35)
        bolts.append(SphereBolt556(position:start,velocity:d*520,life:1.1))
        shotCooldown = 0.135
    }

    /// Moving geodesic collision: use the shortest arc at the beginning of
    /// the step and compare relative tangent velocities to avoid tunneling.
    /// The geometry is the Sphere67 local tangent approximation over <=1/60s.
    static func sweptBoltHit(start:Vec2,velocity:Vec2,rock:SphereAsteroid556,dt:Float) -> Bool {
        let separation = Sphere67.delta(target:rock.position,origin:start)
        let transported = Sphere67.transport(Sphere67.vector(rock.position,rock.velocity),
                                               from:Sphere67.normal(rock.position),
                                               to:Sphere67.normal(start))
        let localRockVelocity = Sphere67.components(start,transported)
        let relative = (velocity-localRockVelocity)*dt
        let radius = rock.radius + 7
        let a = relative.lengthSquared
        if separation.lengthSquared <= radius*radius { return true }
        if a <= 1e-9 { return false }
        let t = max(0,min(1,(separation.x*relative.x+separation.y*relative.y)/a))
        let distance = separation-relative*t
        return distance.lengthSquared <= radius*radius
    }

    mutating func tick(dt:Float,playerPosition:Vec2,playerRadius:Float=26,
                       detectContacts:Bool=true) {
        guard dt > 0 else { return }
        elapsed += dt
        hitCooldown = max(0,hitCooldown-dt)
        shotCooldown = max(0,shotCooldown-dt)
        if objective == .waves { objectiveWave = min(3,1+Int(elapsed/16)) }

        let previousRockPositions = asteroids.map { $0.position }
        for i in asteroids.indices { asteroids[i].advance(dt:dt) }
        // Process projectiles against the positions at the start of the step.
        var rockHits:[Int:Int] = [:]
        for i in bolts.indices.reversed() {
            if bolts[i].life <= 0 { bolts.remove(at:i); continue }
            var target:Int? = nil
            for j in asteroids.indices {
                var previous = asteroids[j]
                previous.position = previousRockPositions[j]
                if Self.sweptBoltHit(start:bolts[i].position,velocity:bolts[i].velocity,
                                    rock:previous,dt:dt) {
                    target = j
                    break
                }
            }
            if let target {
                rockHits[target,default:0] += 1
                bolts.remove(at:i)
            } else {
                bolts[i].position = Sphere67.advance(bolts[i].position,velocity:&bolts[i].velocity,dt:dt)
                bolts[i].life -= dt
                if bolts[i].life <= 0 { bolts.remove(at:i) }
            }
        }
        // Descending indices prevent removal from invalidating still-pending hits.
        for idx in rockHits.keys.sorted(by:>) {
            for _ in 0..<rockHits[idx]! {
                if asteroids.indices.contains(idx) { damageRock(at:idx) }
            }
        }
        // Shards are cosmetic and expire on their own; unlike threats, they
        // still block the diagnostic sector-clear condition until gone.
        for i in asteroids.indices.reversed() where asteroids[i].shardLife > 0 {
            asteroids[i].shardLife -= dt
            if asteroids[i].shardLife <= 0 { asteroids.remove(at:i) }
        }
        if incomingRocksLeft > 0 &&
           (elapsed >= nextIncoming || (objective != .waves && asteroids.count <= 4)) {
            spawnArrivals(near:playerPosition)
        }
        let overlap = detectContacts && asteroids.contains {
            $0.shardLife <= 0 && $0.touches(playerPosition,otherRadius:playerRadius)
        }
        if overlap && !inContact {
            shipContacts += 1
            if hitCooldown <= 0 && hull > 0 {
                hull -= 1
                damageEvents += 1
                hitCooldown = 1.3
            }
        }
        inContact = overlap
        if sectorFinished { sectorCleared = true }
    }
}
