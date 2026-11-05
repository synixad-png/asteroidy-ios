import Foundation

@main struct CombatVerifiedEncounter556Tests {
    static func body(_ x:Float) -> CombatBody68 {
        CombatBody68(position:Vec2(x:x,y:360),
                     velocity:Vec2(x:0,y:0),mass:2.4,radius:11)
    }
    static func rock() -> SphereAsteroid556 {
        SphereAsteroid556(position:Vec2(x:659,y:360),
            velocity:Vec2(x:0,y:0),radius:15,mass:8)
    }
    static func setup(_ partner:Bool=false) -> CombatVerifiedEncounter556 {
        let scene=CombatEncounter68(first:body(partner ? 100 : 640),
            second:partner ? body(640) : nil,rocks:[rock()],bugs:[],
            boss:nil,pickups:[],firstSurvival:CombatSurvival96(),
            secondSurvival:CombatSurvival96(),level:10,difficulty:.normal)
        return CombatVerifiedEncounter556(encounter:scene)
    }
    static func main() {
        typealias V=CombatVerifiedHit556
        var shielded=setup()
        shielded.encounter.firstSurvival.shieldCharges=2
        let active=shielded.step(dt:1/120,firstDomeHeld:true)
        precondition(active.contacts==[.shipRock(0)])
        precondition(active.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.activeTarczaAbsorbed)])
        precondition(active.damageTransitions.isEmpty)
        precondition(shielded.encounter.firstSurvival.shieldCharges==2)
        precondition(shielded.encounter.firstSurvival.lives==3)
        precondition(shielded.domeFirst.energy<25)

        // Unverified guardian/talent must leave every player alive.
        var uncertain=setup()
        let unresolved=uncertain.step(dt:1/120)
        precondition(unresolved.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.requiresGuardianVerification)])
        precondition(uncertain.encounter.firstSurvival.lives==3)

        // A fully verified solo collision takes a life, clears shots and
        // moves dangerously close asteroids outside the source 160-unit zone.
        var solo=setup()
        solo.shots=[SphereBolt556(position:Vec2(x:650,y:365),
                                  velocity:Vec2(x:10,y:0),life:1)]
        let dead=solo.step(dt:1/120,
            guardianFirst:.clear,talentFirst:.clear)
        precondition(dead.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.applied(
                .lifeLost(remaining:2,respawnProtection:3,cause:"ASTEROIDA")))])
        precondition(dead.damageTransitions == [
            .respawned(removedShots:1,relocatedRocks:1)])
        precondition(solo.shots.isEmpty)
        precondition(solo.encounter.first.position==Vec2(x:640,y:360))
        precondition(solo.encounter.first.velocity.lengthSquared==0)
        let distance=sqrt(Sphere67.delta(
            target:solo.encounter.rocks[0].position,
            origin:solo.encounter.first.position).lengthSquared)
        precondition(abs(distance-220)<0.5)

        // Actual co-op contact must lead to the Gameplay65 12-second wreck,
        // not a loss of life, and the partner can subsequently rescue.
        var coop=setup(true)
        let wreck=coop.step(dt:1/120,
            guardianFirst:.clear,guardianSecond:.clear,
            talentFirst:.clear,talentSecond:.clear)
        precondition(wreck.contacts==[.partnerRock(0)])
        precondition(wreck.hitOutcomes==[
            V.TeamOutcome(player:.second,outcome:.downForRescue)])
        precondition(coop.rescue.down(.second))
        precondition(coop.encounter.secondSurvival.lives==3)
        coop.encounter.rocks=[]
        coop.encounter.first=body(675)
        var rescued=false
        for _ in 0..<150 {
            let step=coop.step(dt:1/60,firstFiring:true,
                guardianFirst:.clear,guardianSecond:.clear,
                talentFirst:.clear,talentSecond:.clear)
            if step.rescueEvent == .rescued(.second) {rescued=true;break}
        }
        precondition(rescued && !coop.rescue.down(.second))
        precondition(coop.encounter.secondSurvival.lives==3)
        precondition(coop.encounter.secondSurvival.invincible==3)

        // Repeated zero-dt steps must not double charge a dome or lose lives.
        let e=coop.domeFirst.energy
        let idle=coop.step(dt:0,firstDomeHeld:true,
                           guardianFirst:.clear,talentFirst:.clear)
        precondition(idle.contacts.isEmpty && idle.hitOutcomes.isEmpty)
        precondition(coop.domeFirst.energy==e)
        // Actual defenses, not caller-declared .clear flags:
        // purchased shield -> one-charge Guardian37 -> Talents78 armor/hull.
        var defended=setup()
        defended.encounter.firstSurvival.shieldCharges=1
        defended.firstGuardian=CombatGuardian37(owned:true)
        defended.firstVitals=CombatTalentVitals78()
        let purchased=defended.step(dt:1/120)
        precondition(purchased.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.applied(
                .shieldAbsorbed(remaining:0,cause:"ASTEROIDA")))])
        precondition(defended.firstGuardian!.charges==1)
        precondition(defended.firstVitals!.armor==25 &&
                     defended.firstVitals!.hull==60)
        defended.encounter.rocks=[]
        _=defended.step(dt:1.1)
        defended.encounter.first=body(640)
        defended.encounter.rocks=[rock()]
        let guardianHit=defended.step(dt:1/120)
        precondition(guardianHit.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.guardianAbsorbed)])
        precondition(defended.firstGuardian!.charges==0)
        precondition(defended.firstVitals!.armor==25 &&
                     defended.firstVitals!.hull==60)
        defended.encounter.rocks=[]
        _=defended.step(dt:1.3)
        defended.encounter.first=body(640)
        defended.encounter.rocks=[rock()]
        let talentHit=defended.step(dt:1/120)
        precondition(talentHit.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.talentAbsorbed)])
        precondition(defended.firstVitals!.armor==0 &&
                     defended.firstVitals!.hull==53)
        precondition(defended.encounter.firstSurvival.lives==3)
        precondition(talentHit.damageTransitions.isEmpty)

        // The original unknown-defense contract stays unchanged by
        // the optional integration; nil states still require verification.
        print("PASS: integrated Physics68 -> Tarcza145 -> verified damage -> 160/220 respawn and Gameplay65 2s co-op rescue")
    }
}
