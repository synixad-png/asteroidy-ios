import Foundation

/// A self-contained spherical combat *test sector* built from v556's rock
/// balance and Sphere67 geodesic motion. It does not unlock campaign missions,
/// simulate enemies/bosses, or replace the final planet mission controller.
struct SphereBolt556 {
    var position: Vec2
    var velocity: Vec2
    var life: Float
}

struct SphereShipContact556 {
    var position: Vec2
    var velocity: Vec2
    var contacts: Int
}

struct SphereSector556 {
    private(set) var asteroids: [SphereAsteroid556] = []
    private(set) var bolts: [SphereBolt556] = []
    private(set) var score = 0
    private(set) var destroyedRocks = 0
    private(set) var amigaHits = 0
    private(set) var shipContacts = 0
    private(set) var hull = 3
    private(set) var hitCooldown: Float = 0
    private(set) var damageEvents = 0
    private var inContact = false
    private(set) var elapsed: Float = 0
    private(set) var incomingRocksLeft = 0
    private(set) var nextIncoming: Float = 0
    // Action38.SpawnIncoming: NoticeTime=1.6 and a visible new-rock alert.
    private(set) var arrivalNoticeRemaining: Float = 0
    private(set) var objectiveWave = 1
    private(set) var sectorCleared = false
    let balance: CombatBalance556
    let cooperative: Bool
    let objective: GameCore.TrainingObjective
    var isAmigaDemo:Bool {balance.spherical && balance.level==25}
    private var shotCooldown: Float = 0
    private var seed: UInt32 = 0x556A57E
    private var verifiedEnemyCount: Int? = nil
    private static let unit: Float = 2.7 / 1280

    // Game.DangerSpeed; spherical Game.Wave and Action38 multiply by 0.55.
    static func dangerSpeed(_ difficulty:CombatBalance556.Difficulty) -> Float {
        switch difficulty {
        case .easy: return 0.86
        case .normal: return 1.10
        case .hard: return 1.32
        }
    }

    /// True only after the future mission controller explicitly verifies
    /// enemy and boss state; diagnostic sectorCleared never unlocks missions.
    struct MissionThreats {
        var enemyCount: Int
        var bossActive: Bool
        var requiredBossDefeated: Bool
        var verified: Bool
    }
    // The enemy controller will provide a verified value when it is ported.
    // nil means unknown and must never be interpreted as no enemies.
    mutating func setVerifiedEnemyCount(_ count:Int?) {
        verifiedEnemyCount = count.map { max(0,$0) }
    }

    func canFinishRealMission(_ threats:MissionThreats) -> Bool {
        sectorFinished && threats.verified && threats.enemyCount == 0 &&
        !threats.bossActive && threats.requiredBossDefeated && hull > 0
    }

    var objectiveDuration: Float {
        switch objective {
        case .clear: return 0
        case .escort: return 40
        case .defend: return 50
        case .waves: return 48
        }
    }
    // AmigaBounce265 / Gameplay65: level 25 is a perpetual showroom,
    // not a clearable timed mission. The "20 hits" is only a HUD milestone.
    var objectiveTimerComplete: Bool {
        !isAmigaDemo && elapsed >= objectiveDuration
    }
    var sectorFinished: Bool {
        !isAmigaDemo && objectiveTimerComplete &&
        incomingRocksLeft == 0 && asteroids.isEmpty
    }

