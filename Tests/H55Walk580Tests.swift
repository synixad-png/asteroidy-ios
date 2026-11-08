import Foundation

@main struct H55Walk580Tests {
    static func check(_ ok:Bool,_ why:String) {precondition(ok,"H06: "+why)}
    typealias G=H55CollisionGeometry580

    static func floor(_ h:Float,_ x0:Float,_ x1:Float,
                      _ z0:Float,_ z1:Float)->[Float] {
        [x0,h,z0, x1,h,z0, x0,h,z1,
         x1,h,z0, x1,h,z1, x0,h,z1]
    }
    static func collision(_ extras:[Float]=[])->H55SpatialSupport580 {
        let tris=floor(0,-28,56,-18,20)+extras
        return H55SpatialSupport580(geometry:
             G.Geometry(triangles:tris,objects:[],
                        sourceTriangles:tris.count/9,proxyTriangles:0,sceneNodes:1,
                        minX:-30,maxX:60,minZ:-20,maxZ:22))
    }
    static func main() {
        let p=collision()
        var walk=H55Walk580()
        walk.placeAtSpawn(feet:0)
        check(walk.cameraReady && walk.cameraFeet==0,"spawn visual feet")
        check(walk.x==2 && walk.z==14,"PC source ordered first entry")
        check(abs(H55Walk580.walkSpeed-4.3)<0.0001,"source speed 50")
        check(H55Walk580.bodyRadius==0.34 && H55Walk580.bodyHeight==2,
              "source four-sphere physical dimensions")
        walk.step(dt:1/60,forward:1,right:0,sprint:false,collision:p)
        check(walk.z<14 && walk.x==2,"yaw=0 moves -Z")
        let early=walk.z
        for _ in 0..<30 {walk.step(dt:1/60,forward:1,right:0,sprint:false,collision:p)}
        check(walk.z<early-1,"source response 17 on ground")
        let before=walk.z
        for _ in 0..<60 {walk.step(dt:1/60,forward:0,right:0,sprint:false,collision:p)}
        check(walk.z<before && abs(walk.vz)<0.03,"exponential damping")
        walk.look(deltaX:100,deltaY:100)
        check(abs(walk.yaw-0.28)<0.0001 && abs(walk.pitch+0.25)<0.0001,
              "original 0.0028 / 0.0025 look")

        var jump=H55Walk580()
        jump.placeAtSpawn(feet:0)
        check(jump.jump(collision:p),"source first jump")
        var apex:Float=0
        for _ in 0..<150 {
            jump.step(dt:1/60,forward:0,right:0,sprint:false,collision:p)
            apex=max(apex,jump.y)
        }
        check(apex>1.10 && apex<1.20,"PC 1.15m first apex")
        check(jump.grounded && jump.jumps==0,"landing resets jump")
        check(jump.jump(collision:p),"first jump for double jump")
        for _ in 0..<10 {jump.step(dt:1/60,forward:0,right:0,sprint:false,collision:p)}
        check(jump.jump(collision:p) && !jump.jump(collision:p),"second jump only")
        var second:Float=jump.y
        for _ in 0..<180 {
            jump.step(dt:1/60,forward:0,right:0,sprint:false,collision:p)
            second=max(second,jump.y)
        }
        check(second>3.45 && second<5.0,"second jump adds source 3.45m")
        check(jump.grounded && jump.jumps==0,"double jump resets")

        // Exact H04 collision against a genuine vertical wall mesh.
        let wall:[Float]=[
            3.25,0.60,8, 3.25,2.20,8, 3.25,0.60,17,
            3.25,2.20,8, 3.25,2.20,17, 3.25,0.60,17
        ]
        let w=collision(wall)
        var blocked=H55Walk580()
        blocked.placeAtSpawn(feet:0)
        for _ in 0..<180 {
            blocked.step(dt:1/60,forward:0,right:1,sprint:true,collision:w)
        }
        check(blocked.x<3.25 && w.bodyClear379(blocked.x,feet:blocked.y,blocked.z),
              "swept body does not enter real wall")
        check(blocked.bobAmount<0.1,"source bob uses displacement, not held input")

        var stair=H55Walk580()
        stair.x=18;stair.z=16.8;stair.placeAtSpawn(feet:0.16)
        stair.step(dt:1/60,forward:1,right:0,sprint:false,collision:p)
        check(stair.y>0.16 && stair.y<0.4,"authored PC 381 ramp step at x=18")
        check(p.bodyClear379(stair.x,feet:stair.y,stair.z),
              "ramp is clear at whole capsule")

        // Camera render follows separately: physical feet must not lerp.
        let smooth=H55Walk580.smoothCamera(0,0.5,1/60,true)
        check(smooth>0 && smooth<0.5,"PC 404 smoothing only the camera")
        check(H55Walk580.smoothCamera(0,2,1/60,true)==2,
              "large step cuts camera lag")
        check(H55Walk580.smoothCamera(0,0.5,1/60,false)==0.5,
              "airborne camera is not delayed")
        print("PASS H06 PC580 actual H02-H04 geometry: speed, look, 4-sphere wall, ramp, jumps, bob, camera")
    }
}
