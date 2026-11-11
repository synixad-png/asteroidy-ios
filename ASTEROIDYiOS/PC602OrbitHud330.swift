import Foundation

/// PC602 Windows/src/Orbit50.cs OrbitHud330 source readouts.
/// Source 26 mission coordinates, genuine altitude and course relative
/// to true tangent-forward ship vector. No guessed line-of-sight compass.
enum PC602OrbitHud330 {
    struct Telemetry {
        let zone:Int
        let altitude:Float
        let course:Float
        let unlocked:Bool
        let completed:Bool
    }
    private static func length(_ p:SIMD3<Float>)->Float {
        sqrt(p.x*p.x+p.y*p.y+p.z*p.z)
    }
    private static func dot(_ a:SIMD3<Float>,_ b:SIMD3<Float>)->Float {
        a.x*b.x+a.y*b.y+a.z*b.z
    }
    private static func cross(_ a:SIMD3<Float>,
                              _ b:SIMD3<Float>)->SIMD3<Float> {
        SIMD3(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x)
    }
    private static func unit(_ p:SIMD3<Float>)->SIMD3<Float> {
        let r=length(p)
        return r>1e-6 ? p/r:SIMD3<Float>(repeating:0)
    }

    static func measure(_ source:PC602HomeFlight291)->Telemetry? {
        let p=source.orbitPosition
        let norm=length(p)
        guard norm>1e-6, let surface=source.home.surface(p),
              let destination=source.home.beacon(source.target)
        else{return nil}
        let n=unit(p),goal=unit(destination)
        // Exact OrbitWorld50.Zone, source sector grid row0 equator,
        // row1 northern band, row2 southern band.
        let row=n.y>1/3 ? 1:n.y < -1/3 ? 2:0
        var angle=atan2(n.z,n.x)
        if angle<0 {angle+=2*Float.pi}
        let column=min(7,Int(angle/(Float.pi/4)))
        let zone=row*8+column+1
        // Original Route51: tangential great-circle direction, near-goal
        // physical arrival direction (12m), antipodal fallback.
        let d=dot(goal,n)
        let toward=goal-n*d
        let route:SIMD3<Float>
        if length(toward)<0.001 {
            if d>0 {
                route=unit(n*(125-norm))
            } else {
                route=unit(cross(n,abs(n.y)<0.9
                    ? SIMD3<Float>(0,1,0):SIMD3<Float>(1,0,0)))
            }
        } else if source.orbitDistance<12 {
            route=unit(destination-p)
        } else {
            route=unit(toward)
        }
        let tangent=unit(route-n*dot(route,n))
        let forward=unit(source.orbitForward)
        let side=unit(cross(forward,n))
        let course=atan2(dot(tangent,side),dot(tangent,forward)) * (180/Float.pi)
        guard course.isFinite else {return nil}
        return Telemetry(zone:zone,altitude:norm-surface,
                         course:course,
                         unlocked:PC602HomeFlight291.unlocked(
                            source.target,mask:source.completedMask),
                         completed:PC602HomeFlight291.completed(
                            source.target,mask:source.completedMask))
    }
}
