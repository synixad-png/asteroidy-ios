import Foundation
import CryptoKit

/// Exact PC v609/v603 KESTREL, ShipType 0. The lossless user-provided
/// package stores the original GPU triangle stream and unmodified JPEG.
/// Rendering uses the existing SourceBakedShipMesh / Vanguard431 ABI.
enum SourceKestrel603 {
    enum ImportError:Error {
        case missingFile,invalidPack,invalidGeometry,invalidTexture
    }
    static let packSHA256 =
        "5d3598b655f362f284550261c4cbfe14775d1568885f1ce22b2baaa1c2c288a2"
    static let meshSHA256 =
        "9652c1ab9db5bbe75135c005df9d32e4147c1393615d4b2822d4c295b93ae34a"
    static let jpegSHA256 =
        "f6a717ad7a50497da5ee232e50dc156f946081cef98d9d258c30ce26008fcba6"
    static let expectedPackBytes=2_617_283
    static let expectedMeshBytes=9_495_364
    static let expectedGPUVertexCount=189_906
    private static let headerBytes=20
    private static let magic=Array("KST60901".utf8)

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
                data:meshBytes,expectedMagic:6031),
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
        guard let url=Bundle.main.url(forResource:"KESTREL_PC609",
                                      withExtension:"kestrel")
                  ?? Bundle.main.url(forResource:"KESTREL_PC609",
                                       withExtension:"kestrel",subdirectory:"Assets"),
              let bytes=try? Data(contentsOf:url,options:.mappedIfSafe)
        else{return nil}
        return try? decode(bytes)
    }()

    static func load()->Asset? {
        if let asset=verifiedBundleAsset {return asset}
        guard let path=H55SourceMechanics580.kestrelAssetURL,
              let bytes=try? Data(contentsOf:path,options:.mappedIfSafe)
        else{return nil}
        return try? decode(bytes)
    }

    /// Same one-time, verified, atomic Files installation contract as
    /// BASTION. A failed import cannot replace the previously valid model.
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
            H55SourceMechanics580.kestrelAssetName + "." +
            H55SourceMechanics580.kestrelAssetExtension)
        try bytes.write(to:target,options:.atomic)
    }
}
