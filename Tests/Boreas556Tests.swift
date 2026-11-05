import Foundation
@main struct BoreasAssetTests {
    static func main() throws {
        let d = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let mesh = try AssetMesh(data: d)
        precondition(mesh.vertices.count == 31355)
        precondition(mesh.indices.count == 61554*3)
        var maxRadius: Float = 0
        for v in mesh.vertices {
            let p = v.position
            precondition(p.x.isFinite && p.y.isFinite && p.z.isFinite)
            precondition(v.color.x.isFinite && v.color.y.isFinite && v.color.z.isFinite)
            maxRadius = max(maxRadius, sqrt(p.x*p.x+p.y*p.y+p.z*p.z))
        }
        precondition(abs(maxRadius - 1) < 0.0002)
        print("PASS Boreas556: 31355 vertices, 61554 triangles, radius normalized to 1")
    }
}
