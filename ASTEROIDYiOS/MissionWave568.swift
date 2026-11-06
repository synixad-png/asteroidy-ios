import Foundation

/// Source-derived initial Wave() encounter, not a stand-in for the playable
/// mission loop. Windows v568 Game.cs:83-101, Action38.cs:4-7,
/// EnemyTactics71.cs:11-14,29-30, RobotSnake70.cs:8-13, Balance70.cs:5-6.
/// The source C# CampaignLength is 25; the 26th atlas entry is not a level.
enum MissionWave568 {
    struct Fighter {
        var position: Vec2
        var hp: Int
        var type: Int
        var hunter: Bool
        var fireClock: Float
        var phase: Float
    }
    struct RobotRing {
        var position: Vec2
        var hp: Int
        var link: Float
    }
    struct Robot {
        var position: Vec2
        var hp: Int
        var phase: Float
        var rings: [RobotRing]
    }
    enum Objective: Equatable { case clear, escort, defend, waves }
    struct Encounter {
        var rocks: [SphereAsteroid556]
        var fighters: [Fighter]
        var robots: [Robot]
        let objective: Objective
        let initialReinforcements: Int
        let nextIncomingSeconds: Float
        let lootYieldScale: Float
        let isAmigaShowroom: Bool
        let sector: Int
        /// An encounter snapshot does not imply player/enemy update or
        /// renderer wiring exists. Mission unlock bits are never mutated.
        var playable: Bool { false }
    }
    /// Classic .NET Framework / seeded System.Random subtractive generator.
    /// C# source uses new Random(seed), Rand() and random.Next().
    struct SourceRandom {
        private static let modulus = 2147483647
        private var table = [Int](repeating: 0, count: 56)
        private var index = 0
        private var index2 = 21
        init(seed: Int32) {
            let subtraction = seed == Int32.min ? Int(Int32.max) : abs(Int(seed))
            var mj = 161803398 - subtraction
            if mj < 0 { mj += Self.modulus }
            table[55] = mj
            var mk = 1
            for i in 1..<55 {
                let ii = (21 * i) % 55
                table[ii] = mk
                mk = mj - mk
                if mk < 0 { mk += Self.modulus }
                mj = table[ii]
            }
            for _ in 0..<4 {
                for i in 1...55 {
                    table[i] -= table[1 + (i + 30) % 55]
                    if table[i] < 0 { table[i] += Self.modulus }
                }
            }
        }
        mutating func next() -> Int {
            index += 1; if index >= 56 { index = 1 }
            index2 += 1; if index2 >= 56 { index2 = 1 }
            var n = table[index] - table[index2]
            if n == Self.modulus { n -= 1 }
            if n < 0 { n += Self.modulus }
            table[index] = n
            return n
        }
        mutating func unit() -> Double { Double(next()) / Double(Self.modulus) }
        mutating func float(_ low: Float,_ high: Float) -> Float {
            low + (high - low) * Float(unit())
        }
        mutating func integer(_ upperBound: Int) -> Int {
            guard upperBound > 0 else { return 0 }
            return Int(unit() * Double(upperBound))
        }
    }