    init(balance: CombatBalance556, diagnosticAsteroids: [SphereAsteroid556]? = nil,
         diagnosticIncomingQuota:Int? = nil,cooperative:Bool=false) {
        self.balance = balance
        self.cooperative = cooperative
        self.objective = GameCore.objectiveFor(level:balance.level)
        if let diagnosticAsteroids {
            asteroids = diagnosticAsteroids
            // Explicit fixtures represent a test with no scheduled arrivals.
            incomingRocksLeft = max(0,diagnosticIncomingQuota ?? 0)
            nextIncoming = objective == .waves ? 16 : 12
        } else {
            // Game.Wave() samples the ORIGINAL 1280x720 atlas and rejects
            // positions closer than 260 via WorldDelta67 (spherical geodesic).
            // Flat-rock coordinate rejection is not equivalent on a globe.
            let player = Vec2(x:640,y:360)
            for i in 0..<balance.sectorRockCount {
                let tier = balance.tier(at:i)!
                var position = Vec2(x:0,y:0)
                repeat {
                    position = Vec2(x:random()*1280,y:random()*720)
                } while Sphere67.delta(target:position,origin:player).lengthSquared < 260*260
                let heading = random()*2*Float.pi
                let initialSpeed = SphereAsteroid556.startingSpeed(
                    baseRandomSpeed:48+random()*30,
                    level:balance.level,tier:tier,
                    dangerSpeed:Self.dangerSpeed(balance.difficulty))
                let angle = random()*2*Float.pi
                let spin = (random()*2-1)*0.65
                let shapeSeed=Int(random()*Float(Int32.max))
                // Original Game.Wave calls PrepareRock70: large spherical
                // radius is scaled to 0.52 (0.41 for level 25), and HP
                // comes from Balance70, NOT the flat Rock constructor.
                let hp=balance.sphericalRockHealth(size:3,tier:tier,
                                                    cooperative:cooperative)
                var rock=SphereAsteroid556(position:position,
                    velocity:Vec2(x:cos(heading),y:sin(heading))*initialSpeed,
                    radius:balance.sphericalRockRadius(size:3),
                    size:3,tier:tier,health:hp,spin:spin,angle:angle,
                    originalHealth:Rock.healthFor(size:3,tier:tier),
                    shapeSeed:shapeSeed)
                if balance.level==25 { AmigaBounce265.prepare(&rock) }
                asteroids.append(rock)
            }
            var flat = GameCore()
            flat.setSectorTraining(balance)
            incomingRocksLeft = flat.incomingRocksLeft
            nextIncoming = objective == .waves ? 16 : 12
        }
        // Action38.ConfigureActionSector followed by Game.Wave:
        // original AmigaOnly266 explicitly disables reinforcements.
        if isAmigaDemo { incomingRocksLeft=0 }
    }
    private mutating func random() -> Float {
        seed = seed &* 1664525 &+ 1013904223
        return Float(seed & 0x00FFFFFF) / Float(0x01000000)
    }
    private mutating func spawnArrivals(near player:Vec2,stepDt:Float) {
        guard incomingRocksLeft > 0 else { return }
        let n = min(2,incomingRocksLeft)
        incomingRocksLeft -= n
        for i in 0..<n {
            let tier: Int
            if balance.level >= 13 { tier = 2 + Int(random() * 3) }
            else { tier = balance.level >= 10 ? 2 : balance.level >= 5 ? 1 : 0 }
            let side: Float = i % 2 == 0 ? 20 : 1260
            var candidate = Vec2(x:side,y:360)
            var attempts = 0
            repeat {
                candidate = Vec2(x:side,y:140 + random() * 520)
                attempts += 1
                if attempts > 20 {
                    let angle = random() * 2 * Float.pi
                    candidate = Sphere67.offset(player,by:Vec2(x:cos(angle),y:sin(angle))*340)
                    break
                }
            } while Sphere67.delta(target:candidate,origin:player).lengthSquared < 260*260
            let heading: Vec2
            if objective == .defend {
                let toTarget = Sphere67.delta(target:Vec2(x:640,y:420),origin:candidate)
                heading = toTarget * (1/max(0.0001,sqrt(toTarget.lengthSquared)))
            } else {
                let a = random() * 2 * Float.pi
                heading = Vec2(x:cos(a),y:sin(a))
            }
            let speed = SphereAsteroid556.incomingSpeed(
                baseRandomSpeed:60 + random()*40,
                dangerSpeed:Self.dangerSpeed(balance.difficulty))
            let radius: Float = Rock.radiusFor(size:3) / Self.unit
            let angle = random()*2*Float.pi
            let spin = (random()*2-1)*0.85
            _ = random() // original Rock.Shape random seed
            asteroids.append(SphereAsteroid556(position:candidate,velocity:heading*speed,
                                              radius:radius,size:3,tier:tier,
                                              spin:spin,angle:angle))
        }
        nextIncoming = elapsed + (objective == .waves ? 16 : 11)
        // Game.Step ticks NoticeTime immediately after StepAction.
        // Keep the source's 1.6 s HUD notification without inventing
        // a mission-complete or enemy event.
        arrivalNoticeRemaining=max(0,1.6-stepDt)
    }

