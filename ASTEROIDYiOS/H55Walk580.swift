import Foundation

/// PC v580 Windows/src/HubWalk375.cs: grounded movement, steps, stair ramp,
/// ring-voted support, short ledge recovery and visual camera smoothing.
/// Only authentic H02-H04 collision queries are consulted; flight is isolated.
struct H55Walk580 {
    static let eyes:Float=1.80, bodyRadius:Float=0.34, bodyHeight:Float=2
    static let stepUp:Float=0.50, stepDown:Float=0.50
    static let gravity:Float=18, firstJumpHeight:Float=1.15, secondJumpHeight:Float=3.45
    static let walkSpeed:Float=3.5+50*0.016
    var x:Float=2, y:Float=0, z:Float=14
    var yaw:Float=0, pitch:Float=0
    var vx:Float=0, vz:Float=0, vy:Float=0
    var grounded=true
    private(set) var jumps=0
    private(set) var cameraFeet:Float=0
    private(set) var cameraReady=false
    private(set) var bobPhase:Float=0, bobAmount:Float=0, stride:Float=0, lean:Float=0
    private var aheadX:Float=0, aheadZ:Float=0
    private var blockedTicks=0
    private var stepApproach=false
    private var stepTop:Float=0, stepTravel:Float=0, stepAge:Float=0

