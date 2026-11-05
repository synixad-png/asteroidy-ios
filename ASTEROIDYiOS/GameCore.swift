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
struct Rock { var at: Vec2; var motion: Vec2; var radius: Float; var phase: Float; var tier: Int = 0 }
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

    // Diagnostic arena; does not launch or complete a campaign mission.
    mutating func setSectorTraining(_ balance: CombatBalance556?) {
        trainingBalance = balance
        nextSpawnIndex = 0
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
        let a = random() * Float.pi * 2
        let d = 0.6 + random() * 0.6
        let p = Vec2(x: cos(a) * d, y: sin(a) * d)
        let v = Vec2(x: (random() - 0.5) * 0.14, y: (random() - 0.5) * 0.14)
        let radius = 0.055 + random() * 0.055
        let phase = random() * 6.28
        let tier = trainingBalance?.tier(at: nextSpawnIndex % targetRockCount) ?? 0
        nextSpawnIndex += 1
        rocks.append(Rock(at: p, motion: v, radius: radius, phase: phase, tier: tier))
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
                    removeRocks.insert(i); removeBolts.insert(j); score += 100; break
                }
            }
        }
        rocks = rocks.enumerated().compactMap { removeRocks.contains($0.offset) ? nil : $0.element }
        bolts = bolts.enumerated().compactMap { removeBolts.contains($0.offset) || $0.element.life <= 0 ? nil : $0.element }
        while rocks.count < targetRockCount { spawnRock() }
        if hull == 0 { hull = 3; ship = Vec2(x: 0, y: 0); velocity = Vec2(x: 0, y: 0); hitTimer = 1.3 }
    }
}