    /// Physics68.SplitPhysical68: spherical fragments inherit parent motion
    /// plus a perpendicular +/-19 impulse, not the flat 0.75-radian split.
    private mutating func splitRock(_ parent:SphereAsteroid556) {
        guard parent.size > 1 else { return }
        let speed = sqrt(parent.velocity.lengthSquared)
        let side = speed > 0.00001
            ? Vec2(x:-parent.velocity.y/speed,y:parent.velocity.x/speed)
            : Vec2(x:0,y:0)
        let separation = (parent.size == 3 ? Float(18) : Float(10)) * 1.12 * 0.75 + 1
        for sign:Float in [-1,1] {
            let position = Sphere67.offset(parent.position,by:side*(sign*separation))
            let local = parent.velocity + side*(sign*19)
            let world = Sphere67.transport(Sphere67.vector(parent.position,local),
                                           from:Sphere67.normal(parent.position),
                                           to:Sphere67.normal(position))
            let transported = Sphere67.components(position,world)
            let size = parent.size - 1
            let tier = max(0,parent.tier - 1)
            let radius = (size == 2 ? Float(18) : Float(10)) * 1.12 *
                SphereAsteroid556.fragmentScale(parentSize:parent.size)
            asteroids.append(SphereAsteroid556(position:position,velocity:transported,
                                               radius:radius,size:size,tier:tier,fragment:true,
                                               mass:parent.mass*0.5,
                                               spin:parent.spin+sign*0.35,
                                               angle:parent.angle))
        }
    }
    private mutating func terminalShards(_ parent:SphereAsteroid556) {
        guard asteroids.count <= 220 else { return }
        for i in 0..<18 {
            let a = 2*Float.pi*Float(i)/18 + random()*0.2-0.1
            let dir = Vec2(x:cos(a),y:sin(a))
            let pos = Sphere67.offset(parent.position,by:dir*(2 + random()*5))
            let speed = 42 + random()*73
            let radius = 10*1.12*(0.10+random()*0.13)
            let life = 1.3+random()*1.2
            asteroids.append(SphereAsteroid556(position:pos,
                                              velocity:Sphere67.components(pos,
                                                  Sphere67.transport(
                                                    Sphere67.vector(parent.position,parent.velocity+dir*speed),
                                                    from:Sphere67.normal(parent.position),
                                                    to:Sphere67.normal(pos))),
                                              radius:radius,size:1,tier:0,
                                              health:1,fragment:true,shardLife:life,
                                              spin:(random()*2-1)*5,
                                              angle:parent.angle))
        }
    }

    /// Physics68.ImpactRock68: transfer 5.5% of bullet momentum to the
    /// impacted rock, including angular impulse around the hit lever.
    private mutating func impactRock(at index:Int, with bolt:SphereBolt556) {
        guard asteroids.indices.contains(index), asteroids[index].mass > 0 else { return }
        var rock = asteroids[index]
        let transported = Sphere67.components(rock.position,
            Sphere67.transport(Sphere67.vector(bolt.position,bolt.velocity),
                from:Sphere67.normal(bolt.position),
                to:Sphere67.normal(rock.position)))
        let impact = transported*0.055
        let r = Sphere67.delta(target:bolt.position,origin:rock.position)
        let distance = sqrt(r.lengthSquared)
        let lever = distance > rock.radius ? r*(rock.radius/distance) : r
        rock.velocity = rock.velocity+impact*(1/rock.mass)
        let moment = lever.x*impact.y-lever.y*impact.x
        rock.spin = max(-2.5, min(2.5,
            rock.spin + moment / max(0.0001, 0.4 * rock.mass * rock.radius * rock.radius)))
        asteroids[index] = rock
    }
    private mutating func damageRock(at index:Int,amount:Int=1) {
        guard asteroids.indices.contains(index) else { return }
        let rock=asteroids[index]
        let result=CombatDamage556.hitRock(
            health:rock.health,shardLife:rock.shardLife,amount:amount,
            size:rock.size,originalHealth:rock.originalHealth,tier:rock.tier)
        if result.removedShard { asteroids.remove(at:index); return }
        asteroids[index].health=result.health
        guard result.destroyed else { return }
        let destroyed=asteroids.remove(at:index)
        destroyedRocks += 1
        score += result.score
        if destroyed.size > 1 { splitRock(destroyed) }
        else { terminalShards(destroyed) }
    }



