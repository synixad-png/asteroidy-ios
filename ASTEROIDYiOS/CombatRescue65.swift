import Foundation

/// Gameplay65.TryDown65 / StepRescue65 from ASTEROIDY Windows v556.
/// State transitions are exact; FailRescue65 reports an action to the
/// verified Damage() layer rather than bypassing guardian/talent defenses.
struct CombatRescue65 {
    enum Player:Equatable { case first, second }
    enum Event:Equatable {
        case none
        case rescued(Player)
        case failed(first:Bool,second:Bool)
    }
    private(set) var downFirst:Float=0
    private(set) var downSecond:Float=0
    private(set) var progress:Float=0
    private(set) var rescues=0

    func down(_ p:Player) -> Bool {
        p == .first ? downFirst>0 : downSecond>0
    }
    mutating func reset() {
        downFirst=0
        downSecond=0
        progress=0
    }

    /// True means TryDown65 consumed a fatal hit or the player is already
    /// wrecked. A false return means an external verified Damage() path
    /// remains responsible for deciding the actual life loss.
    mutating func beginDown(_ player:Player,cooperative:Bool,playing:Bool,
                            developerInfinite:Bool,rescueDamage:Bool,
                            survival:inout CombatSurvival96,
                            body:inout CombatBody68) -> Bool {
        guard cooperative && !rescueDamage && playing && !developerInfinite
        else {return false}
        if down(player) {return true}
        if player == .first {downFirst=12} else {downSecond=12}
        progress=0
        body.velocity=Vec2(x:0,y:0)
        survival.currentDown=true
        survival.invincible=9999
        return true
    }

    /// The firing input belongs to the HELPER (not the wreck).
    /// A 105-unit geodesic range and helper speed strictly below 160
    /// are required continuously for 2 s. Lost progress decays at 2x.
    mutating func tick(dt:Float,playing:Bool,sceneBusy:Bool,devOpen:Bool,
                       bossArrival:Bool,cooperative:Bool,
                       first:inout CombatBody68,second:inout CombatBody68,
                       firstSurvival:inout CombatSurvival96,
                       secondSurvival:inout CombatSurvival96,
                       firstFiring:Bool,secondFiring:Bool) -> Event {
        guard cooperative && playing && !sceneBusy && !devOpen &&
              !bossArrival && dt>0 else {return .none}
        let a=downFirst>0, b=downSecond>0
        guard a || b else {return .none}
        downFirst=max(0,downFirst-dt)
        downSecond=max(0,downSecond-dt)
        if a && b {
            reset()
            firstSurvival.currentDown=false
            secondSurvival.currentDown=false
            return .failed(first:true,second:true)
        }
        let wreck=a ? first.position : second.position
        let helper=a ? second.position : first.position
        let firing=a ? secondFiring : firstFiring
        let speed=sqrt((a ? second.velocity : first.velocity).lengthSquared)
        let separation=Sphere67.delta(target:helper,origin:wreck)
        let near=sqrt(separation.lengthSquared)<=105 && speed<160 && firing
        progress=max(0,min(2,progress+(near ? dt : -dt*2)))
        if progress>=2 {
            if a {
                downFirst=0
                firstSurvival.currentDown=false
                firstSurvival.invincible=3
                first.velocity=Vec2(x:0,y:0)
            } else {
                downSecond=0
                secondSurvival.currentDown=false
                secondSurvival.invincible=3
                second.velocity=Vec2(x:0,y:0)
            }
            progress=0
            rescues += 1
            return .rescued(a ? .first : .second)
        }
        if (a && downFirst<=0) || (b && downSecond<=0) {
            reset()
            firstSurvival.currentDown=false
            secondSurvival.currentDown=false
            return .failed(first:a,second:b)
        }
        return .none
    }
}
