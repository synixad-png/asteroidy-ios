import Foundation

/// Lossless runtime reader for the ACTUAL original PC v568 Vanguard431
/// GPU asset *after gzip decompression* (vanguard431.mesh.gz).
///
/// Windows/src/Vanguard431.cs:12-23 uses:
///   Int32 4311, Int32 engineCount=2, 2*vec3 float32,
///   Int32 gpuFloatCount, float32[12] per shader vertex,
///   Int32 CPU faceCount, 3*vec3 float32 per preview face.
/// GPU floats: [x,y,z,nx,ny,nz,r,g,b,a,u,v]. Original UV are
/// NOT V-flipped; normals and tint are from the game, not rebuilt.
/// This type loads no arbitrary GLB / no fabricated PBR materials.
/// A separate source JPEG must be present for textured rendering.
struct SourceVanguardMesh431 {
    enum FormatError: Error {
        case truncated, badMagic, badEngines, badGPUCount, badCPUCount, nonFinite
    }
    struct Socket {
        let x: Float
        let y: Float
        let z: Float
    }

    static let magic: Int = 4311
    // Verified against original user PC v568 glTF and runtime skin.
    static let exactMeshSHA256 =
        "f5d6d0107437fa54c3e8505f9adfbf6143cc877cb970eef687603609e26f9f4a"
    static let exactBaseJPEG_SHA256 =
        "2945f711a6b559bfb5fdfb79750a2f2f77e2071aa5f3f4173eb450bce81b8b95"
    static let floatsPerVertex: Int = 12
    static let bytesPerVertex: Int = 48
    let engines: [Socket]
    let vertices: Data
    let vertexCount: Int
    let cpuFaceCount: Int

    /// The PC baked-GLB stream has one shared wire format. Existing
    /// Vanguard call sites retain 4311; Bastion v606 uses 6061 and the
    /// same XYZ/normal/RGBA/UV layout without remapping the geometry.
    init(data: Data, expectedMagic: Int = 4311) throws {
        var offset=0
        func word() throws -> UInt32 {
            guard offset <= data.count-4 else { throw FormatError.truncated }
            let a=UInt32(data[offset])
            let b=UInt32(data[offset+1]) << 8
            let c=UInt32(data[offset+2]) << 16
            let d=UInt32(data[offset+3]) << 24
            offset += 4
            return a|b|c|d
        }
        func f32() throws -> Float {
            let f=Float(bitPattern:try word())
            guard f.isFinite else { throw FormatError.nonFinite }
            return f
        }
        guard Int(try word()) == expectedMagic else { throw FormatError.badMagic }
        guard Int(try word()) == 2 else { throw FormatError.badEngines }
        var sockets:[Socket]=[]
        for _ in 0..<2 {
            sockets.append(Socket(x:try f32(),y:try f32(),z:try f32()))
        }
        let floatCount=Int(try word())
        guard floatCount>0 && floatCount<=3_500_000 &&
              floatCount%Self.floatsPerVertex==0 else {
            throw FormatError.badGPUCount
        }
        let byteCount=floatCount*MemoryLayout<Float>.size
        guard offset <= data.count-byteCount else { throw FormatError.truncated }
        let packed=Data(data[offset..<(offset+byteCount)])
        offset += byteCount
        let count=Int(try word())
        guard count>0 && count<=13_000 else { throw FormatError.badCPUCount }
        let remaining=count*9*MemoryLayout<Float>.size
        guard offset <= data.count-remaining &&
              offset+remaining==data.count else { throw FormatError.truncated }

        // No CPU or GPU position/normal/UV remapping and no reindexing:
        // each original triangle corner has its own 12-float packet.
        engines=sockets
        vertices=packed
        vertexCount=floatCount/Self.floatsPerVertex
        cpuFaceCount=count
    }
}

/// One canonical decoder for PC baked-GLB playable ships (4311 / 6061).
/// Keep SourceVanguardMesh431 as the stable public compatibility name.
typealias SourceBakedShipMesh = SourceVanguardMesh431
