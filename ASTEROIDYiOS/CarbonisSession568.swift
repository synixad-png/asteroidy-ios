import Foundation
import SwiftUI

/// One persistent state owner for native C279 mission, HUD and touch controls.
/// Metal draws its *actual* simulation, not a second diagnostic sandbox.
final class CarbonisSession568: ObservableObject {
    struct HUD {
        var hull:Int
        var armor:Int
        var lives:Int
        var rocks:Int
        var fighters:Int
        var shots:Int
        var targets:[Vec2]
        var hazards:[Vec2]
        var seconds:Float
        var phase:CarbonisCombat568.Phase
        init(_ game:CarbonisCombat568) {
            hull=game.hull;armor=game.armor;lives=game.lives
            rocks=game.rocks.count;fighters=game.shooters.count
            shots=game.bullets.count
            targets=game.shooters.map {
                Sphere67.delta(target:$0.core.position,origin:game.flight.position)
            }
            hazards=game.rocks.prefix(40).map {
                Sphere67.delta(target:$0.position,origin:game.flight.position)
            }
            seconds=game.elapsed;phase=game.phase
        }
    }
    @Published private(set) var hud:HUD
    private(set) var game:CarbonisCombat568
    var move=Vec2(x:0,y:0)
    var aim=Vec2(x:0,y:0)
    var shooting=false
    var paused=false
    private var lastFrame:TimeInterval?
    private var lastHUD:TimeInterval=0

    init(prepared:Sector01PreparedWave568) {
        let first=CarbonisCombat568(prepared)
        game=first;hud=HUD(first)
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
        while remaining>0.000001 && game.phase == .playing {
            let dt=min(1.0/120.0,remaining)
            game.step(move:move,aim:aim,shooting:shooting,dt:dt)
            remaining-=dt
        }
        if now-lastHUD > 0.10 {
            lastHUD=now
            let snapshot=HUD(game)
            DispatchQueue.main.async { [weak self] in
                self?.hud=snapshot
            }
        }
    }
}
