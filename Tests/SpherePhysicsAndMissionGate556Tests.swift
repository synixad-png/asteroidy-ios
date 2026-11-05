import Foundation

@main struct SpherePhysicsAndMissionGate556Tests {
    static func near(_ a:Float,_ b:Float,_ tolerance:Float=0.035) {
        precondition(abs(a-b)<=tolerance, "Expected \(b), got \(a)")
    }
    static func main() {
        let speed:[Float] = [
            SphereSector556.dangerSpeed(.easy),
            SphereSector556.dangerSpeed(.normal),
            SphereSector556.dangerSpeed(.hard)
        ]
        near(speed[0],0.86,0.0001)
        near(speed[1],1.10,0.0001)
        near(speed[2],1.32,0.0001)
        var checkedProfiles = 0
        for level in 1...26 {
          for (difficulty, factor) in zip(CombatBalance556.Difficulty.allCases,speed) {
            let config=CombatBalance556(level:level,difficulty:difficulty,spherical:true)!
            let sim=SphereSector556(balance:config)
            precondition(sim.asteroids.count == config.sectorRockCount)
            for (idx, rock) in sim.asteroids.enumerated() {
                precondition(rock.tier == config.tier(at:idx))
                let speed = sqrt(rock.velocity.lengthSquared)
                let slowdown:Float = rock.tier >= 2 ? 0.88 : 1
                let low = (48+Float(min(config.level-1,18))*3.2)*slowdown*0.55*factor
                let high = (78+Float(min(config.level-1,18))*3.2)*slowdown*0.55*factor
                precondition(speed >= low-0.01 && speed <= high+0.01)
                precondition(Sphere67.delta(target:rock.position,
                    origin:Vec2(x:640,y:360)).lengthSquared >= 260*260-0.1)
            }
            checkedProfiles += 1
          }
        }
        precondition(checkedProfiles == 78)
        let cfg=CombatBalance556(level:1,difficulty:.normal,spherical:true)!
        let parent=SphereAsteroid556(position:Vec2(x:1279,y:355),
                                    velocity:Vec2(x:80,y:0),
                                    radius:34.72,size:3,tier:3,health:7)
        var sim=SphereSector556(balance:cfg,diagnosticAsteroids:[parent])
        let from=Vec2(x:1239,y:355)
        for _ in 0..<7 {
            sim.tick(dt:0.20,playerPosition:from,playerRadius:0,detectContacts:false)
            sim.fire(from:from,direction:Vec2(x:1,y:0))
            sim.tick(dt:1/120,playerPosition:from,playerRadius:0,detectContacts:false)
        }
        // The parent moves during the repeated hits, so use a separate
        // stationary physical split fixture to verify exact geometry.
        let staticParent=SphereAsteroid556(position:Vec2(x:1279,y:355),
                                          velocity:Vec2(x:80,y:0),
                                          radius:34.72,size:3,tier:3,health:1)
        var physical=SphereSector556(balance:cfg,diagnosticAsteroids:[staticParent])
        physical.fire(from:Vec2(x:1244,y:355),direction:Vec2(x:1,y:0))
        physical.tick(dt:1/120,playerPosition:Vec2(x:1244,y:355),playerRadius:0,detectContacts:false)
        precondition(physical.destroyedRocks == 1 && physical.asteroids.count == 2)
        let a=physical.asteroids[0],b=physical.asteroids[1]
        precondition(a.size==2 && b.size==2 && a.tier==2 && b.tier==2)
        near(a.mass, staticParent.mass*0.5, 0.001)
        near(b.mass, staticParent.mass*0.5, 0.001)
        let sep:Float=18*1.12*0.75 + 1
        near(sqrt(Sphere67.delta(target:a.position,origin:staticParent.position).lengthSquared),sep,0.15)
        near(sqrt(Sphere67.delta(target:b.position,origin:staticParent.position).lengthSquared),sep,0.15)
        let aVel=Sphere67.components(staticParent.position,Sphere67.transport(
            Sphere67.vector(a.position,a.velocity),
            from:Sphere67.normal(a.position),to:Sphere67.normal(staticParent.position)))
        let bVel=Sphere67.components(staticParent.position,Sphere67.transport(
            Sphere67.vector(b.position,b.velocity),
            from:Sphere67.normal(b.position),to:Sphere67.normal(staticParent.position)))
        // ImpactRock68 transfers bullet momentum BEFORE SplitPhysical68.
        let forwardAfterBullet = 80 + 520 * 0.055 / staticParent.mass
        near(aVel.x,forwardAfterBullet,0.15)
        near(bVel.x,forwardAfterBullet,0.15)
        near(abs(aVel.y),19,0.15); near(abs(bVel.y),19,0.15)
        precondition(aVel.y*bVel.y < 0)
        near(a.radius,18*1.12*0.49,0.001)
        // Physics68 children inherit half mass, and opposite spin offsets.
        near(a.mass,staticParent.mass*0.5,0.001)
        near(b.mass,staticParent.mass*0.5,0.001)
        near(abs(a.spin-b.spin),0.7,0.005)
        // A nonterminal rock must receive real momentum and angular impulse
        // before its health is reduced, without affecting the legacy arena.
        var impact=SphereSector556(balance:cfg,diagnosticAsteroids:[
            SphereAsteroid556(position:Vec2(x:640,y:360),
                velocity:Vec2(x:0,y:0),radius:35,size:3,tier:1,health:3)
        ])
        impact.fire(from:Vec2(x:600,y:380),direction:Vec2(x:1,y:0))
        impact.tick(dt:1/120,playerPosition:Vec2(x:600,y:380),
                    playerRadius:0,detectContacts:false)
        precondition(impact.asteroids.count == 1)
        precondition(impact.asteroids[0].health == 2)
        precondition(impact.asteroids[0].velocity.lengthSquared > 1)
        precondition(abs(impact.asteroids[0].spin) > 0.005)

        let clean=SphereSector556(balance:cfg,diagnosticAsteroids:[])
        precondition(clean.sectorFinished)
        let allowed=SphereSector556.MissionThreats(enemyCount:0,bossActive:false,
                                                  requiredBossDefeated:true,verified:true)
        precondition(clean.canFinishRealMission(allowed))
        for threats in [
            SphereSector556.MissionThreats(enemyCount:1,bossActive:false,requiredBossDefeated:true,verified:true),
            SphereSector556.MissionThreats(enemyCount:0,bossActive:true,requiredBossDefeated:true,verified:true),
            SphereSector556.MissionThreats(enemyCount:0,bossActive:false,requiredBossDefeated:false,verified:true),
            SphereSector556.MissionThreats(enemyCount:0,bossActive:false,requiredBossDefeated:true,verified:false)
        ] {
            precondition(!clean.canFinishRealMission(threats))
        }
        print("PASS: 78 geodesic profiles, physical split, inherited child mass, tangent transport and mission gate")
    }
}
