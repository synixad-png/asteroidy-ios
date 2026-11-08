import Foundation

/// Port of Windows PC v580 HubWalk375.StepHubWalk375 ground-plane physics,
/// HubWalkSweepSlide401 and step/snap constants from HubWalk375.cs.
/// Collision queries are supplied by the real active GLB scene, never by an
/// old pre-H55 box. Full H55FullCollision379 parity is not yet claimed.
struct H55Walk580 {
    static let eyes:Float=1.80
    static let bodyRadius:Float=0.34
    static let bodyHeight:Float=2.0
    static let stepUp:Float=0.50
    static let stepDown:Float=0.50
    static let walkSpeed:Float=3.5+50*0.016
    var x:Float=2
    var y:Float=0
    var z:Float=14
    var yaw:Float=0
    var pitch:Float=0
    var vx:Float=0
    var vz:Float=0
    var grounded=true

    mutating func look(deltaX:Float,deltaY:Float) {
        yaw+=deltaX*0.0028
        pitch=max(-1.35,min(1.35,pitch-deltaY*0.0025))
        if yaw>Float.pi*2 {yaw-=Float.pi*2}
        if yaw < -Float.pi*2 {yaw+=Float.pi*2}
    }

    /// Input is local (-1...1) X=right, Z=forward. Return path is only
    /// committed after every 5cm subdivision passes collision and support.
    mutating func step(dt raw:Float,forward rawF:Float,right rawR:Float,
                       sprint:Bool,
                       bodyClear:(Float,Float,Float)->Bool,
                       support:(Float,Float,Float)->Float?) {
        let dt=max(0,min(0.05,raw))
        guard dt>0 else{return}
        var forward=max(-1,min(1,rawF)),right=max(-1,min(1,rawR))
        let magnitude=hypot(forward,right)
        if magnitude>1 {forward/=magnitude;right/=magnitude}
        let hasInput=magnitude>0.001
        let speed=Self.walkSpeed*(sprint ? 1.55 : 1)
        let sy=sin(yaw),cy=cos(yaw)
        let wantX=hasInput ? (forward*sy+right*cy)*speed : 0
        let wantZ=hasInput ? (-forward*cy+right*sy)*speed : 0
        let response:Float=hasInput ? (grounded ? 17:5) : (grounded ? 16:3)
        let a:Float=1-exp(-response*dt)
        vx+=(wantX-vx)*a
        vz+=(wantZ-vz)*a
        if !hasInput && abs(vx)+abs(vz)<0.014 {vx=0;vz=0}
        let dx=vx*dt,dz=vz*dt
        let steps=max(1,min(20,Int(ceil(hypot(dx,dz)/0.05))))
        for _ in 0..<steps {
            let sx=dx/Float(steps),sz=dz/Float(steps)
            if !move(sx,sz,bodyClear:bodyClear,support:support) {
                // Source 401: attempt independent wall-tangent axis motion,
                // no speculative penetration or speed increase.
                let movedX=move(sx,0,bodyClear:bodyClear,support:support)
                let movedZ=move(0,sz,bodyClear:bodyClear,support:support)
                if !movedX && !movedZ {vx=0;vz=0;break}
            }
        }
    }

    @discardableResult
    private mutating func move(_ dx:Float,_ dz:Float,
                               bodyClear:(Float,Float,Float)->Bool,
                               support:(Float,Float,Float)->Float?)->Bool {
        let nx=x+dx,nz=z+dz
        guard nx.isFinite && nz.isFinite else{return false}
        // Same conservative sector/workshop bounds as v580 HubWalkValid375.
        let hall=(nx>=22.9 && nx<=31.9 && nz>=4.20 && nz<=10.2)
        let workshop=(nx>=30.5 && nx<=53.8 && nz>=(-1.35) && nz<=15.6)
        if !hall && !workshop &&
           (nx < -23.52 || nx>23.52 || nz < -16.82 || nz>16.62) {
            return false
        }
        guard let floor=support(nx,nz,y), floor.isFinite,
              floor-y<=Self.stepUp+0.0001,
              y-floor<=Self.stepDown+0.0001,
              bodyClear(nx,floor,nz) else {return false}
        x=nx;y=floor;z=nz
        return true
    }
}
