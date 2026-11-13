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
