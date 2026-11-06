import Foundation
import CryptoKit
import simd

@main
enum ScoutB82SNativeTests {
    static func main() throws {
        let args = CommandLine.arguments
        precondition(args.count == 2, "Usage: scout-native-test DIRECTORY")
        let folder=URL(fileURLWithPath:args[1],isDirectory:true)
        let mesh=try Data(contentsOf: folder.appendingPathComponent(
            "AlienScout173SourceVertices.bin"))
        let animation=try Data(contentsOf: folder.appendingPathComponent(
            "AlienScout173SourceAnimation.bin"))
        let info=try Data(contentsOf: folder.appendingPathComponent(
            "AlienScout173Source.json"))
        let scout=try SourceAlienScout173(
            geometry:mesh,poses:animation,metadata:info)
        precondition(scout.parts.count == 88)
        precondition(scout.geometry.count == 13_569_600)
        precondition(scout.poses.count == 2_759_680)
        precondition(scout.parts[0].firstVertex == 0)
        precondition(scout.parts[87].firstVertex +
            scout.parts[87].vertexCount == 339_240)
        for part in [0,7,27,55,87] {
            for clip in [0,4,9] {
                for frame in [0,24,48] {
                    let matrix=try scout.matrix(
                        part:part,clip:clip,frame:frame)
                    for col in 0..<4 {
                        let v=matrix[col]
                        precondition(v.x.isFinite && v.y.isFinite &&
                            v.z.isFinite && v.w.isFinite)
                    }
                }
            }
        }
        do {
            _=try scout.matrix(part:88,clip:0,frame:0)
            fatalError("Accepted nonexistent original part")
        } catch SourceAlienScout173.InvalidAsset.invalidPose {
            // Expected.
        }
        do {
            _=try scout.matrix(part:0,clip:10,frame:0)
            fatalError("Accepted nonexistent source clip")
        } catch SourceAlienScout173.InvalidAsset.invalidPose {
            // Expected.
        }
        var damaged=mesh
        damaged[0] ^= 0x01
        do {
            _=try SourceAlienScout173(
                geometry:damaged,poses:animation,metadata:info)
            fatalError("Accepted corrupted original boss")
        } catch SourceAlienScout173.InvalidAsset.invalidChecksum {
            // Expected.
        }
        print("PASS: native Swift source B82S 88 parts, 10 original animation clips, 49 frames")
        print("PASS: v568 model SHA256, bounds, matrix access, no silent alternative boss")
        print("LIMIT: animated scene and combat boss rendering still require original hierarchy")
    }
}
