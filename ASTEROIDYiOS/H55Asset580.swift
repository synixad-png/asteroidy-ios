import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Only the user-supplied v580 H55/H71 scene is accepted. The old 2D/legacy
/// hangar is not a fallback. This file contains no renderer or UI logic.
enum H55Asset580 {
    static let fileName = "hangar_h55.glb"
    static let byteCount: UInt64 = 126_419_336
    static let sha256 = "00e6ba4ab2cce025b1290265052c1e252e149209f6fcbbc50b5d569af4592461"
    static let idleClip = "NPC525_standing_relax.001"
    static let walkClip = "NPC525_walk.003"

    struct Inventory: Equatable {
        let nodes: Int
        let meshes: Int
        let animations: [String]
        let skins: Int
    }
    enum ValidationError: Error, LocalizedError {
        case absent, unsupported, malformed, incompatible, checksum
        var errorDescription: String? {
            switch self {
            case .absent: return "Brak sceny hangar_h55.glb."
            case .unsupported: return "To nie jest poprawna scena GLB 2.0."
            case .malformed: return "Plik GLB ma uszkodzoną strukturę."
            case .incompatible: return "To nie jest nowy hangar H55 z animowanym mechanikiem."
            case .checksum: return "Scena nie jest zgodna z zatwierdzonym plikiem H55."
            }
        }
    }
    private static func word(_ b: Data, _ off: Int) -> UInt32? {
        guard off >= 0, off <= b.count-4 else { return nil }
        return UInt32(b[off]) | UInt32(b[off+1]) << 8 |
            UInt32(b[off+2]) << 16 | UInt32(b[off+3]) << 24
    }
    static func validateDocument(_ document: [String: Any]) throws -> Inventory {
        guard let nodes=document["nodes"] as? [[String:Any]],
              let meshes=document["meshes"] as? [[String:Any]],
              let skins=document["skins"] as? [[String:Any]],
              let animations=document["animations"] as? [[String:Any]] else {
            throw ValidationError.incompatible
        }
        let names=animations.compactMap { $0["name"] as? String }
        guard names.contains(idleClip), names.contains(walkClip),
              names.contains("H70_HANGAR_AIRLOCK_SLIDING_DOORS_8S"),
              names.contains("H70_WORKSHOP_AIRLOCK_SLIDING_DOORS_8S"),
              skins.count >= 5,
              nodes.contains(where:{ ($0["name"] as? String ?? "").hasPrefix("MECHANIC_01") }),
              nodes.contains(where:{ ($0["name"] as? String ?? "").contains("HL_Import_2023_space_suit") }) else {
            throw ValidationError.incompatible
        }
        return Inventory(nodes:nodes.count,meshes:meshes.count,
                         animations:names,skins:skins.count)
    }
    static func inspect(_ url: URL, requireUserAsset: Bool = true) throws -> Inventory {
        guard FileManager.default.fileExists(atPath:url.path) else {throw ValidationError.absent}
        let size=(try FileManager.default.attributesOfItem(atPath:url.path)[.size] as? NSNumber)?.uint64Value ?? 0
        guard size >= 28, size < 256*1024*1024 else {throw ValidationError.unsupported}
        if requireUserAsset && size != byteCount {throw ValidationError.checksum}
        let f=try FileHandle(forReadingFrom:url)
        defer {try? f.close()}
        let header=try f.read(upToCount:20) ?? Data()
        guard header.count==20,
              word(header,0)==0x46546C67,word(header,4)==2,
              word(header,8)==UInt32(size),word(header,16)==0x4E4F534A,
              let length=word(header,12),length>0,
              UInt64(length)<size-28 else {throw ValidationError.malformed}
        let json=try f.read(upToCount:Int(length)) ?? Data()
        guard json.count==Int(length),
              let value=try JSONSerialization.jsonObject(with:json) as? [String:Any] else {
            throw ValidationError.malformed
        }
        let inventory=try validateDocument(value)
        let binHeader=try f.read(upToCount:8) ?? Data()
        guard binHeader.count==8,word(binHeader,4)==0x004E4942,
              let binLength=word(binHeader,0),binLength>0,
              UInt64(28)+UInt64(length)+UInt64(binLength)<=size else {
            throw ValidationError.malformed
        }
        #if canImport(CryptoKit)
        if requireUserAsset {
            try f.seek(toOffset:0)
            var hash=SHA256()
            while let chunk=try f.read(upToCount:1024*1024), !chunk.isEmpty {
                hash.update(data:chunk)
            }
            let digest=hash.finalize().map{String(format:"%02x",$0)}.joined()
            guard digest==sha256 else {throw ValidationError.checksum}
        }
        #endif
        return inventory
    }
    static func installedURL() throws -> URL {
        let root=try FileManager.default.url(for:.applicationSupportDirectory,
                        in:.userDomainMask,appropriateFor:nil,create:true)
        return root.appendingPathComponent(fileName)
    }
    static func availableURL() -> URL? {
        if let bundled=Bundle.main.url(forResource:"hangar_h55",withExtension:"glb"),
           (try? inspect(bundled)) != nil {return bundled}
        guard let installed=try? installedURL(),
              (try? inspect(installed)) != nil else {return nil}
        return installed
    }
    @discardableResult
    static func install(from url:URL) throws -> URL {
        #if os(iOS) || os(macOS)
        let accessible=url.startAccessingSecurityScopedResource()
        defer {if accessible {url.stopAccessingSecurityScopedResource()}}
        #endif
        _=try inspect(url)
        let destination=try installedURL()
        if url.standardizedFileURL==destination.standardizedFileURL {return destination}
        let temp=destination.deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString+".glb")
        defer {try? FileManager.default.removeItem(at:temp)}
        try FileManager.default.copyItem(at:url,to:temp)
        _=try inspect(temp)
        if FileManager.default.fileExists(atPath:destination.path) {
            try FileManager.default.removeItem(at:destination)
        }
        try FileManager.default.moveItem(at:temp,to:destination)
        return destination
    }
}
