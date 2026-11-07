import Foundation

/// The original Windows visual settings are independent of these iOS-only
/// draw budgets. Never change the simulation, destruction events or damage.
/// Two unrelated effects are controlled in their corresponding W3 tabs:
/// WYBUCHY 3D (Explosion524) and POCISKI (ProjectileLight285).
///
/// V2 migrates the previous combined toggle without silently replacing a
/// deliberate user's full-quality preference.
struct CarbonisIOSFXBudget568:Equatable {
    static let key="ASTEROIDY.iOS.V568.FX.REDUCED.V1" // legacy read-only
    static let explosionKey="ASTEROIDY.iOS.V568.FX.ExplosionsReduced.V2"
    static let projectileKey="ASTEROIDY.iOS.V568.FX.ProjectilesReduced.V2"
    static let original=Self(reduced:false)
    static let reducedDefault=Self(reduced:true)

    var explosionsReduced:Bool
    var projectilesReduced:Bool

    init(reduced:Bool=true) {
        explosionsReduced=reduced
        projectilesReduced=reduced
    }
    init(explosionsReduced:Bool,projectilesReduced:Bool) {
        self.explosionsReduced=explosionsReduced
        self.projectilesReduced=projectilesReduced
    }
    // Compatibility for old code/tests; never used for individual UI toggles.
    var reduced:Bool { explosionsReduced && projectilesReduced }

    static func load(_ defaults:UserDefaults = .standard)->Self {
        let old=defaults.object(forKey:key) as? Bool ?? true
        return Self(
            explosionsReduced:
                defaults.object(forKey:explosionKey) as? Bool ?? old,
            projectilesReduced:
                defaults.object(forKey:projectileKey) as? Bool ?? old)
    }
    func save(_ defaults:UserDefaults = .standard) {
        defaults.set(explosionsReduced,forKey:Self.explosionKey)
        defaults.set(projectilesReduced,forKey:Self.projectileKey)
    }

    func volumeCount(_ original:Int)->Int {
        // Original 3/4/6 volumes remain distinguishable as 1/2/2.
        explosionsReduced ? max(0,(original+2)/3) : original
    }
    func raySamples(_ original:Int)->Int {
        // GAMEPLAY 22 -> 10, BALANCED 32 -> 15, SHOWCASE 48 -> 22.
        // Unlike the prior hard min(10), original quality buttons work.
        explosionsReduced ? max(0,(original*10+11)/22) : original
    }
    func gasLobes(_ original:Int)->Int {
        // The original 5..17 clump slider remains responsive: 5->3,
        // default 13->7, 17->9, not hard-clamped to the same 7.
        explosionsReduced ? max(0,(original+1)/2) : original
    }
    func explosionDuration(_ original:Float)->Float {
        // Original duration slider still affects the on-screen lifetime.
        // Default 4.2 seconds -> 1.89 seconds (55% shorter).
        explosionsReduced ? original*0.45 : original
    }
    func particleLimit(_ original:Int)->Int {
        explosionsReduced ? min(96,original) : original
    }
    func pieceLimit(_ original:Int)->Int {
        explosionsReduced ? min(48,original) : original
    }
    func shardLimit(_ original:Int)->Int {
        // Source odlamki 0..100% stays meaningful even in light mode:
        // default 35->12, maximum 70->25, and 0 remains truly off.
        explosionsReduced ? (original*35+50)/100 : original
    }
    var drawBulletGlow:Bool {!projectilesReduced}
    var groundLightLayers:[Int] {
        projectilesReduced ? [2] : [0,1,2,3]
    }
    func groundSlices(_ original:Int)->Int {
        projectilesReduced ? min(12,original) : original
    }
}
