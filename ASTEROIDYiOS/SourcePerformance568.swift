import Foundation
import Metal
import SwiftUI

/// Actual GPU-completed-frame display; source option Menu139 ID 6.
/// Windows/SteamOS default ShowPerformance=false, persists across restarts.
/// Source: GpuRenderer.cs EndFrame() + Renderer.cs:200 + Controls.cs:16
/// iOS uses a separate UserDefaults key; source visual.txt is untouched.
final class SourcePerformance568: ObservableObject {
    static let shared=SourcePerformance568()
    static let sourceOptionID=6
    static let sourceKey="ASTEROIDY.V568.Visual.ShowPerformance.006"
    @Published private(set) var enabled:Bool
    @Published private(set) var label="Metal GPU · POMIAR..."
    private let lock=NSLock()
    private var sampling:Bool
    private var meter=SourceFPSAccumulator568()

    private init() {
        let saved=UserDefaults.standard.bool(forKey:Self.sourceKey)
        enabled=saved
        sampling=saved
    }
    func setEnabled(_ value:Bool) {
        guard enabled != value else{return}
        lock.lock()
        sampling=value
        meter.reset()
        lock.unlock()
        enabled=value
        label="Metal GPU · POMIAR..."
        UserDefaults.standard.set(value,forKey:Self.sourceKey)
    }
    func toggle() {setEnabled(!enabled)}

    /// Register completion only if measurement is actually requested.
    /// No CADisplayLink fake refresh-number; each record corresponds to
    /// a Metal command buffer committed and completed by the GPU.
    func watch(_ command:MTLCommandBuffer) {
        lock.lock()
        let measuring=sampling
        lock.unlock()
        guard measuring else {return}
        command.addCompletedHandler { [weak self] completed in
            guard completed.status == .completed else {return}
            let begin=completed.gpuStartTime
            let end=completed.gpuEndTime
            let gpuMs:Double?=begin>0 && end>begin
                ? (end-begin)*1000 : nil
            self?.completedFrame(gpuMs:gpuMs)
        }
    }
    private func completedFrame(gpuMs:Double?) {
        lock.lock()
        guard sampling else {lock.unlock();return}
        let next=meter.completedFrame(
            at:ProcessInfo.processInfo.systemUptime,gpuMs:gpuMs)
        lock.unlock()
        guard let sample=next else{return}
        let fps=Int(sample.framesPerSecond.rounded())
        let timeMs=sample.averageGPUms ?? sample.cadenceMs
        let newText=String(format:"Metal GPU · %d FPS · %.1f ms",
                           fps,timeMs)
        DispatchQueue.main.async { [weak self] in
            guard let self, self.enabled else{return}
            self.label=newText
        }
    }
}

/// Source overlays FPS only over actual game scenes, not W3 HOME / splash.
/// Rendered over gameplay without stealing ship touch inputs.
struct SourcePerformanceOverlay568:View {
    @ObservedObject private var performance=SourcePerformance568.shared
    var body:some View {
        if performance.enabled {
            Text(performance.label)
                .font(.system(size:11,weight:.semibold,design:.monospaced))
                .foregroundStyle(.cyan)
                .monospacedDigit()
                .padding(.horizontal,9)
                .padding(.vertical,5)
                .background(.black.opacity(0.62))
                .allowsHitTesting(false)
                .accessibilityIdentifier("source-real-metal-fps-006")
        }
    }
}
