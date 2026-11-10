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
        guard let header=try? f.read(upToCount:12),
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
    enum Target {case left,right,weapon}
    static let keyMode="ASTEROIDY_H55_HANGAR_VIEW_MODE471"
    static let keyModel="ASTEROIDY_H55_GLOVES_MODEL417"
    static let tripoLeft=[-36,-35,-92,-75,-10,-15,130]
    static let tripoRight=[36,-35,-92,-75,10,15,130]
    static let monolithLeft=[-36,-43,-105,0,-10,-15,60]
    static let monolithRight=[36,-43,-105,0,10,15,60]
    static let weaponDefault=[26,-31,-92,-10,18,3,100]
    private static let oldLeftKey="ASTEROIDY_H55_FPS_LEFT_580"
    private static let oldRightKey="ASTEROIDY_H55_FPS_RIGHT_580"
    private static let weaponKey="ASTEROIDY_H55_FPS_WEAPON_580"

    static func limits(_ component:Int)->ClosedRange<Int> {
        switch component {
        case 0...2:return -150...150
        case 3...5:return -180...180
        default:return 25...250
        }
    }
    private static func key(_ model:Model,_ target:Target)->String {
        switch (model,target) {
        case (.tripo,.left):return "ASTEROIDY_H55_FPS_TRIPO_LEFT_580"
        case (.tripo,.right):return "ASTEROIDY_H55_FPS_TRIPO_RIGHT_580"
        case (.monolith,.left):return "ASTEROIDY_H55_FPS_MONOLIT_LEFT_580"
        case (.monolith,.right):return "ASTEROIDY_H55_FPS_MONOLIT_RIGHT_580"
        case (_, .weapon):return weaponKey
        }
    }
    private static func defaults(_ model:Model,_ target:Target)->[Int] {
        switch (model,target) {
        case (.tripo,.left):return tripoLeft
        case (.tripo,.right):return tripoRight
        case (.monolith,.left):return monolithLeft
        case (.monolith,.right):return monolithRight
        case (_, .weapon):return weaponDefault
        }
    }
    private static func read(_ key:String,fallback:[Int],store:UserDefaults)->[Int] {
        guard let saved=store.array(forKey:key) as? [Int],saved.count==7,
              saved.indices.allSatisfy({limits($0).contains(saved[$0])})
        else{return fallback}
        return saved
    }

    var mode:Mode
    var model:Model
    var left:[Int],right:[Int],weapon:[Int]
    var bob:Bool
    var idle:Bool
    var fingerAnimation:Bool
    init(store:UserDefaults = .standard) {
        mode=Mode(rawValue:store.integer(forKey:Self.keyMode)) ?? .gloves
        model=Model(rawValue:store.integer(forKey:Self.keyModel)) ?? .tripo
        // Legacy keys apply only to the previously selected model. Newly
        // selected models use their OWN persisted values or source defaults.
        let previousLeft=Self.read(Self.oldLeftKey,
            fallback:Self.defaults(model,.left),store:store)
        let previousRight=Self.read(Self.oldRightKey,
            fallback:Self.defaults(model,.right),store:store)
        left=Self.read(Self.key(model,.left),fallback:previousLeft,store:store)
        right=Self.read(Self.key(model,.right),fallback:previousRight,store:store)
        weapon=Self.read(Self.weaponKey,fallback:Self.weaponDefault,store:store)
        bob=store.object(forKey:"ASTEROIDY_H55_FPS_BOB_580") as? Bool ?? true
        idle=store.bool(forKey:"ASTEROIDY_H55_FPS_IDLE_580")
        fingerAnimation=store.object(forKey:"ASTEROIDY_H55_FPS_FINGERS_580") as? Bool ?? true
    }
    func pose(_ target:Target)->[Int] {
        switch target {
        case .left:return left
        case .right:return right
        case .weapon:return weapon
        }
    }
    mutating func changeModel(_ new:Model,store:UserDefaults = .standard) {
        guard model != new else{return}
        save(store:store)
        model=new
        left=Self.read(Self.key(model,.left),
            fallback:Self.defaults(model,.left),store:store)
        right=Self.read(Self.key(model,.right),
            fallback:Self.defaults(model,.right),store:store)
        save(store:store)
    }
    mutating func calibrate(_ target:Target,component:Int,value:Int,
                            store:UserDefaults = .standard) {
        guard (0..<7).contains(component),Self.limits(component).contains(value),
              (mode == .weapon ? target == .weapon : target != .weapon) else{return}
        switch target {
        case .left:left[component]=value
        case .right:right[component]=value
        case .weapon:weapon[component]=value
        }
        save(store:store)
    }
    mutating func reset(_ target:Target,store:UserDefaults = .standard) {
        guard (mode == .weapon ? target == .weapon : target != .weapon) else{return}
        let source=Self.defaults(model,target)
        switch target {
        case .left:left=source
        case .right:right=source
        case .weapon:weapon=source
        }
        save(store:store)
    }
    func save(store:UserDefaults = .standard) {
        store.set(mode.rawValue,forKey:Self.keyMode)
        store.set(model.rawValue,forKey:Self.keyModel)
        // Preserve legacy keys while also saving independent per-model poses.
        store.set(left,forKey:Self.oldLeftKey)
        store.set(right,forKey:Self.oldRightKey)
        store.set(left,forKey:Self.key(model,.left))
        store.set(right,forKey:Self.key(model,.right))
        store.set(weapon,forKey:Self.weaponKey)
        store.set(bob,forKey:"ASTEROIDY_H55_FPS_BOB_580")
        store.set(idle,forKey:"ASTEROIDY_H55_FPS_IDLE_580")
        store.set(fingerAnimation,forKey:"ASTEROIDY_H55_FPS_FINGERS_580")
    }
}
