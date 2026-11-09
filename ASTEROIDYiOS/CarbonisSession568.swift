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
        var tokenBalance:Int
        var weaponName:String
        var weaponLevel:Int
        var rapidLevel:Int
        var shieldCharges:Int
        var tarczaEnergy:Int?  // nil: unported Tarcza145, never invent energy
        var ionAmmo:Int
        var bombs:Int
        var boostCharges:Int
        var hull:Int
        var armor:Int
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
            hull=game.hull;armor=game.armor;lives=game.lives
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
            // The original IonAmmo, Bombs, Boost71 and Tarcza145 are
            // not executable in this first-sector port. Display actual
            // zero inventory; show an em dash for unavailable energy.
            tarczaEnergy=nil
            ionAmmo=0; bombs=0; boostCharges=0
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
    private(set) var game:CarbonisCombat568
    var move=Vec2(x:0,y:0)
    var aim=Vec2(x:0,y:0)
    var shooting=false
    var paused=false
    var onAudioEvents:(([Int])->Void)?
    private var lastFrame:TimeInterval?
    private var lastHUD:TimeInterval=0
    private var summaryElapsed:Float=0

    init(prepared:Sector01PreparedWave568) {
        let first=CarbonisCombat568(prepared)
        game=first;hud=HUD(first)
    }
    /// Genuine GameOver retry: fresh first-wave state, not a save/unlock.
    func restart(prepared:Sector01PreparedWave568) {
        let restarted=CarbonisCombat568(prepared)
        game=restarted
        release()
        paused=false
        lastFrame=nil
        lastHUD=0
        summaryElapsed=0
        hud=HUD(restarted)
    }
    func input(move:Vec2? = nil,aim:Vec2? = nil,shooting:Bool? = nil) {
        if let move {self.move=move}
        if let aim {self.aim=aim}
        if let shooting {self.shooting=shooting}
    }
    func release() {move=Vec2(x:0,y:0);aim=Vec2(x:0,y:0);shooting=false}
    func frame(at now:TimeInterval) {
        defer{lastFrame=now}
        guard let lastFrame, !paused else {return}
        let elapsed=max(0,min(0.05,now-lastFrame))
        guard elapsed>0 else{return}
        var remaining=Float(elapsed)
        if game.phase == .victory {summaryElapsed+=remaining}
        while remaining>0.000001 && game.phase == .playing {
            let dt=min(1.0/120.0,remaining)
            game.step(move:move,aim:aim,shooting:shooting,dt:dt)
            remaining-=dt
        }
        let soundCodes=game.drainOriginalAudioEvents568()
        if !soundCodes.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.onAudioEvents?(soundCodes)
            }
        }
        if now-lastHUD > 0.10 {
            lastHUD=now
            let snapshot=HUD(game,summarySeconds:summaryElapsed)
            DispatchQueue.main.async { [weak self] in
                self?.hud=snapshot
            }
        }
    }
}
