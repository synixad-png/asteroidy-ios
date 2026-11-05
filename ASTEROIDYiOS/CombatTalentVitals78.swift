import Foundation

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
        let blocked=min(hit,armor)
        armor -= blocked
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
    }

    func advance(dt:Float) {
        flash=max(0,flash-max(0,dt))
    }
}
