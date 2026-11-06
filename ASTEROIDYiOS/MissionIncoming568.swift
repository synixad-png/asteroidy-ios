import Foundation

/// Source Action38.cs:7,9-10: scheduled extra asteroid waves after Game.Wave.
/// Simulation-state utility; not active gameplay until CARBONIS world loop
/// applies returned rocks and moves ship/enemies with real collisions.
struct MissionIncoming568 {
    let level: Int
    let difficulty: CombatBalance556.Difficulty
    let cooperative: Bool
    let objective: MissionWave568.Objective
    private var random: MissionWave568.SourceRandom
    private(set) var incomingLeft: Int
    private(set) var sectorTime: Float = 0
    private(set) var nextIncoming: Float
    private(set) var noticeTime: Float = 0

    init(from encounter: MissionWave568.Encounter,
         difficulty: CombatBalance556.Difficulty,
         cooperative: Bool = false) {
        level = encounter.sector
        self.difficulty = difficulty
        self.cooperative = cooperative
        objective = encounter.objective
        random = encounter.randomState // Continue original shared C# random stream.
        incomingLeft = encounter.initialReinforcements
        nextIncoming = encounter.nextIncomingSeconds
    }

    mutating func step(dt: Float, isPlaying: Bool, ship: Vec2,
                       activeRocks: Int, activeEnemies: Int,
                       objectivePosition: Vec2) -> [SphereAsteroid556] {
        guard dt > 0 && isPlaying else { return [] }
        if objective == .clear && activeRocks == 0 && activeEnemies == 0 {
            // Action38.StepAction: no extra rocks after clear objective done.
            incomingLeft = 0
        }
        sectorTime += dt
        noticeTime = max(0,noticeTime-dt)
        guard incomingLeft > 0 &&
              (sectorTime >= nextIncoming ||
               (objective != .waves && activeRocks <= 4)) else { return [] }
        return spawn(ship:ship,objectivePosition:objectivePosition)
    }

    private mutating func spawn(ship: Vec2,
                                objectivePosition: Vec2) -> [SphereAsteroid556] {
        guard let b=CombatBalance556(level:level,difficulty:difficulty,
                                       spherical:true) else { return [] }
        let count=min(2,incomingLeft)
        incomingLeft -= count
        let danger:Float=difficulty == .easy ? 0.86 : difficulty == .normal ? 1.10 : 1.32
        var result:[SphereAsteroid556]=[]
        for i in 0..<count {
            var p=Vec2(x:0,y:0),tries=0
            repeat {
                p=Vec2(x:i%2==0 ? 20 : 1260,y:random.float(140,660))
                tries += 1
                if tries > 20 {
                    let offset=MissionWave568.direction(random.float(0,2*Float.pi))*340
                    p=Sphere67.offset(ship,by:offset)
                }
            } while sqrt(Sphere67.delta(target:p,origin:ship).lengthSquared) < 260 && tries < 1000
            let tier=level>=13 ? 2+random.integer(3) : level>=10 ? 2 : level>=5 ? 1 : 0
            let target=Sphere67.delta(target:objectivePosition,origin:p)
            let heading: Vec2
            if objective == .defend {
                heading=target*(1/max(1,sqrt(target.lengthSquared)))
            } else {
                heading=MissionWave568.direction(random.float(0,2*Float.pi))
            }
            let speed=random.float(60,100)*0.55*danger
            let angle=random.float(0,2*Float.pi)
            let spin=random.float(-0.85,0.85)
            let shape=random.next()
            result.append(SphereAsteroid556(position:p,velocity:heading*speed,
                radius:b.sphericalRockRadius(size:3),size:3,tier:tier,
                health:b.sphericalRockHealth(size:3,tier:tier,cooperative:cooperative),
                spin:spin,angle:angle,
                originalHealth:Rock.healthFor(size:3,tier:tier),shapeSeed:shape))
        }
        noticeTime=1.6
        nextIncoming=sectorTime+(objective == .waves ? 16 : 11)
        return result
    }
}
