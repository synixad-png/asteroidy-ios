import Foundation

/// H12 small synthetic glTF2 fixture exercises REAL accessor parsing and
/// imported-root arbitration. It is NOT a stand-in for the 126MB H55 GLB
/// required for full PC v580 real-world parity and iPhone/iPad acceptance.
@main struct H55H12Tracks580Tests {
    private struct Spec {
        let name:String
        let duration:Float
        let target:Int
        let meta:Bool
        init(_ name:String,_ duration:Float,_ target:Int,_ meta:Bool=false) {
            self.name=name;self.duration=duration;self.target=target
            self.meta=meta
        }
    }
    private static func check(_ ok:Bool,_ message:String) {
        precondition(ok,"H12 original GLB parser: "+message)
    }
    private static func append32(_ n:UInt32,_ bytes:inout Data) {
        let v=n.littleEndian
        withUnsafeBytes(of:v) {bytes.append(contentsOf:$0)}
    }
    private static func writeGLB(_ specs:[Spec],url:URL)throws {
        let nodes:[[String:Any]]=[
            ["name":"H55_Base"],
            ["name":"HL_Import_Workshop_Tool","children":[2]],
            ["name":"HL_Workshop_Part"],
            ["name":"NPC525_Character"],
            ["name":"H70_Door"],
            ["name":"H39_Lamp"]
        ]
        var bin=Data()
        var accessors=[[String:Any]]()
        var views=[[String:Any]]()
        var animations=[[String:Any]]()
        func accessor(_ values:[Float],_ kind:String)->Int {
            let offset=bin.count
            for value in values {append32(value.bitPattern,&bin)}
            let view=views.count
            views.append(["buffer":0,"byteOffset":offset,
                          "byteLength":values.count*4])
            let id=accessors.count
            accessors.append(["bufferView":view,"componentType":5126,
                              "count":kind=="SCALAR" ? values.count : values.count/3,
                              "type":kind])
            return id
        }
        for spec in specs {
            let t=accessor([0,spec.duration],"SCALAR")
            let v=accessor([0,0,0,1,2,3],"VEC3")
            var item:[String:Any]=[
                "name":spec.name,
                "samplers":[["input":t,"output":v,
                              "interpolation":"LINEAR"]],
                "channels":[["sampler":0,
                             "target":["node":spec.target,
                                       "path":"translation"]]]
            ]
            if spec.meta {
                item["extras"]=["ANIMATION_LOOP":true,
                                "ANIMATION_SPEED":1.5]
            }
            animations.append(item)
        }
        while bin.count%4 != 0 {bin.append(0)}
        let doc:[String:Any]=[
            "asset":["version":"2.0"],
            "nodes":nodes,
            "animations":animations,
            "buffers":[["byteLength":bin.count]],
            "bufferViews":views,
            "accessors":accessors,
            "scenes":[["nodes":[0,1,3,4,5]]],
            "scene":0
        ]
        var json=try JSONSerialization.data(
            withJSONObject:doc,options:[.sortedKeys])
        while json.count%4 != 0 {json.append(32)}
        let length=12+8+json.count+8+bin.count
        var glb=Data()
        append32(0x46546c67,&glb)
        append32(2,&glb)
        append32(UInt32(length),&glb)
        append32(UInt32(json.count),&glb)
        append32(0x4e4f534a,&glb)
        glb.append(json)
        append32(UInt32(bin.count),&glb)
        append32(0x004e4942,&glb)
        glb.append(bin)
        check(glb.count==length,"valid little-endian GLB2 chunk lengths")
        try glb.write(to:url,options:.atomic)
    }
    static func main() throws {
        let folder=FileManager.default.temporaryDirectory
            .appendingPathComponent("h12-glb-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at:folder,withIntermediateDirectories:true)
        defer {try? FileManager.default.removeItem(at:folder)}
        let url=folder.appendingPathComponent("valid.glb")
        let specs=[
            Spec(H55H12Timeline580.docking,32,0),
            Spec(H55H12Timeline580.service,96,0),
            Spec(H55H12Timeline580.turbines,2.4,0),
            Spec(H55H12Timeline580.arms,96,0),
            Spec(H55H12Timeline580.lighting,20,0),
            Spec(H55H12Timeline580.crane,16,0),
            Spec("H39_Idle_Natural_24s_NO_ARMS",24,3),
            Spec("HL_TOOL_IDLE",10,2),
            Spec("HL_TOOL_LOOP",7,2),
            Spec("HL_TOOL_OTHER",8,2),
            Spec("H39_META_LOOP",8,5,true),
            Spec("NPC525_Walk",2.375,3),
            Spec("H70_HANGAR_AIRLOCK_SLIDING_DOORS_8S",8,4),
            Spec("H51_03_INVALID_AUTOPLAY",64,0),
            Spec("HL_DOCK_CLAMPS_LOOP",5,2)
        ]
        try writeGLB(specs,url:url)
        let lib=try H55H12Tracks580.load(url)
        check(lib.imported.count==1 &&
              lib.imported[0].name=="HL_TOOL_LOOP",
              "one source-ranked LOOP per imported root, not IDLE/OTHER")
        check(lib.metadata.count==1 &&
              lib.metadata[0].name=="H39_META_LOOP" &&
              lib.metadata[0].speed==1.5,
              "explicit authored metadata loop speed retained")
        check(lib.morphIdle=="H39_Idle_Natural_24s_NO_ARMS",
              "natural idle clip preserved but protected NPC bound separately")
        check(lib.clips.count==9 &&
              lib.clips["HL_TOOL_IDLE"]==nil &&
              lib.clips["HL_TOOL_LOOP"] != nil &&
              lib.clips["NPC525_Walk"]==nil &&
              lib.clips["H70_HANGAR_AIRLOCK_SLIDING_DOORS_8S"]==nil &&
              lib.clips["H51_03_INVALID_AUTOPLAY"]==nil,
              "parse exactly original six + idle + one import + metadata")
        let raw=lib.clips[H55H12Timeline580.docking]!
        check(raw.tracks.count==1 && raw.tracks[0].times.count==2,
              "read original little-endian glTF accessor and two keyframes")
        let p=raw.tracks[0].sample(16)
        check(abs(p[0]-0.5)<0.00001 &&
              abs(p[1]-1)<0.00001 &&
              abs(p[2]-1.5)<0.00001,
              "real accessor LINEAR translation sampled mid-key")
        let frame=lib.frame(48)
        check(frame.count==8 &&
              frame[0].clip==H55H12Timeline580.service &&
              frame[6].clip=="HL_TOOL_LOOP" &&
              frame[7].clip=="H39_META_LOOP",
              "source overlay order: H51, fixed, idle, imported auto, metadata")
        let truncated=folder.appendingPathComponent("truncated.glb")
        var damaged=try Data(contentsOf:url)
        damaged.removeLast()
        try damaged.write(to:truncated,options:.atomic)
        check((try? H55H12Tracks580.load(truncated))==nil,
              "truncated GLB must never create synthesized animation")
        print("PASS H12 source GLB2 parser: real FLOAT32 accessors, 6 original durations, H51 key sampling, imported LOOP/IDLE priority, metadata speed, H70/NPC exclusions and corrupt file fail-safe")
    }
}
