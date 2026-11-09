import Foundation

/// H13 SceneKit-specific calibration. PC v580's custom OpenGL light shader
/// and SceneKit's PBR photometric lights have different illumination units.
/// These are iOS view parameters, not edits to the authored hangar GLB.
struct H55LightingProfile580 {
    static let defaultFill: Float = 0.80
    static let defaultRed: Float = 0.10
    static let minimumFill: Float = 0.25
    static let maximumFill: Float = 1.0
    static let maximumRed: Float = 0.30

    let fill: Float
    let red: Float

    init(fill: Float = defaultFill, red: Float = defaultRed) {
        self.fill = Self.sanitize(fill, fallback: Self.defaultFill,
                                  minValue: Self.minimumFill, maxValue: Self.maximumFill)
        self.red = Self.sanitize(red, fallback: Self.defaultRed,
                                 minValue: 0, maxValue: Self.maximumRed)
    }

    private static func sanitize(_ value: Float, fallback: Float,
                                 minValue: Float, maxValue: Float) -> Float {
        guard value.isFinite else { return fallback }
        return min(maxValue, max(minValue, value))
    }
}
