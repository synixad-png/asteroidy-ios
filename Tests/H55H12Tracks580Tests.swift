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
        let rotation:Bool
        init(_ name:String,_ duration:Float,_ target:Int,
             _ meta:Bool=false,rotation:Bool=false) {
            self.name=name;self.duration=duration;self.target=target
            self.meta=meta;self.rotation=rotation
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
            ["name":"H39_Lamp"],
            ["name":"HL_Import_Drone","children":[7],
             "extras":["hangarLabImported":true,
                       "hangarLabImportName":"drone for service"]],
            ["name":"HL_Drone_Rotor"]
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
                              "count":kind=="SCALAR" ? values.count :
                                     values.count/(kind=="VEC4" ? 4 : 3),
                              "type":kind])
            return id
        }
        for spec in specs {
            let t=accessor([0,spec.duration],"SCALAR")
            let v=spec.rotation ?
                accessor([0,0,0,1,0,0,1,0],"VEC4") :
                accessor([0,0,0,1,2,3],"VEC3")
            var item:[String:Any]=[
                "name":spec.name,
                "samplers":[["input":t,"output":v,
                              "interpolation":"LINEAR"]],
                "channels":[["sampler":0,
                             "target":["node":spec.target,
                                       "path":spec.rotation ? "rotation" : "translation"]]]
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
            Spec(H55H12Timeline580.service,96,0,false,rotation:true),
            Spec(H55H12Timeline580.turbines,2.4,0),
            Spec(H55H12Timeline580.arms,96,0),
            Spec(H55H12Timeline580.lighting,20,0),
            Spec(H55H12Timeline580.crane,16,0),
            Spec("H39_Idle_Natural_24s_NO_ARMS",24,3),
            Spec("HL_TOOL_IDLE",10,2),
            Spec("HL_TOOL_LOOP",7,2),
            Spec("HL_TOOL_OTHER",8,2),
            Spec("H39_META_LOOP",8,5,true),
            Spec("HL_DRONE_LOOP",6,7),
            Spec("H39_DRONE_META_LOOP",4,7,true),
            Spec("NPC525_Walk",2.375,3),
            Spec("H70_HANGAR_AIRLOCK_SLIDING_DOORS_8S",8,4),
            Spec("H51_03_INVALID_AUTOPLAY",64,0),
            Spec("HL_DOCK_CLAMPS_LOOP",5,2)
        ]
        try writeGLB(specs,url:url)
        // Default reader can preserve the old H71 selection for later,
        // but the active H12 scene MUST exclude user-deferred drone loops.
        let withDrones=try H55H12Tracks580.load(url)
        check(withDrones.imported.count==2 &&
              withDrones.metadata.count==2 &&
              withDrones.clips["HL_DRONE_LOOP"] != nil,
              "legacy authored H71 loops retained for future opt-in")
        let lib=try H55H12Tracks580.load(
            url,excludeImportedDroneRoots:true)
        check(lib.imported.count==1 &&
              lib.imported[0].name=="HL_TOOL_LOOP",
              "one source-ranked LOOP per imported root, not IDLE/OTHER")
        check(lib.metadata.count==1 &&
              lib.metadata[0].name=="H39_META_LOOP" &&
              lib.metadata[0].speed==1.5,
              "explicit authored metadata loop speed retained")
        check(lib.clips["HL_DRONE_LOOP"] == nil &&
              lib.clips["H39_DRONE_META_LOOP"] == nil,
              "deferred drones cannot animate even through metadata GLB loops")
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
        var scratch=[Float](repeating:-123,count:64)
        raw.tracks[0].sample(16,into:&scratch)
        check(Array(scratch.prefix(3))==p && scratch[3] == -123,
              "allocation-free sampler returns exactly original translation and never overwrites adjacent channels")
        check(abs(p[0]-0.5)<0.00001 &&
              abs(p[1]-1)<0.00001 &&
              abs(p[2]-1.5)<0.00001,
              "real accessor LINEAR translation sampled mid-key")
        let q=lib.clips[H55H12Timeline580.service]!.tracks[0].sample(48)
        let half:Float=0.70710678
        lib.clips[H55H12Timeline580.service]!.tracks[0].sample(48,into:&scratch)
        check(Array(scratch.prefix(4))==q,
              "allocation-free quaternion SLERP matches original native values")
        check(q.count==4 && abs(q[2]-half)<0.0001 &&
              abs(q[3]-half)<0.0001,
              "original glTF FLOAT32 rotation uses normalized shortest-arc SLERP")
        let opposite=H55H12Tracks580.Track(
            nodeName:"QuaternionTest",path:.rotation,
            times:[0,1],values:[0,0,0,1,0,0,0,-1],
            width:4,step:false).sample(0.5)
        check(abs(opposite[3]-1)<0.0001 &&
              abs(opposite[2])<0.0001,
              "antipodal quaternions take shortest arc, never collapse to zero")
        let step=H55H12Tracks580.Track(
            nodeName:"StepTest",path:.translation,
            times:[0,1],values:[1,2,3,4,5,6],
            width:3,step:true).sample(0.75)
        check(step==[1,2,3],"original glTF STEP never interpolates")
        let stepTrack=H55H12Tracks580.Track(
            nodeName:"StepTest",path:.translation,
            times:[0,1],values:[1,2,3,4,5,6],
            width:3,step:true)
        stepTrack.sample(0.75,into:&scratch)
        check(Array(scratch.prefix(3))==step,
              "allocation-free glTF STEP never blends or changes authored keys")
        // H12 is sampled every rendered frame, not only on the first loop.
        // Reuse the SAME scratch across the entire repair/arms sequence.
        for tick in 0..<12_000 {
            let t=Float(tick)*Float(1.0/120.0)
            let track=lib.clips[H55H12Timeline580.service]!.tracks[0]
            track.sample(t,into:&scratch)
            let expected=track.sample(t)
            check(Array(scratch.prefix(4))==expected,
                  "120Hz quaternion trace must remain byte-equivalent with reusable buffer")
        }
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
        print("PASS H12 source GLB2 parser: real FLOAT32 accessors and quaternion SLERP/STEP, 6 original durations, H51 key sampling, imported LOOP/IDLE priority, metadata speed, H70/NPC exclusions and corrupt file fail-safe")
    }
}
