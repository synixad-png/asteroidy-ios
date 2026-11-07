import Foundation

@main struct SourceFPSAccumulator568Tests {
    static func main() {
        var meter=SourceFPSAccumulator568()
        var got:SourceFPSAccumulator568.Sample?
        for frame in 0...30 {
            got=meter.completedFrame(at:1+Double(frame)/60.0,
                                     gpuMs:5.0) ?? got
        }
        precondition(SourceFPSAccumulator568.samplingSeconds==0.5)
        guard let sample=got else{fatalError("0.5s FPS window empty")}
        precondition(sample.framesPerSecond>=58 &&
                     sample.framesPerSecond<=65,
                     "must count actually completed frames, not nominal refresh")
        precondition(abs((sample.averageGPUms ?? 0)-5)<0.001,
                     "GPU frame time is real source of milliseconds")
        meter.reset()
        precondition(meter.completedFrame(at:3,gpuMs:nil)==nil)
        let missingGPU=meter.completedFrame(at:3.5,gpuMs:nil)
        precondition(missingGPU != nil)
        precondition(missingGPU!.averageGPUms == nil,
                     "do not invent unavailable GPU duration")
        precondition(meter.completedFrame(at:Double.nan,gpuMs:3)==nil)
        meter.reset()
        let start=meter.completedFrame(at:5,gpuMs:4)
        precondition(start==nil)
        precondition(meter.completedFrame(at:4,gpuMs:4)==nil,
                     "monotonic clock reversal resets FPS sampling")
        print("PASS original v568 FPS half-second completed-frame sample, GPU time, reset and bad clock")
    }
}
