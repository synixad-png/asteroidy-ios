import Foundation
import SwiftUI

/// The real H290 orbital lifetime owner. One PC602HomeWorldSession291
/// advances from the SAME MTKView draw clock that displays its snapshot.
/// The NSLock protects its small mutable state against UIKit/GameController
/// callbacks. There is no second CADisplayLink, repeating Timer, SwiftUI
/// TimelineView, or copy of SourceControls586 user bindings.
final class PC602HomeWorldDriver291:ObservableObject {
    struct HUD {
        var target:Int=1
        var completed:Int=0
        var completedMask:Int=0
        var speed:Float=0
        var sectorDistance:Float=0
        var dockDistance:Float=0
        var orbitTime:Float=0
        var canDock=false
        var missionEntrance:Int=0
        var physicalFrames:Int=0
        var projectiles:Int=0
        var shotEmissions:Int=0
        var enginePower:Float=0.32
        var weaponSoundCode:Int=10
        var weaponName:String="IMPULS"
        var zone:Int=1
        var altitude:Float=12
        var courseDegrees:Float=0
        var selectedUnlocked:Bool=true
        var selectedCompleted:Bool=false
    }

    @Published private(set) var hud=HUD()
    @Published private(set) var presentingH55=false
    @Published private(set) var paused=false
    @Published private(set) var pausePadPresses=0
    @Published private(set) var optionsPadPresses=0
    @Published private(set) var error:String?
    private let lock=NSLock()
    private var session:PC602HomeWorldSession291?
    private var touchMove=Vec2(x:0,y:0)
    private var touchAim=Vec2(x:0,y:0)
    private var touchFire=false
    private var suspended=true
    private var lastUIUpdate:TimeInterval=0
    private var pausePadHeld=false
    private var optionsPadHeld=false

    private func withLock<R>(_ body:()->R)->R {
        lock.lock()
        defer{lock.unlock()}
        return body()
    }

    /// PC602 Windows/src/Campaign37.cs:11–13, Physics68.cs:9 and
    /// FlightDynamics298.cs:14–20. The actual purchased levels are kept
    /// in the existing canonical H55 profile, not a second flight save.
    private static func vanguardEquipment291(
        _ state:H55SourceMechanics580.State)
        ->PC602HomeFlight291.Equipment? {
        guard state.valid,(0...2).contains(state.selectedShip),
              H55SourceMechanics580.registeredModelName(
                forShip:state.selectedShip) != nil else{return nil}
        return PC602HomeFlight291.Equipment(
            craft:state.selectedShip==0 ? .kestrel :
                  state.selectedShip==2 ? .bastion : .vanguard,
            engineLevel:state.engine,
            thrusterRank:state.thruster,
            stabilizerLevel:state.stabilizer)
    }

    /// PC602 Game.ShotIntervalBase97 / Modules97 for the only permitted
    /// native H290 craft. This one canonical read serves W3 start,
    /// H55 service return, Carbonis01 settlement and manual slot load.
    private static func vanguardShotSettings291(
        shop:Sector01Shop568.State,
        mechanics:H55SourceMechanics580.State)
        ->PC602HomeWeaponTest292.Settings? {
        guard Sector01Shop568.validate(shop),mechanics.valid,
              (0...2).contains(mechanics.selectedShip),
              let gun=PC602HomeWeaponTest292.Weapon(rawValue:shop.weapon.rawValue)
        else{return nil}
        return PC602HomeWeaponTest292.Settings(
            weapon:gun,upgrade:shop.upgradeLevel,
            rapid:shop.rapidLevel,cooling:mechanics.cooling,
            fireRateScale:mechanics.selectedShip==0 ? 1.08 :
                          mechanics.selectedShip==2 ? 0.96 : 1,
            fireRateTalent:1/(1+0.06*Float(mechanics.rateRank)),
            ionAmmo:shop.ionAmmo)
    }

