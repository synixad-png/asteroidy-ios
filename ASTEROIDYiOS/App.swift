import SwiftUI
import MetalKit
import QuartzCore

@main
struct AsteroidyMobileApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
                .preferredColorScheme(.dark)
                .persistentSystemOverlays(.hidden)
        }
    }
}

final class FlightInput: ObservableObject {
    @Published var thrust: Float = 0
    @Published var steer: Float = 0
    @Published var shooting = false
    // Windows Game.Input.Tarcza145 is a momentary held input.
    @Published var tarczaHeld = false
    // Start in the real v556 Boreas GLB renderer instead of the
    // independent 9-rock flat diagnostic arena. This is still a
    // test sector, NOT a port of the complete original mission.
    @Published var planetPreview = true
    // Explicit optional v568 ship 3. Never replace the default Vanguard556.
    @Published var sourceShip367Preview =
        ProcessInfo.processInfo.environment["ASTEROIDY_SHIP367_VERIFY"] == "1"
    // Real IntroScene41 camera/planet/ship positions, but cinematic
    // GPU rock meshes still need source-specific geometric detail.
    // An explicit rendering preview, NEVER a mission completion.
    @Published var introPreview41 =
        ProcessInfo.processInfo.environment["ASTEROIDY_SHIP367_VERIFY"] != "1"
    @Published var introProgress41: Float = 0
    // Source-defined diagnostic cases: ordinary rocks (1), timed waves
    // (9/17) and AmigaOnly266 perpetual bouncing balls (25).
    // This is NOT a mission/campaign unlock selector.
    @Published var planetTestLevel = 1
    @Published var sectorTraining = false
    @Published var verifiedDamageLab = false
    @Published var verifiedGameOver = false
    @Published var verifiedDeaths = 0
    @Published var verifiedArmor = 25
    @Published var verifiedHull = 60
    @Published var verifiedTarczaEnergy: Float = 60
    @Published var verifiedTarczaActive = false
    @Published var trainingRockCount = 9
    @Published var score = 0
    @Published var hull = 3
    @Published var planetSectorCleared = false
    @Published var planetWave = 1
    @Published var planetIncomingNotice = false
    @Published var planetAmigaDemo = false
    @Published var planetAmigaHits = 0
    @Published var rendererError: String?
    // UI-only pause state; do not mutate saved campaign or physics.
    @Published var gameplayPaused = false

    // Touch gestures may not deliver onEnded if iOS backgrounds the app.
    // Clear only transient held inputs; never reset the game simulation.
    func releaseHeldControls() {
        thrust = 0
        steer = 0
        shooting = false
        tarczaHeld = false
    }
}

