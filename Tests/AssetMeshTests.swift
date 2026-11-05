import Foundation
@main struct TestAsset {
    static func main() throws {
        let path = CommandLine.arguments[1]
        let d = try Data(contentsOf: URL(fileURLWithPath:path))
        let asset = try AssetMesh(data:d)
        precondition(asset.vertices.count == 50026)
        precondition(asset.indices.count == 64809 * 3)
        precondition(asset.vertices.allSatisfy { v in
            [v.position.x,v.position.y,v.position.z,v.color.x,v.color.y,v.color.z].allSatisfy { $0.isFinite }
        })
        var damaged = d
        damaged[damaged.count-4] = 255
        damaged[damaged.count-3] = 255
        damaged[damaged.count-2] = 255
        damaged[damaged.count-1] = 255
        do {
            _ = try AssetMesh(data:damaged)
            preconditionFailure("Out-of-range mesh index accepted")
        } catch AssetMesh.ParseError.invalidIndex { }
        var truncated = d
        truncated.removeLast()
        do {
            _ = try AssetMesh(data:truncated)
            preconditionFailure("Truncated mesh accepted")
        } catch AssetMesh.ParseError.truncated { }
        print("PASS: source GLB mesh + strict AS3D validation, 50026 vertices / 64809 triangles")
    }
}
