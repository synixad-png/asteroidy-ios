import Foundation

/// PC v580 HangarDrone451.cs / DronePilot453 / StepHangarDrone451.
/// Two H71 prefabs; no procedural drone meshes, teleports through walls
/// or independent SceneKit animation clocks. Navigation is built ONCE.
final class H55DroneFlight580 {
    struct Player {
        let walking:Bool
        let position:SIMD3<Float>
        let yaw:Float
    }
    struct Pilot {
        let id:Int
        var seed:UInt32
        var position:SIMD3<Float>
        var velocity=SIMD3<Float>(repeating:0)
        var home:SIMD3<Float>
        var target:SIMD3<Float>
        var last:SIMD3<Float>
        var yaw:Float=0,pitch:Float=0,roll:Float=0
        var time:Float=0,visitIn:Float=0,hover:Float=0
        var progress:Float=0,deadline:Float=0,blocked:Float=0
        var visualScale:Float=1,lookahead:Float=0
        var active=true,takeoff=true,returning=false,visiting=false,launchEgress=false
        var exit:Int,goal:Int = -1,region:Int = -1
        var path:[Int]=[],pathAt:Int=0,visits=0,stalls=0,rescuePhase=0

        mutating func rand()->Float {
            seed=seed &* 1664525 &+ 1013904223
            return Float(seed)/4294967295
        }
    }
    private(set) var pilots:[Pilot]
    private(set) var returns=0,stalls=0
    private var accumulator:Float=0
    private let nav:H55DroneNavigation580
    static func distance(_ a:SIMD3<Float>,_ b:SIMD3<Float>)->Float {
        let d=a-b
        return sqrt(d.x*d.x+d.y*d.y+d.z*d.z)
    }
    private static func vectorLength(_ v:SIMD3<Float>)->Float {
        sqrt(v.x*v.x+v.y*v.y+v.z*v.z)
    }
    private static func clamp(_ v:Float,_ lower:Float,_ upper:Float)->Float {
        min(upper,max(lower,v))
    }

    /// BindHangarDroneImports461: both must pass safe source takeoff,
    /// otherwise no model is reclassified as a dynamic flying actor.
    init?(navigation:H55DroneNavigation580,
          spawns:[H55DroneImports580.Spawn]) {
        guard spawns.count==2 else{return nil}
        var all=[Pilot]()
        for (id,spawn) in spawns.enumerated() {
            guard let launch=navigation.launch(
                SIMD3<Float>(spawn.x,spawn.y,spawn.z)) else{return nil}
            let home=SIMD3<Float>(spawn.x,launch.y,spawn.z)
            var pilot=Pilot(id:id,seed:UInt32(45301+id*1949),
                position:home,home:home,
                target:home+SIMD3<Float>(0,2,0),
                last:home,exit:launch.exit)
            pilot.visitIn=(id==0 ? 38 : 53)+pilot.rand()*25
            all.append(pilot)
        }
        nav=navigation
        pilots=all
    }

