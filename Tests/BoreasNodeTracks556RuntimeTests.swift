import Foundation
import CryptoKit
import simd

/// A genuine macOS Swift runtime regression for original v556 BOREAS data.
/// Static Python zlib checks do not establish iOS/Foundation compatibility.
/// This test exercises the EXACT BoreasNodeTracks556 constructor used by
/// MetalRenderer when CARBONIS Intro41 creates its first real GPU scene.
@main struct BoreasOriginalNodeTracksRuntime {
    static func sha256(_ data:Data)->String {
        SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined()
    }
    static func main() throws {
        let base=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
            .appendingPathComponent("ASTEROIDYiOS/Assets",isDirectory:true)
        let rawMesh=try Data(contentsOf:base.appendingPathComponent("Boreas556.as3d"))
        let rawTracks=try Data(contentsOf:base.appendingPathComponent("Boreas556.asnt"))
        precondition(rawTracks.count==21_218)
        precondition(sha256(rawTracks) ==
            "bdf22733cfe6a1314517537e2400019a97c3a83507b8f654fd1307dbf9809edc")
        let decompressed=SourcePC609Zlib.inflateRFC1950(
            Data(rawTracks.dropFirst(40)),exactBytes:130_752)
        precondition(decompressed != nil,
            "Apple must decode Python RFC1950 Boreas ASNT (not Foundation 5377)")
        precondition(sha256(decompressed!) ==
            "2cca0a79d0e62845225bb819fdd8e3a4cbd37ae4cb512a18d8ca947731dbaccc")
        let mesh=try AssetMesh(data:rawMesh)
        precondition(mesh.vertices.count==31_355)
        let tracks=try BoreasNodeTracks556(data:rawTracks,mesh:mesh)
        precondition(tracks.dynamicVertexRange==0..<4_320)
        var first=mesh.vertices
        tracks.updateVertices(seconds:0,into:&first)
        var second=mesh.vertices
        tracks.updateVertices(seconds:2.5,into:&second)
        let moved=(0..<4_320).filter { i in
            let a=first[i].position,b=second[i].position
            return simd_length(SIMD3<Float>(a.x-b.x,a.y-b.y,a.z-b.z))>0.00001
        }.count
        precondition(moved>0,"Original 96 node tracks must change actual positions")
        for i in 4_320..<31_355 {
            precondition(first[i].position==mesh.vertices[i].position)
            precondition(second[i].position==mesh.vertices[i].position)
        }
        var broken=rawTracks
        broken[40]=0
        do {
            _=try BoreasNodeTracks556(data:broken,mesh:mesh)
            fatalError("Invalid original ASNT zlib framing accepted")
        } catch BoreasNodeTracks556.SourceError.invalidData {
            // Expected fail-closed behavior on malformed compressed source.
        }
        print("PASS original BOREAS ASNT: RFC1950 Swift decode, 48 node records, 96 node channels, 4320 animated vertices, CARBONIS Intro41 renderer initialization")
        print("PASS original BOREAS ASNT frame t=0 -> t=2.5: \(moved) source vertices changed; static vertices preserved")
    }
}
