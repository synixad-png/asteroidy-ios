import Foundation

/// Original Windows/src/GpuShip.cs:10-16 and GpuToon60.cs:34,64,279.
/// Vanguard431 uses material slot 0. BeginToon60(lit:true,
/// textured:true) selects the source toon program by default because
/// ToonEnabled60=true. The active source fragment shader uses the
/// directional key light (0x4000, w=0) and its real 3-step diffuse
/// bands; the second FighterLight source is relevant only when toon
/// mode is disabled. This source-faithful illumination *formula* does
/// not recover the glTF skin/UVs that the current AS3D v1 omitted.
enum SourceFighterToon60 {
    typealias V=SphereVector3
    static let keyDirection = V(x:-0.6,y:0.8,z:1.4).normalized

    static func smoothstep(_ a:Float,_ b:Float,_ value:Float)->Float {
        let t=max(Float(0),min(Float(1),(value-a)/(b-a)))
        return t*t*(3-2*t)
    }

    static func diffuseBand(normalEye:V)->Float {
        let n=normalEye.normalized
        let d=max(Float(0),V.dot(n,keyDirection))
        return 0.25
            + 0.33*smoothstep(0.30,0.32,d)
            + 0.40*smoothstep(0.70,0.72,d)
    }

    static func rim(normalEye:V,positionEye:V)->Float {
        let n=normalEye.normalized
        let view=(positionEye * -1).normalized
        let d=max(Float(0),V.dot(n,keyDirection))
        let angle=1-max(Float(0),V.dot(n,view))
        return 0.10*smoothstep(0.72,0.86,angle)
            * smoothstep(0.10,0.30,d)
    }

    static func shade(base:V,normalEye:V,positionEye:V)->V {
        let brightness=diffuseBand(normalEye:normalEye)
            + rim(normalEye:normalEye,positionEye:positionEye)
        func channel(_ value:Float)->Float {
            min(Float(1),max(Float(0),value*brightness))
        }
        return V(x:channel(base.x),y:channel(base.y),z:channel(base.z))
    }
}
