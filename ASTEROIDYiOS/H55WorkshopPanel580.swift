import SwiftUI
import UniformTypeIdentifiers

/// H11 native W3 Hub320 six-station console, over the original H55 SceneKit.
/// Actions mutate ONLY actual C279 Sector01Shop568 + persistent combat vitals.
/// Later PC mechanics are visible, but disabled until their mission effects
/// exist. No fabricated balance, purchases, player ships or trophies.
struct H55WorkshopPanel580:View {
    let onClose:()->Void
    @State private var tab:Int
    init(initialTab:Int,onClose:@escaping ()->Void){
        self.onClose=onClose
        _tab=State(initialValue:max(0,min(5,initialTab)))
    }
    @State private var wallet=Sector01Shop568.load()
    @State private var vitals=H55Workshop580.loadVitals()
    // Pure source profile: ownership/talents/modules have no GLB dependency.
    @State private var rules=H55SourceMechanics580.load()
    private var sector:Int {min(25,CampaignStore556.load().nextAvailableSector)}
    @State private var notice="STANOWISKA HANGARU PC v580"
    @State private var showBastionImporter606=false
    private let gold=Color(red:0.89,green:0.67,blue:0.31)
    private let cyan=Color(red:0.33,green:0.77,blue:0.83)
    private let muted=Color(red:0.62,green:0.72,blue:0.78)

