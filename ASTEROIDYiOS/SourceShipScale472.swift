import Foundation

/// Original Windows v568 Menu139.cs options 100 and 101.
/// Purely visual multiplier after GpuSphere67.CraftSphere67 StampSphere67.
/// Flight/contact physics, ship health, bullets and collision radii stay unchanged.
struct SourceShipScale472: Codable, Equatable {
    static let key = "ASTEROIDY.v568.VisualShipScale472"
    static let revisionKey = "ASTEROIDY.v568.VisualShipScale472.revision"
    static let minimum = 70
    static let maximum = 150
    static let step = 5
    var missionPercent = 100
    var orbitPercent = 100

    static func snapped(_ raw: Int) -> Int {
        let value = minimum + Int((Double(raw - minimum)/Double(step)).rounded()) * step
        return max(minimum,min(maximum,value))
    }
    mutating func setMission(_ value: Int) { missionPercent = Self.snapped(value) }
    mutating func setOrbit(_ value: Int) { orbitPercent = Self.snapped(value) }
    mutating func clampAll() {
        setMission(missionPercent)
        setOrbit(orbitPercent)
    }
    var missionFactor: Float { Float(missionPercent)*0.01 }
    var orbitFactor: Float { Float(orbitPercent)*0.01 }
    func save(_ defaults: UserDefaults = .standard) {
        var value = self
        value.clampAll()
        if let bytes = try? JSONEncoder().encode(value) {
            defaults.set(bytes,forKey:Self.key)
            defaults.set(defaults.integer(forKey:Self.revisionKey)+1,
                         forKey:Self.revisionKey)
        }
    }
    static func load(_ defaults: UserDefaults = .standard) -> Self {
        guard let bytes = defaults.data(forKey:key),
              var value = try? JSONDecoder().decode(Self.self,from:bytes)
        else { return Self() }
        value.clampAll()
        return value
    }
}
