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
        var failure=CarbonisCombat568(prepared)
        failure.invincible=0;failure.armor=0;failure.hull=1;failure.lives=1
        failure.suffer(8)
        check(failure.phase == .defeat && failure.lives==0,"real defeat")
        var victory=CarbonisCombat568(prepared)
        victory.rocks=[];victory.shooters=[]
        victory.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                     shooting:false,dt:1.0/120)
        check(victory.phase == .victory,"real empty clear objective")
        check(campaign.completedMask==0,"no fake campaign completion")
        print("PASS \(checks) live Carbonis C279 flight, shot, hit, victory and defeat checks")
    }
}