struct GameView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var input = FlightInput()
    @State private var showCampaign = false
    @State private var campaign = CampaignStore556.load()
    // Native CARBONIS first mission runs an original source-driven state,
    // isolated from Boreas diagnostic scenes and unported later sectors.
    @State private var sourceSector01: Sector01Entry568?
    @State private var sourceSector01Setup: Sector01PreparedWave568?
    @State private var reopenAtlasAfterCarbonis = false

    private func inspectSourceSector(_ sector: Int) {
        guard let entry=Sector01Entry568.open(
            selectedSector:sector,campaign:campaign,
            hasOriginalC279Assets:Sector01CarbonisPreview568.isAvailable)
        else { return }
        // Original Game.Wave plus replay-safe real service profile.
        let sourceShop=Sector01Shop568.load()
        guard let preparedWave=Sector01PreparedWave568.prepare(
            entry:entry,campaign:campaign,
            hasOriginalC279Assets:Sector01CarbonisPreview568.isAvailable,
            difficulty:.normal,seed:Int32.random(in:0...Int32.max),
            currentLives:sourceShop.lives,startingLives:3,
            shopProfile:sourceShop)
        else { return }
        input.releaseHeldControls()
        input.gameplayPaused = true
        showCampaign = false
        reopenAtlasAfterCarbonis = false
        sourceSector01Setup = preparedWave
        sourceSector01 = entry
        showMainMenu = true
    }
    // The genuine W3 navigation is the normal entry point.
    // Existing source-GPU verification remains an explicit simulator mode.
    @State private var showMainMenu =
        ProcessInfo.processInfo.environment["ASTEROIDY_RENDER_VERIFY"] != "1" &&
        ProcessInfo.processInfo.environment["ASTEROIDY_SHIP367_VERIFY"] != "1"
    var body: some View {
        GeometryReader { g in
            ZStack {
                if let sourceEntry=sourceSector01,
                   let preparedWave=sourceSector01Setup {
                    Sector01Scene568(entry:sourceEntry,returnToAtlas:{
                        sourceSector01 = nil
                        sourceSector01Setup = nil
                        reopenAtlasAfterCarbonis = true
                        input.releaseHeldControls()
                        input.gameplayPaused = true
                        showCampaign = false
                        showMainMenu = true
                    },onMissionCompleted:{ report in
                        // Only the real Game.FinishLevel source outcome can
                        // persist completed sector 1 and its token reward.
                        var changed=campaign
                        _ = Sector01MissionSettlement568.commit(
                            report,campaign:&changed)
                        campaign=changed
                    },preparedWave:preparedWave)
                } else if showMainMenu {
                    W3MainMenu568(progress:campaign,selectMission:{ sector in
                        if campaign.selectUnlocked(sector) {
                            CampaignStore556.save(campaign)
                        }
                    },inspectSector: { sector in
                        inspectSourceSector(sector)
                    },openDiagnostic:{
                        input.releaseHeldControls()
                        input.gameplayPaused = false
                        reopenAtlasAfterCarbonis = false
                        showMainMenu = false
                    },openCampaignOnEntry:reopenAtlasAfterCarbonis)
                } else {
                MetalScene(input: input)
                    .ignoresSafeArea()
                VStack {
                    if let error = input.rendererError { Text(error).font(.system(size: 12, weight: .bold)).foregroundStyle(.red).padding(8).background(.black.opacity(0.9)) }
                    // Two compact rows keep the native source-scene
                    // switch reachable in landscape on BOTH iPhone/iPad.
                    HStack {
                        Text("ASTEROIDY  •  iOS v21")
                            .font(.system(size: 17, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.cyan)
                        Spacer(minLength: 8)
                        Button(input.introPreview41 ? "BOREAS 3D" : "PRZELOT 3D") {
                            input.introPreview41.toggle()
                            input.planetPreview = true
                            input.tarczaHeld = false
                            input.shooting = false
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.cyan)
                        Button("MENU W3") {
                            input.releaseHeldControls()
                            showCampaign = false
                            input.gameplayPaused = true
                            showMainMenu = true
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.cyan)
                        Button("KAMPANIA") { showCampaign = true }
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.cyan)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    if !input.introPreview41 {
                        HStack(spacing: 12) {
                            Button(input.planetPreview ? "ARENA • DIAGNOSTYKA" : "BOREAS GLB • TEST") {
                                input.planetPreview.toggle()
                                input.tarczaHeld = false
                                input.shooting = false
                            }
                            Spacer(minLength: 4)
                            Button(input.sectorTraining ? "SEKTOR 01 • TEST" : "9 ASTEROID • TEST") {
                                input.sectorTraining.toggle()
                            }
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 18)
                    }
                    if input.introPreview41 {
                        Text("PRZELOT ORBITALNY / ŹRÓDŁOWA KAMERA • \(Int(input.introProgress41)) / 16 s")
                            .font(.system(size: 11, weight: .medium,
                                          design: .monospaced))
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 18)
                        Text("SCENA ROBOCZA • NIE JEST PEŁNĄ MISJĄ")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 18)
                    } else {
                    HStack {
                        Text("WYNIK: \(input.score)")
                        Spacer()
                        Text("ASTEROIDY: \(input.trainingRockCount)")
                        Spacer()
                        Text(input.planetPreview && input.verifiedDamageLab
                             ? "ŻYCIA V556: \(input.hull)" : "KADŁUB: \(input.hull)")
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.horizontal, 18)
                    if input.planetPreview {
                        Menu {
                            Button("SEKTOR 01 · ASTEROIDY") {
                                input.planetTestLevel = 1
                                input.tarczaHeld = false
                                input.shooting = false
                            }
                            Button("SEKTOR 09 · FALE WALKI") {
                                input.planetTestLevel = 9
                                input.tarczaHeld = false
                                input.shooting = false
                            }
                            Button("SEKTOR 17 · FALE WALKI") {
                                input.planetTestLevel = 17
                                input.tarczaHeld = false
                                input.shooting = false
                            }
                            Button("SEKTOR 25 · AMIGA / PIŁKI ODBIJANE") {
                                input.planetTestLevel = 25
                                input.tarczaHeld = false
                                input.shooting = false
                            }
                        } label: {
                            Text("WYBIERZ SEKTOR TESTOWY: \(input.planetTestLevel)")
                                .font(.system(size: 11, weight: .medium,
                                              design: .monospaced))
                                .foregroundStyle(.cyan)
                        }
                        Button(input.sourceShip367Preview
                               ? "STATEK 03 · ORYGINAŁ v568 (TEST)"
                               : "STATEK v556 · TEST") {
                            input.sourceShip367Preview.toggle()
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.cyan)
                        HStack {
                            Button(input.verifiedDamageLab
                                   ? "TEST OBRAŻEŃ v556: WŁ." : "TEST OBRAŻEŃ v556: WYŁ.") {
                                input.verifiedDamageLab.toggle()
                                input.tarczaHeld = false
                            }
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.orange)
                            if input.verifiedDamageLab {
                                Text(input.verifiedGameOver
                                     ? "KONIEC GRY • TEST" :
                                     "BEZ STRAŻNIKA • UTRATY ŻYCIA: \(input.verifiedDeaths)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(input.verifiedGameOver ? .red : .yellow)
                            }
                        }
                        if input.verifiedDamageLab {
                            Text("PANCERZ: \(input.verifiedArmor)/25 · KADŁUB: \(input.verifiedHull)/60")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.yellow)
                            Text("TARCZA v556: \(Int(input.verifiedTarczaEnergy.rounded()))/100")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(input.verifiedTarczaActive ? .cyan : .gray)
                        }
                        if input.planetAmigaDemo {
                            Text("AMIGA / PIŁKI ODBIJANE")
                                .font(.system(size: 11, weight: .medium,
                                              design: .monospaced))
                                .foregroundStyle(.cyan)
                            Text("TRAFIENIA: \(input.planetAmigaHits) · POKAZ DEMO · STRZELAJ, ABY NADAĆ PĘD")
                                .font(.system(size: 10,design:.monospaced))
                                .foregroundStyle(.white)
                        } else {
                            Text(input.planetSectorCleared
                                 ? "TEST SEKTORA UKOŃCZONY"
                                 : input.planetIncomingNotice
                                 ? "NOWE ASTEROIDY NA ORBICIE"
                                 : "BOREAS • SYMULACJA WALKI • FALA \(input.planetWave)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(input.planetSectorCleared ? .green :
                                             input.planetIncomingNotice ? .orange : .cyan)
                        }
                    }
                    Spacer()
                    HStack(alignment: .bottom) {
                        TouchPad(input: input)
                            .frame(width: input.planetPreview && input.verifiedDamageLab
                                   ? min(120, max(95, g.size.width * 0.28)) : 150,
                                   height: input.planetPreview && input.verifiedDamageLab
                                   ? min(120, max(95, g.size.width * 0.28)) : 150)
                        Spacer(minLength: 4)
                        if input.planetPreview && input.verifiedDamageLab {
                            Text("TARCZA")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .frame(width: 68, height: 68)
                                .background(input.tarczaHeld
                                    ? Color.cyan.opacity(0.65) : Color.cyan.opacity(0.2),
                                    in: Circle())
                                .overlay(Circle().stroke(.cyan, lineWidth: 2))
                                .gesture(DragGesture(minimumDistance: 0)
                                    .onChanged { _ in input.tarczaHeld = true }
                                    .onEnded { _ in input.tarczaHeld = false })
                                .accessibilityLabel("Przytrzymaj tarczę v556")
                        }
                        Text("OGIEŃ")
                            .font(.system(.headline, design: .monospaced))
                            .frame(width: input.planetPreview && input.verifiedDamageLab
                                   ? min(86, max(72, g.size.width * 0.22)) : 100,
                                   height: input.planetPreview && input.verifiedDamageLab
                                   ? min(86, max(72, g.size.width * 0.22)) : 100)
                            .background(input.shooting ? Color.orange.opacity(0.8) : Color.orange.opacity(0.25), in: Circle())
                            .overlay(Circle().stroke(.orange, lineWidth: 2))
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { _ in input.shooting = true }
                                .onEnded { _ in input.shooting = false })
                            .accessibilityLabel("Strzelaj")
                    }.padding(.horizontal,
                               input.planetPreview && input.verifiedDamageLab ? 16 : 45)
                     .padding(.bottom, 30)
                    }
                }
                .foregroundStyle(.white)
                if showCampaign {
                    CampaignAtlas556(progress: campaign,
                                     dismiss: { showCampaign = false },
                                     onSelect: { sector in
                                         if campaign.selectUnlocked(sector) {
                                             CampaignStore556.save(campaign)
                                         }
                                     },
                                     onInspect: { sector in inspectSourceSector(sector) })
                }
                }
            }.frame(width: g.size.width, height: g.size.height)
        }
        .onChange(of: scenePhase) { phase in
            input.gameplayPaused = phase != .active || showCampaign || showMainMenu
            if phase != .active { input.releaseHeldControls() }
        }
        .onChange(of: showCampaign) { visible in
            input.gameplayPaused = visible || showMainMenu || scenePhase != .active
            if visible { input.releaseHeldControls() }
        }
        .onChange(of: showMainMenu) { visible in
            input.gameplayPaused = visible || showCampaign || scenePhase != .active
            if visible { input.releaseHeldControls() }
        }
    }
}

