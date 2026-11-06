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
        check(campaign.completedMask==0,"no fake campaign completion")
        print("PASS \(checks) live Carbonis C279 flight, shot, hit, victory and defeat checks")
    }
}
