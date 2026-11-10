import Foundation
import CryptoKit

/// Only the exact original PC v600 planetarium GLB is accepted.
/// The user supplied model is installed once in Application Support.
/// No approximate mesh, PNG, alternate 3D asset or silent fallback.
enum HudPlanetariumAsset600 {
    static let fileName = "planetarium.glb"
    static let expectedSize = 3_228_900
    static let sha256 = "71ca9ff24e044a831a5c7197e343594dd1fd801284af6231870570b35ad43860"
    static let clipName = "HUD_PLANETARIUM_PREMIUM_48S_LOOP"
    static let nodes = 141
    static let channels = 159

    enum Failure: Error, LocalizedError {
        case missing, invalidStructure, unexpectedAsset, invalidAnimation
        var errorDescription: String? {
            switch self {
            case .missing: return "Brak oryginalnego planetarium.glb z ASTEROIDY PC v600."
            case .invalidStructure: return "Planetarium GLB ma niepoprawną strukturę."
            case .unexpectedAsset: return "Model różni się od zatwierdzonego PC v600."
            case .invalidAnimation: return "Brak oryginalnych 159 kanałów animacji planetarium."
            }
        }
    }

    private static func uint32(_ data:Data,_ offset:Int)->UInt32? {
        guard offset>=0 && offset<=data.count-4 else{return nil}
        return UInt32(data[offset])
            | (UInt32(data[offset+1]) << 8)
            | (UInt32(data[offset+2]) << 16)
            | (UInt32(data[offset+3]) << 24)
    }

    static func validate(_ bytes:Data) throws {
        guard bytes.count==expectedSize else{throw Failure.unexpectedAsset}
        guard uint32(bytes,0)==0x46546c67,
              uint32(bytes,4)==2,uint32(bytes,8)==UInt32(bytes.count),
              uint32(bytes,16)==0x4e4f534a,
              let jsonLength=uint32(bytes,12),
              jsonLength>0,
              Int(jsonLength)<=bytes.count-28 else {
            throw Failure.invalidStructure
        }
        let digest=SHA256.hash(data:bytes).map{String(format:"%02x",$0)}.joined()
        guard digest==sha256 else{throw Failure.unexpectedAsset}
        let json=Data(bytes[20..<(20+Int(jsonLength))])
        guard let object=try? JSONSerialization.jsonObject(with:json) as? [String:Any],
              let gltfNodes=object["nodes"] as? [[String:Any]],
              gltfNodes.count==nodes,
              let animations=object["animations"] as? [[String:Any]],
              animations.count==1,animations[0]["name"] as? String == clipName,
              let tracks=animations[0]["channels"] as? [[String:Any]],
              tracks.count==channels else {
            throw Failure.invalidAnimation
        }
        let names=gltfNodes.compactMap{$0["name"] as? String}
        for i in 0..<3 {
            guard names.filter{$0.hasPrefix("CAPSULE_\(i)_WATER_BUBBLE_")}.count==24
            else{throw Failure.invalidAnimation}
        }
        for name in ["DAMAGE_HULL_FLASH_SOCKET","DAMAGE_ARMOR_FLASH_SOCKET",
                     "DAMAGE_SHIELD_FLASH_SOCKET","SPHERE_OUTER_DOTTED_SKIN"] {
            guard names.contains(name) else{throw Failure.invalidAnimation}
        }
    }

    static func installedURL() throws -> URL {
        let base=try FileManager.default.url(for:.applicationSupportDirectory,
                             in:.userDomainMask,appropriateFor:nil,create:true)
        return base.appendingPathComponent(fileName)
    }
    static func availableURL()->URL? {
        if let installed=try? installedURL(),
           let data=try? Data(contentsOf:installed),
           (try? validate(data)) != nil {return installed}
        if let bundled=Bundle.main.url(forResource:"planetarium",withExtension:"glb"),
           let data=try? Data(contentsOf:bundled),
           (try? validate(data)) != nil {return bundled}
        return nil
    }

    /// Only at explicit import action, never in MTKView/SceneKit frame callbacks.
    @discardableResult
    static func install(from original:URL) throws -> URL {
        let scoped=original.startAccessingSecurityScopedResource()
        defer{if scoped{original.stopAccessingSecurityScopedResource()}}
        let bytes=try Data(contentsOf:original)
        try validate(bytes)
        let destination=try installedURL()
        if original.standardizedFileURL==destination.standardizedFileURL{return destination}
        let temp=destination.deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString+".glb")
        do {
            try bytes.write(to:temp,options:.atomic)
            if FileManager.default.fileExists(atPath:destination.path) {
                _ = try FileManager.default.replaceItemAt(destination,withItemAt:temp)
            } else {
                try FileManager.default.moveItem(at:temp,to:destination)
            }
        } catch {
            try? FileManager.default.removeItem(at:temp)
            throw error
        }
        return destination
    }
}
