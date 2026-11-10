import Foundation

/// Compatibility at the GLTFKit2 *import boundary* only.
/// The original PC602 planetarium.glb remains immutable and SHA-verified.
/// PC602's H55 renderer accepts unnormalized UINT8 COLOR_0 accessors, whereas
/// glTF 2.0 requires COLOR_0 UINT8/UINT16 to be normalized. The repair only
/// changes JSON accessor metadata; the entire BIN chunk is copied verbatim.
enum HudPlanetariumGLTFImport {
    enum ImportError: Error {
        case invalidContainer
        case invalidJSON
        case unexpectedOriginal
    }

    private static let magic:UInt32=0x46546C67
    private static let jsonType:UInt32=0x4E4F534A

    private static func read32(_ data:Data,_ position:Int)->UInt32? {
        guard position>=0,position+4<=data.count else{return nil}
        return UInt32(data[position]) |
            (UInt32(data[position+1]) << 8) |
            (UInt32(data[position+2]) << 16) |
            (UInt32(data[position+3]) << 24)
    }

    private static func put32(_ value:UInt32,into data:inout Data) {
        let x=value.littleEndian
        withUnsafeBytes(of:x) {data.append(contentsOf:$0)}
    }

    /// The imported copy must have all genuine node/mesh/animation data.
    /// No changes to material, geometry, keyframes or vertex colors.
    static func compatibleBytes(_ original:Data) throws -> (data:Data,fixed:Int) {
        guard original.count>=28,
              read32(original,0)==magic,
              read32(original,4)==2,
              read32(original,8)==UInt32(original.count),
              read32(original,16)==jsonType,
              let jsonSize=read32(original,12),
              jsonSize%4==0,
              Int(jsonSize)+20<=original.count else {
            throw ImportError.invalidContainer
        }
        let jsonEnd=20+Int(jsonSize)
        let payload=original.subdata(in:20..<jsonEnd)
        guard var root=try JSONSerialization.jsonObject(with:payload)
                    as? [String:Any],
              var accessors=root["accessors"] as? [[String:Any]],
              let meshes=root["meshes"] as? [[String:Any]],
              let nodes=root["nodes"] as? [[String:Any]],
              nodes.count==HudPlanetariumAsset600.nodes,
              let clips=root["animations"] as? [[String:Any]],
              clips.count==1,
              let channels=clips[0]["channels"] as? [[String:Any]],
              channels.count==HudPlanetariumAsset600.channels else {
            throw ImportError.invalidJSON
        }
        var changed=Set<Int>()
        for mesh in meshes {
            guard let primitives=mesh["primitives"] as? [[String:Any]] else {
                throw ImportError.invalidJSON
            }
            for primitive in primitives {
                guard let attrs=primitive["attributes"] as? [String:Int],
                      let colorIndex=attrs["COLOR_0"] else {continue}
                guard accessors.indices.contains(colorIndex) else {
                    throw ImportError.invalidJSON
                }
                var color=accessors[colorIndex]
                guard let kind=color["componentType"] as? Int,
                      let shape=color["type"] as? String else {
                    throw ImportError.invalidJSON
                }
                if kind==5121 || kind==5123 {
                    guard shape=="VEC3" || shape=="VEC4" else {
                        throw ImportError.invalidJSON
                    }
                    if (color["normalized"] as? Bool) != true {
                        color["normalized"]=true
                        accessors[colorIndex]=color
                        changed.insert(colorIndex)
                    }
                }
            }
        }

        // The approved PC602 asset has precisely 12 invalid COLOR_0
        // accessors. Never reinterpret an unknown replacement GLB.
        guard changed.count==12 else {throw ImportError.unexpectedOriginal}
        root["accessors"]=accessors
        let encoded=try JSONSerialization.data(withJSONObject:root,
                                               options:[.sortedKeys])
        var json=encoded
        while json.count%4 != 0 {json.append(0x20)}
        let remaining=original.subdata(in:jsonEnd..<original.count)
        let size=12+8+json.count+remaining.count
        guard size<=Int(UInt32.max),json.count<=Int(UInt32.max) else {
            throw ImportError.invalidContainer
        }
        var result=Data(capacity:size)
        put32(magic,into:&result)
        put32(2,into:&result)
        put32(UInt32(size),into:&result)
        put32(UInt32(json.count),into:&result)
        put32(jsonType,into:&result)
        result.append(json)
        result.append(remaining)

        // A byte-for-byte identical BIN chunk is essential for the
        // original 159-channel animation and detailed meshes.
        guard result.count==size,
              read32(result,8)==UInt32(size),
              result.subdata(in:(20+json.count)..<result.count)==remaining else {
            throw ImportError.invalidContainer
        }
        return (result,changed.count)
    }

    /// Called once per SceneKit load. The authoritative original file stays
    /// in the app bundle or Application Support; only the temporary copy
    /// passes through GLTFKit2.
    static func compatibleURL(originalBytes:Data) throws -> URL {
        try HudPlanetariumAsset600.validate(originalBytes)
        let normalized=try compatibleBytes(originalBytes)
        let cache=FileManager.default.urls(for:.cachesDirectory,
            in:.userDomainMask)[0]
            .appendingPathComponent("planetarium-gltfkit-compatible.glb")
        if let existing=try? Data(contentsOf:cache),
           existing==normalized.data {return cache}
        try normalized.data.write(to:cache,options:.atomic)
        NSLog("HUD602 planetarium: glTF COLOR_0 normalized (%d accessors), original BIN preserved",
              normalized.fixed)
        return cache
    }
}
