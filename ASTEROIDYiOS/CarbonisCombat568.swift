import Foundation

/// Windows PC609 RobotSnake70.cs + EnemyTactics71.cs: real head, connected
/// armored rings and source pursuit/charge/fire on the 1280x720 sphere.
/// Not an independent sandbox: the owner is CarbonisCombat568.
struct SourceRobotSnake70 {
    struct Ring {
        let id:Int
        var position:Vec2
        var velocity=Vec2(x:0,y:0)
        var hp:Int
        let maxHP:Int
        var link:Float
        var hitFlash:Float=0
    }
    struct Shot {
        let point:Vec2
        let velocity:Vec2
    }
    let id:Int
    let initialRings:Int
    var position:Vec2
    var velocity=Vec2(x:0,y:0)
    var hp:Int
    let phase:Float
    var age:Float=0
    var aim:Float=0
    var fireClock:Float=2
    var telegraph:Float=0
    var gunAim:Float=0
    var burst=0
    var muzzle:Float=0
    var headFlash:Float=0
    var warning=false
    var charging=false
    var rings:[Ring]
    var trail:[Vec2]=[]
    // Windows Renderer.cs assigns MissionEnemyPercent=77 by default.
    // Recomputed from source ring topology at initial simulation entry.
    static let sizeScale:Float=0.77
    static let ringMass:Float=3.2
    static let headMass:Float=8
    static let ringContactRadius:Float=9*sizeScale
    static let headContactRadius:Float=16*sizeScale

    init(_ source:MissionWave568.Robot,id:Int) {
        self.id=id
        position=source.position
        hp=source.hp
        phase=source.phase
        initialRings=source.rings.count
        let first=source.rings.first.map {
            Sphere67.delta(target:$0.position,origin:source.position)
        } ?? Vec2(x:0,y:1)
        let tail=CarbonisCombat568.unit(first)
        rings=source.rings.enumerated().map { index,entry in
            let offset=Self.sizeScale*Float(26+index*18)
            return Ring(id:index+1,position:Sphere67.offset(source.position,
                by:tail*offset),hp:entry.hp,maxHP:entry.hp,
                link:Self.sizeScale*(index==0 ? 26:18))
        }
    }

    private static func distance(_ a:Vec2,_ b:Vec2)->Float {
        sqrt(Sphere67.delta(target:a,origin:b).lengthSquared)
    }
    /// RobotSnake70.ConstrainRobot70: a polyline of maximum 220 points.
    /// Ring separation is physically maintained across longitude/poles.
    mutating func constrain(dt:Float) {
        if !trail.isEmpty && Self.distance(position,trail[0])>100 {
            trail.removeAll(keepingCapacity:true)
        }
        if trail.isEmpty {
            trail.append(position)
            var last=position
            for ring in rings {
                let delta=Sphere67.delta(target:ring.position,origin:last)
                let steps=max(1,Int(ceil(sqrt(delta.lengthSquared)/2)))
                for i in 1...steps {
                    trail.append(Sphere67.offset(last,
                        by:delta*(Float(i)/Float(steps))))
                }
                last=ring.position
            }
        }
        let moved=Self.distance(position,trail[0])
        if moved>2 || (trail.count>1 &&
                        Self.distance(position,trail[1])>2) {
            trail.insert(position,at:0)
        } else {
            trail[0]=position
        }
        if trail.count>220 {trail.removeSubrange(220..<trail.count)}
        var parent=position
        var distance:Float=0,passed:Float=0
        var cursor=0
        for i in rings.indices {
            var ring=rings[i]
            ring.link=max(Self.sizeScale*(i==0 ? 26:18),
                          ring.link-100*dt)
            distance+=ring.link
            while cursor+1<trail.count {
                let length=Self.distance(trail[cursor+1],trail[cursor])
                if passed+length>=distance {break}
                passed+=length
                cursor+=1
            }
            var target=trail[cursor]
            if cursor+1<trail.count {
                let d=Sphere67.delta(target:trail[cursor+1],origin:target)
                let len=sqrt(d.lengthSquared)
                target=Sphere67.offset(target,by:d*min(1,
                    (distance-passed)/max(0.001,len)))
            }
            let gap=Sphere67.delta(target:target,origin:parent)
            let old=ring.position
            ring.position=Sphere67.offset(parent,
                by:CarbonisCombat568.unit(gap)*ring.link)
            ring.velocity=CarbonisBodyContact68.transported(
                ring.velocity,from:old,to:ring.position)*exp(-dt*7)
            rings[i]=ring
            parent=ring.position
        }
    }

    /// RobotSnake70.StepRobot70, then EnemyTactics71.StepEnemyFire71.
    /// Returned bolts join the SAME hostile-shot world and player damage.
    mutating func advance(dt:Float,target:Vec2,
                          playerVelocity:Vec2,
                          difficulty:CombatBalance556.Difficulty)->[Shot] {
        age+=dt
        headFlash=max(0,headFlash-dt)
        let cycle:Float=difficulty == .easy ? 8:6.5
        let chargePhase=(age+phase).truncatingRemainder(dividingBy:cycle)
        warning=chargePhase>cycle-1.5 && chargePhase<cycle-0.65
        charging=chargePhase>=cycle-0.65
        let delta=Sphere67.delta(target:target,origin:position)
        let dir=CarbonisCombat568.unit(delta)
        let side=Vec2(x:-dir.y,y:dir.x)
        let base:Float=difficulty == .easy ? 70 :
            difficulty == .hard ? 108:90
        let speed=warning ? base*0.55 :
            charging ? base*2.2 :
            base+min(15,Float(initialRings-rings.count)*1.6)
        let desired=dir*speed+
            side*(sin(age*1.7+phase)*(charging ? 0:18))
        velocity=velocity+(desired-velocity)*(1-exp(-dt*2.4))
        position=Sphere67.advance(position,velocity:&velocity,dt:dt)

        // EnemyTactics71.Predicted71 -> Turn72, robot type=0.
        let danger:Float=difficulty == .easy ? 0.86 :
            difficulty == .hard ? 1.32:1.10
        let distance=sqrt(Sphere67.delta(target:target,
                                          origin:position).lengthSquared)
        let future=Sphere67.offset(target,by:playerVelocity*
            min(Float(0.8),distance/(230*danger)))
        let predicted=Sphere67.delta(target:future,origin:position)
        let targetAngle=atan2(predicted.y,predicted.x)
        aim=CarbonisCombat568.turn72(aim,targetAngle,dt:dt)
        muzzle=max(0,muzzle-dt)
        var shots:[Shot]=[]
        if distance>160 {
            fireClock=max(0.45,fireClock-dt)
            telegraph=0
            burst=0
        } else {
            fireClock-=dt
            let warningTime:Float=0.28
            if fireClock<=warningTime && telegraph<=0 && burst==0 {
                gunAim=targetAngle
                telegraph=warningTime
            }
            if telegraph>0 {telegraph=max(0.001,telegraph-dt)}
            if fireClock<=0 {
                let alignment=abs(atan2(sin(aim-targetAngle),
                                        cos(aim-targetAngle)))
                if alignment<=0.25 {
                    // PC609 robots have exactly two bolts per volley.
                    if burst<3 {
                        for i in 0..<2 {
                            let a=aim+(Float(i)-0.5)*0.055
                            let d=Vec2(x:cos(a),y:sin(a))
                            let start=Sphere67.offset(position,by:d*18)
                            let original=Sphere67.vector(position,
                                d*(230*danger))
                            let tangent=Sphere67.components(start,
                                Sphere67.transport(original,
                                    from:Sphere67.normal(position),
                                    to:Sphere67.normal(start)))
                            shots.append(Shot(point:start,velocity:tangent))
                        }
                    }
                    muzzle=0.10
                    telegraph=0
                    burst+=1
                    let burstLength=difficulty == .easy ? 2:3
                    if burst<burstLength {
                        fireClock=0.19
                    } else {
                        burst=0
                        fireClock=1.3*(difficulty == .easy ? 1.3 :
                                        difficulty == .hard ? 0.90:1)
                    }
                }
            }
        }
        for i in rings.indices {
            rings[i].hitFlash=max(0,rings[i].hitFlash-dt)
            rings[i].velocity=rings[i].velocity*exp(-dt*0.8)
            rings[i].position=Sphere67.advance(rings[i].position,
                velocity:&rings[i].velocity,dt:dt)
        }
        constrain(dt:dt)
        return shots
    }
}