    /// Preserve chosen Vanguard and actual H290 flight coordinates.
    /// The canonical shop remains owner of bought weapon and modules;
    /// no second simulated ship profile or recreated scene is introduced.
    private func refreshVanguardShotSettings291() {
        let shop=Sector01Shop568.load()
        let mechanics=H55SourceMechanics580.load()
        guard let settings=Self.vanguardShotSettings291(
            shop:shop,mechanics:mechanics),
            let equipment=Self.vanguardEquipment291(mechanics)
        else {
            error="H290: BRAK ZWERYFIKOWANEGO MODELU WYBRANEGO STATKU"
            return
        }
        let controls=SourceControls586.Profile.load()
        let current=withLock{()->(PC602HomeFlight291,PC602HomeWeaponTest292,Int)? in
            guard var state=session,
                  state.adoptVanguardEquipment(equipment) else{return nil}
            state.setWeaponSettings(settings)
            state.adoptControls(controls)
            session=state
            return (state.flight,state.weapons,state.steppedFrames)
        }
        if let current {
            hud=Self.measure(current.0,frames:current.2,weapons:current.1)
        }
    }

    static var resourcesInstalled:Bool {
        let b=Bundle.main
        func exists(_ name:String,_ ext:String)->Bool {
            b.url(forResource:name,withExtension:ext) != nil ||
            b.url(forResource:name,withExtension:ext,
                  subdirectory:"Assets") != nil
        }
        let ship=H55SourceMechanics580.load().selectedShip
        let playerModelReady=ship==1
            ? exists("Vanguard431Source","mesh") &&
              exists("Vanguard431Base","jpg")
            : ship==2 ? SourceBastion606.load() != nil
            : ship==0 && SourceKestrel603.load() != nil
        return exists("PC602Home290HeightMap","bin") &&
               exists("PC602OrbitBelt51","bin") &&
               playerModelReady &&
               exists("W3HomePlanet290OriginalGPU","bin") &&
               exists("W3HomePlanet290Base","dat") &&
               exists("W3HomePlanet293Glow","dat")
    }

    /// Called explicitly by W3 after a player presses ENTER ORBIT; the
    /// completed mask comes ONLY from CampaignStore556. No mission is earned
    /// or started by constructing the orbit.
    func start(progress:CampaignProgress556) throws {
        let home=try PC602NewHome290.load()
        _=try PC602OrbitBelt51.load()
        guard Self.resourcesInstalled
        else {throw PC602NewHome290.SourceError.missing}
        let mechanics=H55SourceMechanics580.load()
        guard let equipment=Self.vanguardEquipment291(mechanics)
        else {throw PC602HomeFlight291.SourceError.invalidEquipment}
        var initial=try PC602HomeWorldSession291(
            home:home,equipment:equipment,
            completedMask:progress.completedMask,
            controls:SourceControls586.Profile.load())
        if progress.unlocked(progress.selectedSector) {
            _=initial.selectMission(progress.selectedSector)
        }
        if let settings=Self.vanguardShotSettings291(
            shop:Sector01Shop568.load(),
            mechanics:mechanics) {
            initial.setWeaponSettings(settings)
        }
        let copy=initial.flight
        withLock {
            session=initial
            suspended=false
            touchMove=Vec2(x:0,y:0)
            touchAim=Vec2(x:0,y:0)
            touchFire=false
            lastUIUpdate=0
            pausePadHeld=false
            optionsPadHeld=false
        }
        hud=Self.measure(copy,frames:0,weapons:initial.weapons)
        paused=false
        presentingH55=false
        error=nil
        SourceHardwareInput586.shared.clearKeyboard()
    }

