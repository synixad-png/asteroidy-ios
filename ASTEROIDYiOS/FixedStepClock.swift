import Foundation

// Renderer-independent scheduling: the same physics step is run regardless of
// ProMotion display refresh. Excessive stalls are bounded, never simulated in
// one huge delta that could tunnel through level geometry.
struct FixedStepClock {
    let step: Double = 1.0 / 120.0
    let maxSteps: Int = 8
    private(set) var remaining: Double = 0
    private(set) var stepsTotal: Int = 0

    mutating func advance(elapsed: Double, update: () -> Void) {
        guard elapsed.isFinite else { return }
        remaining = min(remaining + max(0, min(elapsed, 0.25)),step * Double(maxSteps))
        while remaining + 1e-12 >= step {
            update()
            remaining -= step
            stepsTotal += 1
        }
        remaining = max(0, remaining)
    }
}
