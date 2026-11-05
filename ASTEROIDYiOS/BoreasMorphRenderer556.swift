import Foundation

// Binds the original node-0 morph to the verified v556 Boreas vertex order.
// Static triangles are never reprocessed during animation.
struct BoreasMorphBinding556: Decodable {
    let format: String
    let firstVertex: Int
    let vertexCount: Int
    let staticVertexCount: Int
    let center: [Float]
    let radius: Float
}

struct BoreasMorphRenderer556 {
    enum BindingError: Error { case invalidBinding, mismatchedMesh, mixedTriangles }
    private let source: BoreasMorph556
    private let binding: BoreasMorphBinding556
    private let original: [AssetMesh.Vertex]
    private let localTriangles: [(Int, Int, Int)]

    init(source: BoreasMorph556, bindingData: Data, mesh: AssetMesh) throws {
        let b = try JSONDecoder().decode(BoreasMorphBinding556.self, from: bindingData)
        guard b.format == "BoreasMorphBinding556.v1", b.center.count == 3,
              b.center.allSatisfy({ $0.isFinite }), b.radius.isFinite, b.radius > 0,
              b.firstVertex >= 0, b.vertexCount == source.vertexCount,
              b.staticVertexCount == mesh.vertices.count,
              b.firstVertex + b.vertexCount == b.staticVertexCount else { throw BindingError.invalidBinding }
        let c = SIMD3<Float>(b.center[0], b.center[1], b.center[2])
        for i in source.base.indices {
            let expected = (source.base[i] - c) / b.radius
            let p = mesh.vertices[b.firstVertex + i].position
            guard abs(p.x - expected.x) < 1e-4,
                  abs(p.y - expected.y) < 1e-4,
                  abs(p.z - expected.z) < 1e-4 else { throw BindingError.mismatchedMesh }
        }
        var triangles: [(Int, Int, Int)] = []
        triangles.reserveCapacity(mesh.indices.count / 3)
        for t in stride(from: 0, to: mesh.indices.count, by: 3) {
            let a = Int(mesh.indices[t]), d = Int(mesh.indices[t + 1]), e = Int(mesh.indices[t + 2])
            let dynamic = [a, d, e].map { $0 >= b.firstVertex }
            if dynamic.contains(true) {
                guard dynamic.allSatisfy({ $0 }) else { throw BindingError.mixedTriangles }
                triangles.append((a - b.firstVertex, d - b.firstVertex, e - b.firstVertex))
            }
        }
        self.source = source
        self.binding = b
        self.original = mesh.vertices
        self.localTriangles = triangles
    }

    var dynamicVertexRange: Range<Int> {
        binding.firstVertex ..< (binding.firstVertex + binding.vertexCount)
    }

    func makeScratchVertices() -> [AssetMesh.Vertex] { original }

    // Reuses caller-owned storage. Static vertices are never copied or rewritten.
    // Callers must initialize scratch using makeScratchVertices() once.
    func updateVertices(seconds: Double, into result: inout [AssetMesh.Vertex]) {
        precondition(result.count == original.count)
        let weights = source.sampleWeights(seconds: seconds)
        let center = SIMD3<Float>(binding.center[0], binding.center[1], binding.center[2])
        let start = binding.firstVertex
        let count = source.vertexCount
        for i in 0..<count {
            var p = source.base[i]
            for t in 0..<source.targetCount { p += source.deltas[t][i] * weights[t] }
            p = (p - center) / binding.radius
            result[start + i].position = SIMD4<Float>(p.x, p.y, p.z, 1)
        }
        // Only triangles of the morphed submesh can change their normals.
        // These use the same area-weighted cross products and radial fallback as AssetMesh.
        var accumulated = Array(repeating: SIMD3<Float>(repeating: 0), count: count)
        for (a, b, c) in localTriangles {
            let pa = result[start + a].position, pb = result[start + b].position, pc = result[start + c].position
            let ab = SIMD3<Float>(pb.x - pa.x, pb.y - pa.y, pb.z - pa.z)
            let ac = SIMD3<Float>(pc.x - pa.x, pc.y - pa.y, pc.z - pa.z)
            let n = SIMD3<Float>(ab.y*ac.z-ab.z*ac.y, ab.z*ac.x-ab.x*ac.z, ab.x*ac.y-ab.y*ac.x)
            let sq = n.x*n.x+n.y*n.y+n.z*n.z
            if sq > 1e-20 && sq.isFinite {
                accumulated[a] += n; accumulated[b] += n; accumulated[c] += n
            }
        }
        for i in 0..<count {
            let n = accumulated[i]
            let length = (n.x*n.x+n.y*n.y+n.z*n.z).squareRoot()
            if length > 1e-10 && length.isFinite {
                result[start + i].normal = SIMD4(n.x/length,n.y/length,n.z/length,0)
            } else {
                let p = result[start + i].position
                let r = (p.x*p.x+p.y*p.y+p.z*p.z).squareRoot()
                result[start + i].normal = r > 1e-10 && r.isFinite
                    ? SIMD4(p.x/r,p.y/r,p.z/r,0) : SIMD4<Float>(0,0,1,0)
            }
        }
    }

    // Compatibility interface used by existing tests and non-realtime callers.
    func animatedVertices(seconds: Double) -> [AssetMesh.Vertex] {
        var result = makeScratchVertices()
        updateVertices(seconds: seconds, into: &result)
        return result
    }
}