// Real unlocked-only 26-sector selection from Orbit50.MissionUnlocked50.
// LaunchOrbitMission50 / StartHubMission261 combat are NOT ported yet.
// Full CARBONIS first mission completion is earned from the actual
// combat world; later sectors are still under active porting.
struct CampaignAtlas556: View {
    let progress: CampaignProgress556
    let dismiss: () -> Void
    let onSelect: (Int) -> Void
    let onInspect: (Int) -> Void
    private let columns = [GridItem(.adaptive(minimum:52,maximum:90),spacing:8)]

    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:12) {
                HStack {
                    Text("KAMPANIA / 26 SEKTORÓW")
                        .font(.system(.headline,design:.monospaced))
                    Spacer()
                    Button("ZAMKNIJ",action:dismiss)
                        .accessibilityLabel("Zamknij atlas misji")
                }
                Text("UKOŃCZONE: \(progress.completedCount) / 26")
                    .font(.system(.subheadline,design:.monospaced))
                    .foregroundStyle(.cyan)
                Text("WYBRANY SEKTOR: \(String(format:"%02d",progress.selectedSector))")
                    .font(.system(size:13,weight:.bold,design:.monospaced))
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("campaign-selected-sector")
                Text(MissionCatalog568.title(for:progress.selectedSector) ?? "BRAK SEKTORA")
                    .font(.system(size:11,weight:.semibold,design:.monospaced))
                    .foregroundStyle(.cyan)
                    .accessibilityIdentifier("campaign-selected-planet")
                if progress.selectedSector == 1 {
                    VStack(alignment:.leading,spacing:5) {
                        Text("CARBONIS — ORYGINALNA PLANETA 3D / ŹRÓDŁOWA SIATKA")
                            .font(.system(size:10,weight:.semibold,design:.monospaced))
                            .foregroundStyle(.orange)
                        if Sector01CarbonisPreview568.isAvailable {
                            Sector01CarbonisPreview568()
                                .frame(height:166)
                                .accessibilityLabel("Źródłowa planeta CARBONIS, podgląd 3D")
                        } else {
                            Text("BRAK ZWERYFIKOWANEJ SIATKI C279 W PAKIECIE")
                                .font(.system(size:10,design:.monospaced))
                                .foregroundStyle(.secondary)
                        }
                        Text("GRAJ W CARBONIS 01 · UKOŃCZENIE ODBLOKOWUJE SEKTOR 02")
                            .font(.system(size:10,design:.monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth:.infinity,alignment:.leading)
                }
                LazyVGrid(columns:columns,spacing:8) {
                    ForEach(1...CampaignProgress556.missionCount,id:\.self) { sector in
                        let finished=progress.completed(sector)
                        let available=progress.unlocked(sector)
                        let current=progress.selectedSector == sector
                        Button {
                            // Protect original orbit unlock state, also in
                            // case a programmatic callback invokes this.
                            if available { onSelect(sector) }
                        } label: {
                            VStack(spacing:4) {
                                Text(String(format:"%02d",sector))
                                    .font(.system(.headline,design:.monospaced))
                                Image(systemName:finished ? "checkmark.circle.fill"
                                      : current ? "location.circle.fill"
                                      : available ? "circle" : "lock.fill")
                            }
                            .foregroundStyle(current ? Color.orange :
                                             finished ? Color.green :
                                             available ? Color.cyan : Color.gray)
                            .frame(maxWidth:.infinity,minHeight:48)
                            .background(current ? Color.orange.opacity(0.2)
                                        : Color.white.opacity(0.07),
                                        in:RoundedRectangle(cornerRadius:8))
                            .overlay {
                                RoundedRectangle(cornerRadius:8)
                                    .stroke(current ? Color.orange : Color.clear,
                                            lineWidth:2)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!available)
                        .accessibilityIdentifier("campaign-sector-\(sector)")
                        .accessibilityLabel(
                            "Sektor \(sector), \(MissionCatalog568.title(for:sector) ?? "brak nazwy"), " +
                            "\(finished ? "ukończony" : available ? "odblokowany" : "zablokowany")")
                        .accessibilityAddTraits(.isButton)
                    }
                }
                Text("Dotknij odblokowanego sektora, aby go wybrać. Wybór jest zapisywany, ale nie zalicza misji.")
                    .font(.system(size:11,design:.monospaced))
                    .foregroundStyle(.secondary)
                if progress.selectedSector == 1 &&
                   progress.unlocked(1) &&
                   Sector01CarbonisPreview568.isAvailable {
                    Button("ROZPOCZNIJ CARBONIS 01 / PEŁNA WALKA") {
                        onInspect(1)
                    }
                    .font(.system(size:12,weight:.bold,design:.monospaced))
                    .foregroundStyle(.black)
                    .frame(maxWidth:.infinity,minHeight:46)
                    .background(.orange,in:RoundedRectangle(cornerRadius:7))
                    .accessibilityIdentifier("campaign-enter-source-sector01")
                }
                Text("SEKTOR 01: WALKA, RAPORT, ŻETONY I ZAPIS · POZOSTAŁE SEKTORY W OPRACOWANIU")
                    .font(.system(size:11,weight:.bold,design:.monospaced))
                    .foregroundStyle(.orange)
            }
            .padding(18)
        }
        .frame(maxWidth:740,maxHeight:550)
        .background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:18))
        .padding(12)
        .accessibilityElement(children:.contain)
        .accessibilityIdentifier("campaign-26-sector-selector")
    }
}

