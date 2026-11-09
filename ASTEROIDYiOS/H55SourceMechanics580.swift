import Foundation

/// Source-driven gameplay state independent from GLB models.
/// Formulas: Windows/src/Campaign37.cs, Modules97.cs, Talents78.cs,
/// Game.cs, Physics68.cs and ShopProfile56.cs from supplied PC v580.
/// Wallet stays in Sector01Shop568.State; this file NEVER duplicates credits.
enum H55SourceMechanics580 {
    static let shipNames=H55Workshop580.ships
    static let moduleNames=H55Workshop580.modules
    static let bossMask=0x888888     // PC: only sectors 4,8,12,16,20,24
    static let timeMask=(1 << 25)-1

    struct State:Codable,Equatable {
        var selectedShip=1
        var vanguardXOwned=false
        var titanOwned=false
        var mammothOwned=false
        var engine=0,collector=0,stabilizer=0
        var guardianOwned=false
        var cooling=0,thruster=0,dampener=0,guardianStrike=0,guardianFocus=0
        var bossTrophies=0,timeTrophies=0,rateRank=0

        var moduleRanks:[Int] { [cooling,thruster,dampener,guardianStrike,guardianFocus] }
        var ownedShips:[Bool] { [true,true,true,vanguardXOwned,titanOwned,mammothOwned] }
        var valid:Bool {
            (0...5).contains(selectedShip) && ownedShips[selectedShip] &&
            (0...2).contains(engine) && (0...2).contains(collector) &&
            (0...2).contains(stabilizer) &&
            moduleRanks.allSatisfy{(0...2).contains($0)} &&
            (0...4).contains(rateRank) &&
            bossTrophies >= 0 && timeTrophies >= 0 &&
            (bossTrophies & ~Self.bossMask)==0 &&
            (timeTrophies & ~Self.timeMask)==0 &&
            (guardianOwned || guardianStrike==0 && guardianFocus==0)
        }
        var trophiesEarned:Int {
            bossTrophies.nonzeroBitCount + timeTrophies.nonzeroBitCount
        }
        func trophiesFree(vitals:H55Workshop580.Vitals)->Int {
            max(0,trophiesEarned -
                Self.triangle(vitals.hullRank) -
                Self.triangle(vitals.armorRank) -
                Self.triangle(rateRank))
        }
        static func triangle(_ rank:Int)->Int {rank*(rank+1)/2}
    }

    enum SourceEffect:Equatable {
        case changed,unchanged,unavailable,insufficientFunds
    }
    private static let key="asteroidy.ios.pc580.h11.source-mechanics"
    static func load(defaults:UserDefaults = .standard)->State {
        guard let bytes=defaults.data(forKey:key),
              let saved=try? JSONDecoder().decode(State.self,from:bytes),
              saved.valid else{return State()}
        return saved
    }
    @discardableResult static func save(_ state:State,
                     defaults:UserDefaults = .standard)->Bool {
        guard state.valid,let bytes=try? JSONEncoder().encode(state)
            else{return false}
        defaults.set(bytes,forKey:key)
        return true
    }
    static func reset(defaults:UserDefaults = .standard) {
        defaults.removeObject(forKey:key)
    }

    /// PC Campaign37 ShipOwned368. The older 3 ships are always owned;
    /// VANGUARD X is purchased in HubService95, Titan/Mammoth in HubEquip369.
    static func shipOwned(_ ship:Int,state:State)->Bool {
        (0...5).contains(ship) && state.ownedShips[ship]
    }
    static func shipPrice(_ ship:Int)->Int? {
        switch ship {case 3:return 240;case 4:return 420
        case 5:return 620;default:return nil}
    }
    /// The mechanics can be purchased and saved without GLB, but the caller
    /// must NEVER render the VANGUARD as a different ship. UI must explicitly
    /// disclose missing visual assets before committing a purchase/equip.
    static func buyAndEquipShip(_ ship:Int,sector:Int,
                                state:inout State,
                                wallet:inout Sector01Shop568.State)->SourceEffect {
        guard state.valid,Sector01Shop568.validate(wallet),
              (0...5).contains(ship),(1...25).contains(sector)
              else{return .unavailable}
        if ship==3 && !state.vanguardXOwned && sector<13 {return .unavailable}
        if !shipOwned(ship,state:state) {
            guard let cost=shipPrice(ship) else{return .unavailable}
            guard wallet.tokens>=cost else{return .insufficientFunds}
            var next=state
            switch ship {
            case 3:next.vanguardXOwned=true
            case 4:next.titanOwned=true
            case 5:next.mammothOwned=true
            default:return .unavailable
            }
            next.selectedShip=ship
            guard next.valid else{return .unavailable}
            state=next
            wallet.tokens-=cost
            wallet.totalSpent=addCapped(wallet.totalSpent,cost)
            return .changed
        }
        guard ship != state.selectedShip else{return .unchanged}
        state.selectedShip=ship
        return .changed
    }

