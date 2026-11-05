import Foundation

@main struct CombatEncounter68Tests {
    static func body(_ x:Float, radius:Float=11,mass:Float=2.4) -> CombatBody68 {
        CombatBody68(position:Vec2(x:x,y:360),
                     velocity:Vec2(x:0,y:0),mass:mass,radius:radius)
    }
    static func main() {
        let cfg=CombatBalance556.Difficulty.normal
        var first=CombatSurvival96()
        first.shieldCharges=1
        var encounter=CombatEncounter68(
            first:body(640),second:nil,
            rocks:[SphereAsteroid556(position:Vec2(x:660,y:360),
                     velocity:Vec2(x:0,y:0),radius:15,mass:8)],
            bugs:[],boss:nil,pickups:[],
            firstSurvival:first,secondSurvival:CombatSurvival96(),
            level:9,difficulty:cfg)
        let hit=encounter.contactPhase(dt:1/120,
                                       defenseFirst:.noneAbsorbed)
        precondition(hit.contacts == [.shipRock(0)])
        precondition(hit.damage == [
            CombatContactRouter96.TeamOutcome(player:.first,
                outcome:.applied(.shieldAbsorbed(
                    remaining:0,cause:"ASTEROIDA")))
        ])
        precondition(encounter.firstSurvival.lives==3 &&
                     encounter.firstSurvival.shieldCharges==0)
        let rockPosition=encounter.rocks[0].position
        precondition(rockPosition.x != 660)

        var unknown=CombatEncounter68(
            first:body(640),second:nil,
            rocks:[SphereAsteroid556(position:Vec2(x:660,y:360),
                     velocity:Vec2(x:0,y:0),radius:15,mass:8)],
            bugs:[],boss:nil,pickups:[],
            firstSurvival:CombatSurvival96(),
            secondSurvival:CombatSurvival96(),
            level:9,difficulty:cfg)
        let pending=unknown.contactPhase(dt:1/120)
        precondition(pending.contacts == [.shipRock(0)])
        precondition(pending.damage.first?.outcome == .requiresDefenseVerification)
        precondition(unknown.firstSurvival.lives==3 &&
                     unknown.firstSurvival.invincible==0)

        // WithSecond62 contact and pickup attraction remain active while
        // first player is down; lives and invulnerability are independent.
        var coop=CombatEncounter68(
            first:body(100),second:body(640),
            rocks:[],bugs:[body(663,radius:14,mass:3)],
            boss:nil,pickups:[body(710,radius:6,mass:0.15)],
            firstSurvival:CombatSurvival96(),
            secondSurvival:CombatSurvival96(),
            level:10,difficulty:cfg)
        let partnerResult=coop.contactPhase(dt:1/120,
            firstDown:true,secondDown:false,
            defenseSecond:.noneAbsorbed,robotFlags:[true])
        precondition(partnerResult.pickupsTrackingSecond==1)
        precondition(partnerResult.contacts == [.partnerBug(0)])
        precondition(partnerResult.damage == [
            CombatContactRouter96.TeamOutcome(player:.second,
                outcome:.applied(.lifeLost(
                    remaining:2,respawnProtection:3,
                    cause:"ROBOTYCZNY WAZ")))
        ])
        precondition(coop.firstSurvival.lives==3 &&
                     coop.secondSurvival.lives==2)
        precondition(coop.pickups[0].velocity.x<0)

        let frozen=coop.first.position
        let zero=coop.contactPhase(dt:0,firstDown:false,
                                   defenseFirst:.noneAbsorbed)
        precondition(zero.contacts.isEmpty && zero.damage.isEmpty)
        precondition(coop.first.position==frozen)

        // A game not in Playing mode does not move pickups or apply damage.
        coop.firstSurvival.playing=false
        let oldPickup=coop.pickups[0].position
        let blocked=coop.contactPhase(dt:0.5,firstDown:false,
                                      defenseFirst:.noneAbsorbed)
        precondition(blocked.contacts.isEmpty && blocked.damage.isEmpty)
        precondition(coop.pickups[0].position==oldPickup)
        print("PASS: integrated Physics68 pickup/contact/WithSecond62 -> ApplyHit96 shields/lives; verified defense and scene gates")
    }
}
