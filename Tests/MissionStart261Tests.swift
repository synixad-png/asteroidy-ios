import Foundation

@main struct MissionStart261Tests {
    static func main() {
        var count=0
        func check(_ ok: Bool, _ name: String) {
            precondition(ok,name)
            count+=1
        }
        for sector in 1...26 {
            let result=MissionStart261.prepare(
                sector:sector,unlocked:true,sceneBusy:false,
                hasOriginalScene:true,currentLives:0,startingLives:3)
            guard case let .success(s)=result else {fatalError("sector missing")}
            check(s.level==sector && s.lives==3,"sector/lives")
            check(s.invincibleSeconds == (sector<=4 ? 4.5 : 3),"invincibility")
            check(s.shipXFraction==0.5 && s.shipYFraction==0.5 &&
                  s.shipAngleRadians == -Float.pi/2,"source ship reset")
            check(s.clearRocks && s.clearBugs && s.clearBullets &&
                  s.clearPickups && s.clearBossProjectiles,"all five clears")
            check(s.resetVitals && s.resetFlightMotion &&
                  s.resetBossSpecial && s.resetMissionTrophies &&
                  s.resetSphereCamera && s.resetPadHeading,"source resets")
            check(s.clearTunnelState && s.clearShopArrival &&
                  s.bossHealth==0 && !s.visualReady &&
                  !s.bossSpawned && !s.bossDefeated,"source state")
        }
        for sector in [0,-1,27,99] {
            let r=MissionStart261.prepare(sector:sector,unlocked:true,
                sceneBusy:false,hasOriginalScene:true,
                currentLives:1,startingLives:3)
            check(r == .failure(.invalidMission),"invalid sector")
        }
        check(MissionStart261.prepare(sector:1,unlocked:false,
            sceneBusy:false,hasOriginalScene:true,currentLives:1,
            startingLives:3) == .failure(.lockedMission),"locked")
        check(MissionStart261.prepare(sector:1,unlocked:true,
            sceneBusy:true,hasOriginalScene:true,currentLives:1,
            startingLives:3) == .failure(.busyScene),"busy")
        check(MissionStart261.prepare(sector:1,unlocked:true,
            sceneBusy:false,hasOriginalScene:false,currentLives:1,
            startingLives:3) == .failure(.missingOriginalScene),"assets")
        for wave in [false,true] {
            for intro in [false,true] {
                for runtime in [false,true] {
                    check(MissionStart261.canEnterPlaying(
                        hasSourceWave:wave,hasSourceIntro:intro,
                        hasFlightAndCombatRuntime:runtime) ==
                        (wave && intro && runtime),"no fake play")
                }
            }
        }
        print("PASS \(count) source mission-start checks, combat unported")
    }
}
