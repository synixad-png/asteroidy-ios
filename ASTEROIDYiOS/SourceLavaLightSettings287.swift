import Foundation

/// Exact Windows v568 Menu139.cs PLANETY option 45 and Renderer.cs
/// LavaLightBrightness287: 0...400%, step 5%, default 180%.
/// The source GPU uses 0...4.0 as the shader intensity, not 0...400.
/// Stored separately so old v568 planet settings decode without migration loss.
struct SourceLavaLightSettings287: Codable, Equatable {
    static let key = "ASTEROIDY.v568.PlanetLavaBrightness287"
    static let minimum = 0
    static let maximum = 400
    static let step = 5
    var brightnessPercent: Int = 180
    static func normalized(_ raw: Int) -> Int {
        let snapped = Int((Double(raw) / 5).rounded()) * 5
        return max(0,min(400,snapped))
    }
    mutating func setBrightness(_ value: Int) {
        brightnessPercent = Self.normalized(value)
    }
    var intensity: Float { Float(brightnessPercent) / 100 }
    func save(_ defaults: UserDefaults = .standard) {
        var copy = self
        copy.setBrightness(copy.brightnessPercent)
        if let bytes=try? JSONEncoder().encode(copy) {
            defaults.set(bytes,forKey:Self.key)
        }
    }
    static func load(_ defaults: UserDefaults = .standard) -> Self {
        guard let bytes=defaults.data(forKey:key),
              var copy=try? JSONDecoder().decode(Self.self,from:bytes)
        else {return Self()}
        copy.setBrightness(copy.brightnessPercent)
        return copy
    }
}
