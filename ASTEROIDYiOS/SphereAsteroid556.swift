import Foundation

// Port of spherical asteroid movement/distance primitives from ASTEROIDY
// v556 Game.cs, Action38.cs and SphereCombat67.cs. Coordinate units are
// ORIGINAL 1280x720 atlas units, not the normalized Metal sandbox.
// This standalone adapter does not enable unported spherical renderer/collisions.
struct SphereAsteroid556 {
    var position: Vec2
    var velocity: Vec2
    var radius: Float
    var size: Int
    var tier: Int
    var health: Int
    var originalHealth: Int
    var fragment: Bool
    var shardLife: Float
    var mass: Float
    var spin: Float
    var angle: Float
    init(position: Vec2, velocity: Vec2, radius: Float,
         size: Int = 3, tier: Int = 0, health: Int? = nil,
         fragment: Bool = false, shardLife: Float = 0,
         mass: Float? = nil, spin: Float = 0, angle: Float = 0) {
        self.position = Sphere67.canonical(position)
        self.velocity = velocity
        self.radius = radius
        self.size = size
        self.tier = tier
        let hp = health ?? Rock.healthFor(size:size,tier:tier)
        self.health = hp
        self.originalHealth = hp
        self.fragment = fragment
        self.shardLife = shardLife
        self.mass = mass ?? (shardLife > 0 ? 0.09 : size == 3 ? 8 : size == 2 ? 4 : 2)
        self.spin = spin
        self.angle = angle
    }
    // Game.cs r.P = WorldAdvance67(..., dt * (SphereActive67 ? 1 : DangerSpeed))
    mutating func advance(dt: Float) {
        guard dt > 0 else { return }
        position = Sphere67.advance(position, velocity: &velocity, dt: dt)
        angle += spin * dt
    }
    // Game.Wave: level speed, armor slowdown and spherical 0.55*DangerSpeed.
    static func startingSpeed(baseRandomSpeed: Float, level: Int, tier: Int, dangerSpeed: Float) -> Float {
        (baseRandomSpeed + Float(min(max(1, level)-1, 18))*3.2)
            * (tier >= 2 ? 0.88 : 1) * 0.55 * dangerSpeed
    }
    // Action38.SpawnIncoming spherical speed.
    static func incomingSpeed(baseRandomSpeed: Float, dangerSpeed: Float) -> Float {
        baseRandomSpeed * 0.55 * dangerSpeed
    }
    // The shortest spherical arc is authoritative for collision radii.
    func surfaceDistance(to other: Vec2) -> Float {
        sqrt(Sphere67.delta(target:other,origin:position).lengthSquared)
    }
    func touches(_ other: Vec2, otherRadius: Float) -> Bool {
        surfaceDistance(to:other) < radius + otherRadius
    }
    static func fragmentScale(parentSize: Int) -> Float {
        parentSize == 3 ? 0.49 : 0.39
    }
}
