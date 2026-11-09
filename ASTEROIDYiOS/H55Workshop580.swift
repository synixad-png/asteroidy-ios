import Foundation

/// H11: only executable PC v580 Hub90/Game.Shop operations are enabled.
/// The iOS first-sector combat owns the canonical wallet in Sector01Shop568;
/// never issue tokens in a parallel "hangar profile" and never charge for
/// modules/ships whose effects aren't yet part of the playable iOS engine.
enum H55Workshop580 {
    static let tabs=["STATEK","DRZEWKO","UZBROJENIE","TROFEA","SERWIS","MODUŁY"]
    static let ships=["KESTREL","VANGUARD","BASTION","VANGUARD X","TITAN H-01","MAMMOTH T-06"]
    static let weapons=["DZIAŁKO PULSOWE","PODWÓJNE DZIAŁKO",
                        "WACHLARZ PLAZMY","DZIAŁO SZYNOWE","POCISKI NAMIERZAJĄCE"]
    static let services=["KADŁUB","PANCERZ","PASYWNA OSŁONA","PROTOTYP VANGUARD X"]
    static let modules=["CHŁODZENIE UZBROJENIA","DOPALACZ MANEWROWY",
                        "TŁUMIK TRAFIEŃ","DRON — RDZEŃ BOJOWY",
                        "DRON — NAPROWADZANIE LASEROWE"]
    static let moduleLevelRequired=[3,2,5,6,8]
    static let moduleBaseCost=[90,75,130,150,170]
    static let moduleCostStep=[100,90,120,130,140]

    /// Source Talents78 starts at 60/25, four purchasable ranks at +15.
    /// The first iOS C279 mission does not yet award v78 trophies.
    /// This persisted state is USED BY CarbonisCombat568, not merely by UI.
    struct Vitals:Codable,Equatable {
        var hull:Int=60,armor:Int=25
        var hullRank:Int=0,armorRank:Int=0
        var maxHull:Int {60+15*hullRank}
        var maxArmor:Int {25+15*armorRank}
        var valid:Bool {
            (0...4).contains(hullRank) && (0...4).contains(armorRank) &&
            (0...maxHull).contains(hull) && (0...maxArmor).contains(armor)
        }
    }
    enum Outcome:Equatable {
        case changed(String),unchanged(String),unavailable(String)
        var message:String {
            switch self {
            case .changed(let text),.unchanged(let text),.unavailable(let text):return text
            }
        }
        var success:Bool {
            if case .changed=self{return true}
            return false
        }
    }

