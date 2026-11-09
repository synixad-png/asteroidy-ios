import Foundation

/// H11: PC v580 Game.cs GuardianTarget298 / StepGuardian298 /
/// GuideGuardianPlasma298. Pure spherical combat simulation: no UI, GLB,
/// renderer, duplicate wallet or allocations of target arrays per frame.
struct CombatGuardianDrone298 {
    struct Plasma {
        let position: Vec2
        let velocity: Vec2
        let life: Float
        let damage: Int
    }

    private(set) var position = Vec2(x:0,y:0)
    private(set) var velocity = Vec2(x:0,y:0)
    private(set) var desiredPosition = Vec2(x:0,y:0)
    private(set) var lockPoint = Vec2(x:0,y:0)
    private(set) var hasLock = false
    private(set) var visualBank:Float = 0
    private(set) var visualPitch:Float = 0
    private(set) var laser:Float = 0
    private(set) var cooldown:Float = 0
    private var initialized = false
    private var angle:Float = 0
    private var think:Float = 0
    private var orbitSide:Float = 1

    private static func magnitude(_ v:Vec2)->Float {sqrt(v.lengthSquared)}
    private static func clampMagnitude(_ v:Vec2,_ limit:Float)->Vec2 {
        let len=magnitude(v)
        return len>limit && len>0.001 ? v*(limit/len) : v
    }

    /// Game.GuardianTarget298 prioritizes nearby bugs, then active rocks;
    /// the closest eligible target wins, with the original strict tie rule.
    private static func target(origin:Vec2,ship:Vec2,
                               shooters:[CarbonisCombat568.Shooter],
                               rocks:[SphereAsteroid556],
                               focus:Int)->Vec2? {
        let f=Float(focus)
        var nearest:Float=210+18*f
        var best:Vec2?
        for enemy in shooters {
            let shipGap=Sphere67.delta(target:enemy.core.position,origin:ship)
            guard magnitude(shipGap)<=158+14*f else {continue}
            let delta=Sphere67.delta(target:enemy.core.position,origin:origin)
            let distance=magnitude(delta)
            if distance<nearest {
                nearest=distance
                best=Sphere67.offset(origin,by:delta)
            }
        }
        // The PC boss branch is absent: sector 01 has no real boss.
        for rock in rocks where rock.shardLife<=0 {
            let shipGap=Sphere67.delta(target:rock.position,origin:ship)
            guard magnitude(shipGap)<=92+8*f else {continue}
            let delta=Sphere67.delta(target:rock.position,origin:origin)
            let distance=magnitude(delta)
            if distance<nearest {
                nearest=distance
                best=Sphere67.offset(origin,by:delta)
            }
        }
        return best
    }

    private func patrolAnchor(ship:Vec2,focus:Float)->Vec2 {
        let radius:Float=94+focus*8
        let x=cos(angle*0.54)*radius*0.90 + cos(angle*1.11+1.2)*radius*0.14
        let y=sin(angle*0.62+0.3)*radius*0.58 + sin(angle*1.34)*radius*0.12
        return Sphere67.offset(ship,by:Vec2(x:x,y:y))
    }

    private mutating func combatAnchor(target:Vec2,ship:Vec2,
                                       elapsed:Float,focus:Float)->Vec2 {
        let toward=Sphere67.delta(target:target,origin:ship)
        let length=Self.magnitude(toward)
        if length<0.01 {return patrolAnchor(ship:ship,focus:focus)}
        let forward=toward*(1/length)
        let side=Vec2(x:-forward.y,y:forward.x)
        let relative=Sphere67.delta(target:position,origin:ship)
        let bias=relative.x*side.x+relative.y*side.y
        if abs(bias)>=4 {orbitSide=bias>=0 ? 1 : -1}
        let orbit:Float=104+focus*8
        let displacement=side*(orbitSide*orbit*0.70)  - forward*(orbit*0.24)  + Vec2(x:0,y:sin(elapsed*0.72)*orbit*0.05)
        return Sphere67.offset(ship,by:displacement)
    }