    /// Spherical aim is in the ship's own tangent plane; separate from flat
    /// arena controls. Shot radius and speed are explicit testbed values.
    mutating func fire(from player:Vec2, direction:Vec2) {
        guard shotCooldown <= 0 && direction.lengthSquared > 0.0001 && hull > 0 else { return }
        let d = direction * (1/sqrt(direction.lengthSquared))
        let start = Sphere67.offset(player,by:d*35)
        bolts.append(SphereBolt556(position:start,velocity:d*520,life:1.1))
        shotCooldown = 0.135
    }

    /// Moving geodesic collision: use the shortest arc at the beginning of
    /// the step and compare relative tangent velocities to avoid tunneling.
    /// The geometry is the Sphere67 local tangent approximation over <=1/60s.
    static func sweptBoltTime(start:Vec2,velocity:Vec2,rock:SphereAsteroid556,dt:Float) -> Float {
        let separation=Sphere67.delta(target:rock.position,origin:start)
        let transported=Sphere67.transport(Sphere67.vector(rock.position,rock.velocity),
                                            from:Sphere67.normal(rock.position),
                                            to:Sphere67.normal(start))
        let localRockVelocity=Sphere67.components(start,transported)
        let relative=(velocity-localRockVelocity)*dt
        // Same quadratic as source Physics68.SegmentHit68. Zero-time
        // overlap takes precedence over any later surface intersection.
        return CombatCollision556.segmentHit(delta:separation,travel:relative,
                                             radius:rock.radius+7)
    }
    static func sweptBoltHit(start:Vec2,velocity:Vec2,rock:SphereAsteroid556,dt:Float) -> Bool {
        sweptBoltTime(start:start,velocity:velocity,rock:rock,dt:dt) <= 1
    }

    /// Integration boundary for v556 Game.Damage respawn: keep the original
    /// projectile / asteroid arrays as one atomic replacement. Only the
    /// verified death controller should request this; ordinary sandbox
    /// contacts retain the old three-hit behavior unchanged.
    mutating func installRespawnWorld(rocks:[SphereAsteroid556],
                                     shots:[SphereBolt556]) {
        asteroids=rocks
        bolts=shots
        inContact=false
        shotCooldown=0
    }