    /// PC602 SaveManager61.CaptureResume61 and its three source slot IDs.
    /// Never perform file I/O on the Metal render queue while holding lock.
    @discardableResult func captureResume61()->Bool {
        let flight=withLock{session?.route.location == .orbit ? session?.flight : nil}
        guard let flight,let state=PC602OrbitSave61.capture(flight)
        else{return false}
        do {try PC602OrbitSave61.store(state);return true}
        catch {return false}
    }
    @discardableResult func saveOrbitSlot61(_ slot:Int)->Bool {
        let flight=withLock{session?.route.location == .orbit ? session?.flight : nil}
        guard let flight,let state=PC602OrbitSave61.capture(flight)
        else {error="NIE MOŻNA ZAPISAĆ ORBITY";return false}
        do {
            try PC602OrbitSave61.store(state,slot:slot)
            error=nil
            return true
        } catch {
            self.error="NIE UDAŁO SIĘ ZAPISAĆ SLOTU"
            return false
        }
    }
    @discardableResult func loadOrbitSlot61(_ slot:Int?)->Bool {
        guard !presentingH55,
              let state=try? PC602OrbitSave61.read(slot:slot),
              state.isOrbit61
        else {error="BRAK PRAWIDŁOWEGO ZAPISU ORBITY";return false}
        do {
            let home=try PC602NewHome290.load()
            guard let equipment=Self.vanguardEquipment291(state.mechanics)
            else{throw PC602HomeFlight291.SourceError.invalidEquipment}
            var replacement=try PC602HomeWorldSession291(
                home:home,equipment:equipment,
                completedMask:state.completedMask,
                controls:SourceControls586.Profile.load())
            guard let gunSettings=Self.vanguardShotSettings291(
                shop:state.shop,mechanics:state.mechanics)
            else{error="NIEPOPRAWNE UZBROJENIE ZAPISU";return false}
            try replacement.restoreOrbit61(
                position:SIMD3<Float>(state.position[0],state.position[1],state.position[2]),
                forward:SIMD3<Float>(state.forward[0],state.forward[1],state.forward[2]),
                target:state.target,completedMask:state.completedMask,
                weapon:gunSettings)
            guard SourceNewGame568.restoreOrbitProfile61(
                runID:state.runID,completedMask:state.completedMask,
                target:state.target,shop:state.shop,vitals:state.vitals,
                mechanics:state.mechanics,difficultyRaw:state.difficultyRaw,
                tarczaEnergy145:state.tarczaEnergy145,
                archiveExisting:slot != nil)
            else{error="NIE MOŻNA ZARCHIWIZOWAĆ PROFILU";return false}
            let flight=replacement.flight
            withLock {
                session=replacement
                suspended=false
                touchMove=Vec2(x:0,y:0)
                touchAim=Vec2(x:0,y:0)
                touchFire=false
                lastUIUpdate=0
            }
            hud=Self.measure(flight,frames:0,weapons:replacement.weapons)
            paused=true
            presentingH55=false
            error=nil
            SourceHardwareInput586.shared.clearKeyboard()
            return true
        } catch {
            self.error="NIEPOPRAWNY ZAPIS PC602: "+String(describing:error)
            return false
        }
    }

    func stop() {
        withLock {
            suspended=true
            touchMove=Vec2(x:0,y:0)
            touchAim=Vec2(x:0,y:0)
            touchFire=false
        }
        SourceHardwareInput586.shared.clearKeyboard()
    }

    func setSuspended(_ state:Bool) {
        withLock {
            suspended=state
            if state {
                touchMove=Vec2(x:0,y:0)
                touchAim=Vec2(x:0,y:0)
                touchFire=false
            }
        }
        if state {SourceHardwareInput586.shared.clearKeyboard()}
    }

    func setPaused(_ value:Bool) {
        withLock {
            session?.setPaused(value)
            if value {
                touchMove=Vec2(x:0,y:0)
                touchAim=Vec2(x:0,y:0)
                touchFire=false
            }
        }
        paused=value
        if value {SourceHardwareInput586.shared.clearKeyboard()}
    }

    func setTouch(move:Vec2?=nil,aim:Vec2?=nil) {
        withLock {
            if let move {touchMove=Self.clamped(move)}
            if let aim {touchAim=Self.clamped(aim)}
        }
    }
    func setFiring(_ firing:Bool) {
        withLock {touchFire=firing}
    }

