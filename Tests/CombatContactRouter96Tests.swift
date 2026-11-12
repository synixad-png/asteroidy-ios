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
            .applied(.lifeLost(remaining:2,respawnProtection:3,
                               cause:"ASTEROIDA")),
            .applied(.ignored),.applied(.ignored),.ignoredNonPlayer
        ])
        precondition(survival.lives==2 && survival.invincible==3 &&
                     survival.shieldCharges==0,
                     "fatal unprotected hit clears reserves, not one-by-one")
        survival.advance(dt:1)
        let protected=Router.apply([.shipBug(0)],to:&survival,level:10,
                                   difficulty:.normal,defense:.noneAbsorbed,
                                   isRobot:[true])
        precondition(protected == [.applied(.ignored)] &&
                     survival.lives==2,"respawn immunity")
        survival.advance(dt:2)
        let second=Router.apply([.shipBug(0)],to:&survival,level:10,
                                difficulty:.normal,defense:.noneAbsorbed,
                                isRobot:[true])
        precondition(second == [
            .applied(.lifeLost(remaining:1,respawnProtection:3,
                               cause:"ROBOTYCZNY WAZ"))
        ])
        survival.advance(dt:3)
        let third=Router.apply([.shipBoss],to:&survival,level:10,
                               difficulty:.normal,defense:.noneAbsorbed,
                               isRobot:[true])
        precondition(third == [.applied(.gameOver(
                                    cause:"ZDERZENIE Z BOSSEM"))])
        // PC v608 reserves are NOT passive hit points: no matter whether
        // the verified collision is spherical, flat, rock or boss.
        for (event,flat) in [(CombatSolidEvent68.shipBoss,false),
                             (.shipRock(0),false),(.shipRock(0),true)] {
            var withReserve=CombatSurvival96()
            withReserve.shieldCharges=2
            let result=Router.apply([event],to:&withReserve,
                level:10,difficulty:.normal,defense:.noneAbsorbed,
                isRobot:[],spherical:!flat)
            precondition(result == [.applied(.lifeLost(
                remaining:2,respawnProtection:3,
                cause:event == .shipBoss ? "ZDERZENIE Z BOSSEM" : "ASTEROIDA"))])
            precondition(withReserve.shieldCharges==0 &&
                         withReserve.invincible==3)
        }
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
        print("PASS PC608: Physics68 validated defense, NO passive reserve hit, damage/lives/invincibility, boss/robot route")
    }
}
