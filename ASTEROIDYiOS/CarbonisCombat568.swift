import Foundation

/// Native CARBONIS level-one combat simulation. All movement takes place in
/// original 1280x720 spherical coordinates, independent of SwiftUI and Metal.
/// Matches Game.Step + DirectFlight67 + EnemyTactics71 for the first-sector
/// ordinary Pulse / shooter encounter. No boss, shop, multi-ship or later sectors.
struct CarbonisCombat568 {
    enum Phase: Equatable { case playing, victory, defeat }
    struct Projectile {
        var point: Vec2
        var velocity: Vec2
        var life: Float
        var hostile: Bool
    }
    struct Shooter {
        var core: MissionWave568.Fighter
        var velocity: Vec2 = Vec2(x:0,y:0)
        var aim: Float = 0
        var fireClock: Float
        var telegraph: Float = 0
        var gunAim: Float = 0
        var muzzle: Float = 0
        var phase: Float
        init(_ source:MissionWave568.Fighter) {
            core=source; fireClock=source.fireClock; phase=source.phase
        }
    }
    var phase: Phase = .playing
    var flight: SphereFlight67
    var rocks:[SphereAsteroid556]
    var shooters:[Shooter]
    var bullets:[Projectile] = []
    var hostileShots:[Projectile] = []
    var incoming:MissionIncoming568
    var elapsed:Float = 0
    var invincible:Float = 4.5
    var cooldown:Float = 0
    var hull:Int=60
    var armor:Int=25
    var lives:Int=3
    var score:Int=0
    var rocksDestroyed:Int=0
    var shooterKills:Int=0
    private var random:MissionWave568.SourceRandom
    private var completed=false
    private var sourceClearHold:Float=0
    private(set) var lastContactCount=0

    init(_ prepared:Sector01PreparedWave568) {
        var f=SphereFlight67()
        f.heading = -Float.pi/2
        f.flight.configuration.cruiseSpeed=156  // Campaign37 TopSpeed 390 * Physics68 0.4
        f.camera=SphereCamera67(at:f.position)
        flight=f
        rocks=prepared.encounter.rocks
        shooters=prepared.encounter.fighters.map{ Shooter($0) }
        incoming=prepared.incoming
        random=prepared.encounter.randomState
        lives=prepared.reset.lives
        invincible=prepared.reset.invincibleSeconds
    }
    static func unit(_ a:Vec2)->Vec2 {
        let n=sqrt(a.lengthSquared)
        return n > 0.00001 ? a*(1/n) : Vec2(x:1,y:0)
    }
    static func distance(_ a:Vec2,_ b:Vec2)->Float {
        sqrt(Sphere67.delta(target:a,origin:b).lengthSquared)
    }
    private static func hit(_ projectile:Projectile,_ target:Vec2,
                            radius:Float,dt:Float)->Bool {
        let delta=Sphere67.delta(target:target,origin:projectile.point)
        return CombatCollision556.segmentHit(delta:delta,
                  travel:projectile.velocity*dt,radius:radius) <= 1
    }
    mutating func suffer(_ damage:Int) {
        guard phase == .playing && invincible<=0 else{return}
        lastContactCount += 1
        let blocked=min(armor,damage)
        armor-=blocked
        hull-=damage-blocked
        invincible=0.8
        if hull>0 {return}
        lives-=1
        if lives<=0 {phase = .defeat; hull=0;return}
        hull=60;armor=25;invincible=3
        flight.position=Vec2(x:640,y:360)
        flight.velocity=Vec2(x:0,y:0)
        flight.camera=SphereCamera67(at:flight.position)
        bullets.removeAll(keepingCapacity:true)
        hostileShots.removeAll(keepingCapacity:true)
    }
    /// Pure simulation step, max 1/60s to retain collision fidelity.
    /// The authentic position of the first 13 rocks and four fighters is
    /// supplied by MissionWave568 rather than invented here.
    mutating func step(move:Vec2,aim:Vec2,shooting:Bool,dt requested:Float) {
        guard phase == .playing else{return}
        let dt=min(1/60,max(0,requested))
        guard dt>0 else{return}
        elapsed+=dt; cooldown=max(0,cooldown-dt)
        invincible=max(0,invincible-dt)
        flight.tick(move:move,aim:aim,dt:dt)
        // Source Game.Step: spherical rock WorldAdvance67 and spin.
        for i in rocks.indices {rocks[i].advance(dt:dt)}
        let additions=incoming.step(dt:dt,isPlaying:true,ship:flight.position,
             activeRocks:rocks.count,activeEnemies:shooters.count,
             objectivePosition:Vec2(x:640,y:420))
        rocks.append(contentsOf:additions)
        updateShooters(dt:dt)
        if shooting && cooldown<=0 {
            cooldown=0.16 // Game.ShotIntervalBase97 Pulse, rank 1
            let forward=Vec2(x:cos(flight.heading),y:sin(flight.heading))
            let nose=Sphere67.offset(flight.position,by:forward*20)
            let vel=Sphere67.components(nose,Sphere67.transport(
                Sphere67.vector(flight.position,forward*610+flight.velocity),
                from:Sphere67.normal(flight.position),to:Sphere67.normal(nose)))
            bullets.append(Projectile(point:nose,velocity:vel,life:1.1,hostile:false))
        }
        stepShots(dt:dt)
        // Original Physics68.ShipContacts68: always resolve physical
        // overlap, even during temporary post-hit invulnerability.
        resolveShipContacts()
        // MissionCleared69: objective Clear plus absence of rock and bug
        // threats and all reinforcements, not a timer-based fake win.
        let allThreatsCleared=rocks.filter({$0.shardLife<=0}).isEmpty &&
            shooters.isEmpty && incoming.incomingLeft==0 &&
            hostileShots.isEmpty
        if allThreatsCleared && !completed {
            // Game.cs:276: original spherical NextWave > .20s victory
            // staging; a transient empty rock list cannot instantly win.
            sourceClearHold+=dt
            if sourceClearHold>0.20 {
                completed=true;phase = .victory
            }
        } else {
            sourceClearHold=0
        }
    }

