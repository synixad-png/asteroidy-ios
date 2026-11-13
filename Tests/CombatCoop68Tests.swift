import Foundation

@main struct CombatCoop68Tests {
    static func body(_ x:Float,_ mass:Float=2.4) -> CombatBody68 {
        CombatBody68(position:Vec2(x:x,y:360),velocity:Vec2(x:0,y:0),
                     mass:mass,radius:11)
    }
    static func main() {
        let origin=Vec2(x:640,y:360)
        let cfgLevel=10
        let rock=SphereAsteroid556(position:Vec2(x:659,y:360),
                                    velocity:Vec2(x:0,y:0),radius:14,mass:8)
        do {
            var ship=body(100),partner:CombatBody68?=body(640)
            var rocks=[rock],bugs=[CombatBody68](),boss:CombatBody68?=nil
            let events=CombatSolids68.step(ship:&ship,rocks:&rocks,bugs:&bugs,
                boss:&boss,partner:&partner,shipDown:true)
            precondition(events == [.partnerRock(0)])
            precondition(ship.position.x == 100)
            precondition(partner!.position != origin)
        }
        do {
            var ship=body(100),partner:CombatBody68?=body(640)
            var rocks=[SphereAsteroid556](),
                bugs=[body(659,3)],boss:CombatBody68?=nil
            let events=CombatSolids68.step(ship:&ship,rocks:&rocks,bugs:&bugs,
                boss:&boss,partner:&partner,shipDown:true)
            precondition(events == [.partnerBug(0)])
        }
        do {
            var ship=body(100),partner:CombatBody68?=body(640)
            var rocks=[SphereAsteroid556](),bugs=[CombatBody68]()
            var boss:CombatBody68?=CombatBody68(
                position:Vec2(x:665,y:360),velocity:Vec2(x:0,y:0),mass:80,radius:22)
            let events=CombatSolids68.step(ship:&ship,rocks:&rocks,bugs:&bugs,
                boss:&boss,partner:&partner,shipDown:true)
            precondition(events == [.partnerBoss])
        }
        do {
            var ship=body(640),partner:CombatBody68?=body(640)
            var rocks=[rock],bugs=[CombatBody68](),boss:CombatBody68?=nil
            let events=CombatSolids68.step(ship:&ship,rocks:&rocks,bugs:&bugs,
                boss:&boss,partner:&partner,partnerDown:true)
            precondition(events == [.shipRock(0)])
        }
        typealias R=CombatContactRouter96
        precondition(R.player(for:.partnerBoss) == .second)
        precondition(R.player(for:.partnerRock(0)) == .second)
        precondition(R.player(for:.bugRock(0,0)) == nil)
        var first=CombatSurvival96(),second=CombatSurvival96()
        first.shieldCharges=1
        second.shieldCharges=0
        let events:[CombatSolidEvent68]=[.shipRock(0),.partnerBug(0),
                                           .bossRock(1),.partnerBoss,.shipBoss]
        let results=R.applyTeam(events,first:&first,second:&second,
            level:cfgLevel,difficulty:.normal,defenseFirst:.noneAbsorbed,
            defenseSecond:.noneAbsorbed,isRobot:[true])
        precondition(results == [
            R.TeamOutcome(player:.first,outcome:.applied(
                .lifeLost(remaining:2,respawnProtection:3,cause:"ASTEROIDA"))),
            R.TeamOutcome(player:.second,outcome:.applied(
                .lifeLost(remaining:2,respawnProtection:3,cause:"ROBOTYCZNY WAZ"))),
            R.TeamOutcome(player:nil,outcome:.ignoredNonPlayer),
            R.TeamOutcome(player:.second,outcome:.applied(.ignored)),
            R.TeamOutcome(player:.first,outcome:.applied(.ignored))
        ])
        precondition(first.lives==2 && first.shieldCharges==0)
        precondition(second.lives==2 && second.invincible==3)
        first.advance(dt:3)
        second.advance(dt:3)
        let next=R.applyTeam([.shipBoss,.partnerRock(0)],
            first:&first,second:&second,level:cfgLevel,difficulty:.normal,
            defenseFirst:.noneAbsorbed,defenseSecond:.guardianAbsorbed,
            isRobot:[false])
        precondition(next == [
            R.TeamOutcome(player:.first,outcome:.applied(
                .lifeLost(remaining:1,respawnProtection:3,cause:"ZDERZENIE Z BOSSEM"))),
            R.TeamOutcome(player:.second,outcome:.externalDefenseAbsorbed)
        ])
        precondition(second.lives==2 && first.lives==1)
        let pending=R.applyTeam([.partnerRock(0)],first:&first,second:&second,
            level:cfgLevel,difficulty:.normal,defenseFirst:.noneAbsorbed,
            defenseSecond:.unverified,isRobot:[])
        precondition(pending == [
            R.TeamOutcome(player:.second,outcome:.requiresDefenseVerification)
        ])
        precondition(second.lives==2)
        print("PASS: Physics68 WithSecond62 partner rock/bug/boss contacts; independent down, lives, shields, immunity and verified guards")
    }
}
