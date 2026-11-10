import Foundation

/// Deterministic PC v600 HUD dynamics; no game-state mutation or per-frame IO.
/// Port of Windows/src/HudMotion.cs HudMotionController.
struct HudMotion600 {
    struct Settings: Codable, Equatable {
        var profile = 2
        var strength = 45
        var inertia = 65
        var impact = 35
        var leftSway = 400
        var rightSway = 400
        var parallax = true
        var reactions = true
        var profileFactor: Float {
            profile == 0 ? 0 : profile == 1 ? 0.42 : profile == 3 ? 1.32 : 1
        }
    }
    struct Sample {
        var turnRate:Float = 0
        var speed:Float = 0
        var forwardAcceleration:Float = 0
        var bank:Float = 0
        var pitch:Float = 0
        var boost:Float = 0
        var flash:Float = 0
        var damage:Float = 0
        var hull:Float = 0
        var armor:Float = 0
        var shield:Float = 0
        var shots:Int = 0
        var hits:Int = 0
        var pickups:Int = 0
        var shieldActive = false
    }
    struct Pose {
        var x:Float = 0
        var y:Float = 0
        var roll:Float = 0
        var shotPulse:Float = 0
        var hitPulse:Float = 0
        var damagePulse:Float = 0
        var pickupPulse:Float = 0
        var hullPulse:Float = 0
        var armorPulse:Float = 0
        var shieldPulse:Float = 0
        var iconStrength:Float = 0
        var parallax = false
        func weight(_ id:String)->Float {
            guard parallax else {return 1}
            if id == "hud.planetarium" {return 1.18}
            if id == "radar" {return 1}
            if id.hasPrefix("status.") || id.hasPrefix("mission.") || id.hasPrefix("objective.") {return 0.42}
            return 0.78
        }
    }
    var settings = Settings()
    private var previous: Sample?
    private var lastTime:Double?
    private var x:Float = 0, y:Float = 0, roll:Float = 0
    private var vx:Float = 0, vy:Float = 0, vr:Float = 0
    private var shot:Float = 0, hit:Float = 0, damage:Float = 0, pickup:Float = 0
    private var hullPulse:Float = 0, armorPulse:Float = 0, shieldPulse:Float = 0
    private(set) var pose = Pose()

    mutating func reset() {
        previous=nil;lastTime=nil
        x=0;y=0;roll=0;vx=0;vy=0;vr=0
        shot=0;hit=0;damage=0;pickup=0
        hullPulse=0;armorPulse=0;shieldPulse=0
        pose=Pose()
    }
    private static func bound(_ value:Float,_ limit:Float)->Float {
        max(-limit,min(limit,value))
    }
    private static func damp(_ current:Float,_ velocity:inout Float,
                             _ target:Float,_ seconds:Float,_ dt:Float)->Float {
        let omega:Float=2/max(0.045,seconds)
        let error=current-target
        let c=velocity+omega*error
        let decay=exp(-omega*dt)
        velocity=(velocity-omega*c*dt)*decay
        return target+(error+c*dt)*decay
    }
    mutating func update(_ sample:Sample,at now:Double,active:Bool)->Pose {
        guard active,settings.profile != 0,settings.strength > 0,now.isFinite else {
            reset();return pose
        }
        guard let last=lastTime,let prior=previous else {
            previous=sample;lastTime=now;return pose
        }
        let elapsed=now-last
        guard elapsed>=0,elapsed<=0.5,sample.shots>=prior.shots,
              sample.hits>=prior.hits else {
            reset();previous=sample;lastTime=now;return pose
        }
        let dt=Float(min(0.05,elapsed))
        lastTime=now
        guard dt>0 else {return pose}
        let turn=Self.bound(sample.turnRate.isFinite ? sample.turnRate/2.2 : 0,1)
        let bank=Self.bound(sample.bank.isFinite ? sample.bank/26 : 0,1)
        let pitch=Self.bound(sample.pitch.isFinite ? sample.pitch/18 : 0,1)
        var acceleration=sample.forwardAcceleration.isFinite ? sample.forwardAcceleration : 0
        if abs(acceleration)<0.0001 && sample.speed.isFinite && prior.speed.isFinite {
            acceleration=(sample.speed-prior.speed)/dt
        }
        let accel=Self.bound(acceleration/220,1)
        let boost=sample.boost.isFinite ? max(0,min(1,sample.boost)):0
        let strength=settings.profileFactor*Float(settings.strength)*0.01
        let rawX=Self.bound(-turn*0.68-bank*0.32,1)
        let rawRoll=Self.bound(-turn*0.64-bank*0.36,1)
        let lateralX=Float(rawX<0 ? settings.leftSway : settings.rightSway)*0.01
        let lateralRoll=Float(rawRoll<0 ? settings.leftSway : settings.rightSway)*0.01
        let targetX=rawX*8*strength*lateralX
        let targetY=Self.bound((-accel*0.7-pitch*0.3-boost*0.25)*5*strength,5*strength)
        let targetRoll=rawRoll*1.2*strength*lateralRoll
        let settle:Float=0.13+Float(settings.inertia)*0.0043
        x=Self.damp(x,&vx,targetX,settle,dt)
        y=Self.damp(y,&vy,targetY,settle,dt)
        roll=Self.damp(roll,&vr,targetRoll,settle,dt)
        if settings.reactions {
            if sample.shots>prior.shots {shot=min(1,shot+0.55)}
            if sample.hits>prior.hits {hit=min(1,hit+0.70)}
            if sample.damage<prior.damage-0.01 || sample.flash>prior.flash+0.08 {
                damage=min(1,damage+1)
            }
            if sample.hull<prior.hull-0.01 {hullPulse=1}
            if sample.armor<prior.armor-0.01 {armorPulse=1}
            if sample.shield<prior.shield-0.01 || sample.shieldActive && !prior.shieldActive {
                shieldPulse=1
            }
            if sample.pickups>prior.pickups {pickup=min(1,pickup+0.75)}
        } else {
            shot=0;hit=0;damage=0;pickup=0
            hullPulse=0;armorPulse=0;shieldPulse=0
        }
        shot *= exp(-dt*14);hit *= exp(-dt*11)
        damage *= exp(-dt*10);pickup *= exp(-dt*7)
        hullPulse *= exp(-dt*10);armorPulse *= exp(-dt*10);shieldPulse *= exp(-dt*10)
        let impulse=settings.reactions ? Float(settings.impact)*0.01*settings.profileFactor : 0
        pose=Pose(x:Self.bound(x+(damage*0.85+hit*0.24-shot*0.12)*impulse,48),
                  y:Self.bound(y+(damage*0.60-shot*0.16+pickup*0.18)*impulse,8),
                  roll:Self.bound(roll+(damage*0.20+hit*0.10)*impulse,7),
                  shotPulse:shot,hitPulse:hit,damagePulse:damage,pickupPulse:pickup,
                  hullPulse:hullPulse*impulse,armorPulse:armorPulse*impulse,
                  shieldPulse:shieldPulse*impulse,iconStrength:strength*1.6,
                  parallax:settings.parallax)
        previous=sample
        return pose
    }
}