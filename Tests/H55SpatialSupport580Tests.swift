import Foundation

@main struct H55SpatialSupport580Tests {
    static func check(_ condition:Bool,_ message:String) {precondition(condition,"H03: "+message)}
    static func near(_ value:Float?,_ target:Float)->Bool {
        guard let value else{return false}
        return abs(value-target)<0.0001
    }
    static func main() {
        let t:[Float]=[
            0,0.085,0, 4,0.085,0, 0,0.085,4,
            4,0.085,0, 4,0.085,4, 0,0.085,4,
            0,0.005,0, 0,0.005,4, 4,0.005,0,
            0,0.8,0, 4,0.8,0, 0,0.8,4,
            0,0,0, 0,2,0, 0,2,4
        ]
        var box=H55CollisionGeometry580.Box(name:"HL_IMPORT_5")
        box.expand(2,0,1)
        box.expand(3,2,2)
        let geometry=H55CollisionGeometry580.Geometry(
            triangles:t,objects:[box],sourceTriangles:5,proxyTriangles:0,
            sceneNodes:2,minX:-29,maxX:52,minZ:-18,maxZ:20)
        let grid=H55SpatialSupport580(geometry:geometry)
        check(grid.triangleCount==5 && grid.proxyCount==1,"geometry counts")
        check(grid.cellCount>0 && grid.proxyCellCount>0,"both spatial hash grids")
        check(H55SpatialSupport580.cell(-0.001)==(-1) &&
              H55SpatialSupport580.cell(1.999)==0 &&
              H55SpatialSupport580.cell(2)==1,"floor grid crossing negatives")
        check(near(grid.support(0.5,0.5,low:-0.25,high:1),0.8),
              "source highest overlapping platform")
        check(near(grid.supportLowest403(0.5,0.5,low:-0.25,high:1),0.005),
              "source lowest overlapping floor")
        check(near(grid.support(0.5,0.5,low:-0.25,high:0.45),0.085),
              "original user H55 floor with inverted triangle winding")
        check(grid.support(0.5,0.5,low:1,high:3)==nil,
              "must not teleport to out-of-range floor")
        check(grid.support(100,100,low:0,high:5)==nil,"no invented floor")
        check(grid.h72Bounds(52.5,20.5) && !grid.h72Bounds(53,20.5),
              "external GLB bounds with PC half-metre margin")
        check(grid.h72Bounds(30,7,externalGLB:false) &&
             !grid.h72Bounds(30,14,externalGLB:false),
             "original embedded H71 corridor only")
        check(grid.shipBlocks(0,0,0) && !grid.shipBlocks(5,0,0),
              "PC ship radius and vertical overlap")
        check(grid.proxyNear(2.1,1,1.5,radius:0.325,feetLimit:true,footY:0)>0,
              "true 3D static prefab box")
        check(grid.proxyNear(2.1,1,1.5,radius:0.325,feetLimit:true,footY:2.5)==0,
              "source proxy foot-limit exclusion")
        check(grid.proxyCapsule(2.1,0,1.5,radius:0.325)>0,
              "source proxy capsule four samples")
        print("PASS H03 original PC v580 2m grid, min/max supports, inverted winding, exact external bounds, ship and prefab proxies")
    }
}
