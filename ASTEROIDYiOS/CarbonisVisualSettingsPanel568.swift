import SwiftUI

/// Two real W3 settings tabs from Windows/src/Menu139.cs:
/// 11 "WYBUCHY 3D" (12 controls), 16 "POCISKI" (3 controls).
/// Unlike the old placeholder, every slider/dropdown writes to the
/// same persisted rendering profile consumed by CARBONIS 01 GPU.
struct CarbonisVisualSettingsPanel568: View {
    let compact:Bool
    /// Live FPS settings are optional outside the H55 hangar.
    let fpsLoader:H55SceneModel580?
    /// Optional live mission actions; W3 and hangar reuse this same panel.
    let onEditHud:(()->Void)?
    let onHudMotionChange:((HudMotion600.Settings)->Void)?
    // W3 Windows Menu139.cs OptionTabs139[9] is HANGAR. Returning from
    // full-screen H55 opens directly on the original category.
    init(compact:Bool,initialTab:Int=11,
         fpsLoader:H55SceneModel580?=nil,
         onEditHud:(()->Void)?=nil,
         onHudMotionChange:((HudMotion600.Settings)->Void)?=nil) {
        self.compact=compact
        self.fpsLoader=fpsLoader
        self.onEditHud=onEditHud
        self.onHudMotionChange=onHudMotionChange
        _tab=State(initialValue:initialTab)
    }

    @AppStorage("ASTEROIDY_H55_ENV_FILL_580") private var h55Fill=0.80
    @AppStorage("ASTEROIDY_H55_RED_GAIN_580") private var h55Red=0.10
    @AppStorage("ASTEROIDY_H55_SAFE_MATERIALS_580") private var h55SafeShaders=true
    @State private var h55Eyes=Double(H55EyeHeight580.load())

    @State private var profile=CarbonisVisualSettings568.load()
    @State private var planetProfile=SourcePlanetGraphicsSettings568.load()
    @State private var lava287=SourceLavaLightSettings287.load()
    @State private var shipScale472=SourceShipScale472.load()
    @State private var missionSize580=SourceMissionSize580.load()
    @State private var pickupVisual586=SourcePickupVisual586.load()
    @State private var tab:Int=11
    @State private var previewRevision=0
    @State private var showingHudMotionSheet600=false
    @ObservedObject private var performance=SourcePerformance568.shared
    @State private var iosFX=CarbonisIOSFXBudget568.load()

    private let gold=Color(red:0.89,green:0.67,blue:0.31)
    private let cyan=Color(red:0.39,green:0.75,blue:0.79)
    private let muted=Color(red:0.63,green:0.73,blue:0.77)

    private func save(_ change:(inout CarbonisVisualSettings568)->Void) {
        change(&profile)
        profile.clampAll()
        profile.save()
    }
    private func saveLava(_ value:Int) {
        lava287.setBrightness(value)
        lava287.save()
    }
    private func savePlanet(_ change:(inout SourcePlanetGraphicsSettings568)->Void) {
        change(&planetProfile)
        planetProfile.clampAll()
        planetProfile.save()
    }
    private func saveShipScale(_ update:(inout SourceShipScale472)->Void) {
        update(&shipScale472)
        shipScale472.clampAll()
        shipScale472.save()
    }
    private func saveMissionSize580(_ change:(inout SourceMissionSize580)->Void) {
        change(&missionSize580)
        missionSize580.clampAll()
        missionSize580.save()
    }
    private func savePickupVisual586(
        _ update:(inout SourcePickupVisual586)->Void) {
        update(&pickupVisual586)
        pickupVisual586.clampAll()
        pickupVisual586.save()
    }
    private func pickupSlider586(
        _ title:String,
        _ key:WritableKeyPath<SourcePickupVisual586,Int>,
        bounds:ClosedRange<Double>,
        identifier:String)->some View {
        VStack(alignment:.leading,spacing:3) {
            HStack {
                Text(title)
                Spacer()
                Text("\(pickupVisual586[keyPath:key])%").foregroundStyle(gold)
            }
            .font(.system(size:compact ? 10:12,design:.monospaced))
            Slider(value:Binding(
                get:{Double(pickupVisual586[keyPath:key])},
                set:{n in savePickupVisual586{
                    $0[keyPath:key]=Int(n.rounded())
                }}),in:bounds,step:1)
                .tint(cyan)
                .accessibilityIdentifier(identifier)
        }
    }

    private func doubleValue(_ idx:Int)->Binding<Double> {
        Binding(get:{Double(profile.value(idx))},
                set:{n in
            save{$0.setValue(idx,Int(n.rounded()))}
        })
    }
    private func sliderRange(_ idx:Int)->ClosedRange<Double> {
        let low=Double(CarbonisVisualSettings568.minimum[idx])
        let high=Double(CarbonisVisualSettings568.maximum[idx])
        return low...high
    }
    private var brightness:Binding<Double> {
        Binding(get:{Double(profile.projectileBrightness)},
                set:{n in
            save{$0.projectileBrightness=Int(n.rounded())}
        })
    }
    private var colorChoice:Binding<Int> {
        Binding(get:{profile.projectileColor},
                set:{n in save{$0.projectileColor=n}})
    }
    private var mixed:Binding<Bool> {
        Binding(get:{profile.projectileMixed},
                set:{n in save{$0.projectileMixed=n}})
    }


