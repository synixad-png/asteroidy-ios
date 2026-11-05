import Foundation

/// Camera-oriented translucent atmospheric dome from actual
/// Windows/src/GpuPlanet.cs:9-36, v568. A stable untextured mesh
/// identical to the 24 rings x 96 segments x 2 triangles in C#.
///
/// Only the Boreas GLB preview (original planet level 5) uses this
/// source-proven colour: PlanetBiomes.cs:12, Glow=#95DBFF.
/// This is NOT a generic guessed palette for every future planet.
enum IntroAtmosphere47 {
    typealias V = SphereVector3
    static let rings = 24
    static let segments = 96
    static let outerRadius: Float = 1.34
    static let red: Float = 149.0/255.0
    static let green: Float = 219.0/255.0
    static let blue: Float = 255.0/255.0

    static func haze(radius r: Float) -> Float {
        // Original GpuPlanet.AtmosphereVertex: translucent centre and
        // bright limb, smooth outer edge. Preserve the source formula.
        let limb = (r-1.055)/0.125
        let shell: Float = 0.058+0.33*exp(-limb*limb)
        let edge = max(0,min(1,(outerRadius-r)/0.18))
        return shell*edge*edge*(3-2*edge)
    }

    static func point(radius r: Float, angle: Float) -> V {
        let depth = sqrt(max(0,outerRadius*outerRadius-r*r))
        return V(x:r*cos(angle),y:r*sin(angle),z:depth)
    }

    static func basis(center:V,eye:V)->(x:V,y:V,z:V) {
        // PlanetCrawler.Cross(up,z) + Cross(z,x), source line 29.
        let z=(eye-center).normalized
        let up=abs(z.y)<0.95 ? V(x:0,y:1,z:0) : V(x:1,y:0,z:0)
        let x=V.cross(up,z).normalized
        return (x,V.cross(z,x).normalized,z)
    }

    static func geometry() -> (vertices:[AssetMesh.Vertex],indices:[UInt32]) {
        var vertices:[AssetMesh.Vertex]=[]
        var indices:[UInt32]=[]
        vertices.reserveCapacity(rings*segments*6)
        indices.reserveCapacity(rings*segments*6)
        func append(_ radius:Float,_ angle:Float) {
            let p=point(radius:radius,angle:angle)
            let a=haze(radius:radius)
            vertices.append(AssetMesh.Vertex(
                position:SIMD4<Float>(p.x,p.y,p.z,1),
                color:SIMD4<Float>(red,green,blue,a),
                normal:SIMD4<Float>(0,0,1,0)))
            indices.append(UInt32(indices.count))
        }
        for ring in 0..<rings {
            let r=Float(ring)*outerRadius/Float(rings)
            let s=Float(ring+1)*outerRadius/Float(rings)
            for segment in 0..<segments {
                let a=Float(segment)*Float.pi/48
                let next=Float(segment+1)*Float.pi/48
                // Exactly GpuPlanet.cs:25-27 triangle and vertex order.
                append(r,a);append(s,a);append(s,next)
                append(r,a);append(s,next);append(r,next)
            }
        }
        return (vertices,indices)
    }
}
