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
        func diagnose(_ bytes:Data, name:String, expectedMagic:Int) {
            func note(_ message:String) {
                FileHandle.standardError.write(Data((message+"\n").utf8))
            }
            func word(_ index:Int)->Int {
                Int(bytes[index]) | Int(bytes[index+1])<<8 |
                Int(bytes[index+2])<<16 | Int(bytes[index+3])<<24
            }
            let packed=word(12),jpeg=word(16),expectedRaw=word(8)
            note("DIAG \(name) transport: compressed=\(packed) jpeg=\(jpeg) uncompressed=\(expectedRaw), total=\(bytes.count)")
            guard bytes.count==20+packed+jpeg else {note("DIAG invalid transport");return}
            let compressed=Data(bytes[20..<(20+packed)])
            do {
                let raw=try (compressed as NSData).decompressed(using:.zlib) as Data
                note("DIAG \(name) NSData.decompressed success: \(raw.count), SHA256=\(SourceKestrel603.sha256(raw))")
                do {
                    let mesh=try SourceBakedShipMesh(data:raw,expectedMagic:expectedMagic)
                    note("DIAG \(name) mesh parsed: vertices \(mesh.vertexCount), cpu \(mesh.cpuFaceCount)")
                } catch {
                    note("DIAG \(name) SOURCE BAKED MESH parse FAILED: \(error)")
                }
            } catch {
                note("DIAG \(name) Apple Foundation zlib decompression FAILED: \(error)")
            }
        }
        diagnose(kestrelBytes,name:"KESTREL",expectedMagic:6031)
        diagnose(bastionBytes,name:"BASTION",expectedMagic:6061)
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