    private static let vitalsKey="asteroidy.ios.h11.pc580.c279.vitals"
    static func loadVitals(defaults:UserDefaults = .standard)->Vitals {
        guard let bytes=defaults.data(forKey:vitalsKey),
              let state=try? JSONDecoder().decode(Vitals.self,from:bytes),
              state.valid else{return Vitals()}
        return state
    }
    @discardableResult static func saveVitals(_ state:Vitals,
                           defaults:UserDefaults = .standard)->Bool {
        guard state.valid,let data=try? JSONEncoder().encode(state) else{return false}
        defaults.set(data,forKey:vitalsKey)
        return true
    }
    static func resetVitals(defaults:UserDefaults = .standard){
        defaults.removeObject(forKey:vitalsKey)
    }
    static func updateFromCombat(hull:Int,armor:Int,
                     defaults:UserDefaults = .standard){
        var v=loadVitals(defaults:defaults)
        // Game.Damage() and later HubService95 read actual remaining hull.
        v.hull=max(0,min(v.maxHull,hull))
        v.armor=max(0,min(v.maxArmor,armor))
        _=saveVitals(v,defaults:defaults)
    }
    static func serviceMissing(_ id:Int,vitals:Vitals,
                         shop:Sector01Shop568.State)->Int {
        switch id {
        case 0:return max(0,vitals.maxHull-vitals.hull)
        case 1:return max(0,vitals.maxArmor-vitals.armor)
        case 2:return max(0,3-shop.shieldCharges)
        // id=3 is a different GLB ship and MUST NOT be offered unless
        // its gameplay/rendering has been genuinely ported.
        case 3:return 1
        default:return 0
        }
    }
    static func servicePrice(_ id:Int,vitals:Vitals,
                       shop:Sector01Shop568.State)->Int {
        guard serviceMissing(id,vitals:vitals,shop:shop)>0 else{return 0}
        switch id {
        case 0,1:return 0
        case 2:return shop.price(.shield) // PC Price(4): 12 tokens
        case 3:return 240 // Campaign37 CustomShipPrice368; unavailable on iOS
        default:return 0
        }
    }
    /// PC HubService95 + Game.Buy(4); writes into genuine playable C279
    /// profile. Every disallowed operation is pure and free of side effects.
    static func service(_ id:Int,vitals:inout Vitals,
                        shop:inout Sector01Shop568.State)->Outcome {
        guard (0...3).contains(id) else{return .unavailable("BRAK TAKIEGO SERWISU")}
        if id==3 {
            return .unavailable("VANGUARD X: OD MISJI 13 — BRAK MODELU I FIZYKI W PORCIE iOS")
        }
        guard vitals.valid && Sector01Shop568.validate(shop) else {
            return .unavailable("NIEPRAWIDŁOWY STAN PROFILU")
        }
        guard serviceMissing(id,vitals:vitals,shop:shop)>0 else {
            return .unchanged("STAN UKŁADU JUŻ JEST MAKSYMALNY")
        }
        let price=servicePrice(id,vitals:vitals,shop:shop)
        guard shop.tokens>=price else {
            return .unavailable("ZA MAŁO ŻETONÓW · BRAKUJE \(price-shop.tokens)")
        }
        if id==0 {vitals.hull=vitals.maxHull;return .changed("KADŁUB NAPRAWIONY")}
        if id==1 {vitals.armor=vitals.maxArmor;return .changed("PANCERZ ODNOWIONY")}
        guard shop.buy(.shield) else {
            return .unavailable("ŁADUNEK NIEDOSTĘPNY")
        }
        return .changed("PASYWNA OSŁONA UZUPEŁNIONA")
    }
    static func weaponOwned(_ id:Int,_ shop:Sector01Shop568.State)->Bool {
        switch id {
        case 0:return true
        case 1:return shop.twinOwned
        case 2:return shop.scatterOwned
        default:return false // rail/swarm unported in playable C279
        }
    }
    static func selectWeapon(_ id:Int,
               shop:inout Sector01Shop568.State)->Outcome {
        guard (0...4).contains(id) else{return .unavailable("NIEZNANA BROŃ")}
        guard Sector01Shop568.validate(shop) else {
            return .unavailable("NIEPRAWIDŁOWY STAN PROFILU")
        }
        guard id<=2 else {
            return .unavailable("BROŃ DOSTĘPNA W PC OD SEKTORA 13 · EFEKT NIEPRZENIESIONY DO iOS")
        }
        let weapon=Sector01Shop568.Weapon(rawValue:id)!
        if !weaponOwned(id,shop) {
            let item:Sector01Shop568.Item = id==1 ? .twin : .scatter
            guard shop.available(item),shop.tokens>=shop.price(item),
                  shop.buy(item) else {
                return .unavailable("BROŃ NIEDOSTĘPNA · SPRAWDŹ MISJE I ŻETONY")
            }
        }
        guard shop.equip(weapon) else {
            return .unavailable("NIE UDAŁO SIĘ WYPOSAŻYĆ BRONI")
        }
        return .changed("WYPOSAŻONO: "+weapons[id])
    }
    static func moduleCost(_ id:Int,rank:Int)->Int? {
        guard modules.indices.contains(id),(0...2).contains(rank) else{return nil}
        return moduleBaseCost[id]+rank*moduleCostStep[id]
    }
    /// No fake buys: even a correct cost/rank would be cosmetic unless
    /// the original effects are driven in actual mission code.
    static func moduleAvailability(_ id:Int,sector:Int)->String {
        guard modules.indices.contains(id) else{return "NIEZNANY MODUŁ"}
        if sector<moduleLevelRequired[id] {
            return "ODBLOKUJ OD SEKTORA \(moduleLevelRequired[id])"
        }
        return "EFEKT MODUŁU JESZCZE NIEJEST PODŁĄCZONY DO MISJI iOS"
    }
    /// Source PC: costs 1/2/3/4 trophy for hull/armor/rate ranks.
    static func talentCost(rank:Int)->Int? {
        guard (0...4).contains(rank) else{return nil}
        return rank==4 ? nil : rank+1
    }
}
