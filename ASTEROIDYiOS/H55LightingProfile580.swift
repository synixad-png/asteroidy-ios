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

    // All user-facing controls live in W3 Settings > HANGAR, never on
    // the rendered H55 scene. Defaults are iOS calibration, not PC settings.
    static let fillKey="ASTEROIDY_H55_ENV_FILL_580"
    static let redKey="ASTEROIDY_H55_RED_GAIN_580"
    static let safetyKey="ASTEROIDY_H55_SAFE_MATERIALS_580"

    static func saved() -> Self {
        let prefs=UserDefaults.standard
        let fill=(prefs.object(forKey:fillKey) as? NSNumber)?.floatValue ?? defaultFill
        let red=(prefs.object(forKey:redKey) as? NSNumber)?.floatValue ?? defaultRed
        return Self(fill:fill,red:red)
    }

    /// Compatibility is ON by default. Explicitly opt out via W3 Settings
    /// only after a successful device load; avoids GPU compilation storms
    /// from additional SceneKit shader modifiers on first render.
    static var allowCustomEmissionShader:Bool {
        let prefs=UserDefaults.standard
        return prefs.object(forKey:safetyKey) != nil && !prefs.bool(forKey:safetyKey)
    }

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
