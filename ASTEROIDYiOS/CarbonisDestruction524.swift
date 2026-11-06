import Foundation

/// A direct port of the first-sector destruction effects only:
/// Windows/src/Game.cs:39-55,119-122,224-230,235-237
/// Windows/src/BossTunnelGame.cs:96
/// Windows/src/CombatPieces125.cs:4-42
/// Windows/src/Explosion524.cs:8-23,165-220
/// These are *visual* events. No geometry, hitboxes, damage, drops or
/// campaign logic is changed by their simulation.
/// The original System.Random and the iOS MissionWave SourceRandom are
/// different RNG implementations, so stochastic samples are formula-parity,
/// not byte-identical seeded sequences.
struct CarbonisDestruction524 {
    struct Particle {
        var point:Vec2
        var velocity:Vec2
        var life:Float
        let maxLife:Float
        let kind:Int
    }
    struct LightBurst {
        var point:Vec2
        var life:Float
        let maxLife:Float
        let kind:Int
    }
    struct Explosion {
        var point:Vec2
        let spawned:Float
        let scale:Float
        let kind:Int
    }
    struct CombatPiece {
        var point:Vec2
        var velocity:Vec2
        var life:Float
        let maxLife:Float
        var angle:Float
        let spin:Float
        let size:Float
        let kind:Int
    }

    // Exactly the original Game.cs / Explosion524.cs fixed budgets.
    static let maxParticles=512
    static let maxLights=24
    static let maxExplosions=32
    static let maxPieces=160
    static let maxSimultaneousVolumetric=3
    static let volumetricDuration:Float=4.8

    var particles:[Particle]=[]
    var lights:[LightBurst]=[]
    var explosions:[Explosion]=[]
    var pieces:[CombatPiece]=[]
    private var lightCursor=0
    private var explosionCursor=0

    mutating func tick(dt:Float) {
        guard dt>0 else{return}
        let drag=pow(Float(0.3),dt)
        for i in particles.indices.reversed() {
            particles[i].life-=dt
            if particles[i].life<=0 {
                particles.remove(at:i)
                continue
            }
            particles[i].point=Sphere67.advance(
                particles[i].point,
                velocity:&particles[i].velocity,dt:dt)
            particles[i].velocity=particles[i].velocity*drag
        }
        for i in lights.indices {
            lights[i].life=max(0,lights[i].life-dt)
        }
        for i in pieces.indices.reversed() {
            pieces[i].life-=dt
            if pieces[i].life<=0 {
                pieces.remove(at:i)
                continue
            }
            pieces[i].point=Sphere67.advance(
                pieces[i].point,
                velocity:&pieces[i].velocity,dt:dt)
            let resistance:Float=pieces[i].kind==0 ? 3.5 : 1.55
            pieces[i].velocity=pieces[i].velocity*exp(-dt*resistance)
            pieces[i].angle+=pieces[i].spin*dt
        }
    }

    /// Game.cs:121 Burst(p,count,kind), original [35,200] velocity,
    /// [.25,.8] lifetime and particle cap 512.
    mutating func burst(at point:Vec2,count:Int,kind:Int,
                        rng:inout MissionWave568.SourceRandom) {
        for _ in 0..<max(0,count) {
            if particles.count>=Self.maxParticles {break}
            let angle=rng.float(0,Float.pi*2)
            let magnitude=rng.float(35,200)
            let life=rng.float(0.25,0.8)
            particles.append(Particle(
                point:point,
                velocity:Vec2(x:cos(angle)*magnitude,
                              y:sin(angle)*magnitude),
                life:life,maxLife:life,kind:kind))
        }
    }

    /// Game.cs:122 circular 24-slot LightBurst pool.
    mutating func light(at point:Vec2,kind:Int,life:Float) {
        let value=LightBurst(point:point,life:life,
                             maxLife:life,kind:kind)
        if lights.count<Self.maxLights {
            lights.append(value)
        } else {
            lights[lightCursor%Self.maxLights]=value
        }
        lightCursor+=1
    }

    /// Game.cs:41-55 fixed 32-entry destruction queue.
    mutating func explosion(at point:Vec2,kind:Int,
                            scale:Float,time:Float) {
        let value=Explosion(point:point,spawned:time,
                            scale:max(3,scale),kind:max(0,min(2,kind)))
        if explosions.count<Self.maxExplosions {
            explosions.append(value)
        } else {
            explosions[explosionCursor%Self.maxExplosions]=value
        }
        explosionCursor+=1
    }

    /// Explosion524.cs:189–196: newest first, original gameplay budget3,
    /// explosion preset 0 duration2.6+1.6 = 4.2 seconds.
    func visibleExplosions(at time:Float,maxCount:Int=3,
                           duration:Float=4.2)->[Explosion] {
        var result:[Explosion]=[]
        for n in 0..<min(explosions.count,Self.maxExplosions) {
            let idx=(explosionCursor-1-n+Self.maxExplosions) %
                Self.maxExplosions
            if idx>=explosions.count {continue}
            let event=explosions[idx]
            let age=time-event.spawned
            if age<0 || age>min(Self.volumetricDuration,duration) {
                continue
            }
            result.append(event)
            if result.count>=max(1,min(6,maxCount)) {break}
        }
        return result
    }

