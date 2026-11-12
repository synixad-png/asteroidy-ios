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
        let cause="ASTEROIDA"
        let damage=CombatSurvival96.collisionDamage(level:10,difficulty:.normal)
        var survival=CombatSurvival96()
        survival.lives=3
        survival.shieldCharges=2

        // V608 removed all passive reserve-hit interception. If this
        // reducer is reached, real armor/hull/guardian/Tarcza checks have
        // already failed; lost life clears reserves via Game.Damage.
        precondition(survival.applyUnblockedCollision(
            level:10,difficulty:.normal,cause:cause,damage:damage) ==
            .lifeLost(remaining:2,respawnProtection:3,cause:cause))
        precondition(survival.shieldCharges==0 &&
                     survival.lives==2 && survival.invincible==3)
        precondition(survival.applyUnblockedCollision(
            level:10,difficulty:.normal,cause:cause,damage:damage) == .ignored)
        survival.advance(dt:3)
        precondition(survival.applyUnblockedCollision(
            level:10,difficulty:.normal,cause:cause,damage:damage) ==
            .lifeLost(remaining:1,respawnProtection:3,cause:cause))
        survival.advance(dt:3)
        precondition(survival.applyUnblockedCollision(
            level:10,difficulty:.normal,cause:cause,damage:damage) ==
            .gameOver(cause:cause))
        precondition(survival.lives==0 && !survival.playing)
        survival.advance(dt:20)
        precondition(survival.applyUnblockedCollision(
            level:10,difficulty:.normal,cause:cause,damage:damage) == .ignored)

        var other=CombatSurvival96()
        other.shieldCharges=3
        other.currentDown=true
        precondition(other.applyUnblockedCollision(
            level:10,difficulty:.normal,cause:"BOSS",damage:damage) == .ignored)
        precondition(other.shieldCharges==3,
                     "blocked hit cannot spend any full reserve bar")
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
        print("PASS PC608: 78 collision profiles, NO passive reserve interception, death clears charges, respawn/game over guards")
    }
}
