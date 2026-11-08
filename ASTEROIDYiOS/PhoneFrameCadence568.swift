import Foundation

/// Actual MTKViewDelegate.draw(in:) callback cadence, not GPU completion time.
/// Pure iPhone-only diagnostic. Never schedules a frame, changes viewport
/// size, touches the simulation, or draws extra source game geometry.
/// GPU completion and CPU work are measured independently elsewhere.
struct PhoneFrameCadence568 {
    struct Sample {
        let callbackRate:Double
        let averageMs:Double
        let p95Ms:Double
        let peakMs:Double
        let late24:Int
        let late40:Int
        let intervalCount:Int
    }

    private var lastCallback:TimeInterval?
    private var startedAt:TimeInterval?
    private var intervals:[Double]=[]

    mutating func reset() {
        lastCallback=nil
        startedAt=nil
        intervals.removeAll(keepingCapacity:true)
    }

    /// Called once per real iPhone CARBONIS Metal draw callback; NEVER from
    /// command buffer completion, UI refresh or an invented CADisplayLink.
    mutating func drawCallback(at now:TimeInterval) {
        guard now.isFinite && now>=0 else {return}
        guard let previous=lastCallback else {
            startedAt=now
            lastCallback=now
            return
        }
        let delta=now-previous
        if delta<=0 || delta>0.50 {
            // Lock/unlock, backgrounding and timestamp discontinuity must
            // not become a false several-hundred-ms shooting frame spike.
            reset()
            startedAt=now
            lastCallback=now
            return
        }
        lastCallback=now
        intervals.append(delta*1000)
    }

    /// Consume a window only while the existing source FPS overlay updates.
    /// Does not sort/allocate or update SwiftUI during gameplay draw calls.
    mutating func takeSample(at now:TimeInterval)->Sample? {
        guard now.isFinite,let start=startedAt,
              now-start>=0.50,!intervals.isEmpty else {return nil}
        let sorted=intervals.sorted()
        let average=intervals.reduce(0,+)/Double(intervals.count)
        let p95=sorted[min(sorted.count-1,
                           Int((Double(sorted.count)*0.95).rounded(.up))-1)]
        let result=Sample(
            callbackRate:1000/max(0.001,average),
            averageMs:average,
            p95Ms:p95,
            peakMs:sorted[sorted.count-1],
            late24:intervals.filter {$0>=24}.count,
            late40:intervals.filter {$0>=40}.count,
            intervalCount:intervals.count)
        intervals.removeAll(keepingCapacity:true)
        startedAt=now
        return result
    }
}
