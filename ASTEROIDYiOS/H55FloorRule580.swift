import Foundation

/// PC v580 H55FullCollision379.Support() lines 787-810:
/// accepting platform normals must be independent of triangle winding,
/// because the authentic H55 GLB floor plate top has world normal -Y.
/// The source C# checks ny*ny, not ny > 0; then returns highest floor.
enum H55FloorRule580 {
    struct Sample {
        var x:Float
        var y:Float
        var z:Float
        var normalX:Float
        var normalY:Float
        var normalZ:Float
    }

    static func accepts(normalX nx:Float,normalY ny:Float,normalZ nz:Float,
                        floor y:Float,low:Float,high:Float)->Bool {
        guard nx.isFinite,ny.isFinite,nz.isFinite,y.isFinite else{return false}
        // Exact floor inclination inequality from the source v580 C#.
        return ny*ny >= 0.65*(nx*nx+nz*nz) &&
               y >= low-0.002 && y <= high+0.002
    }

    static func highest(_ samples:[Sample],low:Float,high:Float)->Float? {
        var result:Float?
        for hit in samples {
            guard accepts(normalX:hit.normalX,normalY:hit.normalY,
                          normalZ:hit.normalZ,floor:hit.y,
                          low:low,high:high) else {continue}
            if let current=result {
                if hit.y>current {result=hit.y}
            } else {
                result=hit.y
            }
        }
        return result
    }
}
