import Foundation

// Optional per-frame diagnostics: no Metal dependency, so statistics can be tested on Linux.
// Bounded storage avoids unbounded memory usage during long play sessions.
final class RenderTelemetry {
    enum Stage: String, CaseIterable { case morphCPU, uploadCPU, gpuExecution }
    struct Summary {
        let samples: Int
        let meanMS: Double
        let p95MS: Double
        let maxMS: Double
    }
    private let lock = NSLock()
    private let capacity: Int
    private var values: [Stage: [Double]] = [:]
    private var droppedUpdates = 0
    private var successfulUpdates = 0

    init(capacity: Int = 240) { precondition(capacity > 0); self.capacity = capacity }
    func record(_ stage: Stage, seconds: Double) {
        guard seconds.isFinite, seconds >= 0 else { return }
        lock.lock(); defer { lock.unlock() }
        var series = values[stage] ?? []
        series.append(seconds * 1000.0)
        if series.count > capacity { series.removeFirst(series.count - capacity) }
        values[stage] = series
    }
    func noteUpload(success: Bool) {
        lock.lock(); defer { lock.unlock() }
        if success { successfulUpdates += 1 } else { droppedUpdates += 1 }
    }
    func snapshot() -> (stages: [Stage: Summary], uploads: Int, skipped: Int) {
        lock.lock(); defer { lock.unlock() }
        var summaries: [Stage: Summary] = [:]
        for (stage, series) in values where !series.isEmpty {
            let sorted = series.sorted()
            let p95Index = max(0, Int(ceil(Double(sorted.count) * 0.95)) - 1)
            summaries[stage] = Summary(samples: series.count,
                                       meanMS: series.reduce(0,+) / Double(series.count),
                                       p95MS: sorted[p95Index], maxMS: sorted[sorted.count - 1])
        }
        return (summaries, successfulUpdates, droppedUpdates)
    }
    func report() -> String {
        let result = snapshot()
        var parts = ["morph uploads=\(result.uploads) skipped=\(result.skipped)"]
        for stage in Stage.allCases {
            if let stat = result.stages[stage] {
                parts.append(String(format:"%@ n=%d mean=%.3fms p95=%.3fms max=%.3fms",
                                    stage.rawValue, stat.samples, stat.meanMS, stat.p95MS, stat.maxMS))
            }
        }
        return parts.joined(separator:" | ")
    }
}