/// Native CARBONIS level-one combat simulation. All movement takes place in
/// original 1280x720 spherical coordinates, independent of SwiftUI and Metal.
/// Matches Game.Step + DirectFlight67 + EnemyTactics71 for CARBONIS 01.
/// It executes source Rail, Swarm and Guardian shots when the shared H11
/// profile equips them; sectors 02–25, bosses and their scenes are not ported.
struct CarbonisCombat568 {
    enum Phase: Equatable { case playing, victory, defeat }
    /// Source Game.Pickup Token with real spherical position and velocity.
    struct TokenPickup {
        var position:Vec2
        var velocity:Vec2
        var value:Int
        /// Nil = original token. PC586 Energy/Bomb use this SAME pickup list,
        /// motion, attraction and world contact path.
        var sourceKind:SourcePickupModels586.Kind? = nil
        var life:Float = 26
        var angle:Float = 0
    }
    struct Projectile {
        var point: Vec2
        var velocity: Vec2
        var life: Float
        var hostile: Bool
        // Original Game.Bullet.Kind and BossProjectile.Kind select visual
        // material and shot tint, not ballistic damage.
        var kind:Int = 0
        // Game.Fire Pulse rank1 deals one damage. Hostile shots override
        // this with ShooterShotDamage96 (eight damage on CARBONIS).
        var damage:Int = 1
        var pierce:Int = 1
        var hitRockSeeds:[Int] = []
        var hitShooterPhases:[Float] = []
        var hitRobotRings70:[Int] = []
        var hitRobotHeads70:[Int] = []
        // Game.cs Guardian298 plasma shares real player-bullet collisions.
        var guardian298:Bool = false
    }
    struct Shooter {
        /// Stable combat-entity identity for one-hit-per-boost ram tracking.
        var id:Int=0
        var core: MissionWave568.Fighter
        var velocity: Vec2 = Vec2(x:0,y:0)
        var aim: Float = 0
        var fireClock: Float
        var telegraph: Float = 0
        var gunAim: Float = 0
        var muzzle: Float = 0
        var burst:Int = 0
        var phase: Float
        init(_ source:MissionWave568.Fighter,id:Int=0) {
            self.id=id
            core=source; fireClock=source.fireClock; phase=source.phase
        }
    }
    var phase: Phase = .playing
    var flight: SphereFlight67
    var rocks:[SphereAsteroid556]
    var shooters:[Shooter]
    var bullets:[Projectile] = []
    var hostileShots:[Projectile] = []
    var tokenPickups:[TokenPickup] = []
    // Pure visual state ported from Game.Particles/Lights/Explosion524
    // and CombatPieces125. Independent from hitboxes and rewards.
    var destruction=CarbonisDestruction524()
    var incoming:MissionIncoming568
    var elapsed:Float = 0
    var invincible:Float = 4.5
    var cooldown:Float = 0
    var hull:Int=60
    var armor:Int=25
    // PC Talents78: these remain the source of truth for respawn/repair.
    var maxHull:Int=60,maxArmor:Int=25
    var lives:Int=3
    var shieldCharges:Int=0
    /// PC v609 StepArmorRegen78: one simulation clock for real mission armor.
    private var armorRegen609=ArmorRegeneration609()
    // Source PC580 BossTunnelGame.cs: IonAmmo and Bombs share ShopProfile56.
    var ionAmmo:Int=0
    var bombs:Int=0
    var bombCooldown:Float=0
    /// PC608 active energy bar and full-bar reserves form ONE shield system.
    /// Boost71 and ion ammo remain completely independent.
    var tarcza145=SourceTarcza145()
    var boost71=SourceBoost71()
    var shieldHeld=false
    private var legacyDrops586=SourceLegacyPickupDrops586(seed:0)
    let level:Int
    let objective:MissionWave568.Objective
    // PC609 RobotSnake70: real spherical head and linked body; the same
    // simulation state owns its AI, hits, pickups, collision and render poses.
    private(set) var robots:[SourceRobotSnake70]
    let difficulty:CombatBalance556.Difficulty
    let selectedWeapon:Sector01Shop568.Weapon
    let upgradeLevel:Int
    let rapidLevel:Int
    // PC580 Modules97/Talents78 independent of future ship GLB assets.
    let sourceMechanics:H55SourceMechanics580.State
    // Physics68 ShipMass68 / Campaign37.ContactRadius: same existing
    // authoritative source stats, captured once at mission start.
    let shipCollisionMass:Float
    let shipContactRadius:Float
    var guardianCharges:Int=0
    // Independent source drone: orbit, acquisition and plasma, not a fake HUD.
    var guardianDrone=CombatGuardianDrone298()
    var score:Int=0
    var collectedLootTokens:Int=0
    // PC v600 HudMotionSample reads monotonic Game.Shots/Hits/PickupEvents.
    // This is read-only telemetry: increments never affect physics, RNG,
    // collision eligibility, player resources, or audio dispatch.
    struct HUDEvents {
        fileprivate(set) var shots:Int=0
        fileprivate(set) var hits:Int=0
        fileprivate(set) var pickups:Int=0
    }
    private(set) var hudEvents=HUDEvents()
    // Source Game.Tokens: mission HUD begins with real persisted wallet.
    let startingTokens:Int
    private var lootCarry:Float=0
    private let lootYieldScale:Float
    private let isReplay:Bool
    private(set) var missionSummary:Sector01MissionSummary568?
    var rocksDestroyed:Int=0
    var shooterKills:Int=0
    private var random:MissionWave568.SourceRandom
    private var combatSupply586=SourceCombatSupply586(missionSeed:0)
    private var completed=false
    // Audio events mirror original Game.ShotEvents, BlastEvents,
    // PickupEvents and EnemyShotSound79. Pure side channel only.
    private var originalAudioEvents568:[Int]=[]
    mutating func drainOriginalAudioEvents568()->[Int] {
        let result=originalAudioEvents568
        originalAudioEvents568.removeAll(keepingCapacity:true)
        return result
    }
    private mutating func emitOriginalAudio568(_ id:Int) {
        // PC Game.PickupEvents is emitted at the same authoritative
        // successful pickup branch as original audio event 30.
        if id==30 {hudEvents.pickups += 1}
        if originalAudioEvents568.count<64 {originalAudioEvents568.append(id)}
    }
    private var sourceClearHold:Float=0
    private(set) var lastContactCount=0

