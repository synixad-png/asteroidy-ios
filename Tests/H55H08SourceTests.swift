import Foundation

@main struct H55H08SourceTests {
    static func check(_ b:Bool,_ reason:String) {precondition(b,"H08: "+reason)}
    static func sampleFloor(xMax:Float)->H55SpatialSupport580 {
        let x0:Float = -28,z0:Float = -20,z1:Float = 20, floor:Float = 0.10
        let t:[Float]=[
            x0,floor,z0, xMax,floor,z0, x0,floor,z1,
            xMax,floor,z0, xMax,floor,z1, x0,floor,z1
        ]
        return H55SpatialSupport580(geometry:
            H55CollisionGeometry580.Geometry(triangles:t,objects:[],
                sourceTriangles:2,proxyTriangles:0,sceneNodes:1,
                minX:x0,maxX:xMax,minZ:z0,maxZ:z1))
    }
    static func main() throws {
        check(H55Mechanic580.routeX.count==28 && H55Mechanic580.routeZ.count==28,
              "all 28 exact designer waypoints")
        check(H55Mechanic580.workshopIndex==11 &&
              abs(H55Mechanic580.maximumSpeed-1.18)<0.0001 &&
              abs(H55Mechanic580.acceleration-1.75)<0.0001 &&
              abs(H55Mechanic580.braking-2.80)<0.0001,
              "source H08 v528/530 motion values")
        let surface=try H55NpcSurface580.prepare(collision:sampleFloor(xMax:60))
        check(surface.samples==1136 && abs(surface.foot-0.1)<0.0001,
              "same source .08m route samples")
        check(surface.ground(x:12.358,z:13.024) != nil,
              "real original H03/H04 support and capsule")
        do {
            _=try H55NpcSurface580.prepare(collision:sampleFloor(xMax:20))
            preconditionFailure("H08 edited scene must NOT silently skip blocked corridor")
        } catch H55NpcSurface580.RouteError.blocked(let segment,_,_) {
            check(segment>0 && segment<28,"fail at physically blocked segment")
        }
        var worker=H55Mechanic580()
        worker.configureSpawn(x:H55NpcSurface580.rootX,
                              y:H55NpcSurface580.rootY,
                              z:H55NpcSurface580.rootZ,foot:surface.foot)
        worker.calibrate(anatomicalHeading:-2.32326389)
        worker.finishConversation()
        worker.step(dt:1/60,playerX:2,playerZ:14,
                    canWalk:{x,z in surface.ground(x:x,z:z) != nil},
                    groundAt:{x,z in surface.ground(x:x,z:z)})
        check(worker.phase == .walking,"confirmed conversation and distance initiate patrol")
        check(abs(worker.y-H55NpcSurface580.rootY)<0.0001,
              "scene root Y follows authentic surface at start")
        let door=H55AirlockController580()
        check(door.blockingGate(fromX:23,fromZ:7.15,
                                toX:24.36,toZ:7.15)==0,
              "H08 inherits H07 closed-door check")
        // Confirm the original v532 return-leg deadlock repair does NOT
        // allow skipping the mandatory five-second workshop stop.
        let workshopBypass=H55NpcDetour580.bypass(
            start:.init(x:45.2,z:8.1),player:.init(x:45.817,z:8.15),
            goal:.init(x:45.817,z:8.15),goalIndex:11,workshopIndex:11,
            routeX:H55Mechanic580.routeX,routeZ:H55Mechanic580.routeZ,
            walkable:{_,_ in true})
        check(workshopBypass == nil,
              "workshop 11 must never be skipped by an A* detour")

        let returnBypass=H55NpcDetour580.bypass(
            start:.init(x:15.009,z:11.315),player:.init(x:14.2,z:11.181),
            goal:.init(x:13.914,z:11.713),goalIndex:23,workshopIndex:11,
            routeX:H55Mechanic580.routeX,routeZ:H55Mechanic580.routeZ,
            walkable:{_,_ in true})
        check(returnBypass != nil && returnBypass!.skipTo==24,
              "return leg 23 must join next original approved waypoint 24")
        print("PASS H08 source: 28 points, 1136 samples, original floor, NPC/H07, return-leg A* and mandatory 5s workshop preserved")
    }
}
