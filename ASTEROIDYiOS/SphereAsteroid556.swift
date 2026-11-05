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
    // Windows Rock.MaxHealth is modified by Balance70.PrepareRock70.
    // Rock.OriginalHP70 remains the original constructor's lower HP
    // and governs score after destruction.
    var maxHealth: Int
    var originalHealth: Int
    // Original Game.Rock Shape and AmigaBounce265 per-ball state.
    var shapeSeed: Int
    var bounceHeight: Float = 0
    var bounceVertical: Float = 0
    var bounceCount: Int = 0
    var fragment: Bool
    var shardLife: Float
    var mass: Float
    var spin: Float
    var angle: Float
    init(position: Vec2, velocity: Vec2, radius: Float,
         size: Int = 3, tier: Int = 0, health: Int? = nil,
         fragment: Bool = false, shardLife: Float = 0,
         mass: Float? = nil, spin: Float = 0, angle: Float = 0,
         originalHealth: Int? = nil, shapeSeed: Int = 0) {
        self.position = Sphere67.canonical(position)
        self.velocity = velocity
        self.radius = radius
        self.size = size
        self.tier = tier
        let hp = health ?? Rock.healthFor(size:size,tier:tier)
        self.health = hp
        self.maxHealth = hp
        self.originalHealth = originalHealth ?? hp
        self.shapeSeed = shapeSeed
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

// In the same source as SphereAsteroid556 so the existing original v556
// Swift test build lists (including the non-triggered IPA workflow) keep
// compiling without editing or triggering the IPA workflow.
/// Literal port of Windows/src/AmigaBounce265.cs plus the Level==25
/// part of Windows/src/Balance70.cs PrepareRock70. This is ONLY for
/// the original spherical level 25 perpetual bouncing-ball showroom.
enum AmigaBounce265 {
    static let hitsGoal = 20 // HUD reference; NEVER a completion gate.

    static func prepare(_ rock:inout SphereAsteroid556) {
        guard !rock.fragment else { return }
        let shape=Float(rock.shapeSeed & 0xffff)
        let phase=abs(sin(shape*0.01927))
        rock.bounceHeight=4+17*phase
        rock.bounceVertical=119+71*abs(sin(shape*0.03719))
        rock.bounceCount=0
    }

    /// AmigaBounce265.StepAmigaBounce265: 480 gravity, 0.05 s cap,
    /// independent per-ball rhythm, 55-unit radial height limit.
    static func step(_ rock:inout SphereAsteroid556,dt:Float) {
        guard rock.shardLife<=0 && dt>0 else { return }
        let t=min(dt,0.05)
        let gravity:Float=480
        rock.bounceHeight += rock.bounceVertical*t-0.5*gravity*t*t
        rock.bounceVertical -= gravity*t
        if rock.bounceHeight>0 {
            rock.bounceHeight=min(55,rock.bounceHeight)
            return
        }
        rock.bounceHeight=0
        rock.bounceCount += 1
        let shape=Float(rock.shapeSeed & 0xffff)
        let turns=Float(rock.bounceCount)
        let wobble=sin(shape*0.01607+turns*2.417)
        let variety=sin(shape*0.04371+turns*1.319)
        rock.bounceVertical=149+44*(0.5+0.5*variety)
        let current=sqrt(rock.velocity.lengthSquared)
        let speed=max(45,min(270,current*(0.84+0.12*abs(variety))))
        var direction=atan2(rock.velocity.y,rock.velocity.x)+wobble*1.45
        if rock.bounceCount%5==0 {
            direction += variety>=0 ? 0.83 : -0.83
        }
        rock.velocity=Vec2(x:cos(direction),y:sin(direction))*speed
        rock.spin=max(-2.8,min(2.8,rock.spin+wobble*0.22))
    }

    /// AmigaBounce265.ImpulseAmiga266: shots change momentum and hop,
    /// but NEVER reduce rock health or fragment the planet-25 balls.
    /// Caller owns the source counted hit/score increment.
    static func impact(_ rock:inout SphereAsteroid556,
                       origin:Vec2,projectileVelocity:Vec2,
                       power:Int=1) {
        let incoming=Sphere67.components(rock.position,
            Sphere67.transport(Sphere67.vector(origin,projectileVelocity),
                from:Sphere67.normal(origin),
                to:Sphere67.normal(rock.position)))
        let length=sqrt(incoming.lengthSquared)
        let fallback=rock.angle+Float.pi/3
        let direction=length>0.001 ? incoming*(1/length) :
                       Vec2(x:cos(fallback),y:sin(fallback))
        let impulse=min(145,75+Float(power)*14)
        let next=rock.velocity*0.70+direction*impulse
        let speed=sqrt(next.lengthSquared)
        rock.velocity=speed>285 ? next*(285/speed) : next
        let flight=145+min(75,Float(power)*11)
        rock.bounceVertical=max(rock.bounceVertical,flight)
        rock.bounceHeight=max(rock.bounceHeight,3.5)
        let spinStep:Float = (rock.shapeSeed & 1) == 0 ? 0.48 : -0.48
        rock.spin=max(-3,min(3,rock.spin+spinStep))
        rock.health=rock.maxHealth
    }
}
