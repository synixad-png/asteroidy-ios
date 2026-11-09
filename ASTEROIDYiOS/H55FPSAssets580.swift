import Foundation
import CryptoKit

/// Immutable original viewmodel assets from PC v580
/// Shared/assets/gloves417 and Shared/assets/weapon474.
/// Never accepts arbitrary GLB under an approved filename. No substitute meshes.
enum H55FPSAssets580 {
    enum Kind:Int,CaseIterable {
        case tripo=0,monolith=1,weapon=2
        var fileName:String {
            switch self {
            case .tripo:return "gloves_parted.glb"
            case .monolith:return "gloves_combined.glb"
            case .weapon:return "EXP01_SOURCE_v601.glb"
            }
        }
        var bytes:UInt64 {
            switch self {
            case .tripo:return 4_968_356
            case .monolith:return 4_144_252
            case .weapon:return 4_504_600
            }
        }
        var sha256:String {
            switch self {
            case .tripo:return "8a494bbd9a3dd6eb70cb5e22a7db4da7ec33b069dc1b0bab36f6a1c5b4c257ca"
            case .monolith:return "643bfa2799535852362103fa4d24b84d712637d686e773403214400a31ae4516"
            case .weapon:return "07403302f23cb81ce6c26501ca7361c646550c6f91e0a949ce81566553139762"
            }
        }
    }

    enum Failure:Error,LocalizedError {
        case wrongOriginal,invalidFormat
        var errorDescription:String? {
            switch self {
            case .wrongOriginal:return "To nie jest zatwierdzony oryginalny model rąk lub broni z Windows v580."
            case .invalidFormat:return "Model nie jest poprawnym plikiem GLB 2.0."
            }
        }
    }
    private static func directory() throws -> URL {
        let home=try FileManager.default.url(for:.applicationSupportDirectory,
            in:.userDomainMask,appropriateFor:nil,create:true)
        let result=home.appendingPathComponent("H55_FPS_MODELE_580",isDirectory:true)
        try FileManager.default.createDirectory(at:result,
            withIntermediateDirectories:true)
        return result
    }
    static func valid(_ url:URL,as kind:Kind)->Bool {
        guard let info=try? FileManager.default.attributesOfItem(atPath:url.path),
              (info[.size] as? NSNumber)?.uint64Value==kind.bytes,
              let f=try? FileHandle(forReadingFrom:url) else{return false}
        defer{try? f.close()}
        guard let header=try? f.read(upToCount:12),let header,
              header.count==12,
              header.prefix(4)==Data([0x67,0x6c,0x54,0x46]),
              header[4]==2,header[5]==0,header[6]==0,header[7]==0 else{return false}
        try? f.seek(toOffset:0)
        var digest=SHA256()
        do {
            while let bytes=try f.read(upToCount:1024*1024),!bytes.isEmpty {
                digest.update(data:bytes)
            }
        }catch{return false}
        return digest.finalize().map{String(format:"%02x",$0)}.joined()==kind.sha256
    }

    static func installed(_ kind:Kind)->URL? {
        guard let folder=try? directory() else{return nil}
        let url=folder.appendingPathComponent(kind.fileName)
        return valid(url,as:kind) ? url : nil
    }
    /// FileImporter grants temporary security scope; persist a validated
    /// copy in the app sandbox, once, separately from the 126 MB hangar GLB.
    @discardableResult static func install(_ url:URL,as kind:Kind)throws->URL {
        let access=url.startAccessingSecurityScopedResource()
        defer {if access {url.stopAccessingSecurityScopedResource()}}
        guard let first=try? FileHandle(forReadingFrom:url) else{throw Failure.invalidFormat}
        let header=try first.read(upToCount:12) ?? Data()
        try? first.close()
        guard header.count==12,header.prefix(4)==Data([0x67,0x6c,0x54,0x46])
        else{throw Failure.invalidFormat}
        guard valid(url,as:kind) else{throw Failure.wrongOriginal}
        let destination=try directory().appendingPathComponent(kind.fileName)
        if destination.standardizedFileURL==url.standardizedFileURL {return destination}
        let temporary=destination.deletingLastPathComponent().appendingPathComponent(UUID().uuidString+".glb")
        defer{try? FileManager.default.removeItem(at:temporary)}
        try FileManager.default.copyItem(at:url,to:temporary)
        guard valid(temporary,as:kind) else{throw Failure.wrongOriginal}
        if FileManager.default.fileExists(atPath:destination.path) {
            try FileManager.default.removeItem(at:destination)
        }
        try FileManager.default.moveItem(at:temporary,to:destination)
        return destination
    }
}

