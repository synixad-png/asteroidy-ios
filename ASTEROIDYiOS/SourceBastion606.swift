import Foundation
import CryptoKit

/// Authentic playable Bastion (ShipType 2) from PC v609/v606.
/// The importer stores a SINGLE lossless transport pack containing the exact
/// baked GPU float stream and original JPEG. It never creates a substitute
/// Vanguard and never modifies flight, weapons or the PC shop inventory.
enum SourceBastion606 {
    enum ImportError:Error {
        case missingFile,invalidPack,invalidGeometry,invalidTexture
    }
    static let packSHA256 =
        "d18d651aab74bebdb2215940c0774c8aa3f0aff9101c0b7122c336110b3f5e7c"
    static let meshSHA256 =
        "5b9257d55d403a28ef37d370f95a1796e236b7bef34a695a313b1a48450baca6"
    static let jpegSHA256 =
        "4882d508b527d1f13171cf72d732addbaf393681d37942378be5b39ef09fe65e"
    static let expectedPackBytes=2_472_062
    static let expectedMeshBytes=8_284_756
    static let expectedGPUVertexCount=164_379
    private static let headerBytes=20
    private static let magic=Array("BST60901".utf8)

    struct Asset {
        let mesh:SourceBakedShipMesh
        let jpeg:Data
    }

    static func sha256(_ bytes:Data)->String {
        SHA256.hash(data:bytes).map{String(format:"%02x",$0)}.joined()
    }

    static func decode(_ pack:Data) throws->Asset {
        guard pack.count==expectedPackBytes,
              sha256(pack)==packSHA256,
              pack.count>=headerBytes,
              Array(pack.prefix(8))==magic
        else {throw ImportError.invalidPack}
        func length(at index:Int)->Int {
            Int(pack[index]) | Int(pack[index+1]) << 8 |
            Int(pack[index+2]) << 16 | Int(pack[index+3]) << 24
        }
        let rawBytes=length(at:8)
        let packedBytes=length(at:12)
        let jpegBytes=length(at:16)
        guard rawBytes==expectedMeshBytes,packedBytes>0,
              jpegBytes>0,headerBytes+packedBytes+jpegBytes==pack.count
        else {throw ImportError.invalidPack}
        let compressed=Data(pack[headerBytes..<(headerBytes+packedBytes)])
        // PC609 source uses Python zlib.compress (RFC1950 framing).
        // Foundation .zlib expects a different frame on Apple and fails
        // NSDecompressionFailedError 5377 for BOTH original ship packs.
        // Decode the original raw DEFLATE payload once without changing
        // the hash-pinned mesh, texture or model geometry.
        guard let meshBytes=SourcePC609Zlib.inflateRFC1950(
            compressed,exactBytes:expectedMeshBytes) else {
            throw ImportError.invalidGeometry
        }
        guard meshBytes.count==expectedMeshBytes,
              sha256(meshBytes)==meshSHA256,
              let mesh=try? SourceBakedShipMesh(
                data:meshBytes,expectedMagic:6061),
              mesh.vertexCount==expectedGPUVertexCount,
              mesh.engines.count==2
        else {throw ImportError.invalidGeometry}
        let jpeg=Data(pack[(headerBytes+packedBytes)..<pack.count])
        guard sha256(jpeg)==jpegSHA256 else {
            throw ImportError.invalidTexture
        }
        return Asset(mesh:mesh,jpeg:jpeg)
    }

    // Immutable IPA resources are verified only once. W3, H55 and H290
    // reuse the same original, decoded source, avoiding repeated zlib work
    // during SwiftUI updates. Legacy Files data is never preferred to IPA.
    private static let verifiedBundleAsset:Asset? = {
        guard let url=Bundle.main.url(forResource:"BASTION_PC609",
                                      withExtension:"bastion")
                  ?? Bundle.main.url(forResource:"BASTION_PC609",
                                       withExtension:"bastion",subdirectory:"Assets"),
              let bytes=try? Data(contentsOf:url,options:.mappedIfSafe)
        else{return nil}
        return try? decode(bytes)
    }()

    static func load()->Asset? {
        if let asset=verifiedBundleAsset {return asset}
        guard let path=H55SourceMechanics580.bastionAssetURL,
              let bytes=try? Data(contentsOf:path,options:.mappedIfSafe)
        else{return nil}
        return try? decode(bytes)
    }

    /// The only authorized installation path: user's iOS Files importer.
    /// Verify pack checksum and baked GLB data BEFORE replacing the last
    /// good asset; persist atomically inside Application Support.
    static func install(from externalURL:URL) throws {
        let scoped=externalURL.startAccessingSecurityScopedResource()
        defer {if scoped {externalURL.stopAccessingSecurityScopedResource()}}
        let bytes=try Data(contentsOf:externalURL)
        _=try decode(bytes)
        guard let support=FileManager.default.urls(
            for:.applicationSupportDirectory,in:.userDomainMask).first
        else {throw ImportError.missingFile}
        try FileManager.default.createDirectory(
            at:support,withIntermediateDirectories:true)
        let target=support.appendingPathComponent(
            H55SourceMechanics580.bastionAssetName + "." +
            H55SourceMechanics580.bastionAssetExtension)
        try bytes.write(to:target,options:.atomic)
    }
}
