import Foundation
@main struct CombatSurvival96Tests {
    static func main() {
        for level in 1...26 {
            for difficulty in CombatBalance556.Difficulty.allCases {
                let damage=CombatSurvival96.collisionDamage(level:level,difficulty:difficulty)
                let expected = level<=2 ? 18 : level<=4 ? 22 : level<=8 ? 26 :
                               difficulty == .easy ? 27 : difficulty == .hard ? 38 : 32
                precondition(damage==expected)
                let respawn=CombatSurvival96.respawnProtection(
                    level:level,difficulty:difficulty)
                let expectedProtection:Float = level<=4 ? 4.5 :
                               difficulty == .easy ? 4 :
                               difficulty == .hard ? 2 : 3
                precondition(respawn==expectedProtection)
            }
        }
        var survival=CombatSurvival96()
        survival.lives=3
        survival.shieldCharges=2
        let cause="ASTEROIDA"
        let damage=CombatSurvival96.collisionDamage(level:10,difficulty:.normal)
        // A purchased shield intercepts FLAT rock contacts before Damage().
        precondition(survival.absorbPurchasedRockContact(cause:cause) ==
                     .shieldAbsorbed(remaining:1,cause:cause))
        precondition(abs(survival.invincible-0.8)<0.0001 && survival.lives==3)
        precondition(survival.absorbPurchasedRockContact(cause:cause) == nil)
        survival.advance(dt:0.8)
        precondition(survival.absorbPurchasedRockContact(cause:cause) ==
                     .shieldAbsorbed(remaining:0,cause:cause))
        survival.advance(dt:0.8)
        precondition(survival.applyUnblockedCollision(level:10,difficulty:.normal,cause:cause,
                                                      damage:damage) ==
                     .lifeLost(remaining:2,respawnProtection:3,cause:cause))
        precondition(survival.lives==2 && survival.invincible==3)
        survival.advance(dt:3)
        precondition(survival.applyUnblockedCollision(level:10,difficulty:.normal,cause:cause,
                                                      damage:damage) ==
                     .lifeLost(remaining:1,respawnProtection:3,cause:cause))
        survival.advance(dt:3)
        precondition(survival.applyUnblockedCollision(level:10,difficulty:.normal,cause:cause,
                                                      damage:damage) == .gameOver(cause:cause))
        precondition(survival.lives==0 && !survival.playing)
        survival.advance(dt:20)
        precondition(survival.applyUnblockedCollision(level:10,difficulty:.normal,cause:cause,
                                                      damage:damage) == .ignored)

        // A bug or boss collision is NOT the shielded rock-contact branch.
        var unblocked=CombatSurvival96()
        unblocked.shieldCharges=3
        let boss=unblocked.applyUnblockedCollision(level:10,difficulty:.normal,
             cause:"BOSS",damage:damage)
        precondition(boss == .lifeLost(remaining:2,
                                      respawnProtection:3,cause:"BOSS"))
        precondition(unblocked.shieldCharges==0 && unblocked.lives==2)
        for guardFlag in 0..<4 {
            var blocked=CombatSurvival96()
            if guardFlag==0 {blocked.playing=false}
            else if guardFlag==1 {blocked.sceneBusy=true}
            else if guardFlag==2 {blocked.bossArrival=true}
            else {blocked.currentDown=true}
            precondition(blocked.applyUnblockedCollision(level:1,difficulty:.normal,
                cause:"KOLIZJA",damage:18) == .ignored)
            precondition(blocked.lives==3)
        }
        print("PASS: 78 original collision profiles, pre-Damage rock shield only, reset on hit, respawn and game over")
    }
}