/// PC RendererGloves417.cs HangarViewMode471: 0 hands (default), 1 weapon.
/// Source default calibrations are in GlovesSettings417.cs and WeaponViewSettings470.cs.
struct H55FPSSettings580 {
    enum Mode:Int,CaseIterable {case gloves=0,weapon=1}
    enum Model:Int,CaseIterable {case tripo=0,monolith=1}
    static let keyMode="ASTEROIDY_H55_HANGAR_VIEW_MODE471"
    static let keyModel="ASTEROIDY_H55_GLOVES_MODEL417"
    static let tripoLeft=[-36,-35,-92,-75,-10,-15,130]
    static let tripoRight=[36,-35,-92,-75,10,15,130]
    static let monolithLeft=[-36,-43,-105,0,-10,-15,60]
    static let monolithRight=[36,-43,-105,0,10,15,60]
    static let weaponDefault=[26,-31,-92,-10,18,3,100]
    var mode:Mode
    var model:Model
    var left:[Int],right:[Int],weapon:[Int]
    var bob:Bool
    var idle:Bool
    var fingerAnimation:Bool
    init(store:UserDefaults = .standard) {
        mode=Mode(rawValue:store.integer(forKey:Self.keyMode)) ?? .gloves
        model=Model(rawValue:store.integer(forKey:Self.keyModel)) ?? .tripo
        func pose(_ key:String,_ original:[Int])->[Int] {
            guard let s=store.array(forKey:key) as? [Int],s.count==7,
                  (-150...150).contains(s[0]),(-150...150).contains(s[1]),
                  (-150...150).contains(s[2]),(25...250).contains(s[6]) else{return original}
            return s
        }
        left=pose("ASTEROIDY_H55_FPS_LEFT_580",model == .tripo ? Self.tripoLeft : Self.monolithLeft)
        right=pose("ASTEROIDY_H55_FPS_RIGHT_580",model == .tripo ? Self.tripoRight : Self.monolithRight)
        weapon=pose("ASTEROIDY_H55_FPS_WEAPON_580",Self.weaponDefault)
        bob=store.object(forKey:"ASTEROIDY_H55_FPS_BOB_580") as? Bool ?? true
        idle=store.bool(forKey:"ASTEROIDY_H55_FPS_IDLE_580")
        fingerAnimation=store.object(forKey:"ASTEROIDY_H55_FPS_FINGERS_580") as? Bool ?? true
    }
    mutating func changeModel(_ new:Model,store:UserDefaults = .standard) {
        model=new
        left=new == .tripo ? Self.tripoLeft : Self.monolithLeft
        right=new == .tripo ? Self.tripoRight : Self.monolithRight
        save(store:store)
    }
    func save(store:UserDefaults = .standard) {
        store.set(mode.rawValue,forKey:Self.keyMode)
        store.set(model.rawValue,forKey:Self.keyModel)
        store.set(left,forKey:"ASTEROIDY_H55_FPS_LEFT_580")
        store.set(right,forKey:"ASTEROIDY_H55_FPS_RIGHT_580")
        store.set(weapon,forKey:"ASTEROIDY_H55_FPS_WEAPON_580")
        store.set(bob,forKey:"ASTEROIDY_H55_FPS_BOB_580")
        store.set(idle,forKey:"ASTEROIDY_H55_FPS_IDLE_580")
        store.set(fingerAnimation,forKey:"ASTEROIDY_H55_FPS_FINGERS_580")
    }
}
