import Foundation

@main struct CarbonisCombat568Tests {
    static func main() {
        var checks=0
        func check(_ condition:Bool,_ name:String) {
            precondition(condition,name);checks+=1
        }
        let campaign=CampaignProgress556()
        let entry=Sector01Entry568.open(selectedSector:1,
            campaign:campaign,hasOriginalC279Assets:true)!
        let prepared=Sector01PreparedWave568.prepare(
            entry:entry,campaign:campaign,hasOriginalC279Assets:true,
            difficulty:.normal,seed:1)!
        var sim=CarbonisCombat568(prepared)
        check(sim.rocks.count==13 && sim.shooters.count==4,"exact source wave")
        check(sim.flight.flight.configuration.cruiseSpeed==156,"source ship speed")
        check(sim.lives==3 && sim.phase == .playing,"original state")
        let before=sim.flight.position
        for _ in 0..<240 {
            sim.step(move:Vec2(x:1,y:0),aim:Vec2(x:1,y:0),
                     shooting:true,dt:1.0/120)
        }
        check(CarbonisCombat568.distance(sim.flight.position,before)>5,
              "player actually flies over sphere")
        check(sim.elapsed>1.9 && sim.elapsed<2.1,"fixed-step clock")
        check(sim.rocks.count<500 && sim.shooters.count<=4,"combat bounded including genuine rock splits")
        check(sim.bullets.count<20,"Pulse shot interval and lifetimes")
        check(sim.flight.camera.focus.length>0.99,"following camera")
        var contact=CarbonisCombat568(prepared)
        contact.invincible=0
        contact.rocks=[SphereAsteroid556(position:contact.flight.position,
                  velocity:Vec2(x:0,y:0),radius:16)]
        contact.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                     shooting:false,dt:1.0/120)
        check(contact.lastContactCount>0 && contact.armor<25,"source spherical contact")
        check(contact.armor==7,"source 18 HP asteroid collision")
        var enemyContact=CarbonisCombat568(prepared)
        enemyContact.invincible=0
        enemyContact.rocks=[]
        enemyContact.shooters=Array(enemyContact.shooters.prefix(1))
        enemyContact.shooters[0].core.position=enemyContact.flight.position
        enemyContact.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                          shooting:false,dt:1.0/120)
        check(enemyContact.lastContactCount>0 &&
              enemyContact.armor==7,
              "original Physics68 fighter contact applies 18 HP")
        var knock=SphereAsteroid556(position:Vec2(x:650,y:350),
            velocity:Vec2(x:0,y:0),radius:16)
        let slug=CarbonisCombat568.Projectile(
            point:Vec2(x:644,y:347),velocity:Vec2(x:210,y:65),
            life:1.1,hostile:false)
        CarbonisCombat568.impactRock68(&knock,shot:slug)
        check(knock.velocity.lengthSquared>0,
              "original Physics68 bullet transfers momentum")
        check(knock.spin.isFinite && abs(knock.spin)<=2.5,
              "original Physics68 clamps impact torque")
        var failure=CarbonisCombat568(prepared)
        failure.invincible=0;failure.armor=0;failure.hull=1;failure.lives=1
        failure.suffer(8)
        check(failure.phase == .defeat && failure.lives==0,"real defeat")
        var victory=CarbonisCombat568(prepared)
        victory.rocks=[];victory.shooters=[]
        for _ in 0..<35 {
            victory.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                         shooting:false,dt:1.0/120)
        }
        check(victory.phase == .victory,"original spherical 0.20-second clear hold")
        // v568 HitBug: shooter collision uses nearest projected time,
        // but cannot damage a target if a stone is intersected earlier.
        let pulse=CarbonisCombat568.Projectile(
            point:Vec2(x:450,y:360),
            velocity:Vec2(x:6000,y:0),life:1,hostile:false)
        var cover=CarbonisCombat568(prepared)
        cover.rocks=[SphereAsteroid556(
            position:Vec2(x:490,y:360),
            velocity:Vec2(x:0,y:0),radius:9,
            size:3,tier:0,health:2,originalHealth:2)]
        cover.shooters=Array(cover.shooters.prefix(1))
        cover.shooters[0].core.position=Vec2(x:520,y:360)
        let initialEnemyHP=cover.shooters[0].core.hp
        cover.bullets=[pulse]
        cover.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                   shooting:false,dt:1.0/60)
        check(cover.shooters[0].core.hp==initialEnemyHP,
              "Source HitBug prevents firing through nearer asteroid")
        check(cover.rocks[0].health==1,
              "Occluding asteroid receives physical Pulse impact")

        var clearShot=CarbonisCombat568(prepared)
        clearShot.rocks=[]
        clearShot.shooters=Array(clearShot.shooters.prefix(1))
        clearShot.shooters[0].core.position=Vec2(x:520,y:360)
        clearShot.shooters[0].core.hp=1
        clearShot.bullets=[pulse]
        clearShot.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                       shooting:false,dt:1.0/60)
        check(clearShot.shooters.isEmpty && clearShot.shooterKills==1,
              "Unobstructed type0 enemy is destroyed by source Pulse hit")
        check(clearShot.score==180,"Source Bug kill reward 180")
        check(CarbonisCombat568.sourceRockScore(SphereAsteroid556(
                position:Vec2(x:490,y:360),
                velocity:Vec2(x:0,y:0),radius:9,
                size:3,tier:0,health:1,originalHealth:2))==50,
              "Source size3 rock score includes original HP")
        var terminal=CarbonisCombat568(prepared)
        terminal.rocks=[SphereAsteroid556(
            position:Vec2(x:490,y:360),
            velocity:Vec2(x:0,y:0),radius:10,size:1,tier:0,
            health:1,originalHealth:1)]
        terminal.shooters=[]
        terminal.bullets=[pulse]
        terminal.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                      shooting:false,dt:1.0/60)
        check(terminal.rocks.count==18,
              "Game.SpawnTerminalShards187 creates exactly 18 source pieces")
        check(terminal.rocks.allSatisfy({
              $0.fragment && $0.shardLife>=1.3 &&
              $0.shardLife<=2.5 && $0.mass==0.09
              }),"terminal shards preserve source lifetime and physical mass")
        check(terminal.score==100,"source size1 asteroid score")
        check(terminal.phase == .playing,
              "terminal debris must delay source MissionCleared")
        for _ in 0..<460 {
            terminal.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                          shooting:false,dt:1.0/120)
        }
        check(terminal.rocks.isEmpty,
              "terminal debris expires after original 1.3-2.5 seconds")
        check(terminal.phase == .victory,
              "source 0.2-second clear hold starts only after debris gone")
        check(campaign.completedMask==0,"no fake campaign completion")
        print("PASS \(checks) live Carbonis C279 flight, shot, hit, victory and defeat checks")
    }
}
