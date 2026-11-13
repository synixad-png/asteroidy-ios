import Foundation
// Source-only CLI test stub. Never included in the iOS app target.
// Decoders use this type only for optional Files import paths; the
// pinned original bundled pack is loaded and decoded directly below.
enum H55SourceMechanics580 {
    static let kestrelAssetName = "KESTREL_PC609"
    static let kestrelAssetExtension = "kestrel"
    static let bastionAssetName = "BASTION_PC609"
    static let bastionAssetExtension = "bastion"
    static var kestrelAssetURL: URL? {nil}
    static var bastionAssetURL: URL? {nil}
}

@main struct VerifyPC609PackedShips {
    static func main() throws {
        let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
            .appendingPathComponent("ASTEROIDYiOS/Assets")
        let kestrelFile=root.appendingPathComponent("KESTREL_PC609.kestrel")
        let bastionFile=root.appendingPathComponent("BASTION_PC609.bastion")
        let kestrelBytes=try Data(contentsOf:kestrelFile)
        let bastionBytes=try Data(contentsOf:bastionFile)
        print("PC609 runtime decoder test: Kestrel bytes=\(kestrelBytes.count); Bastion bytes=\(bastionBytes.count)")
        // The ORIGINAL source packs include a standard RFC1950 header.
        // Verify the same Apple Compression path used by the game. Tests
        // must actually decompress, parse and SHA-check both full models.
        let compK=Data(kestrelBytes[20..<(20+2_201_881)])
        let compB=Data(bastionBytes[20..<(20+1_942_595)])
        guard let rawK=SourcePC609Zlib.inflateRFC1950(compK,exactBytes:9_495_364),
              let rawB=SourcePC609Zlib.inflateRFC1950(compB,exactBytes:8_284_756)
        else {fatalError("Original PC609 RFC1950 to Apple DEFLATE failed")}
        precondition(SourceKestrel603.sha256(rawK)==SourceKestrel603.meshSHA256)
        precondition(SourceBastion606.sha256(rawB)==SourceBastion606.meshSHA256)
        print("PASS PC609 RFC1950/Apple raw DEFLATE: byte-identical original meshes")
        // Fail closed on invalid RFC1950 header, wrong requested output
        // size, and mutated original immutable PC609 pack (source SHA).
        var bad=compK
        bad[0]=0
        precondition(SourcePC609Zlib.inflateRFC1950(bad,
            exactBytes:9_495_364)==nil)
        precondition(SourcePC609Zlib.inflateRFC1950(compK,
            exactBytes:9_495_363)==nil)
        var wrong=kestrelBytes
        wrong[wrong.count-1]^=0x01
        precondition((try? SourceKestrel603.decode(wrong))==nil)
        do {
            let model=try SourceKestrel603.decode(kestrelBytes)
            precondition(model.mesh.vertexCount==189906 && model.mesh.engines.count==2)
            print("PASS original KESTREL 6031 GPU/CPU/JPEG runtime decoder")
        } catch {
            print("FAIL KESTREL PC609 REAL SWIFT DECODER: \(error)")
            throw error
        }
        do {
            let model=try SourceBastion606.decode(bastionBytes)
            precondition(model.mesh.vertexCount==164379 && model.mesh.engines.count==2)
            print("PASS original BASTION 6061 GPU/CPU/JPEG runtime decoder")
        } catch {
            print("FAIL BASTION PC609 REAL SWIFT DECODER: \(error)")
            throw error
        }
    }
}
