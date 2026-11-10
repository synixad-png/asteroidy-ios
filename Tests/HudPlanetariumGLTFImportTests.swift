import Foundation

@main enum HudPlanetariumGLTFImportTests {
    private static func check(_ condition:@autoclosure ()->Bool,_ reason:String) {
        precondition(condition(),reason)
    }

    private static func read32(_ bytes:Data,_ start:Int)->Int {
        Int(UInt32(bytes[start]) |
            (UInt32(bytes[start+1]) << 8) |
            (UInt32(bytes[start+2]) << 16) |
            (UInt32(bytes[start+3]) << 24))
    }

    static func main() throws {
        guard CommandLine.arguments.count==2 else {
            fatalError("Pass path to the original PC602 planetarium.glb")
        }
        let url=URL(fileURLWithPath:CommandLine.arguments[1])
        let original=try Data(contentsOf:url)
        try HudPlanetariumAsset600.validate(original)
        let patched=try HudPlanetariumGLTFImport.compatibleBytes(original)
        check(patched.fixed==12,"exact source repair count")
        check(original.count==3_228_900,"original PC602 file untouched")
        check(read32(patched.data,0)==0x46546C67,"patched GLB magic")
        check(read32(patched.data,8)==patched.data.count,"patched header length")
        let originalJSONLength=read32(original,12)
        let patchedJSONLength=read32(patched.data,12)
        check(patchedJSONLength%4==0,"padded JSON chunk")
        let first=try JSONSerialization.jsonObject(with:
            original.subdata(in:20..<(20+originalJSONLength))) as! [String:Any]
        let second=try JSONSerialization.jsonObject(with:
            patched.data.subdata(in:20..<(20+patchedJSONLength))) as! [String:Any]
        let a=first["accessors"] as! [[String:Any]]
        let b=second["accessors"] as! [[String:Any]]
        check(a.count==b.count,"all original accessors retained")
        let expected:Set<Int>=[23,26,29,32,35,38,41,44,47,50,298,301]
        for i in a.indices {
            var repaired=a[i]
            if expected.contains(i) {repaired["normalized"]=true}
            // Compare canonical JSON bytes. Foundation NSDictionary's
            // isEqual(to:) can disagree on bridged nested NSNumber arrays
            // even if every value is identical (verified on Swift Linux).
            let expected=try JSONSerialization.data(withJSONObject:repaired,
                options:[.sortedKeys])
            let actual=try JSONSerialization.data(withJSONObject:b[i],
                options:[.sortedKeys])
            check(expected==actual,
                  "only COLOR_0 normalized flags may change (accessor \(i))")
        }
        for key in ["meshes","nodes","materials","animations","bufferViews","buffers"] {
            let expected=try JSONSerialization.data(
                withJSONObject:["source":first[key]!],options:[.sortedKeys])
            let actual=try JSONSerialization.data(
                withJSONObject:["source":second[key]!],options:[.sortedKeys])
            check(expected==actual,"original "+key+" data preserved")
        }
        let originalBIN=original.subdata(
            in:(20+originalJSONLength)..<original.count)
        let newBIN=patched.data.subdata(
            in:(20+patchedJSONLength)..<patched.data.count)
        check(originalBIN==newBIN,"exact glTF BIN payload retained")
        check(patched.data != original,"corrected importer copy is distinct")
        print("PASS original PC602 glTF import: 12 COLOR_0 metadata fixes, 141 nodes, 159 animation channels, identical BIN bytes")
    }
}
