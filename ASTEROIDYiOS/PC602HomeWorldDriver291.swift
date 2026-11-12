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
    @Published private(set) var error:String?
    private let lock=NSLock()
    private var session:PC602HomeWorldSession291?
    private var touchMove=Vec2(x:0,y:0)
    private var touchAim=Vec2(x:0,y:0)
    private var touchFire=false
    private var suspended=true
    private var lastUIUpdate:TimeInterval=0

    private func withLock<R>(_ body:()->R)->R {
        lock.lock()
        defer{lock.unlock()}
        return body()
    }

    static var resourcesInstalled:Bool {
        let b=Bundle.main
        func exists(_ name:String,_ ext:String)->Bool {
            b.url(forResource:name,withExtension:ext) != nil ||
            b.url(forResource:name,withExtension:ext,
                  subdirectory:"Assets") != nil
        }
        return exists("PC602Home290HeightMap","bin") &&
               exists("PC602OrbitBelt51","bin") &&
               exists("Vanguard431Source","mesh") &&
               exists("Vanguard431Base","jpg") &&
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
        guard Self.resourcesInstalled,
              let equipment=PC602HomeFlight291.Equipment(craft:.vanguard)
        else {throw PC602NewHome290.SourceError.missing}
        var initial=try PC602HomeWorldSession291(
            home:home,equipment:equipment,
            completedMask:progress.completedMask,
            controls:SourceControls586.Profile.load())
        if progress.unlocked(progress.selectedSector) {
            _=initial.selectMission(progress.selectedSector)
        }
        let shop=Sector01Shop568.load()
        if let gun=PC602HomeWeaponTest292.Weapon(rawValue:shop.weapon.rawValue),
           let settings=PC602HomeWeaponTest292.Settings(
                weapon:gun,upgrade:shop.upgradeLevel,
                rapid:shop.rapidLevel,
                cooling:H55SourceMechanics580.load().cooling,
                fireRateTalent:1/(1+Float(H55SourceMechanics580.load().rateRank)*0.06)) {
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
            error="NIE UDAŁO SIĘ ZAPISAĆ SLOTU"
            return false
        }
    }
    @discardableResult func loadOrbitSlot61(_ slot:Int?)->Bool {
        guard !presentingH55,
              let state=try? PC602OrbitSave61.read(slot:slot)
        else {error="BRAK PRAWIDŁOWEGO ZAPISU";return false}
        do {
            let home=try PC602NewHome290.load()
            guard let equipment=PC602HomeFlight291.Equipment(craft:.vanguard)
            else{throw PC602HomeFlight291.SourceError.invalidEquipment}
            var replacement=try PC602HomeWorldSession291(
                home:home,equipment:equipment,
                completedMask:state.completedMask,
                controls:SourceControls586.Profile.load())
            guard let gun=PC602HomeWeaponTest292.Weapon(rawValue:state.shop.weapon.rawValue),
                  let gunSettings=PC602HomeWeaponTest292.Settings(
                    weapon:gun,upgrade:state.shop.upgradeLevel,
                    rapid:state.shop.rapidLevel,cooling:state.mechanics.cooling,
                    fireRateTalent:1/(1+Float(state.mechanics.rateRank)*0.06))
            else{error="NIEPOPRAWNE UZBROJENIE ZAPISU";return false}
            try replacement.restoreOrbit61(
                position:SIMD3<Float>(state.position[0],state.position[1],state.position[2]),
                forward:SIMD3<Float>(state.forward[0],state.forward[1],state.forward[2]),
                target:state.target,completedMask:state.completedMask,
                weapon:gunSettings)
            guard SourceNewGame568.restoreOrbitProfile61(
                runID:state.runID,completedMask:state.completedMask,
                target:state.target,shop:state.shop,vitals:state.vitals,
                mechanics:state.mechanics,difficultyRaw:state.difficultyRaw)
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
            error="NIEPOPRAWNY ZAPIS PC602: "+String(describing:error)
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
        let now=ProcessInfo.processInfo.systemUptime
        let latest:PC602HomeFlight291? = withLock {
            guard var session else{return nil}
            if !suspended && session.route.location == .orbit && dt>0 {
                let snapshot=SourceHardwareInput586.shared.snapshot()
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
        let copy=withLock{()->PC602HomeFlight291? in
            guard session?.selectMission(level)==true else{return nil}
            return session?.flight
        }
        guard let copy else{return false}
        // PC OrbitClick51 selects only unlocked stages and preserves the
        // real completion mask. Write only the existing W3 selection key.
        var saved=CampaignStore556.load()
        if saved.selectUnlocked(level) {CampaignStore556.save(saved)}
        hud=Self.measure(copy,frames:hud.physicalFrames)
        return true
    }

    func cycleMission() {
        let result=withLock{()->PC602HomeFlight291? in
            session?.cycleMission()
            return session?.flight
        }
        if let result {
            var saved=CampaignStore556.load()
            if saved.selectUnlocked(result.target) {
                CampaignStore556.save(saved)
            }
            hud=Self.measure(result,frames:hud.physicalFrames)
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
        let copy=withLock{()->PC602HomeFlight291? in
            session?.refreshCommittedCampaign(source.completedMask)
            return session?.flight
        }
        if let copy {hud=Self.measure(copy,frames:hud.physicalFrames)}
    }

    func reportRendererError(_ message:String) {
        error=message
        setSuspended(true)
    }
}
