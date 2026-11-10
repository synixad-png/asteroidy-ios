import Foundation

/// PC Tarcza145.cs: rechargeable, *held* active energy shield.
/// Separate from the purchased, passive shieldCharges inventory.
struct SourceTarcza145 {
    static let maximum:Float = 100
    static let initial:Float = 60
    static let refill:Float = 20
    static let drainPerSecond:Float = 12
    static let impactCost:Float = 35

    var energy:Float = initial
    var active=false
    var flash:Float=0

    mutating func step(dt:Float,held:Bool,playing:Bool) {
        guard dt>0 else{return}
        active=held && energy>0 && playing
        if active {
            energy=max(0,energy-Self.drainPerSecond*dt)
            if energy<=0 {active=false}
        }
        flash=max(0,flash-dt)
    }

    /// The caller applies this AFTER guardian interception and BEFORE the
    /// separately purchased passive shield; an actual hit costs 35 energy.
    mutating func absorb(invincible:inout Float)->Bool {
        guard active && energy>0 else{return false}
        energy=max(0,energy-Self.impactCost)
        active=energy>0
        flash=0.37
        invincible=max(invincible,0.28)
        return true
    }

    mutating func collectCell()->Bool {
        guard energy<Self.maximum else{return false}
        energy=min(Self.maximum,energy+Self.refill)
        return true
    }
}

/// PC Boost71.cs: three stored charges, 0.9s genuine forward dash,
/// ram damage and invulnerability, never a second movement simulation.
struct SourceBoost71 {
    private(set) var charges=0
    private(set) var remaining:Float=0
    private var hitRockSeeds:Set<Int>=[]
    private var hitShooterIDs:Set<Int>=[]

    var active:Bool {remaining>0}

    mutating func collect() {
        charges=min(3,charges+1)
    }

    mutating func activate(playing:Bool)->Bool {
        guard playing && charges>0 && remaining<=0 else{return false}
        charges-=1
        remaining=0.9
        hitRockSeeds.removeAll(keepingCapacity:true)
        hitShooterIDs.removeAll(keepingCapacity:true)
        return true
    }

    /// Whether this movement step belongs to the active ram.
    mutating func advance(dt:Float)->Bool {
        guard dt>0 && remaining>0 else{return false}
        remaining=max(0,remaining-dt)
        return true
    }

    mutating func firstRockContact(_ seed:Int)->Bool {
        hitRockSeeds.insert(seed).inserted
    }

    mutating func firstShooterContact(_ id:Int)->Bool {
        hitShooterIDs.insert(id).inserted
    }
}

/// Exact source drop frequencies and lifetimes for Tarcza145 / Boost71.
/// The classic shared C# Random stream is not reproducible against the
/// already-shipped iOS encounter/AI draw ordering. An independent deterministic
/// .NET RNG preserves established iOS mission seeds and physics outcomes.
struct SourceLegacyPickupDrops586 {
    struct Drop {
        let kind:SourcePickupModels586.Kind
        let velocity:Vec2
        let life:Float
    }
    private var random:MissionWave568.SourceRandom
    private var untilBoost:Int

    init(seed:Int32) {
        random=MissionWave568.SourceRandom(
            seed:seed ^ Int32(bitPattern:0x37C9E215))
        untilBoost=4+random.integer(4)
    }

    mutating func shield(enemy:Bool,rockSize:Int,
                         eligible:Bool,pickups:Int)->Drop? {
        guard eligible && pickups<96 else{return nil}
        let probability:Double=enemy ? 0.55 :
            rockSize>=3 ? 0.20 : rockSize==2 ? 0.10 : 0.035
        guard random.unit()<probability else{return nil}
        let a=random.float(0,2*Float.pi)
        return Drop(kind:.shield,
                    velocity:Vec2(x:cos(a)*14,y:sin(a)*14),
                    life:23)
    }

    /// C# Boost71.DropBoost71 decrements on every eligible rock kill and
    /// rearms to 5–9 even when the shared pickup list is already full.
    mutating func boost(eligible:Bool,pickups:Int)->Drop? {
        guard eligible else{return nil}
        untilBoost-=1
        guard untilBoost<=0 else{return nil}
        untilBoost=5+random.integer(5)
        guard pickups<96 else{return nil}
        let a=random.float(0,2*Float.pi)
        return Drop(kind:.boost,
                    velocity:Vec2(x:cos(a)*22,y:sin(a)*22),
                    life:25)
    }
}