    mutating func placeAtSpawn(feet:Float) {
        y=feet; cameraFeet=feet; cameraReady=true
    }
    private func clear(_ p:H55SpatialSupport580,_ px:Float,_ py:Float,_ pz:Float)->Bool {
        p.bodyClear379(px,feet:py,pz)
    }
    private func support(_ p:H55SpatialSupport580,_ px:Float,_ pz:Float,
                         _ low:Float,_ high:Float)->Float? {
        // HubWalkSupport379: CENTER is authoritative; ring heights need votes.
        guard let top=p.support(px,pz,low:low,high:high) else {
            var highest = -Float.infinity
            for i in 0..<8 {
                let a=Float(i)*Float.pi/4
                if let h=p.support(px+cos(a)*0.325,pz+sin(a)*0.325,low:low,high:high) {
                    highest=max(highest,h)
                }
            }
            if px*px+pz*pz<3.95*3.95 && low<=2.4 && high>=2.4 {
                highest=max(highest,2.4)
            }
            return highest.isFinite ? highest : nil
        }
        var result=top, votes=0, highest = -Float.infinity
        let base=p.supportLowest403(px,pz,low:low,high:high)
        for i in 0..<8 {
            let a=Float(i)*Float.pi/4
            guard let h=p.support(px+cos(a)*0.325,pz+sin(a)*0.325,
                                  low:low,high:high) else{continue}
            highest=max(highest,h)
            if abs(h-top)<=0.048 {votes+=1}
        }
        if let base,top-base>0.055,votes<3 {
            if !narrowTread(p,px,pz,base,top) {result=base}
        } else if highest>result+0.04 {
            var agreeing=0
            for i in 0..<8 {
                let a=Float(i)*Float.pi/4
                if let h=p.support(px+cos(a)*0.325,pz+sin(a)*0.325,
                                   low:low,high:high),
                   abs(h-highest)<=0.045 {agreeing+=1}
            }
            if agreeing>=3 {result=highest}
        }
        if px*px+pz*pz<3.95*3.95 && low<=2.4 && high>=2.4 {
            result=max(result,2.4)
        }
        return result
    }
    private func narrowTread(_ p:H55SpatialSupport580,_ x:Float,_ z:Float,
                             _ lower:Float,_ top:Float)->Bool {
        guard top-lower>=0.055,top-lower<=Self.stepUp+0.0001,
              clear(p,x,top,z) else{return false}
        var votes=0
        let offsets:[(Float,Float)]=[(0.095,0),(-0.095,0),(0,0.095),(0,-0.095)]
        for (ox,oz) in offsets {
            if let h=p.support(x+ox,z+oz,low:top-0.035,high:top+0.035),
               abs(h-top)<0.035 {votes+=1}
        }
        return votes>=3
    }
    private static func stairRamp(_ x:Float,_ z:Float)->Float? {
        if abs(x)<17.35 || abs(x)>18.65 || z<9.65 || z>16.95 {return nil}
        let h:Float = z>=16.65 ? 0.10+(16.95-z)*0.55 : 0.265+(16.65-z)*0.92
        return min(6.03,max(0.10,h))
    }
    private static func onStairs(_ x:Float,_ z:Float)->Bool {
        abs(x)>=17.2 && abs(x)<=18.75 && z>=9.8 && z<=16.8
    }
    private func escapePenetration(_ p:H55SpatialSupport580,_ nx:Float,_ nz:Float)->Bool {
        let before=p.penetration382(x,feet:y,z)
        if before<=0 || before>=100_000 {return false}
        let after=p.penetration382(nx,feet:y,nz)
        return after>=0 && after<before-0.00001
    }
    private func escapePath(_ p:H55SpatialSupport580,_ nx:Float,_ nz:Float,_ newY:Float)->Bool {
        guard clear(p,x,y,z) else{return false}
        let dist=hypot(nx-x,nz-z)
        let n=max(1,Int(ceil(dist/0.035)))
        for i in 1...n {
            let f=Float(i)/Float(n)
            if !clear(p,x+(nx-x)*f,y,z+(nz-z)*f) {return false}
        }
        let vertical=max(1,Int(ceil(abs(newY-y)/0.035)))
        for i in 1...vertical {
            let f=Float(i)/Float(vertical)
            if !clear(p,nx,y+(newY-y)*f,nz) {return false}
        }
        return true
    }
    private func findClear(_ p:H55SpatialSupport580,_ target:Float,
                           landing:Bool)->(Float,Float)? {
        if clear(p,x,target,z) {return (x,z)}
        let a0=atan2(aheadZ,aheadX)
        for ring in 1...7 {
            let r=Float(ring)*0.05
            for a in 0..<24 {
                let angle=a0+Float(a)*Float.pi/12
                let xx=x+r*cos(angle),zz=z+r*sin(angle)
                if !clear(p,xx,target,zz) || !escapePath(p,xx,zz,target) {continue}
                if landing {
                    guard let floor=p.support(xx,zz,low:target-0.035,high:target+0.035),
                          abs(floor-target)<=0.035 else{continue}
                }
                return (xx,zz)
            }
        }
        return nil
    }
    @discardableResult private mutating func land(_ p:H55SpatialSupport580,_ feet:Float)->Bool {
        guard let found=findClear(p,feet,landing:true) else{return false}
        x=found.0;z=found.1;y=feet;vy=0;jumps=0;grounded=true
        return true
    }
    @discardableResult private mutating func recover(_ p:H55SpatialSupport580,
                                                      _ dx:Float,_ dz:Float,
                                                      jumpPath:Bool=false)->Bool {
        if clear(p,x,y,z) || p.penetration382(x,feet:y,z)>=100_000 {return false}
        let length=hypot(dx,dz)
        let angle0:Float=length<0.00001 ? 0 : atan2(dz,dx)
        for ring in 1...7 {
            let r=Float(ring)*0.05
            for a in 0..<16 {
                let angle=angle0+Float(a)*Float.pi/8
                let xx=x+r*cos(angle),zz=z+r*sin(angle)
                if !clear(p,xx,y,zz) {continue}
                if jumpPath {
                    var overhead=true
                    for sample in 1...12 {
                        if !clear(p,xx,y+Float(sample)*0.1,zz) {overhead=false;break}
                    }
                    if !overhead {continue}
                }
                x=xx;z=zz
                if support(p,xx,zz,y-Self.stepDown,y+0.02)==nil {grounded=false}
                blockedTicks=0
                return true
            }
        }
        return false
    }
    @discardableResult mutating func jump(collision p:H55SpatialSupport580)->Bool {
        guard jumps<2 else{return false}
        if !clear(p,x,y,z) {_=recover(p,aheadX,aheadZ,jumpPath:true)}
        if grounded,
           let floor=support(p,x,z,y-0.12,y+Self.stepUp),
           clear(p,x,floor,z) {y=max(y,floor)}
        stepApproach=false
        vy=sqrt(2*Self.gravity*(jumps==0 ? Self.firstJumpHeight : Self.secondJumpHeight))
        jumps+=1;grounded=false
        return true
    }
    mutating func look(deltaX:Float,deltaY:Float) {
        yaw+=deltaX*0.0028
        pitch=max(-1.35,min(1.35,pitch-deltaY*0.0025))
        if yaw>2*Float.pi {yaw-=2*Float.pi}
        if yaw < -2*Float.pi {yaw+=2*Float.pi}
    }
    private mutating func vertical(_ p:H55SpatialSupport580,_ t:Float) {
        if grounded,let ramp=Self.stairRamp(x,z),
           abs(y-ramp)<0.23,clear(p,x,ramp,z) {
            y=ramp;vy=0;jumps=0;return
        }
        if stepApproach && grounded {
            if let upper=p.support(x,z,low:stepTop-0.055,high:stepTop+0.045),
               clear(p,x,upper,z) {
                y=upper;stepApproach=false;vy=0;jumps=0;return
            }
            stepAge+=t
            if stepAge<0.36 && stepTravel<0.57 && clear(p,x,stepTop,z) {
                y=stepTop;vy=0;return
            }
            stepApproach=false
        }
        let current=support(p,x,z,y-Self.stepDown,y+0.02)
        if grounded,let floor=current,
           y-floor>=0,y-floor<=Self.stepDown+0.0001,land(p,floor) {return}
        grounded=false
        let from=y
        var to=from+vy*t-0.5*Self.gravity*t*t
        vy-=Self.gravity*t
        if vy<=0,let floor=support(p,x,z,to-0.04,from+0.015),
           floor<=from+0.015,land(p,floor) {return}
        if to>from && !clear(p,x,to,z) {
            if let found=findClear(p,to,landing:false) {x=found.0;z=found.1}
            else {vy=0;to=from}
        }
        if to<from && !clear(p,x,to,z) {
            if let found=findClear(p,to,landing:false) {x=found.0;z=found.1}
            else {to=from;vy=0}
        }
        y=max(0,to)
        if y<=0 {y=0;vy=0;jumps=0;grounded=true}
    }
    private func leadingStep(_ p:H55SpatialSupport580,_ xx:Float,_ zz:Float,
                             _ dx:Float,_ dz:Float,_ base:Float)->Float? {
        let dist=hypot(dx,dz)
        if dist<0.000001 {return nil}
        let ux=dx/dist,uz=dz/dist,sx = -uz,sz=ux
        for probe in [Float(0.34),0.44,0.56] {
            let px=xx+ux*probe,pz=zz+uz*probe
            guard let h=p.support(px,pz,low:base+0.045,high:base+Self.stepUp-0.001),
                  h-base>=0.055,h-base<=Self.stepUp+0.0001 else{continue}
            guard let l=p.support(px+sx*0.14,pz+sz*0.14,low:h-0.055,high:h+0.035),
                  let r=p.support(px-sx*0.14,pz-sz*0.14,low:h-0.055,high:h+0.035),
                  abs(l-h)<=0.055,abs(r-h)<=0.055,
                  clear(p,x,h,z) else{continue}
            var swept=true
            let vertical=max(1,Int(ceil((h-base)/0.05)))
            for i in 1...vertical {
                if !clear(p,x,base+(h-base)*Float(i)/Float(vertical),z) {swept=false;break}
            }
            if !swept {continue}
            let horizontal=max(1,Int(ceil((probe+dist)/0.05)))
            for i in 1...horizontal {
                let d=(dist+probe)*Float(i)/Float(horizontal)
                if !clear(p,x+ux*d,h,z+uz*d) {swept=false;break}
            }
            if swept {return h}
        }
        return nil
    }
    /// Source MoveHubAxis379: stair ramp, improving depenetration,
    /// verified 50cm step and leading-edge step approach.
    private mutating func moveAxis(_ p:H55SpatialSupport580,_ dx:Float,_ dz:Float) {
        if abs(dx)+abs(dz)<0.000001 {return}
        let nx=x+dx,nz=z+dz,base=y
        if grounded,let ramp=Self.stairRamp(nx,nz),
           (Self.onStairs(x,z) || abs(ramp-base)<=Self.stepUp+0.015),
           abs(ramp-base)<0.23,clear(p,nx,ramp,nz) {
            x=nx;z=nz;y=ramp;vy=0;return
        }
        let free=clear(p,nx,base,nz)
        if !free && escapePenetration(p,nx,nz) {
            x=nx;z=nz;return
        }
        if !free && grounded {
            let floor=support(p,nx,nz,base-0.03,base+Self.stepUp) ?? base
            let rise=floor-base
            if rise<=0.025 || rise>Self.stepUp+0.0001 {
                if let leading=leadingStep(p,nx,nz,dx,dz,base),
                   clear(p,nx,leading,nz) {
                    stepApproach=true;stepTop=leading;stepTravel=0;stepAge=0
                    x=nx;z=nz;y=leading;vy=0
                }
                return
            }
            guard let direct=p.support(nx,nz,low:base+0.020,high:base+Self.stepUp),
                  abs(direct-floor)<=0.045,
                  clear(p,nx,floor,nz),
                  clear(p,x,floor,z),
                  clear(p,(x+nx)*0.5,floor,(z+nz)*0.5) else{return}
            x=nx;z=nz;y=floor;vy=0
            return
        }
        if !free {return}
        x=nx;z=nz
        if grounded {
            if stepApproach {
                if let top=p.support(nx,nz,low:stepTop-0.055,high:stepTop+0.045),
                   clear(p,nx,top,nz) {
                    y=top;stepApproach=false
                }
                return
            }
            if let floor=support(p,nx,nz,base-Self.stepDown,base+Self.stepUp) {
                let d=floor-base
                if d>0.025 && d<=Self.stepUp+0.0001 && clear(p,nx,floor,nz) {y=floor}
                else if d < -0.02 && -d<=Self.stepDown+0.0001 && clear(p,nx,floor,nz) {
                    y=floor
                }
            }
        }
    }
    private static func smoothCamera(_ old:Float,_ real:Float,_ dt:Float,_ onFloor:Bool)->Float {
        if !onFloor || abs(real-old)>1.35 {return real}
        let response:Float=real>old ? 10.5 : 13
        let alpha:Float=1-exp(-response*max(0,min(0.05,dt)))
        let result=old+(real-old)*alpha
        return abs(real-result)<0.0003 ? real : result
    }
    private mutating func updateCamera(_ p:H55SpatialSupport580,_ t:Float) {
        if !cameraReady {cameraFeet=y;cameraReady=true;return}
        var requested=Self.smoothCamera(cameraFeet,y,t,grounded || jumps==0)
        if !p.cameraClear406(x,requested+Self.eyes,z,radius:0.095) {requested=y}
        cameraFeet=requested
    }
    /// Exactly PC StepHubWalk375 with H04 swept 5cm triangle contacts.
    /// Movement and camera use different foot heights, never vice-versa.
    mutating func step(dt raw:Float,forward rawF:Float,right rawR:Float,
                       sprint:Bool,collision p:H55SpatialSupport580) {
        let t=max(0,min(0.05,raw))
        if t<=0 {return}
        vertical(p,t)
        var f=rawF,r=rawR
        let length=hypot(f,r)
        if length>1 {f/=length;r/=length}
        let hasInput=length>0.001
        let sy=sin(yaw),cy=cos(yaw)
        let speed=Self.walkSpeed*(sprint ? 1.55 : 1)
        let wantX=hasInput ? (f*sy+r*cy)*speed : 0
        let wantZ=hasInput ? (-f*cy+r*sy)*speed : 0
        let response:Float=hasInput ? (grounded ? 17:5) : (grounded ? 16:3)
        let alpha:Float=1-exp(-response*t)
        vx+=(wantX-vx)*alpha;vz+=(wantZ-vz)*alpha
        if !hasInput && abs(vx)+abs(vz)<0.014 {vx=0;vz=0}
        let dx=vx*t,dz=vz*t,dist=hypot(dx,dz)
        if dist>0.000001 {aheadX=dx/dist;aheadZ=dz/dist}
        let x0=x,z0=z
        var state=self
        let origin=H55Sweep401580.Position(x:x,feet:y,z:z)
        _=H55Sweep401580.sweep(collision:p,from:origin,vx:dx,vz:dz,
                                moveHubAxis:{_,sx,sz in
            state.moveAxis(p,sx,sz)
            return H55Sweep401580.Position(x:state.x,feet:state.y,z:state.z)
        })
        self=state
        updateCamera(p,t)
        let movedX=x-x0,movedZ=z-z0,moved=hypot(movedX,movedZ)
        if stepApproach {stepTravel+=moved}
        let target:Float=grounded && moved>0.00005 ? min(1,(moved/t)/max(1,Self.walkSpeed)) : 0
        let rate:Float=target>bobAmount ? 9 : 12
        bobAmount+=(target-bobAmount)*(1-exp(-rate*t))
        if bobAmount<0.001 {bobAmount=0}
        if grounded && moved>0.00005 {
            let speedActual=moved/t
            let strideLength=max(0.9,min(1.95,0.9+0.14*max(0,speedActual)))
            bobPhase+=moved*Float.pi/strideLength
            stride+=moved
        }
        let rightward:Float=moved>0.000001 ? (movedX*cy+movedZ*sy)/moved : 0
        let leanTarget:Float=grounded ? rightward*bobAmount : 0
        lean+=(leanTarget-lean)*(1-exp(-8*t))
        if !hasInput && bobAmount==0 {lean=0}
        if moved*moved<0.00000002 {
            if !clear(p,x,y,z) {
                blockedTicks+=1
                if blockedTicks>=4 {_=recover(p,dx,dz)}
            } else {blockedTicks=0}
        } else {blockedTicks=0}
    }
}