    var body:some View {
        GeometryReader {proxy in
            let compact=proxy.size.height<440
            VStack(spacing:compact ? 5 : 10) {
                HStack(spacing:12){
                    Text("H55  /  STANOWISKA").font(.system(size:compact ? 13:18,weight:.bold,design:.monospaced))
                    Spacer()
                    Text("ŻETONY \(wallet.tokens) · KADŁUB \(vitals.hull)/\(vitals.maxHull) · PANCERZ \(vitals.armor)/\(vitals.maxArmor) · TROFEA \(rules.trophiesFree(vitals:vitals))")
                        .font(.system(size:compact ? 9:12,design:.monospaced))
                        .foregroundStyle(cyan)
                    Button("WRÓĆ DO HANGARU",action:onClose)
                        .font(.system(size:compact ? 10:12,weight:.bold))
                        .padding(7)
                        .background(gold)
                        .foregroundStyle(.black)
                        .accessibilityIdentifier("h11-close-stations")
                }
                ScrollView(.horizontal,showsIndicators:false) {
                    HStack(spacing:5) {
                        ForEach(H55Workshop580.tabs.indices,id:\.self){i in
                            Button("\(i+1) · \(H55Workshop580.tabs[i])") {
                                tab=i;notice="STANOWISKO \(i+1) / \(H55Workshop580.tabs[i])"
                            }
                            .font(.system(size:compact ? 9:11,weight:.bold,design:.monospaced))
                            .padding(.horizontal,compact ? 8:11)
                            .padding(.vertical,8)
                            .background(tab==i ? gold : Color(red:0.04,green:0.12,blue:0.19))
                            .foregroundStyle(tab==i ? Color.black : Color.white)
                            .accessibilityIdentifier("h11-tab-\(i)")
                        }
                    }
                }
                ScrollView(showsIndicators:true) {
                    VStack(alignment:.leading,spacing:compact ? 8 : 12) {
                        switch tab {
                        case 0: fleetTab()
                        case 1: talentsTab()
                        case 2: weaponsTab()
                        case 3: trophiesTab()
                        case 4: serviceTab()
                        case 5: modulesTab()
                        default: EmptyView()
                        }
                    }
                    .padding(.horizontal,compact ? 12:18)
                    .padding(.vertical,compact ? 7:12)
                    .frame(maxWidth:.infinity,alignment:.leading)
                }
                HStack {
                    Text(notice)
                        .font(.system(size:compact ? 10:12,weight:.medium,design:.monospaced))
                        .foregroundStyle(cyan)
                        .accessibilityIdentifier("h11-workshop-notice")
                    Spacer()
                    Text("OPERACJE POŁĄCZONE Z MISJĄ 01 • POZOSTAŁE WYMAGAJĄ PORTU SILNIKA")
                        .font(.system(size:9,design:.monospaced))
                        .foregroundStyle(muted)
                }
                .padding(.horizontal,14)
            }
            .padding(.horizontal,compact ? 12:24)
            .padding(.top,compact ? 8:18)
            .padding(.bottom,compact ? 6:12)
            .background(Color(red:0.008,green:0.024,blue:0.042).opacity(0.89))
            .overlay(RoundedRectangle(cornerRadius:8).stroke(cyan.opacity(0.6),lineWidth:1))
            .frame(maxWidth:.infinity,maxHeight:.infinity)
        }
        .fileImporter(isPresented:$showBastionImporter606,
                      allowedContentTypes:[.item],
                      allowsMultipleSelection:false) { result in
            do {
                guard let file=try result.get().first else {
                    notice="BASTION: NIE WYBRANO PLIKU"
                    return
                }
                try SourceBastion606.install(from:file)
                notice="BASTION PC609: MODEL I TEKSTURA ZWERYFIKOWANE · MOŻNA WYPOSAŻYĆ"
            } catch {
                notice="BASTION: NIEPRAWIDŁOWA PACZKA PC609 · BRAK ZMIAN"
            }
        }
        .onAppear {
            // Reload canonical mission profile whenever the console is opened.
            wallet=Sector01Shop568.load()
            vitals=H55Workshop580.loadVitals()
            rules=H55SourceMechanics580.load()
        }
        .accessibilityIdentifier("h11-authentic-w3-stations")
    }
    @ViewBuilder private func fleetTab()->some View {
                            headline("01 / FLOTA","SZEŚĆ STATKÓW · ŹRÓDŁO CAMPAIGN37")
                            if H55SourceMechanics580.registeredModelName(forShip:2)==nil {
                                Button("WCZYTAJ MODEL BASTION PC609 Z PLIKÓW") {
                                    showBastionImporter606=true
                                }
                                .font(.system(size:12,weight:.bold,design:.monospaced))
                                .foregroundStyle(.black)
                                .padding(.horizontal,12)
                                .padding(.vertical,10)
                                .background(gold)
                                .accessibilityIdentifier("h11-import-bastion606")
                            }
                            ForEach(H55Workshop580.ships.indices,id:\.self){i in
                                let stats=H55SourceMechanics580.shipStats(
                                    type:i,engine:rules.engine,
                                    stabilizer:rules.stabilizer,
                                    thruster:rules.thruster)
                                let modeled=H55SourceMechanics580.registeredModelName(forShip:i) != nil
                                let owned=H55SourceMechanics580.shipOwned(i,state:rules)
                                let price=H55SourceMechanics580.shipPrice(i)
                                let detail="A:\(Int(stats?.acceleration ?? 0)) · V:\(Int(stats?.topSpeed ?? 0)) · SKR:\(Int((stats?.turnSpeed ?? 0)*100)/100) · MASA:\(stats?.mass ?? 0)"
                                let craftStatus=i==rules.selectedShip ? "WYBRANY" : owned ? "POSIADANY" : "KOSZT \(price ?? 0) Ż"
                                let craftVisual=modeled ? "MODEL iOS DOSTĘPNY" : "GLB DO DOSTARCZENIA (BEZ PODMIANY)"
                                itemRow(H55Workshop580.ships[i],
                                    detail:"\(detail) · \(craftStatus) · \(craftVisual)",
                                    action:i != rules.selectedShip &&
                                           (modeled || (!owned && price != nil)) ? {
                                        let result=modeled
                                            ? H55SourceMechanics580.buyAndEquipShip(
                                                i,sector:sector,state:&rules,wallet:&wallet)
                                            : H55SourceMechanics580.purchaseShipForLaterModel(
                                                i,sector:sector,state:&rules,wallet:&wallet)
                                        notice=modeled ? shipMessage(result,i) :
                                            result == .changed
                                            ? "ZAKUPIONO "+H55Workshop580.ships[i]+" · CZEKAMY NA GLB"
                                            : shipMessage(result,i)
                                        if result == .changed {persistSource()}
                                    } : nil)
                            }
    }

    @ViewBuilder private func talentsTab()->some View {
                            headline("02 / DRZEWKO","TALENTY 78 · AUTENTYCZNE TROFEA")
                            Text("ZDOBYTE: \(rules.trophiesEarned) · WOLNE: \(rules.trophiesFree(vitals:vitals))")
                                .font(.system(size:12,weight:.bold,design:.monospaced))
                                .foregroundStyle(cyan)
                            ForEach(0..<3,id:\.self){i in
                                let rank=i==0 ? vitals.hullRank : i==1 ? vitals.armorRank : rules.rateRank
                                let cost=H55Workshop580.talentCost(rank:rank)
                                let free=rules.trophiesFree(vitals:vitals)
                                let costText=cost.map{"KOLEJNY KOSZT \($0) TROFEÓW"} ?? "MAKSIMUM"
                                let benefit=i==0 ? "MAX HP \(vitals.maxHull)" :
                                            i==1 ? "MAX PANCERZ \(vitals.maxArmor)" :
                                            "SZYBKOSTRZELNOŚĆ \(Int(100/(1+0.06*Double(rank))))%"
                                itemRow(["KADŁUB","PANCERZ","SZYBKOSTRZELNOŚĆ"][i],
                                    detail:"RANGA \(rank)/4 · \(costText) · \(benefit)",
                                    action:rank<4 && free >= (cost ?? 999) ? {
                                        let r=H55SourceMechanics580.buyTalent(
                                            i,state:&rules,vitals:&vitals)
                                        notice=r == .changed ? "ROZWINIĘTO TALENT" : "BRAK TROFEÓW"
                                        if r == .changed {persistSource()}
                                    } : nil)
                            }
    }

