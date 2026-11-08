import Foundation

/// PC v580 Windows/src/H55Renderer.cs NpcRouteX525/Z525, v530 workshop
/// pause, v528 acceleration and v533/537 anatomical-forward yaw steering.
/// Full v532 player detour A*, v529 foot IK and v544 airlock collision
/// remain separate, unported systems.
struct H55Mechanic580 {
    enum Phase:Equatable {case idle, walking, workshop, completed, blocked}
    static let routeX:[Float]=[
        10.106,10.188,10.966,10.966,11.908,12.358,14.201,
        19.034,21.450,24.112,45.899,45.817,40.288,34.760,
        33.367,27.265,24.480,23.702,22.760,21.491,21.286,
        17.928,15.962,13.914,12.645,12.727,10.679,9.92480]
    static let routeZ:[Float]=[
        12.409,13.106,14.007,16.300,17.119,13.024,11.181,
        10.116,7.822,6.553,7.085,8.150,8.601,8.068,
        7.495,7.495,8.150,8.068,8.068,7.945,8.846,
        11.017,10.935,11.713,14.129,14.949,13.474,12.155]
    static let workshopIndex=11
    static let maximumSpeed:Float=1.18
    static let acceleration:Float=1.75
    static let braking:Float=2.80
    var x:Float=9.9248
    var z:Float=12.155
    private(set) var phase:Phase = .idle
    private(set) var goal=0
    private(set) var speed:Float=0
    private(set) var pause:Float=0
    private(set) var distance:Float=0
    private(set) var yaw:Float=0
    private(set) var anatomicalHeading:Float=0
    private(set) var calibrated=false
    static func wrap(_ angle:Float)->Float {
        atan2(sin(angle),cos(angle))
    }
    mutating func calibrate(anatomicalHeading heading:Float) {
        guard heading.isFinite else{return}
        anatomicalHeading=Self.wrap(heading)
        calibrated=true
    }
    private var talked=false
    private var completedOnce=false
    var moving:Bool {phase == .walking && speed>0.01}

    mutating func finishConversation() {
        // Source v526: merely approaching does not start a patrol.
        talked=true
        completedOnce=false
        phase = .idle
        goal=0
        speed=0
        pause=0
    }

    /// Use actual active H55 floor/GLB collision plus exclusion of player.
    /// If unsafe, stop instead of walking through GLB. Source A* is not
    /// emulated by an arbitrary shortcut.
    mutating func step(dt raw:Float,playerX:Float,playerZ:Float,
                       canWalk:(Float,Float)->Bool) {
        let dt=min(0.07,max(0,raw))
        guard dt>0 else{return}
        if phase == .idle {
            guard talked && calibrated && !completedOnce &&
                  hypot(playerX-x,playerZ-z)>2.5 else{return}
            phase = .walking
        }
        if phase == .workshop {
            pause=max(0,pause-dt)
            speed=max(0,speed-Self.braking*dt)
            if pause<=0 {phase = .walking}
            return
        }
        guard phase == .walking || phase == .blocked else{return}
        var advance=0
        while goal<Self.routeX.count-1 && goal != Self.workshopIndex &&
              advance<Self.routeX.count &&
              hypot(Self.routeX[goal]-x,Self.routeZ[goal]-z)<=0.18 {
            goal+=1;advance+=1
        }
        let destX=Self.routeX[goal],destZ=Self.routeZ[goal]
        let dx=destX-x,dz=destZ-z
        let d=hypot(dx,dz)
        let key=goal==Self.workshopIndex || goal==Self.routeX.count-1
        let tolerance:Float=key ? 0.03 : 0.18
        if d<=tolerance {
            if key {x=destX;z=destZ}
            if goal == Self.workshopIndex {
                pause=5
                phase = .workshop
                goal+=1
                speed=0
            } else if goal == Self.routeX.count-1 {
                completedOnce=true
                phase = .completed
                goal=0
                speed=0
            } else {goal+=1}
            return
        }
        // v533/537: the anatomical GLB direction (measured from
        // original ankle->toe bones) drives root yaw and movement;
        // a track heading is not itself the character facing direction.
        let trackHeading=atan2(dx,-dz)
        let desired=Self.wrap(anatomicalHeading-trackHeading)
        let error=Self.wrap(desired-yaw)
        let turn=max(-2.35*dt,min(2.35*dt,error))
        yaw=Self.wrap(yaw+turn)
        let steering=abs(Self.wrap(desired-yaw))
        let hardTurn=steering>1.48 ||
             (goal==0 && distance<0.01 && steering>0.24)
        if hardTurn {
            speed=max(0,speed-Self.braking*dt)
            return
        }
        let brakingLimit=sqrt(max(0,2*Self.braking*max(0,d-tolerance)))
        let cornerFactor=cos(min(1.47,steering))
        let base=key ? min(Self.maximumSpeed,brakingLimit) : Self.maximumSpeed
        let request=base*max(0.23,cornerFactor)
        if speed<request {speed=min(request,speed+Self.acceleration*dt)}
        else {speed=max(request,speed-Self.braking*dt)}
        let move=min(d,speed*dt)
        guard d>0 else{return}
        let facing=Self.wrap(anatomicalHeading-yaw)
        let nx=x+sin(facing)*move,nz=z-cos(facing)*move
        let playerClearance:Float=d>6 ? 0.97 : 0.82
        guard hypot(nx-playerX,nz-playerZ)>=playerClearance,
              canWalk(nx,nz) else {
            speed=max(0,speed-Self.braking*dt)
            phase = .blocked
            return
        }
        x=nx;z=nz;distance+=move
        phase = .walking
    }
}
