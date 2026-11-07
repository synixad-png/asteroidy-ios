import SwiftUI
import CryptoKit
import UIKit

// The two original v568 W3 JPEG/PNG byte streams are stored as .dat to avoid\n// Xcode image optimization, then decoded by UIImage(data:) once across all flat
// native menu screens. Never load mismatched or unverified images.
private enum SourceW3Images568 {
    static let pair: (background: UIImage, logo: UIImage)? = {
        func verified(_ name: String,_ ext: String,_ expected: String) -> UIImage? {
            let url=Bundle.main.url(forResource:name,withExtension:ext)
                ?? Bundle.main.url(forResource:name,withExtension:ext,
                    subdirectory:"Assets")
            guard let file=url, let bytes=try? Data(contentsOf:file) else {
                return nil
            }
            let digest=SHA256.hash(data:bytes)
                .map { String(format:"%02x",$0) }.joined()
            guard digest==expected else {return nil}
            return UIImage(data:bytes)
        }
        guard let bg=verified("W3Background568Original","dat",
            "a8aa28883084657f0c38900dbb011de09e2b0fd461704d370a68858be0178145"),
              let logo=verified("W3Logo568Original","dat",
            "cab4198b953640c787975c5a8436a0fdeaa82502b40e000077ff055cc0709e09")
        else {return nil}
        return (background:bg,logo:logo)
    }()
}

/// Source-guided native UI for v568 Windows/src/RendererW3Home328.cs.
/// Uses the original seven action captions and W3 palette/layout hierarchy.
/// This is a real, tappable iPhone/iPad navigation surface, not HTML/WebView,
/// not a captured image of another game and not a claim of W3 visual parity.
/// W3 background/logo and actual GLB-derived NewHome290 source are loaded if SHA-verified;\n/// final shader parity is still a separate task.
struct W3MainMenu568: View {
    enum Page: String, CaseIterable, Identifiable {
        case newGame = "NOWA GRA"
        case continueGame = "KONTYNUUJ"
        case campaign = "KAMPANIA"
        case hangar = "HANGAR"
        case settings = "USTAWIENIA"
        case credits = "AUTORZY"
        case exit = "WYJŚCIE"

        var id: String { rawValue }
    }

    let progress: CampaignProgress556
    let selectMission: (Int) -> Void
    let inspectSector: (Int) -> Void
    let openDiagnostic: () -> Void
    let openCampaignOnEntry: Bool
    @State private var page: Page?
    // Same Y/X globe rotation axes as the source W3 NewHome290 preview.
    @State private var planetYaw: Float=0
    @State private var planetPitch: Float=0
    @State private var planetDragYaw: Float=0
    @State private var planetDragPitch: Float=0
    @State private var planetDragging=false

