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
    @Published var planetPreview = false
    @Published var score = 0
    @Published var hull = 3
    @Published var rendererError: String?
}

struct GameView: View {
    @StateObject private var input = FlightInput()
    var body: some View {
        GeometryReader { g in
            ZStack {
                MetalScene(input: input)
                    .ignoresSafeArea()
                VStack {
                    if let error = input.rendererError { Text(error).font(.system(size: 12, weight: .bold)).foregroundStyle(.red).padding(8).background(.black.opacity(0.9)) }
                    HStack {
                        Text("ASTEROIDY  •  iOS LAB v9")
                            .font(.system(size: 17, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.cyan)
                        Spacer()
                        Button(input.planetPreview ? "ARENA TESTOWA" : "BOREAS GLB • TEST") { input.planetPreview.toggle() }
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.cyan)
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .padding(18)
                    HStack { Text("WYNIK: \(input.score)"); Spacer(); Text("KADŁUB: \(input.hull)") }.font(.system(size: 12, design: .monospaced)).padding(.horizontal, 18)
                    Spacer()
                    HStack(alignment: .bottom) {
                        TouchPad(input: input)
                            .frame(width: 150, height: 150)
                        Spacer()
                        Text("OGIEŃ")
                            .font(.system(.headline, design: .monospaced))
                            .frame(width: 100, height: 100)
                            .background(input.shooting ? Color.orange.opacity(0.8) : Color.orange.opacity(0.25), in: Circle())
                            .overlay(Circle().stroke(.orange, lineWidth: 2))
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { _ in input.shooting = true }
                                .onEnded { _ in input.shooting = false })
                            .accessibilityLabel("Strzelaj")
                    }.padding(.horizontal, 45).padding(.bottom, 30)
                }
                .foregroundStyle(.white)
            }.frame(width: g.size.width, height: g.size.height)
        }
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

