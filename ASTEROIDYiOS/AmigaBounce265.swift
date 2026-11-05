import Foundation

/// Literal port of Windows/src/AmigaBounce265.cs plus the Level==25
/// part of Windows/src/Balance70.cs PrepareRock70. This is ONLY for
/// the original spherical level 25 perpetual bouncing-ball showroom.
enum AmigaBounce265 {
    static let hitsGoal = 20 // HUD reference; NEVER a completion gate.

    static func prepare(_ rock:inout SphereAsteroid556) {
        guard !rock.fragment else { return }
        let shape=Float(rock.shapeSeed & 0xffff)
        let phase=abs(sin(shape*0.01927))
        rock.bounceHeight=4+17*phase
        rock.bounceVertical=119+71*abs(sin(shape*0.03719))
        rock.bounceCount=0
    }

    /// AmigaBounce265.StepAmigaBounce265: 480 gravity, 0.05 s cap,
    /// independent per-ball rhythm, 55-unit radial height limit.
    static func step(_ rock:inout SphereAsteroid556,dt:Float) {
        guard rock.shardLife<=0 && dt>0 else { return }
        let t=min(dt,0.05)
        let gravity:Float=480
        rock.bounceHeight += rock.bounceVertical*t-0.5*gravity*t*t
        rock.bounceVertical -= gravity*t
        if rock.bounceHeight>0 {
            rock.bounceHeight=min(55,rock.bounceHeight)
            return
        }
        rock.bounceHeight=0
        rock.bounceCount += 1
        let shape=Float(rock.shapeSeed & 0xffff)
        let turns=Float(rock.bounceCount)
        let wobble=sin(shape*0.01607+turns*2.417)
        let variety=sin(shape*0.04371+turns*1.319)
        rock.bounceVertical=149+44*(0.5+0.5*variety)
        let current=sqrt(rock.velocity.lengthSquared)
        let speed=max(45,min(270,current*(0.84+0.12*abs(variety))))
        var direction=atan2(rock.velocity.y,rock.velocity.x)+wobble*1.45
        if rock.bounceCount%5==0 {
            direction += variety>=0 ? 0.83 : -0.83
        }
        rock.velocity=Vec2(x:cos(direction),y:sin(direction))*speed
        rock.spin=max(-2.8,min(2.8,rock.spin+wobble*0.22))
    }

    /// AmigaBounce265.ImpulseAmiga266: shots change momentum and hop,
    /// but NEVER reduce rock health or fragment the planet-25 balls.
    /// Caller owns the source counted hit/score increment.
    static func impact(_ rock:inout SphereAsteroid556,
                       origin:Vec2,projectileVelocity:Vec2,
                       power:Int=1) {
        let incoming=Sphere67.components(rock.position,
            Sphere67.transport(Sphere67.vector(origin,projectileVelocity),
                from:Sphere67.normal(origin),
                to:Sphere67.normal(rock.position)))
        let length=sqrt(incoming.lengthSquared)
        let fallback=rock.angle+Float.pi/3
        let direction=length>0.001 ? incoming*(1/length) :
                       Vec2(x:cos(fallback),y:sin(fallback))
        let impulse=min(145,75+Float(power)*14)
        let next=rock.velocity*0.70+direction*impulse
        let speed=sqrt(next.lengthSquared)
        rock.velocity=speed>285 ? next*(285/speed) : next
        let flight=145+min(75,Float(power)*11)
        rock.bounceVertical=max(rock.bounceVertical,flight)
        rock.bounceHeight=max(rock.bounceHeight,3.5)
        rock.spin=max(-3,min(3,rock.spin+
                      (rock.shapeSeed & 1 == 0 ? 0.48 : -0.48)))
        rock.health=rock.maxHealth
    }
}
