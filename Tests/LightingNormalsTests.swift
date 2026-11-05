import Foundation
@main struct LightingNormalsTests {
    static func main() {
        func v(_ x:Float,_ y:Float,_ z:Float) -> AssetMesh.Vertex {
            AssetMesh.Vertex(position: SIMD4(x,y,z,1),color: SIMD4<Float>(1,1,1,1),normal:SIMD4<Float>(0,0,0,0))
        }
        let verts = [v(0,0,0),v(1,0,0),v(0,1,0),v(2,2,2)]
        let result = AssetMesh.computeNormals(vertices: verts,indices:[0,1,2,0,0,0])
        for i in 0..<3 {
            precondition(abs(result[i].x)<0.00001 && abs(result[i].y)<0.00001)
            precondition(abs(result[i].z-1)<0.00001)
        }
        let length = (result[3].x*result[3].x+result[3].y*result[3].y+result[3].z*result[3].z).squareRoot()
        precondition(abs(length-1)<0.00001)
        let corrupted = AssetMesh.computeNormals(vertices:verts,indices:[0,1,99])
        precondition(corrupted.allSatisfy {$0.x.isFinite && $0.y.isFinite && $0.z.isFinite})
        print("PASS: indexed triangle normals, degenerate/isolated vertices, invalid triangle fallback")
    }
}