    private static func clamped(_ v:Vec2)->Vec2 {
        guard v.x.isFinite,v.y.isFinite else{return Vec2(x:0,y:0)}
        let distance=sqrt(v.lengthSquared)
        return distance>1 ? v*(1/distance) : v
    }

    func readFlight()->PC602HomeFlight291? {
        withLock{session?.flight}
    }
    func readProjectiles()->[PC602HomeWeaponTest292.Bullet] {
        withLock{session?.weapons.projectiles ?? []}
    }

    private static func measure(_ flight:PC602HomeFlight291,
                                frames:Int,
                                weapons:PC602HomeWeaponTest292?=nil)->HUD {
        let gun=weapons?.settings.weapon
        let gunLabel:String
        switch gun {
        case .twin:gunLabel="PODWÓJNA"
        case .scatter:gunLabel="WACHLARZ"
        case .rail:gunLabel="GAUSS"
        case .swarm:gunLabel="RÓJ"
        default:gunLabel="IMPULS"
        }
        let source330=PC602OrbitHud330.measure(flight)
        return HUD(target:flight.target,completed:flight.completedMask.nonzeroBitCount,
            completedMask:flight.completedMask,speed:flight.orbitSpeed,sectorDistance:flight.orbitDistance,
            dockDistance:flight.dockDistance,orbitTime:flight.orbitTime,
            canDock:flight.canDock90(context:.init(
                planetHub:true,orbitMode:true)),
            missionEntrance:flight.entryMission,physicalFrames:frames,
            projectiles:weapons?.projectiles.count ?? 0,
            shotEmissions:weapons?.emissions ?? 0,
            enginePower:flight.thrusting ? 1 : abs(flight.sideThrust)>0.001 ? 0.70 : 0.32,
            weaponSoundCode:10+(gun?.rawValue ?? 0),
            weaponName:gunLabel,
            zone:source330?.zone ?? 1,
            altitude:source330?.altitude ?? 12,
            courseDegrees:source330?.course ?? 0,
            selectedUnlocked:source330?.unlocked ?? false,
            selectedCompleted:source330?.completed ?? false)
    }

    /// Called by HomeScene291.draw(in:) exactly once per Metal frame.
    /// Only 8 HUD updates/sec are marshalled to the main SwiftUI thread.
    func frame(dt:TimeInterval)->PC602HomeFlight291? {
        var newHud:HUD?
        var sourceError:Error?
        var triggerPausePad=false
        var triggerOptionsPad=false
        let now=ProcessInfo.processInfo.systemUptime
        let latest:PC602HomeFlight291? = withLock {
            guard var session else{return nil}
            if !suspended && session.route.location == .orbit && dt>0 {
                let snapshot=SourceHardwareInput586.shared.snapshot()
                // Program.cs PollController: PC602 source action 9 pauses,
                // action 27 opens settings. Ignore keyboard keys here:
                // physical ESC/remapped key events are already edge-gated
                // by SourceKeyboardCapture586 on the UIKit main thread.
                let padOnly=SourceControls586.Snapshot(
                    buttons:snapshot.buttons,axes:snapshot.axes)
                let pauseDown=padOnly.held(9,profile:session.controls)
                let optionsDown=padOnly.held(27,profile:session.controls)
                triggerPausePad=pauseDown && !pausePadHeld
                triggerOptionsPad=optionsDown && !optionsPadHeld
                pausePadHeld=pauseDown
                optionsPadHeld=optionsDown
                do {
                    _=try session.advance(snapshot:snapshot,
                                          touchMove:touchMove,touchAim:touchAim,
                                          touchFire:touchFire,dt:Float(dt))
                } catch {sourceError=error;suspended=true}
                self.session=session
            }
            if lastUIUpdate==0 || now-lastUIUpdate>=0.125 {
                lastUIUpdate=now
                newHud=Self.measure(session.flight,
                                    frames:session.steppedFrames,
                                    weapons:session.weapons)
            }
            return session.flight
        }
        if triggerPausePad || triggerOptionsPad {
            let pausePress=triggerPausePad
            let optionsPress=triggerOptionsPad
            DispatchQueue.main.async { [weak self] in
                if pausePress {self?.pausePadPresses += 1}
                if optionsPress {self?.optionsPadPresses += 1}
            }
        }
        if let update=newHud {
            DispatchQueue.main.async { [weak self] in
                self?.hud=update
            }
        }
        if let sourceError {
            DispatchQueue.main.async { [weak self] in
                self?.error="PC602 lot zatrzymany: "+String(describing:sourceError)
            }
        }
        return latest
    }

