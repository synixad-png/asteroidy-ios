import Foundation

/// Windows v568 Game.cs:105-109, first post-CARBONIS service shop.
/// Only items whose actual effects are implemented in Sector01Combat are
/// purchasable. Ion ammo / bombs / modules remain unported, NOT silently
/// offered as fake purchases or charged against a user's balance.
enum Sector01Shop568 {
    enum Weapon:Int,Codable,CaseIterable {
        case pulse=0,twin=1,scatter=2
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
        var weapon:Weapon = .pulse
        var upgradeLevel:Int=1
        var rapidLevel:Int=0
        var shieldCharges:Int=0
        var lives:Int=3
        var repairsBought:Int=0

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
                  (newWeapon == .scatter && scatterOwned)
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
         (s.weapon == .scatter && s.scatterOwned))
    }
}
