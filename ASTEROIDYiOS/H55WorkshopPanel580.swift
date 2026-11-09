import SwiftUI

/// H11 native W3 Hub320 six-station console, over the original H55 SceneKit.
/// Actions mutate ONLY actual C279 Sector01Shop568 + persistent combat vitals.
/// Later PC mechanics are visible, but disabled until their mission effects
/// exist. No fabricated balance, purchases, player ships or trophies.
struct H55WorkshopPanel580:View {
    let onClose:()->Void
    @State private var tab=4
    @State private var wallet=Sector01Shop568.load()
    @State private var vitals=H55Workshop580.loadVitals()
    @State private var notice="STANOWISKA HANGARU PC v580"
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
                    Text("ŻETONY \(wallet.tokens)     KADŁUB \(vitals.hull)/\(vitals.maxHull)     PANCERZ \(vitals.armor)/\(vitals.maxArmor)")
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
                        case 0:
                            headline("01 / FLOTA","WYBÓR ORYGINALNEGO STATKU")
                            ForEach(H55Workshop580.ships.indices,id:\.self){i in
                                itemRow(H55Workshop580.ships[i],
                                    detail:i==1 ? "AKTYWNY — oryginalny VANGUARD C279" :
                                      i==3 ? "PC: zakup w serwisie od misji 13 · iOS: niedostępny" :
                                      i==4 ? "PC: cena 420 ż · iOS: brak silnika statku" :
                                      i==5 ? "PC: cena 620 ż · iOS: brak silnika statku" :
                                      "PC: statek posiadany · model i fizyka jeszcze nieprzeniesione",
                                    action:nil)
                            }
                        case 1:
                            headline("02 / DRZEWKO","TROFEA I ULEPSZENIA")
                            ForEach(0..<3,id:\.self){i in
                                itemRow(["KADŁUB","PANCERZ","SZYBKOSTRZELNOŚĆ"][i],
                                        detail:"PC: ranga 0/4 · następny koszt 1 trofeum. Zdobywanie trofeów w iOS jeszcze niedostępne.",
                                        action:nil)
                            }
                        case 2:
                            headline("03 / UZBROJENIE","KONFIGURACJA BRONI")
                            ForEach(H55Workshop580.weapons.indices,id:\.self){i in
                                let owned=H55Workshop580.weaponOwned(i,wallet)
                                let selected=wallet.weapon.rawValue==i
                                let price=i==1 ? wallet.price(.twin) : i==2 ? wallet.price(.scatter) : 0
                                itemRow(H55Workshop580.weapons[i],
                                    detail:selected ? "AKTUALNIE ZAŁOŻONA" :
                                        i>2 ? "PC: od sektora 13 · efekt iOS jeszcze niezaimplementowany" :
                                        owned ? "POSIADANA · WYPOSAŻ BEZ OPŁAT" : "ZAKUP: \(price) ŻETONÓW",
                                    action:i<=2 ? {
                                        let result=H55Workshop580.selectWeapon(i,shop:&wallet)
                                        notice=result.message
                                        if result.success {Sector01Shop568.save(wallet)}
                                    } : nil)
                            }
                        case 3:
                            headline("04 / GALERIA","TROFEA KAMPANII")
                            itemRow("TROFEA BOSSÓW (0/6)",
                                    detail:"Oryginalne nagrody PC nie są jeszcze przyznawane przez obecny port pierwszej misji.",
                                    action:nil)
                            itemRow("PRÓBY CZASOWE (0/25)",
                                    detail:"Czasy i 25 prób pochodzą z Talents78.cs. Brak zatwierdzonych odznaczeń.",
                                    action:nil)
                        case 4:
                            headline("05 / SERWIS","NAPRAWY I OSŁONY")
                            ForEach(H55Workshop580.services.indices,id:\.self){i in
                                let current=i==0 ? vitals.hull : i==1 ? vitals.armor :
                                            i==2 ? wallet.shieldCharges : 0
                                let total=i==0 ? vitals.maxHull : i==1 ? vitals.maxArmor : 3
                                let missing=H55Workshop580.serviceMissing(i,vitals:vitals,shop:wallet)
                                let price=H55Workshop580.servicePrice(i,vitals:vitals,shop:wallet)
                                itemRow(H55Workshop580.services[i],
                                    detail:i==3 ?
                                        "PC: VANGUARD X od misji 13, 240 ż · model i fizyka iOS nieprzeniesione" :
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
                        case 5:
                            headline("06 / MODUŁY","MODYFIKACJE JEDNOSTKI PC v580")
                            ForEach(H55Workshop580.modules.indices,id:\.self){i in
                                itemRow(H55Workshop580.modules[i],
                                    detail:"POZIOM 0/2 · PC: \(H55Workshop580.moduleCost(i,rank:0) ?? 0) Ż · \(H55Workshop580.moduleAvailability(i,sector:1))",
                                    action:nil)
                            }
                        default:EmptyView()
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
            .background(Color(red:0.008,green:0.024,blue:0.042).opacity(0.98))
            .overlay(RoundedRectangle(cornerRadius:8).stroke(cyan.opacity(0.6),lineWidth:1))
            .frame(maxWidth:.infinity,maxHeight:.infinity)
        }
        .onAppear {
            // Reload canonical mission profile whenever the console is opened.
            wallet=Sector01Shop568.load()
            vitals=H55Workshop580.loadVitals()
        }
        .accessibilityIdentifier("h11-authentic-w3-stations")
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