struct TouchPad: View {
    @ObservedObject var input: FlightInput
    @State private var offset: CGSize = .zero
    var body: some View {
        GeometryReader { proxy in
            let r = min(proxy.size.width, proxy.size.height) * 0.31
            Circle().fill(.cyan.opacity(0.08)).overlay(Circle().stroke(.cyan.opacity(0.4)))
                .overlay(
                    Circle().fill(.cyan.opacity(0.35))
                        .frame(width: 54, height: 54)
                        .offset(offset)
                )
                .contentShape(Circle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let dx = value.location.x - proxy.size.width / 2
                        let dy = value.location.y - proxy.size.height / 2
                        let length = max(1, sqrt(dx * dx + dy * dy))
                        let scale = min(1, r / length)
                        offset = CGSize(width: dx * scale, height: dy * scale)
                        input.steer = Float(offset.width / r)
                        input.thrust = Float(-offset.height / r)
                    }
                    .onEnded { _ in offset = .zero; input.steer = 0; input.thrust = 0 })
        }
    }
}

struct MetalScene: UIViewRepresentable {
    @ObservedObject var input: FlightInput
    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.sampleCount = 1
        view.clearColor = MTLClearColor(red: 0.01, green: 0.025, blue: 0.07, alpha: 1)
        view.preferredFramesPerSecond = 60
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        if let device = view.device {
            do {
                let renderer = try MetalRenderer(device: device, input: input)
                context.coordinator.renderer = renderer
                view.delegate = renderer
            } catch {
                DispatchQueue.main.async { input.rendererError = "Metal: \(error.localizedDescription)" }
            }
        } else {
            DispatchQueue.main.async { input.rendererError = "Metal nie jest dostępny na tym urządzeniu" }
        }
        return view
    }
    func updateUIView(_ uiView: MTKView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var renderer: MetalRenderer? }
}

