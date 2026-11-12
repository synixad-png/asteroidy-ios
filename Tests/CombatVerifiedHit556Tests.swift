import Foundation
@main struct CombatVerifiedHit556Tests {
    static func body(_ x:Float=640,_ velocity:Float=0) -> CombatBody68 {
        CombatBody68(position:Vec2(x:x,y:360),
                     velocity:Vec2(x:velocity,y:0),mass:2.4,radius:11)
    }
    static func main() {
        typealias V=CombatVerifiedHit556
        var survival=CombatSurvival96(), dome=CombatTarcza145()
        var rescue=CombatRescue65(),ship=body()
        // Unknown guardian/talent results must NEVER subtract lives.
        precondition(V.hit(cause:"ASTEROIDA",level:9,difficulty:.normal,
            player:.first,survival:&survival,body:&ship,dome:&dome,
            rescue:&rescue,cooperative:false,developerInfinite:false,
            guardian:.unverified,talent:.unverified) ==
            .requiresGuardianVerification)
        precondition(survival.lives==3)
        precondition(V.hit(cause:"ASTEROIDA",level:9,difficulty:.normal,
            player:.first,survival:&survival,body:&ship,dome:&dome,
            rescue:&rescue,cooperative:false,developerInfinite:false,
            guardian:.clear,talent:.unverified) ==
            .requiresTalentVerification)
        precondition(survival.lives==3)
        // PC608 active Tarcza145 protects; spare bars never passively guard hits.
        survival.shieldCharges=2
        dome.tick(dt:1/120,held:true,playing:true,shipDown:false,
                  reserve:&survival.shieldCharges)
        precondition(V.hit(cause:"ASTEROIDA",level:9,difficulty:.normal,
            player:.first,survival:&survival,body:&ship,dome:&dome,
            rescue:&rescue,cooperative:false,developerInfinite:false,
            guardian:.unverified,talent:.unverified) == .activeTarczaAbsorbed)
        precondition(survival.shieldCharges==2)
        precondition(survival.lives==3 && survival.invincible>=0.28)
        survival.invincible=0
        dome.tick(dt:1,held:false,playing:true,shipDown:false,
                  reserve:&survival.shieldCharges)
        precondition(V.hit(cause:"ASTEROIDA",level:9,difficulty:.normal,
            player:.first,survival:&survival,body:&ship,dome:&dome,
            rescue:&rescue,cooperative:false,developerInfinite:false,
            guardian:.unverified,talent:.unverified) ==
            .requiresGuardianVerification)
        precondition(survival.shieldCharges==2 && survival.invincible==0)
        survival.invincible=0
        survival.shieldCharges=0
        precondition(V.hit(cause:"ASTEROIDA",level:9,difficulty:.normal,
            player:.first,survival:&survival,body:&ship,dome:&dome,
            rescue:&rescue,cooperative:false,developerInfinite:false,
            guardian:.absorbed,talent:.unverified) == .guardianAbsorbed)
        precondition(survival.lives==3)
        precondition(V.hit(cause:"ASTEROIDA",level:9,difficulty:.normal,
            player:.first,survival:&survival,body:&ship,dome:&dome,
            rescue:&rescue,cooperative:false,developerInfinite:false,
            guardian:.clear,talent:.absorbed) == .talentAbsorbed)
        precondition(survival.lives==3)
        precondition(V.hit(cause:"ASTEROIDA",level:9,difficulty:.normal,
            player:.first,survival:&survival,body:&ship,dome:&dome,
            rescue:&rescue,cooperative:false,developerInfinite:false,
            guardian:.clear,talent:.clear) ==
            .applied(.lifeLost(remaining:2,respawnProtection:3,cause:"ASTEROIDA")))
        precondition(survival.invincible==3)
        precondition(V.hit(cause:"ASTEROIDA",level:9,difficulty:.normal,
            player:.first,survival:&survival,body:&ship,dome:&dome,
            rescue:&rescue,cooperative:false,developerInfinite:false,
            guardian:.clear,talent:.clear) == .ignored)

        // Co-op: verified lack of guardian and talents must wreck (12 s)
        // instead of consuming a life. The second contact is ignored.
        var first=body(100),second:CombatBody68?=body(640,40)
        var s1=CombatSurvival96(),s2=CombatSurvival96()
        var t1=CombatTarcza145(),t2=CombatTarcza145(),coop=CombatRescue65()
        let events:[CombatSolidEvent68]=[.partnerRock(0),.partnerBug(0)]
        let result=V.applyTeam(events,level:10,difficulty:.normal,
            first:&first,second:&second,
            survivalFirst:&s1,survivalSecond:&s2,
            tarczaFirst:&t1,tarczaSecond:&t2,rescue:&coop,
            developerInfinite:false,guardianFirst:.clear,
            guardianSecond:.clear,talentFirst:.clear,
            talentSecond:.clear,isRobot:[true])
        precondition(result == [
            V.TeamOutcome(player:.second,outcome:.downForRescue),
            V.TeamOutcome(player:.second,outcome:.ignored)
        ])
        precondition(coop.down(.second))
        precondition(s2.lives==3 && s2.currentDown && s2.invincible==9999)
        precondition(second!.velocity.lengthSquared==0 && s1.lives==3)

        var dev=CombatSurvival96(),devShip=body()
        var devT=CombatTarcza145(),devR=CombatRescue65()
        precondition(V.hit(cause:"ASTEROIDA",level:3,difficulty:.hard,
            player:.first,survival:&dev,body:&devShip,dome:&devT,
            rescue:&devR,cooperative:false,developerInfinite:true,
            guardian:.unverified,talent:.unverified) == .developerProtected)
        precondition(dev.lives==3 && dev.invincible==0.8)
        // Simultaneous collision events in one Physics68 contact frame:
        // only the first impact may spend armor/hull; the second is
        // suppressed by 0.85s invulnerability from AbsorbDamage78.
        var burstFirst=body(),burstSecond:CombatBody68?=nil
        var burstSurvival=CombatSurvival96(),spareSurvival=CombatSurvival96()
        var burstDome=CombatTarcza145(),spareDome=CombatTarcza145()
        var burstRescue=CombatRescue65()
        let burstVitals=CombatTalentVitals78()
        let burstGuardian=CombatGuardian37(owned:false)
        let burst=V.applyTeam([.shipRock(0),.shipRock(1)],
            level:10,difficulty:.normal,
            first:&burstFirst,second:&burstSecond,
            survivalFirst:&burstSurvival,survivalSecond:&spareSurvival,
            tarczaFirst:&burstDome,tarczaSecond:&spareDome,
            rescue:&burstRescue,developerInfinite:false,
            guardianFirst:.unverified,guardianSecond:.unverified,
            talentFirst:.unverified,talentSecond:.unverified,
            isRobot:[],
            vitalsFirst:burstVitals,guardianStateFirst:burstGuardian)
        precondition(burst == [
            V.TeamOutcome(player:.first,outcome:.talentAbsorbed),
            V.TeamOutcome(player:.first,outcome:.ignored)])
        precondition(burstVitals.armor==0 && burstVitals.hull==53)
        precondition(burstSurvival.lives==3 &&
                     burstSurvival.invincible==0.85)
        burstSurvival.advance(dt:0.84)
        let stillProtected=V.hit(cause:"ASTEROIDA",level:10,
            difficulty:.normal,player:.first,survival:&burstSurvival,
            body:&burstFirst,dome:&burstDome,rescue:&burstRescue,
            cooperative:false,developerInfinite:false,
            guardian:.unverified,talent:.unverified,
            vitals:burstVitals,guardianState:burstGuardian)
        precondition(stillProtected == .ignored)
        burstSurvival.advance(dt:0.02)
        let nextContact=V.hit(cause:"ASTEROIDA",level:10,
            difficulty:.normal,player:.first,survival:&burstSurvival,
            body:&burstFirst,dome:&burstDome,rescue:&burstRescue,
            cooperative:false,developerInfinite:false,
            guardian:.unverified,talent:.unverified,
            vitals:burstVitals,guardianState:burstGuardian)
        precondition(nextContact == .talentAbsorbed)
        precondition(burstVitals.hull==21 &&
                     burstSurvival.lives==3)
        print("PASS PC608: active Tarcza -> guardian -> talents -> rescue -> lives; no passive reserve interception")
    }
}
