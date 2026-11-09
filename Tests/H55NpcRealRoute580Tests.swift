import Foundation

/// H08 genuine H55 GLB end-to-end: 28 PC v580 waypoints, independently
/// opening H70 airlocks, original four-sphere floor and v532 player A*.
/// Run with the user's SHA-verified hangar_h55.glb (126419336 bytes) or
/// exactly its +4-byte cgltf-compatible copy (126419340 bytes).
@main struct H55NpcRealRoute580Tests {
    struct Result {
        var frames=0,visited=Set<Int>()
        var workshopFrames=0,doorOpened=[false,false]
        var doorPassed=[false,false],detours=0
        var blockedFrames=0,distance:Float=0
    }
    static func check(_ pass:Bool,_ why:String) {
        precondition(pass,"H08 REAL GLB: "+why)
    }
    static func simulate(surface:H55NpcSurface580,obstructReturn:Bool)->Result {
        var npc=H55Mechanic580()
        npc.configureSpawn(x:H55NpcSurface580.rootX,y:H55NpcSurface580.rootY,
                           z:H55NpcSurface580.rootZ,foot:surface.foot)
        // This anatomical forward direction was MEASURED from the actual
        // GLB bind-pose LEFT+RIGHT ankle->toe vectors (dot=.9605888).
        // It is not a route guess or manually authored facing direction.
        npc.calibrate(anatomicalHeading:-2.323263891)
        npc.finishConversation()
        var doors=H55AirlockController580()
        var result=Result(),lastX=npc.x
        var seenWorkshop=false
        for frame in 0..<15000 {
            // This actual corridor point blocks outbound and return legs.
            // Original PC v580 incorrectly clamped return A* waypoint search
            // to index <= workshopIndex-1, causing permanent deadlock.
            let px:Float=obstructReturn && frame>=300 ? 14.2 : -30
            let pz:Float=obstructReturn && frame>=300 ? 11.181 : -30
            npc.step(dt:1/60,playerX:px,playerZ:pz,
                     canWalk:{x,z in surface.ground(x:x,z:z) != nil},
                     groundAt:{x,z in surface.ground(x:x,z:z)},
                     doorBlocking:{ax,az,bx,bz in
                doors.blockingGate(fromX:ax,fromZ:az,toX:bx,toZ:bz)
            })
            doors.step(playerX:px,playerZ:pz,playerPresent:true,
                       npcX:npc.x,npcZ:npc.z,
                       npcPresent:npc.isPatrolling,dt:1/60)
            result.visited.insert(npc.goal)
            for gate in 0..<2 {
                if doors.openness[gate]>=0.90 {result.doorOpened[gate]=true}
            }
            if npc.x>24.7 && lastX<=24.7 {result.doorPassed[0]=true}
            if npc.x>30.8 && lastX<=30.8 {result.doorPassed[1]=true}
            lastX=npc.x
            if npc.phase == .workshop {result.workshopFrames+=1;seenWorkshop=true}
            if npc.phase == .blocked {result.blockedFrames+=1}
            check(npc.doorFailure == nil,"unexpected permanently closed H70")
            if frame%60==0 {
                guard let floor=surface.ground(x:npc.x,z:npc.z) else {
                    preconditionFailure("H08: NPC left original GLB at frame \(frame)")
                }
                check(abs(npc.y-(H55NpcSurface580.rootY+floor-surface.foot))<0.005,
                      "GLB root height follows real support")
                check(surface.collision.bodyClear379(npc.x,feet:floor,npc.z),
                      "NPC penetrates genuine H55 geometry")
            }
            if npc.phase == .completed {
                result.frames=frame+1;result.distance=npc.distance
                result.detours=npc.detoursBuilt
                check(seenWorkshop,"patrol completed without service pause")
                check(abs(npc.x-9.9248)<0.001 && abs(npc.z-12.155)<0.001,
                      "NPC must return to original root position")
                check(result.workshopFrames>=300 && result.workshopFrames<=301,
                      "original five seconds at 60FPS")
                check(result.doorOpened.allSatisfy{$0} &&
                      result.doorPassed.allSatisfy{$0},
                      "both H70 authentic gates must open and be crossed")
                check(result.visited.count>=22 && result.distance>85,
                      "all original 28 waypoints without teleporting")
                if obstructReturn {
                    check(result.detours>=2,
                          "A* must bypass player on outbound AND return route")
                }
                for _ in 0..<120 {
                    npc.step(dt:1/60,playerX:px,playerZ:pz,
                             canWalk:{x,z in surface.ground(x:x,z:z) != nil},
                             groundAt:{x,z in surface.ground(x:x,z:z)},
                             doorBlocking:{_,_,_,_ in nil})
                    check(npc.phase == .completed,"no automatic patrol restart")
                }
                return result
            }
        }
        preconditionFailure("H08: NPC never finished approved route")
    }
    static func main() throws {
        check(CommandLine.arguments.count==2,
              "pass original 126MB hangar_h55.glb path")
        let file=URL(fileURLWithPath:CommandLine.arguments[1])
        let size=try FileManager.default.attributesOfItem(atPath:file.path)[.size] as? NSNumber
        check(size?.uint64Value==126419336 || size?.uint64Value==126419340,
              "requires original or precisely +4B cgltf-compatible H55")
        let geometry=try H55CollisionGeometry580.fromGLB(file)
        let collision=H55SpatialSupport580(geometry:geometry)
        let surface=try H55NpcSurface580.prepare(collision:collision)
        check(surface.samples>=1100,"all 28 approved segments preflighted")
        check(H55Mechanic580.routeX.count==28 && H55Mechanic580.routeZ.count==28,
              "PC 28 source waypoint invariant")
        let clear=simulate(surface:surface,obstructReturn:false)
        print("PASS H08 CLEAR: \(clear.frames) frames, \(clear.distance)m, \(clear.workshopFrames) pause frames, 2 doors")
        let blocked=simulate(surface:surface,obstructReturn:true)
        print("PASS H08 PLAYER: \(blocked.frames) frames, \(blocked.detours) A* bypasses, two doors, original return root")
    }
}
