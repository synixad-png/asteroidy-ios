import Foundation

@main struct Sector01MissionFinish568Tests {
    static func main() {
        var count=0
        func check(_ yes:Bool,_ title:String) {
            precondition(yes,title)
            count+=1
        }
        let defaults=UserDefaults(suiteName:"asteroidy-c279-test-\(UUID().uuidString)")!
        
        var campaign=CampaignProgress556()
        var shop=Sector01Shop568.load(defaults:defaults)
        check(shop.tokens==0 && shop.upgradeLevel==1 &&
              shop.rapidLevel==0 && shop.weapon == .pulse &&
              shop.lives==3,"new source profile defaults")
        check(!shop.buy(.twin),"cannot buy without sufficient tokens")
        let summary=Sector01MissionSummary568.completedFirstMission(
            rocks:27,enemies:4,score:1750,lootTokens:38,
            replay:false,elapsed:135)
        check(summary.sector==1 && summary.clearBonus==12,
              "original Level1 Game.FinishLevel reward 12")
        check(summary.collectedTokens==38 && summary.earnedTokens==50,
              "original LevelSummary166 pickup+bonus reconciliation")
        check(Sector01MissionSettlement568.commit(
            summary,campaign:&campaign,defaults:defaults),
            "source first clear grants exactly one completion bit")
        check(campaign.completed(1) && campaign.unlocked(2),
              "first mission completion unlocks real second atlas sector")
        check(Sector01Shop568.load(defaults:defaults).tokens==50,
              "source shop wallet saved with reward")
        check(!Sector01MissionSettlement568.commit(
            summary,campaign:&campaign,defaults:defaults),
            "duplicate victory callback never grants reward twice")
        check(Sector01Shop568.load(defaults:defaults).tokens==50,
              "duplicate save does not inflate earned tokens")
        check(CampaignStore556.load(defaults:defaults).completed(1),
              "campaign bit survives app restart")
        let replay=Sector01MissionSummary568.completedFirstMission(
            rocks:45,enemies:6,score:5000,lootTokens:70,
            replay:true,elapsed:90)
        check(replay.earnedTokens==0 && replay.clearBonus==0,
              "source BeginRewards57 suppresses replay token reward")
        check(!Sector01MissionSettlement568.commit(
            replay,campaign:&campaign,defaults:defaults),
            "replaying completed mission preserves single bit")
        check(Sector01Shop568.load(defaults:defaults).tokens==50,
              "replay does not recredit wallet")
        var purchase=Sector01Shop568.load(defaults:defaults)
        check(purchase.price(.twin)==45 && purchase.price(.scatter)==80 &&
              purchase.price(.power)==60 && purchase.price(.rapid)==75 &&
              purchase.price(.shield)==12 && purchase.price(.repair)==70,
              "original first-level shop prices")
        check(purchase.buy(.twin),"twin can be bought for 45")
        check(purchase.tokens==5 && purchase.weapon == .twin &&
              purchase.twinOwned,"twin purchase actually equips weapon")
        check(!purchase.buy(.scatter),"80-token Scatter cannot buy with 5")
        check(purchase.equip(.pulse),"owned Pulse can be re-equipped")
        check(!purchase.equip(.scatter),"unowned Scatter cannot be equipped")
        check(purchase.equip(.twin),"owned Twin can be equipped")
        check(purchase.buy(.twin),"original owned equipment re-equip costs zero")
        Sector01Shop568.save(purchase,defaults:defaults)
        check(Sector01Shop568.load(defaults:defaults)==purchase,
              "shop inventory, credits and active weapon survive restart")
        var upgrades=Sector01Shop568.State(tokens:1400)
        check(upgrades.buy(.power) && upgrades.upgradeLevel==2 &&
              upgrades.tokens==1340,"first source power upgrade 60")
        check(upgrades.buy(.power) && upgrades.upgradeLevel==3 &&
              upgrades.tokens==1190,"second source power upgrade 150")
        check(!upgrades.buy(.power),"unported ion ammo not sold")
        check(upgrades.buy(.rapid) && upgrades.rapidLevel==1 &&
              upgrades.tokens==1115,"first source rapid upgrade 75")
        check(upgrades.buy(.rapid) && upgrades.rapidLevel==2 &&
              upgrades.tokens==975,"second source rapid upgrade 140")
        check(!upgrades.buy(.rapid),"unported bombs not sold")
        for _ in 0..<3 {check(upgrades.buy(.shield),
                               "source shield 12 tokens per charge")}
        check(upgrades.shieldCharges==3 && !upgrades.buy(.shield),
              "source shield charge cap three")
        check(upgrades.buy(.repair) && upgrades.lives==4 &&
              upgrades.repairsBought==1,
              "source repair raises lives to four and adjusts next price")
        check(upgrades.price(.repair)==95,"second repair costs 95")
        check(upgrades.buy(.repair) && upgrades.lives==5,
              "second repair reaches source life cap five")
        check(!upgrades.buy(.repair),"no sixth source life")
        check(Sector01Shop568.validate(upgrades),
              "all upgraded source state remains valid")
        var damaged=upgrades;damaged.lives=6
        check(!Sector01Shop568.validate(damaged),
              "tampered profile with over-cap life rejected")
        let noRewards=Sector01MissionSummary568.completedFirstMission(
            rocks:0,enemies:0,score:0,lootTokens:60,
            replay:true,elapsed:0)
        check(noRewards.collectedTokens==0 && noRewards.earnedTokens==0,
              "replay cannot claim uncollected phantom rewards")
        print("PASS \(count) original first-sector mission settlement, replay and real 6-item service shop assertions")
    }
}
