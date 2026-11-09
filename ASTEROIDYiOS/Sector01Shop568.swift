import Foundation

/// Windows Game.cs v568/v580: canonical first-sector shop and PC v580
/// sector-13 Rail/Swarm weapon ownership. Existing JSON profiles migrate
/// without losing credits or weapons. Ion ammo/bombs remain explicitly
/// unimplemented and must not be falsely sold.
enum Sector01Shop568 {
    enum Weapon:Int,Codable,CaseIterable {
        case pulse=0,twin=1,scatter=2,rail=3,swarm=4
        var shortLabel:String {
            switch self {
            case .pulse:return "IMPULS"
            case .twin:return "PODWÓJNA"
            case .scatter:return "WACHLARZ"
            case .rail:return "GAUSS"
            case .swarm:return "RÓJ ŁOWCÓW"
            }
        }
    }
    enum Item:Int,CaseIterable {
        case twin=0,scatter=1,power=2,rapid=3,shield=4,repair=5
        var title:String {
            switch self {
            case .twin:return "PODWÓJNE DZIAŁKO"
            case .scatter:return "WACHLARZ PLAZMY"
            case .power:return "MOC BRONI"
            case .rapid:return "SZYBKOSTRZELNOŚĆ"
            case .shield:return "ŁADUNEK OSŁONY"
            case .repair:return "NAPRAWA STATKU"
            }
        }
    }
    struct State:Codable,Equatable {
        var tokens:Int=0
        var totalEarned:Int=0
        var totalSpent:Int=0
        var twinOwned:Bool=false
        var scatterOwned:Bool=false
        var railOwned:Bool=false
        var swarmOwned:Bool=false
        var weapon:Weapon = .pulse
        var upgradeLevel:Int=1
        var rapidLevel:Int=0
        var shieldCharges:Int=0
        var lives:Int=3
        var repairsBought:Int=0

        // Decode both v568 profiles (which lack Rail/Swarm keys) and H11
        // profiles. Preserve all earlier purchases, tokens and equipped guns.
        // Preserve the original v568 memberwise API: SourceNewGame568
        // initializes lives and multiple existing tests initialize tokens.
        // Defaulted new ownership flags cannot change those call sites.
        init(tokens:Int=0,totalEarned:Int=0,totalSpent:Int=0,
             twinOwned:Bool=false,scatterOwned:Bool=false,
             railOwned:Bool=false,swarmOwned:Bool=false,
             weapon:Weapon = .pulse,upgradeLevel:Int=1,rapidLevel:Int=0,
             shieldCharges:Int=0,lives:Int=3,repairsBought:Int=0) {
            self.tokens=tokens
            self.totalEarned=totalEarned
            self.totalSpent=totalSpent
            self.twinOwned=twinOwned
            self.scatterOwned=scatterOwned
            self.railOwned=railOwned
            self.swarmOwned=swarmOwned
            self.weapon=weapon
            self.upgradeLevel=upgradeLevel
            self.rapidLevel=rapidLevel
            self.shieldCharges=shieldCharges
            self.lives=lives
            self.repairsBought=repairsBought
        }
        private enum CodingKeys:String,CodingKey {
            case tokens,totalEarned,totalSpent,twinOwned,scatterOwned
            case railOwned,swarmOwned,weapon,upgradeLevel,rapidLevel
            case shieldCharges,lives,repairsBought
        }
        init(from decoder:Decoder) throws {
            let v=try decoder.container(keyedBy:CodingKeys.self)
            tokens=try v.decode(Int.self,forKey:.tokens)
            totalEarned=try v.decode(Int.self,forKey:.totalEarned)
            totalSpent=try v.decode(Int.self,forKey:.totalSpent)
            twinOwned=try v.decode(Bool.self,forKey:.twinOwned)
            scatterOwned=try v.decode(Bool.self,forKey:.scatterOwned)
            railOwned=try v.decodeIfPresent(Bool.self,forKey:.railOwned) ?? false
            swarmOwned=try v.decodeIfPresent(Bool.self,forKey:.swarmOwned) ?? false
            weapon=try v.decode(Weapon.self,forKey:.weapon)
            upgradeLevel=try v.decode(Int.self,forKey:.upgradeLevel)
            rapidLevel=try v.decode(Int.self,forKey:.rapidLevel)
            shieldCharges=try v.decode(Int.self,forKey:.shieldCharges)
            lives=try v.decode(Int.self,forKey:.lives)
            repairsBought=try v.decode(Int.self,forKey:.repairsBought)
        }

