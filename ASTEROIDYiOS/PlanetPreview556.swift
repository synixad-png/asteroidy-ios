import Foundation

// Diagnostic planet surface for verifying Sphere67 and Metal projection.
// NOT a replacement for planets/level_XX.glb or the v556 planet shader.
enum PlanetPreview556 {
    struct Mesh {
        var vertices: [AssetMesh.Vertex]
        var indices: [UInt32]
    }
    static func make(longitudes: Int = 96, latitudes: Int = 48) -> Mesh {
        precondition(longitudes >= 3 && latitudes >= 2)
        var vertices: [AssetMesh.Vertex] = []
        var indices: [UInt32] = []
        for row in 0...latitudes {
            for col in 0...longitudes {
                let uv = Vec2(x: Float(col) * Sphere67.width / Float(longitudes),
                              y: Float(row) * Sphere67.height / Float(latitudes))
                let n = Sphere67.normal(uv)
                let checker = ((col / 8) + (row / 6)) % 2 == 0
                let c: SIMD4<Float> = checker ? SIMD4(0.09,0.23,0.39,1) : SIMD4(0.055,0.15,0.27,1)
                vertices.append(.init(position: SIMD4(n.x,n.y,n.z,1), color: c,normal: SIMD4(n.x,n.y,n.z,0)))
            }
        }
        for row in 0..<latitudes {
            for col in 0..<longitudes {
                let a = UInt32(row * (longitudes+1)+col)
                let b = a+1, c=a+UInt32(longitudes+1), d=c+1
                indices.append(contentsOf: [a,c,b,b,c,d])
            }
        }
        return Mesh(vertices:vertices,indices:indices)
    }
    static func shipSurfacePosition(_ point: Vec2, altitude: Float = 0.09) -> SIMD3<Float> {
        let n = Sphere67.normal(point)
        return SIMD3(n.x,n.y,n.z) * (1+altitude)
    }
}
