import Foundation

/// Physical after-hit transition from Windows Game.Damage() v556.
/// Pure source behavior: clear active player shots, reset ship to W/2,H/2,
/// heading -PI/2, and move dangerous rocks within 160 geodesic units
/// to 220 units away. Real talent/vitals/FX resets remain separate owners.
enum CombatRespawn556 {
    enum Action:Equatable {
        case none
        case respawned(removedShots:Int,relocatedRocks:Int)
        case gameOver(removedShots:Int)
    }
    static func apply(_ result:CombatSurvival96.Hit,
                      ship:inout CombatBody68,heading:inout Float,
                      rocks:inout [SphereAsteroid556],
                      shots:inout [SphereBolt556],
                      randomAngle:(Int)->Float) -> Action {
        switch result {
        case .ignored, .shieldAbsorbed:
            return .none
        case .gameOver:
            let n=shots.count
            shots.removeAll()
            return .gameOver(removedShots:n)
        case .lifeLost:
            let n=shots.count
            shots.removeAll()
            let center=Vec2(x:640,y:360)
            ship.position=center
            ship.velocity=Vec2(x:0,y:0)
            heading = -Float.pi/2
            var moved=0
            for i in rocks.indices {
                let distance=Sphere67.delta(target:rocks[i].position,
                                             origin:center).lengthSquared
                if distance < 160*160 {
                    let angle=randomAngle(moved)
                    let direction=Vec2(x:cos(angle),y:sin(angle))
                    let speed=sqrt(rocks[i].velocity.lengthSquared)
                    rocks[i].position=Sphere67.offset(center,by:direction*220)
                    rocks[i].velocity=direction*speed
                    moved += 1
                }
            }
            return .respawned(removedShots:n,relocatedRocks:moved)
        }
    }
}
