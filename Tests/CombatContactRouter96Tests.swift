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
        // HitByBoss shields all ApplyHit96 causes for one second,
        // whereas the flat asteroid interception grants only .8 seconds.
        var bossShield=CombatSurvival96()
        bossShield.shieldCharges=2
        let bossResult=Router.apply([.shipBoss],to:&bossShield,
            level:10,difficulty:.normal,defense:.noneAbsorbed,isRobot:[])
        precondition(bossResult == [
            .applied(.shieldAbsorbed(remaining:1,cause:"ZDERZENIE Z BOSSEM"))
        ])
        precondition(bossShield.lives==3 && bossShield.invincible==1)
        var sphereShield=CombatSurvival96()
        sphereShield.shieldCharges=1
        let sphereRock=Router.apply([.shipRock(0)],to:&sphereShield,
            level:10,difficulty:.normal,defense:.noneAbsorbed,isRobot:[],
            spherical:true)
        precondition(sphereRock == [
            .applied(.shieldAbsorbed(remaining:0,cause:"ASTEROIDA"))
        ])
        precondition(sphereShield.invincible==1)
        var flatShield=CombatSurvival96()
        flatShield.shieldCharges=1
        let flatRock=Router.apply([.shipRock(0)],to:&flatShield,
            level:10,difficulty:.normal,defense:.noneAbsorbed,isRobot:[],
            spherical:false)
        precondition(flatRock == [
            .applied(.shieldAbsorbed(remaining:0,cause:"ASTEROIDA"))
        ])
        precondition(abs(flatShield.invincible-0.8)<0.0001)
        var unshielded=CombatSurvival96()
        unshielded.shieldCharges=2
        let damageOnly=unshielded.applyUnblockedCollision(
            level:10,difficulty:.normal,cause:"BOSS",damage:32)
        precondition(damageOnly == .lifeLost(
            remaining:2,respawnProtection:3,cause:"BOSS"))
        precondition(unshielded.shieldCharges==0)

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
