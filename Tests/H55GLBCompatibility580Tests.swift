import Foundation

@main struct H55GLBCompatibility580Tests {
    static func main() throws {
        func check(_ good:Bool,_ msg:String) {precondition(good,msg)}
        func word(_ n:UInt32)->Data {
            Data((0..<4).map {UInt8((n >> ($0*8)) & 255)})
        }
        let record="\"componentType\":5126,\"count\":51,\"type\":\"SCALAR\",\"min\":0,\"max\":10}"
        var json=Data(("{\"accessors\":[{" + record + "]}").utf8)
        json.append(Data(repeating:0x20,count:(4-json.count%4)%4))
        let bin=Data([0x10,0x20,0x30,0x40,0x50,0x60,0x70,0x80])
        var glb=Data()
        glb.append(word(0x46546c67))
        glb.append(word(2))
        glb.append(word(UInt32(28+json.count+bin.count)))
        glb.append(word(UInt32(json.count)))
        glb.append(word(0x4e4f534a))
        glb.append(json)
        glb.append(word(UInt32(bin.count)))
        glb.append(word(0x004e4942))
        glb.append(bin)
        let root=FileManager.default.temporaryDirectory
            .appendingPathComponent("h55-cgltf-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at:root,
                                              withIntermediateDirectories:true)
        defer {try? FileManager.default.removeItem(at:root)}
        let original=root.appendingPathComponent("original.glb")
        let repaired=root.appendingPathComponent("repaired.glb")
        try glb.write(to:original)
        let size=try H55GLBCompatibility580.repair(original:original,to:repaired)
        let raw=try Data(contentsOf:original)
        let fixed=try Data(contentsOf:repaired)
        check(raw==glb,"user original is never modified")
        check(size==UInt64(glb.count+4) && fixed.count==glb.count+4,
              "only four JSON bytes added")
        func u32(_ data:Data,_ offset:Int)->UInt32 {
            UInt32(data[offset]) | UInt32(data[offset+1])<<8 |
              UInt32(data[offset+2])<<16 | UInt32(data[offset+3])<<24
        }
        check(u32(fixed,8)==UInt32(glb.count+4),
              "whole GLB length is updated")
        check(u32(fixed,12)==UInt32(json.count+4),
              "GLB JSON chunk length is updated")
        let repairedDocument=try JSONSerialization.jsonObject(
            with:fixed[20..<(20+json.count+4)]) as! [String:Any]
        let accessor=(repairedDocument["accessors"] as! [[String:Any]])[0]
        check((accessor["min"] as? [Int]) == [0] &&
              (accessor["max"] as? [Int]) == [10],
              "glTF 2.0 SCALAR ranges must be arrays")
        check(fixed.suffix(bin.count)==bin,"all GLB binary bytes are unchanged")
        do {
            let dest=root.appendingPathComponent("duplicate.glb")
            _=try H55GLBCompatibility580.repair(original:repaired,to:dest)
            preconditionFailure("Already repaired source must not silently rewrite")
        } catch H55GLBCompatibility580.RepairError.mismatchedSource {}
        print("PASS: H55 only 4 JSON bytes corrected, glTF min/max arrays, unchanged geometry/animation BIN and unchanged user original")
    }
}
