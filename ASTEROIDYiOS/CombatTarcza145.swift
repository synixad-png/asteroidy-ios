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

    /// Persistent active-bar charge is a checkpoint value, not a second
    /// live shield. Saved separately from the unchanged 3/3 shop inventory.
    static let persistentKey="asteroidy.ios.pc608.tarcza-energy145"

    static func loadPersistentEnergy(defaults:UserDefaults = .standard)->Float {
        guard let value=defaults.object(forKey:persistentKey) as? NSNumber,
              value.floatValue.isFinite,
              (0...maximum).contains(value.floatValue)
        else{return initial}
        return value.floatValue
    }

    @discardableResult
    static func savePersistentEnergy(_ value:Float,
                                      defaults:UserDefaults = .standard)->Bool {
        guard value.isFinite,(0...maximum).contains(value) else{return false}
        defaults.set(Double(value),forKey:persistentKey)
        return true
    }
    static func resetPersistentEnergy(defaults:UserDefaults = .standard) {
        defaults.removeObject(forKey:persistentKey)
    }

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

/// Compatibility adapter for the verified Physics68/Coop62 encounter.
/// PC v608 has ONE active shield + reserve mechanic, implemented by
/// SourceTarcza145. This adapter does not own different protection rules.
struct CombatTarcza145 {
    static let maximum:Float=SourceTarcza145.maximum
    static let drainPerSecond:Float=SourceTarcza145.drainPerSecond
    static let impactCost:Float=SourceTarcza145.impactCost
    static let reserveMaximum:Int=SourceTarcza145.reserveMaximum

    private var source=SourceTarcza145()
    var energy:Float {source.energy}
    var active:Bool {source.active}
    var flash:Float {source.flash}

    mutating func reset() {source.reset()}
    mutating func refill() {source.refill()}

    mutating func tick(dt:Float,held:Bool,playing:Bool,shipDown:Bool,
                       reserve:inout Int) {
        source.step(dt:dt,held:held,playing:playing,
                    shipDown:shipDown,reserve:&reserve)
    }

    @discardableResult
    mutating func absorb(invincible:inout Float,reserve:inout Int)->Bool {
        source.absorb(invincible:&invincible,reserve:&reserve)
    }

    @discardableResult
    mutating func collectCell(reserve:inout Int)->Bool {
        source.collectCell(reserve:&reserve)
    }
}
