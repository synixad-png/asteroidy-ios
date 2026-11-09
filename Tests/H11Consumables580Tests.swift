import Foundation

/// PC v580 Game.Price/Buy/Fire, BossTunnelGame.UseBomb,
/// Physics68.Explosion68 and ShopProfile56 regression against real C279.
@main struct H11Consumables580Tests {
    static func check(_ actual:Bool,_ reason:String) {
        precondition(actual,"H11 consumables PC580: "+reason)
    }
    static func close(_ a:Float,_ b:Float,_ reason:String,
                      tolerance:Float=0.001) {
        check(abs(a-b)<tolerance,reason+" actual=\(a), source=\(b)")
    }
    static func main() throws {
        let suite="asteroidy-h11-ion-bomb-"+UUID().uuidString
        let defaults=UserDefaults(suiteName:suite)!
        defer {defaults.removePersistentDomain(forName:suite)}

        var store=Sector01Shop568.State(tokens:2000)
        check(store.ionAmmo==0 && store.bombs==0 &&
              !store.available(.power,sector:25) &&
              !store.available(.rapid,sector:25),
              "source initial counts and final-sector purchase prohibition")
        check(store.price(.power)==60 && store.price(.rapid)==75,
              "first price slots are permanent upgrades")
        check(store.buy(.power) && store.upgradeLevel==2 &&
              store.buy(.power) && store.upgradeLevel==3,
              "source permanent weapon levels II and III")
        check(store.price(.power,sector:1)==53 &&
              store.price(.power,sector:13)==89 &&
              store.price(.power,sector:24)==122,
              "ceil((50+sector*3)*min(100,300-ion)/100) source price")
        check(store.buy(.power) && store.ionAmmo==100 &&
              store.price(.power)==53,
              "first ion pack buys +100 salvos, not per-bolt charges")
        check(store.buy(.power) && store.ionAmmo==200 &&
              store.buy(.power) && store.ionAmmo==300 &&
              !store.available(.power),"300-unit source ion cap")
        let ionCap=store
        check(!store.buy(.power) && store==ionCap,
              "capped ion purchase cannot charge or change wallet")
        store.ionAmmo=299
        check(store.ionPackSize==1 && store.price(.power)==1,
              "partial one-unit cap uses source round-up price")
        let ionCredit=store.tokens
        check(store.buy(.power) && store.ionAmmo==300 &&
              store.tokens==ionCredit-1,
              "partial capped pack does not overbill or overfill")
        check(store.buy(.rapid) && store.rapidLevel==1 &&
              store.buy(.rapid) && store.rapidLevel==2,
              "two genuine permanent rapid ranks")
        check(store.price(.rapid,sector:1)==62 &&
              store.price(.rapid,sector:13)==86 &&
              store.price(.rapid,sector:24)==108,
              "bomb price 60+sector*2 independent of inventory")
        for n in 1...3 {
            check(store.buy(.rapid) && store.bombs==n,
                  "each third-rank Rapid purchase buys exactly one bomb")
        }
        let full=store
        check(!store.available(.rapid) && !store.buy(.rapid) &&
              store==full,"bomb cap3 has no side effects")
        var empty=Sector01Shop568.State(tokens:100,upgradeLevel:3)
        let before=empty
        check(!empty.buy(.power,sector:24) && empty==before,
              "out-of-money Ion cannot mutate rank or wallet")
        empty.tokens=61;empty.rapidLevel=2
        let beforeBomb=empty
        check(!empty.buy(.rapid,sector:1) && empty==beforeBomb,
              "out-of-money bomb cannot charge partial credit")
        check(Sector01Shop568.validate(store),
              "ion/bomb purchased state remains valid")
        var broken=store
        broken.ionAmmo=301
        check(!Sector01Shop568.validate(broken),"reject ion301")
        broken=store;broken.bombs=4
        check(!Sector01Shop568.validate(broken),"reject bomb4")

        // Upgraded v568 profiles have no keys for v580 consumables;
        // migration must keep all pre-existing wallet and weapon fields.
        let bytes=try JSONEncoder().encode(store)
        guard var old=try JSONSerialization.jsonObject(with:bytes)
                as? [String:Any] else {
            preconditionFailure("encoded State must be a dictionary")
        }
        old.removeValue(forKey:"ionAmmo")
        old.removeValue(forKey:"bombs")
        let migrated=try JSONDecoder().decode(
            Sector01Shop568.State.self,
            from:JSONSerialization.data(withJSONObject:old))
        check(migrated.ionAmmo==0 && migrated.bombs==0 &&
              migrated.tokens==store.tokens &&
              migrated.upgradeLevel==store.upgradeLevel &&
              migrated.rapidLevel==store.rapidLevel &&
              migrated.totalSpent==store.totalSpent,
              "legacy v568/vH11 shops decode with no loss")
        Sector01Shop568.save(store,defaults:defaults)
        check(Sector01Shop568.load(defaults:defaults)==store,
              "both consumables round-trip alongside whole existing wallet")
        Sector01Shop568.persistConsumables(
            ionAmmo:97,bombs:2,defaults:defaults)
        let resumed=Sector01Shop568.load(defaults:defaults)
        check(resumed.ionAmmo==97 && resumed.bombs==2 &&
              resumed.tokens==store.tokens &&
              resumed.totalSpent==store.totalSpent,
              "mission survival persists consumed ammo only, no false charges")
        Sector01Shop568.persistSurvival(
            lives:2,shieldCharges:1,defaults:defaults)
        check(Sector01Shop568.load(defaults:defaults).ionAmmo==97 &&
              Sector01Shop568.load(defaults:defaults).bombs==2,
              "life/shield persistence never erases ammo or bombs")

        let campaign=CampaignProgress556()
        let entry=Sector01Entry568.open(
            selectedSector:1,campaign:campaign,
            hasOriginalC279Assets:true)!
        let zero=Vec2(x:0,y:0)
        let ionProfile=Sector01Shop568.State(
            tokens:145,scatterOwned:true,weapon:.scatter,
            upgradeLevel:3,rapidLevel:2,ionAmmo:2,bombs:2)
        // The explicit initializer matches the original factory used in
        // SourceNewGame568; no separate duplicate gameplay inventory.
        let prepared=Sector01PreparedWave568.prepare(
            entry:entry,campaign:campaign,
            hasOriginalC279Assets:true,difficulty:.normal,
            seed:5,shopProfile:ionProfile)!
        var game=CarbonisCombat568(prepared)
        check(game.ionAmmo==2 && game.bombs==2,
              "actual combat reads the one persisted source profile")
        game.step(move:zero,aim:zero,shooting:true,dt:1/60)
        check(game.ionAmmo==1 && game.bullets.count==5 &&
              game.bullets.allSatisfy({$0.damage==2}),
              "one ion per FIVE-bolt Scatter III salvo, +1 each bolt")
        check(game.drainOriginalAudioEvents568().contains(12),
              "ion boosted Scatter still uses source SFX12")
        for _ in 0..<120 {
            if game.phase != .playing {break}
            game.step(move:zero,aim:zero,shooting:true,dt:1/60)
            if game.ionAmmo==0 {break}
        }
        check(game.ionAmmo==0,"second ion salvo consumes final ion")
        // At ionAmmo0, newly fired shots receive native damage only.
        var plainProfile=ionProfile
        plainProfile.ionAmmo=0
        let withoutIon=Sector01PreparedWave568.prepare(
            entry:entry,campaign:campaign,hasOriginalC279Assets:true,
            difficulty:.normal,seed:5,shopProfile:plainProfile)!
        var ordinary=CarbonisCombat568(withoutIon)
        ordinary.step(move:zero,aim:zero,shooting:true,dt:1/60)
        check(ordinary.bullets.count==5 &&
              ordinary.bullets.allSatisfy({$0.damage==1}),
              "no ion inventory means no phantom extra damage")

        // Bomb must damage ALL existing enemies and active rocks, not
        // a visualization-only blast. Include both fatal and surviving actors.
        var battle=CarbonisCombat568(prepared)
        let origin=battle.flight.position
        let near=Sphere67.offset(origin,by:Vec2(x:80,y:0))
        let far=Sphere67.offset(origin,by:Vec2(x:800,y:0))
        battle.rocks=[
            SphereAsteroid556(position:near,velocity:zero,radius:14,
                size:3,tier:2,health:6,originalHealth:6,
                shapeSeed:110),
            SphereAsteroid556(position:far,velocity:zero,radius:9,
                size:3,tier:0,health:4,originalHealth:4,
                shapeSeed:111)
        ]
        let fighter=MissionWave568.Fighter(
            position:Sphere67.offset(origin,by:Vec2(x:140,y:0)),
            hp:4,type:0,hunter:false,fireClock:5,phase:1)
        let tough=MissionWave568.Fighter(
            position:Sphere67.offset(origin,by:Vec2(x:190,y:0)),
            hp:7,type:0,hunter:false,fireClock:5,phase:2)
        battle.shooters=[CarbonisCombat568.Shooter(fighter),
                         CarbonisCombat568.Shooter(tough)]
        battle.hostileShots=[
            CarbonisCombat568.Projectile(
                point:near,velocity:zero,life:2,hostile:true)]
        battle.invincible=0
        let oldScore=battle.score
        check(battle.useBomb(),"source real action allows active threats")
        check(battle.bombs==1 && battle.bombCooldown==1.5 &&
              battle.invincible==0.5,
              "one bomb consumed, 1.5-second cooldown and 0.5-second immunity")
        check(battle.hostileShots.isEmpty,"source clears enemy projectiles")
        check(battle.rocks[0].health==1 &&
              !battle.rocks.contains(where:{$0.shapeSeed==111}),
              "even far rocks receive 5 damage; only fatal rocks split")
        check(battle.shooters.count==1 &&
              battle.shooters[0].core.hp==2 &&
              battle.shooterKills==1 &&
              battle.score>oldScore,
              "5 damage applied to both fighters, fatal kill uses real score")
        let bombAudio=battle.drainOriginalAudioEvents568()
        check(bombAudio.contains(22),"source full explosion SFX22")
        check(!battle.useBomb() && battle.bombs==1,
              "cooldown blocks repeat tap without consuming bomb")
        close(sqrt(battle.rocks[0].velocity.lengthSquared),
              90*(1-80.0/330)/8,
              "Physics68 Explosion68 rock recoil radius330 mass8",
              tolerance:0.03)
        for _ in 0..<94 {
            battle.step(move:zero,aim:zero,shooting:false,dt:1/60)
        }
        check(battle.bombCooldown==0,"bomb cooldown actually ticks down")
        // No-target protection must not consume inventory or signal audio.
        var clear=CarbonisCombat568(prepared)
        clear.rocks=[];clear.shooters=[]
        let counts=clear.bombs
        check(!clear.useBomb() && clear.bombs==counts,
              "no-target launch is prohibited without charge loss")
        var noBombs=CarbonisCombat568(prepared)
        noBombs.bombs=0
        check(!noBombs.useBomb(),"zero bombs cannot fire or go negative")
        print("PASS H11 PC580 Ion/Bomb: pricing and partial packs, 300/3 caps, legacy migration, live ion scatter volley, 5-damage full-field blast, Physics68 recoil, cooldown, SFX22 and real persisted inventory")
    }
}
