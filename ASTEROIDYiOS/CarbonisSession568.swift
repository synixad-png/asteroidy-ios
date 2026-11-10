import Foundation
import SwiftUI

/// One persistent state owner for native C279 mission, HUD and touch controls.
/// Metal draws its *actual* simulation, not a second diagnostic sandbox.
final class CarbonisSession568: ObservableObject {
    struct HUD {
        // RendererW3Combat331 uses SphereFocus/Right/Up and removes targets
        // on the far hemisphere, not a flat delta map or a fake radar.
        struct RadarContact {
            let x:Float
            let y:Float
            let kind:Int  // 0 asteroid, 1 fighter, 2 pickup
        }
        var radarContacts:[RadarContact]
        var motion:HudMotion600.Pose = .init()
        var capsuleLevels:HudCapsuleController600.Snapshot = .init(levels:[1,1,1],flashes:[0,0,0])
        var tokenBalance:Int
        var weaponName:String
        var weaponLevel:Int
        var rapidLevel:Int
        var shieldCharges:Int
        var tarczaEnergy:Int?  // real PC Tarcza145 energy, separate from shieldCharges
        var ionAmmo:Int
        var bombs:Int
        var boostCharges:Int
        var boostActive:Bool
        var hull:Int
        var armor:Int
        var maxHull:Int
        var maxArmor:Int
        var lives:Int
        var rocks:Int
        var fighters:Int
        var shots:Int
        var tokenPickups:[Vec2]
        var score:Int
        var collectedTokens:Int
        var destroyedRocks:Int
        var shotDownEnemies:Int
        var summary:Sector01MissionSummary568?
        var summarySeconds:Float
        var targets:[Vec2]
        var hazards:[Vec2]
        var seconds:Float
        var phase:CarbonisCombat568.Phase
        init(_ game:CarbonisCombat568,summarySeconds:Float=0) {
            hull=game.hull;armor=game.armor
            maxHull=game.maxHull;maxArmor=game.maxArmor
            lives=game.lives
            score=game.score;collectedTokens=game.collectedLootTokens
            destroyedRocks=game.rocksDestroyed
            shotDownEnemies=game.shooterKills
            tokenPickups=game.tokenPickups.map {
                Sphere67.delta(target:$0.position,
                               origin:game.flight.position)
            }
            summary=game.missionSummary
            self.summarySeconds=summarySeconds
            rocks=game.rocks.count;fighters=game.shooters.count
            shots=game.bullets.count
            targets=game.shooters.map {
                Sphere67.delta(target:$0.core.position,origin:game.flight.position)
            }
            hazards=game.rocks.prefix(40).map {
                Sphere67.delta(target:$0.position,origin:game.flight.position)
            }
            seconds=game.elapsed;phase=game.phase
            let initialTokens=max(0,game.startingTokens)
            let earned=max(0,game.collectedLootTokens)
            tokenBalance=initialTokens>Int.max-earned ? Int.max : initialTokens+earned
            // PC BossTunnelGame.WeaponName is one canonical source label.
            weaponName=game.selectedWeapon.shortLabel
            weaponLevel=game.upgradeLevel
            rapidLevel=game.rapidLevel
            shieldCharges=game.shieldCharges
            // PC586: three independent active combat resource systems.
            // PC RendererW3Combat331 uses ceiling rather than rounding.
            tarczaEnergy=max(0,Int(ceil(Double(game.tarcza145.energy))))
            ionAmmo=game.ionAmmo; bombs=game.bombs
            boostCharges=game.boost71.charges
            boostActive=game.boost71.active
            let camera=game.flight.camera
            func contact(_ point:Vec2,_ kind:Int)->RadarContact? {
                let n=Sphere67.normal(point)
                if SphereVector3.dot(n,camera.focus) < -0.06 {return nil}
                return RadarContact(
                    x:SphereVector3.dot(n,camera.right),
                    y:-SphereVector3.dot(n,camera.up),kind:kind)
            }
            radarContacts=game.rocks.compactMap {contact($0.position,0)}
                + game.shooters.compactMap {contact($0.core.position,1)}
                + game.tokenPickups.compactMap {contact($0.position,2)}
        }
    }
    @Published private(set) var hud:HUD
    @Published private(set) var hud3DIconsReady600=false
    // Renderer reads one stable copy per GPU frame. The lock isolates
    // layout editing from the Metal render queue without touching physics.
    private let hudLayoutLock600=NSLock()
    private var hudLayoutSnapshot600=HudLayout600.load()
    private var hudSafeInsetsSnapshot600=W3ScreenInsets568()
    private var hudLivePose600=HudMotion600.Pose()
    private var hudLiveCapsules600=HudCapsuleController600.Snapshot(
        levels:[1,1,1],flashes:[0,0,0])
    private var hudLiveSeconds600:Double=0
    func updateHudSafeInsets600(_ insets:W3ScreenInsets568) {
        hudLayoutLock600.lock()
        hudSafeInsetsSnapshot600=insets
        hudLayoutLock600.unlock()
    }
    // One immutable visual snapshot per Metal frame: no publishing and no
    // repeated 46-widget radar/scores rebuild at 60 Hz.
    func currentHudRenderState600()->(
        layout:HudLayout600,insets:W3ScreenInsets568,pose:HudMotion600.Pose,
        capsules:HudCapsuleController600.Snapshot
    ) {
        hudLayoutLock600.lock()
        defer {hudLayoutLock600.unlock()}
        return (hudLayoutSnapshot600,hudSafeInsetsSnapshot600,
                hudLivePose600,hudLiveCapsules600)
    }
    // Hot 60Hz SceneKit/SwiftUI consumers need only 12 small Float fields.
    // Do not copy the 46-widget layout or safe-area metadata just to
    // animate plasma and the three source capsules.
    func currentHudVisual600()->(
        pose:HudMotion600.Pose,capsules:HudCapsuleController600.Snapshot,
        seconds:Double
    ) {
        hudLayoutLock600.lock()
        defer {hudLayoutLock600.unlock()}
        return (hudLivePose600,hudLiveCapsules600,hudLiveSeconds600)
    }
    func updateHudLayout600(_ updated:HudLayout600) {
        guard updated.isValid else{return}
        hudLayoutLock600.lock()
        hudLayoutSnapshot600=updated
        hudLayoutLock600.unlock()
    }
    func setHUD3DIconsReady600(_ ready:Bool) {
        if hud3DIconsReady600 != ready {hud3DIconsReady600=ready}
    }
    private(set) var game:CarbonisCombat568
    var move=Vec2(x:0,y:0)
    var aim=Vec2(x:0,y:0)
    var shooting=false
    var paused=false
    /// Real PC v586 mapping is owned once and loaded at mission entry.
    /// Touch remains independent; keyboard/gamepad input shares gameplay.
    private var controls586=SourceControls586.Profile.load()
    private var controlRouter586=SourceControlRouter586()
    private var touchShieldHeld586=false
    var onPauseRequested:(()->Void)?
    var onAudioEvents:(([Int])->Void)?
    private var lastFrame:TimeInterval?
    private var lastHUD:TimeInterval=0
    private var summaryElapsed:Float=0
    // One visual solver fed by actual mission flight and survival state.
    // This does not enter or alter Game.step, collisions or damage.
    private var hudCapsules600=HudCapsuleController600()
    private var hudMotion600:HudMotion600 = {
        var solver=HudMotion600()
        solver.settings = HudMotion600.Settings.load()
        return solver
    }()
    func applyHudMotion600(_ settings:HudMotion600.Settings) {
        // The SwiftUI sheet updates on main while Metal advances physics.
        // Serialize the solver itself with the live pose, not only its copy.
        hudLayoutLock600.lock()
        hudMotion600.settings=settings
        hudMotion600.reset()
        hudLivePose600=HudMotion600.Pose()
        hudLayoutLock600.unlock()
    }

