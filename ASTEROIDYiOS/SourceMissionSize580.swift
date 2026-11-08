import Foundation

/// Windows PC v580 Menu139.cs: options 142 (MissionEnemyPercent)
/// and 144 (MissionRockPercent). Only visual geometry is scaled.
/// Neither spawn counts nor physical hit/contact radii are changed.
struct SourceMissionSize580: Codable, Equatable {
    static let key="ASTEROIDY.iOS.v580.MissionEnemyRockVisualSize"
    static let enemyMinimum=30, rockMinimum=40, maximum=150
    static let defaultEnemy=77, defaultRock=78
    var enemyPercent=defaultEnemy
    var rockPercent=defaultRock

    mutating func setEnemy(_ value:Int) {
        enemyPercent=max(Self.enemyMinimum,min(Self.maximum,value))
    }
    mutating func setRock(_ value:Int) {
        rockPercent=max(Self.rockMinimum,min(Self.maximum,value))
    }
    mutating func clampAll() {
        setEnemy(enemyPercent)
        setRock(rockPercent)
    }
    var enemyFactor:Float {Float(enemyPercent)*0.01}
    var rockFactor:Float {Float(rockPercent)*0.01}
    static func load(_ defaults:UserDefaults = .standard)->Self {
        guard let data=defaults.data(forKey:key),
              var value=try? JSONDecoder().decode(Self.self,from:data)
        else {return Self()}
        value.clampAll()
        return value
    }
    func save(_ defaults:UserDefaults = .standard) {
        var value=self
        value.clampAll()
        guard let data=try? JSONEncoder().encode(value) else{return}
        defaults.set(data,forKey:Self.key)
    }
}
