import Foundation

@main struct H55Asset580Tests {
    static func main() throws {
        func word(_ value:UInt32)->Data {
            Data([UInt8(value & 255),UInt8((value >> 8) & 255),
                  UInt8((value >> 16) & 255),UInt8((value >> 24) & 255)])
        }
        let clips=[H55Asset580.idleClip,H55Asset580.walkClip,
                   "H70_HANGAR_AIRLOCK_SLIDING_DOORS_8S",
                   "H70_WORKSHOP_AIRLOCK_SLIDING_DOORS_8S"]
        let document:[String:Any]=[
            "nodes":[["name":"MECHANIC_01 / anchor"],
                     ["name":"HL_Import_2023_space_suit_3d_model_ca_o_c_animacji_-_najleps"]],
            "meshes":[["name":"Hangar test"]],
            "skins":Array(repeating:[String:Any](),count:5),
            "animations":clips.map{["name":$0]]
        ]
        let inventory=try H55Asset580.validateDocument(document)
        precondition(inventory.animations.count==4 && inventory.skins==5)
        var obsolete=document
        obsolete["animations"]=[["name":"H39_NO_SHIP_IDLE"]]
        do {
            _=try H55Asset580.validateDocument(obsolete)
            preconditionFailure("Old hangar should not pass")
        } catch H55Asset580.ValidationError.incompatible { }
        let payload=try JSONSerialization.data(withJSONObject:document)
        var padded=payload
        padded.append(Data(repeating:0x20,count:(4-padded.count%4)%4))
        var blob=Data()
        blob.append(word(0x46546C67))
        blob.append(word(2))
        blob.append(word(UInt32(28+padded.count+4)))
        blob.append(word(UInt32(padded.count)))
        blob.append(word(0x4E4F534A))
        blob.append(padded)
        blob.append(word(4))
        blob.append(word(0x004E4942))
        blob.append(Data(repeating:0,count:4))
        let url=FileManager.default.temporaryDirectory
            .appendingPathComponent("h55-validate-\(UUID().uuidString).glb")
        defer{try? FileManager.default.removeItem(at:url)}
        try blob.write(to:url)
        let verified=try H55Asset580.inspect(url,requireUserAsset:false)
        precondition(verified.nodes==2 && verified.meshes==1)
        do {
            _=try H55Asset580.inspect(url)
            preconditionFailure("Only the 126 MB approved H55 file may be installed")
        } catch H55Asset580.ValidationError.checksum { }
        // Truncated GLB must fail before JSON is parsed.
        try blob.prefix(24).write(to:url)
        do {
            _=try H55Asset580.inspect(url,requireUserAsset:false)
            preconditionFailure("Truncated binary must be rejected")
        } catch H55Asset580.ValidationError.unsupported { }
        print("PASS: source v580 H55 GLB structure, required NPC clips, old-scene rejection and identity gate")
    }
}