    @discardableResult
    func selectMission(_ level:Int)->Bool {
        let current=withLock{()->(PC602HomeFlight291,PC602HomeWeaponTest292,Int)? in
            guard session?.selectMission(level)==true,
                  let session else{return nil}
            return (session.flight,session.weapons,session.steppedFrames)
        }
        guard let current else{return false}
        // PC OrbitClick51 selects only unlocked stages and preserves the
        // real completion mask. Write only the existing W3 selection key.
        var saved=CampaignStore556.load()
        if saved.selectUnlocked(level) {CampaignStore556.save(saved)}
        // Preserve the actual cumulative shot count when changing the
        // selected beacon. Rebuilding HUD without weapons reset emissions
        // to zero and the next MTKView frame replayed old gun SFX in bulk.
        hud=Self.measure(current.0,frames:current.2,weapons:current.1)
        return true
    }

    func cycleMission() {
        let current=withLock{()->(PC602HomeFlight291,PC602HomeWeaponTest292,Int)? in
            session?.cycleMission()
            guard let session else{return nil}
            return (session.flight,session.weapons,session.steppedFrames)
        }
        if let current {
            var saved=CampaignStore556.load()
            if saved.selectUnlocked(current.0.target) {
                CampaignStore556.save(saved)
            }
            hud=Self.measure(current.0,frames:current.2,weapons:current.1)
        }
    }

    /// Underlying pilot must be WITHIN 43.2 metres of the actual wreck.
    /// An entry request never changes the physical distance or H55 GLB.
    @discardableResult
    func requestH55()->Bool {
        let permitted=withLock{session?.requestDock(context:.init(
            planetHub:true,orbitMode:true)) ?? false}
        if permitted {
            withLock {
                touchMove=Vec2(x:0,y:0)
                touchAim=Vec2(x:0,y:0)
                touchFire=false
            }
            // PC v608 EnterHub90 restores the ACTIVE bar to 100 for
            // free, preserving the bought 0...3 full reserve bars.
            _=SourceTarcza145.savePersistentEnergy(100)
            presentingH55=true
            SourceHardwareInput586.shared.clearKeyboard()
        }
        return permitted
    }

    func exitH55() {
        let result=withLock{
            session?.finishPhysicalH55Visit()
        }
        if result == .orbit {
            presentingH55=false
            refreshVanguardShotSettings291()
            SourceHardwareInput586.shared.clearKeyboard()
        } else {
            error="Odrzucono nieprawidłowe wyjście H55"
        }
    }

    /// Mission 1 is the only actual Carbonis combat gameplay installed.
    /// Mission 2–26 atlas/progression cannot become a fabricated game.
    @discardableResult
    func requestAuthoredMission()->Int {
        withLock {
            guard !suspended,session?.canEnterAuthoredMissionArea==1
            else{return 0}
            return 1
        }
    }

    func refreshCampaign(_ source:CampaignProgress556) {
        let current=withLock{()->(PC602HomeFlight291,PC602HomeWeaponTest292,Int)? in
            session?.refreshCommittedCampaign(source.completedMask)
            guard let session else{return nil}
            return (session.flight,session.weapons,session.steppedFrames)
        }
        if let current {
            hud=Self.measure(current.0,frames:current.2,weapons:current.1)
        }
        refreshVanguardShotSettings291()
    }

    func reportRendererError(_ message:String) {
        error=message
        setSuspended(true)
    }
}