    // EXACT source order: Windows/src/Menu139.cs OptionTabs139 (v555).
    // The original W3 presentation has a left vertical navigation rail,
    // not the six horizontal legacy iOS tabs. Preserve all live settings.
    private let sourceTabs139=[
        "GRAFIKA","DŹWIĘK","STEROWANIE","ROZGRYWKA","INTERFEJS",
        "DOSTĘPNOŚĆ","RĘKAWICE","PLANETY","BROŃ","HANGAR",
        "GOLD MELTER","WYBUCHY 3D","SZYBY","STATEK",
        "POSTPROCES","KOSMOS","POCISKI"
    ]
    private func legacyTestID(_ sourceIndex:Int)->String {
        // Retain existing accessibility selectors for source-verified
        // iOS UI tests without changing the real on-screen source order.
        switch sourceIndex {
        case 11:return "w3-effects-tab-0"
        case 16:return "w3-effects-tab-1"
        case 1:return "w3-effects-tab-2"
        case 7:return "w3-effects-tab-3"
        case 14:return "w3-effects-tab-4"
        case 13:return "w3-effects-tab-5"
        default:return "w3-original-category-\(sourceIndex)"
        }
    }
    var body:some View {
        HStack(alignment:.top,spacing:compact ? 8 : 16) {
            ScrollViewReader { scroll in
                ScrollView(.vertical) {
                    VStack(alignment:.leading,spacing:2) {
                        Text("KATEGORIE / W3")
                            .font(.system(size:compact ? 9 : 11,
                                weight:.bold,design:.monospaced))
                            .foregroundStyle(gold)
                            .padding(.horizontal,7)
                            .padding(.vertical,9)
                        ForEach(0..<sourceTabs139.count,id:\.self) { i in
                            tabButton(sourceTabs139[i],index:i)
                                .id(i)
                        }
                    }
                    .frame(maxWidth:.infinity,alignment:.leading)
                }
                .scrollIndicators(.hidden)
                .accessibilityIdentifier("w3-effects-tabs-524-285")
                .onAppear {scroll.scrollTo(tab,anchor:.center)}
                .onChange(of:tab) { value in
                    withAnimation(.easeInOut(duration:0.2)) {
                        scroll.scrollTo(value,anchor:.center)
                    }
                }
            }
            .frame(width:compact ? 126 : 174)
            .background(Color(red:0.006,green:0.025,blue:0.045).opacity(0.94))
            .overlay(Rectangle().stroke(cyan.opacity(0.28),lineWidth:1))
            ScrollView {
                VStack(alignment:.leading,spacing:compact ? 8 : 13) {
                    HStack {
                        Text(sourceTabs139[tab]+" / PARAMETRY")
                            .font(.system(size:compact ? 11 : 14,
                                          weight:.bold,design:.monospaced))
                            .foregroundStyle(gold)
                        Spacer()
                        Text("W3 / #\(tab)")
                            .font(.system(size:compact ? 8 : 10,
                                          design:.monospaced))
                            .foregroundStyle(muted)
                    }
                    Rectangle().fill(cyan.opacity(0.28)).frame(height:1)
                    switch tab {
                    case 0: sourceGraphicsPage
                    case 3: missionObjectSizePage580
                    case 4: interfacePage600
                    case 9: hangarPage580
                    case 6: H55FPSSettingsSection580(category:.gloves,loader:fpsLoader)
                    case 8: H55FPSSettingsSection580(category:.weapon,loader:fpsLoader)
                    case 11: explosionPage
                    case 16: projectilePage
                    case 1: OriginalAudioSettingsPanel568(compact:compact)
                    case 2: SourceControlSettings586(compact:compact)
                    case 7: planetPage
                    case 14: postprocessPage
                    case 13: shipSizePage
                    default: unavailableSourceCategory
                    }
                }
                .padding(compact ? 10 : 17)
                .frame(maxWidth:.infinity,alignment:.topLeading)
            }
            .background(Color(red:0.008,green:0.030,blue:0.054).opacity(0.94))
            .overlay(Rectangle().stroke(cyan.opacity(0.22),lineWidth:1))
            .accessibilityIdentifier("w3-effects-scroll")
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading)
        .accessibilityIdentifier("w3-original-explosion-projectile-settings")
    }
    private func tabButton(_ title:String,index:Int)->some View {
        Button {
            tab=index
        } label:{
            HStack(spacing:6) {
                Rectangle()
                    .fill(index==tab ? gold : cyan.opacity(0.2))
                    .frame(width:3,height:22)
                Text(title)
                    .font(.system(size:compact ? 9 : 10,
                                  weight:.semibold,design:.monospaced))
                    .foregroundStyle(index==tab ? gold : muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength:0)
            }
            .padding(.horizontal,compact ? 5 : 9)
            .frame(maxWidth:.infinity,minHeight:compact ? 33 : 37,
                   alignment:.leading)
            .background(index==tab
                ? Color(red:0.10,green:0.085,blue:0.060)
                : Color.clear)
            .overlay(alignment:.bottom) {
                Rectangle().fill(cyan.opacity(0.10)).frame(height:1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier(legacyTestID(index))
    }
    // Windows/src/Menu139.cs OptionLabels228[6] = "Licznik wydajności".
    // ShowPerformance defaults false; Renderer.cs:200 deliberately omits
    // W3 HOME, SHOP and summary frames. This is a REAL toggled counter,
    // not an inert iOS settings decoration.
    private var sourceGraphicsPage:some View {
        VStack(alignment:.leading,spacing:compact ? 9 : 15) {
            header("GRAFIKA / ORYGINALNY LICZNIK WYDAJNOŚCI")
            Toggle("LICZNIK WYDAJNOŚCI (POMIAR FPS)",isOn:Binding(
                get:{performance.enabled},
                set:{value in performance.setEnabled(value)}))
                .tint(cyan)
                .font(.system(size:compact ? 10 : 13,
                              weight:.semibold,design:.monospaced))
                .foregroundStyle(.white)
                .accessibilityIdentifier("w3-source-show-performance-006")
            Text(performance.enabled ? "WŁĄCZONY" : "WYŁĄCZONY")
                .font(.system(size:compact ? 10 : 12,design:.monospaced))
                .foregroundStyle(gold)
                .accessibilityIdentifier("w3-source-fps-enabled-value")
            Text("ŹRÓDŁO: WINDOWS v568 / MENU139 ID 6 · GPU RENDERER / 0,5 s. ZAPIS AUTOMATYCZNY. LICZNIK POJAWIA SIĘ WYŁĄCZNIE W GRZE, NIE W MENU.")
                .font(.system(size:compact ? 10 : 12,design:.monospaced))
                .foregroundStyle(muted)
                .fixedSize(horizontal:false,vertical:true)
            Spacer(minLength:0)
        }
        .accessibilityIdentifier("w3-source-graphics-settings")
    }
    /// Windows PC v580: Menu139 options 142/144. Both are graphics-only;
    /// the count, hitboxes, physics, pickup scale and other categories remain separate.
    private var missionObjectSizePage580:some View {
        VStack(alignment:.leading,spacing:compact ? 10:16) {
            header("ROZGRYWKA / WIELKOŚĆ OBIEKTÓW — PC v580")
            HStack {
                Text("PRZECIWNICY / WIELKOŚĆ MODELI")
                Spacer()
                Text("\(missionSize580.enemyPercent)%").foregroundStyle(gold)
            }
            .font(.system(size:compact ? 10:12,design:.monospaced))
            Slider(value:Binding(
                get:{Double(missionSize580.enemyPercent)},
                set:{n in saveMissionSize580{$0.setEnemy(Int(n.rounded()))}}),
                in:30...150,step:1)
                .tint(cyan)
                .accessibilityIdentifier("w3-v580-enemy-size-slider")
            HStack {
                Text("ASTEROIDY / WIELKOŚĆ MODELI")
                Spacer()
                Text("\(missionSize580.rockPercent)%").foregroundStyle(gold)
            }
            .font(.system(size:compact ? 10:12,design:.monospaced))
            Slider(value:Binding(
                get:{Double(missionSize580.rockPercent)},
                set:{n in saveMissionSize580{$0.setRock(Int(n.rounded()))}}),
                in:40...150,step:1)
                .tint(cyan)
                .accessibilityIdentifier("w3-v580-asteroid-size-slider")
            Text("Wyłącznie rozmiar wizualny modeli w misji. Liczba obiektów, obrażenia, fizyka i promienie kolizji nie zmieniają się. Wartości źródłowe: 77% / 78%.")
                .font(.system(size:compact ? 9:11,design:.monospaced))
                .foregroundStyle(muted)
                .fixedSize(horizontal:false,vertical:true)
            Rectangle().fill(cyan.opacity(0.28)).frame(height:1)
            header("PRZEDMIOTY GLB / PC v586 — USTAWIENIA ROZGRYWKI")
            pickupSlider586("PRZEDMIOTY GLB — JASNOŚĆ MODELI",
                \.brightnessPercent,bounds:0...400,
                identifier:"pc586-pickup-glb-brightness")
            pickupSlider586("OSŁONY ENERGETYCZNE — WIELKOŚĆ",
                \.shieldPercent,bounds:30...150,
                identifier:"pc586-pickup-shield-size")
            pickupSlider586("DOPALACZ GLB — WIELKOŚĆ",
                \.boostPercent,bounds:30...150,
                identifier:"pc586-pickup-boost-size")
            pickupSlider586("ENERGIA GLB — WIELKOŚĆ",
                \.energyPercent,bounds:30...150,
                identifier:"pc586-pickup-energy-size")
            pickupSlider586("BOMBA GLB — WIELKOŚĆ",
                \.bombPercent,bounds:30...150,
                identifier:"pc586-pickup-bomb-size")
            pickupSlider586("PIENIĄDZE / ŻETONY — WIELKOŚĆ",
                \.moneyPercent,bounds:40...150,
                identifier:"pc586-pickup-money-size")
            Text("Jasność 0% wyłącza tylko dodatkowe doświetlanie GLB. Rozmiar nie zmienia promienia zbierania ani obrażeń.")
                .font(.system(size:compact ? 9:11,design:.monospaced))
                .foregroundStyle(muted)
                .fixedSize(horizontal:false,vertical:true)
            Spacer(minLength:0)
        }
        .accessibilityIdentifier("w3-v580-object-size-settings")
    }
    // This is the one settings owner for H55. Source:
    // Windows/src/Menu139.cs OptionGroups139[9] =
    // [140,134..139,102,48..53]. Other original controls remain pending
    // H13-B port rather than becoming decorative non-functional sliders.
    private var hangarPage580:some View {
        VStack(alignment:.leading,spacing:compact ? 9:14) {
            header("HANGAR H55 / WINDOWS PC v580")
            Text("Oryginalne ustawienia PC obejmują wygląd H72, ekspozycję i kinematykę, wysokość kamery, kontrast oraz ruch. Poniższe dwie regulacje są tymczasową kalibracją SceneKit iOS, a nie udawanymi wartościami shadera PC.")
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(muted)
                .fixedSize(horizontal:false,vertical:true)
            Toggle("BEZPIECZNE ŁADOWANIE MATERIAŁÓW (ZALECANE)",isOn:$h55SafeShaders)
                .tint(cyan)
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                .accessibilityIdentifier("h55-settings-safe-shaders")
            Text("Włączone: bez dodatkowego kodu shadera emisji SceneKit. Wyłączone: testowa korekta emissive_strength. Po zmianie ponownie otwórz hangar. Nowa mapa IBL jest wyłączona w obu trybach.")
                .font(.system(size:compact ? 9:11,design:.monospaced))
                .foregroundStyle(muted)
                .fixedSize(horizontal:false,vertical:true)
            HStack {
                Text("JASNOŚĆ WYPEŁNIENIA iOS")
                Spacer()
                Text("\(Int((h55Fill*100).rounded()))%").foregroundStyle(gold)
            }
            .font(.system(size:compact ? 10:12,design:.monospaced))
            Slider(value:$h55Fill,in:0.25...1,step:0.05)
                .tint(cyan)
                .accessibilityIdentifier("h55-settings-fill")
            HStack {
                Text("CZERWONE LAMPY iOS")
                Spacer()
                Text("\(Int((h55Red*100).rounded()))%").foregroundStyle(gold)
            }
            .font(.system(size:compact ? 10:12,design:.monospaced))
            Slider(value:$h55Red,in:0...0.30,step:0.02)
                .tint(cyan)
                .accessibilityIdentifier("h55-settings-red")
            HStack {
                Text("WYSOKOŚĆ OCZU / KAMERA CHODZENIA")
                Spacer()
                Text(String(format:"%.2f m",h55Eyes)).foregroundStyle(gold)
            }
            .font(.system(size:compact ? 10:12,design:.monospaced))
            Slider(value:$h55Eyes,
                   in:Double(H55EyeHeight580.minimum)...Double(H55EyeHeight580.maximum),
                   step:0.05)
                .tint(cyan)
                .onChange(of:h55Eyes) {value in
                    let eyes=H55EyeHeight580.valid(Float(value))
                    H55EyeHeight580.save(eyes)
                    fpsLoader?.setEyeHeight580(eyes)
                }
                .accessibilityIdentifier("h55-settings-eye-height")
            Text("Oryginał PC: 1,80 m. Regulacja dotyczy tylko kamery. Kolizje, schody i skoki pozostają bez zmian; pod sufitem kamera nie przejdzie przez geometrię.")
                .font(.system(size:compact ? 9:11,design:.monospaced))
                .foregroundStyle(muted)
                .fixedSize(horizontal:false,vertical:true)
            Button("PRZYWRÓĆ WYSOKOŚĆ OCZU 1,80 m") {
                H55EyeHeight580.reset()
                h55Eyes=Double(H55EyeHeight580.original)
                fpsLoader?.setEyeHeight580(H55EyeHeight580.original)
            }
            .font(.system(size:compact ? 10:12,weight:.semibold,design:.monospaced))
            .foregroundStyle(cyan)
            .accessibilityIdentifier("h55-settings-eye-height-reset")
            HStack(spacing:12) {
                Button("PRZYWRÓĆ KALIBRACJĘ iOS") {
                    h55Fill=Double(H55LightingProfile580.defaultFill)
                    h55Red=Double(H55LightingProfile580.defaultRed)
                    h55SafeShaders=true
                }
                .accessibilityIdentifier("h55-settings-reset")
                ShareLink(item:H55LoadDiagnostics580.report()) {
                    Text("UDOSTĘPNIJ RAPORT WCZYTYWANIA")
                }
                .accessibilityIdentifier("h55-settings-share-load-report")
            }
            .font(.system(size:compact ? 9:11,weight:.semibold,design:.monospaced))
            .foregroundStyle(cyan)
            Text(H55LoadDiagnostics580.report())
                .font(.system(size:compact ? 9:11,design:.monospaced))
                .foregroundStyle(.white)
                .textSelection(.enabled)
                .accessibilityIdentifier("h55-settings-last-load-stage")
            Text("Raport pozostaje w pamięci urządzenia także po nieoczekiwanym zamknięciu aplikacji. Otwórz USTAWIENIA → HANGAR przed ponownym uruchomieniem sceny, aby go skopiować.")
                .font(.system(size:compact ? 9:11,design:.monospaced))
                .foregroundStyle(muted)
                .fixedSize(horizontal:false,vertical:true)
            Spacer(minLength:0)
        }
        .accessibilityIdentifier("w3-h55-original-category-settings")
    }

    /// One W3 INTERFEJS owner for pause settings and the HUD editor.
    /// The actual live layout overlay remains hosted in Sector01Scene568.
    private var interfacePage600:some View {
        VStack(alignment:.leading,spacing:12) {
            Text("INTERFEJS / HUD")
                .font(.system(size:14,weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
            if let edit=onEditHud {
                Button("EDYTUJ UKŁAD HUD (46 ELEMENTÓW)") {edit()}
                    .frame(maxWidth:.infinity,alignment:.leading)
                    .padding(12)
                    .foregroundStyle(cyan)
                    .background(Color(red:0.04,green:0.12,blue:0.19))
                    .overlay(Rectangle().stroke(cyan.opacity(0.4),lineWidth:1))
                    .accessibilityIdentifier("w3-interface-edit-hud")
            } else {
                Text("EDYTOR UKŁADU HUD JEST DOSTĘPNY PODCZAS PAUZY MISJI.")
                    .font(.system(size:11,design:.monospaced))
                    .foregroundStyle(muted)
            }
            Button("HUD DYNAMICZNY / USTAWIENIA") {
                showingHudMotionSheet600=true
            }
            .frame(maxWidth:.infinity,alignment:.leading)
            .padding(12)
            .foregroundStyle(cyan)
            .background(Color(red:0.04,green:0.12,blue:0.19))
            .overlay(Rectangle().stroke(cyan.opacity(0.4),lineWidth:1))
            .accessibilityIdentifier("w3-interface-hud-motion")
            Text("Zmiany dotyczą wyłącznie rozmieszczenia i animacji HUD-u. Sterowanie, kolizje oraz nagrody misji pozostają bez zmian.")
                .font(.system(size:11,design:.monospaced))
                .foregroundStyle(muted)
        }
        .sheet(isPresented:$showingHudMotionSheet600) {
            HudMotionSettingsPanel600 { value in
                onHudMotionChange?(value)
            }
        }
        .accessibilityIdentifier("w3-interface-hud-settings")
    }

    private var unavailableSourceCategory:some View {
        VStack(alignment:.leading,spacing:12) {
            Text("ORYGINALNA KATEGORIA / "+sourceTabs139[tab])
                .font(.system(size:compact ? 11 : 14,
                              weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
            Text("Ta kategoria występuje w oryginalnym Windows v568. Jej parametry nie są jeszcze podłączone do właściwego silnika iOS. Nie wyświetlam pozornych przełączników, które nie zmieniają działania gry.")
                .font(.system(size:compact ? 10 : 12,design:.monospaced))
                .foregroundStyle(muted)
                .fixedSize(horizontal:false,vertical:true)
            Spacer(minLength:0)
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading)
        .accessibilityIdentifier("w3-not-yet-ported-source-category")
    }
    private func header(_ title:String)->some View {
        Text(title)
            .font(.system(size:compact ? 11:13,
                          weight:.bold,design:.monospaced))
            .foregroundStyle(gold)
    }
    private var explosionPage:some View {
        VStack(alignment:.leading,spacing:compact ? 8:12) {
            header("ORYGINALNE USTAWIENIA V8.2 / EXPLOSION524")
            HStack(spacing:6) {
                ForEach(0..<CarbonisVisualSettings568.typeNames.count,
                        id:\.self) { index in
                    Button(CarbonisVisualSettings568.typeNames[index]) {
                        save{$0.selectPreset(index)}
                        previewRevision+=1
                    }
                    .font(.system(size:compact ? 10:12,
                                  weight:.bold,design:.monospaced))
                    .foregroundStyle(profile.type==index ? .black:cyan)
                    .padding(.horizontal,compact ? 5:9)
                    .padding(.vertical,compact ? 5:8)
                    .background(profile.type==index ? gold:
                                Color.white.opacity(0.08))
                    .overlay(Rectangle().stroke(
                        gold.opacity(profile.type==index ? 1:0.25)))
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("w3-explosion-type-\(index)")
                    .accessibilityValue(profile.type==index ? "wybrany":"niewybrany")
                }
            }
            header("JAKOŚĆ RENDEROWANIA")
            HStack(spacing:6) {
                ForEach(0..<CarbonisVisualSettings568.qualityNames.count,
                        id:\.self) { index in
                    Button(CarbonisVisualSettings568.qualityNames[index]) {
                        save{$0.quality=index}
                    }
                    .font(.system(size:compact ? 9:11,design:.monospaced))
                    .foregroundStyle(profile.quality==index ? .black:cyan)
                    .padding(.horizontal,compact ? 5:10)
                    .padding(.vertical,compact ? 6:9)
                    .background(profile.quality==index ? gold:
                                Color.white.opacity(0.08))
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("w3-explosion-quality-\(index)")
                    .accessibilityValue(profile.quality==index ? "wybrany":"niewybrany")
                }
            }
            Toggle("iOS · OGRANICZ WYBUCHY 3D",isOn:Binding(
                get:{iosFX.explosionsReduced},
                set:{enabled in
                    iosFX.explosionsReduced=enabled
                    iosFX.save()
                    previewRevision+=1
                }))
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                .tint(cyan)
                .accessibilityIdentifier("ios-explosions-reduced")
            Text(iosFX.explosionsReduced
                ? "iOS OSZCZĘDNY · MNIEJ WOLUMENÓW, PRÓBEK I ODŁAMKÓW"
                : "ORYGINALNA PEŁNA JAKOŚĆ WYBUCHÓW")
                .font(.system(size:compact ? 9:10,design:.monospaced))
                .foregroundStyle(muted)
                .accessibilityIdentifier("ios-explosions-reduced-status")
            ForEach(0..<8,id:\.self) { i in
                VStack(alignment:.leading,spacing:2) {
                    HStack {
                        Text(CarbonisVisualSettings568.explosionLabels[i])
                        Spacer(minLength:8)
                        Text(explosionValue(i))
                            .foregroundStyle(gold)
                            .accessibilityIdentifier("w3-explosion-value-\(i)")
                    }
                    .font(.system(size:compact ? 10:12,
                                  weight:.medium,design:.monospaced))
                    .foregroundStyle(.white)
                    Slider(value:doubleValue(i),in:sliderRange(i),
                           step:Double(CarbonisVisualSettings568.increments[i]))
                        .tint(cyan)
                        .accessibilityIdentifier("w3-explosion-slider-\(i)")
                }
            }
            HStack {
                Toggle("OBRÓT PODGLĄDU",isOn:Binding(
                    get:{profile.autoRotate},
                    set:{n in save{$0.autoRotate=n}}))
                    .toggleStyle(.switch)
                    .tint(cyan)
                    .font(.system(size:compact ? 10:12,
                                  weight:.medium,design:.monospaced))
                Spacer(minLength:5)
                Button("NOWY WYBUCH (PODGLĄD)") {
                    previewRevision+=1
                }
                .font(.system(size:compact ? 9:11,
                              weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
                .padding(8)
                .background(cyan.opacity(0.13))
                .accessibilityIdentifier("w3-explosion-detonate-preview")
            }
            // Actual native Explosion524 volume shader in a dedicated
            // Metal viewport. No simulated SwiftUI fire sprites.
            CarbonisExplosion524Preview568(
                settings:profile,revision:previewRevision,
                budget:iosFX)
                .frame(height:compact ? 124:194)
                .background(Color.black.opacity(0.6))
                .accessibilityIdentifier("w3-explosion-metal-preview")
            Text("ŹRÓDŁO: WINDOWS v568 / WYBUCHY 3D · ZMIANY ZAPISYWANE AUTOMATYCZNIE")
                .font(.system(size:9,design:.monospaced))
                .foregroundStyle(muted)
        }
    }
    private func explosionValue(_ index:Int)->String {
        if index==1 {return "\(profile.value(index))"}
        if index==7 {
            return String(format:"%.2f s",
                          Double(profile.value(index))/100)
        }
        return "\(profile.value(index))%"
    }
    private var projectilePage:some View {
        VStack(alignment:.leading,spacing:compact ? 12:18) {
            header("ORYGINALNE USTAWIENIA POCISKÓW / GPU 285")
            Toggle("iOS · OGRANICZ ŚWIATŁO POCISKÓW",isOn:Binding(
                get:{iosFX.projectilesReduced},
                set:{enabled in
                    iosFX.projectilesReduced=enabled
                    iosFX.save()
                }))
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                .tint(cyan)
                .accessibilityIdentifier("ios-projectiles-reduced")
            Text(iosFX.projectilesReduced
                ? "iOS OSZCZĘDNY · 1 WARSTWA ŚWIATŁA, BEZ ZEWNĘTRZNEJ POŚWIATY"
                : "ORYGINALNE 4 WARSTWY ŚWIATŁA I PEŁNA POŚWIATA")
                .font(.system(size:compact ? 9:10,design:.monospaced))
                .foregroundStyle(muted)
                .accessibilityIdentifier("ios-projectiles-reduced-status")
            VStack(alignment:.leading,spacing:4) {
                HStack {
                    Text("JASNOŚĆ OŚWIETLENIA POCISKÓW")
                    Spacer()
                    Text("\(profile.projectileBrightness)%")
                        .foregroundStyle(gold)
                        .accessibilityIdentifier("w3-projectile-brightness-value")
                }
                .foregroundStyle(.white)
                .font(.system(size:compact ? 10:12,
                              weight:.medium,design:.monospaced))
                Slider(value:brightness,in:0...400,step:5)
                    .tint(cyan)
                    .accessibilityIdentifier("w3-projectile-light-brightness")
            }
            HStack(spacing:8) {
                Text("KOLOR OŚWIETLENIA POCISKÓW")
                    .font(.system(size:compact ? 10:12,design:.monospaced))
                Spacer()
                Picker("BARWA",selection:colorChoice) {
                    ForEach(0..<CarbonisVisualSettings568.shotColorNames.count,
                            id:\.self) {index in
                        Text(CarbonisVisualSettings568.shotColorNames[index])
                            .tag(index)
                    }
                }
                .pickerStyle(.menu)
                .tint(gold)
                .accessibilityIdentifier("w3-projectile-light-color")
            }
            .foregroundStyle(.white)
            Toggle("MIESZANE KOLORY OŚWIETLENIA",isOn:mixed)
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                .tint(cyan)
                .accessibilityIdentifier("w3-projectile-light-mixed")
            Text("WYBRANA BARWA DOTYCZY ŚWIATŁA PADAJĄCEGO NA PLANETĘ. NATURALNY KOLOR POCISKU ZALEŻY OD BRONI LUB WROGA, JAK W ORYGINALE.")
                .font(.system(size:10,design:.monospaced))
                .foregroundStyle(muted)
            Text("ŹRÓDŁO: COMBAT69 / SHOTAPPEARANCE151 / GPUSPHERE67")
                .font(.system(size:10,design:.monospaced))
                .foregroundStyle(gold)
            Spacer(minLength:0)
        }
        .accessibilityIdentifier("w3-projectile-settings")
    }
    // Menu139.cs: source PLANETY tab, original IDs #55 / #56 / #57.
    // This is the same profile that the actual C279 Metal renderer reads.
    private var planetPage:some View {
        VStack(alignment:.leading,spacing:compact ? 10:18) {
            header("ORYGINALNE USTAWIENIA PLANET / v436–437")
            Toggle("ŚWIATŁO PLANETY",isOn:Binding(
                get:{planetProfile.planetLightEnabled},
                set:{v in savePlanet{$0.planetLightEnabled=v}}))
                .tint(cyan)
                .foregroundStyle(.white)
                .accessibilityIdentifier("w3-planet-light-436")
            VStack(alignment:.leading,spacing:4) {
                HStack {
                    Text("ŚWIATŁO PLANETY / PRĘDKOŚĆ")
                    Spacer()
                    Text("\(planetProfile.planetLightSpeed)%")
                        .foregroundStyle(gold)
                }
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                Slider(value:Binding(
                    get:{Double(planetProfile.planetLightSpeed)},
                    set:{v in savePlanet{$0.planetLightSpeed=Int(v)}}),
                    in:0...400,step:5)
                    .tint(cyan)
                    .accessibilityIdentifier("w3-planet-light-speed-436")
            }
            VStack(alignment:.leading,spacing:4) {
                HStack {
                    Text("ŚWIATŁO PLANETY / JASNOŚĆ NOCY")
                    Spacer()
                    Text("\(planetProfile.planetNightBrightness)%")
                        .foregroundStyle(gold)
                }
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                Slider(value:Binding(
                    get:{Double(planetProfile.planetNightBrightness)},
                    set:{v in savePlanet{$0.planetNightBrightness=Int(v)}}),
                    in:0...400,step:5)
                    .tint(cyan)
                    .accessibilityIdentifier("w3-planet-night-brightness-437")
            }
            VStack(alignment:.leading,spacing:4) {
                HStack {
                    Text("JASNOŚĆ EMISJI LAWY")
                    Spacer()
                    Text("\(lava287.brightnessPercent)%")
                        .foregroundStyle(gold)
                        .accessibilityIdentifier("w3-planet-lava-brightness-value-287")
                }
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                Slider(value:Binding(
                    get:{Double(lava287.brightnessPercent)},
                    set:{v in saveLava(Int(v.rounded()))}),
                    in:0...400,step:5)
                    .tint(cyan)
                    .accessibilityIdentifier("w3-planet-lava-brightness-287")
            }
            Text("ORYGINALNE MENU: PLANETY / #45 — EMISJA LAWY CARBONIS, POŚWIATA LAWY NEWHOME ORAZ MATERIAŁY LAWOWE INNYCH PLANET, GDY ICH RENDERERY ZOSTANĄ PRZENIESIONE.")
                .font(.system(size:compact ? 9:11,design:.monospaced))
                .foregroundStyle(muted)
            Text("ORIGINAL: WINDOWS/src/Menu139.cs #45, #55–57. LAWĘ REGULUJE SKALA 0–400%, KROK 5%, DOMYŚLNIE 180%.")
                .font(.system(size:9,design:.monospaced))
                .foregroundStyle(muted)
                .font(.system(size:9,design:.monospaced))
                .foregroundStyle(muted)
            Spacer(minLength:0)
        }
        .accessibilityIdentifier("w3-original-planet-settings-436")
    }
    private var postprocessPage:some View {
        VStack(alignment:.leading,spacing:compact ? 10:18) {
            header("ORYGINALNE USTAWIENIA POSTPROCES / #2")
            Toggle("GLOW — POŚWIATA",isOn:Binding(
                get:{planetProfile.glowEnabled},
                set:{v in savePlanet{$0.glowEnabled=v}}))
                .tint(cyan)
                .foregroundStyle(.white)
                .accessibilityIdentifier("w3-source-planet-glow-256")
            Toggle("MGŁAWICA KOSMICZNA",isOn:Binding(
                get:{planetProfile.nebulaEnabled},
                set:{v in savePlanet{$0.nebulaEnabled=v}}))
                .tint(cyan)
                .foregroundStyle(.white)
                .accessibilityIdentifier("w3-source-nebula-option-12")
            Toggle("PROMIENIE SŁONECZNE",isOn:Binding(
                get:{planetProfile.solarRaysEnabled},
                set:{v in savePlanet{$0.solarRaysEnabled=v}}))
                .tint(cyan)
                .foregroundStyle(.white)
                .accessibilityIdentifier("w3-source-solar-rays-option-13")
            Text("PRZEŁĄCZNIKI ORYGINAŁU PC v602: GLOW / POŚWIATA (#2), MGŁAWICA KOSMICZNA (#12), PROMIENIE SŁONECZNE (#13). MODEL 3D, TEKSTURY I FIZYKA POZOSTAJĄ NIEZMIENIONE.")
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(muted)
            Text("PRZEŁĄCZNIK ORYGINAŁU: WŁĄCZA / WYŁĄCZA POŚWIATĘ I ATMOSFERĘ PLANETY. SAM MODEL 3D, EMISJA TEKSTURY ORAZ ŚWIATŁO POCISKÓW POZOSTAJĄ NIENARUSZONE.")
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(muted)
            Text("ŹRÓDŁO: WINDOWS/src/Renderer.cs OPTION #2; GpuPlanet.cs Atmosphere47; GpuPlanetAnimation.cs GlowVertex.")
                .font(.system(size:9,design:.monospaced))
                .foregroundStyle(gold)
            Spacer(minLength:0)
        }
        .accessibilityIdentifier("w3-original-postprocess-glow-256")
    }

    // Source Windows/src/Menu139.cs OptionGroups139 STATEK, IDs 100 and 101.
    // 17 choices from 70% through 150%, increments 5%, default 100%.
    private var shipSizePage:some View {
        VStack(alignment:.leading,spacing:compact ? 10:18) {
            header("ORYGINALNA SKALA WIZUALNA STATKU / v472")
            VStack(alignment:.leading,spacing:5) {
                HStack {
                    Text("STATEK / SKALA W MISJACH")
                    Spacer()
                    Text("\(shipScale472.missionPercent)%")
                        .foregroundStyle(gold)
                        .accessibilityIdentifier("w3-ship-mission-scale-value-472")
                }
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                Slider(value:Binding(
                    get:{Double(shipScale472.missionPercent)},
                    set:{value in saveShipScale{$0.setMission(Int(value.rounded()))}}),
                    in:70...150,step:5)
                    .tint(cyan)
                    .accessibilityIdentifier("w3-ship-mission-scale-slider-472")
            }
            VStack(alignment:.leading,spacing:5) {
                HStack {
                    Text("STATEK / SKALA W ŚWIECIE ORBITALNYM")
                    Spacer()
                    Text("\(shipScale472.orbitPercent)%")
                        .foregroundStyle(gold)
                        .accessibilityIdentifier("w3-ship-orbit-scale-value-472")
                }
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                Slider(value:Binding(
                    get:{Double(shipScale472.orbitPercent)},
                    set:{value in saveShipScale{$0.setOrbit(Int(value.rounded()))}}),
                    in:70...150,step:5)
                    .tint(cyan)
                    .accessibilityIdentifier("w3-ship-orbit-scale-slider-472")
            }
            Text("ZAKRES ORYGINAŁU: 70–150%, KROK 5%, DOMYŚLNIE 100%. ZMIANA DOTYCZY WYŁĄCZNIE WIDOCZNEJ GEOMETRII I DYSZ; NIE ZMIENIA KOLIZJI, PRĘDKOŚCI ANI OBRAŻEŃ.")
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(muted)
            Text("ŹRÓDŁO: Menu139.cs #100/#101; Renderer.cs; GpuSphere67.CraftSphere67; Orbit50.cs:318.")
                .font(.system(size:9,design:.monospaced))
                .foregroundStyle(gold)
            Spacer(minLength:0)
        }
        .accessibilityIdentifier("w3-source-ship-scale-settings-472")
    }

}