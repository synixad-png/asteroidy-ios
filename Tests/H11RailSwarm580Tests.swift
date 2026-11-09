import Foundation

/// Deterministic H11 original PC v580 Game.cs Fire/Buy and
/// BossTunnelGame.cs GuideSwarm proof against the real CARBONIS engine.
@main struct H11RailSwarm580Tests {
    static func check(_ value:Bool,_ name:String) {
        precondition(value,"H11 RAIL/SWARM PC580: "+name)
    }
    static func close(_ actual:Float,_ expected:Float,_ name:String,
                      tolerance:Float=0.001) {
        check(abs(actual-expected)<tolerance,
              name+" actual="+String(actual)+" source="+String(expected))
    }
    static func main() throws {
        let suiteName="h11-rail-swarm-"+UUID().uuidString
        guard let defaults=UserDefaults(suiteName:suiteName)
            else {preconditionFailure("missing isolated defaults")}
        defer {defaults.removePersistentDomain(forName:suiteName)}
        var w=Sector01Shop568.State()
        w.award(500)
        check(H55Workshop580.weaponPrice(3,shop:w)==160 &&
              H55Workshop580.weaponPrice(4,shop:w)==190,
              "PC v580 rail160 and swarm190 shop prices")
        let before=w
        check(!H55Workshop580.selectWeapon(3,sector:12,shop:&w).success &&
              w==before,"rail locked sector12 no side effects")
        check(!H55Workshop580.selectWeapon(4,sector:1,shop:&w).success &&
              w==before,"swarm locked sector1 no side effects")
        check(H55Workshop580.selectWeapon(3,sector:13,shop:&w).success &&
              w.railOwned && w.weapon == .rail &&
              w.tokens==340 && w.totalSpent==160,
              "Rail bought and equipped in same persistent game wallet")
        check(H55Workshop580.selectWeapon(4,sector:13,shop:&w).success &&
              w.swarmOwned && w.weapon == .swarm &&
              w.tokens==150 && w.totalSpent==350,
              "Swarm bought and equipped cost190")
        check(H55Workshop580.selectWeapon(3,sector:13,shop:&w).success &&
              w.weapon == .rail && w.tokens==150 &&
              w.totalSpent==350,"owned Rail re-equip is free")
        check(H55Workshop580.selectWeapon(4,sector:13,shop:&w).success &&
              w.weapon == .swarm && w.tokens==150,
              "owned Swarm re-equip free")
        check(Sector01Shop568.validate(w),"both weapon flags validate")
        Sector01Shop568.save(w,defaults:defaults)
        check(Sector01Shop568.load(defaults:defaults)==w,
              "advanced purchases survive full profile round-trip")
        var empty=Sector01Shop568.State()
        empty.award(159)
        let notEnough=empty
        check(!H55Workshop580.selectWeapon(3,sector:13,shop:&empty).success &&
              empty==notEnough,"no partial debit at 159 tokens")
        check(!H55Workshop580.selectWeapon(2,sector:13,shop:&empty).success &&
              empty==notEnough,
              "old unowned Scatter cannot be sold after sector12")
        check(!H55Workshop580.selectWeapon(1,sector:13,shop:&empty).success &&
              empty==notEnough,
              "old unowned Twin cannot be sold after sector12")
        var legacy=Sector01Shop568.State()
        legacy.award(210)
        check(legacy.buy(.twin),"legacy Twin is still functional")
        let oldBytes=try JSONEncoder().encode(legacy)
        guard var oldJSON=try JSONSerialization.jsonObject(with:oldBytes)
                as? [String:Any] else {
            preconditionFailure("encoded profile must be a JSON dictionary")
        }
        oldJSON.removeValue(forKey:"railOwned")
        oldJSON.removeValue(forKey:"swarmOwned")
        let original568=try JSONSerialization.data(withJSONObject:oldJSON)
        let migrated=try JSONDecoder().decode(Sector01Shop568.State.self,
                                               from:original568)
        check(!migrated.railOwned && !migrated.swarmOwned &&
              migrated.twinOwned && migrated.weapon == .twin &&
              migrated.tokens==165 && migrated.totalSpent==45,
              "old v568 JSON loads all wallet/purchases without losing data")

        let campaign=CampaignProgress556()
        let entry=Sector01Entry568.open(
            selectedSector:1,campaign:campaign,
            hasOriginalC279Assets:true)!
        var armed=w
        check(armed.equip(.rail),"rail equipment stored")
        let railPrepared=Sector01PreparedWave568.prepare(
            entry:entry,campaign:campaign,hasOriginalC279Assets:true,
            difficulty:.normal,seed:1,shopProfile:armed)!
        var rail=CarbonisCombat568(railPrepared)
        check(rail.selectedWeapon == .rail,"actual CARBONIS reads saved Rail")
        let zero=Vec2(x:0,y:0)
        rail.step(move:zero,aim:zero,shooting:true,dt:1/60)
        check(rail.bullets.count==1 && rail.bullets[0].kind==3 &&
              rail.bullets[0].damage==4 && rail.bullets[0].pierce==4,
              "live Rail single 4-damage 4-pierce projectile")
        close(sqrt(rail.bullets[0].velocity.lengthSquared),1050,
              "Rail initial ballistic speed",tolerance:0.1)
        close(rail.bullets[0].life,1.05-1/60,
              "source default bullet life on Rail",tolerance:0.0002)
        check(rail.drainOriginalAudioEvents568().contains(13),
              "Rail source CombatSound.Shot weapon id3")

        // Original PC Rail pierces multiple rocks while never hitting the
        // same rock twice and is not consumed on the first rock contact.
        var piercer=CarbonisCombat568(railPrepared)
        let facing=Vec2(x:cos(piercer.flight.heading),
                        y:sin(piercer.flight.heading))
        piercer.rocks=[
            SphereAsteroid556(
                position:Sphere67.offset(piercer.flight.position,by:facing*55),
                velocity:zero,radius:9,size:3,tier:0,
                health:12,originalHealth:12,shapeSeed:107),
            SphereAsteroid556(
                position:Sphere67.offset(piercer.flight.position,by:facing*92),
                velocity:zero,radius:9,size:3,tier:0,
                health:12,originalHealth:12,shapeSeed:109)
        ]
        piercer.shooters=[]
        piercer.invincible=60
        for tick in 0..<10 {
            piercer.step(move:zero,aim:zero,shooting:tick==0,dt:1/60)
        }
        check(piercer.rocks.count==2 &&
              piercer.rocks[0].health==8 &&
              piercer.rocks[1].health==8,
              "Rail really penetrates two distinct rock targets")
        check(piercer.bullets.count==1 &&
              piercer.bullets[0].pierce==2,
              "spent only two of four source Rail penetrations")

        check(armed.equip(.swarm),"swarm equipment stored")
        let swarmPrepared=Sector01PreparedWave568.prepare(
            entry:entry,campaign:campaign,hasOriginalC279Assets:true,
            difficulty:.normal,seed:1,shopProfile:armed)!
        var swarm=CarbonisCombat568(swarmPrepared)
        swarm.step(move:zero,aim:zero,shooting:true,dt:1/60)
        check(swarm.bullets.count==3 &&
              swarm.bullets.allSatisfy({$0.kind==4 && $0.damage==1}),
              "live Swarm fires exactly three genuine guided projectiles")
        check(swarm.bullets.allSatisfy({abs($0.life-(1.8-1/60))<0.001}),
              "all Swarm projectiles retain original 1.8s lifespan")
        check(swarm.drainOriginalAudioEvents568().contains(14),
              "Swarm source CombatSound.Shot weapon id4")
        let angles=swarm.bullets.map{atan2($0.velocity.y,$0.velocity.x)}
        check(angles[0]<angles[1] && angles[1]<angles[2],
              "source Swarm fan offsets -0.18, 0, +0.18")

        // Pure source guide: nearest eligible rock wins, fixed 420 limit,
        // t=min(1,dt*4), and the original does not re-normalize the mix.
        let start=Vec2(x:640,y:360)
        let target=Sphere67.offset(start,by:Vec2(x:0,y:100))
        let rock=SphereAsteroid556(
            position:target,velocity:zero,radius:9,
            size:3,tier:0,health:1)
        let shot=CarbonisCombat568.Projectile(
            point:start,velocity:Vec2(x:300,y:0),
            life:1.8,hostile:false,kind:4)
        let guided=CarbonisCombat568.guidedSwarmVelocity(
            shot:shot,dt:0.1,rocks:[rock],shooters:[])
        close(guided.x,180,"Game.GuideSwarm velocity x",tolerance:0.04)
        close(guided.y,120,"Game.GuideSwarm velocity y",tolerance:0.04)
        let plain=CarbonisCombat568.Projectile(
            point:start,velocity:Vec2(x:300,y:0),
            life:1.1,hostile:false,kind:0)
        check(CarbonisCombat568.guidedSwarmVelocity(
            shot:plain,dt:0.1,rocks:[rock],shooters:[]).x==300,
            "Pulse stays unguided")
        let far=SphereAsteroid556(
            position:Sphere67.offset(start,by:Vec2(x:460,y:0)),
            velocity:zero,radius:9,size:3,tier:0,health:1)
        check(CarbonisCombat568.guidedSwarmVelocity(
            shot:shot,dt:0.1,rocks:[far],shooters:[]).x==300,
            "Swarm original 420-unit target limit")
        close(H55SourceMechanics580.shotInterval(
            weapon:3,upgrade:1,rapid:0,
            shipType:1,rateRank:0,cooling:0)!,0.32,"Rail cooldown")
        close(H55SourceMechanics580.shotInterval(
            weapon:4,upgrade:1,rapid:0,
            shipType:1,rateRank:0,cooling:0)!,0.29,"Swarm cooldown")
        print("PASS H11 PC580 Rail/Swarm: shop prices/sectors, migration, durability, live 4-damage rail, 2 pierced rocks, 3 homing Swarm shots, audio 13/14 and 420-unit guidance")
    }
}
