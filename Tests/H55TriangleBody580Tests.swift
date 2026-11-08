import Foundation

/// Regression cases tied to Windows/src/HubWalk375.cs PC v580
/// H55FullCollision379.Dist2, BodyClear, Penetration382,
/// ContactNormal401 and CameraClear406. No SceneKit mocks.
@main struct H55TriangleBody580Tests {
    typealias G=H55CollisionGeometry580
    private static func require(_ value:Bool,_ text:String) {
        precondition(value,"H04 "+text)
    }
    private static func close(_ actual:Float,_ expected:Float,_ tolerance:Float=0.0001)->Bool {
        abs(actual-expected)<=tolerance
    }
    static func main() {
        var proxy=G.Box(name:"HL_IMPORT_2011")
        proxy.expand(15,0.7,15)
        proxy.expand(16,2.0,16)
        let triangles:[Float]=[
            // Test triangle in XY plane, z=0.
            0,0,0, 2,0,0, 0,2,0,
            // Real vertical wall, two triangles, x=10.
            10,0.6,9, 10,1.8,9, 10,0.6,11,
            10,1.8,9, 10,1.8,11, 10,0.6,11,
            // Decorative trim below 50cm: ignored for body.
            11,0.1,9, 12,0.1,9, 11,0.1,11
        ]
        let geometry=G.Geometry(triangles:triangles,objects:[proxy],
            sourceTriangles:4,proxyTriangles:0,sceneNodes:4,
            minX:-20,maxX:30,minZ:-20,maxZ:30)
        let body=H55SpatialSupport580(geometry:geometry)
        // Ericson triangle region checks: vertex, edge, face, vertex C.
        require(close(body.distanceSquared379(at:0,x:-1,y:0,z:0),1),
                "vertex A region")
        require(close(body.distanceSquared379(at:0,x:3,y:0,z:0),1),
                "vertex B region")
        require(close(body.distanceSquared379(at:0,x:0,y:3,z:0),1),
                "vertex C region")
        require(close(body.distanceSquared379(at:0,x:1,y:-1,z:0),1),
                "edge AB region")
        require(close(body.distanceSquared379(at:0,x:-1,y:1,z:0),1),
                "edge AC region")
        require(close(body.distanceSquared379(at:0,x:1.5,y:1.5,z:0),0.5),
                "edge BC region")
        require(close(body.distanceSquared379(at:0,x:0.5,y:0.5,z:2),4),
                "inside face with perpendicular distance")
        // BodyClear must test four spheres in true 3D.
        require(!body.bodyClear379(10.20,feet:0,9.6),
                "wall intersects four standing spheres")
        require(body.bodyClear379(11.0,feet:0,9.6),
                "clear standing body beyond wall")
        require(body.penetration382(10.20,feet:0,9.6)>0,
                "source penetration energy is positive near true wall")
        require(close(body.penetration382(11.0,feet:0,9.6),0),
                "clear body has zero penetration energy")
        require(body.contactNormal401(10.20,feet:0,9.6) != nil,
                "source wall contact energy gradient")
        require(!body.bodyClear379(15.1,feet:0,15.1),
                "prefab AABB blocks four-sphere capsule")
        require(body.penetration382(15.1,feet:0,15.1)>0,
                "source prefab supplies nonzero overlap energy")
        require(!body.bodyClear379(0,feet:0,0),
                "the original docked ship remains solid")
        require(!body.bodyClear379(40,feet:0,40),
                "original external H55 map bounds are solid")
        require(!body.cameraClear406(10.15,1.0,9.6,radius:0.2),
                "source near-eye sphere blocks camera through wall")
        require(body.cameraClear406(11.0,1.0,9.6,radius:0.2),
                "camera free beyond wall")
        require(body.cameraClear406(11.3,0.75,9.6,radius:0.2),
                "floor trim does not incorrectly block camera away from trim")
        print("PASS H04 Ericson 7 region distances; exact 4 spheres, wall, prefab, ship, bounds, overlap, contact gradient and near-eye collision")
    }
}