    init(_ prepared:Sector01PreparedWave568) {
        level=prepared.reset.level
        objective=prepared.encounter.objective
        robots=prepared.encounter.robots.enumerated().map {
            SourceRobotSnake70($0.element,id:$0.offset+1)
        }
        var f=SphereFlight67()
        f.heading = -Float.pi/2
        // H11: compute original Campaign37 source bonuses in ONE place.
        // The existing FlightDynamics556 normalized response remains the
        // iOS motion solver; control scales by PC acceleration ratio.
        let upgrades=H55SourceMechanics580.load()
        Self.applySourceShipStats(&f,source:upgrades)
        f.camera=SphereCamera67(at:f.position)
        flight=f
        rocks=prepared.encounter.rocks
        shooters=prepared.encounter.fighters.enumerated().map {
            Shooter($0.element,id:$0.offset+1)
        }
        incoming=prepared.incoming
        random=prepared.encounter.randomState
        combatSupply586=SourceCombatSupply586(missionSeed:prepared.combatSupplySeed)
        legacyDrops586=SourceLegacyPickupDrops586(seed:prepared.combatSupplySeed)
        lootYieldScale=prepared.encounter.lootYieldScale
        isReplay=prepared.isReplay
        lives=prepared.reset.lives
        invincible=prepared.reset.invincibleSeconds
        difficulty=prepared.difficulty
        let profile=prepared.shopProfile
        sourceMechanics=upgrades
        let originalShipStats=H55SourceMechanics580.shipStats(
            type:upgrades.selectedShip,engine:upgrades.engine,
            stabilizer:upgrades.stabilizer,thruster:upgrades.thruster)
        shipCollisionMass=originalShipStats?.mass ?? 3.4
        shipContactRadius=originalShipStats?.contactRadius ?? 11.2
        guardianCharges=upgrades.guardianOwned ? 1 : 0
        startingTokens=profile.tokens
        selectedWeapon=profile.weapon
        upgradeLevel=profile.upgradeLevel
        rapidLevel=profile.rapidLevel
        shieldCharges=profile.shieldCharges
        tarcza145.energy=SourceTarcza145.loadPersistentEnergy()
        ionAmmo=profile.ionAmmo
        bombs=profile.bombs
        // H11 reads the same actual saved hull/armor repaired in H55.
        // No parallel visual-only values: these fields drive suffer(),
        // respawn and the real mission HUD.
        let saved=H55Workshop580.loadVitals()
        hull=saved.hull>0 ? saved.hull : saved.maxHull
        armor=saved.armor
        maxHull=saved.maxHull
        maxArmor=saved.maxArmor
    }
    /// No parallel ship physics implementation: exact source multipliers
    /// come from Campaign37 in H55SourceMechanics580.shipStats().
    /// The current verified iOS mesh is VANGUARD; other GLBs will register
    /// against their stable source IDs without changing these formulas.
    private static func applySourceShipStats(
        _ flight:inout SphereFlight67,
        source:H55SourceMechanics580.State) {
        guard let stats=H55SourceMechanics580.shipStats(
            type:source.selectedShip,engine:source.engine,
            stabilizer:source.stabilizer,thruster:source.thruster) else {return}
        flight.flight.configuration.cruiseSpeed=stats.topSpeed * 0.40
        flight.flight.configuration.control=stats.acceleration/245
        flight.flight.configuration.stabilizerLevel=Float(source.stabilizer)
        flight.flight.configuration.visualTurnRate=6.2*(stats.turnSpeed/3.8)
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
    // Preserve the frozen first-sector damage API for all contact callers.
    mutating func suffer(_ damage:Int) {
        suffer(damage,hostileProjectile:false)
    }
    private mutating func suffer(_ damage:Int,hostileProjectile:Bool) {
        guard phase == .playing && invincible<=0 else{return}
        lastContactCount += 1
        // Source Game.Damage(): guardian intercept is BEFORE tarcza/shield.
        if guardianCharges>0 {
            guardianCharges-=1
            invincible=1.2
            return
        }
        // PC v608: only an actively held dome can absorb this hit.
        // The ONLY reserve consumption occurs in SourceTarcza145 on
        // depletion of its current energy bar, never on a passive hit.
        if tarcza145.absorb(invincible:&invincible,
                            reserve:&shieldCharges) {return}
        // Modules97.DampenerRank97 only applies to hostile projectile,
        // never asteroid/body contacts. Preserve source minimum damage 1.
        let received=hostileProjectile
            ? H55SourceMechanics580.hostileShotDamage(
                damage,dampener:sourceMechanics.dampener)
            : damage
        let wasFull=armor>=maxArmor
        let blocked=min(armor,received)
        armor-=blocked
        armorRegen609.tookDamage(wasFull:wasFull,now:armor,maximum:maxArmor)
        hull-=received-blocked
        invincible=0.8
        if hull>0 {return}
        // Original Windows/src/Game.cs:190 Game.Damage: fatal hull loss
        // increments BlastEvents and sets BlastSound>=1. CombatSound.Blast(1)
        // is source SFX 21, both for respawn and final GameOver.
        emitOriginalAudio568(21)
        lives-=1
        shieldCharges=0
        if lives<=0 {phase = .defeat; hull=0;return}
        hull=maxHull;armor=maxArmor;invincible=4.5
        armorRegen609.reset()
        // Game.Damage: respawn keeps the original Vanguard and restores
        // its heading, movement damping, bank and aiming state.
        flight.position=Vec2(x:640,y:360)
        flight.velocity=Vec2(x:0,y:0)
        flight.heading = -Float.pi/2
        flight.flight=FlightDynamics556()
        Self.applySourceShipStats(&flight,source:sourceMechanics)
        flight.camera=SphereCamera67(at:flight.position)
        bullets.removeAll(keepingCapacity:true)
        // Original Game.Damage relocates every rock within 160 atlas
        // units to 220 units from spawn to prevent unavoidable spawn death.
        for i in rocks.indices {
            if Self.distance(rocks[i].position,flight.position)<160 {
                let angle=random.float(0,Float.pi*2)
                let dir=Vec2(x:cos(angle),y:sin(angle))
                let oldSpeed=sqrt(rocks[i].velocity.lengthSquared)
                let point=Sphere67.offset(flight.position,by:dir*220)
                rocks[i].position=point
                rocks[i].velocity=CarbonisBodyContact68.transported(
                    dir*oldSpeed,from:flight.position,to:point)
            }
        }
    }
    /// Pure simulation step, max 1/60s to retain collision fidelity.
    /// The authentic position of the first 13 rocks and four fighters is
    /// supplied by MissionWave568 rather than invented here.
    mutating func setShieldHeld(_ held:Bool) {
        shieldHeld=held && phase == .playing
        if !shieldHeld {tarcza145.active=false}
    }
    @discardableResult mutating func activateBoost71()->Bool {
        boost71.activate(playing:phase == .playing)
    }

    mutating func step(move:Vec2,aim:Vec2,shooting:Bool,dt requested:Float) {
        guard phase == .playing else{return}
        let dt=min(1/60,max(0,requested))
        guard dt>0 else{return}
        elapsed+=dt; cooldown=max(0,cooldown-dt)
        bombCooldown=max(0,bombCooldown-dt)
        destruction.tick(dt:dt)
        invincible=max(0,invincible-dt)
        armorRegen609.advance(dt:dt,armor:&armor,maximum:maxArmor,
                              playing:true,shipDown:false)
        tarcza145.step(dt:dt,held:shieldHeld,playing:true,
                       reserve:&shieldCharges)
        let boosting=boost71.advance(dt:dt)
        if boosting {invincible=max(invincible,0.15)}
        let previousShip=flight.position
        flight.tick(move:move,aim:aim,dt:dt,
                    boostMultiplier:boosting ? 2.6 : nil)
        stepTokenPickups(dt:dt)
        // Game.cs:240 — terminal debris expires BEFORE advancing rocks.
        for i in rocks.indices.reversed() {
            if rocks[i].shardLife>0 {
                rocks[i].shardLife-=dt
                if rocks[i].shardLife<=0 {rocks.remove(at:i)}
            }
        }
        // Source Game.Step: spherical rock WorldAdvance67 and spin.
        for i in rocks.indices {rocks[i].advance(dt:dt)}
        let additions=incoming.step(dt:dt,isPlaying:true,ship:flight.position,
             activeRocks:rocks.count,activeEnemies:shooters.count,
             objectivePosition:Vec2(x:640,y:420))
        rocks.append(contentsOf:additions)
        updateShooters(dt:dt)
        updateRobots70(dt:dt)
        if boosting {applyBoostRam71(from:previousShip)}
        // Game.Step: StepBugs -> StepGuardian298 before solids/player Fire.
        // Damage-bearing Guardian plasma enters the SAME swept-hit pipeline.
        if let plasma=guardianDrone.step(
            dt:dt,elapsed:elapsed,ship:flight.position,
            shipVelocity:flight.velocity,shooters:shooters,rocks:rocks,
            owned:sourceMechanics.guardianOwned,
            strike:sourceMechanics.guardianStrike,
            focus:sourceMechanics.guardianFocus,
            projectileCount:bullets.count) {
            bullets.append(Projectile(
                point:plasma.position,velocity:plasma.velocity,
                life:plasma.life,hostile:false,kind:2,
                damage:plasma.damage,pierce:1,guardian298:true))
        }
        // Original Physics68.StepSolids68 order: all solid contacts
        // BEFORE the player's new bullets are fired.
        resolveWorldContacts()
        resolveShipContacts()
        resolveRobotContacts70(dt:dt)
        if phase != .playing {return}
        if shooting && cooldown<=0 && bullets.count<=140 {
            fireSourceWeapon()
        }
        stepShots(dt:dt)
        // MissionCleared69: objective Clear plus absence of rock and bug
        // threats and all reinforcements, not a timer-based fake win.
        // Game.Step checks objective, rocks and Bugs; hostile shots
        // do NOT delay clear. FinishLevel guards remaining reinforcements.
        // Gameplay65/Objective: BOREAS 05 defends for 50 s; a preview
        // or an empty frame is never enough to win. RobotSnake actors
        // remain pending until their real source runtime defeats them.
        let requiredTime:Float
        switch objective {
        case .clear: requiredTime=0
        case .escort: requiredTime=40
        case .defend: requiredTime=50
        case .waves: requiredTime=48
        }
        let allThreatsCleared=rocks.isEmpty &&
            shooters.isEmpty && robots.isEmpty &&
            incoming.incomingLeft==0 && elapsed>=requiredTime
        if allThreatsCleared && !completed {
            // Game.cs:276: original spherical NextWave > .20s victory
            // staging; a transient empty rock list cannot instantly win.
            sourceClearHold+=dt
            if sourceClearHold>0.20 {
                completed=true
                finishSourceMission()
            }
        } else {
            sourceClearHold=0
        }
    }

    /// Source Game.DropLoot: small/large asteroids generate token
    /// pickups; medium rocks never do. Classic fractional carry is
    /// accumulated deterministically (not randomly awarded).
    private mutating func dropSourceRockLoot(_ rock:SphereAsteroid556) {
        guard !isReplay && rock.shardLife<=0 && rock.size != 2 else{return}
        lootCarry += Float((rock.size==3 ? 1 : 2)+rock.tier)*lootYieldScale
        let value=Int(lootCarry)
        lootCarry-=Float(value)
        guard value>0 else{return}
        if tokenPickups.count>=96 {
            // Source money cannot be merged into an Energy or Bomb item:
            // the unified collection may now contain both kinds.
            if let index=tokenPickups.firstIndex(where:{$0.sourceKind == nil}) {
                tokenPickups[index].value+=value
            } else {
                collectedLootTokens+=value
            }
            return
        }
        let a=random.float(0,Float.pi*2)
        tokenPickups.append(TokenPickup(
            position:rock.position,
            velocity:Vec2(x:cos(a)*15,y:sin(a)*15),
            value:value))
    }

    /// The original PC MovePickup68 applies to coins AND consumables.
    /// One shared physics/attraction/contact path, no second loot pool.
    private mutating func stepTokenPickups(dt:Float) {
        for i in tokenPickups.indices.reversed() {
            var item=tokenPickups[i]
            if item.sourceKind != nil {
                // Original PC Game.Step advances pickup model orientation.
                item.angle+=dt*0.8
            }
            if item.sourceKind != nil {
                item.life-=dt
                if item.life<=0 {
                    tokenPickups.remove(at:i)
                    continue
                }
            }
            let delta=Sphere67.delta(target:flight.position,
                                     origin:item.position)
            let distance=sqrt(delta.lengthSquared)
            if distance<26 {
                if let kind=item.sourceKind {
                    if kind == .shield {
                        let collected=tarcza145.collectCell(
                            reserve:&shieldCharges)
                        if collected {emitOriginalAudio568(30)}
                        tokenPickups.remove(at:i)
                        continue
                    }
                    if kind == .boost {
                        boost71.collect()
                        emitOriginalAudio568(30)
                        tokenPickups.remove(at:i)
                        continue
                    }
                    // PC Game.Step removes an item on contact even when
                    // the magazine filled after its original drop.
                    // In that case CollectCombatSupply returns false
                    // and emits no PickupEvents / sound.
                    let collected=SourceCombatSupply586.collected(
                        kind,ionAmmo:&ionAmmo,bombs:&bombs)
                    if collected {emitOriginalAudio568(30)}
                    tokenPickups.remove(at:i)
                    continue
                } else if !isReplay {
                    collectedLootTokens+=item.value
                }
                emitOriginalAudio568(30) // original PickupEvents
                tokenPickups.remove(at:i)
                continue
            }
            let attractionRadius=H55SourceMechanics580.collectorRadius(
                rank:sourceMechanics.collector)
            if distance<attractionRadius && distance>0.1 {
                let sourceAcceleration=H55SourceMechanics580.collectorSpeed(
                    rank:sourceMechanics.collector,spherical:true)
                let attraction=delta*(dt*sourceAcceleration/max(distance,0.1))
                item.velocity=item.velocity+attraction
            }
            let drag:Float=distance<attractionRadius ? 1.4 : 0.18
            item.velocity=item.velocity*exp(-dt*drag)
            let speed=sqrt(item.velocity.lengthSquared)
            let cap=H55SourceMechanics580.collectorSpeedCap(
                rank:sourceMechanics.collector)
            if speed>cap {item.velocity=item.velocity*(cap/speed)}
            item.position=Sphere67.advance(
                item.position,velocity:&item.velocity,dt:dt)
            // Physics68.MovePickup68: token mass .15, radius 6, genuine
            // physical contact against all nearby source asteroids.
            for j in rocks.indices {
                var pickup=CarbonisBodyContact68.Body(
                    position:item.position,velocity:item.velocity,
                    mass:0.15,radius:6)
                var stone=CarbonisBodyContact68.Body(
                    position:rocks[j].position,velocity:rocks[j].velocity,
                    mass:rocks[j].mass,radius:rocks[j].radius)
                if CarbonisBodyContact68.resolve(
                    &pickup,&stone,restitution:0.25) {
                    item.position=pickup.position
                    item.velocity=pickup.velocity
                    rocks[j].position=stone.position
                    rocks[j].velocity=stone.velocity
                }
            }
            tokenPickups[i]=item
        }
    }

    /// Game.FinishLevel: first valid clear records the mission once,
    /// collects ALL remaining tokens, and grants 10+level*2=12.
    /// The owning GameView alone is allowed to save campaign progress.
    private mutating func finishSourceMission() {
        guard phase == .playing && missionSummary==nil else{return}
        if !isReplay {
            collectedLootTokens+=tokenPickups.reduce(0) {
                $0+($1.sourceKind == nil ? $1.value : 0)
            }
        }
        // Only tokens become money; uncollected Energy/Bomb expire with
        // the battle instead of being silently turned into currency.
        tokenPickups.removeAll(keepingCapacity:true)
        bullets.removeAll(keepingCapacity:true)
        missionSummary=Sector01MissionSummary568.completedSourceMission(
            sector:level,rocks:rocksDestroyed,enemies:shooterKills,score:score,
            lootTokens:collectedLootTokens,replay:isReplay,
            elapsed:elapsed)
        phase = .victory
    }

    /// Physics68.StepSolids68: rock/rock broadphase, every shooter/rock
    /// and shooter/shooter contact. This is separate from ship hit damage.
    private mutating func resolveWorldContacts() {
        _=SphereRockContact68.solve(&rocks)
        for i in shooters.indices {
            for j in rocks.indices {
                var enemy=CarbonisBodyContact68.Body(
                    position:shooters[i].core.position,
                    velocity:shooters[i].velocity,mass:2,radius:16)
                var stone=CarbonisBodyContact68.Body(
                    position:rocks[j].position,velocity:rocks[j].velocity,
                    mass:rocks[j].mass,radius:rocks[j].radius)
                if CarbonisBodyContact68.resolve(
                    &enemy,&stone,restitution:0.45) {
                    shooters[i].core.position=enemy.position
                    shooters[i].velocity=enemy.velocity
                    rocks[j].position=stone.position
                    rocks[j].velocity=stone.velocity
                }
            }
        }
        if shooters.count>=2 {
            for i in 0..<(shooters.count-1) {
                for j in (i+1)..<shooters.count {
                    var a=CarbonisBodyContact68.Body(
                        position:shooters[i].core.position,
                        velocity:shooters[i].velocity,mass:2,radius:16)
                    var b=CarbonisBodyContact68.Body(
                        position:shooters[j].core.position,
                        velocity:shooters[j].velocity,mass:2,radius:16)
                    if CarbonisBodyContact68.resolve(
                        &a,&b,restitution:0.30) {
                        shooters[i].core.position=a.position
                        shooters[i].velocity=a.velocity
                        shooters[j].core.position=b.position
                        shooters[j].velocity=b.velocity
                    }
                }
            }
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
                mass:shipCollisionMass,radius:shipContactRadius)
            var rock=CarbonisBodyContact68.Body(
                position:rocks[i].position,velocity:rocks[i].velocity,
                mass:rocks[i].mass,radius:rocks[i].radius)
            if CarbonisBodyContact68.resolve(&player,&rock,restitution:0.42) {
                flight.position=player.position
                flight.velocity=player.velocity
                rocks[i].position=rock.position
                rocks[i].velocity=rock.velocity
                // v608: no passive 3/3 shield collision branch.
                // Normal physical contact still resolves; suffer()
                // checks the active Tarcza145 and real armor/hull.
                suffer(level<=2 ? 18 : level<=4 ? 22 : level<=8 ? 26 : 32)
                if phase != .playing {return}
            }
        }
        for i in shooters.indices {
            var player=CarbonisBodyContact68.Body(
                position:flight.position,velocity:flight.velocity,
                mass:shipCollisionMass,radius:shipContactRadius)
            var enemy=CarbonisBodyContact68.Body(
                position:shooters[i].core.position,
                velocity:shooters[i].velocity,mass:2,radius:16)
            if CarbonisBodyContact68.resolve(&player,&enemy,restitution:0.35) {
                flight.position=player.position
                flight.velocity=player.velocity
                shooters[i].core.position=enemy.position
                shooters[i].velocity=enemy.velocity
                suffer(level<=2 ? 18 : level<=4 ? 22 : level<=8 ? 26 : 32)
                if phase != .playing {return}
            }
        }
    }

