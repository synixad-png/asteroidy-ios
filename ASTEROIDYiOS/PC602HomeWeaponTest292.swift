import Foundation

/// Actual non-hostile test range from Windows/src/HomeFlight291.cs:
/// StepHomeWeaponTest292 -> Game.Fire -> Sphere67.WorldAdvance67.
/// This DOES NOT damage enemies or asteroids and CANNOT grant credits,
/// score, ion ammunition, level completion or any persistent reward.
/// The exact PC Game.Fire weapon pattern lives here, not a fake laser ray.
struct PC602HomeWeaponTest292 {
    enum Weapon:Int,CaseIterable {
        case pulse=0,twin=1,scatter=2,rail=3,swarm=4
    }
    struct Settings {
        let weapon:Weapon
        let upgrade:Int
        let rapid:Int
        let cooling:Int
        let fireRateScale:Float
        let fireRateTalent:Float
        // The actual new-game PC default is weapon Pulse, upgrade 1,
        // Rapid 0 and Cooling 0. Verified constants need no force-unwrap.
        init() {
            weapon = .pulse
            upgrade = 1
            rapid = 0
            cooling = 0
            fireRateScale = 1
            fireRateTalent = 1
        }
        static let defaultPulse=Settings()
        init?(weapon:Weapon,upgrade:Int=1,rapid:Int=0,cooling:Int=0,
              fireRateScale:Float=1,fireRateTalent:Float=1) {
            guard (1...3).contains(upgrade),(0...2).contains(rapid),
                  (0...2).contains(cooling),
                  fireRateScale.isFinite,fireRateTalent.isFinite,
                  fireRateScale>0,fireRateTalent>0 else{return nil}
            self.weapon=weapon
            self.upgrade=upgrade
            self.rapid=rapid
            self.cooling=cooling
            self.fireRateScale=fireRateScale
            self.fireRateTalent=fireRateTalent
        }
        // PC602 Game.ShotIntervalBase97 and Modules97.ShotInterval.
        var interval:Float {
            let rate:Float
            switch weapon {
            case .rail:
                rate=(0.32-0.02*Float(upgrade-1))/(1+Float(rapid)*0.15)
            case .swarm:
                rate=(0.29-0.015*Float(upgrade-1))/(1+Float(rapid)*0.15)
            case .pulse,.twin,.scatter:
                let base:Float=weapon == .scatter ? 0.31 :
                               weapon == .twin ? 0.20 : 0.16
                let perLevel:Float=weapon == .scatter ? 0.03:0.02
                let raw=base-perLevel*Float(upgrade-1)
                rate=max(0.075,raw*fireRateScale*fireRateTalent/(1+Float(rapid)*0.15))
                return max(0.065,rate*(1-0.06*Float(cooling)))
            }
            return max(0.065,rate*fireRateScale*fireRateTalent*(1-0.06*Float(cooling)))
        }
    }

    struct Bullet {
        var position:Vec2
        var velocity:Vec2
        var life:Float
        let kind:Weapon
        let damage:Int
        let pierce:Int
    }

    private(set) var projectiles=[Bullet]()
    private(set) var cooldown:Float=0
    private(set) var emissions:Int=0
    var settings:Settings

    init(settings:Settings) {self.settings=settings}

    private static func direction(_ angle:Float)->Vec2 {
        Vec2(x:cos(angle),y:sin(angle))
    }
    private static func length(_ v:Vec2)->Float {
        sqrt(v.lengthSquared)
    }

    /// Takes the SAME physical 67 scene state used by HomeFlight291 AFTER
    /// DirectFlight/MoveShip, never a separate invented camera coordinate.
    /// The step order matches source: cooldown, Fire, geodesic advance.
    mutating func step(ship:SphereFlight67,dt:Float,fire:Bool) {
        guard dt.isFinite,dt>=0 else{return}
        let dt=min(0.05,dt)
        cooldown=max(0,cooldown-dt)
        if fire && cooldown<=0 {
            emit(ship:ship)
        }
        for i in projectiles.indices.reversed() {
            var bullet=projectiles[i]
            bullet.position=Sphere67.advance(bullet.position,
                velocity:&bullet.velocity,dt:dt)
            bullet.life-=dt
            if bullet.life<=0 {
                projectiles.remove(at:i)
            } else {
                projectiles[i]=bullet
            }
        }
    }

    private mutating func emit(ship:SphereFlight67) {
        // Original Game.Fire blocks ONLY when Count>140 BEFORE the salvo.
        guard projectiles.count<=140 else{return}
        cooldown=settings.interval
        emissions+=1
        let kind=settings.weapon
        let count=kind == .swarm ? 3 :
                  kind == .twin ? 2 :
                  kind == .scatter ? (settings.upgrade==3 ? 5:3):1
        let forward=Self.direction(ship.heading)
        let side=Self.direction(ship.heading+Float.pi/2)
        let first=Sphere67.offset(ship.position,by:forward*20)
        let sourceNormal=Sphere67.normal(ship.position)
        let boost=610+Float(settings.upgrade-1)*95
        for index in 0..<count {
            let offset:Float
            if kind == .swarm {
                offset=Float(index-1)*0.18
            } else if kind == .scatter {
                offset=(Float(index)-Float(count-1)*0.5)*0.16
            } else {offset=0}
            let origin=kind == .twin
                ? Sphere67.offset(first,by:side*(index==0 ? -9:9))
                : first
            // Source's Velocity67 is tangent at the pilot position;
            // each new bullet velocity is parallel-transported to its
            // actual Sphere67 origin BEFORE its first movement tick.
            let angle=ship.heading+(kind == .rail ? 0:offset)
            let initial=Self.direction(angle)*(kind == .rail ? 1050:boost)+ship.velocity
            let world=Sphere67.vector(ship.position,initial)
            let moved=Sphere67.transport(world,from:sourceNormal,
                                         to:Sphere67.normal(origin))
            let velocity=Sphere67.components(origin,moved)
            let piercing=settings.upgrade==3 &&
                (kind != .scatter || index==count/2)
            projectiles.append(Bullet(
                position:origin,velocity:velocity,
                life:kind == .swarm ? 1.8:1.05,kind:kind,
                damage:kind == .rail ? 4 :
                    kind == .pulse && settings.upgrade==3 ? 2:1,
                pierce:kind == .rail ? 4:(piercing ? 2:1)))
        }
    }
}
