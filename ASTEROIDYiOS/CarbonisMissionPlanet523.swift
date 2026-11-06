import Foundation
/// Windows v568 GpuPlanetGltf463.MissionPlanetScale523.
/// The original C279 has 12 float32 values per vertex (XYZ first);
/// Carbonis uses the real farthest terrain vertex, NOT MaxRadius.
enum CarbonisMissionPlanet523 {
    static let strideBytes = 12 * MemoryLayout<Float>.stride
    static func sourceOuterRadius523(vertexBytes:Data)->Float? {
        guard !vertexBytes.isEmpty,
              vertexBytes.count % strideBytes == 0 else {return nil}
        var maxSquared:Float=0.0001
        var valid=true
        vertexBytes.withUnsafeBytes { bytes in
            for offset in stride(from:0,to:bytes.count,by:strideBytes) {
                let x=bytes.loadUnaligned(fromByteOffset:offset,as:Float.self)
                let y=bytes.loadUnaligned(fromByteOffset:offset+4,as:Float.self)
                let z=bytes.loadUnaligned(fromByteOffset:offset+8,as:Float.self)
                let squared=x*x+y*y+z*z
                if !squared.isFinite {valid=false;break}
                maxSquared=max(maxSquared,squared)
            }
        }
        return valid ? sqrt(maxSquared) : nil
    }
    static func missionScale523(vertexBytes:Data)->Float? {
        guard let radius=sourceOuterRadius523(vertexBytes:vertexBytes),
              radius > 0.01 else {return nil}
        // PC: (100 * HomeOuterRadius523 / radius) /
        //     (100 * HomeOuterRadius523).
        return 1/radius
    }
}