    /// One canonical destruction/reward path for both PC bullet hits
    /// and the source-wide bomb wave; avoids duplicate scoring or loot.
    private mutating func destroyRock(at index:Int) {
        let removed=rocks.remove(at:index)
        emitOriginalAudio568(removed.size>=3 ? 21 : 20)
        destruction.rockDestroyed(removed,time:elapsed,rng:&random)
        rocksDestroyed+=1
        score+=Self.sourceRockScore(removed)
        dropSourceRockLoot(removed)
        tryDropLegacyPickup586(at:removed.position,
                               enemy:false,rockSize:removed.size)
        tryDropCombatSupply586(at:removed.position,
                               enemy:false,asteroidSize:removed.size)
        splitRock(removed)
    }

    private mutating func defeatShooter(at index:Int) {
        let destroyed=shooters.remove(at:index)
        emitOriginalAudio568(20)
        shooterKills+=1
        score+=destroyed.core.hunter ? 300 : 180
        // Original BossTunnelGame.HitBug: reward remains a real pickup.
        if !isReplay {
            let amount=2+destroyed.core.type/2
            if tokenPickups.count<96 {
                let a=Float(5)*1.37
                let velocity=Vec2(x:cos(a)*18,y:sin(a)*18)
                tokenPickups.append(TokenPickup(
                    position:destroyed.core.position,
                    velocity:velocity,value:amount))
            } else {
                collectedLootTokens+=amount
            }
        }
        tryDropLegacyPickup586(at:destroyed.core.position,
                               enemy:true,rockSize:0)
        tryDropCombatSupply586(at:destroyed.core.position,enemy:true)
    }