    /// Legacy Game.cs shop items 6..9; source buy only after unlocking.
    static func legacyModuleCost(_ item:Int,state:State)->Int? {
        switch item {
        case 6:return 75+state.engine*85
        case 7:return 55+state.collector*65
        case 8:return 190
        case 9:return 65+state.stabilizer*70
        default:return nil
        }
    }
    static func buyLegacyModule(_ item:Int,sector:Int,
                                state:inout State,
                                wallet:inout Sector01Shop568.State)->SourceEffect {
        guard state.valid,Sector01Shop568.validate(wallet),
              (1...24).contains(sector),
              let cost=legacyModuleCost(item,state:state)
              else{return .unavailable}
        let allowed:Bool
        switch item {
        case 6:allowed=state.engine<2
        case 7:allowed=state.collector<2
        case 8:allowed = !state.guardianOwned && sector>=6
        case 9:allowed=state.stabilizer<2
        default:allowed=false
        }
        guard allowed else{return .unavailable}
        guard wallet.tokens>=cost else{return .insufficientFunds}
        var next=state
        switch item {
        case 6:next.engine+=1
        case 7:next.collector+=1
        case 8:next.guardianOwned=true
        case 9:next.stabilizer+=1
        default:return .unavailable
        }
        guard next.valid else{return .unavailable}
        state=next;wallet.tokens-=cost
        wallet.totalSpent=addCapped(wallet.totalSpent,cost)
        return .changed
    }

    /// Exact PC Modules97: ranks 0..2, sector requirements 3/2/5/6/8,
    /// GuardianStrike and Focus require previous GuardianOwned purchase.
    static func buyModule(_ id:Int,sector:Int,state:inout State,
                          wallet:inout Sector01Shop568.State)->SourceEffect {
        guard state.valid,Sector01Shop568.validate(wallet),
              (1...24).contains(sector),moduleNames.indices.contains(id),
              sector>=H55Workshop580.moduleLevelRequired[id],
              (id<3 || state.guardianOwned) else{return .unavailable}
        let rank=state.moduleRanks[id]
        guard rank<2,
              let cost=H55Workshop580.moduleCost(id,rank:rank)
              else{return .unavailable}
        guard wallet.tokens>=cost else{return .insufficientFunds}
        var next=state
        switch id {
        case 0:next.cooling+=1
        case 1:next.thruster+=1
        case 2:next.dampener+=1
        case 3:next.guardianStrike+=1
        case 4:next.guardianFocus+=1
        default:return .unavailable
        }
        guard next.valid else{return .unavailable}
        state=next
        wallet.tokens-=cost
        wallet.totalSpent=addCapped(wallet.totalSpent,cost)
        return .changed
    }

    /// Original Talents78 costs 1,2,3,4 collected trophies. Vitals ranks
    /// are the already-persisted H11 combat truth, not a second HUD gauge.
    static func buyTalent(_ id:Int,state:inout State,
                          vitals:inout H55Workshop580.Vitals)->SourceEffect {
        guard state.valid,vitals.valid,(0...2).contains(id) else{return .unavailable}
        let rank=id==0 ? vitals.hullRank : id==1 ? vitals.armorRank : state.rateRank
        guard rank<4 else{return .unavailable}
        guard state.trophiesFree(vitals:vitals)>=rank+1 else{return .insufficientFunds}
        if id==0 {vitals.hullRank+=1;vitals.hull+=15}
        else if id==1 {vitals.armorRank+=1;vitals.armor+=15}
        else {state.rateRank+=1}
        return .changed
    }

    enum MissionObjective {case normal,escort,defend,waves}
    static func timeTarget(sector:Int,objective:MissionObjective)->Int? {
        guard (1...25).contains(sector) else{return nil}
        var seconds=94+(sector-1)*7+(sector%4==0 ? 85:0)
        switch objective {
        case .escort,.defend: seconds+=46
        case .waves: seconds+=52
        case .normal: break
        }
        return seconds
    }
    /// Use ONLY after confirmed first completion (Game.FinishLevel).
    /// Replay and duplicate events are free of trophies.
    static func awardTimeTrophy(sector:Int,elapsed:Float,
                  objective:MissionObjective,state:inout State)->Bool {
        guard state.valid,elapsed.isFinite,elapsed>=0,
              let target=timeTarget(sector:sector,objective:objective),
              elapsed<=Float(target) else{return false}
        let bit=1 << (sector-1)
        guard state.timeTrophies & bit == 0 else{return false}
        state.timeTrophies |= bit
        return true
    }
    /// PC DropBossTrophy78 then CollectBossTrophy78: never award for
    /// simply entering the battle or merely killing a boss. Requires
    /// the game's actual collected trophy pickup event.
    static func collectBossTrophy(sector:Int,collectedPickup:Bool,
                                  state:inout State)->Bool {
        guard state.valid,collectedPickup,(1...24).contains(sector),
              sector%4==0 else{return false}
        let bit=1 << (sector-1)
        guard state.bossTrophies & bit == 0 else{return false}
        state.bossTrophies |= bit
        return true
    }

