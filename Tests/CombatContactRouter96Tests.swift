import Foundation
@main struct CombatContactRouter96Tests {
    static func main() {
        typealias Router=CombatContactRouter96
        let events:[CombatSolidEvent68]=[.shipRock(0),.shipBug(0),
                                          .shipBoss,.bossRock(1)]
        var survival=CombatSurvival96()
        let unknown=Router.apply(events,to:&survival,level:10,
                                 difficulty:.normal,defense:.unverified,
                                 isRobot:[true])
        precondition(unknown == [.requiresDefenseVerification,
                                 .requiresDefenseVerification,
                                 .requiresDefenseVerification,
                                 .ignoredNonPlayer])
        precondition(survival.lives==3 && survival.shieldCharges==0)
        let external=Router.apply(events,to:&survival,level:10,
                                  difficulty:.normal,defense:.tarczaAbsorbed,
                                  isRobot:[true])
        precondition(external == [.externalDefenseAbsorbed,
                                  .externalDefenseAbsorbed,
                                  .externalDefenseAbsorbed,
                                  .ignoredNonPlayer])
        precondition(survival.lives==3)
        survival.shieldCharges=1
        let first=Router.apply(events,to:&survival,level:10,
                               difficulty:.normal,defense:.noneAbsorbed,
                               isRobot:[true])
        precondition(first == [
            .applied(.shieldAbsorbed(remaining:0,cause:"ASTEROIDA")),
            .applied(.ignored),.applied(.ignored),.ignoredNonPlayer
        ])
        precondition(survival.lives==3 && survival.invincible==1)
        survival.advance(dt:1)
        let second=Router.apply([.shipBug(0)],to:&survival,level:10,
                                difficulty:.normal,defense:.noneAbsorbed,
                                isRobot:[true])
        precondition(second == [
            .applied(.lifeLost(remaining:2,respawnProtection:3,
                               cause:"ROBOTYCZNY WAZ"))
        ])
        survival.advance(dt:3)
        let third=Router.apply([.shipBoss],to:&survival,level:10,
                               difficulty:.normal,defense:.noneAbsorbed,
                               isRobot:[true])
        precondition(third == [
            .applied(.lifeLost(remaining:1,respawnProtection:3,
                               cause:"ZDERZENIE Z BOSSEM"))
        ])
        var missing=CombatSurvival96()
        let noClassification=Router.apply([.shipBug(2)],to:&missing,
            level:1,difficulty:.easy,defense:.noneAbsorbed,isRobot:[false])
        precondition(noClassification == [.requiresDefenseVerification])
        precondition(missing.lives==3)
        precondition(Router.cause(.shipBug(0),isRobot:[false]) ==
                     "KOLIZJA ZE STATKIEM")
        print("PASS: Physics68 collision -> ApplyHit96 priority and causes, defense verification, shield/life/invincibility, boss/robot route")
    }
}