        /// PC v580 Game.Price(item 0/1) at level >=13, and Game.Buy.
        /// The same persisted C279 wallet owns advanced weapons too.
        func advancedPrice(_ weapon:Weapon)->Int? {
            switch weapon {
            case .rail:return railOwned ? 0 : 160
            case .swarm:return swarmOwned ? 0 : 190
            default:return nil
            }
        }
        @discardableResult mutating func buyAdvanced(_ weapon:Weapon,
                                                  sector:Int)->Bool {
            guard (13..<25).contains(sector),
                  let cost=advancedPrice(weapon),cost>0,
                  tokens>=cost,totalSpent<=Int.max-cost
            else{return false}
            tokens-=cost
            totalSpent+=cost
            if weapon == .rail {railOwned=true} else {swarmOwned=true}
            self.weapon=weapon
            return true
        }
        func price(_ item:Item)->Int {
            switch item {
            case .twin:return twinOwned ? 0 : 45
            case .scatter:return scatterOwned ? 0 : 80
            case .power:return upgradeLevel==1 ? 60 : upgradeLevel==2 ? 150 : 0
            case .rapid:return rapidLevel==0 ? 75 : rapidLevel==1 ? 140 : 0
            case .shield:return 12
            case .repair:return 70+25*repairsBought
            }
        }
        func available(_ item:Item)->Bool {
            switch item {
            case .power:return upgradeLevel<3
            case .rapid:return rapidLevel<2
            case .shield:return shieldCharges<3
            case .repair:return lives<5
            default:return true
            }
        }
        @discardableResult mutating func buy(_ item:Item)->Bool {
            guard available(item) else {return false}
            let cost=price(item)
            guard cost>=0 && tokens>=cost else {return false}
            tokens-=cost
            totalSpent+=cost
            switch item {
            case .twin:
                twinOwned=true;weapon = .twin
            case .scatter:
                scatterOwned=true;weapon = .scatter
            case .power:upgradeLevel+=1
            case .rapid:rapidLevel+=1
            case .shield:shieldCharges+=1
            case .repair:lives+=1;repairsBought+=1
            }
            return true
        }
        @discardableResult mutating func equip(_ newWeapon:Weapon)->Bool {
            guard newWeapon == .pulse ||
                  (newWeapon == .twin && twinOwned) ||
                  (newWeapon == .scatter && scatterOwned) ||
                  (newWeapon == .rail && railOwned) ||
                  (newWeapon == .swarm && swarmOwned)
            else {return false}
            weapon=newWeapon
            return true
        }
        mutating func award(_ amount:Int) {
            guard amount>0 else{return}
            tokens=addCapped(tokens,amount)
            totalEarned=addCapped(totalEarned,amount)
        }
        private func addCapped(_ a:Int,_ b:Int)->Int {
            a>Int.max-b ? Int.max : a+b
        }
    }

    private static let storageKey="asteroidy.ios.v568.shop-profile-first-sector"
    static func load(defaults:UserDefaults = .standard)->State {
        guard let bytes=defaults.data(forKey:storageKey),
              let state=try? JSONDecoder().decode(State.self,from:bytes),
              validate(state)
        else {return State()}
        return state
    }
    /// Game.ReturnToMenu / SaveShopProfile56 preserves lives and
    /// purchased shield state. Zero lives reload as StartingLives=3.
    static func persistSurvival(lives:Int,shieldCharges:Int,
                                defaults:UserDefaults = .standard) {
        var profile=load(defaults:defaults)
        profile.lives=min(5,lives>0 ? lives:3)
        profile.shieldCharges=max(0,min(3,shieldCharges))
        save(profile,defaults:defaults)
    }
    static func save(_ state:State,defaults:UserDefaults = .standard) {
        guard validate(state),let bytes=try? JSONEncoder().encode(state)
        else{return}
        defaults.set(bytes,forKey:storageKey)
    }
    static func validate(_ s:State)->Bool {
        s.tokens>=0 && s.totalEarned>=0 && s.totalSpent>=0 &&
        (1...3).contains(s.upgradeLevel) &&
        (0...2).contains(s.rapidLevel) &&
        (0...3).contains(s.shieldCharges) &&
        (1...5).contains(s.lives) && s.repairsBought>=0 &&
        (s.weapon == .pulse ||
         (s.weapon == .twin && s.twinOwned) ||
         (s.weapon == .scatter && s.scatterOwned) ||
         (s.weapon == .rail && s.railOwned) ||
         (s.weapon == .swarm && s.swarmOwned))
    }
}
