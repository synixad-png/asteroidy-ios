import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Identity and verified bundle lookup for four ORIGINAL PC v586 GLB pickups.
/// This is a catalog, not a second importer, loot generator or rendering pass.
enum SourcePickupModels586 {
    enum Kind:String,CaseIterable,Hashable {
        case shield,boost,energy,bomb
        var fileName:String {rawValue + ".glb"}
        var sourceSupplyNames:[String] {
            switch self {
            case .shield:return ["Tarcza145","Shield"]
            case .boost:return ["Boost71"]
            case .energy:return ["Energy"]
            case .bomb:return ["Bomb"]
            }
        }
        var sourceBaseSize:Float {self == .shield ? 30 : 26}
        var byteCount:Int {
            switch self {
            case .shield:return 478_320
            case .boost:return 502_996
            case .energy:return 506_076
            case .bomb:return 483_424
            }
        }
        var sha256:String {
            switch self {
            case .shield:return "531f1d49ea9782a2c40ce6870cd308d067461cc5f80cfaefc659f3db4ffe5a62"
            case .boost:return "6f7a083b493b029f4907988b55dbf9cdc49c7d5d187e023fa20521319b494362"
            case .energy:return "df9c3a85ef45d55d3ce08d9d82ec9ec1f0ec1b8c2cdf06fb35550eb96aa3aca1"
            case .bomb:return "e8787ce4b11c8b44b6b710a93419b0c8cc263cafe27c35e580b0c4cb8bffaaee"
            }
        }
        var defaultVisualPercent:Int {self == .shield ? 60 : 78}
    }
    /// Trophies and money must not use one of the four original GLB models.
    static func kind(forSourceSupplyName supply:String,trophy:Bool=false)->Kind? {
        guard !trophy else{return nil}
        return Kind.allCases.first{$0.sourceSupplyNames.contains(supply)}
    }

    /// Called ONCE per resource during loading; never inside the frame loop.
    /// Missing/altered GLBs return nil for the procedural fallback.
    static func verifiedBundledURL(_ kind:Kind,bundle:Bundle = .main)->URL? {
        guard let url=bundle.url(forResource:kind.rawValue,withExtension:"glb")
                      ?? bundle.url(forResource:kind.rawValue,withExtension:"glb",
                                    subdirectory:"Assets"),
              let raw=try? Data(contentsOf:url),raw.count==kind.byteCount,
              raw.count>=20,raw.prefix(4)==Data([0x67,0x6c,0x54,0x46]),
              raw[4]==2,raw[5]==0,raw[6]==0,raw[7]==0 else{return nil}
        let length=UInt32(raw[8]) | (UInt32(raw[9]) << 8)
            | (UInt32(raw[10]) << 16) | (UInt32(raw[11]) << 24)
        guard length==raw.count else{return nil}
        #if canImport(CryptoKit)
        let hash=SHA256.hash(data:raw).map{String(format:"%02x",$0)}.joined()
        return hash==kind.sha256 ? url : nil
        #else
        return nil
        #endif
    }
}
