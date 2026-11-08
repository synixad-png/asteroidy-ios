import SwiftUI
import CryptoKit
import UIKit

// The two original v568 W3 JPEG/PNG byte streams are stored as .dat to avoid\n// Xcode image optimization, then decoded by UIImage(data:) once across all flat
// native menu screens. Never load mismatched or unverified images.
enum SourceW3Images568 {
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
    let startNewGame: (SourceNewGameSelection568)->Bool
    @State private var page: Page?
    @State private var newPlayers568=1
    @State private var newDifficulty568=SourceNewGame568.selection().difficulty
    @State private var confirmNewGame568=false
    @State private var newGameLaunchFailed568=false
    // Windows UiW3NativeLayout315.cs BeginW3NativeTransition327:
    // 1.25 s total, 36% left-side cover + 64% right-side uncover.
    @State private var w3Wiping327 = false
    @State private var w3WipeAmount327: CGFloat = 0
    @State private var w3WipeFromRight327 = false
    // Same Y/X globe rotation axes as the source W3 NewHome290 preview.
    @State private var planetYaw: Float=0
    @State private var planetPitch: Float=0
    @State private var planetDragYaw: Float=0
    @State private var planetDragPitch: Float=0
    @State private var planetDragging=false
    @State private var safeInsets=W3ScreenInsets568()

    private let gold = Color(red: 0.89, green: 0.67, blue: 0.31)
    private let cyan = Color(red: 0.39, green: 0.75, blue: 0.79)
    private let paper = Color(red: 0.92, green: 0.93, blue: 0.94)
    private let muted = Color(red: 0.63, green: 0.73, blue: 0.77)

