import Foundation

/// PC v609 Windows/src/Tarcza145.cs: one active 100-point bar and
/// three *full-bar* reserves. The reserve is consumed ONLY here, when
/// the active bar is exhausted by held drain, impact or legacy save state.
/// Both the real first-sector game and verified multi-player path delegate
/// to this reducer; no parallel purchased passive-hit shield exists.
struct SourceTarcza145 {
    static let maximum:Float = 100
    static let initial:Float = 60
    static let reserveMaximum:Int = 3
    static let drainPerSecond:Float = 12
    static let impactCost:Float = 35

    var energy:Float = initial
    var active=false
    var flash:Float=0

    mutating func reset() {
        energy=Self.initial
        active=false
        flash=0
    }

    /// Hub90's free current-bar refill never spends a reserve.
    mutating func refill() {
        energy=Self.maximum
        active=false
        flash=0
    }

    /// Exact RestoreTarczaFromReserve145() from PC v608.
    @discardableResult
    mutating func restoreFromReserve(_ reserve:inout Int)->Bool {
        guard energy<=0 && reserve>0 else{return false}
        reserve-=1
        energy=Self.maximum
        flash=max(flash,0.24)
        return true
    }

    mutating func step(dt:Float,held:Bool,playing:Bool,
                       shipDown:Bool=false,reserve:inout Int) {
        guard playing && !shipDown else {
            active=false
            return
        }
        // Old saved states may have zero energy with stored charges.
        if energy<=0 {_=restoreFromReserve(&reserve)}
        active=held && energy>0
        if active {
            energy=max(0,energy-Self.drainPerSecond*max(0,dt))
            if energy<=0 {
                active=restoreFromReserve(&reserve)
            }
        }
        flash=max(0,flash-max(0,dt))
    }

    /// A hit consumes 35 current energy only when the user holds TARCZA.
    /// The intercept itself remains successful even if the last few energy
    /// points are exhausted and no reserve is left.
    mutating func absorb(invincible:inout Float,reserve:inout Int)->Bool {
        guard active && energy>0 else{return false}
        energy=max(0,energy-Self.impactCost)
        if energy<=0 {_=restoreFromReserve(&reserve)}
        active=energy>0
        flash=0.37
        invincible=max(invincible,0.28)
        return true
    }

    /// PC CollectTarcza145: +1 reserve, never +20 energy; at 3/3 refill
    /// the incomplete current bar, and if picked up at zero energy use
    /// that fresh reserve immediately to restore 100/100.
    @discardableResult
    mutating func collectCell(reserve:inout Int)->Bool {
        if reserve<Self.reserveMaximum {
            reserve+=1
            if energy<=0 {_=restoreFromReserve(&reserve)}
            return true
        }
        guard energy<Self.maximum else{return false}
        energy=Self.maximum
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
        var rng=MissionWave568.SourceRandom(
            seed:seed ^ Int32(bitPattern:0x37C9E215))
        let firstBoost=4+rng.integer(4)
        random=rng
        untilBoost=firstBoost
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
