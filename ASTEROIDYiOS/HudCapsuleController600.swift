import Foundation

/// HUD-only resource smoothing translated from PC v600 HudCapsuleController.
/// The planetarium's original glTF node transforms and animation stay authoritative.
struct HudCapsuleController600 {
    struct Snapshot: Equatable {
        let levels: [Float]
        let flashes: [Float]
        func level(_ i: Int) -> Float { levels[i] }
        func flash(_ i: Int) -> Float { flashes[i] }
    }
    private(set) var snapshot = Snapshot(levels: [1, 1, 1], flashes: [0, 0, 0])
    private var previousTime: Double?
    static func clamp(_ value: Float) -> Float {
        guard value.isFinite else { return 0 }
        return max(0, min(1, value))
    }
    mutating func reset() {
        previousTime = nil
        snapshot = Snapshot(levels: [1, 1, 1], flashes: [0, 0, 0])
    }
    mutating func advance(hull: Float, armor: Float, shield: Float,
                          seconds: Double, hullPulse: Float = 0,
                          armorPulse: Float = 0, shieldPulse: Float = 0) {
        let targets = [hull, armor, shield].map(Self.clamp)
        let pulses = [hullPulse, armorPulse, shieldPulse].map(Self.clamp)
        guard let prior = previousTime, seconds.isFinite,
              seconds >= prior, seconds - prior <= 1 else {
            previousTime = seconds.isFinite ? seconds : nil
            snapshot = Snapshot(levels: targets, flashes: [0, 0, 0])
            return
        }
        let dt = Float(max(0, min(0.08, seconds - prior)))
        previousTime = seconds
        var levels = snapshot.levels
        var flashes = snapshot.flashes
        for i in 0..<3 {
            let delta = targets[i] - levels[i]
            let decay = exp(-dt / (delta < 0 ? 0.16 : 0.27))
            levels[i] = Self.clamp(targets[i] + (levels[i] - targets[i]) * decay)
            flashes[i] = max(flashes[i] * exp(-dt * 12), pulses[i])
        }
        snapshot = Snapshot(levels: levels, flashes: flashes)
    }
}