    @ViewBuilder private func weaponsTab()->some View {
        headline("03 / UZBROJENIE","KONFIGURACJA BRONI · PC v580")
        ForEach(H55Workshop580.weapons.indices,id:\.self){i in
            let owned=H55Workshop580.weaponOwned(i,wallet)
            let selected=wallet.weapon.rawValue==i
            let price=H55Workshop580.weaponPrice(i,shop:wallet) ?? 0
            let unlocked=owned || (i<3 ? sector<13 : sector>=13 && sector<25)
            let description=selected ? "AKTUALNIE ZAŁOŻONA" :
                owned ? "POSIADANA · WYPOSAŻ BEZ OPŁAT" :
                !unlocked ? (i>=3 ? "ODBLOKUJ OD SEKTORA 13" :
                              "ZAKUP DOSTĘPNY PRZED SEKTOREM 13") :
                "ZAKUP: \(price) ŻETONÓW"
            itemRow(H55Workshop580.weapons[i],detail:description,
                    action:!selected && unlocked ? {
                let result=H55Workshop580.selectWeapon(
                    i,sector:sector,shop:&wallet)
                notice=result.message
                if result.success {Sector01Shop568.save(wallet)}
            } : nil)
        }
    }

    @ViewBuilder private func trophiesTab()->some View {
                            headline("04 / GALERIA","TROFEA Z RZECZYWISTYCH MISJI")
                            itemRow("BOSSOWIE \(rules.bossTrophies.nonzeroBitCount)/6",
                                    detail:"Poziomy 4, 8, 12, 16, 20, 24 · trofeum dopiero po podniesieniu łupu",
                                    action:nil)
                            itemRow("PRÓBY CZASOWE \(rules.timeTrophies.nonzeroBitCount)/25",
                                    detail:"Sektor 01: limit 94 s · wynik nadawany przy prawdziwym FinishLevel",
                                    action:nil)
                            ForEach(1...25,id:\.self){level in
                                let cleared=(rules.timeTrophies & (1 << (level-1))) != 0
                                itemRow("CZAS · SEKTOR \(level)",
                                    detail:cleared ? "ZDOBYTE" :
                                        "NIEZDOBYTE · \(H55SourceMechanics580.timeTarget(sector:level,objective:level==2 || level==11 || level==21 ? .escort : level==5 || level==14 || level==23 ? .defend : level==9 || level==17 ? .waves : .normal) ?? 0) s",
                                    action:nil)
                            }
    }

    @ViewBuilder private func serviceTab()->some View {
                            headline("05 / SERWIS","NAPRAWY I OSŁONY")
                            ForEach(H55Workshop580.services.indices,id:\.self){i in
                                let current=i==0 ? vitals.hull : i==1 ? vitals.armor :
                                            i==2 ? wallet.shieldCharges : 0
                                let total=i==0 ? vitals.maxHull : i==1 ? vitals.maxArmor : 3
                                let missing=H55Workshop580.serviceMissing(i,vitals:vitals,shop:wallet)
                                let price=H55Workshop580.servicePrice(i,vitals:vitals,shop:wallet)
                                itemRow(H55Workshop580.services[i],
                                    detail:i==3 ?
                                        (rules.vanguardXOwned ? "POSIADANY · MODEL GLB DO DOSTARCZENIA" : "OD SEKTORA 13 · ZAKUP 240 Ż W PANELU STATEK") :
                                        "\(current)/\(total) · \(missing==0 ? "GOTOWE" : price==0 ? "NAPRAWA GRATIS" : "\(price) ŻETONÓW")",
                                    action:i<=2 && missing>0 ? {
                                        let result=H55Workshop580.service(i,vitals:&vitals,shop:&wallet)
                                        notice=result.message
                                        if result.success {
                                            _=H55Workshop580.saveVitals(vitals)
                                            Sector01Shop568.save(wallet)
                                        }
                                    } : nil)
                            }
    }

