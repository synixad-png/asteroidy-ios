import Foundation
import CryptoKit

/// Exact GPU float32 stream exported from Windows v568 PlayerShip363.cs.
/// The source is player_ship367.mesh.gz, marker 3671, 12 float32 per corner.
/// Exporter applied only the original StandardSize369 = 0.714 to XYZ.
/// UV, normals, color and alpha are byte-for-byte original PC values.
struct SourcePlayerShip367 {
    enum AssetError: Error {
        case wrongSize, wrongSource
    }
    static let vertexCount = 599_997
    static let stride = 48
    static let expectedGPU_SHA256 =
        "932b0a9028404562cfd28db4174f51ded5977e23a90c15580566c69f9c41819a"
    static let expectedTexture_SHA256 =
        "9ed4fe25c25566f40b0ca401185c6280aa219e2ecb186d160ed3254d14eeb111"

    let gpuBytes: Data
    init(data: Data) throws {
        guard data.count == Self.vertexCount * Self.stride else {
            throw AssetError.wrongSize
        }
        guard Self.sha256(data) == Self.expectedGPU_SHA256 else {
            throw AssetError.wrongSource
        }
        gpuBytes = data
    }

    static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map {
            String(format: "%02x", $0)
        }.joined()
    }

    static func verifiedTexture(_ image: Data) -> Bool {
        sha256(image) == expectedTexture_SHA256
    }
}
