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
    var body: some View {
        GeometryReader { g in
            ZStack {
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
                    CampaignAtlas556(progress: campaign, dismiss: { showCampaign = false })
                }
            }.frame(width: g.size.width, height: g.size.height)
        }
        .onChange(of: scenePhase) { phase in
            input.gameplayPaused = phase != .active || showCampaign
            if phase != .active { input.releaseHeldControls() }
        }
        .onChange(of: showCampaign) { visible in
            input.gameplayPaused = visible || scenePhase != .active
            if visible { input.releaseHeldControls() }
        }
    }
}

// Read-only mission atlas. A mission is never claimed playable before porting.
struct CampaignAtlas556: View {
    let progress: CampaignProgress556
    let dismiss: () -> Void
    private let columns = Array(repeating: GridItem(.flexible(),spacing:8),count:7)

    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                HStack {
                    Text("KAMPANIA / 26 SEKTORÓW").font(.system(.headline, design:.monospaced))
                    Spacer()
                    Button("ZAMKNIJ",action:dismiss).accessibilityLabel("Zamknij atlas misji")
                }
                Text("UKOŃCZONE: \(progress.completedCount) / 26")
                    .font(.system(.subheadline,design:.monospaced)).foregroundStyle(.cyan)
                LazyVGrid(columns:columns,spacing:8) {
                    ForEach(1...CampaignProgress556.missionCount,id:\.self) { sector in
                        let finished = progress.completed(sector)
                        let available = progress.unlocked(sector)
                        VStack(spacing:4) {
                            Text(String(format:"%02d",sector)).font(.system(.headline,design:.monospaced))
                            Image(systemName:finished ? "checkmark.circle.fill" : available ? "circle" : "lock.fill")
                        }
                        .foregroundStyle(finished ? Color.green : available ? Color.cyan : Color.gray)
                        .frame(maxWidth:.infinity,minHeight:48)
                        .background(Color.white.opacity(0.07),in:RoundedRectangle(cornerRadius:8))
                        .accessibilityElement(children:.ignore)
                        .accessibilityLabel("Sektor \(sector), \(finished ? "ukończony" : available ? "odblokowany" : "zablokowany")")
                    }
                }
                Text("Atlas odzwierciedla zasady odblokowania z v556. Rozgrywanie misji i zaliczanie postępu zostaną uruchomione po przeniesieniu oryginalnych misji.")
                    .font(.system(.caption,design:.monospaced)).foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .frame(maxWidth:740,maxHeight:550)
        .background(.ultraThinMaterial,in:RoundedRectangle(cornerRadius:18))
        .padding(20)
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