    /// Physics68.cs:62-65 ShipContacts68 with exact source body masses:
    /// Vanguard (type 1) 3.4; shooter mass 2; contact radii 11.2 and 16;
    /// restitution .42 for Rock, .35 for enemy. Damage96 level1 = 18.
    private mutating func resolveShipContacts() {
        guard phase == .playing else {return}
        for i in rocks.indices {
            var player=CarbonisBodyContact68.Body(
                position:flight.position,velocity:flight.velocity,
                mass:3.4,radius:11.2)
            var rock=CarbonisBodyContact68.Body(
                position:rocks[i].position,velocity:rocks[i].velocity,
                mass:rocks[i].mass,radius:rocks[i].radius)
            if CarbonisBodyContact68.resolve(&player,&rock,restitution:0.42) {
                flight.position=player.position
                flight.velocity=player.velocity
                rocks[i].position=rock.position
                rocks[i].velocity=rock.velocity
                suffer(18)
                if phase != .playing {return}
            }
        }
        for i in shooters.indices {
            var player=CarbonisBodyContact68.Body(
                position:flight.position,velocity:flight.velocity,
                mass:3.4,radius:11.2)
            var enemy=CarbonisBodyContact68.Body(
                position:shooters[i].core.position,
                velocity:shooters[i].velocity,mass:2,radius:16)
            if CarbonisBodyContact68.resolve(&player,&enemy,restitution:0.35) {
                flight.position=player.position
                flight.velocity=player.velocity
                shooters[i].core.position=enemy.position
                shooters[i].velocity=enemy.velocity
                suffer(18)
                if phase != .playing {return}
            }
        }
    }