    var body: some View {
        GeometryReader { proxy in
            let layout=W3AdaptiveViewport568(
                width:proxy.size.width,height:proxy.size.height,
                insets:safeInsets)
            let compact=layout.compact
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
                    header(compact:compact,layout:layout)
                    if let shown=page {
                        panel(for:shown,compact:compact,layout:layout)
                            .frame(maxWidth:.infinity,maxHeight:.infinity)
                            // W3 pages use only the verified 0.45 + 0.80 s shutter.
                    } else {
                        HStack(alignment:.top,spacing:compact ? 10 : 20) {
                            navigation(compact:compact)
                                .frame(width:min(206,max(153,layout.usableWidth * 0.162)))
                            radar(compact:compact)
                                .frame(maxWidth:.infinity,maxHeight:.infinity)
                            // iPhone 15 Pro Max is 932pt wide in landscape,
                            // but its actual safe content can be <850pt.
                            // Do not let the extra telemetry column crush
                            // the genuine transparent 3D NewHome290 globe.
                            if layout.usableWidth > 850 {
                                telemetry
                                    .frame(width:min(215,proxy.size.width * 0.18))
                            }
                        }
                        .padding(.leading,layout.leadingPadding)
                        .padding(.trailing,layout.trailingPadding)
                        .padding(.vertical,compact ? 7 : 16)
                        // HOME also uses that shutter; no extra iOS fade.
                    }
                    footer(compact:compact,layout:layout)
                }
                if w3Wiping327 {
                    // W3 native left-to-right shutter, NOT old modal
                    // fade or duplicated full-screen background assets.
                    GeometryReader { canvas in
                        let top:CGFloat = layout.headerHeight
                        let bottom:CGFloat = layout.footerHeight
                        HStack(spacing:0) {
                            if w3WipeFromRight327 {Spacer(minLength:0)}
                            Rectangle()
                                .fill(Color(red:0.016,green:0.050,blue:0.078))
                                .frame(width:max(0,canvas.size.width*w3WipeAmount327))
                                .overlay(alignment:
                                         w3WipeFromRight327 ? .leading : .trailing) {
                                    Rectangle().fill(gold)
                                        .frame(width:2)
                                }
                            if !w3WipeFromRight327 {Spacer(minLength:0)}
                        }
                        .frame(width:canvas.size.width,
                               height:max(0,canvas.size.height-top-bottom))
                        .offset(y:top)
                    }
                    .allowsHitTesting(true)
                    .accessibilityHidden(true)
                }
            }
            .background {
                W3SafeAreaReader568(insets:$safeInsets)
                    .frame(width:0,height:0)
                    .allowsHitTesting(false)
            }
        }
        // Match the music-first startup on 4:3: background, header and
        // footer use the actual fullscreen viewport, not iPad safe-area
        // letterbox margins that lower the source y=0 W3 top bar.
        .ignoresSafeArea()
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
            OriginalRenderProofWriter568.save(
                proof,filename:"ASTEROIDY_W3_MenuProof.json")
        }
    }

    private func navigateW3(_ destination:Page?) {
        guard !w3Wiping327 else {return}
        w3Wiping327=true
        w3WipeFromRight327=false
        w3WipeAmount327=0
        // Exact source W3 v10 two-phase reference:
        // 1.25 seconds; .36 cover (.45 s), .64 uncover (.80 s);
        // CSS cubic-bezier controls from UiW3NativeLayout315.cs.
        withAnimation(.timingCurve(0.58,0.05,0.28,1,duration:0.45)) {
            w3WipeAmount327=1
        }
        DispatchQueue.main.asyncAfter(deadline:.now()+0.45) {
            page=destination
            w3WipeFromRight327=true
            withAnimation(.timingCurve(0.22,0.7,0.15,1,duration:0.80)) {
                w3WipeAmount327=0
            }
            DispatchQueue.main.asyncAfter(deadline:.now()+0.80) {
                w3Wiping327=false
                w3WipeFromRight327=false
            }
        }
    }

    private func header(compact:Bool,
                        layout:W3AdaptiveViewport568) -> some View {
        HStack(spacing:12) {
            if let image=SourceW3Images568.pair?.logo {
                Image(uiImage:image)
                    .resizable()
                    .scaledToFit()
                    .frame(width:compact ? 86 : 122,height:compact ? 34 : 44)
                    .accessibilityLabel("Oryginalne logo ASTEROIDY W3")
            }
            VStack(alignment:.leading,spacing:2) {
                Text("SYNIXAD SYSTEMS / PROTOTYP INTERFEJSU")
                    .font(.system(size:compact ? 9 : 11,
                                  weight:.heavy,design:.monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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
        .padding(.leading,layout.safeLeft+(compact ? 14 : 26))
        .padding(.trailing,layout.safeRight+(compact ? 14 : 26))
        .padding(.top,layout.safeTop)
        .frame(height:layout.headerHeight)
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
                    navigateW3(item)
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

    // Windows/src/GpuW3HomeReal333.cs:32-59 — HomePlanetPreview333:
    // the real GPU globe is composited directly over the W3 background.
    // glClear(GL_DEPTH_BUFFER_BIT) only. The four backdrop rings and axes
    // in RendererW3Home328.DrawHomePlanetBackdrop333 belong exclusively
    // to the non-GPU fallback; the GPU path must not draw a radar frame,
    // reticle, decorative orbit ellipse, panel tint, or captions here.
    private func radar(compact:Bool) -> some View {
        GeometryReader { geo in
            let diameter=min(geo.size.width * 0.76,geo.size.height * 0.78)
            ZStack {
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
                                // Preserve the already-tested original 455 px
                                // W3 user interaction mapping and planet mesh.
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
                }
                // Intentionally draw nothing if a source-verified model
                // is unavailable; never substitute a fake planet graphic.
            }
            .frame(width:geo.size.width,height:geo.size.height)
        }
        .accessibilityLabel(
            W3HomePlanetMetal568.isAvailable
                ? "Oryginalna planeta 3D NewHome290 na przezroczystym tle"
                : "Brak zweryfikowanego oryginalnego modelu planety")
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

    private func footer(compact:Bool,
                        layout:W3AdaptiveViewport568) -> some View {
        HStack(spacing:8) {
            Text("DOTKNIJ FUNKCJĘ / W3 · NAWIGACJA NATYWNA")
                .foregroundStyle(muted)
            Spacer()
            Text("UI W3 / METAL")
                .foregroundStyle(gold)
            // Windows ProgramW3Native315 does NOT display a test-scene
            // entry in the normal W3 HOME. It must never lead users
            // into the older diagnostic arena unintentionally.
            if ProcessInfo.processInfo.environment["ASTEROIDY_DEBUG_MENU"] == "1" {
                Button("SCENA TESTOWA") { openDiagnostic() }
                    .fontWeight(.bold)
                    .foregroundStyle(gold)
                    .accessibilityIdentifier("w3-open-diagnostic")
            }
        }
        .accessibilityElement(children: .contain)
        .font(.system(size:compact ? 9 : 11,design:.monospaced))
        .padding(.leading,layout.safeLeft+(compact ? 14 : 26))
        .padding(.trailing,layout.safeRight+(compact ? 14 : 26))
        .padding(.bottom,layout.safeBottom)
        .frame(height:layout.footerHeight)
        .background(Color(red:0.004,green:0.027,blue:0.048))
        .overlay(alignment:.top) {
            Rectangle().fill(cyan.opacity(0.25)).frame(height:1)
        }
    }

    // Original W3 subpages have their own full-screen chrome, not iOS
    // native sheet/material overlays and not the pre-W3 CampaignAtlas shell.
    @ViewBuilder private func panel(for item:Page,compact:Bool,
                                    layout:W3AdaptiveViewport568) -> some View {
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
                        navigateW3(nil)
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
                                navigateW3(.campaign)
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
            .padding(.leading,layout.safeLeft+(compact ? 12 : 24))
            .padding(.trailing,layout.safeRight+(compact ? 12 : 24))
            .padding(.vertical,compact ? 9 : 16)
            .frame(width:area.size.width,height:area.size.height)
        }
        .accessibilityElement(children:.contain)
        .accessibilityIdentifier("w3-panel-\(item.id)")
    }

    private func requestNewGame568() {
        guard newPlayers568==1 else {return}
        newGameLaunchFailed568=false
        if SourceNewGame568.hasActiveProfile() {
            confirmNewGame568=true
        } else {
            launchNewGame568()
        }
    }
    private func launchNewGame568() {
        confirmNewGame568=false
        newGameLaunchFailed568 = !startNewGame(SourceNewGameSelection568(
            players:newPlayers568,difficulty:newDifficulty568))
    }
    // Windows ProgramW3Native315.cs:348-354 and v342 explicit
    // non-destructive confirmation. No fictional iOS co-op.
    private func newGamePage(compact:Bool) -> some View {
        // iPhone 15 Pro Max landscape has only ~330pt central height
        // after the source W3 chrome and bottom home-indicator inset.
        // Scroll the REAL source controls; do not scale/tuck away the
        // difficulty, crew, start button or profile confirmation.
        ScrollView(.vertical) {
            VStack(alignment:.leading,spacing:compact ? 9 : 16) {
                Text("NOWA GRA / KONFIGURACJA")
                    .font(.system(size:compact ? 14 : 20,
                                  weight:.bold,design:.monospaced))
                    .foregroundStyle(gold)
                Text("ZAŁOGA")
                    .font(.system(size:compact ? 10 : 12,weight:.bold,design:.monospaced))
                    .foregroundStyle(cyan)
                HStack(spacing:10) {
                    ForEach([1,2],id:\.self) { count in
                        Button(count==1 ? "1 GRACZ" : "2 GRACZY") {
                            newPlayers568=count
                            newGameLaunchFailed568=false
                        }
                        .font(.system(size:compact ? 10 : 13,weight:.semibold,design:.monospaced))
                        .foregroundStyle(newPlayers568==count ? .black : paper)
                        .padding(.horizontal,14).frame(minHeight:40)
                        .background(newPlayers568==count ? gold : Color(red:0.03,green:0.09,blue:0.13))
                        .accessibilityIdentifier("w3-new-players-\(count)")
                    }
                }
                Text("TRUDNOŚĆ")
                    .font(.system(size:compact ? 10 : 12,weight:.bold,design:.monospaced))
                    .foregroundStyle(cyan)
                HStack(spacing:10) {
                    ForEach(CombatBalance556.Difficulty.allCases,id:\.rawValue) { mode in
                        Button(mode == .easy ? "ŁATWY" : mode == .normal ? "NORMALNY" : "TRUDNY") {
                            newDifficulty568=mode
                            newGameLaunchFailed568=false
                        }
                        .font(.system(size:compact ? 10 : 13,weight:.semibold,design:.monospaced))
                        .foregroundStyle(newDifficulty568==mode ? .black : paper)
                        .padding(.horizontal,12).frame(minHeight:40)
                        .background(newDifficulty568==mode ? gold : Color(red:0.03,green:0.09,blue:0.13))
                        .accessibilityIdentifier("w3-new-difficulty-\(mode.rawValue)")
                    }
                }
                Text("VANGUARD / ŻYCIA NA START: \(SourceNewGame568.startingLives(difficulty:newDifficulty568))")
                    .font(.system(size:compact ? 10 : 12,design:.monospaced))
                    .foregroundStyle(paper)
                if newPlayers568==2 {
                    Text("TRYB 2 GRACZY: NIEGOTOWY — brak drugiego statku, sterowania i oryginalnej synchronizacji. Start jest zablokowany.")
                        .font(.system(size:compact ? 10 : 12,design:.monospaced))
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal:false,vertical:true)
                } else {
                    Text("Uruchamia prawdziwą misję CARBONIS 01. Oryginalny 62-sekundowy prolog Story359 nie jest jeszcze przeniesiony na iOS.")
                        .font(.system(size:compact ? 9 : 11,design:.monospaced))
                        .foregroundStyle(muted)
                        .fixedSize(horizontal:false,vertical:true)
                }
                Button("URUCHOM MISJĘ") { requestNewGame568() }
                    .font(.system(size:compact ? 12 : 14,weight:.bold,design:.monospaced))
                    .foregroundStyle(.black)
                    .padding(.horizontal,18)
                    .frame(minHeight:44)
                    .background(gold)
                    .disabled(newPlayers568 != 1)
                    .opacity(newPlayers568==1 ? 1 : 0.5)
                    .accessibilityIdentifier("w3-new-start-source")
                if newGameLaunchFailed568 {
                    Text("Nie udało się zabezpieczyć profilu lub brakuje zweryfikowanych zasobów CARBONIS. Dane poprzedniej gry pozostają bez zmian.")
                        .font(.system(size:compact ? 10 : 12,design:.monospaced))
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal:false,vertical:true)
                }
                Spacer(minLength:0)
            }
            .padding(compact ? 13 : 22)
            .frame(maxWidth:.infinity,alignment:.topLeading)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading)
        .background(Color(red:0.006,green:0.026,blue:0.049).opacity(0.94))
        .overlay(Rectangle().stroke(cyan.opacity(0.22),lineWidth:1))
        .overlay {
            if confirmNewGame568 {
                ZStack {
                    Color.black.opacity(0.82)
                    VStack(spacing:16) {
                        Text("NOWA KAMPANIA / ZABEZPIECZENIE PROFILU")
                            .font(.system(size:compact ? 13 : 18,weight:.bold,design:.monospaced))
                            .foregroundStyle(gold)
                        Text("Obecny profil zostanie najpierw zapisany w kopii bezpieczeństwa. Ręczne zapisy, ustawienia grafiki i muzyki pozostaną nietknięte.")
                            .font(.system(size:compact ? 10 : 13,design:.monospaced))
                            .foregroundStyle(paper)
                            .multilineTextAlignment(.center)
                        HStack(spacing:16) {
                            Button("ANULUJ") {confirmNewGame568=false}
                                .accessibilityIdentifier("w3-new-cancel-confirmation")
                            Button("POTWIERDŹ NOWĄ GRĘ") {launchNewGame568()}
                                .accessibilityIdentifier("w3-new-accept-confirmation")
                        }
                        .font(.system(size:compact ? 11 : 14,weight:.bold,design:.monospaced))
                        .foregroundStyle(cyan)
                    }
                    .padding(24)
                    .frame(maxWidth:600)
                    .background(Color(red:0.02,green:0.05,blue:0.08))
                    .overlay(Rectangle().stroke(gold,lineWidth:1))
                }
                .accessibilityIdentifier("w3-new-confirmation")
            }
        }
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
