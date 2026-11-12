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
        // Historical independent diagnostics are explicit. Production
        // two-player encounters default to source Coop62 shared resources.
        return CombatVerifiedEncounter556(encounter:scene,
            independentDiagnosticCoop:partner)
    }
    static func main() {
        typealias V=CombatVerifiedHit556
        var shielded=setup()
        shielded.encounter.firstSurvival.shieldCharges=2
        let active=shielded.step(dt:1/120,firstDomeHeld:true,
                                 guardianFirst:.clear)
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
        // Exact PC609 Game.Damage: Guardian37 first, then held
        // Tarcza145, then Talents78 armor/hull (no passive reserves).
        var defended=setup()
        defended.encounter.firstSurvival.shieldCharges=1
        defended.firstGuardian=CombatGuardian37(owned:true)
        defended.firstVitals=CombatTalentVitals78()
        let purchased=defended.step(dt:1/120,firstDomeHeld:true)
        precondition(purchased.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.guardianAbsorbed)])
        precondition(defended.encounter.firstSurvival.shieldCharges==1)
        precondition(defended.firstGuardian!.charges==0)
        precondition(defended.domeFirst.energy>59 &&
                     defended.domeFirst.energy<60)
        precondition(defended.firstVitals!.armor==25 &&
                     defended.firstVitals!.hull==60)
        defended.encounter.rocks=[]
        // PC Guardian37 protection is 1.2s, longer than the removed
        // purchased shield's 1.0s; do not test a hit during immunity.
        _=defended.step(dt:1.3)
        defended.encounter.first=body(640)
        defended.encounter.rocks=[rock()]
        let guardianHit=defended.step(dt:1/120,firstDomeHeld:true)
        precondition(guardianHit.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.activeTarczaAbsorbed)])
        precondition(defended.firstGuardian!.charges==0)
        precondition(defended.encounter.firstSurvival.shieldCharges==1)
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
        for impact in 1...4 {
            if impact>1 {
                fatal.encounter.rocks=[]
                _=fatal.step(dt:3.2)
                fatal.encounter.first=body(640)
                fatal.encounter.rocks=[rock()]
            }
            let frame=fatal.step(dt:1/120)
            precondition(frame.contacts == [.shipRock(0)])
            if impact<4 {
                precondition(frame.hitOutcomes == [
                    V.TeamOutcome(player:.first,outcome:.talentAbsorbed)])
                precondition(frame.damageTransitions.isEmpty)
                // PC609 regenerates 6 armor points between 3.2s contacts.
                // Thus hull takes 7, then 26, then 26, and the fourth
                // collision finally causes the genuine life loss.
                let expectedHull=impact==1 ? 53 : impact==2 ? 27 : 1
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
        // are lost only after FOUR hits each, since v609 regenerates 6 armor
        // points during every 3.2s gap. Fatal contacts
        // reset vitals and the final contact transitions to GameOver, not a
        // fourth respawn. Unknown defenses remain explicitly opt-in.
        var campaignDeaths=setup()
        campaignDeaths.firstGuardian=CombatGuardian37(owned:false)
        campaignDeaths.firstVitals=CombatTalentVitals78()
        for life in 1...3 {
            for hitNo in 1...4 {
                if life>1 || hitNo>1 {
                    campaignDeaths.encounter.rocks=[]
                    _=campaignDeaths.step(dt:3.2)
                    campaignDeaths.encounter.first=body(640)
                    campaignDeaths.encounter.rocks=[rock()]
                }
                let frame=campaignDeaths.step(dt:1/120)
                precondition(frame.contacts == [.shipRock(0)])
                if hitNo<4 {
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

        // Gameplay65 explicitly disables rescue progress while the developer
        // menu is open. The encounter must forward the real flag instead of
        // hardcoding false, then resume the original two-second requirement.
        var menuGate=setup(true)
        let menuWreck=menuGate.step(dt:1/120,
            guardianFirst:.clear,guardianSecond:.clear,
            talentFirst:.clear,talentSecond:.clear)
        precondition(menuWreck.hitOutcomes == [
            V.TeamOutcome(player:.second,outcome:.downForRescue)])
        menuGate.encounter.rocks=[]
        menuGate.encounter.first=body(675)
        for _ in 0..<150 {
            let blocked=menuGate.step(dt:1/60,firstFiring:true,
                devOpen:true,guardianFirst:.clear,guardianSecond:.clear,
                talentFirst:.clear,talentSecond:.clear)
            precondition(blocked.rescueEvent == .none)
        }
        precondition(menuGate.rescue.down(.second))
        precondition(menuGate.rescue.progress == 0)
        var menuRescued=false
        for _ in 0..<150 {
            let frame=menuGate.step(dt:1/60,firstFiring:true,
                devOpen:false,guardianFirst:.clear,guardianSecond:.clear,
                talentFirst:.clear,talentSecond:.clear)
            if frame.rescueEvent == .rescued(.second) {
                menuRescued=true
                break
            }
        }
        precondition(menuRescued && !menuGate.rescue.down(.second))
        precondition(menuGate.encounter.secondSurvival.lives == 3)

        // Original Gameplay65.FailRescue65 directly calls Game.Damage,
        // bypassing ApplyHit96/HitByBoss and the wreck's immunity timer.
        // With unknown guard/talent owners, the exact transition stays
        // pending rather than guessing that no protection exists.
        var failedRescue=setup(true)
        let failedStart=failedRescue.step(dt:1/120,
            guardianFirst:.clear,guardianSecond:.clear,
            talentFirst:.clear,talentSecond:.clear)
        precondition(failedStart.hitOutcomes == [
            V.TeamOutcome(player:.second,outcome:.downForRescue)])
        failedRescue.encounter.rocks=[]
        let expired=failedRescue.step(dt:12.1)
        precondition(expired.rescueEvent == .failed(first:false,second:true))
        precondition(expired.requiresRescueDamageResolution)
        precondition(expired.rescueDamageOutcome ==
                     V.TeamOutcome(player:.second,
                        outcome:.requiresGuardianVerification))
        precondition(failedRescue.pendingRescueFailure ==
                     .failed(first:false,second:true))
        precondition(failedRescue.encounter.secondSurvival.lives==3)
        let blocked=failedRescue.step(dt:1/60)
        precondition(blocked.contacts.isEmpty && blocked.hitOutcomes.isEmpty)
        precondition(blocked.requiresRescueDamageResolution)
        // The source's direct Damage() path does NOT spend the bought
        // HitByBoss shield; an unblocked fatal hit instead clears charges.
        failedRescue.encounter.secondSurvival.shieldCharges=1
        let resolved=failedRescue.step(dt:1/60,
            guardianSecond:.clear,talentSecond:.clear)
        precondition(resolved.rescueDamageOutcome ==
            V.TeamOutcome(player:.second,outcome:.applied(
                .lifeLost(remaining:2,respawnProtection:3,
                          cause:"ZDERZENIE"))))
        precondition(resolved.damageTransitions == [
            .respawned(removedShots:0,relocatedRocks:0)])
        precondition(!resolved.requiresRescueDamageResolution)
        precondition(failedRescue.pendingRescueFailure == nil)
        precondition(failedRescue.encounter.secondSurvival.lives == 2)
        precondition(failedRescue.encounter.secondSurvival.shieldCharges == 0)
        precondition(failedRescue.encounter.secondSurvival.invincible == 3)

        // Real co-op armor/hull already exhausted on the third contact:
        // a timed-out wreck invokes the same Damage() controller and
        // resets exactly the affected player's vitals after life loss.
        cooperativeVitals.encounter.rocks=[]
        let actualFailure=cooperativeVitals.step(dt:12.1)
        precondition(actualFailure.rescueEvent ==
                     .failed(first:false,second:true))
        precondition(actualFailure.rescueDamageOutcome ==
            V.TeamOutcome(player:.second,outcome:.applied(
                .lifeLost(remaining:2,respawnProtection:3,
                          cause:"ZDERZENIE"))))
        precondition(actualFailure.damageTransitions == [
            .respawned(removedShots:0,relocatedRocks:0)])
        precondition(!actualFailure.requiresRescueDamageResolution)
        precondition(cooperativeVitals.secondVitals!.armor == 25 &&
                     cooperativeVitals.secondVitals!.hull == 60)
        precondition(cooperativeVitals.encounter.secondSurvival.lives == 2)
        precondition(cooperativeVitals.encounter.firstSurvival.lives == 3)

        // Original FailRescue65(true,true) calls Damage() ONCE for
        // player 1, then moves player 2 by +85 and grants 3 s immunity.
        var doubleWreck=setup(true)
        var firstWreck=doubleWreck.encounter.first
        var firstSurvival=doubleWreck.encounter.firstSurvival
        precondition(doubleWreck.rescue.beginDown(.first,cooperative:true,
            playing:true,developerInfinite:false,rescueDamage:false,
            survival:&firstSurvival,body:&firstWreck))
        doubleWreck.encounter.first=firstWreck
        doubleWreck.encounter.firstSurvival=firstSurvival
        var secondWreck=doubleWreck.encounter.second!
        var secondSurvival=doubleWreck.encounter.secondSurvival
        precondition(doubleWreck.rescue.beginDown(.second,cooperative:true,
            playing:true,developerInfinite:false,rescueDamage:false,
            survival:&secondSurvival,body:&secondWreck))
        doubleWreck.encounter.second=secondWreck
        doubleWreck.encounter.secondSurvival=secondSurvival
        doubleWreck.encounter.rocks=[]
        let bothFailed=doubleWreck.step(dt:1/60,
            guardianFirst:.clear,talentFirst:.clear)
        precondition(bothFailed.rescueEvent == .failed(first:true,second:true))
        precondition(bothFailed.rescueDamageOutcome ==
            V.TeamOutcome(player:.first,outcome:.applied(
                .lifeLost(remaining:2,respawnProtection:3,
                          cause:"ZDERZENIE"))))
        precondition(doubleWreck.encounter.firstSurvival.lives == 2)
        precondition(doubleWreck.encounter.secondSurvival.lives == 3)
        precondition(doubleWreck.encounter.secondSurvival.invincible == 3)
        precondition(doubleWreck.encounter.second!.velocity.lengthSquared == 0)
        let partnerGap=Sphere67.delta(
            target:doubleWreck.encounter.second!.position,
            origin:doubleWreck.encounter.first.position)
        precondition(abs(sqrt(partnerGap.lengthSquared)-85)<0.6)

        // Windows Gameplay65.StepRescue65: after real armor/hull wreck,
        // a two-second partner rescue restores ResetVitals78 for either
        // rescued ship, not merely the 3-second immunity and velocity.
        for wreckFirst in [false,true] {
            var restored=setup(true)
            restored.firstGuardian=CombatGuardian37(owned:false)
            restored.secondGuardian=CombatGuardian37(owned:false)
            restored.firstVitals=CombatTalentVitals78()
            restored.secondVitals=CombatTalentVitals78()
            restored.encounter.first=body(wreckFirst ? 640 : 100)
            restored.encounter.second=body(wreckFirst ? 100 : 640)
            for impact in 1...3 {
                if impact>1 {
                    restored.encounter.rocks=[]
                    _=restored.step(dt:1.1)
                    if wreckFirst {
                        restored.encounter.first=body(640)
                    } else {
                        restored.encounter.second=body(640)
                    }
                    restored.encounter.rocks=[rock()]
                }
                let frame=restored.step(dt:1/120)
                let expected:CombatSolidEvent68 =
                    wreckFirst ? .shipRock(0) : .partnerRock(0)
                precondition(frame.contacts == [expected])
                let hit=frame.hitOutcomes
                let player:CombatContactRouter96.Player =
                    wreckFirst ? .first : .second
                precondition(hit == [
                    V.TeamOutcome(player:player,outcome:
                        impact<3 ? .talentAbsorbed : .downForRescue)])
            }
            let gauge=wreckFirst ? restored.firstVitals! :
                                  restored.secondVitals!
            precondition(gauge.armor==0 && gauge.hull==0)
            let who:CombatRescue65.Player =
                wreckFirst ? .first : .second
            precondition(restored.rescue.down(who))
            restored.encounter.rocks=[]
            if wreckFirst {
                restored.encounter.second=body(675)
            } else {
                restored.encounter.first=body(675)
            }
            var saved=false
            for _ in 0..<150 {
                let frame=restored.step(dt:1/60,
                    firstFiring:!wreckFirst,secondFiring:wreckFirst)
                if frame.rescueEvent == .rescued(who) {
                    saved=true
                    break
                }
            }
            precondition(saved && !restored.rescue.down(who))
            precondition(gauge.armor==25 && gauge.hull==60)
            precondition(restored.encounter.firstSurvival.lives==3 &&
                         restored.encounter.secondSurvival.lives==3)
            precondition(restored.pendingRescueFailure == nil)
        }

        // Source Coop62.WithSecond62 deliberately shares Game.Lives,
        // ShieldCharges, GuardianCharges, Hull78 and Armor78, but keeps
        // the two ships' immunity timers distinct. This opt-in verified
        // mode must NOT give the second ship extra lives/shields/armor.
        var common=setup(true)
        common.sourceSharedCoopResources=true
        common.firstGuardian=CombatGuardian37(owned:false)
        common.firstVitals=CombatTalentVitals78()
        common.encounter.firstSurvival.shieldCharges=1
        let bought=common.step(dt:1/120,firstDomeHeld:true)
        precondition(bought.hitOutcomes == [
            V.TeamOutcome(player:.second,outcome:.activeTarczaAbsorbed)])
        precondition(common.encounter.firstSurvival.shieldCharges==1 &&
                     common.encounter.secondSurvival.shieldCharges==1)
        precondition(common.encounter.firstSurvival.invincible==0 &&
                     common.encounter.secondSurvival.invincible>=0.28)
        precondition(common.firstVitals!.armor==25 &&
                     common.firstVitals!.hull==60)
        // P1 hits the rock while P2 still has personal immunity. The
        // Dome is released: reserve 1/3 cannot passively shield P1.
        common.encounter.rocks=[]
        common.encounter.first=body(640)
        common.encounter.second=body(100)
        common.encounter.rocks=[rock()]
        let p1Damage=common.step(dt:1/120)
        precondition(p1Damage.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.talentAbsorbed)])
        precondition(common.firstVitals!.armor==0 &&
                     common.firstVitals!.hull==53)
        common.encounter.rocks=[]
        _=common.step(dt:1.1)
        common.encounter.first=body(100)
        common.encounter.second=body(640)
        common.encounter.rocks=[rock()]
        let p2Damage=common.step(dt:1/120)
        precondition(p2Damage.hitOutcomes == [
            V.TeamOutcome(player:.second,outcome:.talentAbsorbed)])
        precondition(common.firstVitals!.armor==0 &&
                     common.firstVitals!.hull==21)
        common.encounter.rocks=[]
        _=common.step(dt:1.1)
        common.encounter.first=body(640)
        common.encounter.second=body(100)
        common.encounter.rocks=[rock()]
        let p1Wreck=common.step(dt:1/120)
        precondition(p1Wreck.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.downForRescue)])
        precondition(common.rescue.down(.first))
        precondition(common.firstVitals!.hull==0)
        common.encounter.rocks=[]
        let sharedFail=common.step(dt:12.1)
        precondition(sharedFail.rescueEvent ==
                     .failed(first:true,second:false))
        precondition(sharedFail.rescueDamageOutcome ==
            V.TeamOutcome(player:.first,outcome:.applied(
                .lifeLost(remaining:2,respawnProtection:3,
                          cause:"ZDERZENIE"))))
        precondition(common.encounter.firstSurvival.lives==2 &&
                     common.encounter.secondSurvival.lives==2)
        precondition(common.firstVitals!.hull==60 &&
                     common.firstVitals!.armor==25)
        precondition(common.pendingRescueFailure==nil)

        // Global resources must also remain coherent within the SAME
        // Physics68 frame: P1 uses the held active dome, then P2
        // consumes the single Campaign37 guardian interception. Neither
        // player gets a duplicate copy of either protection.
        let separateRocks=[
            SphereAsteroid556(position:Vec2(x:319,y:360),
                              velocity:Vec2(x:0,y:0),radius:15,mass:8),
            SphereAsteroid556(position:Vec2(x:659,y:360),
                              velocity:Vec2(x:0,y:0),radius:15,mass:8)
        ]
        let sharedFrameScene=CombatEncounter68(first:body(300),
            second:body(640),rocks:separateRocks,bugs:[],boss:nil,
            pickups:[],firstSurvival:CombatSurvival96(),
            secondSurvival:CombatSurvival96(),
            level:10,difficulty:.normal)
        var simultaneous=CombatVerifiedEncounter556(encounter:sharedFrameScene)
        simultaneous.sourceSharedCoopResources=true
        simultaneous.firstGuardian=CombatGuardian37(owned:true)
        simultaneous.firstVitals=CombatTalentVitals78()
        simultaneous.encounter.firstSurvival.shieldCharges=1
        let twoImpacts=simultaneous.step(dt:1/120,firstDomeHeld:true)
        precondition(twoImpacts.contacts ==
                     [.shipRock(0),.partnerRock(1)])
        precondition(twoImpacts.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.guardianAbsorbed),
            V.TeamOutcome(player:.second,outcome:.activeTarczaAbsorbed)])
        precondition(simultaneous.encounter.firstSurvival.shieldCharges==1 &&
                     simultaneous.encounter.secondSurvival.shieldCharges==1)
        precondition(simultaneous.domeFirst.energy>24 &&
                     simultaneous.domeFirst.energy<25)
        precondition(simultaneous.domeFirst.energy ==
                     simultaneous.domeSecond.energy)
        precondition(simultaneous.firstGuardian!.charges==0)
        precondition(simultaneous.firstVitals!.armor==25 &&
                     simultaneous.firstVitals!.hull==60)
        precondition(simultaneous.encounter.firstSurvival.lives==3 &&
                     simultaneous.encounter.secondSurvival.lives==3)

        // The real co-op constructor must never create an independent
        // duplicated shield/life pool; only the explicit diagnostic opt-out
        // is allowed to keep the older fixture semantics.
        let coOpDefault=CombatEncounter68(first:body(100),
            second:body(640),rocks:[rock()],bugs:[],boss:nil,pickups:[],
            firstSurvival:CombatSurvival96(),
            secondSurvival:CombatSurvival96(),
            level:10,difficulty:.normal)
        var liveCoop=CombatVerifiedEncounter556(encounter:coOpDefault)
        precondition(liveCoop.sourceSharedCoopResources)
        precondition(!setup(true).sourceSharedCoopResources)
        precondition(!setup().sourceSharedCoopResources)

        // Windows Game.Step calls StepTarcza145 only ONCE for primary
        // input; Coop62.WithSecond62 does not swap its active/energy state.
        // Therefore the second ship's asteroid hits the SAME energy dome.
        let activePartner=liveCoop.step(dt:1/120,firstDomeHeld:true,
                                            guardianSecond:.clear)
        precondition(activePartner.contacts == [.partnerRock(0)])
        precondition(activePartner.hitOutcomes == [
            V.TeamOutcome(player:.second,outcome:.activeTarczaAbsorbed)])
        precondition(liveCoop.domeFirst.energy < 25.1 &&
                     liveCoop.domeFirst.energy > 24.8)
        precondition(liveCoop.domeFirst.energy==liveCoop.domeSecond.energy)
        precondition(liveCoop.encounter.secondSurvival.lives==3)

        // A held second-player input alone must not create a second
        // Tarcza145: the source only ticks from P1's input.
        var phantomDome=CombatVerifiedEncounter556(encounter:coOpDefault)
        phantomDome.encounter.firstSurvival.shieldCharges=1
        let noSecondDome=phantomDome.step(dt:1/120,
            firstDomeHeld:false,secondDomeHeld:true)
        precondition(noSecondDome.hitOutcomes == [
            V.TeamOutcome(player:.second,outcome:.requiresGuardianVerification)])
        precondition(phantomDome.encounter.firstSurvival.shieldCharges==1 &&
                     phantomDome.encounter.secondSurvival.shieldCharges==1)
        precondition(phantomDome.domeFirst.energy==60 &&
                     phantomDome.domeSecond.energy==60)

        // Two simultaneous real ship contacts cannot multiply the
        // one global 60-point dome pool: first spends 35, second spends
        // remaining 25, both are intercepted without extra charges.
        var twoDomes=CombatVerifiedEncounter556(encounter:sharedFrameScene)
        let bothActive=twoDomes.step(dt:1/120,firstDomeHeld:true,
                                        guardianFirst:.clear,
                                        guardianSecond:.clear)
        precondition(bothActive.contacts ==
                     [.shipRock(0),.partnerRock(1)])
        precondition(bothActive.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.activeTarczaAbsorbed),
            V.TeamOutcome(player:.second,outcome:.activeTarczaAbsorbed)])
        precondition(twoDomes.domeFirst.energy==0 &&
                     twoDomes.domeSecond.energy==0)
        precondition(twoDomes.encounter.firstSurvival.lives==3 &&
                     twoDomes.encounter.secondSurvival.lives==3)

        // The original FailRescue65 calls global Game.Damage. When only
        // P2 is wrecked and P1 activates Tarcza145 immediately before its
        // timeout, the ONE common dome can absorb P2's failed-rescue hit.
        // No second energy pool, invented life loss or repeated rescue.
        var shieldedFailure=setup(true)
        shieldedFailure.sourceSharedCoopResources=true
        var shieldedPartner=shieldedFailure.encounter.second!
        var shieldedSurvival=shieldedFailure.encounter.secondSurvival
        precondition(shieldedFailure.rescue.beginDown(.second,
            cooperative:true,playing:true,developerInfinite:false,
            rescueDamage:false,survival:&shieldedSurvival,
            body:&shieldedPartner))
        shieldedFailure.encounter.second=shieldedPartner
        shieldedFailure.encounter.secondSurvival=shieldedSurvival
        shieldedFailure.encounter.rocks=[]
        let nearlyExpired=shieldedFailure.step(dt:11.95,
            firstDomeHeld:false,guardianSecond:.clear,
            talentSecond:.clear)
        precondition(nearlyExpired.rescueEvent == .none &&
                     shieldedFailure.rescue.down(.second))
        let absorbedTimeout=shieldedFailure.step(dt:0.1,
            firstDomeHeld:true,guardianSecond:.clear,
            talentSecond:.clear)
        precondition(absorbedTimeout.rescueEvent ==
                     .failed(first:false,second:true))
        precondition(absorbedTimeout.rescueDamageOutcome ==
            V.TeamOutcome(player:.second,outcome:.activeTarczaAbsorbed))
        precondition(!absorbedTimeout.requiresRescueDamageResolution)
        precondition(absorbedTimeout.damageTransitions.isEmpty)
        precondition(shieldedFailure.encounter.firstSurvival.lives==3 &&
                     shieldedFailure.encounter.secondSurvival.lives==3)
        precondition(shieldedFailure.domeFirst.energy<25 &&
                     shieldedFailure.domeFirst.energy>23)
        precondition(shieldedFailure.domeFirst.energy ==
                     shieldedFailure.domeSecond.energy)

        // Direct source comparison: Windows Game.cs:234 returns before
        // StepTarcza145, StepSolids68, immunity countdown and pickups
        // whenever DevOpen. This must freeze the ENTIRE combat phase,
        // not just the 12-second co-op rescue progress.
        var developerPaused=setup()
        developerPaused.firstGuardian=CombatGuardian37(owned:false)
        developerPaused.firstVitals=CombatTalentVitals78()
        developerPaused.encounter.firstSurvival.invincible=1.5
        let originalRock=developerPaused.encounter.rocks[0].position
        let pausedFrame=developerPaused.step(dt:2,
            firstDomeHeld:true,devOpen:true)
        precondition(pausedFrame.contacts.isEmpty &&
                     pausedFrame.hitOutcomes.isEmpty &&
                     pausedFrame.damageTransitions.isEmpty)
        precondition(developerPaused.encounter.firstSurvival.invincible==1.5)
        precondition(developerPaused.encounter.rocks[0].position==originalRock)
        precondition(developerPaused.domeFirst.energy==60 &&
                     !developerPaused.domeFirst.active)
        precondition(developerPaused.firstVitals!.armor==25 &&
                     developerPaused.firstVitals!.hull==60)
        let resumedFrame=developerPaused.step(dt:1.6,
            firstDomeHeld:false,devOpen:false)
        precondition(resumedFrame.contacts == [.shipRock(0)])
        precondition(resumedFrame.hitOutcomes == [
            V.TeamOutcome(player:.first,outcome:.talentAbsorbed)])

        // The same Game.Step early exit must not resolve a previously
        // deferred FailRescue65 while the developer menu remains open.
        var pendingMenu=setup(true)
        var wrecked=pendingMenu.encounter.second!
        var surviving=pendingMenu.encounter.secondSurvival
        precondition(pendingMenu.rescue.beginDown(.second,
            cooperative:true,playing:true,developerInfinite:false,
            rescueDamage:false,survival:&surviving,body:&wrecked))
        pendingMenu.encounter.second=wrecked
        pendingMenu.encounter.secondSurvival=surviving
        pendingMenu.encounter.rocks=[]
        let missingDefense=pendingMenu.step(dt:12.1)
        precondition(missingDefense.rescueEvent ==
                     .failed(first:false,second:true))
        precondition(missingDefense.requiresRescueDamageResolution)
        let blockedResolution=pendingMenu.step(dt:3,
            devOpen:true,guardianSecond:.clear,talentSecond:.clear)
        precondition(blockedResolution.rescueDamageOutcome == nil &&
                     blockedResolution.damageTransitions.isEmpty &&
                     blockedResolution.requiresRescueDamageResolution)
        precondition(pendingMenu.encounter.secondSurvival.lives==3)
        let postMenu=pendingMenu.step(dt:1/120,
            devOpen:false,guardianSecond:.clear,talentSecond:.clear)
        precondition(postMenu.rescueDamageOutcome ==
            V.TeamOutcome(player:.second,outcome:.applied(
                .lifeLost(remaining:2,respawnProtection:3,
                          cause:"ZDERZENIE"))))
        precondition(!postMenu.requiresRescueDamageResolution &&
                     pendingMenu.encounter.secondSurvival.lives==2)

        // The original unknown-defense contract stays unchanged by
        // the optional integration; nil states still require verification.
        print("PASS: integrated Physics68 -> Tarcza145 -> verified damage -> 160/220 respawn and Gameplay65 2s co-op rescue")
    }
}
