import Foundation

// Isolated iOS prototype. Flight exponential response adapted from v556 FlightDynamics298.
struct Vec2: Equatable {
    var x: Float
    var y: Float
    static func +(a: Self, b: Self) -> Self { .init(x: a.x + b.x, y: a.y + b.y) }
    static func -(a: Self, b: Self) -> Self { .init(x: a.x - b.x, y: a.y - b.y) }
    static func *(a: Self, n: Float) -> Self { .init(x: a.x * n, y: a.y * n) }
    var lengthSquared: Float { x * x + y * y }
}

struct FlightCommand { var turn: Float = 0; var throttle: Float = 0; var fire = false }
struct Rock {
    var at: Vec2
    var motion: Vec2
    var radius: Float
    var phase: Float
    var tier: Int = 0
    var size: Int = 3
    var health: Int = 1
    var originalHealth: Int = 1
    var fragment = false
    var shardLife: Float = 0
    static func healthFor(size: Int, tier: Int) -> Int {
        if tier == 0 { return 1 }
        if size == 3 { return 1 + tier * 2 }
        if size == 2 { return 1 + tier }
        return 1 + (tier + 1) / 2
    }
    static func radiusFor(size: Int, scale: Float = 1) -> Float {
        let pixels: Float = size == 3 ? 31 : size == 2 ? 18 : 10
        return pixels * 1.12 * (2.7 / 1280) * scale
    }
}
struct Bolt { var at: Vec2; var motion: Vec2; var life: Float }

struct GameCore {
    var ship = Vec2(x: 0, y: 0)
    var velocity = Vec2(x: 0, y: 0)
    var flight = FlightDynamics556()
    var angle: Float = 0
    var rocks: [Rock] = []
    var bolts: [Bolt] = []
    var score = 0
    var hull = 3
    var time: Float = 0
    private var shotTimer: Float = 0
    private var hitTimer: Float = 0
    private var seed: UInt32 = 0x556A57E
    let extent: Float = 1.35
    private(set) var trainingBalance: CombatBalance556? = nil
    var targetRockCount: Int { trainingBalance?.sectorRockCount ?? 9 }
    private var nextSpawnIndex: Int = 0
    private(set) var incomingRocksLeft = 0
    private(set) var sectorElapsed: Float = 0
    private(set) var nextIncoming: Float = 0
    private(set) var sectorCleared = false
    private(set) var destroyedRocks = 0
    enum TrainingObjective: Equatable { case clear, waves, escort, defend }
    private(set) var trainingObjective: TrainingObjective = .clear
    private(set) var objectiveWave = 1
    // Gameplay65.ResetObjective65 starts the flat arena escort at 180,530.
    // Pixel-space coordinates are transformed into this sandbox's world units.
    private(set) var objectivePosition = Vec2(x: (180 - 640) * 2.7 / 1280, y: (360 - 530) * 2.7 / 1280)
    static func escortPosition(at elapsed: Float) -> Vec2 {
        let t = min(1, max(0, elapsed / 40))
        let x = 180 + 920 * t
        let y = 530 - 310 * t + sin(t * .pi) * 45
        let scale: Float = 2.7 / 1280
        return Vec2(x: (x - 640) * scale, y: (360 - y) * scale)
    }

    // Gameplay65.cs: level-specific objective types; no assumptions about
    // missing boss logic, escorts, or objective collision beyond the timer.
    static func objectiveFor(level: Int) -> TrainingObjective {
        if [2, 11, 21].contains(level) { return .escort }
        if [5, 14, 23].contains(level) { return .defend }
        if [9, 17].contains(level) { return .waves }
        return .clear
    }
    var objectiveDuration: Float {
        switch trainingObjective {
        case .escort: return 40
        case .defend: return 50
        case .waves: return 48
        case .clear: return 0
        }
    }
    var objectiveTimerComplete: Bool {
        trainingObjective == .clear || sectorElapsed >= objectiveDuration
    }
    // Finishing additionally requires no remaining rocks, shards or arrivals:
    // Game.cs FinishLevel() / Gameplay65.cs ObjectiveComplete65.
    var sectorFinished: Bool {
        trainingBalance != nil && objectiveTimerComplete &&
        rocks.isEmpty && incomingRocksLeft == 0
    }
    var activeThreatCount: Int { rocks.filter { $0.shardLife <= 0 }.count }