    /// No old ring or depth glow beside a currently active volumetric
    /// event: Game.NearDestruction524.
    func nearDestruction(_ point:Vec2,time:Float)->Bool {
        for event in explosions {
            let age=time-event.spawned
            if age<0 || age>Self.volumetricDuration {continue}
            let delta=Sphere67.delta(target:point,origin:event.point)
            if delta.lengthSquared <
                pow(max(8,event.scale*0.6),Float(2)) {
                return true
            }
        }
        return false
    }

    /// CombatPieces125.cs:13-25: six orange/cyan impact streaks,
    /// plus optionally two metal fragments, bounded by 160.
    mutating func impact(at point:Vec2,shotVelocity:Vec2,
                         armored:Int,rng:inout MissionWave568.SourceRandom) {
        if pieces.count<=138 {
            let speed=sqrt(shotVelocity.lengthSquared)
            let angle=speed>0.01
                ? atan2(shotVelocity.y,shotVelocity.x)
                : rng.float(0,Float.pi*2)
            let forward=Vec2(x:cos(angle),y:sin(angle))
            for _ in 0..<6 {
                let direction=rng.float(0,Float.pi*2)
                let ray=Vec2(x:cos(direction),y:sin(direction))
                let velocity=ray*rng.float(38,115) -
                    forward*rng.float(10,38)
                pieces.append(CombatPiece(
                    point:point,velocity:velocity,
                    life:0.19+rng.float(0,0.18),maxLife:0.37,
                    angle:rng.float(0,Float.pi*2),
                    spin:rng.float(-9,9),size:rng.float(1.2,2.8),
                    kind:0))
            }
            if armored>0 && pieces.count<142 {
                for _ in 0..<2 {
                    let angle=rng.float(0,Float.pi*2)
                    let travel=rng.float(35,88)
                    pieces.append(CombatPiece(
                        point:point,
                        velocity:Vec2(x:cos(angle)*travel,
                                      y:sin(angle)*travel),
                        life:0.6,maxLife:0.6,
                        angle:rng.float(0,Float.pi*2),
                        spin:rng.float(-8,8),
                        size:rng.float(2.3,4.4),kind:2))
                }
            }
        }
        light(at:point,kind:1,life:0.13)
    }

    /// CombatPieces125.cs:26–35: exactly eleven type2 angular 3D
    /// fighter shards of size8, travel[55,190]*.72, life[.95,2.1].
    mutating func breakApart(at center:Vec2,momentum:Vec2,
                             count:Int,size:Float,type:Int,
                             rng:inout MissionWave568.SourceRandom) {
        if pieces.count>125 {
            let remove=min(pieces.count-125,50)
            pieces.removeFirst(remove)
        }
        for i in 0..<count where pieces.count<Self.maxPieces {
            let a=(2*Float.pi*Float(i)/Float(max(1,count))) +
                rng.float(-0.27,0.27)
            let direction=Vec2(x:cos(a),y:sin(a))
            let travel=rng.float(55,190) *
                (size/16 > 0.6 ? 1 : 0.72)
            let offset=rng.float(2,size*0.46)
            let point=Sphere67.offset(center,by:direction*offset)
            let local=direction*travel+momentum*0.24
            let velocity=CarbonisBodyContact68.transported(
                local,from:center,to:point)
            let life=rng.float(0.95,2.1)
            let piece=CombatPiece(
                point:point,velocity:velocity,
                life:life,maxLife:2.1,
                angle:rng.float(0,2*Float.pi),
                spin:rng.float(-7.5,7.5),
                size:rng.float(size*0.13,size*0.31),kind:type)
            pieces.append(piece)
        }
        light(at:center,kind:1,life:0.72)
    }

    /// Game.cs:224–229, every destroyed rock except aging debris:
    /// Burst count 18/18/27, ring .9s, volume Kind1 scale 9/15/23.
    mutating func rockDestroyed(_ rock:SphereAsteroid556,time:Float,
                                rng:inout MissionWave568.SourceRandom) {
        if rock.shardLife>0 {
            burst(at:rock.position,count:3,kind:0,rng:&rng)
            return
        }
        let count=rock.size==1 ? 18 : rock.size*9
        burst(at:rock.position,count:count,kind:0,rng:&rng)
        light(at:rock.position,kind:0,life:0.9)
        explosion(at:rock.position,kind:1,
                  scale:rock.size==3 ? 23 : rock.size==2 ? 15 : 9,
                  time:time)
    }

    /// Game.cs:257–258, nonfatal asteroid hit.
    mutating func rockHit(_ rock:SphereAsteroid556,
                          rng:inout MissionWave568.SourceRandom) {
        burst(at:rock.position,count:3,kind:0,rng:&rng)
        light(at:rock.position,kind:0,life:0.13)
    }

    /// BossTunnelGame.cs:96, ordinary shooter: contact sparks, 11 real
    /// 3D pieces, burst22, ring .30, Explosion524 kind0 scale14.
    mutating func shooterHit(at point:Vec2,impactPoint:Vec2,
                             velocity:Vec2,momentum:Vec2,
                             defeated:Bool,time:Float,
                             rng:inout MissionWave568.SourceRandom) {
        impact(at:impactPoint,shotVelocity:velocity,
               armored:0,rng:&rng)
        if defeated {
            breakApart(at:point,momentum:momentum,
                       count:11,size:8,type:2,rng:&rng)
            burst(at:point,count:22,kind:1,rng:&rng)
            light(at:point,kind:1,life:0.3)
            explosion(at:point,kind:0,scale:14,time:time)
        } else {
            burst(at:point,count:3,kind:1,rng:&rng)
        }
    }
}