    @ViewBuilder private func modulesTab()->some View {
                            headline("06 / MODUŁY","PIĘĆ MODUŁÓW 97 · EFEKTY ŹRÓDŁOWE")
                            ForEach(H55Workshop580.modules.indices,id:\.self){i in
                                let rank=rules.moduleRanks[i]
                                let cost=H55Workshop580.moduleCost(i,rank:rank)
                                let level=H55Workshop580.moduleLevelRequired[i]
                                let can=rank<2 && sector>=level &&
                                    (i<3 || rules.guardianOwned)
                                let costInfo=cost.map{"\($0) Ż"} ?? "MAKSIMUM"
                                let droneInfo=i>=3 && !rules.guardianOwned ? " · WYMAGA DRONA" : ""
                                itemRow(H55Workshop580.modules[i],
                                    detail:"RANGA \(rank)/2 · \(costInfo) · OD SEKTORA \(level)\(droneInfo)",
                                    action:can ? {
                                        let r=H55SourceMechanics580.buyModule(
                                            i,sector:sector,state:&rules,wallet:&wallet)
                                        notice=moduleMessage(r,H55Workshop580.modules[i])
                                        if r == .changed {persistSource()}
                                    } : nil)
                            }
                            headline("STARSZE MODUŁY GAME.CS","SILNIK · KOLEKTOR · DRON · STABILIZATOR")
                            ForEach(6...9,id:\.self){id in
                                let labels=["SILNIK","KOLEKTOR","DRON STRAŻNIK","STABILIZATOR"]
                                let rank=id==6 ? rules.engine : id==7 ? rules.collector :
                                             id==8 ? (rules.guardianOwned ? 1:0) : rules.stabilizer
                                let cost=H55SourceMechanics580.legacyModuleCost(id,state:rules) ?? 0
                                let can=(id==8 ? !rules.guardianOwned && sector>=6 : rank<2)
                                itemRow(labels[id-6],
                                    detail:"RANGA \(rank)/\(id==8 ? 1:2) · \(cost) Ż"+(id==8 ? " · OD SEKTORA 6":""),
                                    action:can ? {
                                        let result=H55SourceMechanics580.buyLegacyModule(
                                            id,sector:sector,state:&rules,wallet:&wallet)
                                        notice=moduleMessage(result,labels[id-6])
                                        if result == .changed {persistSource()}
                                    } : nil)
                            }
    }
    private func persistSource() {
        // Operations have passed source validation. Store only the canonical
        // wallet and independent no-GLB source state; never copy money.
        Sector01Shop568.save(wallet)
        _=H55Workshop580.saveVitals(vitals)
        _=H55SourceMechanics580.save(rules)
    }
    private func moduleMessage(_ result:H55SourceMechanics580.SourceEffect,
                               _ name:String)->String {
        switch result {
        case .changed:return "ZAMONTOWANO: "+name
        case .unchanged:return "BEZ ZMIAN"
        case .unavailable:return "MODUŁ NIEDOSTĘPNY W TYM SEKTORZE"
        case .insufficientFunds:return "BRAKUJE ŻETONÓW"
        }
    }
    private func shipMessage(_ result:H55SourceMechanics580.SourceEffect,
                             _ index:Int)->String {
        switch result {
        case .changed:return "WYBRANO "+H55Workshop580.ships[index]
        case .unchanged:return "BEZ ZMIAN"
        case .unavailable:return "STATEK ZABLOKOWANY"
        case .insufficientFunds:return "BRAKUJE ŻETONÓW"
        }
    }
    private func headline(_ kicker:String,_ title:String)->some View {
        VStack(alignment:.leading,spacing:4) {
            Text(kicker).font(.system(size:10,weight:.bold,design:.monospaced)).foregroundStyle(cyan)
            Text(title).font(.system(size:17,weight:.bold,design:.monospaced)).foregroundStyle(.white)
        }
    }
    private func itemRow(_ name:String,detail:String,
                         action:(()->Void)?)->some View {
        HStack(alignment:.center,spacing:12) {
            VStack(alignment:.leading,spacing:4) {
                Text(name).font(.system(size:13,weight:.bold,design:.monospaced)).foregroundStyle(.white)
                Text(detail).font(.system(size:11,design:.monospaced))
                    .foregroundStyle(muted)
            }
            Spacer(minLength:4)
            if let action {
                Button("WYKONAJ",action:action)
                    .font(.system(size:10,weight:.bold,design:.monospaced))
                    .padding(.horizontal,12).padding(.vertical,8)
                    .background(gold).foregroundStyle(Color.black)
                    .accessibilityIdentifier("h11-action-"+name)
            } else {
                Text("—").foregroundStyle(muted)
            }
        }
        .padding(10)
        .background(Color(red:0.03,green:0.08,blue:0.14))
        .overlay(alignment:.leading){Rectangle().fill(cyan.opacity(0.4)).frame(width:3)}
    }
}
