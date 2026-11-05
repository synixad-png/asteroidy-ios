import Foundation

/// End-to-end source-order regressions. Windows Game.Step executes:
/// shard expiration (Game.cs:238) -> rock motion (239) ->
/// StepAction/SpawnIncoming (240) -> StepSolids68 (248) ->
/// bullet/rock hit resolution (251-270).
@main struct Action38FrameOrder556Tests {
    static func main() {
        let player=Vec2(x:640,y:360)
        let config=CombatBalance556(level:1,difficulty:.normal,spherical:true)!

        // Find the actual seeded incoming location using the same source
        // wave logic as the live sector. Do not invent a spawn coordinate.
        var preview=SphereSector556(balance:config,
            diagnosticAsteroids:[],diagnosticIncomingQuota:1)
        _=preview.tick(dt:1/120,playerPosition:player,
            playerRadius:0,detectContacts:false)
        precondition(preview.asteroids.count==1)
        let arrival=preview.asteroids[0]
        precondition(arrival.size==3 && arrival.tier==0 && arrival.health==1)
        precondition(preview.incomingRocksLeft==0)
        precondition(preview.arrivalNoticeRemaining > 1.58 &&
                     preview.arrivalNoticeRemaining < 1.6)
        for _ in 0..<200 {
            _=preview.tick(dt:1/120,playerPosition:player,
                playerRadius:0,detectContacts:false)
        }
        precondition(preview.arrivalNoticeRemaining==0,
                     "Original Action38 notice should expire after 1.6s")

        // A bullet that is present at the rock's spawn point must hit
        // a rock arriving IN THE SAME FRAME. The old Swift ordering
        // wrongly processed bullets first and missed this source hit.
        var incoming=SphereSector556(balance:config,
            diagnosticAsteroids:[],diagnosticIncomingQuota:1)
        let origin=Sphere67.offset(arrival.position,
                                   by:Vec2(x:-35,y:0))
        incoming.fire(from:origin,direction:Vec2(x:1,y:0))
        precondition(incoming.bolts.count==1)
        _=incoming.tick(dt:1/120,playerPosition:player,
            playerRadius:0,detectContacts:false)
        precondition(incoming.incomingRocksLeft==0)
        precondition(incoming.destroyedRocks==1 &&
                     incoming.score==20,
                     "New Action38 asteroid must accept a same-frame shot")
        precondition(incoming.asteroids.count==2 &&
                     incoming.asteroids.allSatisfy { $0.size==2 })
        precondition(incoming.bolts.isEmpty)
        precondition(incoming.arrivalNoticeRemaining > 1.58)

        // StepSolids68 sees newly spawned rocks before the bullet phase.
        var ship=SphereSector556(balance:config,
            diagnosticAsteroids:[],diagnosticIncomingQuota:1)
        guard let collision=ship.tick(dt:1/120,playerPosition:player,
                playerRadius:1000,playerVelocity:Vec2(x:0,y:0),
                shipMass:2.4)
        else {fatalError("Missing ship contact response")}
        precondition(collision.contacts==1)
        precondition(ship.hull==2 && ship.damageEvents==1)

        // Windows Game.cs:238 removes a shard with life <=dt before
        // projectile checks. A projectile must NOT be intercepted by
        // an expired cosmetic fragment during that same frame.
        let dying=SphereAsteroid556(position:Vec2(x:640,y:360),
            velocity:Vec2(x:0,y:0),radius:25,size:1,tier:0,
            health:1,fragment:true,shardLife:0.001,mass:0.09)
        var shards=SphereSector556(balance:config,
            diagnosticAsteroids:[dying])
        shards.fire(from:Vec2(x:605,y:360),
                    direction:Vec2(x:1,y:0))
        _=shards.tick(dt:1/120,playerPosition:player,
            playerRadius:0,detectContacts:false)
        precondition(shards.destroyedRocks==0 && shards.score==0)
        precondition(shards.asteroids.isEmpty)
        precondition(shards.bolts.count==1,
                     "Expired shard must not absorb a source projectile")

        // Action38.StepAction checks the Clear cancellation BEFORE
        // bullets destroy rocks (Game.cs:240 before Game.cs:251-270).
        // The final rock destroyed during this frame must NOT erase the
        // quota already eligible for an incoming pair in this frame.
        let lastRock=SphereAsteroid556(position:Vec2(x:640,y:360),
            velocity:Vec2(x:0,y:0),radius:25,size:1,tier:0,
            health:1)
        var lastInFrame=SphereSector556(balance:config,
            diagnosticAsteroids:[lastRock],diagnosticIncomingQuota:3)
        lastInFrame.setVerifiedEnemyCount(0)
        lastInFrame.fire(from:Vec2(x:605,y:360),
                         direction:Vec2(x:1,y:0))
        _=lastInFrame.tick(dt:1/120,playerPosition:player,
            playerRadius:0,detectContacts:false)
        precondition(lastInFrame.destroyedRocks==1 &&
                     lastInFrame.score==100)
        precondition(lastInFrame.incomingRocksLeft==1,
                     "StepAction cannot retroactively cancel arrivals when a bullet destroys the last old rock")
        precondition(lastInFrame.asteroids.count==20,
                     "Two arrivals plus 18 terminal shards after last-rock hit")

        // Source Game.Action38 does not cancel the timed-wave quota
        // when its rock field happens to be empty.
        let waveConfig=CombatBalance556(level:9,difficulty:.normal,
                                         spherical:true)!
        var waves=SphereSector556(balance:waveConfig,
            diagnosticAsteroids:[],diagnosticIncomingQuota:3)
        waves.setVerifiedEnemyCount(0)
        _=waves.tick(dt:1/120,playerPosition:player,
            playerRadius:0,detectContacts:false)
        precondition(waves.incomingRocksLeft==3 &&
                     !waves.sectorFinished)
        for _ in 0..<1920 {
            _=waves.tick(dt:1/120,playerPosition:player,
                playerRadius:0,detectContacts:false)
        }
        precondition(waves.incomingRocksLeft==1)
        precondition(waves.objectiveWave==2)
        precondition(!waves.sectorFinished)
        print("PASS: source Game.Step 238/239/240/248/251 same-frame arrivals, solids, bullets, shard expiry, three timed waves")
    }
}
