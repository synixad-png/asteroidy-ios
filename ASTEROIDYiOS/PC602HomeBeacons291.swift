import Foundation

/// Source-authored 26 orbital mission beacons from PC602 HomeScene291.
/// These are world-space line segments on REAL NewHome290 height; they are
/// not map/UI decorations and never award mission completion.
enum PC602HomeBeacons291 {
    struct Vertex {
        var position:SIMD4<Float>
        var tint:SIMD4<Float>
    }
    static let levels=26
    static let ringSegments=40
    static let verticesPerLevel=(ringSegments+1)*2

    private static func dot(_ a:SIMD3<Float>,_ b:SIMD3<Float>)->Float {
        a.x*b.x+a.y*b.y+a.z*b.z
    }
    private static func cross(_ a:SIMD3<Float>,_ b:SIMD3<Float>)->SIMD3<Float> {
        SIMD3(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x)
    }
    private static func unit(_ p:SIMD3<Float>)->SIMD3<Float>? {
        let length=sqrt(dot(p,p))
        return length>1e-6 && length.isFinite ? p/length : nil
    }

    static func vertices(home:PC602NewHome290,
                         selected:Int,completedMask:Int)->[Vertex]? {
        guard (1...levels).contains(selected) else{return nil}
        var points=[Vertex]()
        points.reserveCapacity(levels*verticesPerLevel)
        let y=SIMD3<Float>(0,1,0)
        let x=SIMD3<Float>(1,0,0)
        func append(_ p:SIMD3<Float>,_ tint:SIMD4<Float>) {
            points.append(Vertex(
                position:SIMD4(p.x,p.y,p.z,1),tint:tint))
        }
        for level in 1...levels {
            guard let beacon=home.beacon(level),
                  let n=unit(beacon),let height=home.surface(n)
            else{return nil}
            let complete=PC602HomeFlight291.completed(
                level,mask:completedMask)
            let unlocked=PC602HomeFlight291.unlocked(
                level,mask:completedMask)
            let rgb:SIMD3<Float>
            if complete {
                rgb=SIMD3(95/255,236/255,161/255)
            } else if unlocked {
                rgb=SIMD3(82/255,217/255,255/255)
            } else {
                rgb=SIMD3(110/255,124/255,139/255)
            }
            let selectedMarker=level==selected
            let tint=SIMD4(rgb.x,rgb.y,rgb.z,
                           selectedMarker ? 1 : 0.66)
            // PC602 HomeScene291 first vertical line begins at H290+0.5m.
            append(n*(height+0.5),tint)
            append(beacon,tint)

            var right=unit(cross(n,y))
            if right==nil {right=unit(cross(n,x))}
            guard let tangent=right,let side=unit(cross(n,tangent))
            else{return nil}
            let radius:Float=selectedMarker ? 8 : 3.4
            for j in 0..<ringSegments {
                let a=Float(j)*Float.pi/20
                let b=Float(j+1)*Float.pi/20
                let first=beacon+(tangent*cos(a)+side*sin(a))*radius
                let second=beacon+(tangent*cos(b)+side*sin(b))*radius
                append(first,tint)
                append(second,tint)
            }
        }
        return points.count==levels*verticesPerLevel ? points : nil
    }
}