    // Provide playerVelocity to opt into the real Physics68 Contact68
    // ship/rock impulse. Existing diagnostic position-only callers preserve
    // their original entry-only hull tests.
    @discardableResult
    mutating func tick(dt:Float,playerPosition:Vec2,playerRadius:Float=26,
                       detectContacts:Bool=true,playerVelocity:Vec2?=nil,
                       shipMass:Float=2.4,
                       useLegacyHull:Bool=true) -> SphereShipContact556? {
        guard dt > 0 else { return nil }
        elapsed += dt
        CombatHull556.advance(cooldown:&hitCooldown,dt:dt)
        shotCooldown = max(0,shotCooldown-dt)
        arrivalNoticeRemaining=max(0,arrivalNoticeRemaining-dt)
        // Windows Game.Step removes expired ShardLife187 BEFORE advancing
        // rocks, StepAction and projectile impacts. An expired shard must
        // never intercept a projectile in the same frame.
        for i in asteroids.indices.reversed() where asteroids[i].shardLife > 0 {
            asteroids[i].shardLife -= dt
            if asteroids[i].shardLife <= 0 { asteroids.remove(at:i) }
        }

        var previousRockPositions = asteroids.map { $0.position }
        for i in asteroids.indices { asteroids[i].advance(dt:dt) }

        // Windows Game.Step: rock advance -> Action38.StepAction ->
        // Physics68.StepSolids68 -> projectile hits. In particular, rocks
        // spawned THIS frame can already collide with the ship and bullets.
        // Previous Swift ordering added incoming rocks AFTER bullet hits.
        if objective == .waves { objectiveWave = min(3,1+Int(elapsed/16)) }
        // Only original verified Bugs.Count==0 cancels the Clear quota.
        // Nil means no enemy-controller evidence, not zero enemies.
        if objective == .clear && asteroids.isEmpty && verifiedEnemyCount == 0 {
            incomingRocksLeft = 0
        }
        if incomingRocksLeft > 0 &&
           (elapsed >= nextIncoming || (objective != .waves && asteroids.count <= 4)) {
            spawnArrivals(near:playerPosition,stepDt:dt)
        }
        // A newly spawned rock starts its sweep at its spawn point;
        // only pre-existing rocks have traveled during this step.
        if asteroids.count > previousRockPositions.count {
            previousRockPositions.append(contentsOf:
                asteroids[previousRockPositions.count...].map { $0.position })
        }
        // Physics68.StepSolids68: real rock/rock response in the spherical
        // tangent plane, with native 216-cell broadphase.
        _ = SphereRockContact68.solve(&asteroids)

        // Physics68.StepSolids68 resolves ship contacts BEFORE Game.Step
        // checks projectile impacts. Preserve the ship result until the
        // sector-clear flag has been evaluated after the projectile pass.
        let shipContact:SphereShipContact556?
        if detectContacts, let velocity=playerVelocity {
            var ship=SphereAsteroid556(position:playerPosition,velocity:velocity,
                                       radius:playerRadius,mass:shipMass)
            var contacts=0
            for i in asteroids.indices where asteroids[i].shardLife <= 0 {
                var rock=asteroids[i]
                if SphereRockContact68.resolve(&ship,&rock,
                                               restitution:0.42,
                                               applyRockSpin:false) {
                    asteroids[i]=rock
                    contacts += 1
                    if useLegacyHull &&
                        CombatHull556.applyContact(hull:&hull,cooldown:&hitCooldown) {
                        damageEvents += 1
                    }
                }
            }
            if contacts>0 && !inContact { shipContacts += 1 }
            inContact=contacts>0
            shipContact=SphereShipContact556(position:ship.position,
                                             velocity:ship.velocity,
                                             contacts:contacts)
        } else {
            let overlap = detectContacts && asteroids.contains {
                $0.shardLife <= 0 && $0.touches(playerPosition,otherRadius:playerRadius)
            }
            if overlap && !inContact {
                shipContacts += 1
                if useLegacyHull &&
                    CombatHull556.applyContact(hull:&hull,cooldown:&hitCooldown) {
                    damageEvents += 1
                }
            }
            inContact=overlap
            shipContact=nil
        }

        // Process projectiles against the positions at the start of the step.
        var rockHits:[Int:[SphereBolt556]] = [:]
        for i in bolts.indices.reversed() {
            if bolts[i].life <= 0 { bolts.remove(at:i); continue }
            var target:Int? = nil
            var first:Float = 2
            for j in asteroids.indices {
                var previous = asteroids[j]
                previous.position = previousRockPositions[j]
                let t=Self.sweptBoltTime(start:bolts[i].position,
                                         velocity:bolts[i].velocity,rock:previous,dt:dt)
                if CombatDamage556.prefer(candidateTime:t,candidateIndex:j,
                                           bestTime:first,bestIndex:target) {
                    first=t
                    target=j
                }
            }
            if let target {
                rockHits[target,default:[]].append(bolts[i])
                bolts.remove(at:i)
            } else {
                var moving = bolts[i]
                moving.position = Sphere67.advance(moving.position,velocity:&moving.velocity,dt:dt)
                moving.life -= dt
                if moving.life <= 0 { bolts.remove(at:i) }
                else { bolts[i] = moving }
            }
        }
        // Descending indices prevent removal from invalidating still-pending hits.
        for idx in rockHits.keys.sorted(by:>) {
            let incoming = rockHits[idx]!
            for bolt in incoming { impactRock(at:idx,with:bolt) }
            damageRock(at:idx,amount:incoming.count)
        }
        if sectorFinished { sectorCleared = true }
        return shipContact
    }
}
