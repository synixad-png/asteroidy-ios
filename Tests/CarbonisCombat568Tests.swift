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
        // PC v584 supply roll: exact .NET seeded stream, one bonus per
        // destroyed target, preserving all previous mission RNG calls.
        check(prepared.combatSupplySeed==1,
              "original mission seed is preserved for independent supply RNG")
        var supplyA=SourceCombatSupply586(missionSeed:1)
        var supplyB=SourceCombatSupply586(missionSeed:1)
        var energyCount=0,bombCount=0
        for _ in 0..<20_000 {
            let a=supplyA.decide(enemy:true,asteroidSize:0,
                currentBombs:0,currentIonAmmo:0,
                pickupsCount:0,lootEnabled:true)
            let b=supplyB.decide(enemy:true,asteroidSize:0,
                currentBombs:0,currentIonAmmo:0,
                pickupsCount:0,lootEnabled:true)
            check(a==b,"PC RNG deterministic one-roll supply stream")
            if a == .energy {energyCount+=1; _=supplyA.velocity(); _=supplyB.velocity()}
            if a == .bomb {bombCount+=1; _=supplyA.velocity(); _=supplyB.velocity()}
        }
        check(energyCount>2700 && energyCount<3500 &&
              bombCount>900 && bombCount<1300,
              "original enemy drop rates remain near 15.5% energy / 5.5% bomb")
        var blocked=SourceCombatSupply586(missionSeed:1)
        check(blocked.decide(enemy:true,asteroidSize:0,
            currentBombs:0,currentIonAmmo:0,
            pickupsCount:96,lootEnabled:true)==nil,
            "source maximum of 96 shared pickups")
        check(blocked.decide(enemy:true,asteroidSize:0,
            currentBombs:0,currentIonAmmo:0,
            pickupsCount:0,lootEnabled:false)==nil,
            "disabled/replay loot produces no bonus")
        var ion=277, bombs=2
        check(SourceCombatSupply586.collected(.energy,
            ionAmmo:&ion,bombs:&bombs) && ion==300,
            "energy pickup credits real IonAmmo capped at 300")
        check(!SourceCombatSupply586.collected(.energy,
            ionAmmo:&ion,bombs:&bombs),
            "full ion inventory does not consume pickup")
        check(SourceCombatSupply586.collected(.bomb,
            ionAmmo:&ion,bombs:&bombs) && bombs==3,
            "bomb pickup credits real Bombs capped at three")
        check(!SourceCombatSupply586.collected(.bomb,
            ionAmmo:&ion,bombs:&bombs),
            "full bomb inventory does not consume pickup")
        check(!SourceCombatSupply586.collected(.shield,
            ionAmmo:&ion,bombs:&bombs),
            "unported shield mechanic must not be faked")
        // Integration on the REAL CARBONIS combat state, not merely a
        // test of the standalone picker. Two original PC586 supplies must
        // change the existing ammo/bomb fields and their source HUD events.
        var realPickup=CarbonisCombat568(prepared)
        realPickup.ionAmmo=260
        realPickup.bombs=2
        let place=realPickup.flight.position
        realPickup.tokenPickups=[
            CarbonisCombat568.TokenPickup(
                position:place,velocity:Vec2(x:0,y:0),value:40,
                sourceKind:.energy),
            CarbonisCombat568.TokenPickup(
                position:place,velocity:Vec2(x:0,y:0),value:1,
                sourceKind:.bomb)
        ]
        realPickup.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                        shooting:false,dt:1/120)
        check(realPickup.ionAmmo==300 && realPickup.bombs==3,
              "physical pickups mutate the REAL mission IonAmmo and Bombs")
        check(realPickup.tokenPickups.isEmpty,
              "collected PC586 supplies leave the unified source pickup list")
        check(realPickup.drainOriginalAudioEvents568().filter{$0==30}.count==2,
              "one original pickup audio event for each collected supply")
        check(realPickup.hudEvents.pickups==2,
              "PC v600 HUD counts both real consumables, not only token currency")
        // PC Game.Step removes a source pickup on contact even if the
        // ammunition magazine filled after the drop. No false SFX event.
        var fullPickup=CarbonisCombat568(prepared)
        fullPickup.ionAmmo=300
        fullPickup.bombs=3
        fullPickup.tokenPickups=[
            CarbonisCombat568.TokenPickup(position:fullPickup.flight.position,
                velocity:Vec2(x:0,y:0),value:40,sourceKind:.energy),
            CarbonisCombat568.TokenPickup(position:fullPickup.flight.position,
                velocity:Vec2(x:0,y:0),value:1,sourceKind:.bomb)
        ]
        fullPickup.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                        shooting:false,dt:1/120)
        check(fullPickup.tokenPickups.isEmpty &&
              fullPickup.ionAmmo==300 && fullPickup.bombs==3,
              "PC580 full magazines remove expended supply pickups")
        check(!fullPickup.drainOriginalAudioEvents568().contains(30),
              "full magazines do not trigger false pickup notification")
        check(fullPickup.hudEvents.pickups==0,
              "rejected full-magazine supplies never pulse HUD")
        var expiredPickup=CarbonisCombat568(prepared)
        expiredPickup.tokenPickups=[
            CarbonisCombat568.TokenPickup(
                position:expiredPickup.flight.position,
                velocity:Vec2(x:0,y:0),value:40,
                sourceKind:.energy,life:0.00001)
        ]
        expiredPickup.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                           shooting:false,dt:1/120)
        check(expiredPickup.tokenPickups.isEmpty && expiredPickup.ionAmmo==0,
              "expired 26-second PC586 consumable cannot be collected")
        // PC v608 GLB shield pickup restores a full reserve bar and
        // must never silently add 20 units to the active energy gauge.
        var legacy=CarbonisCombat568(prepared)
        legacy.tarcza145.energy=80
        legacy.tokenPickups=[
            CarbonisCombat568.TokenPickup(
                position:legacy.flight.position,
                velocity:Vec2(x:0,y:0),value:0,
                sourceKind:.shield,life:23),
            CarbonisCombat568.TokenPickup(
                position:legacy.flight.position,
                velocity:Vec2(x:0,y:0),value:1,
                sourceKind:.boost,life:25)
        ]
        legacy.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                    shooting:false,dt:1/120)
        check(legacy.tokenPickups.isEmpty &&
              legacy.tarcza145.energy==80 &&
              legacy.shieldCharges==1 && legacy.boost71.charges==1,
              "PC608 shield GLB adds one reserve, not 20 active energy")
        check(legacy.drainOriginalAudioEvents568().filter{$0==30}.count==2,
              "shield/boost pickups share source audio event path")

        var activeShield=CarbonisCombat568(prepared)
        activeShield.shieldCharges=1
        activeShield.tarcza145.energy=100
        activeShield.invincible=0
        activeShield.setShieldHeld(true)
        activeShield.rocks.removeAll()
        activeShield.shooters.removeAll()
        activeShield.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                          shooting:false,dt:1/120)
        let beforeShield=activeShield.tarcza145.energy
        check(beforeShield<100 && beforeShield>99.8,
              "held active shield drains exactly 12 energy/sec")
        activeShield.suffer(18)
        check(abs(activeShield.tarcza145.energy-(beforeShield-35))<0.001 &&
              activeShield.shieldCharges==1 &&
              activeShield.armor==25 && activeShield.hull==60 &&
              activeShield.invincible>=0.28,
              "held Tarcza145 absorbs 35 energy without spending reserves")
        activeShield.setShieldHeld(false)
        check(!activeShield.tarcza145.active,
              "releasing touch shield stops drain/absorption immediately")
        check(activeShield.boost71.charges==0,
              "active shield is not an alias for Boost71 charges")

        var boosted=CarbonisCombat568(prepared)
        boosted.boost71.collect()
        boosted.invincible=0
        check(boosted.activateBoost71() &&
              boosted.boost71.charges==0 &&
              boosted.boost71.remaining==0.9,
              "one tap uses one stored Boost71 charge for 0.9 seconds")
        check(!boosted.activateBoost71(),
              "a second press cannot spend another charge during active boost")
        let beforeTravel=boosted.flight.position
        boosted.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                     shooting:false,dt:1/120)
        check(boosted.boost71.remaining<0.9 &&
              boosted.boost71.remaining>0.88 &&
              boosted.invincible>=0.14 &&
              CarbonisCombat568.distance(beforeTravel,boosted.flight.position)>0,
              "boost physically moves the real player, grants protection and advances timer")
        // Original PC145/PC71 probabilities and cooldown counter use
        // deterministic seeds without contaminating the ship/AI RNG.
        var sourceLegacyA=SourceLegacyPickupDrops586(seed:17)
        var sourceLegacyB=SourceLegacyPickupDrops586(seed:17)
        var shieldDrops=0,boostDrops=0
        for _ in 0..<300 {
            let sa=sourceLegacyA.shield(
                enemy:false,rockSize:3,eligible:true,pickups:0)
            let sb=sourceLegacyB.shield(
                enemy:false,rockSize:3,eligible:true,pickups:0)
            check(sa?.kind==sb?.kind && sa?.life==sb?.life &&
                  sa?.velocity.x==sb?.velocity.x,
                  "source original shield drop stream reproducible")
            if sa != nil {shieldDrops+=1}
            let ba=sourceLegacyA.boost(eligible:true,pickups:0)
            let bb=sourceLegacyB.boost(eligible:true,pickups:0)
            check(ba?.kind==bb?.kind && ba?.life==bb?.life &&
                  ba?.velocity.y==bb?.velocity.y,
                  "source original boost drop counter reproducible")
            if ba != nil {boostDrops+=1}
        }
        check(shieldDrops>=35 && shieldDrops<=85,
              "big rock shield cell probability stays near original 20%")
        check(boostDrops>=30 && boostDrops<=65,
              "source boost drops once per 4-7 then 5-9 rock kills")
        var ram=CarbonisCombat568(prepared)
        var testRock=ram.rocks[0]
        testRock.health=50
        testRock.velocity=Vec2(x:0,y:0)
        let forward=Vec2(x:cos(ram.flight.heading),
                         y:sin(ram.flight.heading))
        testRock.position=Sphere67.offset(ram.flight.position,by:forward*8)
        ram.rocks=[testRock]
        ram.shooters.removeAll()
        ram.boost71.collect()
        check(ram.activateBoost71(),
              "original Boost71 can be activated from a collected charge")
        ram.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                 shooting:false,dt:1/120)
        check(ram.rocks.count==1 && ram.rocks[0].health==42,
              "actual ram hits REAL rock HP for original 8 damage")
        ram.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                 shooting:false,dt:1/120)
        check(ram.rocks[0].health==42,
              "one 0.9-second boost does not damage the same rock twice")
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
        // Right-half touch semantics: finger down instantly enables
        // Source Pulse, holding continues normal cooldown-based firing,
        // lifting ends shooting without stopping the independent flight.
        var touchFire=CarbonisCombat568(prepared)
        touchFire.invincible=5
        let still=Vec2(x:0,y:0)
        touchFire.step(move:still,aim:still,shooting:false,dt:1/120)
        check(touchFire.bullets.isEmpty,"right side untouched: no auto-fire")
        touchFire.step(move:still,aim:still,shooting:true,dt:1/120)
        check(touchFire.bullets.count==1,
              "first right-side contact fires immediately without a button")
        check(touchFire.hudEvents.shots==1,
              "PC v600 shot event increments exactly once on real fire")
        let firstAudio=touchFire.drainOriginalAudioEvents568()
        check(firstAudio.contains(10),
              "true first Pulse fire emits original CombatSound code 10")
        check(touchFire.drainOriginalAudioEvents568().isEmpty,
              "original SFX queue drains atomically; no duplicated audio")
        for _ in 0..<24 {
            touchFire.step(move:still,aim:still,shooting:true,dt:1/120)
        }
        check(touchFire.bullets.count>=2,
              "holding right side repeats Pulse via original shot cadence")
        check(touchFire.hudEvents.shots>=2,
              "shot event counter is monotonic beyond active bullet lifetimes")
        let emitted=touchFire.bullets.count
        let positionBefore=touchFire.flight.position
        for _ in 0..<12 {
            touchFire.step(move:Vec2(x:1,y:0),aim:still,
                           shooting:false,dt:1/120)
        }
        check(touchFire.bullets.count<=emitted,
              "releasing right side immediately stops adding new shots")
        check(CarbonisCombat568.distance(
              touchFire.flight.position,positionBefore)>0,
              "left flight remains operational after right-side release")
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
        check(failure.drainOriginalAudioEvents568()==[21],
              "source Game.Damage fatal hull emits BlastEvents/BlastSound1 as SFX21")
        var protectedRespawn=CarbonisCombat568(prepared)
        protectedRespawn.invincible=0
        protectedRespawn.armor=0
        protectedRespawn.hull=1
        protectedRespawn.lives=2
        protectedRespawn.rocks=[SphereAsteroid556(
            position:Vec2(x:644,y:360),
            velocity:Vec2(x:30,y:0),radius:16,
            size:3,tier:0,health:5)]
        protectedRespawn.suffer(18)
        check(protectedRespawn.drainOriginalAudioEvents568()==[21],
              "source Game.Damage respawn uses same SFX21 exactly once")
        check(protectedRespawn.phase == .playing &&
              protectedRespawn.lives==1 &&
              protectedRespawn.invincible==4.5,
              "Game.Damage resets lives and source 4.5s immunity on level1")
        check(abs(protectedRespawn.flight.heading+Float.pi/2)<0.0001 &&
              protectedRespawn.flight.velocity.lengthSquared==0,
              "Game.Damage resets heading and speed")
        check(CarbonisCombat568.distance(
              protectedRespawn.flight.position,
              protectedRespawn.rocks[0].position)>160,
              "Game.Damage relocates obstructing source rock beyond spawn exclusion")

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
        check(cover.hudEvents.hits==1,
              "real obstructing asteroid hit creates exactly one HUD hit event")
        check(cover.destruction.explosions.isEmpty &&
              cover.destruction.particles.count==3,
              "one nonfatal rock hit adds original three cyan trails, not a death cloud")


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
        check(clearShot.hudEvents.hits==1,
              "real enemy shot impact feeds source HUD hit telemetry")
        check(clearShot.score==180,"Source Bug kill reward 180")
        check(clearShot.drainOriginalAudioEvents568().contains(20),
              "original destroyed shooter dispatches fuel blast SFX code20")
        check(clearShot.destruction.particles.count==22 &&
              clearShot.destruction.pieces.count==17 &&
              clearShot.destruction.explosions.count==1 &&
              clearShot.destruction.explosions[0].kind==0 &&
              clearShot.destruction.explosions[0].scale==14,
              "real Pulse shooter kill emits original 22 orange trails, six impact sparks, 11 metal tetra and fuel cloud")

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
        check(terminal.drainOriginalAudioEvents568().contains(20),
              "original small asteroid destruction emits CombatSound blast20")
        check(terminal.destruction.particles.count==18 &&
              terminal.destruction.explosions.count==1 &&
              terminal.destruction.explosions[0].kind==1 &&
              terminal.destruction.explosions[0].scale==9,
              "source Game.Split size1 produces actual 18 cyan trails and 3D rock volume")

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
        // Real first-sector completion, including remaining uncollected
        // source tokens and Game.FinishLevel clear bonus, only once.
        var settlement=CarbonisCombat568(prepared)
        settlement.rocks=[];settlement.shooters=[]
        settlement.tokenPickups=[
            CarbonisCombat568.TokenPickup(
                position:Vec2(x:320,y:430),
                velocity:Vec2(x:0,y:0),value:2),
            CarbonisCombat568.TokenPickup(
                position:Vec2(x:990,y:450),
                velocity:Vec2(x:0,y:0),value:6)
        ]
        for _ in 0..<40 {
            settlement.step(move:Vec2(x:0,y:0),
                aim:Vec2(x:0,y:0),shooting:false,dt:1/120)
        }
        check(settlement.phase == .victory &&
              settlement.missionSummary?.earnedTokens==20,
              "source FinishLevel gathers remaining 8 tokens plus bonus 12")
        check(settlement.tokenPickups.isEmpty,
              "FinishLevel settles and clears outstanding collectibles")
        check(settlement.missionSummary?.clearBonus==12,
              "first mission original non-boss clear bonus")
        let integrationDefaults=UserDefaults(
            suiteName:"c279-real-finish-\(UUID().uuidString)")!
        var integratedCampaign=CampaignProgress556()
        check(Sector01MissionSettlement568.commit(
              settlement.missionSummary!,
              campaign:&integratedCampaign,
              defaults:integrationDefaults),
              "real combat victory commits source campaign exactly once")
        check(integratedCampaign.completed(1) &&
              integratedCampaign.unlocked(2),
              "real CARBONIS clear unlocks sector02 in atlas state")
        check(Sector01Shop568.load(defaults:integrationDefaults).tokens==20,
              "actual Game.FinishLevel summary transfers 8 pickups +12 clear to wallet")
        check(CampaignStore556.load(defaults:integrationDefaults).completed(1),
              "end-to-end saved source first mission survives app state reconstruction")
        check(!Sector01MissionSettlement568.commit(
              settlement.missionSummary!,campaign:&integratedCampaign,
              defaults:integrationDefaults),
              "same CombatGame victory cannot credit wallet twice")
        check(Sector01Shop568.load(defaults:integrationDefaults).tokens==20,
              "source Game and shop wallet remain idempotent")

        for _ in 0..<60 {
            settlement.step(move:Vec2(x:0,y:0),
                aim:Vec2(x:0,y:0),shooting:false,dt:1/120)
        }
        check(settlement.missionSummary?.earnedTokens==20,
              "victory cannot award the clear bonus twice")
        var replayProgress=CampaignProgress556()
        _=replayProgress.finishMission(1)
        let replayEntry=Sector01Entry568.open(
            selectedSector:1,campaign:replayProgress,
            hasOriginalC279Assets:true)!
        let replayWave=Sector01PreparedWave568.prepare(
            entry:replayEntry,campaign:replayProgress,
            hasOriginalC279Assets:true,difficulty:.normal,seed:1)!
        check(replayWave.isReplay,
              "source replay suppression originates at the recorded atlas bit")
        var replayGame=CarbonisCombat568(replayWave)
        replayGame.rocks=[];replayGame.shooters=[]
        for _ in 0..<40 {
            replayGame.step(move:Vec2(x:0,y:0),
                aim:Vec2(x:0,y:0),shooting:false,dt:1/120)
        }
        check(replayGame.missionSummary?.earnedTokens==0 &&
              replayGame.missionSummary?.isReplay==true,
              "replay earns no tokens or repeated mission bonus")
        var shieldProfile=Sector01Shop568.State()
        shieldProfile.shieldCharges=1
        shieldProfile.twinOwned=true
        shieldProfile.weapon = .twin
        shieldProfile.upgradeLevel=3
        shieldProfile.rapidLevel=2
        var purchased=prepared
        purchased.shopProfile=shieldProfile
        var upgraded=CarbonisCombat568(purchased)
        upgraded.invincible=0
        upgraded.suffer(18)
        check(upgraded.drainOriginalAudioEvents568().isEmpty,
              "source shield intercept makes no fatal explosion sound")
        check(upgraded.shieldCharges==1 && upgraded.armor==7 &&
              upgraded.hull==60 && upgraded.invincible==0.8,
              "PC608: unshielded hit damages armor but does not spend 1/3 reserves")
        var rockProfile=Sector01Shop568.State()
        rockProfile.shieldCharges=1
        var equipped=prepared
        equipped.shopProfile=rockProfile
        var shieldedRock=CarbonisCombat568(equipped)
        shieldedRock.invincible=0
        shieldedRock.shooters=[]
        shieldedRock.rocks=[SphereAsteroid556(
            position:shieldedRock.flight.position,
            velocity:Vec2(x:0,y:0),radius:16,
            size:3,tier:0,health:4)]
        shieldedRock.step(move:Vec2(x:0,y:0),
            aim:Vec2(x:0,y:0),shooting:false,dt:1/120)
        check(shieldedRock.shieldCharges==1 &&
              abs(shieldedRock.invincible-0.8)<0.01 &&
              shieldedRock.armor==7,
              "PC608: unshielded rock contact hits armor, reserves remain 1/3")

        upgraded.invincible=0
        upgraded.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:1),
                      shooting:true,dt:1/120)
        check(upgraded.selectedWeapon == .twin &&
              upgraded.bullets.count==2,
              "shop Twin fires two real projectiles, not only a UI icon")
        check(upgraded.bullets.allSatisfy({
             $0.pierce==2 && abs($0.velocity.lengthSquared)>600*600
             }),"power III increases shot speed and allows two impacts")
        check(upgraded.cooldown<0.16,
              "rapid II mechanically shortens the firing interval")
        check(failure.missionSummary==nil,
              "fatal loss never creates a mission-reward result")
        check(campaign.completedMask==0,"no fake campaign completion")
        // H11 model-independent PC580 effects must affect the genuine
        // first-sector physics, not just a profile inspector or shop UI.
        var bonuses=H55SourceMechanics580.State()
        bonuses.guardianOwned=true
        bonuses.engine=1
        bonuses.thruster=1
        bonuses.stabilizer=1
        bonuses.collector=2
        bonuses.cooling=2
        bonuses.dampener=2
        bonuses.rateRank=1
        check(H55SourceMechanics580.save(bonuses),"source H11 install")
        var bonusVitals=H55Workshop580.Vitals()
        bonusVitals.hullRank=1;bonusVitals.armorRank=1
        bonusVitals.hull=75;bonusVitals.armor=40
        check(H55Workshop580.saveVitals(bonusVitals),"source talent values persist")
        defer {
            H55SourceMechanics580.reset()
            H55Workshop580.resetVitals()
        }
        var bonusSim=CarbonisCombat568(prepared)
        check(bonusSim.maxHull==75 && bonusSim.maxArmor==40 &&
              bonusSim.hull==75 && bonusSim.armor==40,
              "H11 +15/+15 talents read by actual playable source combat")
        let bonusStats=H55SourceMechanics580.shipStats(
            type:1,engine:1,stabilizer:1,thruster:1)!
        check(abs(bonusSim.flight.flight.configuration.cruiseSpeed-bonusStats.topSpeed*0.40)<0.0002 &&
              abs(bonusSim.flight.flight.configuration.control-bonusStats.acceleration/245)<0.0002,
              "PC v580 legacy Engine + Thruster genuinely change ship motion")
        check(bonusSim.guardianCharges==1,"owned Guardian grants one intercept per sector")
        bonusSim.invincible=0;bonusSim.suffer(8)
        check(bonusSim.guardianCharges==0 && bonusSim.armor==40 &&
              bonusSim.invincible==1.2,
              "guardian intercept is before armor and consumable shields")
        bonusSim.invincible=0
        bonusSim.suffer(8)
        check(bonusSim.armor==32,
              "dampener never incorrectly reduces physical collisions")
        var slowed=CarbonisCombat568(prepared)
        slowed.guardianCharges=0;slowed.invincible=0
        slowed.rocks=[];slowed.shooters=[]
        slowed.hostileShots=[CarbonisCombat568.Projectile(
            point:slowed.flight.position,velocity:Vec2(x:0,y:0),
            life:1,hostile:true,damage:8)]
        slowed.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                    shooting:false,dt:1/120)
        check(slowed.armor==36,
              "source Dampener Rank2 reduces actual hostile shot 8->4")
        var collection=CarbonisCombat568(prepared)
        collection.rocks=[];collection.shooters=[]
        collection.tokenPickups=[CarbonisCombat568.TokenPickup(
            position:Sphere67.offset(collection.flight.position,
                                      by:Vec2(x:190,y:0)),
            velocity:Vec2(x:0,y:0),value:3)]
        collection.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                        shooting:false,dt:1/120)
        check(collection.tokenPickups.count==1 &&
              collection.tokenPickups[0].velocity.lengthSquared>0,
              "real collector rank2 attracts tokens from 190m, beyond rank0 165m")
        var cooling=CarbonisCombat568(prepared)
        cooling.invincible=5
        cooling.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                     shooting:true,dt:1/120)
        let expectedInterval=H55SourceMechanics580.shotInterval(
            weapon:0,upgrade:1,rapid:0,shipType:1,rateRank:1,cooling:2)!
        check(cooling.bullets.count==1 &&
              abs(cooling.cooldown-expectedInterval)<0.0002,
              "actual C279 firing uses source rate talent and cooling")
        // PC v609 Campaign37 / Physics68 Bastion ShipType=2:
        // source mass, collision radius, engine/thruster and firing rate
        // affect the ACTUAL C279 game, not only the hangar inventory.
        var bastionState=bonuses
        bastionState.selectedShip=2
        check(H55SourceMechanics580.save(bastionState),
              "PC609 Bastion is a legitimate source-owned craft")
        let bastionSim=CarbonisCombat568(prepared)
        let bastionStats=H55SourceMechanics580.shipStats(
            type:2,engine:1,stabilizer:1,thruster:1)!
        check(bastionSim.sourceMechanics.selectedShip==2 &&
              abs(bastionSim.shipCollisionMass-5)<0.0001 &&
              abs(bastionSim.shipContactRadius-12.096)<0.001,
              "PC609 Bastion 5.0 mass and 1.08x physical impact radius")
        check(abs(bastionSim.flight.flight.configuration.cruiseSpeed -
                  bastionStats.topSpeed * 0.40)<0.0002,
              "Bastion source physical speed and engine upgrades")
        check(abs(bastionStats.fireRateScale-0.96)<0.0002,
              "Bastion source 0.96 shot interval multiplier")
        // PC609 KESTREL ShipType=0: actual C279 flight/collision/rate,
        // not a Vanguard visual substitution or a merely selectable UI.
        var kestrelState=bonuses
        kestrelState.selectedShip=0
        check(H55SourceMechanics580.save(kestrelState),
              "PC609 Kestrel is a legitimate original source-owned craft")
        let kestrelSim=CarbonisCombat568(prepared)
        let kestrelStats=H55SourceMechanics580.shipStats(
            type:0,engine:1,stabilizer:1,thruster:1)!
        check(kestrelSim.sourceMechanics.selectedShip==0 &&
              abs(kestrelSim.shipCollisionMass-2.4)<0.0001 &&
              abs(kestrelSim.shipContactRadius-10.528)<0.001,
              "PC609 Kestrel: original 2.4 mass and 0.94x contact radius")
        check(abs(kestrelSim.flight.flight.configuration.cruiseSpeed -
                  kestrelStats.topSpeed * 0.40)<0.0002,
              "Kestrel source physical speed and engine upgrades")
        check(abs(kestrelStats.fireRateScale-1.08)<0.0002,
              "Kestrel source 1.08 shot interval multiplier")
        check(abs(bonusSim.shipCollisionMass-3.4)<0.0001 &&
              abs(bonusSim.shipContactRadius-11.2)<0.0001,
              "no Vanguard physics regression when Bastion is installed")
        print("PASS H11 actual C279: source ship dynamics, talents, guardian shield, hostile dampener, collector and cooling")
        print("PASS \(checks) live Carbonis C279 flight, shot, hit, victory and defeat checks")
    }
}
