import Foundation

/// PC v580 Windows/src/H55Renderer.cs NpcRouteX525/Z525, v530 workshop
/// pause, v528 acceleration and v533/537 anatomical-forward yaw steering.
/// Uses the original v532 player-avoidance A* from H55NpcDetour580.
/// H08 route/clearance are sourced from PC v580; H09 will own Foot IK.
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
    private(set) var y:Float=0.1095
    private var startY:Float=0.1095
    private var originalFoot:Float=0.10
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
    private var detour:[H55NpcDetour580.Point]=[]
    private var detourCursor=0
    private var detourSkipTo = -1
    private var blockedFrames=0
    private var detourAge:Float=999
    private(set) var detoursBuilt=0
    private(set) var playerBlockedSeconds:Float=0
    var avoidingPlayer:Bool {detourCursor<detour.count}
    private(set) var doorWait:Float=0
    private(set) var doorFailure:Int?=nil
    var isPatrolling:Bool {
        doorFailure == nil && (phase == .walking || phase == .blocked || phase == .workshop)
    }
    // Source mode=walk is driven by actual translation, not speed requested
    // against a blocked player, geometry or door.
    private(set) var movedThisFrame:Float=0
    var moving:Bool {movedThisFrame>0.00001}

    /// Source NPC root TRS and floor height are measured from authenticated
    /// GLB and verified by H55NpcSurface580 preflight before scene activation.
    mutating func configureSpawn(x:Float,y:Float,z:Float,foot:Float) {
        self.x=x;self.y=y;self.z=z
        startY=y;originalFoot=foot
    }

    mutating func finishConversation() {
        // Source v526: merely approaching does not start a patrol.
        talked=true
        completedOnce=false
        phase = .idle
        goal=0
        speed=0
        pause=0
        detour.removeAll()
        detourCursor=0
        detourSkipTo = -1
        blockedFrames=0
        playerBlockedSeconds=0
        detourAge=999
        doorWait=0
        doorFailure=nil
    }

    /// Use actual active H55 floor/GLB collision plus exclusion of player.
    /// If unsafe, stop instead of walking through GLB. Source A* is not
    /// emulated by an arbitrary shortcut.
    mutating func step(dt raw:Float,playerX:Float,playerZ:Float,
                       canWalk:(Float,Float)->Bool,
                       groundAt:((Float,Float)->Float?)? = nil,
                       doorBlocking:(Float,Float,Float,Float)->Int? =
                         {_,_,_,_ in nil}) {
        let dt=min(0.07,max(0,raw))
        movedThisFrame=0
        guard dt>0 && doorFailure == nil else{return}
        detourAge+=dt
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
        if phase == .completed {
            // PC v526 aligns GLB root back to original orientation.
            let error=Self.wrap(-yaw)
            yaw=Self.wrap(yaw+max(-2*dt,min(2*dt,error)))
            return
        }
        guard phase == .walking || phase == .blocked else{return}
        let avoiding=detourCursor<detour.count
        if !avoiding {
            var advance=0
            while goal<Self.routeX.count-1 && goal != Self.workshopIndex &&
                  advance<Self.routeX.count &&
                  hypot(Self.routeX[goal]-x,Self.routeZ[goal]-z)<=0.18 {
                goal+=1;advance+=1
            }
        }
        let destX=avoiding ? detour[detourCursor].x : Self.routeX[goal]
        let destZ=avoiding ? detour[detourCursor].z : Self.routeZ[goal]
        let dx=destX-x,dz=destZ-z
        let d=hypot(dx,dz)
        let key = !avoiding &&
                  (goal==Self.workshopIndex || goal==Self.routeX.count-1)
        let tolerance:Float=key ? 0.03 : 0.18
        if d<=tolerance {
            if avoiding {
                detourCursor+=1
                if detourCursor>=detour.count {
                    detour.removeAll()
                    detourCursor=0
                    blockedFrames=0
                    if detourSkipTo>=0 {
                        goal=min(Self.routeX.count-1,detourSkipTo+1)
                        detourSkipTo = -1
                    }
                }
                return
            }
            if key {
                let endStep=hypot(destX-x,destZ-z)
                x=destX;z=destZ;distance+=endStep;movedThisFrame=endStep
                if let h=groundAt?(x,z) {y=startY+(h-originalFoot)}
            }
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
        let hardTurn=avoiding ? steering>=0.20 :
             (steering>1.48 || (goal==0 && distance<0.01 && steering>0.24))
        if hardTurn {
            speed=max(0,speed-Self.braking*dt)
            return
        }
        let brakingLimit=sqrt(max(0,2*Self.braking*max(0,d-tolerance)))
        let cornerFactor=cos(min(1.47,steering))
        let base=key ? min(Self.maximumSpeed,brakingLimit) : Self.maximumSpeed
        let request=avoiding ? base*(steering>0.18 ? max(0.92,cos(steering)) : 1)
                              : base*max(0.23,cornerFactor)
        if speed<request {speed=min(request,speed+Self.acceleration*dt)}
        else {speed=max(request,speed-Self.braking*dt)}
        let move=min(d,speed*dt)
        guard d>0 else{return}
        let facing=Self.wrap(anatomicalHeading-yaw)
        let nx=x+(avoiding ? dx/d : sin(facing))*move
        let nz=z+(avoiding ? dz/d : -cos(facing))*move
        let playerClearance:Float=avoiding ? 0.82 : (d>6 ? 0.97 : 0.82)
        let playerBlocked=hypot(nx-playerX,nz-playerZ)<playerClearance
        // PC v544: evaluate source door plane on the NPC's actual
        // movement segment BEFORE player A*/static walkability.
        let gate=doorBlocking(x,z,nx,nz)
        if !playerBlocked && gate == nil && canWalk(nx,nz) {
            // Real original floor support drives NPC GLB root Y, rather
            // than holding it at the initial 0.1095 throughout the route.
            let ground:Float
            if let groundAt {
                guard let supported=groundAt(nx,nz) else{return}
                ground=supported
            } else {ground=originalFoot} // Legacy synthetic tests only.
            x=nx;z=nz;y=startY+(ground-originalFoot)
            distance+=move;movedThisFrame=move
            blockedFrames=0
            playerBlockedSeconds=0
            doorWait=0
            phase = .walking
            return
        }
        speed=max(0,speed-Self.braking*dt)
        phase = .blocked
        if let gate {
            // PC H55Renderer.cs NPC v544 waits 2.5s, then aborts.
            // Static walls and gates must NEVER trigger player-only A*.
            doorWait+=dt
            if doorWait>2.5 {
                doorFailure=gate
                talked=false
            }
            return
        }
        if playerBlocked {
            playerBlockedSeconds+=dt
            blockedFrames+=1
            // PC v532: only the player's capsule can trigger A*.
            // Static GLB/door collision never causes a speculative bypass.
            if blockedFrames>=8 && detourAge>=0.8 {
                blockedFrames=0
                detourAge=0
                detour.removeAll()
                detourCursor=0
                let start=H55NpcDetour580.Point(x:x,z:z)
                let player=H55NpcDetour580.Point(x:playerX,z:playerZ)
                let routeGoal=H55NpcDetour580.Point(x:Self.routeX[goal],
                                                       z:Self.routeZ[goal])
                if let bypass=H55NpcDetour580.bypass(
                    start:start,player:player,goal:routeGoal,
                    goalIndex:goal,workshopIndex:Self.workshopIndex,
                    routeX:Self.routeX,routeZ:Self.routeZ,
                    walkable:canWalk) {
                    detour=bypass.points
                    detourSkipTo=bypass.skipTo
                    detoursBuilt+=1
                }
            }
        }
    }
}
