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
        var speed:Float=0
        var sectorDistance:Float=0
        var dockDistance:Float=0
        var orbitTime:Float=0
        var canDock=false
        var missionEntrance:Int=0
        var physicalFrames:Int=0
        var projectiles:Int=0
        var weaponName:String="IMPULS"
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
                rapid:shop.rapidLevel) {
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
        return HUD(target:flight.target,completed:flight.completedMask.nonzeroBitCount,
            speed:flight.orbitSpeed,sectorDistance:flight.orbitDistance,
            dockDistance:flight.dockDistance,orbitTime:flight.orbitTime,
            canDock:flight.canDock90(context:.init(
                planetHub:true,orbitMode:true)),
            missionEntrance:flight.entryMission,physicalFrames:frames,
            projectiles:weapons?.projectiles.count ?? 0,
            weaponName:gunLabel)
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

    func cycleMission() {
        let copy=withLock{()->PC602HomeFlight291? in
            session?.cycleMission()
            return session?.flight
        }
        if let copy {hud=Self.measure(copy,frames:hud.physicalFrames)}
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
