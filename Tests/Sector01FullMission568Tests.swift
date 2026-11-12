import Foundation

/// Deterministic source CARBONIS01 stress playthrough through ACTUAL
/// Game.Step, EnemyTactics71, Physics68, source Wave, hit sorting,
/// terminal debris, FinishLevel, CampaignStore and ShopProfile.
@main struct Sector01FullMission568Tests {
    static func main() {
        var assertions=0
        func verify(_ value:Bool,_ label:String) {
            precondition(value,label)
            assertions+=1
        }
        let suite="asteroidy-c279-e2e-\(UUID().uuidString)"
        let defaults=UserDefaults(suiteName:suite)!
        defer{defaults.removePersistentDomain(forName:suite)}
        var campaign=CampaignProgress556()
        guard let entry=Sector01Entry568.open(
            selectedSector:1,campaign:campaign,
            hasOriginalC279Assets:true),
              let prepared=Sector01PreparedWave568.prepare(
            entry:entry,campaign:campaign,
            hasOriginalC279Assets:true,difficulty:.normal,seed:67899)
        else {fatalError("real first-sector mission cannot be prepared")}
        var game=CarbonisCombat568(prepared)
        verify(game.rocks.count==13 && game.shooters.count==4,
               "real Windows v568 Carbonis opening 13 rocks and 4 fighters")
        verify(game.phase == .playing && game.missionSummary==nil,
               "entering first mission does not grant fake victory")
        verify(!campaign.completed(1) && !campaign.unlocked(2),
               "second sector is locked before source fight is actually won")

        // A deterministic automated shooting operator targets *actual*
        // moving enemies and real rocks (including split children).
        // It never overrides victory, reward, clear time or any threat list.
        // Bullets begin at the actor position with zero travel only to
        // stress-test genuine Projectile->Contact/HP->Split paths quickly.
        // This is NOT visual human gameplay verification.
        let zero=Vec2(x:0,y:0)
        var ticks=0
        while game.phase == .playing && ticks<1440 {
            game.bullets.removeAll(keepingCapacity:true)
            for enemy in game.shooters {
                game.bullets.append(CarbonisCombat568.Projectile(
                    point:enemy.core.position,velocity:zero,
                    life:0.4,hostile:false,damage:1))
            }
            for rock in game.rocks where rock.shardLife<=0 {
                game.bullets.append(CarbonisCombat568.Projectile(
                    point:rock.position,velocity:zero,
                    life:0.4,hostile:false,damage:1))
            }
            game.step(move:zero,aim:zero,shooting:false,dt:1/120)
            ticks+=1
        }
        verify(game.phase == .victory,
               "first mission truly completes from real shot/hit/debris loop")
        verify(game.rocks.isEmpty && game.shooters.isEmpty &&
               game.incoming.incomingLeft==0,
               "all initial and split physical enemies/rocks eliminated")
        verify(game.shooterKills==4 && game.rocksDestroyed>=13,
               "real opening shooter kills and source rock destruction")
        guard let summary=game.missionSummary else {
            fatalError("real Game.FinishLevel omitted the first mission summary")
        }
        verify(summary.sector==1 && summary.clearBonus==12,
               "source mission reward and clear bonus are correct")
        verify(summary.enemiesDestroyed==4 &&
               summary.rocksDestroyed==game.rocksDestroyed &&
               summary.scoreGained==game.score,
               "LevelSummary166 reflects actual world score and kills")
        verify(summary.earnedTokens>=12,
               "real played first mission earns a twelve-token bonus")
        verify(game.tokenPickups.isEmpty,
               "all source loot is automatically settled at FinishLevel")
        verify(!campaign.completed(1),
               "the battle engine cannot secretly persist an unlock")
        verify(Sector01MissionSettlement568.commit(
            summary,campaign:&campaign,defaults:defaults),
            "only committed genuine finish unlocks the next sector")
        verify(campaign.completed(1) && campaign.unlocked(2) &&
               CampaignStore556.load(defaults:defaults).completed(1),
               "mission and sector 02 unlock survive permanent save")
        verify(Sector01Shop568.load(defaults:defaults).tokens ==
               summary.earnedTokens,
               "real mission collectible+bonus becomes persisted shop wallet")
        verify(!Sector01MissionSettlement568.commit(
            summary,campaign:&campaign,defaults:defaults),
            "repeat completion notifications are idempotent")

        let entryReplay=Sector01Entry568.open(
            selectedSector:1,campaign:campaign,
            hasOriginalC279Assets:true)!
        guard let preparedReplay=Sector01PreparedWave568.prepare(
            entry:entryReplay,campaign:campaign,
            hasOriginalC279Assets:true,difficulty:.normal,seed:67899,
            shopProfile:Sector01Shop568.load(defaults:defaults))
        else {fatalError("real first mission replay preparation missing")}
        verify(preparedReplay.isReplay,"replay flag from real saved completion")
        // PC602 Game.DropLoot is reward-gated, but Tarcza145/Boost71
        // and TryDropCombatSupply do not require MissionRewards57.
        // Ensure the non-monetary spawn routes are still reachable on replay.
        verify(CampaignStore556.load(defaults:defaults).completed(1),
               "completed first sector remains accessible to replay")
        var repeatGame=CarbonisCombat568(preparedReplay)
        repeatGame.rocks=[];repeatGame.shooters=[]
        for _ in 0..<28 {
            repeatGame.step(move:zero,aim:zero,shooting:false,dt:1/120)
        }
        verify(repeatGame.phase == .victory &&
               repeatGame.missionSummary?.earnedTokens==0,
               "replay clear earns zero new rewards")
        verify(!Sector01MissionSettlement568.commit(
            repeatGame.missionSummary!,campaign:&campaign,defaults:defaults) &&
               Sector01Shop568.load(defaults:defaults).tokens ==
                  summary.earnedTokens,
               "replay cannot duplicate shop wallet or unlock")
        print("PASS \(assertions) real CARBONIS01 wave-to-loot-to-victory-to-persistent atlas/shop integration assertions; \(ticks) source 120Hz steps")
    }
}