    /// Physics68.SplitPhysical68: each large rock produces two physical
    /// spherical fragments with perpendicular 19-unit momentum and transport.
    private mutating func splitRock(_ parent:SphereAsteroid556) {
        guard parent.size>1,
              let balance=CombatBalance556(level:1,difficulty:.normal,
                                           spherical:true) else{return}
        let speed=sqrt(parent.velocity.lengthSquared)
        let sideways=speed>0.00001
            ? Vec2(x:-parent.velocity.y/speed,
                   y:parent.velocity.x/speed)
            : Vec2(x:0,y:0)
        let separation:Float=(parent.size==3 ? 18:10)*1.12*0.75+1
        for sign:Float in [-1,1] {
            let point=Sphere67.offset(parent.position,
                                      by:sideways*(sign*separation))
            let local=parent.velocity+sideways*(sign*19)
            let transported=Sphere67.components(point,
                Sphere67.transport(Sphere67.vector(parent.position,local),
                  from:Sphere67.normal(parent.position),
                  to:Sphere67.normal(point)))
            let nextSize=parent.size-1
            let tier=max(0,parent.tier-1)
            let hp=balance.sphericalRockHealth(size:nextSize,tier:tier)
            rocks.append(SphereAsteroid556(position:point,velocity:transported,
                radius:balance.sphericalRockRadius(
                    size:nextSize,parentSize:parent.size),
                size:nextSize,tier:tier,health:hp,fragment:true,
                mass:parent.mass*0.5,
                spin:parent.spin+sign*0.35,angle:parent.angle,
                originalHealth:Rock.healthFor(size:nextSize,tier:tier),
                shapeSeed:random.next()))
        }
    }

    /// EnemyTactics71.cs:32 Turn72, angularly capped to 6.5 rad/s.
    static func turn72(_ angle:Float,_ target:Float,
                       dt:Float,speed:Float=6.5)->Float {
        let delta=atan2(sin(target-angle),cos(target-angle))
        return angle + max(-speed*dt,min(speed*dt,delta))
    }

    private mutating func updateShooters(dt:Float) {
        let player=flight.position
        let dangerSpeed:Float=1.1
        let speed:Float=245
        for i in shooters.indices {
            var fighter=shooters[i]
            let delta=Sphere67.delta(target:player,origin:fighter.core.position)
            let dir=Self.unit(delta)
            let side=Vec2(x:-dir.y,y:dir.x)
            let distance=sqrt(delta.lengthSquared)
            // Level <=4: source source standoff ring at 158.
            let preferred:Float=158
            var radial:Float=0
            if distance>preferred+32 {
                radial=min(124,(distance-preferred-32)*1.4)
            } else if distance<preferred-25 {
                radial = -min(145,(preferred-25-distance)*2.5)
            }
            // Bug.Phase is a fixed spawn-time orbit direction: DO NOT
            // animate it. Original EnemyTactics71.cs:43-45 uses sin(Phase+.4).
            let orbitDirection:Float=sin(fighter.phase+0.4)>0 ? 1 : -1
            let flank:Float=(abs(distance-preferred)<90 ? 52 : 22) * orbitDirection
            let desired=(dir*radial+side*flank)*dangerSpeed
            let convergence:Float=1-exp(-dt*4.2)
            fighter.velocity=fighter.velocity+(desired-fighter.velocity)*convergence
            let old=fighter.core.position
            let oldAim=Sphere67.vector(old,Vec2(
                x:cos(fighter.aim),y:sin(fighter.aim)))
            fighter.core.position=Sphere67.advance(
                old,velocity:&fighter.velocity,dt:dt)
            let transported=Sphere67.components(
                fighter.core.position,Sphere67.transport(
                    oldAim,from:Sphere67.normal(old),
                    to:Sphere67.normal(fighter.core.position)))
            fighter.aim=atan2(transported.y,transported.x)

            // EnemyTactics71.cs:31 Predicted71, exact first-level 245
            // shooter speed, original 0.8-second max lead.
            let offset=Sphere67.delta(target:player,
                                      origin:fighter.core.position)
            let range=sqrt(offset.lengthSquared)
            let lead=min(Float(0.8),range/(speed*dangerSpeed))
            let future=Sphere67.offset(player,by:flight.velocity*lead)
            let prediction=Sphere67.delta(target:future,
                                          origin:fighter.core.position)
            let targetAngle=atan2(prediction.y,prediction.x)
            fighter.aim=Self.turn72(fighter.aim,targetAngle,dt:dt)
            fighter.muzzle=max(0,fighter.muzzle-dt)

            if range>200 {
                // Source out-of-range enemies cancel all warnings and cannot
                // carry an old firing countdown into range.
                fighter.fireClock=max(0.45,fighter.fireClock-dt)
                fighter.telegraph=0
                shooters[i]=fighter
                continue
            }
            fighter.fireClock-=dt
            let warning:Float=0.82
            if fighter.fireClock<=warning && fighter.telegraph<=0 {
                fighter.gunAim=targetAngle
                fighter.telegraph=warning
            }
            if fighter.telegraph>0 {
                fighter.telegraph=max(0.001,fighter.telegraph-dt)
            }
            if fighter.fireClock>0 {
                shooters[i]=fighter
                continue
            }
            // EnemyTactics71.cs:63-64: for type 0, shotAngle=Aim71,
            // so its alignment with the current aim is exactly zero.
            // The GunAim72 alignment gate only affects enemy kinds 1/4.
            // Level 1: single bullet per volley, 2.8 s recovery.
            if hostileShots.count<160 {
                let forward=Vec2(x:cos(fighter.aim),y:sin(fighter.aim))
                let start=Sphere67.offset(fighter.core.position,
                                         by:forward*18)
                let velocity=Sphere67.components(start,Sphere67.transport(
                    Sphere67.vector(fighter.core.position,
                                    forward*(speed*dangerSpeed)),
                    from:Sphere67.normal(fighter.core.position),
                    to:Sphere67.normal(start)))
                hostileShots.append(Projectile(
                    point:start,velocity:velocity,life:2.6,hostile:true))
            }
            fighter.muzzle=0.10
            fighter.telegraph=0
            fighter.fireClock=2.8
            shooters[i]=fighter
        }
    }

