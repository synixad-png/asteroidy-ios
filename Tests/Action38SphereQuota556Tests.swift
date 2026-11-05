import Foundation
@main struct Action38SphereQuota556Tests {
    static func main() {
        let cfg=CombatBalance556(level:7,difficulty:.normal,spherical:true)!
        precondition(GameCore.objectiveFor(level:7) == .clear)
        let player=Vec2(x:640,y:360)
        var unknown=SphereSector556(balance:cfg,diagnosticAsteroids:[],diagnosticIncomingQuota:3)
        unknown.tick(dt:1/120,playerPosition:player,playerRadius:0,detectContacts:false)
        precondition(unknown.incomingRocksLeft == 1 && unknown.asteroids.count == 2,
                     "Unknown enemy status must never prematurely complete a mission")
        let first=unknown.asteroids[0].position,second=unknown.asteroids[1].position
        precondition(abs(first.x-20)<0.01 && abs(second.x-1260)<0.01,
                     "Action38 delivers opposite edges within a pair")
        precondition(Sphere67.delta(target:first,origin:player).lengthSquared >= 260*260-0.1)
        precondition(Sphere67.delta(target:second,origin:player).lengthSquared >= 260*260-0.1)

        var enemies=SphereSector556(balance:cfg,diagnosticAsteroids:[],diagnosticIncomingQuota:3)
        enemies.setVerifiedEnemyCount(1)
        enemies.tick(dt:1/120,playerPosition:player,playerRadius:0,detectContacts:false)
        precondition(enemies.incomingRocksLeft == 1 && enemies.asteroids.count == 2)

        var cleared=SphereSector556(balance:cfg,diagnosticAsteroids:[],diagnosticIncomingQuota:3)
        cleared.setVerifiedEnemyCount(0)
        cleared.tick(dt:1/120,playerPosition:player,playerRadius:0,detectContacts:false)
        precondition(cleared.incomingRocksLeft == 0 && cleared.asteroids.isEmpty)
        precondition(cleared.sectorFinished && cleared.sectorCleared)

        var timed=SphereSector556(balance:
            CombatBalance556(level:9,difficulty:.normal,spherical:true)!,
            diagnosticAsteroids:[],diagnosticIncomingQuota:3)
        timed.setVerifiedEnemyCount(0)
        timed.tick(dt:1/120,playerPosition:player,playerRadius:0,detectContacts:false)
        precondition(timed.incomingRocksLeft==3 && !timed.sectorFinished,
                     "Wave objective must not apply Clear early-quota cancellation")
        print("PASS: Action38 260px safe arrival, pair edges, unknown/enemy/zero verified status and timed-wave isolation")
    }
}
