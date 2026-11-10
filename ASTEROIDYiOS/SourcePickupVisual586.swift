import Foundation

/// PC v583-v585 Menu139 source visual parameters for collectible models.
/// These values NEVER change pickup collision, loot rewards or actor physics.
struct SourcePickupVisual586:Codable,Equatable {
    static let key="ASTEROIDY.iOS.PC586.PickupGLBVisual"
    var brightnessPercent:Int=180
    var shieldPercent:Int=60
    var boostPercent:Int=78
    var energyPercent:Int=78
    var bombPercent:Int=78
    var moneyPercent:Int=78

    mutating func clampAll() {
        brightnessPercent=max(0,min(400,brightnessPercent))
        shieldPercent=max(30,min(150,shieldPercent))
        boostPercent=max(30,min(150,boostPercent))
        energyPercent=max(30,min(150,energyPercent))
        bombPercent=max(30,min(150,bombPercent))
        moneyPercent=max(40,min(150,moneyPercent))
    }

    func visualFactor(_ kind:SourcePickupModels586.Kind)->Float {
        let percent:Int
        switch kind {
        case .shield:percent=shieldPercent
        case .boost:percent=boostPercent
        case .energy:percent=energyPercent
        case .bomb:percent=bombPercent
        }
        return Float(percent)/100
    }
    var moneyFactor:Float {Float(moneyPercent)/100}
    /// Original Renderer.cs sets GPU.ItemGlbFill = percent * 0.0065.
    /// Shader ambient stays independent: 0% disables extra fill only.
    var addedFill:Float {Float(brightnessPercent)*0.0065}

    static func load(_ store:UserDefaults = .standard)->Self {
        guard let data=store.data(forKey:key),
              var settings=try? JSONDecoder().decode(Self.self,from:data)
        else{return Self()}
        settings.clampAll()
        return settings
    }
    func save(_ store:UserDefaults = .standard) {
        var corrected=self
        corrected.clampAll()
        guard let data=try? JSONEncoder().encode(corrected) else{return}
        store.set(data,forKey:Self.key)
    }
}
