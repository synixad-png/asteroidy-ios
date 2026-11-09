import Foundation

/// H11 source PC v580 Guardian298 regression, including real C279 mission.
@main struct CombatGuardianDrone298Tests {
    static func check(_ yes:Bool,_ name:String) {
        precondition(yes,"Guardian298 regression: "+name)
    }

    static func main() {
        let campaign=CampaignProgress556()
        let entry=Sector01Entry568.open(
            selectedSector:1,campaign:campaign,
            hasOriginalC279Assets:true)!
        let prepared=Sector01PreparedWave568.prepare(
            entry:entry,campaign:campaign,hasOriginalC279Assets:true,
            difficulty:.normal,seed:1)!
        let ship=Vec2(x:640,y:360)
        var shooter=CarbonisCombat568(prepared).shooters[0]
        shooter.core.position=Sphere67.offset(ship,by:Vec2(x:110,y:0))
        var drone=CombatGuardianDrone298()
        let stationary=Vec2(x:0,y:0)
        check(drone.step(dt:1/60,elapsed:0,ship:ship,
                         shipVelocity:stationary,shooters:[shooter],
                         rocks:[],owned:false,strike:2,focus:2,
                         projectileCount:0)==nil,
              "unowned drone cannot shoot")
        let first=drone.step(dt:1/60,elapsed:1/60,ship:ship,
                             shipVelocity:stationary,shooters:[shooter],
                             rocks:[],owned:true,strike:2,focus:2,
                             projectileCount:0)
        check(first != nil,"owned Guardian acquires a real shooter")
        check(first?.damage==2 && abs((first?.life ?? 0)-1.2)<0.001,
              "PC GuardianStrike2 + GuardianFocus2 plasma damage and life")
        check((first?.velocity.lengthSquared ?? 0)>80_000,
              "PC plasma has real source 300+24*2 velocity")
        check(abs(drone.cooldown-1.16)<0.0001,
              "source GuardianStrike2 Focus2 exact 1.16s cooldown")
        check(drone.step(dt:1/60,elapsed:2/60,ship:ship,
                         shipVelocity:stationary,shooters:[shooter],
                         rocks:[],owned:true,strike:2,focus:2,
                         projectileCount:0)==nil,
              "never fire twice before Guardian cooldown")
        let homed=drone.guidedVelocity(
            at:ship,velocity:Vec2(x:0,y:300),dt:1/60,
            ship:ship,shooters:[shooter],rocks:[],focus:2)
        check(homed.x>0 && abs(sqrt(homed.lengthSquared)-300)<0.01,
              "real Guardian bullet turns toward target preserving speed")
        var outside=CombatGuardianDrone298()
        shooter.core.position=Sphere67.offset(ship,by:Vec2(x:240,y:0))
        let notLocked=outside.step(dt:1/60,elapsed:0,
            ship:ship,shipVelocity:stationary,
            shooters:[shooter],rocks:[],
            owned:true,strike:0,focus:0,projectileCount:0)
        check(notLocked == nil,"cannot target source-out-of-range enemy")

        // The active H11 Guardian upgrade must spawn a real, swept-hit
        // player projectile, not merely a light or workshop tooltip.
        let saved=H55SourceMechanics580.load()
        defer { _=H55SourceMechanics580.save(saved) }
        var rules=saved
        rules.guardianOwned=true
        rules.guardianStrike=2
        rules.guardianFocus=2
        check(H55SourceMechanics580.save(rules),
              "persist source drone upgrade into canonical profile")
        var combat=CarbonisCombat568(prepared)
        check(combat.sourceMechanics.guardianOwned,
              "actual mission has canonical owned Guardian")
        combat.rocks=[]
        combat.shooters=Array(combat.shooters.prefix(1))
        combat.shooters[0].core.position=Sphere67.offset(
            combat.flight.position,by:Vec2(x:170,y:0))
        combat.invincible=10
        combat.step(move:stationary,aim:stationary,
                    shooting:false,dt:1/60)
        check(combat.bullets.contains(where:{$0.guardian298}),
              "Guardian shoots real player bullet even without touch fire")
        check(combat.bullets.contains(where:{
            $0.guardian298 && $0.damage==2 && $0.kind==2
        }),"same source plasma damage, kind and shared hit pipeline")

        // With purchased upgrades OFF, legacy first-sector combat still
        // never spontaneously fires when the player does not press right.
        H55SourceMechanics580.reset()
        var legacy=CarbonisCombat568(prepared)
        legacy.rocks=[]
        legacy.shooters=Array(legacy.shooters.prefix(1))
        legacy.shooters[0].core.position=Sphere67.offset(
            legacy.flight.position,by:Vec2(x:170,y:0))
        legacy.step(move:stationary,aim:stationary,
                    shooting:false,dt:1/60)
        check(legacy.bullets.isEmpty && legacy.guardianCharges==0,
              "no ghost drone or player bullet without Guardian ownership")
        print("PASS H11 PC580 Guardian298 target/orbit/cooldown/homing, active C279 damage bullets and disabled baseline")
    }
}