    /// PC602 Tarcza145.TryDropTarcza145 and Boost71.DropBoost71
    /// depend on LootEnabled and pickup-cap, NOT MissionRewards57.
    /// Replays continue to drop usable items; only tokens are suppressed.
    /// One canonical pickup array; RNG stays independent of combat.
    private mutating func tryDropLegacyPickup586(
        at point:Vec2,enemy:Bool,rockSize:Int) {
        let eligible=phase == .playing
        if let item=legacyDrops586.shield(
            enemy:enemy,rockSize:rockSize,eligible:eligible,
            pickups:tokenPickups.count) {
            tokenPickups.append(TokenPickup(
                position:point,velocity:item.velocity,value:0,
                sourceKind:item.kind,life:item.life))
        }
        guard !enemy else{return}
        if let item=legacyDrops586.boost(
            eligible:eligible,pickups:tokenPickups.count) {
            tokenPickups.append(TokenPickup(
                position:point,velocity:item.velocity,value:1,
                sourceKind:item.kind,life:item.life))
        }
    }

    /// PC Boost71.cs: active 0.9 s dash rams each actor at most once.
    /// Uses existing rock/shooter health, death, debris, score and rewards.
    private mutating func applyBoostRam71(from previous:Vec2) {
        let travel=Sphere67.delta(target:flight.position,origin:previous)
        guard travel.lengthSquared>0.000001 else{return}
        for i in rocks.indices.reversed() where rocks[i].shardLife<=0 {
            let rock=rocks[i]
            let delta=Sphere67.delta(target:rock.position,origin:previous)
            let t=CombatCollision556.segmentHit(
                delta:delta,travel:travel,radius:rock.radius+shipContactRadius)
            guard t<=1,boost71.firstRockContact(rock.shapeSeed) else{continue}
            rocks[i].health-=8
            let shove=CarbonisBodyContact68.transported(
                Self.unit(travel)*55,from:previous,to:rock.position)
            rocks[i].velocity=rocks[i].velocity+shove
            if rocks[i].health<=0 {
                destroyRock(at:i)
            } else {
                destruction.rockHit(rocks[i],rng:&random)
            }
        }
        for i in shooters.indices.reversed() {
            let fighter=shooters[i]
            let delta=Sphere67.delta(
                target:fighter.core.position,origin:previous)
            let t=CombatCollision556.segmentHit(
                delta:delta,travel:travel,radius:16+shipContactRadius)
            guard t<=1,boost71.firstShooterContact(fighter.id) else{continue}
            shooters[i].core.hp-=6
            let dead=shooters[i].core.hp<=0
            destruction.shooterHit(
                at:fighter.core.position,impactPoint:fighter.core.position,
                velocity:travel,momentum:fighter.velocity,
                defeated:dead,time:elapsed,rng:&random)
            if dead {defeatShooter(at:i)}
        }
    }

    /// PC602 CombatSupplyDrops.TryDropCombatSupply does not test
    /// MissionRewards57: replay can collect Energy and Bomb pickups.
    /// Uses existing seeded source RNG and the one canonical pickup array.
    private mutating func tryDropCombatSupply586(
        at point:Vec2,enemy:Bool,asteroidSize:Int=0) {
        let eligible=phase == .playing
        guard let kind=combatSupply586.decide(
            enemy:enemy,asteroidSize:asteroidSize,
            currentBombs:bombs,currentIonAmmo:ionAmmo,
            pickupsCount:tokenPickups.count,lootEnabled:eligible)
        else{return}
        tokenPickups.append(TokenPickup(
            position:point,velocity:combatSupply586.velocity(),
            value:kind == .energy ? 40 : 1,
            sourceKind:kind,life:26))
    }

    /// Physics68.Explosion68: radius 330, impulse 90. Applied BEFORE
    /// damage and splitting, to the original live rocks, fighters and loot.
    /// Normal zero-distance fallback matches Physics68.Unit68=(1,0).
    private mutating func bombImpulse68() {
        let center=flight.position
        func deltaImpulse(_ position:Vec2,_ mass:Float)->Vec2? {
            guard mass>0 else{return nil}
            let d=Sphere67.delta(target:position,origin:center)
            let dist=sqrt(d.lengthSquared)
            guard dist<330 else{return nil}
            let dir=dist>0.00001 ? d*(1/dist) : Vec2(x:1,y:0)
            let raw=dir*(90*(1-dist/330)/mass)
            return CarbonisBodyContact68.transported(
                raw,from:center,to:position)
        }
        for i in rocks.indices {
            if let impulse=deltaImpulse(rocks[i].position,rocks[i].mass) {
                rocks[i].velocity=rocks[i].velocity+impulse
            }
        }
        for i in shooters.indices {
            if let impulse=deltaImpulse(shooters[i].core.position,2) {
                shooters[i].velocity=shooters[i].velocity+impulse
            }
        }
        for i in tokenPickups.indices {
            if let impulse=deltaImpulse(tokenPickups[i].position,1) {
                tokenPickups[i].velocity=tokenPickups[i].velocity+impulse
            }
        }
    }

    /// PC v580 BossTunnelGame.UseBomb, surface/Sphere67 branch.
    /// A bomb can be used only with an active threat, costs one charge,
    /// cools down for 1.5s, damages every rock/fighter by 5, clears
    /// all hostile bullets and grants 0.5s collision immunity.
    /// Boss/tunnel branches remain outside the playable CARBONIS 01 scene.
    @discardableResult mutating func useBomb()->Bool {
        guard phase == .playing,bombs>0,bombCooldown<=0,
              !rocks.isEmpty || !shooters.isEmpty || !robots.isEmpty
        else {return false}
        bombs-=1
        bombCooldown=1.5
        emitOriginalAudio568(22) // BlastSound 2 -> original SFX22
        destruction.light(at:flight.position,kind:2,life:0.5)
        destruction.burst(at:flight.position,count:28,kind:2,
                          rng:&random)
        bombImpulse68()
        for i in rocks.indices.reversed() {
            // Match original UseBomb: always damage the rocks existing
            // when the pulse was fired, never newly split child rocks.
            rocks[i].health-=5
            if rocks[i].health<=0 {
                destroyRock(at:i)
            } else {
                destruction.rockHit(rocks[i],rng:&random)
            }
        }
        for i in shooters.indices.reversed() {
            shooters[i].core.hp-=5
            let fatal=shooters[i].core.hp<=0
            destruction.shooterHit(
                at:shooters[i].core.position,
                impactPoint:shooters[i].core.position,
                velocity:Vec2(x:0,y:0),momentum:shooters[i].velocity,
                defeated:fatal,time:elapsed,rng:&random)
            if fatal {defeatShooter(at:i)}
        }
        // PC609 BombRobot70: every ring first, then the armored head.
        for i in robots.indices.reversed() {
            for j in robots[i].rings.indices.reversed() {
                damageRobotRing70(snakeIndex:i,ringIndex:j,damage:5)
            }
            damageRobotHead70(snakeIndex:i,damage:5)
        }
        hostileShots.removeAll(keepingCapacity:true)
        invincible=max(invincible,0.5)
        return true
    }