    // Diagnostic arena; does not launch or complete a campaign mission.
    mutating func setSectorTraining(_ balance: CombatBalance556?, objective: TrainingObjective? = nil) {
        trainingBalance = balance
        trainingObjective = objective ?? balance.map { Self.objectiveFor(level: $0.level) } ?? .clear
        objectiveWave = 1
        objectivePosition = trainingObjective == .defend
            ? Vec2(x: 0, y: (360 - 420) * 2.7 / 1280)
            : Self.escortPosition(at: 0)
        nextSpawnIndex = 0
        sectorElapsed = 0
        sectorCleared = false
        destroyedRocks = 0
        if let balance {
            let quota = balance.reinforcementQuota
            let initial: Int
            switch trainingObjective {
            case .clear: initial = quota
            case .waves: initial = 4
            case .escort: initial = max(4, quota)
            case .defend: initial = max(6, quota)
            }
            incomingRocksLeft = Int((Double(initial) * 0.8).rounded(.toNearestOrEven))
            nextIncoming = trainingObjective == .waves ? 16 : 12
        } else {
            incomingRocksLeft = 0
            nextIncoming = 0
        }
        rocks.removeAll(keepingCapacity: true)
        bolts.removeAll(keepingCapacity: true)
        while rocks.count < targetRockCount { spawnRock() }
    }