    private let gold = Color(red: 0.89, green: 0.67, blue: 0.31)
    private let cyan = Color(red: 0.39, green: 0.75, blue: 0.79)
    private let paper = Color(red: 0.92, green: 0.93, blue: 0.94)
    private let muted = Color(red: 0.63, green: 0.73, blue: 0.77)

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 540
            let pad: CGFloat = compact ? 12 : 24
            ZStack {
                if let images=SourceW3Images568.pair {
                    Image(uiImage:images.background)
                        .resizable()
                        .scaledToFill()
                        .frame(width:proxy.size.width,height:proxy.size.height)
                        .clipped()
                        .overlay(Color(red:0.004,green:0.035,blue:0.067)
                            .opacity(0.65))
                        .ignoresSafeArea()
                } else {
                    LinearGradient(
                        colors: [Color(red:0.012,green:0.042,blue:0.071),
                                 Color(red:0.006,green:0.019,blue:0.035)],
                        startPoint:.topLeading,endPoint:.bottomTrailing)
                        .ignoresSafeArea()
                }
                // Source ProgramW3Native315.cs + UiW3NativeLayout315.cs:
                // home and every submenu are separate W3 screens, NEVER
                // the old menu overlaid as a dark modal atop W3 home.
                VStack(spacing:0) {
                    header(compact:compact)
                    if let shown=page {
                        panel(for:shown,compact:compact)
                            .frame(maxWidth:.infinity,maxHeight:.infinity)
                            .transition(.opacity.combined(with:.move(edge:.trailing)))
                    } else {
                        HStack(alignment:.top,spacing:compact ? 10 : 20) {
                            navigation(compact:compact)
                                .frame(width:min(206,max(153,proxy.size.width * 0.162)))
                            radar(compact:compact)
                                .frame(maxWidth:.infinity,maxHeight:.infinity)
                            if proxy.size.width > 850 {
                                telemetry
                                    .frame(width:min(215,proxy.size.width * 0.18))
                            }
                        }
                        .padding(.horizontal,pad)
                        .padding(.vertical,compact ? 7 : 16)
                        .transition(.opacity)
                    }
                    footer(compact:compact)
                }
            }
        }
        // Keep native buttons accessible to VoiceOver and XCTest.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("asteroidy-w3-main-menu")
        .onAppear {
            // Returning from original C279 planet restores the real
            // source-locked 26-sector campaign atlas, not the W3 home page.
            if openCampaignOnEntry { page = .campaign }
            // Simulator diagnostic only. An actual screenshot is still
            // independently required; never report this marker as pixel parity.
            guard ProcessInfo.processInfo.environment["ASTEROIDY_W3_MENU_VERIFY"] == "1" else {
                return
            }
            let proof: [String: Any] = [
                "screen": "native-W3-v568-home",
                "menuItems": Page.allCases.map { $0.rawValue },
                "navigationAvailable": true,
                "htmlOrWebView": false,
                "hasOriginalW3BackgroundImage": SourceW3Images568.pair != nil,
                "hasOriginalW3LogoImage": SourceW3Images568.pair != nil,
                "sourcePlanet3DIntegrated": W3HomePlanetMetal568.isAvailable,
                "bundleID": Bundle.main.bundleIdentifier ?? "",
                "simulatorOnly": true
            ]
            if let folder = FileManager.default.urls(
                for: .cachesDirectory, in: .userDomainMask).first,
               let data = try? JSONSerialization.data(
                withJSONObject: proof, options: [.sortedKeys]) {
                try? data.write(to: folder.appendingPathComponent(
                    "ASTEROIDY_W3_MenuProof.json"), options: .atomic)
            }
        }
    }

    private func header(compact:Bool) -> some View {
        HStack(spacing:12) {
            if let image=SourceW3Images568.pair?.logo {
                Image(uiImage:image)
                    .resizable()
                    .scaledToFit()
                    .frame(width:compact ? 86 : 122,height:compact ? 34 : 44)
                    .accessibilityLabel("Oryginalne logo ASTEROIDY W3")
            }
            VStack(alignment:.leading,spacing:2) {
                Text("SYNIXAD SYSTEMS")
                    .font(.system(size:compact ? 13 : 18,
                                  weight:.heavy,design:.monospaced))
                    .foregroundStyle(gold)
                Text("ORBITAL NAVIGATION SYSTEM")
                    .font(.system(size:compact ? 9 : 11,design:.monospaced))
                    .foregroundStyle(paper)
            }
            Spacer()
            VStack(alignment:.trailing,spacing:3) {
                Text("TRYB CENTRUM DOWODZENIA")
                    .font(.system(size:compact ? 9 : 12,design:.monospaced))
                    .foregroundStyle(muted)
                Text("SYSTEM ONLINE")
                    .font(.system(size:compact ? 10 : 12,
                                  weight:.semibold,design:.monospaced))
                    .foregroundStyle(cyan)
            }
        }
        .padding(.horizontal,compact ? 14 : 26)
        .frame(height:compact ? 52 : 74)
        .background(Color(red:0.004,green:0.027,blue:0.048).opacity(0.96))
        .overlay(alignment:.bottom) { Rectangle().fill(cyan.opacity(0.25)).frame(height:1) }
    }

    private func navigation(compact:Bool) -> some View {
        // On landscape iPhone the seven original W3 actions cannot all fit
        // between the fixed header and footer. Keep every real Button
        // reachable by touch, VoiceOver and XCTest without clipping.
        ScrollView(.vertical) {
            VStack(alignment:.leading,spacing:compact ? 5 : 10) {
            Text("PANEL OPERACYJNY")
                .font(.system(size:compact ? 9 : 12,weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
            Text("CENTRUM DOWODZENIA")
                .font(.system(size:compact ? 15 : 22,
                              weight:.bold,design:.monospaced))
                .foregroundStyle(paper)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Rectangle().fill(gold.opacity(0.55)).frame(height:1)
                .padding(.bottom,compact ? 1 : 6)
            ForEach(0..<Page.allCases.count,id:\.self) { index in
                let item=Page.allCases[index]
                Button {
                    // Actual W3 destination replaces HOME rather than
                    // launching the pre-W3 modal navigation layer.
                    withAnimation(.easeInOut(duration:0.35)) {page=item}
                } label: {
                    HStack(spacing:10) {
                        Text(String(format:"%02d",index+1))
                            .foregroundStyle(gold)
                            .frame(width:22,alignment:.leading)
                        Text(item.rawValue)
                            .foregroundStyle(paper)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength:0)
                        Image(systemName:"chevron.right")
                            .foregroundStyle(gold)
                    }
                    .font(.system(size:compact ? 11 : 13,
                                  weight:.semibold,design:.monospaced))
                    .padding(.horizontal,11)
                    .frame(maxWidth:.infinity,minHeight:44)
                    .background(Color(red:0.02,green:0.065,blue:0.10).opacity(0.96))
                    .overlay {
                        RoundedRectangle(cornerRadius:3)
                            .stroke(cyan.opacity(0.32),lineWidth:1)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.rawValue)
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("w3-home-\(index)")
            }
            }
        }
        .scrollIndicators(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("w3-home-navigation")
    }

    // The source H290 globe is a real independent Metal render in the middle;
// reference W3 radar/orbit lines remain native vector UI overlays.
    private func radar(compact:Bool) -> some View {
        GeometryReader { geo in
            let diameter=min(geo.size.width * 0.76,geo.size.height * 0.78)
            ZStack {
                RoundedRectangle(cornerRadius:5)
                    .fill(Color(red:0.009,green:0.036,blue:0.061).opacity(0.85))
                RoundedRectangle(cornerRadius:5)
                    .stroke(cyan.opacity(0.24),lineWidth:1)
                ForEach(1...5,id:\.self) { i in
                    Circle()
                        .stroke(cyan.opacity(0.09+Double(i)*0.035),lineWidth:1)
                        .frame(width:diameter*CGFloat(i)/5,
                               height:diameter*CGFloat(i)/5)
                }
                Rectangle().fill(cyan.opacity(0.22))
                    .frame(width:diameter*1.07,height:1)
                Rectangle().fill(cyan.opacity(0.22))
                    .frame(width:1,height:diameter*1.07)
                if W3HomePlanetMetal568.isAvailable {
                    W3HomePlanetMetal568(yaw:planetYaw,pitch:planetPitch)
                        .frame(width:diameter,height:diameter)
                        .contentShape(Circle())
                        .gesture(DragGesture(minimumDistance:0)
                            .onChanged { value in
                                if !planetDragging {
                                    planetDragYaw=planetYaw
                                    planetDragPitch=planetPitch
                                    planetDragging=true
                                }
                                // Normalize drag distance to the original 455 px
                                // W3 preview. No change to the gameplay camera.
                                let dx=Float(value.translation.width)
                                    * 455 / Float(max(1,diameter))
                                let dy=Float(value.translation.height)
                                    * 455 / Float(max(1,diameter))
                                planetYaw=planetDragYaw+dx*0.006
                                planetPitch=min(1.05,max(-1.05,
                                    planetDragPitch+dy*0.005))
                            }
                            .onEnded { _ in planetDragging=false })
                        .accessibilityLabel(
                            "Oryginalna planeta NewHome290 v568. Przeciągnij, aby obracać.")
                } else {
                    Circle()
                        .fill(Color(red:0.023,green:0.113,blue:0.158))
                        .frame(width:diameter*0.36,height:diameter*0.36)
                        .overlay { Circle().stroke(gold.opacity(0.5),lineWidth:1) }
                }
                Ellipse()
                    .stroke(gold.opacity(0.85),lineWidth:1.5)
                    .frame(width:diameter*0.97,height:diameter*0.38)
                    .rotationEffect(.degrees(-24))
                VStack {
                    HStack {
                        Text("RADAR / SYSTEM NAWIGACJI")
                        Spacer()
                        Text("W3 v568")
                    }
                    .font(.system(size:compact ? 8 : 11,design:.monospaced))
                    .foregroundStyle(muted)
                    Spacer()
                    Text(W3HomePlanetMetal568.isAvailable ? "ORYGINALNA PLANETA NEWHOME290 / 3D METAL" : "MODEL PLANETY 3D — BRAK ZASOBÓW")
                        .font(.system(size:compact ? 8 : 10,design:.monospaced))
                        .foregroundStyle(gold)
                }
                .padding(12)
            }
        }
        .accessibilityLabel(
            W3HomePlanetMetal568.isAvailable
                ? "Radar W3 z oryginalną planetą 3D NewHome290"
                : "Radar W3. Brak zweryfikowanego oryginalnego modelu planety")
    }

    private var telemetry: some View {
        VStack(alignment:.leading,spacing:16) {
            Text("PARAMETRY SYSTEMU")
                .font(.system(size:11,weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
            ForEach(["STATUS  /  ONLINE","SEKTORY / 26",
                     "ŹRÓDŁO / PC v568","SILNIK / METAL",
                     "TRYB / MENU"],id:\.self) { line in
                Text(line)
                    .font(.system(size:11,design:.monospaced))
                    .foregroundStyle(muted)
                Rectangle().fill(cyan.opacity(0.18)).frame(height:1)
            }
            Text("STATEK / PODGLĄD")
                .font(.system(size:11,weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
            if W3HomeShipPreview568.isAvailable {
                W3HomeShipPreview568()
                    // More of the existing sidebar real estate for the
                    // same source-accurate v568 0.34-size Vanguard431 pose.
                    // Changing viewport size does not rescale the 3D mesh.
                    .frame(height:164)
                    .accessibilityLabel(
                        "Oryginalny Vanguard431, domyślny statek 01")
                Text("VANGUARD / TYP 01")
                    .font(.system(size:10,design:.monospaced))
                    .foregroundStyle(muted)
            } else {
                Text("BRAK ORYGINALNEJ SIATKI LUB TEKSTURY")
                    .font(.system(size:10,design:.monospaced))
                    .foregroundStyle(muted)
            }
            Spacer(minLength:0)
        }
        .padding(15)
        .background(Color(red:0.008,green:0.035,blue:0.055).opacity(0.9))
        .overlay { Rectangle().stroke(cyan.opacity(0.2),lineWidth:1) }
    }

    private func footer(compact:Bool) -> some View {
        HStack(spacing:8) {
            Text("ASTEROIDY / NATYWNY PORT W3")
                .foregroundStyle(muted)
            Spacer()
            Button("SCENA TESTOWA") {
                openDiagnostic()
            }
            .fontWeight(.bold)
            .foregroundStyle(gold)
            .accessibilityIdentifier("w3-open-diagnostic")
        }
        .accessibilityElement(children: .contain)
        .font(.system(size:compact ? 9 : 11,design:.monospaced))
        .padding(.horizontal,compact ? 14 : 26)
        .frame(height:compact ? 37 : 52)
        .background(Color(red:0.004,green:0.027,blue:0.048))
        .overlay(alignment:.top) {
            Rectangle().fill(cyan.opacity(0.25)).frame(height:1)
        }
    }

    // Original W3 subpages have their own full-screen chrome, not iOS
    // native sheet/material overlays and not the pre-W3 CampaignAtlas shell.
    @ViewBuilder private func panel(for item:Page,compact:Bool) -> some View {
        GeometryReader { area in
            VStack(alignment:.leading,spacing:compact ? 8 : 14) {
                HStack(spacing:12) {
                    Text("SYNIXAD / "+item.rawValue)
                        .font(.system(size:compact ? 16 : 22,
                                      weight:.bold,design:.monospaced))
                        .foregroundStyle(gold)
                    Spacer()
                    Text("W3 / v568")
                        .font(.system(size:compact ? 9 : 11,design:.monospaced))
                        .foregroundStyle(muted)
                    Button("WSTECZ") {
                        withAnimation(.easeInOut(duration:0.35)) { page=nil }
                    }
                    .font(.system(size:compact ? 11 : 13,
                                  weight:.bold,design:.monospaced))
                    .foregroundStyle(cyan)
                    .padding(.horizontal,12)
                    .frame(minHeight:38)
                    .background(Color(red:0.014,green:0.056,blue:0.085))
                    .overlay(Rectangle().stroke(cyan.opacity(0.55),lineWidth:1))
                    .accessibilityIdentifier("w3-panel-back")
                }
                Rectangle().fill(cyan.opacity(0.36)).frame(height:1)
                if item == .settings {
                    // Windows Menu139 v555: all 17 original left-rail
                    // categories, with implemented iOS engine bindings.
                    CarbonisVisualSettingsPanel568(compact:compact)
                        .frame(maxWidth:.infinity,maxHeight:.infinity)
                } else if item == .campaign {
                    CampaignAtlas556(progress:progress,
                                     dismiss:{page=nil},
                                     onSelect:selectMission,
                                     onInspect:inspectSector)
                        .frame(maxWidth:.infinity,maxHeight:.infinity)
                } else if item == .newGame {
                    newGamePage(compact:compact)
                } else {
                    // Original W3 frame is retained even for an unported
                    // action; never pretend the underlying gameplay exists.
                    VStack(alignment:.leading,spacing:14) {
                        Text("PANEL OPERACYJNY / "+item.rawValue)
                            .font(.system(size:compact ? 11 : 15,
                                          weight:.bold,design:.monospaced))
                            .foregroundStyle(gold)
                        Rectangle().fill(cyan.opacity(0.24)).frame(height:1)
                        Text(message(for:item))
                            .font(.system(size:compact ? 12 : 15,design:.monospaced))
                            .foregroundStyle(paper)
                            .fixedSize(horizontal:false,vertical:true)
                        if item == .continueGame {
                            Button("OTWÓRZ KAMPANIĘ") {
                                withAnimation(.easeInOut(duration:0.35)) {
                                    page = .campaign
                                }
                            }
                            .foregroundStyle(gold)
                            .accessibilityIdentifier("w3-continue-open-campaign")
                        }
                        Spacer(minLength:0)
                    }
                    .frame(maxWidth:.infinity,maxHeight:.infinity,
                           alignment:.topLeading)
                    .padding(compact ? 13 : 22)
                    .background(Color(red:0.006,green:0.026,blue:0.049).opacity(0.94))
                    .overlay(Rectangle().stroke(cyan.opacity(0.22),lineWidth:1))
                }
            }
            .padding(.horizontal,compact ? 12 : 24)
            .padding(.vertical,compact ? 9 : 16)
            .frame(width:area.size.width,height:area.size.height)
        }
        .accessibilityElement(children:.contain)
        .accessibilityIdentifier("w3-panel-\(item.id)")
    }

    // Native Windows ProgramW3Native315.cs has a distinct "new" page,
    // separate from the 26-sector campaign atlas. Co-op and new-profile
    // overwrite semantics are not ported, so these are NOT fake controls.
    private func newGamePage(compact:Bool) -> some View {
        VStack(alignment:.leading,spacing:compact ? 10 : 17) {
            Text("NOWA GRA / KONFIGURACJA")
                .font(.system(size:compact ? 14 : 20,
                              weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
            Text("ORYGINAŁ W3: 1 GRACZ / 2 GRACZY · ŁATWY / NORMALNY / TRUDNY · URUCHOM MISJĘ")
                .font(.system(size:compact ? 10 : 12,design:.monospaced))
                .foregroundStyle(muted)
            Rectangle().fill(cyan.opacity(0.28)).frame(height:1)
            Text("Pełna procedura nowej gry, wybór trudności i tryb 2 graczy wymagają jeszcze przeniesienia profili i startu kampanii z Windows v568. Nie nadpisuję istniejącego zapisu ani nie uruchamiam potajemnie sektora testowego.")
                .font(.system(size:compact ? 11 : 14,design:.monospaced))
                .foregroundStyle(paper)
                .fixedSize(horizontal:false,vertical:true)
            Button("PRZEJDŹ DO KAMPANII / CARBONIS 01") {
                withAnimation(.easeInOut(duration:0.35)) {
                    page = .campaign
                }
            }
            .font(.system(size:compact ? 11 : 13,
                          weight:.bold,design:.monospaced))
            .foregroundStyle(.black)
            .padding(.horizontal,16)
            .frame(minHeight:42)
            .background(gold)
            .accessibilityIdentifier("w3-new-open-campaign")
            Spacer(minLength:0)
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading)
        .padding(compact ? 13 : 22)
        .background(Color(red:0.006,green:0.026,blue:0.049).opacity(0.94))
        .overlay(Rectangle().stroke(cyan.opacity(0.22),lineWidth:1))
        .accessibilityIdentifier("w3-new-game-source-panel")
    }

    private func message(for item:Page) -> String {
        switch item {
        case .continueGame:
            return "Wczytanie rzeczywistego zapisu gry Windows v568 nie jest jeszcze podłączone. Nie uruchamiam przypadkowego sektora."
        case .hangar:
            return "Hangar wymaga oryginalnej sceny hangar_h55.glb, której nie zawiera dostarczona paczka BEZ_HANGARU."
        case .settings:
            return "Ustawienia wybuchów 3D i oświetlenia pocisków są aktywne w osobnych zakładkach."
        case .credits:
            return "SYNIXAD SYSTEMS — ASTEROIDY. Oryginalne źródła: Windows/SteamOS v568. Natywny port iOS jest w trakcie prac."
        case .exit:
            return "Na iPhonie i iPadzie aplikację zamyka się gestem systemowym. Menu pozostaje dostępne."
        case .newGame,.campaign:
            return ""
        }
    }
}
