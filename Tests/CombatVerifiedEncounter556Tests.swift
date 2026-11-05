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

        // Independent player defense state in a real co-op Physics68 event.
        // The second player receives the collision; the first player's
        // guardian, armor and hull must remain entirely untouched.
        var twoPlayers=setup(true)
        twoPlayers.firstGuardian=CombatGuardian37(owned:true)
        twoPlayers.secondGuardian=CombatGuardian37(owned:true)
        twoPlayers.firstVitals=CombatTalentVitals78()
        twoPlayers.secondVitals=CombatTalentVitals78()
        let secondIntercept=twoPlayers.step(dt:1/120)
        precondition(secondIntercept.hitOutcomes == [
            V.TeamOutcome(player:.second,outcome:.guardianAbsorbed)])
        precondition(twoPlayers.firstGuardian!.charges == 1)
        precondition(twoPlayers.secondGuardian!.charges == 0)
        precondition(twoPlayers.firstVitals!.armor == 25 &&
                     twoPlayers.firstVitals!.hull == 60)
        precondition(twoPlayers.secondVitals!.armor == 25 &&
                     twoPlayers.secondVitals!.hull == 60)
        precondition(twoPlayers.encounter.firstSurvival.lives == 3 &&
                     twoPlayers.encounter.secondSurvival.lives == 3)
        twoPlayers.encounter.rocks=[]
        _=twoPlayers.step(dt:1.3)
        twoPlayers.encounter.second=body(640)
        twoPlayers.encounter.rocks=[rock()]
        let secondVitalsHit=twoPlayers.step(dt:1/120)
        precondition(secondVitalsHit.hitOutcomes == [
            V.TeamOutcome(player:.second,outcome:.talentAbsorbed)])
        precondition(twoPlayers.secondVitals!.armor == 0 &&
                     twoPlayers.secondVitals!.hull == 53)
        precondition(twoPlayers.firstVitals!.armor == 25 &&
                     twoPlayers.firstVitals!.hull == 60)
        precondition(twoPlayers.firstGuardian!.charges == 1)
        precondition(twoPlayers.encounter.firstSurvival.lives == 3 &&
                     twoPlayers.encounter.secondSurvival.lives == 3)
        precondition(secondVitalsHit.damageTransitions.isEmpty)

        // Real actor-body collisions, without pretending enemy AI is ported.
        // Physics68 must classify a verified robot contact and a boss-body
        // contact, preserve the correct original cause, and apply the
        // already-verified armor/hull reducer independently of weapon AI.
        var robotContact=setup()
        robotContact.encounter.rocks=[]
        robotContact.encounter.bugs=[body(659)]
        robotContact.firstGuardian=CombatGuardian37(owned:false)
        robotContact.firstVitals=CombatTalentVitals78()
        let robotHit=robotContact.step(dt:1/120,robotFlags:[true])
        precondition(robotHit.contacts == [.shipBug(0)])
        precondition(robotHit.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.talentAbsorbed)])
        precondition(robotContact.firstVitals!.armor == 0 &&
                     robotContact.firstVitals!.hull == 53)
        precondition(robotContact.encounter.firstSurvival.lives == 3)

        var bossContact=setup()
        bossContact.encounter.rocks=[]
        bossContact.encounter.boss=body(659)
        bossContact.firstGuardian=CombatGuardian37(owned:true)
        bossContact.firstVitals=CombatTalentVitals78()
        let bossHit=bossContact.step(dt:1/120)
        precondition(bossHit.contacts == [.shipBoss])
        precondition(bossHit.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.guardianAbsorbed)])
        precondition(bossContact.firstGuardian!.charges == 0)
        precondition(bossContact.firstVitals!.armor == 25 &&
                     bossContact.firstVitals!.hull == 60)
        precondition(bossContact.encounter.firstSurvival.lives == 3)

        // End-to-end collision harness: repeated real Physics68 contacts
        // drain armor -> hull, then cost exactly one life and reset gauges.
        // Every impact is separated by the actual immunity interval; no
        // synthetic .lifeLost outcome is injected into this test.
        var fatal=setup()
        fatal.firstGuardian=CombatGuardian37(owned:false)
        fatal.firstVitals=CombatTalentVitals78()
        for impact in 1...3 {
            if impact>1 {
                fatal.encounter.rocks=[]
                _=fatal.step(dt:3.2)
                fatal.encounter.first=body(640)
                fatal.encounter.rocks=[rock()]
            }
            let frame=fatal.step(dt:1/120)
            precondition(frame.contacts == [.shipRock(0)])
            if impact<3 {
                precondition(frame.hitOutcomes == [
                    V.TeamOutcome(player:.first,outcome:.talentAbsorbed)])
                precondition(frame.damageTransitions.isEmpty)
                let expectedHull=impact==1 ? 53 : 21
                precondition(fatal.firstVitals!.hull==expectedHull)
                precondition(fatal.firstVitals!.armor==0)
                precondition(fatal.encounter.firstSurvival.lives==3)
            } else {
                precondition(frame.hitOutcomes == [
                    V.TeamOutcome(player:.first,outcome:.applied(
                        .lifeLost(remaining:2,respawnProtection:3,
                                  cause:"ASTEROIDA")))])
                precondition(frame.damageTransitions == [
                    .respawned(removedShots:0,relocatedRocks:1)])
                precondition(fatal.encounter.firstSurvival.lives==2)
                precondition(fatal.firstVitals!.hull==60 &&
                             fatal.firstVitals!.armor==25)
                precondition(fatal.encounter.first.position==Vec2(x:640,y:360))
            }
        }

        // Three consecutive source lives in the *real* Physics68 encounter
        // are lost only after three armor/hull impacts each. Fatal contacts
        // reset vitals and the final contact transitions to GameOver, not a
        // fourth respawn. Unknown defenses remain explicitly opt-in.
        var campaignDeaths=setup()
        campaignDeaths.firstGuardian=CombatGuardian37(owned:false)
        campaignDeaths.firstVitals=CombatTalentVitals78()
        for life in 1...3 {
            for hitNo in 1...3 {
                if life>1 || hitNo>1 {
                    campaignDeaths.encounter.rocks=[]
                    _=campaignDeaths.step(dt:3.2)
                    campaignDeaths.encounter.first=body(640)
                    campaignDeaths.encounter.rocks=[rock()]
                }
                let frame=campaignDeaths.step(dt:1/120)
                precondition(frame.contacts == [.shipRock(0)])
                if hitNo<3 {
                    precondition(frame.hitOutcomes == [
                        V.TeamOutcome(player:.first,outcome:.talentAbsorbed)])
                    precondition(frame.damageTransitions.isEmpty)
                } else if life<3 {
                    precondition(frame.hitOutcomes == [
                        V.TeamOutcome(player:.first,outcome:.applied(
                            .lifeLost(remaining:3-life,
                                      respawnProtection:3,
                                      cause:"ASTEROIDA")))])
                    precondition(frame.damageTransitions == [
                        .respawned(removedShots:0,relocatedRocks:1)])
                    precondition(campaignDeaths.encounter.firstSurvival.playing)
                } else {
                    precondition(frame.hitOutcomes == [
                        V.TeamOutcome(player:.first,outcome:.applied(
                            .gameOver(cause:"ASTEROIDA")))])
                    precondition(frame.damageTransitions == [
                        .gameOver(removedShots:0)])
                    precondition(!campaignDeaths.encounter.firstSurvival.playing)
                }
            }
            precondition(campaignDeaths.encounter.firstSurvival.lives == 3-life)
            precondition(campaignDeaths.firstVitals!.armor == 25 &&
                         campaignDeaths.firstVitals!.hull == 60)
        }
        let postGame=campaignDeaths.step(dt:1/120)
        precondition(postGame.contacts.isEmpty && postGame.hitOutcomes.isEmpty)
        precondition(campaignDeaths.encounter.firstSurvival.lives == 0)

        // Cooperative hull must be exhausted before the real 12-second
        // rescue wreck. The earlier .clear-only fixture tests routing, not
        // an actual Talents78-backed ship. Keep both players' lives intact.
        var cooperativeVitals=setup(true)
        cooperativeVitals.firstGuardian=CombatGuardian37(owned:false)
        cooperativeVitals.secondGuardian=CombatGuardian37(owned:false)
        cooperativeVitals.firstVitals=CombatTalentVitals78()
        cooperativeVitals.secondVitals=CombatTalentVitals78()
        for impact in 1...3 {
            if impact>1 {
                cooperativeVitals.encounter.rocks=[]
                _=cooperativeVitals.step(dt:1.1)
                cooperativeVitals.encounter.second=body(640)
                cooperativeVitals.encounter.rocks=[rock()]
            }
            let frame=cooperativeVitals.step(dt:1/120)
            precondition(frame.contacts == [.partnerRock(0)])
            if impact<3 {
                precondition(frame.hitOutcomes == [
                    V.TeamOutcome(player:.second,outcome:.talentAbsorbed)])
                precondition(!cooperativeVitals.rescue.down(.second))
            } else {
                precondition(frame.hitOutcomes == [
                    V.TeamOutcome(player:.second,outcome:.downForRescue)])
                precondition(cooperativeVitals.rescue.down(.second))
                precondition(cooperativeVitals.encounter.secondSurvival.currentDown)
                precondition(cooperativeVitals.encounter.secondSurvival.lives == 3)
            }
            precondition(cooperativeVitals.encounter.firstSurvival.lives == 3)
            precondition(cooperativeVitals.firstVitals!.armor == 25 &&
                         cooperativeVitals.firstVitals!.hull == 60)
        }

        // The original unknown-defense contract stays unchanged by
        // the optional integration; nil states still require verification.
        print("PASS: integrated Physics68 -> Tarcza145 -> verified damage -> 160/220 respawn and Gameplay65 2s co-op rescue")
    }
}
