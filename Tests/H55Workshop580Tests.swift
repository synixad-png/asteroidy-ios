import Foundation

@main struct H55Workshop580Tests {
    static func check(_ x:Bool,_ reason:String) {
        precondition(x,"H11 source PC580: "+reason)
    }
    static func main() {
        check(H55Workshop580.tabs ==
              ["STATEK","DRZEWKO","UZBROJENIE","TROFEA","SERWIS","MODUŁY"],
              "source W3 six stations 1..6")
        check(H55Workshop580.ships ==
              ["KESTREL","VANGUARD","BASTION","VANGUARD X","TITAN H-01","MAMMOTH T-06"],
              "Campaign37 source ship names")
        check(H55Workshop580.modules.count==5 &&
              H55Workshop580.moduleLevelRequired==[3,2,5,6,8],
              "Modules97 five modules and rank unlock levels")
        for i in 0..<5 {
            let base=[90,75,130,150,170][i]
            let step=[100,90,120,130,140][i]
            for rank in 0...2 {
                check(H55Workshop580.moduleCost(i,rank:rank)==base+rank*step,
                      "PC v97 source purchase cost at index \(i), rank \(rank)")
            }
            check(H55Workshop580.moduleCost(i,rank:3)==nil,
                  "source modules cap level 2")
        }
        check(H55Workshop580.talentCost(rank:0)==1 &&
              H55Workshop580.talentCost(rank:1)==2 &&
              H55Workshop580.talentCost(rank:2)==3 &&
              H55Workshop580.talentCost(rank:3)==4 &&
              H55Workshop580.talentCost(rank:4)==nil,
              "PC Talents78 progressive trophies")
        let suite="H11-PC580-tests-"+UUID().uuidString
        let defaults=UserDefaults(suiteName:suite)!
        defer {defaults.removePersistentDomain(forName:suite)}
        check(H55Workshop580.loadVitals(defaults:defaults) == H55Workshop580.Vitals(),
              "missing profile always starts 60/25, no fake damage")
        var vitals=H55Workshop580.Vitals(hull:23,armor:7)
        var shop=Sector01Shop568.State()
        check(H55Workshop580.serviceMissing(0,vitals:vitals,shop:shop)==37,
              "source hull gap")
        check(H55Workshop580.serviceMissing(1,vitals:vitals,shop:shop)==18,
              "source armor gap")
        let originalWallet=shop
        check(H55Workshop580.service(0,vitals:&vitals,shop:&shop)==
              .changed("KADŁUB NAPRAWIONY") &&
              vitals.hull==60 && shop==originalWallet,
              "PC service free hull repair changes REAL state, not wallet")
        check(H55Workshop580.service(1,vitals:&vitals,shop:&shop)==
              .changed("PANCERZ ODNOWIONY") &&
              vitals.armor==25 && shop==originalWallet,
              "PC free armor repair")
        check(H55Workshop580.service(1,vitals:&vitals,shop:&shop)==
              .unchanged("STAN UKŁADU JUŻ JEST MAKSYMALNY"),
              "never bill healthy armor")
        check(H55Workshop580.servicePrice(2,vitals:vitals,shop:shop)==12,
              "source shield price Price(4) twelve tokens")
        check(!H55Workshop580.service(2,vitals:&vitals,shop:&shop).success &&
              shop==originalWallet,"no tokens: no free shield")
        shop.award(24) // real source award, not UI debug wallet
        check(H55Workshop580.service(2,vitals:&vitals,shop:&shop).success &&
              shop.shieldCharges==1 && shop.tokens==12 && shop.totalSpent==12,
              "source shop shared profile shield charge first purchase")
        check(H55Workshop580.service(2,vitals:&vitals,shop:&shop).success &&
              shop.shieldCharges==2 && shop.tokens==0 && shop.totalSpent==24,
              "second shield purchase no duplication")
        let beforeThird=shop
        check(!H55Workshop580.service(2,vitals:&vitals,shop:&shop).success &&
              shop==beforeThird,"out of credits must not change wallet")
        check(!H55Workshop580.service(3,vitals:&vitals,shop:&shop).success &&
              shop==beforeThird,"locked Vanguard X must not charge fake 240 tokens")
        check(!H55Workshop580.selectWeapon(3,shop:&shop).success &&
              !H55Workshop580.selectWeapon(4,shop:&shop).success &&
              shop==beforeThird,"unported level-13 weapons do not charge tokens")

        shop.award(125)
        check(H55Workshop580.selectWeapon(1,shop:&shop).success &&
              shop.twinOwned && shop.weapon == .twin &&
              shop.tokens==80 && shop.totalSpent==69,
              "source Twin shop Buy(0) 45 tokens and actual equipped C279 weapon")
        check(H55Workshop580.selectWeapon(2,shop:&shop).success &&
              shop.scatterOwned && shop.weapon == .scatter &&
              shop.tokens==0 && shop.totalSpent==149,
              "source Scatter Buy(1) 80 tokens and actual equipped weapon")
        check(H55Workshop580.selectWeapon(0,shop:&shop).success &&
              shop.weapon == .pulse && shop.tokens==0,
              "source free equipment switch")
        check(H55Workshop580.selectWeapon(1,shop:&shop).success &&
              shop.weapon == .twin && shop.tokens==0 &&
              shop.totalSpent==149,"re-equip owned gun never charges again")
        check(Sector01Shop568.validate(shop),"source shop store remains valid")

        check(H55Workshop580.saveVitals(vitals,defaults:defaults),
              "persist validated hull+armor")
        check(H55Workshop580.loadVitals(defaults:defaults)==vitals,
              "reload actual mission gauges for revisits")
        H55Workshop580.updateFromCombat(hull:29,armor:3,defaults:defaults)
        check(H55Workshop580.loadVitals(defaults:defaults).hull==29 &&
              H55Workshop580.loadVitals(defaults:defaults).armor==3,
              "mission actually damages two persisted gauges")
        H55Workshop580.resetVitals(defaults:defaults)
        check(H55Workshop580.loadVitals(defaults:defaults) == H55Workshop580.Vitals(),
              "PC new game clears damage")
        vitals.hull=-1
        check(!H55Workshop580.saveVitals(vitals,defaults:defaults),
              "cannot save corrupt negative hull")
        check(H55Workshop580.loadVitals(defaults:defaults) == H55Workshop580.Vitals(),
              "invalid state never replaces legitimate profile")
        print("PASS H11 PC580: 6 tabs, 6 ships, 5 modules source prices, rank limits, 4-step talents, real shop wallet+guns+shield, repair and persistence, no fake transactions")
    }
}
