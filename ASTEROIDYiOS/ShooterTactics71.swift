import Foundation

/// Pure rules from Windows v568 EnemyTactics71.cs:9–30, 39, 53–74.
/// The live CARBONIS sector uses level=1/type=0. Types 1–5 are
/// reference rules for later missions, not claims that those worlds
/// or their geometry are already playable.
/// Difficulty is the source C# value 0 easy, 1 normal, 2 hard.
struct ShooterTactics71 {
    let level:Int
    let type:Int
    let difficulty:Int

    init(level:Int,type:Int,difficulty:Int) {
        precondition((1...25).contains(level))
        precondition((0...5).contains(type))
        precondition((0...2).contains(difficulty))
        self.level=level;self.type=type;self.difficulty=difficulty
    }
    var tier:Int {max(0,min(5,(level-1)/4))}
    var isHunter:Bool {type==1 || type==5}
    var sourceSpeed:Float {type==1 ? 295 : 245+Float(type)*6}
    var shootingRange:Float {level<=2 ? 200 : level<=4 ? 205 : 210}
    var preferredStandoff:Float {
        if level<=4{return 158}
        switch type {
        case 1:return 176
        case 3:return 153
        case 4:return 170
        default:return 163
        }
    }
    var warningSeconds:Float {
        if level<=4{return 0.82}
        if level<=8{return 0.55}
        return type==1 || type==4 ? 0.7 : 0.28
    }
    var lockedSalvo:Bool {type==1 || type==4}
    var volleyCount:Int {
        if level<=4{return 1}
        if level<=8{return min(2,type==1 ? 1 : type==4 ? 6 : type==2 ? 3 : 2)}
        return type==1 ? 1 : type==4 ? 7 : type==2 ? 3 : 2
    }
    var spread:Float {type==4 ? 0.38 : type==2 ? 0.15 : 0.055}
    var burstLength:Int {
        if level<=4{return 1}
        if level<=8{return 2}
        if type==1 || type==4{return 1}
        return difficulty==0 ? 2 : 3
    }
    var recoverySeconds:Float {
        var gap:Float=type==1 ? 1.6 : type==4 ? 2.0 : 1.1
        if level<=2 {gap=2.8}
        else if level<=4 {gap=2.35}
        else if level<=8 {gap=1.75}
        return gap*(difficulty==0 ? 1.3 : difficulty==2 ? 0.9 : 1)
    }
    var projectileKind:Int {type==3 ? 2 : 0}
    var projectileDamage:Int {
        let initial:Int
        if level<=2 {initial=8}
        else if level<=4 {initial=10}
        else if level<=8 {initial=14}
        else if level<=12 {initial=18}
        else if level<=16 {initial=21}
        else {initial=25}
        let adjusted=initial+(projectileKind==2 ? 2 : 0)
        let factor:Double=difficulty==0 ? 0.8 : difficulty==2 ? 1.25 : 1
        return max(4,Int((Double(adjusted)*factor).rounded(.toNearestOrEven)))
    }
    /// Source BugReward71: fighter bounty (not displayed score);
    /// scored externally via Game.Split/Bonus. No made-up point mapping.
    var bounty:Int {2+type/2}
}