    /// Physics68.SplitPhysical68: each large rock produces two physical
    /// spherical fragments with perpendicular 19-unit momentum and transport.
    private mutating func splitRock(_ parent:SphereAsteroid556) {
        // Game.Split() makes 18 physical terminal shards from each size-1
        // asteroid; they expire without score or further splitting.
        if parent.size==1 {
            spawnTerminalShards187(parent)
            return
        }
        guard parent.size>1,
              let balance=CombatBalance556(level:level,difficulty:difficulty,
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

    /// Game.cs:206-224 SpawnTerminalShards187. Exactly 18 short-lived
    /// shape-bearing rocks with zero score; don't invent particle decals.
    private mutating func spawnTerminalShards187(_ parent:SphereAsteroid556) {
        let pieces=18
        if rocks.count>220 {return}
        let basis=CombatBalance556(level:level,difficulty:difficulty,
                                   spherical:true)
        for i in 0..<pieces {
            let a=Float(2)*Float.pi*Float(i)/Float(pieces)
                + random.float(-0.10,0.10)
            let dir=Vec2(x:cos(a),y:sin(a))
            let position=Sphere67.offset(parent.position,
                by:dir*random.float(2,7))
            let sourceVelocity=parent.velocity
                + dir*random.float(42,115)
            let velocity=CarbonisBodyContact68.transported(
                sourceVelocity,from:parent.position,to:position)
            let rotation=random.float(-5,5)
            let shape=random.next()
            let scale=random.float(0.10,0.23)
            let life=random.float(1.3,2.5)
            rocks.append(SphereAsteroid556(
                position:position,velocity:velocity,
                radius:10*1.12*scale,size:1,tier:0,
                health:basis?.sphericalRockHealth(size:1,tier:0) ?? 2,
                fragment:true,shardLife:life,mass:0.09,
                spin:rotation,angle:parent.angle,
                originalHealth:1,shapeSeed:shape))
        }
    }

    /// EnemyTactics71.cs:32 Turn72, angularly capped to 6.5 rad/s.
    static func turn72(_ angle:Float,_ target:Float,
                       dt:Float,speed:Float=6.5)->Float {
        let delta=atan2(sin(target-angle),cos(target-angle))
        return angle + max(-speed*dt,min(speed*dt,delta))
    }


    /// PC609 RobotSnake70.StepRobot70: same sphere and hostile bullet path.
    private mutating func updateRobots70(dt:Float) {
        let robotShotDamage=ShooterTactics71(
            level:level,type:0,difficulty:difficulty.rawValue).projectileDamage
        for i in robots.indices {
            let volleys=robots[i].advance(
                dt:dt,target:flight.position,playerVelocity:flight.velocity,
                difficulty:difficulty)
            for bolt in volleys where hostileShots.count<160 {
                hostileShots.append(Projectile(
                    point:bolt.point,velocity:bolt.velocity,life:2.6,
                    hostile:true,kind:0,damage:robotShotDamage))
            }
        }
    }

    /// PC609 RobotContacts70: 3.2-unit ring mass, 8-unit head mass.
    /// Physical contacts use the existing real Sphere67/Physics68 solver.
    private mutating func resolveRobotContacts70(dt:Float) {
        guard phase == .playing else{return}
        let contactDamage=level<=2 ? 18 : level<=4 ? 22 :
            level<=8 ? 26 : level<=12 ? 27 : level<=16 ? 32 : 38
        for i in robots.indices {
            var snake=robots[i]
            for j in snake.rings.indices {
                var ring=snake.rings[j]
                for k in rocks.indices where rocks[k].shardLife<=0 {
                    var a=CarbonisBodyContact68.Body(
                        position:ring.position,velocity:ring.velocity,
                        mass:3.2,radius:SourceRobotSnake70.ringContactRadius)
                    var b=CarbonisBodyContact68.Body(
                        position:rocks[k].position,velocity:rocks[k].velocity,
                        mass:rocks[k].mass,radius:rocks[k].radius)
                    if CarbonisBodyContact68.resolve(&a,&b,restitution:0.4) {
                        ring.position=a.position;ring.velocity=a.velocity
                        rocks[k].position=b.position;rocks[k].velocity=b.velocity
                    }
                }
                for k in shooters.indices {
                    var a=CarbonisBodyContact68.Body(
                        position:ring.position,velocity:ring.velocity,
                        mass:3.2,radius:SourceRobotSnake70.ringContactRadius)
                    var b=CarbonisBodyContact68.Body(
                        position:shooters[k].core.position,
                        velocity:shooters[k].velocity,mass:2,radius:16)
                    if CarbonisBodyContact68.resolve(&a,&b,restitution:0.35) {
                        ring.position=a.position;ring.velocity=a.velocity
                        shooters[k].core.position=b.position
                        shooters[k].velocity=b.velocity
                    }
                }
                var pilot=CarbonisBodyContact68.Body(
                    position:flight.position,velocity:flight.velocity,
                    mass:shipCollisionMass,radius:shipContactRadius)
                var body=CarbonisBodyContact68.Body(
                    position:ring.position,velocity:ring.velocity,
                    mass:3.2,radius:SourceRobotSnake70.ringContactRadius)
                if CarbonisBodyContact68.resolve(&pilot,&body,restitution:0.35) {
                    flight.position=pilot.position;flight.velocity=pilot.velocity
                    ring.position=body.position;ring.velocity=body.velocity
                    suffer(contactDamage)
                }
                snake.rings[j]=ring
                if phase != .playing {robots[i]=snake;return}
            }
            for k in rocks.indices where rocks[k].shardLife<=0 {
                var a=CarbonisBodyContact68.Body(
                    position:snake.position,velocity:snake.velocity,
                    mass:8,radius:SourceRobotSnake70.headContactRadius)
                var b=CarbonisBodyContact68.Body(
                    position:rocks[k].position,velocity:rocks[k].velocity,
                    mass:rocks[k].mass,radius:rocks[k].radius)
                if CarbonisBodyContact68.resolve(&a,&b,restitution:0.45) {
                    snake.position=a.position;snake.velocity=a.velocity
                    rocks[k].position=b.position;rocks[k].velocity=b.velocity
                }
            }
            var pilot=CarbonisBodyContact68.Body(
                position:flight.position,velocity:flight.velocity,
                mass:shipCollisionMass,radius:shipContactRadius)
            var head=CarbonisBodyContact68.Body(
                position:snake.position,velocity:snake.velocity,
                mass:8,radius:SourceRobotSnake70.headContactRadius)
            if CarbonisBodyContact68.resolve(&pilot,&head,restitution:0.35) {
                flight.position=pilot.position;flight.velocity=pilot.velocity
                snake.position=head.position;snake.velocity=head.velocity
                suffer(contactDamage)
            }
            snake.constrain(dt:dt)
            robots[i]=snake
            if phase != .playing {return}
        }
    }


    /// PC609 DamageRing70: one real HP-bearing body segment, detachable
    /// without killing the snake's armored head prematurely.
    private mutating func damageRobotRing70(
        snakeIndex:Int,ringIndex:Int,damage:Int) {
        guard robots.indices.contains(snakeIndex),
              robots[snakeIndex].rings.indices.contains(ringIndex),
              damage>0 else{return}
        var snake=robots[snakeIndex]
        snake.rings[ringIndex].hp-=damage
        snake.rings[ringIndex].hitFlash=0.13
        let position=snake.rings[ringIndex].position
        destruction.burst(at:position,count:3,kind:1,rng:&random)
        if snake.rings[ringIndex].hp<=0 {
            snake.rings.remove(at:ringIndex)
            if ringIndex<snake.rings.count {
                let prior=ringIndex==0 ? snake.position :
                    snake.rings[ringIndex-1].position
                snake.rings[ringIndex].link=Self.distance(
                    snake.rings[ringIndex].position,prior)
            }
            destruction.burst(at:position,count:10,kind:1,rng:&random)
            destruction.light(at:position,kind:1,life:0.22)
            score+=20
            emitOriginalAudio568(20)
        }
        robots[snakeIndex]=snake
    }

    /// PC609 DamageRobotHead70: head is armored by every surviving ring.
    /// One genuine death increments original 400 points and Earn(9).
    private mutating func damageRobotHead70(snakeIndex:Int,damage:Int) {
        guard robots.indices.contains(snakeIndex),damage>0 else{return}
        var snake=robots[snakeIndex]
        snake.headFlash=0.12
        destruction.burst(at:snake.position,count:3,kind:1,rng:&random)
        guard snake.rings.isEmpty else{robots[snakeIndex]=snake;return}
        snake.hp-=damage
        guard snake.hp<=0 else{robots[snakeIndex]=snake;return}
        robots.remove(at:snakeIndex)
        shooterKills+=1
        score+=400
        if !isReplay {collectedLootTokens+=9}
        destruction.burst(at:snake.position,count:26,kind:1,rng:&random)
        destruction.light(at:snake.position,kind:1,life:0.5)
        emitOriginalAudio568(21)
        tryDropLegacyPickup586(at:snake.position,enemy:true,rockSize:0)
        tryDropCombatSupply586(at:snake.position,enemy:true)
    }

    /// PC609 HitRobot70 first resolves nearest head/ring and checks
    /// physical rocks/fighters for an earlier occluding contact.
    private mutating func hitRobot70(
        _ projectile:inout Projectile,dt:Float)->Bool {
        guard !robots.isEmpty else{return false}
        let gate=ShotSweepGate568(shot:projectile,dt:dt)
        var selected:Int?=nil,ringIndex:Int?=nil
        var first:Float=2
        for i in robots.indices {
            let snake=robots[i]
            let headRadius:Float=18*SourceRobotSnake70.sizeScale
            if !projectile.hitRobotHeads70.contains(snake.id),
               gate.mayReach(snake.position,radius:headRadius),
               let t=Self.projectedHit71(projectile,
                    target:snake.position,radius:headRadius,dt:dt),
               t<first {
                first=t;selected=i;ringIndex=nil
            }
            for j in snake.rings.indices {
                let ring=snake.rings[j]
                let identity=snake.id*100+ring.id
                let radius:Float=11*SourceRobotSnake70.sizeScale
                guard !projectile.hitRobotRings70.contains(identity),
                      gate.mayReach(ring.position,radius:radius),
                      let t=Self.projectedHit71(projectile,
                          target:ring.position,radius:radius,dt:dt),
                      t<first else{continue}
                first=t;selected=i;ringIndex=j
            }
        }
        guard let i=selected else{return false}
        for rock in rocks where rock.shardLife<=0 &&
            !projectile.hitRockSeeds.contains(rock.shapeSeed) {
            if gate.mayReach(rock.position,radius:rock.radius+2),
               let t=Self.projectedHit71(projectile,
                    target:rock.position,radius:rock.radius+2,dt:dt),
               t<first {return false}
        }
        for fighter in shooters {
            if gate.mayReach(fighter.core.position,radius:16),
               let t=Self.projectedHit71(projectile,
                    target:fighter.core.position,radius:16,dt:dt),
               t<first {return false}
        }
        if let j=ringIndex {
            let identity=robots[i].id*100+robots[i].rings[j].id
            projectile.hitRobotRings70.append(identity)
            damageRobotRing70(snakeIndex:i,ringIndex:j,
                damage:projectile.damage)
        } else {
            projectile.hitRobotHeads70.append(robots[i].id)
            damageRobotHead70(snakeIndex:i,damage:projectile.damage)
        }
        projectile.pierce-=1
        hudEvents.hits+=1
        return true
    }

    private mutating func updateShooters(dt:Float) {
        let player=flight.position
        let dangerSpeed:Float=difficulty == .easy ? 0.86 :
            difficulty == .normal ? 1.10 : 1.32
        for i in shooters.indices {
            var fighter=shooters[i]
            // CARBONIS remains level 1, but the W3 NEW GAME difficulty
            // reaches actual fighter tactics (not only the spawn wave).
            let tactics=ShooterTactics71(
                level:level,type:fighter.core.type,difficulty:difficulty.rawValue)
            let speed=tactics.sourceSpeed
            let delta=Sphere67.delta(target:player,origin:fighter.core.position)
            let dir=Self.unit(delta)
            let side=Vec2(x:-dir.y,y:dir.x)
            let distance=sqrt(delta.lengthSquared)
            let preferred=tactics.preferredStandoff
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
            fighter.aim=Self.turn72(
                fighter.aim,
                tactics.lockedSalvo && fighter.telegraph>0
                    ? fighter.gunAim : targetAngle,dt:dt)
            fighter.muzzle=max(0,fighter.muzzle-dt)

            if range>tactics.shootingRange {
                // Source out-of-range enemies cancel all warnings and cannot
                // carry an old firing countdown into range.
                fighter.fireClock=max(0.45,fighter.fireClock-dt)
                fighter.telegraph=0
                fighter.burst=0
                shooters[i]=fighter
                continue
            }
            fighter.fireClock-=dt
            let warning=tactics.warningSeconds
            if fighter.fireClock<=warning && fighter.telegraph<=0 &&
               fighter.burst==0 {
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
            // EnemyTactics71.cs:63-74: heavy fighters retain marked
            // gun direction; other kinds track until their shot.
            let shotAngle=tactics.lockedSalvo
                ? fighter.gunAim : fighter.aim
            let alignment=abs(atan2(
                sin(shotAngle-fighter.aim),cos(shotAngle-fighter.aim)))
            if alignment>0.25 {
                shooters[i]=fighter
                continue
            }
            for shotIndex in 0..<tactics.volleyCount {
                if tactics.type==4 && shotIndex==3 {continue}
                if hostileShots.count>=160 {break}
                let spreadOffset=(Float(shotIndex) -
                    Float(tactics.volleyCount-1)*0.5)*tactics.spread
                let a=shotAngle+spreadOffset
                let forward=Vec2(x:cos(a),y:sin(a))
                let start=Sphere67.offset(fighter.core.position,
                                         by:forward*18)
                let velocity=Sphere67.components(start,Sphere67.transport(
                    Sphere67.vector(fighter.core.position,
                                    forward*(speed*dangerSpeed)),
                    from:Sphere67.normal(fighter.core.position),
                    to:Sphere67.normal(start)))
                hostileShots.append(Projectile(
                    point:start,velocity:velocity,life:2.6,
                    hostile:true,kind:tactics.type==3 ? 2:0,
                    damage:tactics.projectileDamage))
            }
            // One sound event per hostile gun volley, not per bolt.
            emitOriginalAudio568(40+max(0,min(5,fighter.core.type)))
            fighter.muzzle=0.10
            fighter.telegraph=0
            fighter.burst+=1
            if fighter.burst<tactics.burstLength {
                fighter.fireClock=0.19
            } else {
                fighter.burst=0
                fighter.fireClock=tactics.recoverySeconds
            }
            shooters[i]=fighter
        }
    }

    /// PC v580 Game.Fire / ShotIntervalBase97. Four post-13 weapons use
    /// the same real damage/swept-contact pipeline as the original Pulse.
    private mutating func fireSourceWeapon() {
        guard let interval=H55SourceMechanics580.shotInterval(
            weapon:selectedWeapon.rawValue,upgrade:upgradeLevel,
            rapid:rapidLevel,shipType:sourceMechanics.selectedShip,
            rateRank:sourceMechanics.rateRank,
            cooling:sourceMechanics.cooling) else {return}
        cooldown=interval
        // One source fire trigger, not each Twin/Scatter projectile.
        hudEvents.shots += 1
        // PC Game.Fire consumes exactly ONE ion unit per trigger, not one
        // per individual Twin/Scatter/Swarm bolt.
        let ion=ionAmmo>0 ? 1 : 0
        ionAmmo-=ion
        // MusicAudio.cs CombatSound.Shot(weapon) = 10 + source enum ID.
        emitOriginalAudio568(10+selectedWeapon.rawValue)
        let count=selectedWeapon == .swarm ? 3 :
                  selectedWeapon == .twin ? 2 :
                  selectedWeapon == .scatter
                    ? (upgradeLevel==3 ? 5:3) : 1
        let direction=Vec2(x:cos(flight.heading),
                           y:sin(flight.heading))
        let side=Vec2(x:-direction.y,y:direction.x)
        for index in 0..<count {
            let offset:Float=selectedWeapon == .swarm
                ? Float(index-1)*0.18 :
                selectedWeapon == .scatter
                    ? (Float(index)-Float(count-1)*0.5)*0.16 : 0
            let angle=flight.heading+offset
            let heading=Vec2(x:cos(angle),y:sin(angle))
            var origin=Sphere67.offset(flight.position,by:direction*20)
            if selectedWeapon == .twin {
                origin=Sphere67.offset(origin,
                    by:side*(index==0 ? -9:9))
            }
            let speed=610+Float(upgradeLevel-1)*95
            let raw=selectedWeapon == .rail
                ? direction*1050+flight.velocity
                : heading*speed+flight.velocity
            let velocity=CarbonisBodyContact68.transported(
                raw,from:flight.position,to:origin)
            let damage=selectedWeapon == .rail ? 4 :
                selectedWeapon == .pulse && upgradeLevel==3 ? 2 : 1
            let pierce=selectedWeapon == .rail ? 4 :
                upgradeLevel==3 &&
                    (selectedWeapon != .scatter || index==count/2) ? 2:1
            bullets.append(Projectile(
                point:origin,velocity:velocity,
                life:selectedWeapon == .swarm ? 1.8 :
                     selectedWeapon == .rail ? 1.05 : 1.1,
                hostile:false,kind:selectedWeapon.rawValue,
                damage:damage+ion,pierce:pierce))
        }
    }

    /// Original Windows/src/BossTunnelGame.cs GuideSwarm: source
    /// target priority rocks -> enemy fighters (no robot in sector01).
    /// The projectile changes REAL velocity before its swept collision.
    /// PC intentionally does not re-normalize the blended velocity.
    static func guidedSwarmVelocity(
        shot:Projectile,dt:Float,rocks:[SphereAsteroid556],
        shooters:[Shooter])->Vec2 {
        guard shot.kind==4 else{return shot.velocity}
        var nearest:Float=420
        var delta=Vec2(x:0,y:0)
        var found=false
        for rock in rocks {
            let d=Sphere67.delta(target:rock.position,origin:shot.point)
            let distance=sqrt(d.lengthSquared)
            if distance<nearest {
                delta=d;nearest=distance;found=true
            }
        }
        for shooter in shooters {
            let d=Sphere67.delta(target:shooter.core.position,origin:shot.point)
            let distance=sqrt(d.lengthSquared)
            if distance<nearest {
                delta=d;nearest=distance;found=true
            }
        }
        guard found,nearest>0.01 else{return shot.velocity}
        let speed=sqrt(shot.velocity.lengthSquared)
        let desired=delta*(speed/nearest)
        let t=min(1,dt*4)
        return shot.velocity*(1-t)+desired*t
    }

    /// Source Physics68.cs:77 ImpactRock68: Pulse transfers momentum and
    /// torque to the *actual* Rock state; it is not damage-only shooting.
    /// Level-one Pulse has one damage and one pierce, so transfer=1.
    static func impactRock68(_ rock:inout SphereAsteroid556,
                             shot:Projectile) {
        guard rock.mass>0 && rock.radius>0 else{return}
        let transfer:Float=shot.pierce>1 ? 0.20 : 1
        let momentum=CarbonisBodyContact68.transported(
            shot.velocity,from:shot.point,to:rock.position) *
            (0.055*Float(max(1,shot.damage))*transfer)
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

    /// Broadphase for the EXISTING original sphere-projectile swept
    /// collision test. This is NOT a new hit model: it can reject only
    /// targets strictly farther away than |velocity|*dt+targetRadius.
    /// On a unit sphere, chord distance <= great-circle arc distance.
    /// That inequality makes the chord cap conservative even across
    /// longitude wrapping, poles, and antipodal coordinates.
    ///
    /// Source GpuSphere67 / Combat69 still decides every actual hit
    /// using Sphere67.delta + CombatCollision556.segmentHit unchanged.
    struct ShotSweepGate568 {
        let origin:Vec2
        let sourceNormal:SphereVector3
        let travelDistance:Float

        init(shot:Projectile,dt:Float) {
            origin=Sphere67.canonical(shot.point)
            sourceNormal=Sphere67.normal(origin)
            travelDistance=sqrt(shot.velocity.lengthSquared)*max(0,dt)
        }
        func mayReach(_ target:Vec2,radius:Float)->Bool {
            // 1/4 source unit is a conservative round-off guard, not a
            // change in the source projectile's actual hit radius.
            let reach=travelDistance+max(0,radius)+0.25
            if !reach.isFinite {return true}
            if reach>=Float.pi*Sphere67.radius {return true}
            let canonical=Sphere67.canonical(target)
            // Any great-circle arc is at least the absolute change
            // in latitude (Sphere67.height/pi source units).
            if abs(canonical.y-origin.y)>reach {return false}
            let normal=Sphere67.normal(canonical)
            let chord=normal-sourceNormal
            let bound=reach/Sphere67.radius
            return SphereVector3.dot(chord,chord)<=bound*bound
        }
    }

    /// BossTunnelGame.cs:96 HitBug: source projected closest-contact time
    /// and the rock occlusion check before accepting an enemy hit.
    static func projectedHit71(_ shot:Projectile,target:Vec2,
                               radius:Float,dt:Float)->Float? {
        let travel=shot.velocity*dt
        let len=travel.lengthSquared
        let delta=Sphere67.delta(target:target,origin:shot.point)
        let t=len>0 ? max(0,min(1,
            (delta.x*travel.x+delta.y*travel.y)/len)) : 0
        let closest=delta-travel*t
        return closest.lengthSquared < radius*radius ? t : nil
    }
    static func sourceRockScore(_ rock:SphereAsteroid556)->Int {
        let sizeScore=rock.size==3 ? 20 : rock.size==2 ? 50 : 100
        return sizeScore+(rock.originalHealth-1)*30+rock.tier*10
    }

    private mutating func stepShots(dt:Float) {
        for i in bullets.indices.reversed() {
            // Source GuideSwarm in BossTunnelGame.cs; no target clones or
            // new memory allocations in this per-frame update.
            if bullets[i].kind==4 && !bullets[i].guardian298 {
                bullets[i].velocity=Self.guidedSwarmVelocity(
                    shot:bullets[i],dt:dt,rocks:rocks,shooters:shooters)
            }
            // Source GuideGuardianPlasma298 runs before each collision sweep.
            // This changes actual velocities, not just a rendered trail.
            if bullets[i].guardian298 {
                bullets[i].velocity=guardianDrone.guidedVelocity(
                    at:bullets[i].point,velocity:bullets[i].velocity,dt:dt,
                    ship:flight.position,shooters:shooters,rocks:rocks,
                    focus:sourceMechanics.guardianFocus)
            }
            var robotShot=bullets[i]
            if hitRobot70(&robotShot,dt:dt) {
                if robotShot.pierce<=0 {bullets.remove(at:i);continue}
                robotShot.point=Sphere67.advance(
                    robotShot.point,velocity:&robotShot.velocity,dt:dt)
                robotShot.life-=dt
                if robotShot.life<=0 {bullets.remove(at:i)}
                else{bullets[i]=robotShot}
                continue
            }
            let shot=bullets[i]
            let gate=ShotSweepGate568(shot:shot,dt:dt)
            var impact=false
            var advancedShooterHit=false
            // The source selects the earliest projected hit on a shooter,
            // then permits it only if NO rock intersects earlier.
            var shooterIndex:Int?=nil
            var firstShooter:Float=2
            for j in shooters.indices {
                if shot.hitShooterPhases.contains(shooters[j].phase) {continue}
                if !gate.mayReach(shooters[j].core.position,radius:16) {continue}
                if let time=Self.projectedHit71(
                    shot,target:shooters[j].core.position,radius:16,dt:dt),
                    time<firstShooter {
                    firstShooter=time
                    shooterIndex=j
                }
            }
            if let j=shooterIndex {
                let blocked=rocks.contains { rock in
                    guard rock.shardLife<=0 else {return false}
                    guard gate.mayReach(rock.position,
                                        radius:rock.radius+2)
                    else {return false}
                    guard let time=Self.projectedHit71(
                        shot,target:rock.position,radius:rock.radius+2,dt:dt)
                    else {return false}
                    return time<firstShooter
                }
                if !blocked {
                    let recoil=CarbonisBodyContact68.transported(
                        shot.velocity,from:shot.point,
                        to:shooters[j].core.position)*0.035
                    shooters[j].velocity=shooters[j].velocity+recoil
                    shooters[j].core.hp-=shot.damage
                    hudEvents.hits += 1
                    impact=true
                    advancedShooterHit=shot.kind==3 || shot.kind==4
                    bullets[i].hitShooterPhases.append(shooters[j].phase)
                    // BossTunnelGame.HitBug: exact 6 sparks + 3/22 burst,
                    // physical 11-part debris only on fatal hit.
                    let fatal=shooters[j].core.hp<=0
                    let impactPoint=Sphere67.offset(
                        shot.point,by:shot.velocity*(dt*firstShooter))
                    destruction.shooterHit(
                        at:shooters[j].core.position,impactPoint:impactPoint,
                        velocity:shot.velocity,momentum:shooters[j].velocity,
                        defeated:fatal,time:elapsed,rng:&random)
                    if fatal {
                        defeatShooter(at:j)
                    }
                }
            }
            if !impact {
                // Original Game.Step: choose the earliest swept rock,
                // not the first array element, regardless of draw order.
                var hitIndex:Int?=nil
                var first:Float=2
                for j in rocks.indices where rocks[j].shardLife<=0 &&
                    !shot.hitRockSeeds.contains(rocks[j].shapeSeed) {
                    guard gate.mayReach(rocks[j].position,
                                        radius:rocks[j].radius+2)
                    else {continue}
                    let travel=shot.velocity*dt
                    let delta=Sphere67.delta(target:rocks[j].position,
                                             origin:shot.point)
                    let t=CombatCollision556.segmentHit(
                        delta:delta,travel:travel,
                        radius:rocks[j].radius+2)
                    if t<first {first=t;hitIndex=j}
                }
                if let j=hitIndex {
                    Self.impactRock68(&rocks[j],shot:shot)
                    rocks[j].health-=shot.damage
                    hudEvents.hits += 1
                    impact=true
                    bullets[i].hitRockSeeds.append(rocks[j].shapeSeed)
                    if rocks[j].health<=0 {
                        destroyRock(at:j)
                    } else {
                        // Game.cs:258 HitFlash only, no destruction cloud.
                        destruction.rockHit(rocks[j],rng:&random)
                    }
                }
            }
            if impact {
                // PC HitBug consumes a Rail/Swarm bullet even with rock
                // piercing remaining. Rock piercing itself is unchanged.
                if advancedShooterHit || bullets[i].pierce<=1 {
                    bullets.remove(at:i)
                    continue
                }
                bullets[i].pierce-=1
            }
            var moved=bullets[i]
            moved.point=Sphere67.advance(shot.point,velocity:&moved.velocity,dt:dt)
            moved.life-=dt
            if moved.life<=0 {bullets.remove(at:i)}else{bullets[i]=moved}
        }
        for i in hostileShots.indices.reversed() {
            let shot=hostileShots[i]
            let gate=ShotSweepGate568(shot:shot,dt:dt)
            if gate.mayReach(flight.position,radius:shipContactRadius+4.5) &&
               Self.hit(shot,flight.position,radius:shipContactRadius+4.5,dt:dt) {
                hostileShots.remove(at:i);suffer(shot.damage,hostileProjectile:true);continue
            }
            var moved=shot
            moved.point=Sphere67.advance(shot.point,velocity:&moved.velocity,dt:dt)
            moved.life-=dt
            if moved.life<=0 {hostileShots.remove(at:i)}else{hostileShots[i]=moved}
        }
    }
}