    struct ShipStats:Equatable {
        let acceleration:Float,topSpeed:Float,turnSpeed:Float
        let fireRateScale:Float,contactRadius:Float,mass:Float
    }
    /// Exact Campaign37 + Physics68 coefficients and mining detached mode.
    static func shipStats(type:Int,engine:Int=0,stabilizer:Int=0,
                 thruster:Int=0,miningDetached:Bool=false)->ShipStats? {
        guard (0...5).contains(type),(0...2).contains(engine),
              (0...2).contains(stabilizer),(0...2).contains(thruster)
              else{return nil}
        let a:[Float]=[1.18,1,0.82,0.79,0.67,miningDetached ? 1.30:0.60]
        let s:[Float]=[1.12,1,0.86,0.93,0.76,miningDetached ? 1.16:0.70]
        let t:[Float]=[1.12,1,0.84,0.55,0.42,miningDetached ? 1.35:0.35]
        let radius:[Float]=[0.94,1,1.08,1.12,1.30,miningDetached ? 0.65:1.46]
        let mass:[Float]=[2.4,3.4,5,6.2,10,miningDetached ? 1.5:12.5]
        return ShipStats(acceleration:245*a[type]*(1+Float(engine)*0.06)*
                            (1+Float(thruster)*0.045),
                         topSpeed:390*s[type]*(1+Float(engine)*0.035)*
                            (1+Float(thruster)*0.025),
                         turnSpeed:3.8*t[type]*(1+Float(stabilizer)*0.04),
                         fireRateScale:type==0 ? 1.08 : type==2 ? 0.96:1,
                         contactRadius:11.2*radius[type],mass:mass[type])
    }
    /// PC ShotIntervalBase97 + Modules97.ShotInterval. Used by real C279.
    static func shotInterval(weapon:Int,upgrade:Int,rapid:Int,
                    shipType:Int,rateRank:Int,cooling:Int)->Float? {
        guard (0...4).contains(weapon),(1...3).contains(upgrade),
              (0...2).contains(rapid),(0...5).contains(shipType),
              (0...4).contains(rateRank),(0...2).contains(cooling)
              else{return nil}
        let talent:Float=1/(1+0.06*Float(rateRank))
        let fireScale:Float=shipType==0 ? 1.08 : shipType==2 ? 0.96:1
        let base:Float
        switch weapon {
        case 3:base=(0.32-0.02*Float(upgrade-1))/(1+0.15*Float(rapid))
        case 4:base=(0.29-0.015*Float(upgrade-1))/(1+0.15*Float(rapid))
        default:
            let interval:Float=weapon==2 ? 0.31 : weapon==1 ? 0.20:0.16
            let reduction:Float=weapon==2 ? 0.03:0.02
            base=max(0.075,(interval-reduction*Float(upgrade-1))/
                     (1+0.15*Float(rapid))*fireScale*talent)
        }
        let withTalent:Float=weapon>=3 ? base*fireScale*talent : base
        return max(0.065,withTalent*(1-0.06*Float(cooling)))
    }
    static func hostileShotDamage(_ damage:Int,dampener:Int)->Int {
        max(1,damage-2*max(0,min(2,dampener)))
    }
    static func collectorRadius(rank:Int)->Float {165+Float(max(0,min(2,rank)))*30}
    static func collectorSpeed(rank:Int)->Float {200+Float(max(0,min(2,rank)))*25}
    static func guardianShotCooldown(strike:Int,focus:Int)->Float {
        max(0.96,1.38-0.07*Float(strike)-0.04*Float(focus))
    }
    static func guardianShotDamage(strike:Int)->Int {1+(strike>=2 ? 1:0)}
    static func guardianTargetRadius(focus:Int)->Float {210+Float(focus)*18}
    private static func addCapped(_ value:Int,_ cost:Int)->Int {
        value>Int.max-cost ? Int.max : value+cost
    }

    /// Asset registration is intentionally data, never a fallback mesh.
    static func registeredModelName(forShip id:Int)->String? {
        guard id==1 else{return nil}
        return "SOURCE-C279-VANGUARD" // the only presently verified iOS 3D model
    }
}
