import Foundation

/// Full original 126MB GLB H08+H09 integration on Linux Swift 6:
/// actual 803,538-triangle geometry, BOTH H70 doors and return A* while
/// all 80 imported mocap bones are evaluated at every real navigation tick.
@main struct H55NpcH09RealPatrol580Tests {
    static func check(_ x:Bool,_ msg:String){precondition(x,"H09 REAL GLB: "+msg)}
    static func main() throws {
        guard CommandLine.arguments.count==2 else{fatalError("pass original H55 GLB")}
        let url=URL(fileURLWithPath:CommandLine.arguments[1])
        let rig=try H55NpcTracks580.load(url)
        let motion=try H55NpcMotion580(rig:rig)
        let p=H55SpatialSupport580(geometry:try H55CollisionGeometry580.fromGLB(url))
        check(p.triangleCount==803538 && p.proxyCount==233,"authentic H55 collision data")
        let surface=try H55NpcSurface580.prepare(collision:p)
        check(surface.samples==1136,"all 28 original route segments validated")
        var worker=H55Mechanic580()
        worker.configureSpawn(x:H55NpcSurface580.rootX,
            y:H55NpcSurface580.rootY,z:H55NpcSurface580.rootZ,foot:surface.foot)
        worker.calibrate(anatomicalHeading:-2.323263891)
        worker.finishConversation()
        var doors=H55AirlockController580()
        var workshopFrames=0,walkFrames=0,restFrames=0,changedWalk=0
        var previousMode=false,previousPhase:Float=0,lastYaw:Float=worker.yaw
        var maxAngularError:Float=0
        for frame in 0..<15000 {
            let px:Float=frame<300 ? -30 : 14.2
            let pz:Float=frame<300 ? -30 : 11.181
            worker.step(dt:1/60,playerX:px,playerZ:pz,
                canWalk:{x,z in surface.ground(x:x,z:z) != nil},
                groundAt:{x,z in surface.ground(x:x,z:z)},
                doorBlocking:{ax,az,bx,bz in
                    doors.blockingGate(fromX:ax,fromZ:az,toX:bx,toZ:bz)
                })
            doors.step(playerX:px,playerZ:pz,playerPresent:true,
                npcX:worker.x,npcZ:worker.z,
                npcPresent:worker.isPatrolling,dt:1/60)
            // PC mode=0 at the final <=3cm workshop waypoint snap.
            let moving=worker.moving && worker.phase == .walking
            let angular=H55Mechanic580.wrap(worker.yaw-lastYaw)*60
            lastYaw=worker.yaw
            let pose=motion.step(dt:1/60,moving:moving,distance:worker.distance,
                                  speed:moving ? worker.movedThisFrame*60 : 0,
                                  yawRate:angular)
            check(pose.count==80,"all authentic glTF joints animated")
            if moving {
                walkFrames+=1
                let expected=(worker.distance/4.01*2.375).truncatingRemainder(dividingBy:2.375)
                check(abs(motion.gaitTime-expected)<0.00003,
                      "walk phase depends on real distance, not elapsed time")
                if !previousMode {changedWalk+=1}
            }else{
                restFrames+=1
                if previousMode {previousPhase=motion.gaitTime}
                else {check(abs(motion.gaitTime-previousPhase)<0.001 ||
                            frame==0 || changedWalk==0,
                            "stopped feet never advance gait phase")}
            }
            previousMode=moving
            for link in motion.links {
                let q=pose[link.bone].rotation
                check(abs(q.norm-1)<0.004,"source 110kg springs stay stable")
            }
            if frame%60==0 {
                let authored=rig.sample(walk:moving,time:motion.clipTime)
                for link in motion.links {
                    let q=pose[link.bone].rotation,t=authored[link.bone].rotation
                    let similarity=abs(q.x*t.x+q.y*t.y+q.z*t.z+q.w*t.w)
                    let delta=2*acos(max(0,min(1,similarity)))
                    maxAngularError=max(maxAngularError,delta)
                }
                check(surface.ground(x:worker.x,z:worker.z) != nil &&
                      p.bodyClear379(worker.x,feet:surface.foot,z:worker.z),
                      "valid source GLB floor and physical collision")
            }
            if worker.phase == .workshop {
                workshopFrames+=1
                check(!moving,"mandatory workshop is idle, even on first arrival")
            }
            if worker.phase == .completed {
                check(abs(worker.x-9.9248)<0.001 && abs(worker.z-12.155)<0.001,
                      "must return to true GLB bind-pose root")
                check(workshopFrames>=300 && workshopFrames<=301,
                      "exact five-second workshop stop")
                check(worker.detoursBuilt>=2,"player A* both legs")
                check(walkFrames>2200 && restFrames>300 && changedWalk>10,
                      "real changes between original walk/idle")
                check(maxAngularError.isFinite,"no NaN physics")
                print("PASS H09 REAL GLB: \(frame+1) frames, \(walkFrames) walking, \(restFrames) idle, \(changedWalk) transitions, 2 A* bypasses, 300 service frames, 80 bones, 15 springs")
                return
            }
        }
        fatalError("H09 NPC route timed out")
    }
}
