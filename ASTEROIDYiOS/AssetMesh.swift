import Foundation

// Exact format validated with a checked exporter; first stage of GLB integration.
// Static geometry only. glTF texture maps and morph animations not yet imported.
struct AssetMesh {
    struct Vertex {
        var position: SIMD4<Float>
        var color: SIMD4<Float>
        var normal: SIMD4<Float>
        // metallic, roughness, clearcoat factor, clearcoat roughness
        var material: SIMD4<Float> = SIMD4<Float>(0, 1, 0, 0)
    }
    let vertices: [Vertex]
    let indices: [UInt32]
    enum ParseError: Error { case invalidHeader, truncated, invalidIndex }

    init(data: Data) throws {
        guard data.count >= 16, Array(data.prefix(4)) == Array("AS3D".utf8) else { throw ParseError.invalidHeader }
        func u32(_ offset: Int) -> UInt32 {
            UInt32(data[offset]) | (UInt32(data[offset+1]) << 8) | (UInt32(data[offset+2]) << 16) | (UInt32(data[offset+3]) << 24)
        }
        let version = u32(4)
        guard version == 1 || version == 2 || version == 3 else { throw ParseError.invalidHeader }
        let vertexStride = version >= 2 ? 48 : 32
        let count = Int(u32(8)), indexCount = Int(u32(12))
        guard count > 0, indexCount > 0, indexCount % 3 == 0,
              count <= 2_000_000, indexCount <= 6_000_000,
              data.count == 16 + count * vertexStride + indexCount * 4 else { throw ParseError.truncated }
        func f32(_ offset: Int) -> Float { Float(bitPattern: u32(offset)) }
        var v: [Vertex] = [], ids: [UInt32] = []
        v.reserveCapacity(count); ids.reserveCapacity(indexCount)
        for i in 0..<count {
            let o = 16 + i * vertexStride
            v.append(Vertex(position: SIMD4(f32(o),f32(o+4),f32(o+8),f32(o+12)),
                            color: SIMD4(f32(o+16),f32(o+20),f32(o+24),f32(o+28)),
                            normal: SIMD4<Float>(0,0,1,0),
                            material: version >= 2 ? SIMD4(f32(o+32),f32(o+36),f32(o+40),f32(o+44)) : SIMD4<Float>(0,1,0,0)))
            guard v.last!.material.x.isFinite, v.last!.material.y.isFinite,
                  (0...1).contains(v.last!.material.x), (0.04...1).contains(v.last!.material.y),
                  (0...1).contains(v.last!.material.z), (0...1).contains(v.last!.material.w) else { throw ParseError.invalidHeader }
        }
        let start = 16 + count * vertexStride
        for i in 0..<indexCount {
            let index = u32(start+i*4)
            guard index < count else { throw ParseError.invalidIndex }
            ids.append(index)
        }
        // Reconstruct vertex normals from authentic indexed triangles. Flat or degenerate
        // surfaces are handled safely without modifying the source AS3D v1.
        let normals = Self.computeNormals(vertices: v, indices: ids)
        for i in v.indices { v[i].normal = normals[i] }
        vertices = v; indices = ids
    }

    static func computeNormals(vertices: [Vertex], indices: [UInt32]) -> [SIMD4<Float>] {
        var accumulated = Array(repeating: SIMD3<Float>(repeating: 0), count: vertices.count)
        guard indices.count % 3 == 0 else {
            return Array(repeating: SIMD4<Float>(0,0,1,0), count: vertices.count)
        }
        for t in stride(from: 0, to: indices.count, by: 3) {
            let a = Int(indices[t]), b = Int(indices[t+1]), c = Int(indices[t+2])
            guard a < vertices.count && b < vertices.count && c < vertices.count else { continue }
            let pa = SIMD3<Float>(vertices[a].position.x,vertices[a].position.y,vertices[a].position.z)
            let pb = SIMD3<Float>(vertices[b].position.x,vertices[b].position.y,vertices[b].position.z)
            let pc = SIMD3<Float>(vertices[c].position.x,vertices[c].position.y,vertices[c].position.z)
            let ab = pb-pa, ac = pc-pa
            let n = SIMD3<Float>(ab.y*ac.z-ab.z*ac.y, ab.z*ac.x-ab.x*ac.z, ab.x*ac.y-ab.y*ac.x)
            let sq = n.x*n.x+n.y*n.y+n.z*n.z
            if sq > 1e-20 && sq.isFinite {
                accumulated[a] += n; accumulated[b] += n; accumulated[c] += n
            }
        }
        return accumulated.enumerated().map { i,n in
            let length = (n.x*n.x+n.y*n.y+n.z*n.z).squareRoot()
            if length > 1e-10 && length.isFinite { return SIMD4(n.x/length,n.y/length,n.z/length,0) }
            let p = vertices[i].position
            let rad = (p.x*p.x+p.y*p.y+p.z*p.z).squareRoot()
            if rad > 1e-10 && rad.isFinite { return SIMD4(p.x/rad,p.y/rad,p.z/rad,0) }
            return SIMD4<Float>(0,0,1,0)
        }
    }
}