    /// WaveCount(Game.cs) and Action38.ConfigureActionSector evaluated
    /// on the original source level/difficulty; no invented 26th mission.
    static func initialQuota(level: Int, difficulty: CombatBalance556.Difficulty,
                             objective: Objective) -> Int {
        guard let b = CombatBalance556(level: level, difficulty: difficulty,
                                        spherical: true) else { return 0 }
        let basic: Int
        switch objective {
        case .waves: basic = 4
        case .escort: basic = max(4, b.reinforcementQuota)
        case .defend: basic = max(6, b.reinforcementQuota)
        case .clear: basic = b.reinforcementQuota
        }
        return Int((Double(basic) * 0.8).rounded(.toNearestOrEven))
    }
    static func objective(_ level:Int) -> Objective {
        if [2,11,21].contains(level) { return .escort }
        if [5,14,23].contains(level) { return .defend }
        if [9,17].contains(level) { return .waves }
        return .clear
    }
    static func shooterCount(_ level:Int,_ difficulty:CombatBalance556.Difficulty) -> Int {
        let d=difficulty.rawValue
        let starting: Int
        if level <= 2 { starting = d == 0 ? 1 : d == 2 ? 3 : 2 }
        else if level <= 4 { starting = d == 0 ? 2 : d == 2 ? 4 : 3 }
        else if level <= 8 { starting = d == 0 ? 3 : d == 2 ? 5 : 4 }
        else { starting = 4 + min(5,max(0,(level-1)/4)) + (d == 2 ? 2 : d == 0 ? -1 : 0) }
        return starting + 2 // EnemyTactics71.cs:30; old Gameplay77Tests is stale
    }
    static func robotCount(_ level:Int,_ difficulty:CombatBalance556.Difficulty) -> Int {
        let d=difficulty.rawValue
        if level < (d == 0 ? 5 : d == 2 ? 2 : 3) { return 0 }
        if d == 2 { return level >= 17 ? 3 : level >= 9 ? 2 : 1 }
        if d == 0 { return level >= 17 ? 2 : 1 }
        return level >= 21 ? 3 : level >= 13 ? 2 : 1
    }
    static func direction(_ angle:Float) -> Vec2 {
        Vec2(x:Float(cos(Double(angle))),y:Float(sin(Double(angle))))
    }
    private static func distance(_ a:Vec2,_ b:Vec2) -> Float {
        sqrt(Sphere67.delta(target:a,origin:b).lengthSquared)
    }
    static func generate(level:Int,difficulty:CombatBalance556.Difficulty,
                         seed:Int32,ship:Vec2=Vec2(x:640,y:360),
                         cooperative:Bool=false) -> Encounter? {
        guard (1...25).contains(level),
              let b=CombatBalance556(level:level,difficulty:difficulty,
                                     spherical:true) else { return nil }
        var random=SourceRandom(seed:seed)
        let danger: Float = difficulty == .easy ? 0.86 : difficulty == .normal ? 1.10 : 1.32
        let isAmiga = level == 25
        var rocks:[SphereAsteroid556]=[]
        rocks.reserveCapacity(b.sectorRockCount)
        for i in 0..<b.sectorRockCount {
            guard let tier=b.tier(at:i) else { return nil }
            var p=Vec2(x:0,y:0)
            // Original Game.Wave uses rejection without a fixed try count.
            // Seeded .NET RNG varies; cap solely protects from corrupt state.
            var safe=false
            for _ in 0..<100_000 {
                p=Vec2(x:random.float(0,1280),y:random.float(0,720))
                if distance(p,ship)>=260 { safe=true;break }
            }
            guard safe else { return nil }
            let heading=random.float(0,2*Float.pi)
            let speed=(random.float(48,78)+Float(min(level-1,18))*3.2)
                * (tier>=2 ? 0.88 : 1) * 0.55 * danger
            let angle=random.float(0,2*Float.pi)
            let spin=random.float(-0.65,0.65)
            let shape=random.next()
            var rock=SphereAsteroid556(position:p,velocity:direction(heading)*speed,
                radius:b.sphericalRockRadius(size:3),size:3,tier:tier,
                health:b.sphericalRockHealth(size:3,tier:tier,cooperative:cooperative),
                spin:spin,angle:angle,
                originalHealth:Rock.healthFor(size:3,tier:tier),shapeSeed:shape)
            if isAmiga { AmigaBounce265.prepare(&rock) }
            rocks.append(rock)
        }
        var fighters:[Fighter]=[]
        var robots:[Robot]=[]
        if !isAmiga {
            let n=shooterCount(level,difficulty)
            let tier=min(5,max(0,(level-1)/4))
            for i in 0..<n {
                let angle=Float(i)*2*Float.pi/Float(n)+0.7
                let offset=direction(angle)*random.float(level<=4 ? 285 : 210,
                                                            level<=4 ? 370 : 320)
                let p=Sphere67.offset(ship,by:offset)
                let type=i==0 ? tier : random.integer(tier+1)
                fighters.append(Fighter(position:p,hp:3+type+(difficulty == .hard ? 2 : 0),
                    type:type,hunter:type==1 || type==5,
                    fireClock:(level<=4 ? 2.4 : 0.9)+Float(i)*(level<=4 ? 0.8 : 0.22),
                    phase:Float(i)*1.7))
            }
            let ringCount=6+min(6,max(0,(level-3)/3))
            let ringHP=2+difficulty.rawValue+(level>=13 ? 1 : 0)+(level>=21 ? 1 : 0)
            let secondShip=Sphere67.offset(ship,by:Vec2(x:85,y:0))
            for _ in 0..<robotCount(level,difficulty) {
                var p=Vec2(x:0,y:0), tail=Vec2(x:0,y:0)
                for _ in 0..<128 {
                    p=Vec2(x:random.float(0,1280),y:random.float(100,620))
                    tail=direction(random.float(0,2*Float.pi))
                    var safe=true
                    for i in 0...ringCount {
                        let ring=Sphere67.offset(p,by:tail * Float(i==0 ? 0 : 26+(i-1)*18))
                        if distance(ring,ship)<230 || (cooperative && distance(ring,secondShip)<200) {
                            safe=false;break
                        }
                    }
                    if safe { break }
                }
                var rings:[RobotRing]=[]
                for i in 0..<ringCount {
                    rings.append(RobotRing(position:Sphere67.offset(p,by:tail*Float(26+i*18)),
                                           hp:ringHP,link:Float(i==0 ? 26 : 18)))
                }
                robots.append(Robot(position:p,hp:6+difficulty.rawValue+(level>=13 ? 2 : 0),
                                    phase:random.float(0,6),rings:rings))
            }
        }
        let goal=objective(level)
        let incoming=isAmiga ? 0 : initialQuota(level:level,difficulty:difficulty,objective:goal)
        let classic=level>=13 ? 7+min(5,(level-13)/2) : min(4+level/2,10)
        let loot=Float(classic)*1.08 / Float(b.sectorRockCount+incoming)
        return Encounter(rocks:rocks,fighters:fighters,robots:robots,objective:goal,
             initialReinforcements:incoming,nextIncomingSeconds:goal == .waves ? 16 : 12,
             lootYieldScale:loot,isAmigaShowroom:isAmiga,sector:level)
    }
}