    init() {
        for _ in 0..<9 { spawnRock() }
    }
    private mutating func random() -> Float {
        seed = seed &* 1664525 &+ 1013904223
        return Float(seed & 0x00FFFFFF) / Float(0x01000000)
    }
    private mutating func spawnRock() {
        let radius = 0.055 + random() * 0.055
        let phase = random() * 6.28
        let tier = trainingBalance?.tier(at: nextSpawnIndex % targetRockCount) ?? 0
        nextSpawnIndex += 1
        let p: Vec2
        let v: Vec2
        if let config = trainingBalance {
            // Game.Wave() flat sector spawning: positions sampled from the
            // original 1280x720 arena, at least 260 px from the player.
            // Keep the legacy nine-rock demonstration spawn unchanged.
            let unit: Float = 2.7 / 1280
            var candidate = Vec2(x: 0, y: 0)
            var attempts = 0
            repeat {
                let x = random() * 1280
                let y = random() * 720
                candidate = Vec2(x: (x - 640) * unit, y: (360 - y) * unit)
                attempts += 1
                // Bound rejection sampling in this deterministic prototype.
                if attempts >= 1024 { break }
            } while (candidate - ship).lengthSquared < pow(260 * unit, 2)
            p = candidate
            let a = random() * 2 * Float.pi
            let speedPx = (48 + random() * 30 + Float(min(config.level - 1, 18)) * 3.2)
                * (tier >= 2 ? 0.88 : 1)
            v = Vec2(x: cos(a), y: sin(a)) * (speedPx * unit)
        } else {
            let a = random() * Float.pi * 2
            let d = 0.6 + random() * 0.6
            p = Vec2(x: cos(a) * d, y: sin(a) * d)
            v = Vec2(x: (random() - 0.5) * 0.14, y: (random() - 0.5) * 0.14)
        }
        let size = 3
        let hp = trainingBalance == nil ? 1 : Rock.healthFor(size: size, tier: tier)
        rocks.append(Rock(at: p, motion: v, radius: trainingBalance == nil ? radius : Rock.radiusFor(size: size), phase: phase, tier: tier, size: size, health: hp, originalHealth: hp))
    }
    private mutating func addFragments(of parent: Rock) {
        guard parent.size > 1 else { return }
        let angle = atan2(parent.motion.y, parent.motion.x)
        let speed = sqrt(parent.motion.lengthSquared)
        // Game.Split: two children with decremented armor tier.
        for sign: Float in [-1, 1] {
            let offsetAngle = angle + sign * .pi / 2
            let offset = Vec2(x: cos(offsetAngle), y: sin(offsetAngle)) * (8 * 2.7 / 1280)
            let motionAngle = angle + sign * 0.75
            let childSpeed = min(175 * 2.7 / 1280, speed * 1.17 + 9 * 2.7 / 1280)
            let childTier = max(0, parent.tier - 1)
            let childSize = parent.size - 1
            let hp = Rock.healthFor(size: childSize, tier: childTier)
            let scale: Float = parent.size == 3 ? 0.68 : 0.52
            rocks.append(Rock(at: wrapped(parent.at + offset), motion: Vec2(x: cos(motionAngle), y: sin(motionAngle)) * childSpeed,
                              radius: Rock.radiusFor(size: childSize, scale: scale), phase: random() * 6.28,
                              tier: childTier, size: childSize, health: hp, originalHealth: hp, fragment: true))
        }
    }
    private mutating func addTerminalShards(of parent: Rock) {
        // Game.SpawnTerminalShards187: bounded, short-lived physical shards.
        guard rocks.count <= 220 else { return }
        for i in 0..<18 {
            let angle = 2 * Float.pi * Float(i) / 18 + (random() * 0.2 - 0.1)
            let dir = Vec2(x: cos(angle), y: sin(angle))
            let distance = (2 + random() * 5) * 2.7 / 1280
            let speed = (42 + random() * 73) * 2.7 / 1280
            let scale = 0.10 + random() * 0.13
            let life = 1.3 + random() * 1.2
            rocks.append(Rock(at: wrapped(parent.at + dir * distance), motion: parent.motion + dir * speed,
                              radius: Rock.radiusFor(size: 1, scale: scale), phase: parent.phase,
                              tier: 0, size: 1, health: 1, originalHealth: 1, fragment: true, shardLife: life))
        }
    }
    private mutating func damageRock(at index: Int, amount: Int) {
        guard rocks.indices.contains(index) else { return }
        if rocks[index].shardLife > 0 {
            // Game.Split removes a hit cosmetic shard without score or further splitting.
            rocks.remove(at: index)
            return
        }
        rocks[index].health -= amount
        guard rocks[index].health <= 0 else { return }
        let destroyed = rocks.remove(at: index)
        destroyedRocks += 1
        score += (destroyed.size == 3 ? 20 : destroyed.size == 2 ? 50 : 100)
            + (destroyed.originalHealth - 1) * 30 + destroyed.tier * 10
        if destroyed.size > 1 { addFragments(of: destroyed) }
        else { addTerminalShards(of: destroyed) }
    }
    private mutating func spawnIncoming() {
        guard let config = trainingBalance, incomingRocksLeft > 0 else { return }
        let n = min(2, incomingRocksLeft)
        incomingRocksLeft -= n
        let unit: Float = 2.7 / 1280
        for i in 0..<n {
            let tier: Int
            if config.level >= 13 { tier = 2 + Int(random() * 3) }
            else { tier = config.level >= 10 ? 2 : config.level >= 5 ? 1 : 0 }
            // Action38.SpawnIncoming: alternate the left/right boundary
            // within EACH two-rock batch and keep away from the player.
            let x = i % 2 == 0 ? Float(20) : Float(1260)
            var p = Vec2(x: (x - 640) * unit, y: 0)
            var attempts = 0
            repeat {
                let y = Float(140) + random() * Float(520)
                p = Vec2(x: (x - 640) * unit, y: (360 - y) * unit)
                attempts += 1
                if attempts > 20 {
                    let a = random() * .pi * 2
                    p = wrapped(ship + Vec2(x: cos(a), y: sin(a)) * (340 * unit))
                    break
                }
            } while (p - ship).lengthSquared < (260 * unit) * (260 * unit)
            // Gameplay65: Defend rocks steer to the original objective
            // at (640,420); others receive a random heading.
            let heading: Vec2
            if trainingObjective == .defend {
                let delta = Vec2(x: 0, y: (360 - 420) * unit) - p
                let length = sqrt(delta.lengthSquared)
                heading = delta * (1 / max(1e-6, length))
            } else {
                let a = random() * .pi * 2
                heading = Vec2(x: cos(a), y: sin(a))
            }
            let speed = (60 + random() * 40) * unit
            let hp = Rock.healthFor(size: 3, tier: tier)
            rocks.append(Rock(at: p, motion: heading * speed,
                              radius: Rock.radiusFor(size: 3), phase: random() * 6.28,
                              tier: tier, size: 3, health: hp, originalHealth: hp))
        }
        nextIncoming = sectorElapsed + (trainingObjective == .waves ? 16 : 11)
    }
    private mutating func stepTrainingSector(dt: Float) {
        guard trainingBalance != nil else { return }
        sectorElapsed += dt
        // Gameplay65.StepObjective65: escort follows the original flat 40s route.
        // SphereActive67 would use MoveObjective68; do not use this curve for
        // a future spherical mission until that system is implemented.
        if trainingObjective == .escort { objectivePosition = Self.escortPosition(at: sectorElapsed) }
        // Gameplay65.StepObjective65: three 16-second intervals, capped at wave 3.
        if trainingObjective == .waves {
            objectiveWave = min(3, 1 + Int(sectorElapsed / 16))
        }
        // Sector training remains separate from unported real mission transitions.
        if incomingRocksLeft > 0 && (sectorElapsed >= nextIncoming ||
           (trainingObjective != .waves && rocks.count <= 4)) { spawnIncoming() }
        if sectorFinished { sectorCleared = true }
    }
    // Swept segment-circle collision on the periodic arena. Both bodies move
    // during each physics step, so collision is computed in relative motion.
    // Nine periodic images handle objects crossing opposite arena edges.
    static func sweptHit(from a: Vec2, to b: Vec2, rockFrom c: Vec2, rockTo d: Vec2,
                         radius: Float, extent: Float) -> Bool {
        CombatCollision556.firstPeriodicHit(from:a,to:b,rockFrom:c,rockTo:d,radius:radius,extent:extent) <= 1
    }
    private func wrapped(_ p: Vec2) -> Vec2 {
        var p = p
        if p.x > extent { p.x -= 2 * extent }
        if p.x < -extent { p.x += 2 * extent }
        if p.y > extent { p.y -= 2 * extent }
        if p.y < -extent { p.y += 2 * extent }
        return p
    }
    mutating func tick(_ command: FlightCommand, dt unbounded: Float) {
        let dt = min(1.0 / 60, max(0, unbounded))
        guard dt > 0 else { return }
        time += dt
        shotTimer -= dt
        hitTimer = max(0, hitTimer - dt)
        angle -= max(-1, min(1, command.turn)) * 3.4 * dt
        let forward = Vec2(x: -sin(angle), y: cos(angle))
        let thrust = max(0, min(1, command.throttle))
        // v556 inertial response: desired target speed, exponential rise/coast.
        let accel = flight.motion(velocity:&velocity,desired:forward*(thrust*flight.configuration.cruiseSpeed),inputLength:thrust,dt:dt)
        flight.attitude(angle:angle,velocity:velocity,acceleration:accel,dt:dt)
        let previousShip = ship
        let nextShip = ship + velocity * dt
        ship = wrapped(nextShip)
        if command.fire && shotTimer <= 0 {
            shotTimer = 0.135
            bolts.append(Bolt(at: wrapped(ship + forward * 0.12), motion: velocity + forward * 1.65, life: 1.1))
        }
        let previousRocks = rocks.map { $0.at }
        let previousBolts = bolts.map { $0.at }
        for i in rocks.indices { rocks[i].at = wrapped(rocks[i].at + rocks[i].motion * dt) }
        for i in bolts.indices { bolts[i].at = wrapped(bolts[i].at + bolts[i].motion * dt); bolts[i].life -= dt }
        var removeRocks = Set<Int>(), removeBolts = Set<Int>()
        var damageEvents: [Int: Int] = [:]
        for i in rocks.indices {
            let rock = rocks[i]
            if hitTimer <= 0 && Self.sweptHit(from:previousShip,to:nextShip,
                rockFrom:previousRocks[i],rockTo:previousRocks[i] + rock.motion*dt,
                radius:rock.radius + 0.06,extent:extent) {
                hull = max(0, hull - 1)
                hitTimer = 1.3
                velocity = velocity * -0.45
            }
            for j in bolts.indices where bolts[j].life > 0 && !removeBolts.contains(j) {
                if Self.sweptHit(from:previousBolts[j],to:previousBolts[j] + bolts[j].motion*dt,
                    rockFrom:previousRocks[i],rockTo:previousRocks[i] + rock.motion*dt,
                    radius:rock.radius + 0.014,extent:extent) {
                    if trainingBalance != nil { damageEvents[i, default: 0] += 1 }
                    else { removeRocks.insert(i); score += 100 }
                    removeBolts.insert(j); break
                }
            }
        }
        if trainingBalance != nil {
            for index in damageEvents.keys.sorted(by: >) { damageRock(at: index, amount: damageEvents[index]!) }
        } else {
            rocks = rocks.enumerated().compactMap { removeRocks.contains($0.offset) ? nil : $0.element }
        }
        bolts = bolts.enumerated().compactMap { removeBolts.contains($0.offset) || $0.element.life <= 0 ? nil : $0.element }
        if trainingBalance == nil { while rocks.count < targetRockCount { spawnRock() } }
        if trainingBalance != nil {
            for i in rocks.indices.reversed() where rocks[i].shardLife > 0 {
                rocks[i].shardLife -= dt
                if rocks[i].shardLife <= 0 { rocks.remove(at: i) }
            }
            stepTrainingSector(dt: dt)
        }
        if hull == 0 { hull = 3; ship = Vec2(x: 0, y: 0); velocity = Vec2(x: 0, y: 0); hitTimer = 1.3 }
    }
}