    private func plan(_ p:inout Pilot,goal:Int)->Bool {
        guard nav.nodes.indices.contains(goal),
              let start=nav.closest(to:p.position,
                  component:nav.nodes[goal].component) else{return false}
        let path=nav.route(from:start,to:goal)
        guard !path.isEmpty else{return false}
        p.path=path;p.pathAt=0;p.goal=goal
        p.deadline=30;p.lookahead=0
        p.target=nav.position(path[0])
        return true
    }
    private func newPatrol(_ p:inout Pilot) {
        p.returning=false;p.visiting=false;p.hover=0
        guard let start=nav.closest(to:p.position) else {
            recover(&p);return
        }
        let component=nav.nodes[start].component
        var best:Int?,score:Float = -.infinity
        let desired=p.region==2 ? 0 : p.id==0 && p.region<0 ? 0 : 2
        for _ in 0..<90 {
            let i=min(nav.nodes.count-1,
                      Int(p.rand()*Float(nav.nodes.count)))
            let n=nav.nodes[i]
            if !n.open || n.component != component {continue}
            let dist=Self.distance(p.position,nav.position(i))
            if dist<9 {continue}
            let region=n.x>32 ? 2 : n.x>18 ? 1 : 0
            let value=dist*0.65+p.rand()*15+(region==desired ? 100:0)
            if value>score {best=i;score=value}
        }
        if best==nil {
            best=nav.nodes.indices.first(where:{
                nav.nodes[$0].open &&
                nav.nodes[$0].component==component})
        }
        if let best,plan(&p,goal:best) {
            let x=nav.nodes[best].x
            p.region=x>32 ? 2 : x>18 ? 1 : 0
        } else {p.active=false;p.path=[]}
    }
    private func rescue(_ p:inout Pilot) {
        guard p.rescuePhase==0 else{return}
        p.rescuePhase=1;p.velocity=SIMD3<Float>(repeating:0)
        p.hover=0;p.lookahead=0;p.path=[];p.pathAt=0
    }
    private func recover(_ p:inout Pilot) {
        p.returning=true;p.visiting=false;p.hover=0
        p.stalls+=1;stalls+=1
        let raised=p.home+SIMD3<Float>(0,2,0)
        if let home=nav.closest(to:raised),
           plan(&p,goal:home) {
            var length:Float=0,previous=p.position
            for id in p.path {
                let waypoint=nav.position(id)
                length+=Self.distance(previous,waypoint)
                previous=waypoint
            }
            p.deadline=max(28,length/2.1+14)
        } else {
            rescue(&p)
        }
    }
    private func finishRescue(_ p:inout Pilot,other:Pilot) {
        let location=p.home+SIMD3<Float>(0,2,0)
        var spawn=location
        var free=nav.airspace(location.x,location.y,location.z)
        if other.active && other.visualScale>0.15 &&
           Self.distance(location,other.position)<2.3 {free=false}
        if !free {
            var best:Float = .infinity
            var candidate:Int?
            for id in nav.nodes.indices where nav.nodes[id].open {
                let proposed=nav.position(id)
                let dist=Self.distance(proposed,location)
                if dist>8 || dist>=best {continue}
                if other.active && other.visualScale>0.15 &&
                   Self.distance(proposed,other.position)<2.3 {continue}
                best=dist;candidate=id
            }
            guard let id=candidate else{return}
            spawn=nav.position(id)
        }
        p.position=spawn;p.velocity=SIMD3<Float>(repeating:0)
        p.returning=false;p.visiting=false;p.takeoff=false
        p.path=[];p.pathAt=0
        p.deadline=0;p.progress=0;p.blocked=0;p.last=spawn
        p.rescuePhase=2;returns+=1
    }
    private func stepRescue(_ p:inout Pilot,other:Pilot,dt:Float) {
        if p.rescuePhase==1 {
            p.visualScale=max(0,p.visualScale-dt*2.4)
            if p.visualScale<=0 {finishRescue(&p,other:other)}
        } else if p.rescuePhase==2 {
            p.visualScale=min(1,p.visualScale+dt*1.65)
            if p.visualScale>=1 {
                p.rescuePhase=0;p.returning=false
                newPatrol(&p)
            }
        }
    }
    private func lookAhead(_ p:inout Pilot,dt:Float) {
        guard p.pathAt<p.path.count else{return}
        p.lookahead-=dt
        guard p.lookahead<=0 else{return}
        p.lookahead=0.16
        var best=p.pathAt
        let end=min(p.pathAt+4,p.path.count-1)
        if end>best {
            for i in (best+1)...end {
                if !nav.segment(p.position,nav.position(p.path[i])) {break}
                best=i
            }
        }
        p.pathAt=best
    }
    private func moveClear(_ p:Pilot,to point:SIMD3<Float>,
                           other:Pilot)->Bool {
        guard nav.segment(p.position,point,takeoff:p.takeoff) else{return false}
        if other.active && other.rescuePhase==0 &&
           Self.distance(point,other.position)<1.48 {return false}
        return true
    }
    private func visit(_ p:inout Pilot,player:Player)->Bool {
        guard player.walking else{return false}
        let x=player.position.x+cos(player.yaw)*2.55
        let z=player.position.z+sin(player.yaw)*2.55
        let y=Self.clamp(player.position.y+2.7,2.8,5.9)
        guard nav.airspace(x,y,z),
              let nearest=nav.closest(to:SIMD3<Float>(x,y,z)),
              plan(&p,goal:nearest) else{return false}
        p.visiting=true;p.returning=false;p.hover=0
        return true
    }
    private func step(_ p:inout Pilot,other:Pilot,dt:Float,
                      player:Player) {
        guard p.active else{return}
        p.time+=dt
        if p.rescuePhase != 0 {
            stepRescue(&p,other:other,dt:dt);return
        }
        if p.takeoff {
            if !p.launchEgress {
                p.target=p.home+SIMD3<Float>(0,2,0)
                if p.position.y>=p.target.y-0.05 &&
                   abs(p.velocity.y)<0.25 {
                    p.position.y=p.target.y
                    p.velocity=SIMD3<Float>(repeating:0)
                    if nav.airspace(p.position.x,p.position.y,p.position.z) {
                        p.takeoff=false
                        newPatrol(&p)
                    } else {
                        p.launchEgress=true
                        p.target=nav.position(p.exit)
                    }
                }
            } else if Self.distance(p.target,p.position)<0.32 &&
                      nav.airspace(p.position.x,p.position.y,p.position.z) {
                p.takeoff=false;p.launchEgress=false
                newPatrol(&p)
            }
        } else {
            p.visitIn-=dt
            if p.returning {
                p.deadline-=dt
                if p.deadline<=0 {rescue(&p);return}
            } else if p.hover>0 {
                p.hover-=dt
                if p.hover<=0 {
                    p.visiting=false;p.visitIn=38+p.rand()*34
                    newPatrol(&p)
                }
            } else if p.visitIn<=0 && player.walking &&
                      !p.visiting && !p.returning {
                if !visit(&p,player:player) {p.visitIn=11+p.rand()*15}
            }
            if p.hover<=0 {lookAhead(&p,dt:dt)}
            if p.hover<=0 && p.pathAt<p.path.count {
                p.target=nav.position(p.path[p.pathAt])
                if Self.distance(p.position,p.target)<0.55 {
                    p.pathAt+=1;p.lookahead=0
                }
            } else if p.hover<=0 && p.pathAt>=p.path.count {
                if p.returning {
                    p.returning=false;p.visitIn=38+p.rand()*28
                    returns+=1;newPatrol(&p)
                } else if p.visiting {
                    p.hover=3+p.rand()*3;p.visits+=1
                } else {
                    newPatrol(&p)
                }
            }
            p.progress+=dt
            if p.progress>=3.5 {
                let travel=Self.distance(p.position,p.last)
                if p.hover<=0 && travel<0.85 {
                    if p.returning {rescue(&p)}
                    else {recover(&p)}
                }
                p.progress=0;p.last=p.position
            }
        }
        let delta=p.target-p.position
        let distance=Self.vectorLength(delta)
        let maxSpeed:Float=p.returning ? 4.7 : 3.35
        let brake:Float=p.returning ? 4.6 : 3.0
        var speed=min(maxSpeed,sqrt(max(0,2*brake*distance)))
        if p.takeoff {speed=min(1.75,speed)}
        if p.visiting {speed=min(speed,2.35)}
        if p.hover>0 {speed=0}
        var direction=distance>0.0001
            ? delta/distance : SIMD3<Float>(repeating:0)
        if other.active {
            let separation=p.position-other.position
            let gap=Self.vectorLength(separation)
            if gap<2.2 && gap>0.01 {
                let factor=(2.2-gap)/2.2
                direction+=SIMD3<Float>(
                    separation.x/gap*factor*1.8,
                    separation.y/gap*factor*0.7,
                    separation.z/gap*factor*1.8)
            }
        }
        let dirLength=Self.vectorLength(direction)
        if dirLength>0.00001 {direction/=dirLength}
        var acceleration=direction*speed-p.velocity
        let maxStep:Float=(p.returning ? 5.2 : 3.1)*dt
        let accelLength=Self.vectorLength(acceleration)
        if accelLength>maxStep && accelLength>0.0001 {
            acceleration*=maxStep/accelLength
        }
        let previous=p.velocity
        p.velocity+=acceleration
        let next=p.position+p.velocity*dt
        if moveClear(p,to:next,other:other) {
            p.position=next;p.blocked=0
        } else {
            // Source v455 attempts orthogonal wall slides, then recovery.
            let x=SIMD3<Float>(next.x,p.position.y,p.position.z)
            let z=SIMD3<Float>(p.position.x,p.position.y,next.z)
            let y=SIMD3<Float>(p.position.x,next.y,p.position.z)
            if moveClear(p,to:x,other:other) {
                p.position=x;p.velocity.y=0;p.velocity.z=0;p.blocked=0
            } else if moveClear(p,to:z,other:other) {
                p.position=z;p.velocity.x=0;p.velocity.y=0;p.blocked=0
            } else if moveClear(p,to:y,other:other) {
                p.position=y;p.velocity.x=0;p.velocity.z=0;p.blocked=0
            } else {
                p.velocity=SIMD3<Float>(repeating:0)
                p.blocked+=dt
                if p.blocked>1.35 {
                    p.blocked=0
                    if p.returning {rescue(&p)}
                    else {recover(&p)}
                    return
                }
            }
        }
        if player.walking {
            let px=p.position.x-player.position.x
            let pz=p.position.z-player.position.z
            if hypot(px,pz)<1.5 &&
               abs(p.position.y-(player.position.y+1.8))<1.2 {
                p.velocity.x=0;p.velocity.z=0
                if !p.returning && !p.takeoff {recover(&p)}
                return
            }
        }
        let horizontal=hypot(p.velocity.x,p.velocity.z)
        let smooth:Float=1-exp(-dt*5)
        if horizontal>0.10 {
            let targetYaw=atan2(p.velocity.x,-p.velocity.z)*180/Float.pi
            var turn=(targetYaw-p.yaw+540).truncatingRemainder(dividingBy:360)-180
            if turn < -180 {turn+=360}
            p.yaw+=Self.clamp(turn,-95*dt,95*dt)
        }
        let yaw=p.yaw*Float.pi/180
        let ax=(p.velocity.x-previous.x)/max(0.001,dt)
        let az=(p.velocity.z-previous.z)/max(0.001,dt)
        let lateral=ax*cos(yaw)+az*sin(yaw)
        let forward=ax*sin(yaw)-az*cos(yaw)
        let targetPitch=Self.clamp(-forward*2-p.velocity.y*1.2,-12,12)
        let targetRoll=Self.clamp(-lateral*3.2,-17,17)
        p.pitch+=(targetPitch-p.pitch)*smooth
        p.roll+=(targetRoll-p.roll)*smooth
    }

    /// Source fixed 0.01-second steps; six substeps/frame, no unbounded
    /// catch-up or frame-rate-dependent orientation/clearance changes.
    func advance(dt:Float,player:Player) {
        guard dt.isFinite,dt>0 else{return}
        accumulator+=Self.clamp(dt,0,0.06)
        for _ in 0..<6 {
            guard accumulator>=0.009999 else{break}
            for id in pilots.indices {
                var pilot=pilots[id]
                step(&pilot,other:pilots[1-id],dt:0.01,player:player)
                pilots[id]=pilot
            }
            accumulator-=0.01
        }
    }
}
