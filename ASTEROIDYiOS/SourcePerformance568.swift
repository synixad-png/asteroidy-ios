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
    // Real timings measured around the actual CARBONIS Metal draw loop.
    // Work excludes waiting for CAMetalDrawable/three in-flight buffers.
    // Simulation is a subset of CPU work, not an additional cost.
    private var cpuWorkTotal:Double=0
    private var cpuSimulationTotal:Double=0
    private var cpuWaitTotal:Double=0
    // iPhone-only precise Metal wait breakdown. The existing iPad FPS
    // label remains byte-for-byte identical, with no extra HUD lines.
    private var drawableWaitTotal:Double=0
    private var streamWaitTotal:Double=0
    private var phoneWaitSamples:Int=0
    // CPU build times only; GPU raster/shading is measured separately
    // by actual gpuStartTime/gpuEndTime, never guessed from FPS.
    private var projectileMeshTotal:Double=0
    private var destructionMeshTotal:Double=0
    private var cpuSamples:Int=0

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
        cpuWorkTotal=0
        cpuSimulationTotal=0
        cpuWaitTotal=0
        drawableWaitTotal=0
        streamWaitTotal=0
        phoneWaitSamples=0
        projectileMeshTotal=0
        destructionMeshTotal=0
        cpuSamples=0
        lock.unlock()
        enabled=value
        label="Metal GPU · POMIAR..."
        UserDefaults.standard.set(value,forKey:Self.sourceKey)
    }
    func toggle() {setEnabled(!enabled)}

    /// CPU stopwatch from the actual Metal callback, collected only when
    /// FPS measurement is switched on. It is not GPU counter time.
    func recordCPU(workMs:Double,simulationMs:Double,waitMs:Double,
                   projectileMeshMs:Double=0,destructionMeshMs:Double=0,
                   drawableWaitMs:Double?=nil,streamWaitMs:Double?=nil) {
        guard workMs.isFinite && simulationMs.isFinite &&
              waitMs.isFinite && workMs>=0 && simulationMs>=0 && waitMs>=0 &&
              projectileMeshMs.isFinite && destructionMeshMs.isFinite &&
              projectileMeshMs>=0 && destructionMeshMs>=0 &&
              (drawableWaitMs.map {$0.isFinite && $0>=0} ?? true) &&
              (streamWaitMs.map {$0.isFinite && $0>=0} ?? true)
        else {return}
        lock.lock()
        if sampling {
            cpuWorkTotal+=workMs
            cpuSimulationTotal+=simulationMs
            cpuWaitTotal+=waitMs
            if let drawableWaitMs,let streamWaitMs {
                drawableWaitTotal+=drawableWaitMs
                streamWaitTotal+=streamWaitMs
                phoneWaitSamples+=1
            }
            projectileMeshTotal+=projectileMeshMs
            destructionMeshTotal+=destructionMeshMs
            cpuSamples+=1
        }
        lock.unlock()
    }

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
        var phoneWait:[Double]?=nil
        let cpu:[Double]?=next.map { _ in
            defer {
                cpuWorkTotal=0
                cpuSimulationTotal=0
                cpuWaitTotal=0
                drawableWaitTotal=0
                streamWaitTotal=0
                phoneWaitSamples=0
                projectileMeshTotal=0
                destructionMeshTotal=0
                cpuSamples=0
            }
            guard cpuSamples>0 else{return []}
            let n=Double(cpuSamples)
            if phoneWaitSamples>0 {
                let pn=Double(phoneWaitSamples)
                phoneWait=[drawableWaitTotal/pn,streamWaitTotal/pn]
            }
            return [cpuWorkTotal/n,cpuSimulationTotal/n,cpuWaitTotal/n,
                    projectileMeshTotal/n,destructionMeshTotal/n]
        }
        lock.unlock()
        guard let sample=next else{return}
        let fps=Int(sample.framesPerSecond.rounded())
        let gpuText=sample.averageGPUms.map {
            String(format:"%.1f", $0)
        } ?? "n/d"
        let cpuText=cpu?.count==5
            ? String(format:"CPU %.1f (SYM %.1f / WAIT %.1f) ms",
                     cpu![0],cpu![1],cpu![2])
            : "CPU n/d"
        // These are wall-clock CPU calculations of geometry, NOT
        // independent GPU pass timings. No new W3 configuration toggle.
        let fxText=cpu?.count==5
            ? String(format:"FX CPU P %.1f / W %.1f ms",
                     cpu![3],cpu![4])
            : "FX CPU n/d"
        // Never call 1/FPS GPU time if Metal GPU timestamps are unavailable.
        // Cadence and GPU execution are distinct, especially at 35 FPS.
        // Additional diagnostics appear ONLY on iPhone, when that
        // renderer supplies the split Metal wait timings. iPad's HUD
        // format and scene remain identical to the already-working #142.
        let phoneText=phoneWait.map {
            String(format:"\nWAIT drawable %.1f / stream %.1f ms",$0[0],$0[1])
        } ?? ""
        let newText="\(fps) FPS · GPU \(gpuText) ms\n"+cpuText+"\n"+fxText+phoneText
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
                .font(.system(size:10,weight:.semibold,design:.monospaced))
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
