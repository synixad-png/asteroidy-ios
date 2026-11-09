import Foundation

@main struct H55SourceMechanics580Tests {
    static func check(_ condition:Bool,_ explanation:String) {
        precondition(condition,"H11 PC580 SOURCE FAILURE: "+explanation)
    }
    static func close(_ a:Float,_ b:Float,_ key:String,tolerance:Float=0.00012) {
        check(abs(a-b)<tolerance,key+" got "+String(a)+" expected "+String(b))
    }
    static func main() {
        let suite="PC580-H11-"+UUID().uuidString
        let d=UserDefaults(suiteName:suite)!
        defer{d.removePersistentDomain(forName:suite)}
        var s=H55SourceMechanics580.load(defaults:d)
        check(s.selectedShip==1 && s.ownedShips == [true,true,true,false,false,false],
              "six ships original PC owned defaults")
        check(H55SourceMechanics580.registeredModelName(forShip:0)==nil &&
              H55SourceMechanics580.registeredModelName(forShip:1) != nil &&
              H55SourceMechanics580.registeredModelName(forShip:5)==nil,
              "never claim VANGUARD GLB represents another craft")
        check(s.valid,"default state valid")
        let expectedA:[Float]=[1.18,1,0.82,0.79,0.67,0.60]
        let expectedS:[Float]=[1.12,1,0.86,0.93,0.76,0.70]
        let expectedT:[Float]=[1.12,1,0.84,0.55,0.42,0.35]
        let expectedR:[Float]=[0.94,1,1.08,1.12,1.30,1.46]
        let expectedMass:[Float]=[2.4,3.4,5,6.2,10,12.5]
        for ship in 0..<6 {
            let r=H55SourceMechanics580.shipStats(type:ship)!
            close(r.acceleration,245*expectedA[ship],"Acceleration source for ship \(ship)")
            close(r.topSpeed,390*expectedS[ship],"TopSpeed source for ship \(ship)")
            close(r.turnSpeed,3.8*expectedT[ship],"TurnSpeed source for ship \(ship)")
            close(r.contactRadius,11.2*expectedR[ship],"ContactRadius source \(ship)")
            close(r.mass,expectedMass[ship],"Physics68 ship mass \(ship)")
        }
        let mining=H55SourceMechanics580.shipStats(type:5,miningDetached:true)!
        close(mining.acceleration,245*1.30,"transport miner detached acceleration")
        close(mining.topSpeed,390*1.16,"transport miner detached speed")
        close(mining.turnSpeed,3.8*1.35,"transport miner detached turn")
        close(mining.contactRadius,11.2*0.65,"transport miner detached radius")
        close(mining.mass,1.5,"transport miner detached mass")
        let boosted=H55SourceMechanics580.shipStats(type:1,engine:2,
                                                 stabilizer:2,thruster:2)!
        close(boosted.acceleration,245*1.12*1.09,"source engine+thruster multipliers")
        close(boosted.topSpeed,390*1.07*1.05,"source engine+thruster speed")
        close(boosted.turnSpeed,3.8*1.08,"source stabilizer turn")

        var wallet=Sector01Shop568.State()
        wallet.award(2000)
        let starting=wallet.tokens
        check(H55SourceMechanics580.buyAndEquipShip(3,sector:12,state:&s,wallet:&wallet) == .unavailable &&
              wallet.tokens==starting,"prototype gated until sector 13")
        check(H55SourceMechanics580.buyAndEquipShip(3,sector:13,state:&s,wallet:&wallet) == .changed &&
              s.vanguardXOwned && s.selectedShip==3 && wallet.tokens==starting-240,
              "original PC Vanguard X real atomic shop state")
        check(H55SourceMechanics580.buyAndEquipShip(4,sector:13,state:&s,wallet:&wallet) == .changed &&
              s.titanOwned && wallet.tokens==starting-240-420,
              "original PC TITAN 420")
        check(H55SourceMechanics580.buyAndEquipShip(5,sector:13,state:&s,wallet:&wallet) == .changed &&
              s.mammothOwned && wallet.tokens==starting-240-420-620,
              "original PC MAMMOTH 620")
        check(H55SourceMechanics580.buyAndEquipShip(5,sector:13,state:&s,wallet:&wallet) == .unchanged,
              "never charge an already selected ship")
        check(H55SourceMechanics580.buyAndEquipShip(1,sector:1,state:&s,wallet:&wallet) == .changed &&
              wallet.tokens==720,"return to original Vanguard does not charge")

        var r=H55SourceMechanics580.State()
        var w=Sector01Shop568.State()
        w.award(4000)
        check(H55SourceMechanics580.buyLegacyModule(8,sector:5,state:&r,wallet:&w) == .unavailable,
              "original guardian locked before sector 6")
        check(H55SourceMechanics580.buyLegacyModule(8,sector:6,state:&r,wallet:&w) == .changed &&
              r.guardianOwned && w.tokens==3810,"source original guardian price 190")
        check(H55SourceMechanics580.buyLegacyModule(8,sector:6,state:&r,wallet:&w) == .unavailable,
              "original GuardianOwned prevents duplicate")
        check(H55SourceMechanics580.buyLegacyModule(6,sector:2,state:&r,wallet:&w) == .changed &&
              r.engine==1 && w.tokens==3735,"legacy engine rank1 price75")
        check(H55SourceMechanics580.buyLegacyModule(6,sector:2,state:&r,wallet:&w) == .changed &&
              r.engine==2 && w.tokens==3575,"legacy engine rank2 price160")
        check(H55SourceMechanics580.buyLegacyModule(6,sector:2,state:&r,wallet:&w) == .unavailable,
              "engine rank capped 2")
        check(H55SourceMechanics580.buyLegacyModule(7,sector:2,state:&r,wallet:&w) == .changed &&
              r.collector==1 && w.tokens==3520,"collector price55")
        check(H55SourceMechanics580.buyLegacyModule(9,sector:2,state:&r,wallet:&w) == .changed &&
              r.stabilizer==1 && w.tokens==3455,"stabilizer price65")
        for id in 0..<5 {
            check(H55SourceMechanics580.buyModule(id,sector:1,state:&r,wallet:&w) == .unavailable,
                  "advanced module must respect sector level \(id)")
            let threshold=H55Workshop580.moduleLevelRequired[id]
            let cost=H55Workshop580.moduleCost(id,rank:0)!
            let before=w.tokens
            check(H55SourceMechanics580.buyModule(id,sector:threshold,state:&r,wallet:&w) == .changed,
                  "buy actual advanced rank 1 \(id)")
            check(w.tokens==before-cost && r.moduleRanks[id]==1,
                  "source Advanced Modules97 exact price/level \(id)")
            check(H55SourceMechanics580.buyModule(id,sector:threshold,state:&r,wallet:&w) == .changed &&
                  r.moduleRanks[id]==2,"module rank 2 source")
            let post=w
            check(H55SourceMechanics580.buyModule(id,sector:threshold,state:&r,wallet:&w) == .unavailable &&
                  w==post,"rank 2 maximum no further charge")
        }
        check(H55SourceMechanics580.save(r,defaults:d) &&
              H55SourceMechanics580.load(defaults:d)==r,
              "persistent source module/guardian/ships state round trip")

        var trophies=H55SourceMechanics580.State()
        var hp=H55Workshop580.Vitals()
        check(H55SourceMechanics580.timeTarget(sector:1,objective:.normal)==94,
              "source first-sector time target 94")
        check(H55SourceMechanics580.timeTarget(sector:4,objective:.waves)==
              94+21+85+52,"source boss/4 waves time target")
        check(!H55SourceMechanics580.awardTimeTrophy(sector:1,elapsed:94.01,objective:.normal,state:&trophies),
              "no undeserved first-sector trophy")
        check(H55SourceMechanics580.awardTimeTrophy(sector:1,elapsed:94,objective:.normal,state:&trophies) &&
              !H55SourceMechanics580.awardTimeTrophy(sector:1,elapsed:90,objective:.normal,state:&trophies),
              "exact one source time trophy on true mission completion")
        check(trophies.trophiesEarned==1 && trophies.trophiesFree(vitals:hp)==1,
              "unused trophy visible")
        check(H55SourceMechanics580.buyTalent(0,state:&trophies,vitals:&hp) == .changed &&
              hp.hullRank==1 && hp.hull==75 &&
              trophies.trophiesFree(vitals:hp)==0,"actual hull +15 and consumes first trophy")
        check(H55SourceMechanics580.buyTalent(1,state:&trophies,vitals:&hp) == .insufficientFunds &&
              hp.armorRank==0,"cannot spend more trophies than earned")
        check(!H55SourceMechanics580.collectBossTrophy(sector:3,collectedPickup:true,state:&trophies),
              "boss only 4,8,..24")
        check(!H55SourceMechanics580.collectBossTrophy(sector:4,collectedPickup:false,state:&trophies),
              "boss kill alone is not pickup")
        check(H55SourceMechanics580.collectBossTrophy(sector:4,collectedPickup:true,state:&trophies) &&
              !H55SourceMechanics580.collectBossTrophy(sector:4,collectedPickup:true,state:&trophies),
              "physical trophy pickup grants exactly one")
        check(H55SourceMechanics580.buyTalent(2,state:&trophies,vitals:&hp) == .changed &&
              trophies.rateRank==1 && trophies.trophiesFree(vitals:hp)==0,
              "rate rank effect consumes trophy")
        close(H55SourceMechanics580.shotInterval(
             weapon:0,upgrade:1,rapid:0,shipType:1,rateRank:0,cooling:0)!,0.16,
             "existing Pulse C279 baseline exact")
        close(H55SourceMechanics580.shotInterval(
             weapon:0,upgrade:1,rapid:0,shipType:1,rateRank:1,cooling:2)!,
             0.16 / 1.06 * 0.88,"source talent+cooling both apply in live combat")
        close(H55SourceMechanics580.shotInterval(
             weapon:3,upgrade:3,rapid:1,shipType:2,rateRank:2,cooling:1)!,
             (0.32-0.04)/1.15*0.96/1.12*0.94,
             "source advanced Rail coefficient")
        check(H55SourceMechanics580.hostileShotDamage(8,dampener:2)==4 &&
              H55SourceMechanics580.hostileShotDamage(2,dampener:2)==1,
              "only source hostile projectile damage reduction")
        close(H55SourceMechanics580.collectorRadius(rank:2),225,"source collector radius")
        close(H55SourceMechanics580.collectorSpeed(rank:2),250,"source collector speed")
        close(H55SourceMechanics580.guardianShotCooldown(strike:2,focus:2),1.16,
              "source Guardian plasma cooldown")
        check(H55SourceMechanics580.guardianShotDamage(strike:2)==2 &&
              H55SourceMechanics580.guardianShotDamage(strike:1)==1,
              "Guardian strike damage")
        print("PASS PC580 H11: 6 source ship physics, 5 advanced + 4 legacy modules with atomic wallet, genuine trophies/talents, collector/guardian/dampener/shot intervals, 1:1 persistence and no fake GLB")
    }
}
