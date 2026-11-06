import SwiftUI

/// First-sector slice of Windows RendererW3Shop321 / Game.Price and Buy.
/// All six displayed items update real verified Sector01Combat weapons,
/// shield/lives or persistent profile; no imaginary late-game options.
struct Sector01ShopPanel568:View {
    let onReturnAtlas:()->Void
    @State private var state=Sector01Shop568.load()

    private func caption(_ item:Sector01Shop568.Item)->String {
        switch item {
        case .twin:
            return state.twinOwned ? (state.weapon == .twin ?
                   "WYPOSAŻONO":"POSIADASZ · WYPOSAŻ") :
                   "DWA RÓWNOLEGŁE POCISKI"
        case .scatter:
            return state.scatterOwned ? (state.weapon == .scatter ?
                   "WYPOSAŻONO":"POSIADASZ · WYPOSAŻ") :
                   "TRZY POCISKI · PIĘĆ NA MOCY III"
        case .power:
            return state.upgradeLevel>=3 ?
                   "MOC III · MAX (PAKIETY JONOWE W OPRACOWANIU)" :
                   "MOC II / III · WIĘKSZA PRĘDKOŚĆ POCISKÓW"
        case .rapid:
            return state.rapidLevel>=2 ?
                   "TEMPO II · MAX (BOMBY W OPRACOWANIU)" :
                   "TEMPO OGNIA +15% / +30%"
        case .shield:
            return "ŁADUNKI \(state.shieldCharges) / 3 · 1 TRAFIENIE"
        case .repair:
            return "ŻYCIA \(state.lives) / 5"
        }
    }
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:14) {
                HStack {
                    Text("SERWIS / PO MISJI 01")
                        .font(.system(size:24,weight:.heavy,design:.monospaced))
                        .foregroundStyle(.cyan)
                    Spacer()
                    Text("ŻETONY \(state.tokens)")
                        .font(.system(size:15,weight:.bold,design:.monospaced))
                        .foregroundStyle(.yellow)
                }
                Text("POZIOM 01 ZAKOŃCZONY · WYPOSAŻENIE ZAPISANE")
                    .font(.system(size:12,weight:.semibold,design:.monospaced))
                    .foregroundStyle(.white.opacity(0.83))
                ForEach(Sector01Shop568.Item.allCases,id:\.rawValue){ item in
                    let price=state.price(item)
                    let allowed=state.available(item) && state.tokens>=price
                    HStack(alignment:.center,spacing:10) {
                        VStack(alignment:.leading,spacing:4) {
                            Text(item.title)
                                .font(.system(size:14,weight:.bold,design:.monospaced))
                                .foregroundStyle(.white)
                            Text(caption(item))
                                .font(.system(size:10,design:.monospaced))
                                .foregroundStyle(.cyan.opacity(0.85))
                        }
                        Spacer(minLength:10)
                        Button(price==0 ? "WYPOSAŻ" : "\(price) Ż") {
                            if state.buy(item) {
                                Sector01Shop568.save(state)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(allowed ? .orange : .gray)
                        .disabled(!allowed)
                        .accessibilityIdentifier("sector01-service-item-\(item.rawValue)")
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.06),
                                in:RoundedRectangle(cornerRadius:10))
                }
                HStack(spacing:12) {
                    Text("BROŃ: \(state.weapon == .pulse ? "PULSE" : state.weapon == .twin ? "TWIN" : "SCATTER")")
                        .font(.system(size:11,weight:.bold,design:.monospaced))
                        .foregroundStyle(.cyan)
                    Button("PULSE") {
                        if state.equip(.pulse){Sector01Shop568.save(state)}
                    }
                    .font(.system(size:11,weight:.bold,design:.monospaced))
                    .buttonStyle(.bordered)
                    Spacer()
                }
                Button("ZAPISZ I WRÓĆ DO ATLASU") {
                    Sector01Shop568.save(state)
                    onReturnAtlas()
                }
                .font(.system(size:14,weight:.bold,design:.monospaced))
                .frame(maxWidth:.infinity,minHeight:46)
                .background(.orange,in:RoundedRectangle(cornerRadius:8))
                .foregroundStyle(.black)
                .accessibilityIdentifier("sector01-service-return-to-atlas")
                Text("Sektor 02 został odblokowany. Jego pełna rozgrywka jest nadal przenoszona z Windows v568.")
                    .font(.system(size:10,design:.monospaced))
                    .foregroundStyle(.yellow)
            }
            .padding(22)
        }
        .frame(maxWidth:750,maxHeight:620)
        .background(Color(red:0.015,green:0.035,blue:0.075),
                    in:RoundedRectangle(cornerRadius:16))
        .onAppear {state=Sector01Shop568.load()}
        .accessibilityIdentifier("sector01-source-post-mission-service-shop")
    }
}
