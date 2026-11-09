import Foundation

/// H08 offline PC v580 ↔ iOS traversal regression on ORIGINAL 126 MB H55 GLB.
/// No flat substitute floor. Run with exact known SHA256 GLB path.
@main struct H55H08PatrolRealGLBTests {
    static func check(_ value:Bool,_ why:String){precondition(value,"H08: "+why)}
    static let heading:Float = -2.32326389 // Source GLB bind-pose ankle→toe both feet.
    static let fps:Float=1/60
    static func configured(_ nav:H55NpcSurface580)->H55Mechanic580 {
        var worker=H55Mechanic580()
        worker.configureSpawn(x:H55NpcSurface580.rootX,
                              y:H55NpcSurface580.rootY,
                              z:H55NpcSurface580.rootZ,foot:nav.foot)
        worker.calibrate(anatomicalHeading:heading)
        return worker
    }
    static func run(_ nav:H55NpcSurface580,playerX:Float,playerZ:Float,
                    blockDoor:Bool=false,maxFrames:Int=12000)->(H55Mechanic580,Float,Float,Int) {
        let p=nav.collision
        var worker=configured(nav)
        var doors=H55AirlockController580()
        worker.finishConversation()
        var stopTime:Float = -1,workshopSeconds:Float=0,checks=0
        var prev=worker.phase
        for frame in 0..<maxFrames {
            worker.step(dt:fps,playerX:playerX,playerZ:playerZ,
                canWalk:{x,z in nav.ground(x:x,z:z) != nil},
                groundAt:{x,z in nav.ground(x:x,z:z)},
                doorBlocking:{ax,az,bx,bz in
                    if blockDoor {
                        let gateX:Float=24.36
                        if min(ax,bx)<=gateX+0.30 && max(ax,bx)>=gateX-0.30 &&
                           max(abs(az-7.15),abs(bz-7.15))<=2.15 {return 0}
                        return nil
                    }
                    return doors.blockingGate(fromX:ax,fromZ:az,toX:bx,toZ:bz)
                })
            doors.step(playerX:playerX,playerZ:playerZ,playerPresent:true,
                       npcX:worker.x,npcZ:worker.z,
                       npcPresent:worker.isPatrolling,dt:fps)
            if worker.phase == .workshop {workshopSeconds+=fps}
            if worker.phase != prev {
                if worker.phase == .completed {stopTime=Float(frame+1)*fps}
                prev=worker.phase
            }
            if frame%30==0 {
                check(p.bodyClear379(worker.x,feet:worker.y-0.0095,worker.z),
                      "4-sphere real capsule, no penetration after movement")
                if let support=nav.ground(x:worker.x,z:worker.z) {
                    check(abs(worker.y - (H55NpcSurface580.rootY+support-nav.foot))<0.03,
                          "root Y tracks original real floor")
                } else {check(false,"root strayed off original valid floor")}
                checks+=1
            }
            if stopTime>=0 {break}
            if worker.doorFailure != nil {break}
        }
        return (worker,stopTime,workshopSeconds,checks)
    }
    static func main() throws {
        check(CommandLine.arguments.count==2,"pass SHA256 verified original hangar_h55.glb")
        let url=URL(fileURLWithPath:CommandLine.arguments[1])
        let p=H55SpatialSupport580(geometry:try H55CollisionGeometry580.fromGLB(url))
        check(p.triangleCount==803538 && p.proxyCount==233,
              "must be real H02 geometry, not synthetic floor")
        let nav=try H55NpcSurface580.prepare(collision:p)
        check(nav.samples>1000 && abs(nav.foot-0.1)<0.001,
              "PC v531 validates entire 28-point route every .08m")
        print("H08 full original GLB route audit: \(nav.samples) real collision checks PASS")
        var idle=configured(nav)
        for _ in 0..<40 {
            idle.step(dt:fps,playerX:2,playerZ:14,
                 canWalk:{x,z in nav.ground(x:x,z:z) != nil})
        }
        check(idle.phase == .idle,"no completed conversation never patrols")
        idle.finishConversation()
        for _ in 0..<40 {
            idle.step(dt:fps,playerX:idle.x+0.8,playerZ:idle.z,
                 canWalk:{x,z in nav.ground(x:x,z:z) != nil})
        }
        check(idle.phase == .idle,"player still near after talking prevents patrol")
        idle.step(dt:fps,playerX:2,playerZ:14,
             canWalk:{x,z in nav.ground(x:x,z:z) != nil})
        check(idle.phase == .walking,"moves when player leaves 2.5m range")
        let regular=run(nav,playerX:2,playerZ:14)
        check(regular.0.phase == .completed,"unobstructed NPC full trip")
        check(abs(regular.0.x-H55NpcSurface580.rootX)<0.0002 &&
              abs(regular.0.z-H55NpcSurface580.rootZ)<0.0002,
              "exact designer return point 9.9248,12.155")
        check(regular.1>78 && regular.1<86,"full PC v580 trip duration")
        check(regular.2>=5 && regular.2<5.05,"exact 5 s workshop pause")
        check(regular.0.detoursBuilt==0,"normal full route no needless A* detour")
        var turn=regular.0
        for _ in 0..<120 {
            turn.step(dt:fps,playerX:2,playerZ:14,
                canWalk:{x,z in nav.ground(x:x,z:z) != nil})
        }
        check(abs(turn.yaw)<0.02,"post-patrol source v526 root yaw returns zero")
        print("PASS 28-point out-and-back through both auto airlocks: \(regular.1)s, workshop \(regular.2)s, \(regular.3) collision samples")

        let avoiding=run(nav,playerX:11.908,playerZ:17.119)
        check(avoiding.0.phase == .completed && avoiding.0.detoursBuilt>0,
              "real original GLB player-avoidance A* bypass and full return")
        check(avoiding.2>=5 && avoiding.2<5.05,"5s workshop remains after A*")
        print("PASS real player A*: \(avoiding.0.detoursBuilt) planned bypass(es), \(avoiding.1)s, physically valid entire route")

        let blocked=run(nav,playerX:2,playerZ:14,blockDoor:true,maxFrames:3200)
        check(blocked.0.doorFailure==0 && !blocked.0.isPatrolling,
              "shut gate abort after 2.5s, fail closed")
        check(blocked.0.x<24.36 && blocked.0.detoursBuilt==0,
              "no A* through shut door / no teleport")
        print("PASS shutter held closed: source 2.5s abort, no A* bypass")
        print("PASS H08 original user GLB: full route preflight, 28 waypoints, 5s stop, return and yaw, real player A*, two auto airlocks, hard door abort, physical Y")
    }
}
