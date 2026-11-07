import Foundation

/// Explicit iOS-only rendering budget requested after the earlier
/// source-exact GPU optimization did not improve physical-device FPS.
/// The original Windows visual profile is never overwritten.
///
/// Reduced = default for ALL iOS users (including earlier installs),
/// original = source-identical full visual quality. Gameplay and
/// CarbonisDestruction524 state continue to simulate unchanged.
struct CarbonisIOSFXBudget568:Equatable {
    static let key="ASTEROIDY.iOS.V568.FX.REDUCED.V1"
    static let original=Self(reduced:false)
    static let reducedDefault=Self(reduced:true)
    var reduced:Bool=true

    static func load(_ defaults:UserDefaults = .standard)->Self {
        guard defaults.object(forKey:key) != nil else {
            return .reducedDefault
        }
        return Self(reduced:defaults.bool(forKey:key))
    }
    func save(_ defaults:UserDefaults = .standard) {
        defaults.set(reduced,forKey:Self.key)
    }

    func volumeCount(_ original:Int)->Int {
        reduced ? min(1,original) : original
    }
    func raySamples(_ original:Int)->Int {
        reduced ? min(10,original) : original
    }
    func gasLobes(_ original:Int)->Int {
        reduced ? min(7,original) : original
    }
    func explosionDuration(_ original:Float)->Float {
        reduced ? min(1.9,original) : original
    }
    func particleLimit(_ original:Int)->Int {
        reduced ? min(96,original) : original
    }
    func pieceLimit(_ original:Int)->Int {
        reduced ? min(48,original) : original
    }
    func shardLimit(_ original:Int)->Int {
        reduced ? min(12,original) : original
    }
    var drawBulletGlow:Bool {!reduced}
    var groundLightLayers:[Int] {
        reduced ? [2] : [0,1,2,3]
    }
    func groundSlices(_ original:Int)->Int {
        reduced ? min(12,original) : original
    }
}
