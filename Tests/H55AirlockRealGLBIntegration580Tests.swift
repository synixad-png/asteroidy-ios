import Foundation

/// H07 offline end-to-end gate with exact 126419336-byte H55 user GLB.
/// Not run on GitHub CI: the 126MB GLB is intentionally not in the repo/IPA.
@main struct H55AirlockRealGLBIntegration580Tests {
    static func check(_ b:Bool,_ message:String) {
        precondition(b,"H07 REAL GLB: "+message)
    }
    static func main() throws {
        guard CommandLine.arguments.count==2 else {
            throw NSError(domain:"H07",code:2,userInfo:[
                NSLocalizedDescriptionKey:"Supply exact original hangar_h55.glb"
            ])
        }
        let url=URL(fileURLWithPath:CommandLine.arguments[1])
        let geom=try H55CollisionGeometry580.fromGLB(url)
        let physical=H55SpatialSupport580(geometry:geom)
        let keys=try H55AirlockTracks580.load(from:url)
        check(physical.triangleCount==803538 && physical.proxyCount==233,
              "actual H02 geometry, never a synthetic floor")
        check(keys.nodes.count==4,"actual four H70 translation channels")
        guard let entry=H55Entry580.find(using:physical) else {
            preconditionFailure("H05 original spawn regression")
        }
        check(abs(entry.x-2)<0.0001 && abs(entry.z-14)<0.0001 &&
              abs(entry.feet-0.10)<0.001,"H05 original first safe entry")

        var doors=H55AirlockController580()
        var walk=H55Walk580()
        walk.x=23.5;walk.z=7.15;walk.placeAtSpawn(feet:0.085)
        check(physical.bodyClear379(walk.x,feet:walk.y,walk.z),
              "real original corridor is walkable at start")
        func collisionStep(_ w:inout H55Walk580,_ controller:H55AirlockController580) {
            w.step(dt:1/60,forward:0,right:1,sprint:false,
                   collision:physical,doorBlocks:{ax,az,bx,bz in
                controller.blockingGate(fromX:ax,fromZ:az,toX:bx,toZ:bz) != nil
            })
        }
        for _ in 0..<180 {collisionStep(&walk,doors)}
        check(walk.x>=23.9 && walk.x<=24.06 &&
              physical.bodyClear379(walk.x,feet:walk.y,walk.z),
              "CLOSED hanger gate stops original H06 four-sphere walk")

        for _ in 0..<120 {
            collisionStep(&walk,doors)
            doors.step(playerX:walk.x,playerZ:walk.z,playerPresent:true,
                       npcX:50,npcZ:50,npcPresent:false,dt:1/60)
        }
        check(walk.x>24.36 && walk.x<30.46,
              "player walks through OPEN first actual H70 airlock")
        check(doors.openness[0]>=0.90 && doors.openness[1]>=0.90,
              "both original separate H70 sensors open in corridor")
        check(physical.bodyClear379(walk.x,feet:walk.y,walk.z),
              "player remains in exact four-sphere H02-H04 collision")

        for _ in 0..<200 {
            collisionStep(&walk,doors)
            doors.step(playerX:walk.x,playerZ:walk.z,playerPresent:true,
                       npcX:50,npcZ:50,npcPresent:false,dt:1/60)
        }
        check(walk.x>31.0 && walk.z==7.15 &&
              physical.bodyClear379(walk.x,feet:walk.y,walk.z),
              "OPEN second real H70 workshop airlock passes and stays collision clear")
        check(doors.openness[0]<0.05 && doors.openness[1]<0.05,
              "original hysteretic sensors re-close both gates after departure")
        print("PASS H07 actual user GLB: original H05 start, 803538 triangles/233 boxes, closed first gate, opened two real sensor gates, crossed x31, automatic re-close")
    }
}
