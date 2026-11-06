import Foundation
import CryptoKit
import simd

/// Native binary reader for the *real* PC v568 alien_scout_173 B82S payload.
/// Read 88 independent parts + 10 source animation clips with 49 key frames.
/// Exactly the raw float32 packets and authored 4x4 matrices from
/// Windows/src/GpuBossGallery82.cs; no flattened mesh or guessed bone poses.
/// Do not enable campaign rendering until the original hierarchy is ported.
struct SourceAlienScout173 {
    enum InvalidAsset: Error {
        case invalidLength, invalidChecksum, invalidMetadata, invalidPose
    }
    struct Part: Codable {
        let index: Int
        let firstVertex: Int
        let vertexCount: Int
        let firstAnimationByte: Int
        let animationByteCount: Int
        let frames: Int
        let clips: Int
    }
    struct Metadata: Decodable {
        let format: String
        let partCount: Int
        let clipCount: Int
        let framesPerClip: Int
        let vertexCount: Int
        let gpuSHA256: String
        let animationsSHA256: String
        let parts: [Part]
    }
    static let partCount = 88
    static let vertexCount = 339_240
    static let clips = 10
    static let frames = 49
    static let stride = 40
    static let verticesSHA256 =
        "21e602b4db46716ef72e447c09e0c2b8faf083c1872c45af537caf20056d81c3"
    static let posesSHA256 =
        "0ca71aeb3751e65ffe1772129ddb39bc29cd193e5d3ad5edefdf5d0565b9c505"
    let geometry: Data
    let poses: Data
    let parts: [Part]

    init(geometry: Data, poses: Data, metadata: Data) throws {
        guard geometry.count == Self.vertexCount * Self.stride,
              poses.count == Self.partCount * Self.clips * Self.frames * 16 * 4
        else { throw InvalidAsset.invalidLength }
        let digest: (Data) -> String = {
            SHA256.hash(data: $0).map { String(format: "%02x", $0) }.joined()
        }
        guard digest(geometry) == Self.verticesSHA256,
              digest(poses) == Self.posesSHA256
        else { throw InvalidAsset.invalidChecksum }
        let info = try JSONDecoder().decode(Metadata.self, from: metadata)
        guard info.format == "B82S", info.partCount == Self.partCount,
              info.clipCount == Self.clips,
              info.framesPerClip == Self.frames,
              info.vertexCount == Self.vertexCount,
              info.gpuSHA256 == Self.verticesSHA256,
              info.animationsSHA256 == Self.posesSHA256,
              info.parts.count == Self.partCount
        else { throw InvalidAsset.invalidMetadata }
        var first = 0
        var poseByte = 0
        let perPartPoses = Self.clips * Self.frames * 16 * 4
        for (index, part) in info.parts.enumerated() {
            guard part.index == index,
                  part.firstVertex == first,
                  part.vertexCount >= 3, part.vertexCount % 3 == 0,
                  part.firstAnimationByte == poseByte,
                  part.animationByteCount == perPartPoses,
                  part.clips == Self.clips, part.frames == Self.frames
            else { throw InvalidAsset.invalidMetadata }
            first += part.vertexCount
            poseByte += part.animationByteCount
        }
        guard first == Self.vertexCount, poseByte == poses.count
        else { throw InvalidAsset.invalidMetadata }
        self.geometry = geometry
        self.poses = poses
        self.parts = info.parts
    }

    /// Original column-major glTF/B82S matrix, WITHOUT reorientation.
    /// Gameplay's original pose hierarchy must be applied separately.
    func matrix(part: Int, clip: Int, frame: Int) throws -> simd_float4x4 {
        guard (0..<Self.partCount).contains(part),
              (0..<Self.clips).contains(clip),
              (0..<Self.frames).contains(frame)
        else { throw InvalidAsset.invalidPose }
        let offset = parts[part].firstAnimationByte +
            (clip * Self.frames + frame) * 16 * MemoryLayout<Float>.size
        let floats: [Float] = poses.withUnsafeBytes { raw in
            (0..<16).map { i in
                Float(bitPattern: raw.loadUnaligned(
                    fromByteOffset: offset + i * 4, as: UInt32.self))
            }
        }
        guard floats.allSatisfy({ $0.isFinite })
        else { throw InvalidAsset.invalidPose }
        return simd_float4x4(columns: (
            SIMD4(floats[0],floats[1],floats[2],floats[3]),
            SIMD4(floats[4],floats[5],floats[6],floats[7]),
            SIMD4(floats[8],floats[9],floats[10],floats[11]),
            SIMD4(floats[12],floats[13],floats[14],floats[15])
        ))
    }
}
