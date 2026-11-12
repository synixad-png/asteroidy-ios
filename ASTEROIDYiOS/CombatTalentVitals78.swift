import Foundation

/// Exact PC v609 Talents78.StepArmorRegen78 timing and fractional
/// carry, reused by the real C279 mission and the verified Physics68
/// encounter. No additional HUD gauge or second armor pool.
struct ArmorRegeneration609 {
    static let interval:Double=3
    static let fraction:Double=0.25

    private(set) var elapsed:Double=0
    private(set) var carry:Double=0

    mutating func reset() {
        elapsed=0
        carry=0
    }

    /// First hit after full armor starts a new three-second interval;
    /// later hits during a partially depleted interval DO NOT reset it.
    mutating func tookDamage(wasFull:Bool,now:Int,maximum:Int) {
        if wasFull && now<maximum {reset()}
    }

    /// This may be called only by an active mission/tunnel simulation step.
    /// The explicit guards prevent healing during downed rescue, pause,
    /// menu and hangar even if a caller mistakenly advances game time.
    mutating func advance(dt:Float,armor:inout Int,maximum:Int,
                          playing:Bool,shipDown:Bool) {
        guard maximum>0 else{return}
        if armor>=maximum {reset();return}
        guard playing && !shipDown && dt>0 else{return}
        elapsed+=Double(dt)
        guard elapsed>=Self.interval else{return}
        let intervals=Int(elapsed/Self.interval)
        elapsed-=Double(intervals)*Self.interval
        let amount=carry+Double(intervals)*Double(maximum)*Self.fraction
        let restored=Int(amount)
        carry=amount-Double(restored)
        guard restored>0 else{return}
        armor=min(maximum,armor+restored)
        if armor>=maximum {reset()}
    }
}

/// Direct port of Windows/src/Talents78.cs AbsorbDamage78 and ResetVitals78.
/// This owns the player's numeric armor/hull gauges, not life loss or the
/// guardian/tarcza/coop checks that surround it in Game.Damage().
final class CombatTalentVitals78 {
    let hullRank:Int
    let armorRank:Int
    var dampenerRank:Int
    private(set) var hull:Int
    private(set) var armor:Int
    private(set) var flash:Float=0
    private(set) var lastDamage:Int=0
    private var armorRegen609=ArmorRegeneration609()

    var maxHull:Int { 60 + 15*hullRank }
    var maxArmor:Int { 25 + 15*armorRank }

    init(hullRank:Int=0,armorRank:Int=0,dampenerRank:Int=0) {
        self.hullRank=max(0,min(4,hullRank))
        self.armorRank=max(0,min(4,armorRank))
        self.dampenerRank=max(0,dampenerRank)
        hull=60+15*self.hullRank
        armor=25+15*self.armorRank
    }

    /// Original AbsorbDamage78: armor takes damage before hull. Return false
    /// only when remaining hull is zero; the verified damage controller
    /// may then resolve co-op wreck/life loss. Even a fatal gauge hit sets
    /// .85 seconds of invulnerability and a .09 flash.
    @discardableResult
    func absorb(damage:Int,cause:String,difficulty:CombatBalance556.Difficulty,
                invincible:inout Float) -> Bool {
        let defaultDamage:Int = difficulty == .easy ? 27 :
                                difficulty == .hard ? 38 : 32
        var hit=damage>0 ? damage : defaultDamage
        if cause == "POCISK WROGA" && damage>0 {
            hit=max(1,hit-2*dampenerRank)
        }
        let wasFull=armor>=maxArmor
        let blocked=min(hit,armor)
        armor -= blocked
        armorRegen609.tookDamage(wasFull:wasFull,now:armor,maximum:maxArmor)
        hull=max(0,hull-(hit-blocked))
        invincible=max(invincible,0.85)
        flash=max(flash,0.09)
        lastDamage=hit
        return hull>0
    }

    func reset() {
        hull=maxHull
        armor=maxArmor
        flash=0
        lastDamage=0
        armorRegen609.reset()
    }

    func advance(dt:Float,playing:Bool=true,shipDown:Bool=false) {
        flash=max(0,flash-max(0,dt))
        armorRegen609.advance(dt:dt,armor:&armor,maximum:maxArmor,
                              playing:playing,shipDown:shipDown)
    }
}