    /// Called after original enemy motion and before player fire/collisions.
    /// Returns a genuine damage-bearing player projectile, never a visual-only
    /// fake. No extra shot SFX: PC emits Light rather than ShotEvents here.
    mutating func step(dt:Float,elapsed:Float,ship:Vec2,shipVelocity:Vec2,
                       shooters:[CarbonisCombat568.Shooter],
                       rocks:[SphereAsteroid556],owned:Bool,
                       strike:Int,focus:Int,projectileCount:Int)->Plasma? {
        guard dt>0,dt.isFinite,(0...2).contains(strike),
              (0...2).contains(focus) else{return nil}
        cooldown=max(0,cooldown-dt)
        laser=max(0,laser-dt)
        think=max(0,think-dt)
        if !owned {
            hasLock=false
            velocity=velocity*pow(Float(0.55),dt)
            visualBank*=max(0,1-dt*3.2)
            visualPitch*=max(0,1-dt*3.2)
            return nil
        }
        let f=Float(focus)
        angle+=dt*(0.40+0.035*f)
        if !initialized {
            position=patrolAnchor(ship:ship,focus:f)
            desiredPosition=position
            initialized=true
        }
        let gapBefore=Self.magnitude(Sphere67.delta(target:position,origin:ship))
        if gapBefore>208+f*10 {
            hasLock=false
            think=min(think,0.06)
        }
        let senseOrigin=position
        if think<=0 || !hasLock {
            let sensed=Self.target(origin:senseOrigin,ship:ship,
                                   shooters:shooters,rocks:rocks,focus:focus)
            think=sensed == nil ? 0.34 : 0.24
            if let found=sensed,gapBefore<186+f*10 {
                if hasLock {
                    lockPoint=Sphere67.offset(lockPoint,
                        by:Sphere67.delta(target:found,origin:lockPoint)*0.28)
                } else {
                    lockPoint=found
                }
                hasLock=true
            } else {
                hasLock=false
            }
        }
        if hasLock {
            let toShip=Sphere67.delta(target:lockPoint,origin:ship)
            if Self.magnitude(toShip)>236+f*16 {hasLock=false}
        }
        var hasTarget=hasLock
        var anchor=hasTarget
            ? combatAnchor(target:lockPoint,ship:ship,elapsed:elapsed,focus:f)
            : patrolAnchor(ship:ship,focus:f)
        let shipGap=Sphere67.delta(target:position,origin:ship)
        let gap=Self.magnitude(shipGap)
        let minGap:Float=84+f*6
        let catchUp=gap>148+f*8
        if catchUp {
            hasTarget=false
            anchor=patrolAnchor(ship:ship,focus:f)
        }
        let shift=Self.clampMagnitude(
            Sphere67.delta(target:anchor,origin:desiredPosition),
            (catchUp ? 88 : hasTarget ? 38 : 23)*dt)
        desiredPosition=Sphere67.offset(desiredPosition,by:shift)
        let rel=Sphere67.delta(target:desiredPosition,origin:position)
        let distance=Self.magnitude(rel)
        if gap>335 || distance>315 {
            position=Sphere67.offset(position,
                by:rel*(gap>430 ? 0.26 : 0.16))
            velocity=velocity*(gap>430 ? 0.42 : 0.58)
        }
        let maxSpeed:Float=(catchUp ? 132 : hasTarget ? 70 : 56)  + f*(catchUp ? 11 : 7)
        let accel:Float=(catchUp ? 118 : hasTarget ? 56 : 44)  + f*(catchUp ? 9 : 5)
        var wanted=shipVelocity*(catchUp ? 0.78 : hasTarget ? 0.28 : 0.16)
        if distance>0.01 {
            wanted=wanted+rel*(min(maxSpeed,
                distance*(catchUp ? 1.08 : hasTarget ? 0.54 : 0.42))/distance)
        }
        let error=wanted-velocity
        var spring=rel*(catchUp ? 0.88 : hasTarget ? 0.72 : 0.54)  + error*(catchUp ? 1.44 : hasTarget ? 1.00 : 0.86)
        spring=Self.clampMagnitude(spring,accel)
        if gap<minGap && gap>0.001 {
            spring=spring+shipGap*((minGap-gap)*1.08/gap)
        }
        velocity=velocity+spring*dt
        velocity=velocity*pow(Float(catchUp ? 0.57 : 0.64),dt)
        velocity=Self.clampMagnitude(velocity,maxSpeed)
        position=Sphere67.offset(position,by:velocity*dt)
        let targetBank=max(-14,min(14,-spring.x*0.11-velocity.x*0.05))
        let targetPitch=max(-10,min(10,-spring.y*0.08-velocity.y*0.035))
        visualBank+=(targetBank-visualBank)*min(1,dt*(catchUp ? 1.8 : 1.45))
        visualPitch+=(targetPitch-visualPitch)*min(1,dt*(catchUp ? 1.7 : 1.35))
        if catchUp || !hasLock {return nil}
        laser=min(0.56,laser+dt*0.95)
        guard cooldown<=0,projectileCount<180 else{return nil}
        let toTarget=Sphere67.delta(target:lockPoint,origin:position)
        let len=Self.magnitude(toTarget)
        guard len>0.01,len<=182+f*16 else{return nil}
        let speed:Float=300+f*24
        let initial=toTarget*(speed/len)+velocity*0.08
        cooldown=H55SourceMechanics580.guardianShotCooldown(
            strike:strike,focus:focus)
        laser=0.48
        return Plasma(position:position,velocity:initial,
                      life:0.92+0.14*f,
                      damage:H55SourceMechanics580.guardianShotDamage(
                          strike:strike))
    }

    /// PC Game.GuideGuardianPlasma298 steers an actual active bullet toward
    /// the nearest threat each tick, preserving the bullet's speed.
    func guidedVelocity(at point:Vec2,velocity:Vec2,dt:Float,
                        ship:Vec2,shooters:[CarbonisCombat568.Shooter],
                        rocks:[SphereAsteroid556],focus:Int)->Vec2 {
        guard (0...2).contains(focus),
              let target=Self.target(origin:point,ship:ship,
                                     shooters:shooters,rocks:rocks,focus:focus)
              else{return velocity}
        let toward=Sphere67.delta(target:target,origin:point)
        let distance=Self.magnitude(toward)
        guard distance>0.01 else{return velocity}
        let speed=max(1,Self.magnitude(velocity))
        let desired=toward*(speed/distance)
        let turn=min(1,dt*(1.35+Float(focus)*0.36))
        var next=velocity*(1-turn)+desired*turn
        let length=Self.magnitude(next)
        if length>0.01 {next=next*(speed/length)}
        return next
    }
}