    init(prepared:Sector01PreparedWave568) {
        let first=CarbonisCombat568(prepared)
        game=first;hud=HUD(first)
    }
    /// Genuine GameOver retry: fresh first-wave state, not a save/unlock.
    func restart(prepared:Sector01PreparedWave568) {
        let restarted=CarbonisCombat568(prepared)
        game=restarted
        release()
        controlRouter586.reset()
        SourceHardwareInput586.shared.clearKeyboard()
        paused=false
        lastFrame=nil
        lastHUD=0
        summaryElapsed=0
        hudLayoutLock600.lock()
        hudMotion600.reset()
        hudLivePose600=HudMotion600.Pose()
        hudLiveCapsules600=HudCapsuleController600.Snapshot(
            levels:[1,1,1],flashes:[0,0,0])
        hudLayoutLock600.unlock()
        hudCapsules600.reset()
        hud=HUD(restarted)
    }
    /// Refresh PC586 assignments only at an explicit scene transition.
    /// Never read UserDefaults in the 120 Hz CARBONIS physics step.
    func refreshControls586() {
        controls586=SourceControls586.Profile.load()
    }
    func input(move:Vec2? = nil,aim:Vec2? = nil,shooting:Bool? = nil) {
        if let move {self.move=move}
        if let aim {self.aim=aim}
        if let shooting {self.shooting=shooting}
    }
    func release() {
        move=Vec2(x:0,y:0)
        aim=Vec2(x:0,y:0)
        shooting=false
        // A paused/backgrounded app cannot retain a stuck V-equivalent.
        touchShieldHeld586=false
        game.setShieldHeld(false)
    }
    func holdShield145(_ pressed:Bool) {
        touchShieldHeld586=pressed && !paused && game.phase == .playing
        game.setShieldHeld(touchShieldHeld586)
        if !touchShieldHeld586 {
            hud=HUD(game,summarySeconds:summaryElapsed)
        }
    }
    @discardableResult func useBoost71()->Bool {
        guard !paused,game.activateBoost71() else{return false}
        hud=HUD(game,summarySeconds:summaryElapsed)
        return true
    }
    /// One physical touch is one bomb action; PC UseBomb validates
    /// threats/inventory/cooldown atomically inside the simulation.
    @discardableResult func useBomb()->Bool {
        guard !paused,game.useBomb() else{return false}
        hud=HUD(game,summarySeconds:summaryElapsed)
        let events=game.drainOriginalAudioEvents568()
        if !events.isEmpty {onAudioEvents?(events)}
        return true
    }
    func frame(at now:TimeInterval) {
        defer{lastFrame=now}
        // One device snapshot per rendered update, not per 120Hz physics
        // substep. Never clone current sim, camera, HUD or touch controls.
        let sourceInput=controlRouter586.read(
            SourceHardwareInput586.shared.snapshot(),profile:controls586)
        if sourceInput.pausePressed {
            DispatchQueue.main.async { [weak self] in
                self?.onPauseRequested?()
            }
            return
        }
        guard let lastFrame, !paused else {return}
        let elapsed=max(0,min(0.05,now-lastFrame))
        guard elapsed>0 else{return}
        if sourceInput.bombPressed {_=useBomb()}
        if sourceInput.boostPressed {_=useBoost71()}
        game.setShieldHeld(touchShieldHeld586 || sourceInput.continuous.shield)
        let controlledMove=sourceInput.continuous.move
        let controlledAim=sourceInput.continuous.aim
        let effectiveMove=controlledMove.hasInput
            ? Vec2(x:controlledMove.x,y:controlledMove.y):move
        let effectiveAim=controlledAim.hasInput
            ? Vec2(x:controlledAim.x,y:controlledAim.y):aim
        let effectiveFire=shooting || sourceInput.continuous.shooting
        var remaining=Float(elapsed)
        if game.phase == .victory {summaryElapsed+=remaining}
        while remaining>0.000001 && game.phase == .playing {
            let dt=min(1.0/120.0,remaining)
            game.step(move:effectiveMove,aim:effectiveAim,
                      shooting:effectiveFire,dt:dt)
            remaining-=dt
        }
        let soundCodes=game.drainOriginalAudioEvents568()
        if !soundCodes.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.onAudioEvents?(soundCodes)
            }
        }
        // Sample only existing authoritative physics state. Never infer
        // combat events from screen pixels or fabricate hit/shot counters.
        var motionSample=HudMotion600.Sample()
        motionSample.turnRate=game.flight.flight.angularVelocity
        motionSample.speed=sqrt(game.flight.velocity.lengthSquared)
        motionSample.bank=game.flight.flight.visualBank
        motionSample.pitch=game.flight.flight.visualPitch
        motionSample.boost=game.boost71.active ? 1 : 0
        motionSample.hull=Float(game.hull)
        motionSample.armor=Float(game.armor)
        motionSample.shield=game.tarcza145.energy
        motionSample.damage=motionSample.hull+motionSample.armor+motionSample.shield
        // PC HudMotionSample.Read: lifetime mission event counters, not
        // active bullet count or wallet balance. Pickups include consumables.
        motionSample.shots=game.hudEvents.shots
        motionSample.hits=game.hudEvents.hits
        motionSample.pickups=game.hudEvents.pickups
        motionSample.shieldActive=game.tarcza145.energy>0
        // The native pause-sheet may change solver settings concurrently.
        // Update the solver and export the pose inside ONE lock region.
        hudLayoutLock600.lock()
        let hudPose600=hudMotion600.update(motionSample,at:now,
                                          active:game.phase == .playing)
        hudLivePose600=hudPose600
        hudLayoutLock600.unlock()
        // Radar/scores/semantic HUD continue publishing at 10 Hz.
        // Feed normalized live values, never inventory charges as energy.
        hudCapsules600.advance(
            hull:Float(game.hull)/Float(max(1,game.maxHull)),
            armor:Float(game.armor)/Float(max(1,game.maxArmor)),
            shield:game.tarcza145.energy/100,
            seconds:now,hullPulse:hudPose600.hullPulse,
            armorPulse:hudPose600.armorPulse,
            shieldPulse:hudPose600.shieldPulse)
        // PC HudCapsuleScene.ApplyHudCapsules runs after every animated
        // GLB frame. Export the small immutable 3x2 state every physics tick;
        // NEVER rebuild the HUD radar or text more frequently.
        hudLayoutLock600.lock()
        hudLiveCapsules600=hudCapsules600.snapshot
        hudLiveSeconds600=Double(game.elapsed)
        hudLayoutLock600.unlock()
        if now-lastHUD > 0.10 {
            lastHUD=now
            var snapshot=HUD(game,summarySeconds:summaryElapsed)
            snapshot.motion=hudPose600
            snapshot.capsuleLevels=hudCapsules600.snapshot
            DispatchQueue.main.async { [weak self] in
                self?.hud=snapshot
            }
        }
    }
}
