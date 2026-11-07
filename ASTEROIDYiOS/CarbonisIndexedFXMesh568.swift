import Foundation

/// Geometry-only packing. The original 12 Float shader vertex format is
/// unchanged (XYZ, NXYZ, RGBA, UV). Indices reference duplicated ring
/// corners instead of allocating six complete vertices for each sector.
/// Each indexed triangle expands to the exact legacy vertex stream.
struct CarbonisIndexedFXMesh568 {
    var vertices:[Float]=[]
    var indices:[UInt32]=[]
    var vertexCount:Int {vertices.count/12}
    var indexCount:Int {indices.count}
    var transferBytes:Int {
        vertices.count*MemoryLayout<Float>.size
            + indices.count*MemoryLayout<UInt32>.size
    }
    func expandedTriangles()->[Float] {
        var expanded:[Float]=[]
        expanded.reserveCapacity(indices.count*12)
        for index in indices {
            let start=Int(index)*12
            expanded.append(contentsOf:vertices[start..<(start+12)])
        }
        return expanded
    }
}
