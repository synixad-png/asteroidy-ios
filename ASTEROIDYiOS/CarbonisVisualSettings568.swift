import Foundation

/// 1:1 setting semantics of Windows/src/Explosion524.cs:8-30,
/// Menu139.cs OptionTabs139 "WYBUCHY 3D" (IDs 113..124) and
/// Renderer.cs projectile light controls 42/43/44 ("POCISKI").
/// iOS stores the same values as Codable UserDefaults rather than the
/// Windows-only %LOCALAPPDATA%/Asteroidy/explosions524.txt/visual.txt.
/// This is a visual configuration only: it must never change physics,
/// hitboxes, weapon cadence, damage, drops or mission progress.
struct CarbonisVisualSettings568: Codable, Equatable {
    static let typeNames=["PALIWO","ASTEROIDA","REAKTOR"]
    static let qualityNames=["GAMEPLAY","BALANCED","SHOWCASE"]
    static let shotColorNames=[
        "Automatyczny","Błękit","Złoty","Zielony","Fiolet",
        "Karmazyn","Lodowy","Bursztynowy"]
    static let explosionLabels=[
        "ROZMIAR 3D","LICZBA DUŻYCH KŁĘBÓW",
        "OGIEŃ / TEMPERATURA","SADZA I DYM",
        "NIEREGULARNOŚĆ KŁĘBÓW","ROZRZUT / EKSPANSJA",
        "ODŁAMKI 3D","CZAS EKSPLOZJI"]
    static let minimum=[45,5,0,0,10,40,0,150]
    static let maximum=[170,17,200,200,200,200,100,450]
    static let increments=[1,1,5,5,5,5,1,5]
    static let presets=[
        [100,13,135,100,130,125,50,260],
        [92,11,80,165,145,155,90,270],
        [130,15,160,110,175,150,75,350]]
    static let sourceKey="ASTEROIDY.V568.Visual.Explosion524.ProjectileLight285.v1"

    var type:Int=0
    var quality:Int=0
    var values:[Int]=presets[0]
    var autoRotate:Bool=true
    var projectileBrightness:Int=220
    var projectileColor:Int=0
    var projectileMixed:Bool=true

    mutating func selectPreset(_ next:Int) {
        type=max(0,min(2,next))
        values=Self.presets[type]
    }
    mutating func setValue(_ i:Int,_ raw:Int) {
        guard (0..<8).contains(i) else {return}
        let step=Self.increments[i]
        let low=Self.minimum[i]
        let quantized=low+Int((Double(raw-low)/Double(step)).rounded())*step
        values[i]=max(low,min(Self.maximum[i],quantized))
    }
    func value(_ i:Int)->Int {values[i]}
    func factor(_ i:Int)->Float {Float(values[i])/100}
    var raySamples:Int {[22,32,48][quality]}
    var simultaneousVolumes:Int {[3,4,6][quality]}
    var explosionDuration:Float {min(4.8,Float(values[7])/100+1.6)}
    var shardCount:Int {min(70,Int(Float(values[6])*0.7))}
    var projectileBrightnessFactor:Float {Float(projectileBrightness)/100}
    mutating func clampAll() {
        type=max(0,min(2,type))
        quality=max(0,min(2,quality))
        if values.count != 8 {values=Self.presets[type]}
        for i in 0..<8 {setValue(i,values[i])}
        projectileBrightness=max(0,min(400,
            Int((Double(projectileBrightness)/5).rounded())*5))
        projectileColor=max(0,min(7,projectileColor))
    }
    static func load(_ defaults:UserDefaults = .standard)->Self {
        guard let data=defaults.data(forKey:sourceKey),
              var result=try? JSONDecoder().decode(Self.self,from:data)
        else {return Self()}
        result.clampAll()
        return result
    }
    func save(_ defaults:UserDefaults = .standard) {
        var result=self
        result.clampAll()
        if let data=try? JSONEncoder().encode(result) {
            defaults.set(data,forKey:Self.sourceKey)
        }
    }
}