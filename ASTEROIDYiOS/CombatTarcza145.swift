import Foundation

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
