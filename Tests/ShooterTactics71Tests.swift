import Foundation

@main struct ShooterTactics71Tests {
    static func main() {
        var checks=0
        func eq<T:Equatable>(_ a:T,_ b:T,_ label:String) {
            precondition(a==b,label+" expected \(b) but got \(a)")
            checks+=1
        }
        for difficulty in 0...2 {
            for level in 1...25 {
                for kind in 0...5 {
                    let s=ShooterTactics71(
                        level:level,type:kind,difficulty:difficulty)
                    let tier=min(5,(level-1)/4)
                    eq(s.tier,tier,"original EnemyTier71")
                    eq(s.isHunter,kind==1 || kind==5,"Hunter type")
                    eq(s.shootingRange,
                       level<=2 ? 200 : level<=4 ? 205 : 210,
                       "FireRange96")
                    eq(s.preferredStandoff,
                       level<=4 ? 158 :
                         kind==1 ? 176 : kind==3 ? 153 :
                         kind==4 ? 170 : 163,"source enemy orbit distance")
                    eq(s.sourceSpeed,
                       kind==1 ? 295 : Float(245+kind*6),
                       "EnemyTactics71 source projectile speed")
                    eq(s.warningSeconds,
                       level<=4 ? 0.82 : level<=8 ? 0.55 :
                         (kind==1 || kind==4) ? 0.7 : 0.28,
                       "source warning duration")
                    eq(s.lockedSalvo,kind==1 || kind==4,
                       "GunAim72 locked heavy salvo")
                    let shots=level<=4 ? 1 : level<=8 ?
                       (kind==1 ? 1 : 2) :
                       kind==1 ? 1 : kind==4 ? 7 : kind==2 ? 3 : 2
                    eq(s.volleyCount,shots,"source volley size")
                    eq(s.spread,kind==4 ? 0.38 : kind==2 ? 0.15 : 0.055,
                       "source shot dispersion")
                    eq(s.burstLength,
                       level<=4 ? 1 : level<=8 ? 2 :
                         (kind==1 || kind==4) ? 1 :
                         difficulty==0 ? 2 : 3,
                       "source burst sequence")
                    let baseGap:Float=level<=2 ? 2.8 : level<=4 ? 2.35 :
                                      level<=8 ? 1.75 :
                                      kind==1 ? 1.6 : kind==4 ? 2.0 : 1.1
                    let factor:Float=difficulty==0 ? 1.3 :
                                     difficulty==2 ? 0.9 : 1.0
                    eq(abs(s.recoverySeconds-baseGap*factor)<0.00001,true,
                       "source recovery timing")
                    eq(s.projectileKind,kind==3 ? 2 : 0,
                       "slow projectile kind only from type3")
                    eq(s.bounty,2+kind/2,"BugReward71 source bounty")
                    let initial:Double=level<=2 ? 8 : level<=4 ? 10 :
                      level<=8 ? 14 : level<=12 ? 18 :
                      level<=16 ? 21 : 25
                    let modifier:Double=kind==3 ? 2:0
                    let multiplier:Double=difficulty==0 ? 0.8 :
                      difficulty==2 ? 1.25 : 1
                    eq(s.projectileDamage,
                       max(4,Int(((initial+modifier)*multiplier)
                                  .rounded(.toNearestOrEven))),
                       "ShooterShotDamage96 C# Math.Round bankers parity")
                }
            }
        }
        let first=ShooterTactics71(level:1,type:0,difficulty:1)
        eq(first.preferredStandoff,158,"CARBONIS current source standoff")
        eq(first.recoverySeconds,2.8,"CARBONIS initial recovery")
        eq(first.volleyCount,1,"CARBONIS initial single shot")
        eq(first.projectileDamage,8,"CARBONIS enemy damage")
        let next=ShooterTactics71(level:5,type:1,difficulty:1)
        eq(next.sourceSpeed,295,"second authored fighter speed level5")
        eq(next.preferredStandoff,176,"second fighter level5 ring")
        eq(next.warningSeconds,0.55,"level5 warning")
        print("PASS \(checks) real EnemyTactics71 rule assertions over 450 source profiles")
    }
}
