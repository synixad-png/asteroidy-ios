import Foundation

/// H02 regression fixtures use real GLB 2.0 binary layout and the authored
/// metadata rules of PC Windows HangarCollision441.FromGlb. The 126MB source
/// scene also undergoes independent differential testing outside GitHub CI.
@main struct H55CollisionGeometry580Tests {
    private static func check(_ condition:Bool,_ message:String) {
        precondition(condition,"H02: "+message)
    }
    private static func u16(_ n:UInt16)->Data {
        Data([UInt8(n & 0xff),UInt8((n >> 8) & 0xff)])
    }
    private static func u32(_ n:UInt32)->Data {
        Data((0..<4).map{UInt8((n >> ($0*8)) & 0xff)})
    }
    private static func f32(_ n:Float)->Data {u32(n.bitPattern)}
    private struct Fixture {
        var bytes=Data()
        var views=[[String:Any]]()
        var accessors=[[String:Any]]()
        var meshes=[[String:Any]]()
        var nodes=[[String:Any]]()
        var roots=[Int]()
        mutating func addBuffer(_ data:Data)->Int {
            let aligned=(4-bytes.count%4)%4
            bytes.append(Data(repeating:0,count:aligned))
            let index=views.count
            views.append(["buffer":0,"byteOffset":bytes.count,"byteLength":data.count])
            bytes.append(data)
            return index
        }
        mutating func pos(_ points:[Float],component:Int=5126,normalized:Bool=false)->Int {
            var binary=Data()
            if component==5126 {
                for value in points {binary.append(H55CollisionGeometry580Tests.f32(value))}
            } else {
                for value in points {
                    let n=UInt16((max(0,min(1,value))*65535).rounded())
                    binary.append(H55CollisionGeometry580Tests.u16(n))
                }
            }
            let view=addBuffer(binary),id=accessors.count
            accessors.append(["bufferView":view,"componentType":component,
                              "count":points.count/3,"type":"VEC3",
                              "normalized":normalized])
            return id
        }
        mutating func indices(_ items:[Int])->Int {
            var binary=Data()
            for value in items {binary.append(H55CollisionGeometry580Tests.u16(UInt16(value)))}
            let view=addBuffer(binary),id=accessors.count
            accessors.append(["bufferView":view,"componentType":5123,
                              "count":items.count,"type":"SCALAR"])
            return id
        }
        mutating func mesh(_ pos:Int,_ indices:Int)->Int {
            let id=meshes.count
            meshes.append(["primitives":[["mode":4,"indices":indices,
                                            "attributes":["POSITION":pos]]]])
            return id
        }
        mutating func node(_ value:[String:Any],root:Bool=true)->Int {
            let id=nodes.count
            nodes.append(value)
            if root {roots.append(id)}
            return id
        }
        func write(_ url:URL)throws {
            let doc:[String:Any]=[
                "asset":["version":"2.0"],
                "scene":0,"scenes":[["nodes":roots]],
                "nodes":nodes,"meshes":meshes,"accessors":accessors,
                "bufferViews":views,
                "buffers":[["byteLength":bytes.count]]
            ]
            var json=try JSONSerialization.data(withJSONObject:doc,options:[.sortedKeys])
            json.append(Data(repeating:0x20,count:(4-json.count%4)%4))
            var bin=bytes
            bin.append(Data(repeating:0,count:(4-bin.count%4)%4))
            let size=28+json.count+bin.count
            var glb=Data()
            glb.append(H55CollisionGeometry580Tests.u32(0x46546c67))
            glb.append(H55CollisionGeometry580Tests.u32(2))
            glb.append(H55CollisionGeometry580Tests.u32(UInt32(size)))
            glb.append(H55CollisionGeometry580Tests.u32(UInt32(json.count)))
            glb.append(H55CollisionGeometry580Tests.u32(0x4e4f534a))
            glb.append(json)
            glb.append(H55CollisionGeometry580Tests.u32(UInt32(bin.count)))
            glb.append(H55CollisionGeometry580Tests.u32(0x004e4942))
            glb.append(bin)
            try glb.write(to:url)
        }
    }
    static func main() throws {
        var f=Fixture()
        let architecture=f.pos([0,0,0,1,0,0,0,0,1])
        let many=f.indices(Array(repeating:[0,1,2],count:10_000).flatMap{$0})
        let staticMesh=f.mesh(architecture,many)
        _=f.node(["name":"H55_STATIC","mesh":staticMesh,
                   "translation":[2,0,0]])
        let quantized=f.pos([0,0,0,1,0,0,0,0,1],component:5123,normalized:true)
        let one=f.indices([0,1,2])
        let importedMesh=f.mesh(quantized,one)
        let parent=f.node(["name":"HL_Import_original_mesh",
            "extras":["hangarLabPrefabId":"HL_IMPORT_2317"],
            "matrix":[1,0,0,0,0,1,0,0,0,0,1,0,5,0,0,1],
            "children":[2]])
        check(parent==1,"parent index construction")
        _=f.node(["name":"HL_Import_1785_legacy_name","mesh":importedMesh],
                  root:false)
        // Authored dynamic drone instances: source selects nearest TWO
        // actual matrix-placed drone imports near the original mechanic.
        for (idx,x) in [(1835,Float(10)),(1837,Float(11)),(1839,Float(15))] {
            let rootId=f.nodes.count
            let group="HL_IMPORT_\(idx)"
            _=f.node(["name":"HL_Import_drone_\(idx)",
                "matrix":[1,0,0,0,0,1,0,0,0,0,1,0,x,0,12,1],
                "children":[rootId+1],
                "extras":["hangarLabPrefabId":group,
                           "hangarLabImported":true,
                           "hangarLabImportName":"dron"]])
            _=f.node(["name":"static_source_name_\(idx)",
                       "mesh":importedMesh],root:false)
        }
        // Original GLB animated airlock leaves rest-pose static collider out.
        _=f.node(["name":"H70_HANGAR_AIRLOCK_panel","mesh":staticMesh])
        let path=FileManager.default.temporaryDirectory
            .appendingPathComponent("h02-authentic-GLB-\(UUID().uuidString).glb")
        defer{try? FileManager.default.removeItem(at:path)}
        try f.write(path)
        let result=try H55CollisionGeometry580.fromGLB(path)
        check(result.sceneNodes==10,"active scene descendants + doors")
        check(result.sourceTriangles==10_002,"dynamic drone instances omitted, source triangles counted")
        check(result.proxyTriangles==2,"two static proxies: authored prefab and third drone")
        check(result.triangles.count==90_054,"10k architectural triangles + source six bridge triangles")
        check(result.objects.count==2,"two distinct physical instance ids")
        check(result.objects.contains(where:{$0.name=="HL_IMPORT_2317"}),
              "prefab instance id inherited from ancestor, not legacy mesh-name number")
        check(result.objects.contains(where:{$0.name=="HL_IMPORT_1839"}),
              "third imported drone remains a physical static prefab")
        check(!result.objects.contains(where:{$0.name=="HL_IMPORT_1835"}) &&
              !result.objects.contains(where:{$0.name=="HL_IMPORT_1837"}),
              "two active drone actors excluded from static collision")
        check(abs(result.triangles[0]-2)<0.0001 &&
              abs(result.triangles[3]-3)<0.0001,
              "architectural glTF TRS applied in world metres")
        check(abs(result.minX-2)<0.0001 && result.maxX>=15,
              "original active-scene bounds computed after exclusions")
        let invalid=path.deletingLastPathComponent().appendingPathComponent(
            "h02-invalid-\(UUID().uuidString).glb")
        defer{try? FileManager.default.removeItem(at:invalid)}
        try Data([1,2,3,4,5,6]).write(to:invalid)
        do {
            _=try H55CollisionGeometry580.fromGLB(invalid)
            preconditionFailure("invalid input must not generate geometry")
        } catch H55CollisionGeometry580.Invalid.glb {}
        print("PASS H02 original GLB binary transforms/indices, 10k triangles, quantized positions, per-instance prefab IDs, 2 moving drones, third static drone, animated door exclusion, bridge, bounds")
    }
}
