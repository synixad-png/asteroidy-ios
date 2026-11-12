import Foundation

/// The single future iOS orbital gameplay state for original PC602 Home291.
/// This is the first complete source-backed coordination of REAL flight,
/// saved PC586 controls, mission selection and H55 dock route. It is not
/// attached to W3 and NEVER simulates a mission result or a garage arrival.
///
/// Only the HOST can create this state from a validated original H290 map
/// and currently equipped legitimate craft. Rendering consumes its flight
/// snapshot; user input advances physics once per explicit frame.
struct PC602HomeWorldSession291 {
    enum SourceError:Error {case invalidFrame}
    private(set) var flight:PC602HomeFlight291
    private(set) var weapons:PC602HomeWeaponTest292
    private(set) var route=PC602HomeHubRoute90()
    private(set) var controls:SourceControls586.Profile
    private(set) var paused=false
    private(set) var steppedFrames=0

    init(home:PC602NewHome290,
         equipment:PC602HomeFlight291.Equipment,
         completedMask:Int=0,
         controls:SourceControls586.Profile) throws {
        self.controls=controls
        // Source Settings(weapon:.pulse) succeeds for the verified
        // initial default. Use a nonfailable, explicit source constant.
        self.weapons=PC602HomeWeaponTest292(
            settings:PC602HomeWeaponTest292.Settings.defaultPulse)
        self.flight=try PC602HomeFlight291(
            home:home,equipment:equipment,completedMask:completedMask)
    }

    mutating func restoreOrbit61(_ saved:PC602OrbitSave61.Snapshot) throws {
        try flight.restoreOrbit61(saved)
        let mechanics=saved.mechanics
        if let gun=PC602HomeWeaponTest292.Weapon(rawValue:saved.shop.weapon.rawValue),
           let settings=PC602HomeWeaponTest292.Settings(
               weapon:gun,upgrade:saved.shop.upgradeLevel,
               rapid:saved.shop.rapidLevel,cooling:mechanics.cooling,
               fireRateTalent:1/(1+Float(mechanics.rateRank)*0.06)) {
            weapons=PC602HomeWeaponTest292(settings:settings)
        } else {throw PC602HomeFlight291.SourceError.invalidInput}
        steppedFrames=0
        paused=true
    }

    /// The PC586 settings screen is the sole owner of its actual saved
    /// bindings; this imports an atomic snapshot instead of mutating
    /// a duplicate key map inside the orbit simulation.
    mutating func adoptControls(_ next:SourceControls586.Profile) {
        controls=next
    }

    /// The authentic existing C279 shop owns purchased weapons and upgrade
    /// levels. Orbital test firing only borrows its immutable values; it
    /// NEVER changes money, ion ammo, score, hits or mission progression.
    mutating func setWeaponSettings(_ settings:PC602HomeWeaponTest292.Settings) {
        weapons.settings=settings
    }
    mutating func setPaused(_ value:Bool) {paused=value}

    /// Exact World -> HardwareInput586 -> Controls586 -> HomeFlight291
    /// pipeline. Returned false means the SOURCE flight did not advance.
    /// Caller owns elapsed time and must not process twice per display tick.
    @discardableResult
    mutating func advance(snapshot:SourceControls586.Snapshot,
                          touchMove:Vec2=Vec2(x:0,y:0),
                          touchAim:Vec2=Vec2(x:0,y:0),
                          touchFire:Bool=false,dt:Float) throws -> Bool {
        guard dt.isFinite,dt>=0 else {throw SourceError.invalidFrame}
        guard !paused,route.location == .orbit,dt>0 else{return false}
        let input=PC602HomeFlightInput291.read(
            snapshot:snapshot,profile:controls,
            touchMove:touchMove,touchAim:touchAim)
        try flight.step(input,dt:dt)
        // Windows StepHomeWeaponTest292 happens AFTER flight movement,
        // using the live ship's heading/velocity. No enemies, rewards.
        weapons.step(ship:flight.flight,dt:dt,
                     fire:touchFire || snapshot.held(6,profile:controls))
        steppedFrames+=1
        return true
    }

    /// H55 is the existing physical SceneKit scene; requestDock returns
    /// permission to present it, NOT proof that an H55 transition ran.
    /// No proximity bypass for direct W3 visits or sceneBusy/talent state.
    @discardableResult
    mutating func requestDock(
        context:PC602HomeFlight291.DockContext)->Bool {
        guard !paused else {return false}
        return route.enterFromOrbit(flight,context:context)
    }

    /// Call only after real existing H55 scene reports an explicit exit.
    /// State returns to same live orbit; never fabricates a new campaign.
    mutating func finishPhysicalH55Visit()->PC602HomeHubRoute90.Exit? {
        route.exitHangar()
    }

    /// No mission 2–26 is dispatched until its actual gameplay port is ready.
    /// This is only source orbit target navigation, no reward/unlock shortcut.
    @discardableResult
    mutating func selectMission(_ level:Int)->Bool {
        guard route.location == .orbit else{return false}
        return flight.select(level)
    }

    mutating func cycleMission() {
        guard route.location == .orbit else{return}
        flight.cycleTarget()
    }

    /// Only real Campaign37/FinishLevel's saved bitmask may call this;
    /// never manufacture completion because an orbit beacon was reached.
    mutating func refreshCommittedCampaign(_ completedMask:Int) {
        flight.applyCompletedMask(completedMask)
    }

    var canEnterAuthoredMissionArea:Int {
        guard !paused,route.location == .orbit else{return 0}
        return flight.entryMission
    }
}
