import Foundation

/// Windows/src/Tarcza145.cs, v556: rechargeable manually held energy dome.
/// Distinct from the legacy purchased ShieldCharges passive impact shield.
/// This standalone state is owned by its future ship equipment controller.
struct CombatTarcza145 {
    static let maximum:Float = 100
    static let cell:Float = 20
    static let drainPerSecond:Float = 12
    static let impactCost:Float = 35

    private(set) var energy:Float = 60
    private(set) var active = false
    private(set) var flash:Float = 0

    mutating func reset() {
        energy=60
        active=false
        flash=0
    }
    mutating func refill() {
        energy=Self.maximum
        active=false
        flash=0
    }
    mutating func tick(dt:Float,held:Bool,playing:Bool,shipDown:Bool) {
        guard dt>0 else {
            active=held && energy>0 && playing && !shipDown
            return
        }
        active=held && energy>0 && playing && !shipDown
        if active {
            energy=max(0,energy-Self.drainPerSecond*dt)
            if energy<=0 {active=false}
        }
        flash=max(0,flash-dt)
    }
    /// Returns true only if an active shield intercepted the incoming hit.
    /// The next ApplyHit96 call must see at least 0.28s invulnerability.
    mutating func absorb(invincible:inout Float) -> Bool {
        guard active && energy>0 else {return false}
        energy=max(0,energy-Self.impactCost)
        active=energy>0
        flash=0.37
        invincible=max(invincible,0.28)
        return true
    }
    @discardableResult
    mutating func collectCell() -> Bool {
        guard energy<Self.maximum else {return false}
        energy=min(Self.maximum,energy+Self.cell)
        return true
    }
}
