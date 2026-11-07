import Foundation

/// Same half-second sampling window as Windows/src/GpuRenderer.cs:202
/// and Renderer.cs:200. Counts only completed Metal GPU command buffers,
/// not nominal 60/120-Hz screen refresh callbacks.
struct SourceFPSAccumulator568 {
    struct Sample {
        let framesPerSecond:Double
        let averageGPUms:Double?
        let cadenceMs:Double
    }
    private var startedAt:Double?
    private var frames:Int=0
    private var gpuTotal:Double=0
    private var gpuValidFrames:Int=0
    static let samplingSeconds:Double=0.5

    mutating func reset() {
        startedAt=nil;frames=0;gpuTotal=0;gpuValidFrames=0
    }
    mutating func completedFrame(at now:Double,gpuMs:Double?)->Sample? {
        guard now.isFinite,now>=0 else {return nil}
        guard let start=startedAt else {
            startedAt=now
            frames=1
            if let gpuMs, gpuMs.isFinite && gpuMs>0 {
                gpuTotal=gpuMs;gpuValidFrames=1
            }
            return nil
        }
        if now<start {reset();startedAt=now;return nil}
        frames+=1
        if let gpuMs, gpuMs.isFinite && gpuMs>0 {
            gpuTotal+=gpuMs
            gpuValidFrames+=1
        }
        let interval=now-start
        guard interval>=Self.samplingSeconds else {return nil}
        let result=Sample(
            framesPerSecond:Double(frames)/interval,
            averageGPUms:gpuValidFrames>0
                ? gpuTotal/Double(gpuValidFrames) : nil,
            cadenceMs:interval*1000/Double(frames))
        startedAt=now
        frames=0
        gpuTotal=0
        gpuValidFrames=0
        return result
    }
}