    /// Source Physics68.cs:77 ImpactRock68: Pulse transfers momentum and
    /// torque to the *actual* Rock state; it is not damage-only shooting.
    /// Level-one Pulse has one damage and one pierce, so transfer=1.
    static func impactRock68(_ rock:inout SphereAsteroid556,
                             shot:Projectile) {
        guard rock.mass>0 && rock.radius>0 else{return}
        let momentum=CarbonisBodyContact68.transported(
            shot.velocity,from:shot.point,to:rock.position)*0.055
        var lever=Sphere67.delta(target:shot.point,origin:rock.position)
        let length=sqrt(lever.lengthSquared)
        if length>rock.radius {
            lever=lever*(rock.radius/length)
        }
        rock.velocity=rock.velocity+momentum*(1/rock.mass)
        let angular=lever.x*momentum.y-lever.y*momentum.x
        let inertial=0.4*rock.mass*rock.radius*rock.radius
        rock.spin=max(-2.5,min(2.5,rock.spin+angular/inertial))
    }

    private mutating func stepShots(dt:Float) {
        for i in bullets.indices.reversed() {
            let shot=bullets[i]
            var impact=false
            for j in shooters.indices.reversed() {
                if Self.hit(shot,shooters[j].core.position,radius:15,dt:dt) {
                    shooters[j].core.hp-=1;impact=true
                    if shooters[j].core.hp<=0 {shooters.remove(at:j);shooterKills+=1;score+=2}
                    break
                }
            }
            if !impact {
                for j in rocks.indices.reversed() where rocks[j].shardLife<=0 {
                    if Self.hit(shot,rocks[j].position,radius:rocks[j].radius+2,dt:dt) {
                        Self.impactRock68(&rocks[j],shot:shot)
                        rocks[j].health-=1;impact=true
                        if rocks[j].health<=0 {
                            let removed=rocks.remove(at:j)
                            rocksDestroyed+=1;score+=1
                            splitRock(removed)
                        }
                        break
                    }
                }
            }
            if impact {bullets.remove(at:i);continue}
            var moved=shot
            moved.point=Sphere67.advance(shot.point,velocity:&moved.velocity,dt:dt)
            moved.life-=dt
            if moved.life<=0 {bullets.remove(at:i)}else{bullets[i]=moved}
        }
        for i in hostileShots.indices.reversed() {
            let shot=hostileShots[i]
            if Self.hit(shot,flight.position,radius:11.2+4.5,dt:dt) {
                hostileShots.remove(at:i);suffer(8);continue
            }
            var moved=shot
            moved.point=Sphere67.advance(shot.point,velocity:&moved.velocity,dt:dt)
            moved.life-=dt
            if moved.life<=0 {hostileShots.remove(at:i)}else{hostileShots[i]=moved}
        }
    }
}
