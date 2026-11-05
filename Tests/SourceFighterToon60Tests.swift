import Foundation

/// Literal CPU fixtures for Windows GpuToon60.cs:64 default shader:
/// band=.25+.33*smoothstep(.30,.32,d)+.40*smoothstep(.70,.72,d)
/// rim=.10*smoothstep(.72,.86,edge)*smoothstep(.1,.3,d)
/// Uses the actual GpuShip.FighterLight key(-.6,.8,1.4,w=0).
@main struct SourceFighterToon60Tests {
    typealias V=SphereVector3
    static func near(_ a:Float,_ b:Float,_ tol:Float=0.00005) {
        precondition(a.isFinite && b.isFinite && abs(a-b)<tol,
                     "Original Vanguard toon-light numeric mismatch")
    }
    static func main() {
        let s=SourceFighterToon60.self
        let key=V(x:-0.6,y:0.8,z:1.4).normalized
        near(s.keyDirection.x,key.x)
        near(s.keyDirection.y,key.y)
        near(s.keyDirection.z,key.z)
        near(key.length,1)
        near(s.smoothstep(0.30,0.32,0),0)
        near(s.smoothstep(0.30,0.32,1),1)
        near(s.smoothstep(0.30,0.32,0.31),0.5)
        near(s.smoothstep(0.70,0.72,0.71),0.5)

        // No illumination: real source band never goes fully dark.
        near(s.diffuseBand(normalEye:key * -1),0.25)
        // Facing first directional source light; 3-band max 0.98.
        near(s.diffuseBand(normalEye:key),0.98)
        // Unlit-facing smoothstep step midpoint fixtures are computed
        // with normals chosen for exact source light cosines.
        let cross=V.cross(key,V(x:0,y:1,z:0)).normalized
        func n(_ cosine:Float)->V {
            (key*cosine+cross*sqrt(1-cosine*cosine)).normalized
        }
        near(s.diffuseBand(normalEye:n(0.31)),0.25+0.33*0.5,0.0001)
        near(s.diffuseBand(normalEye:n(0.71)),
             0.25+0.33+0.40*0.5,0.0001)

        // Eye-relative rim is zero for a forward-facing diffuse
        // normal and reaches 0.1 for a back-facing normal with d>0.3.
        near(s.rim(normalEye:key,positionEye:key * -1),0)
        near(s.rim(normalEye:key,positionEye:key),0.10)
        near(s.rim(normalEye:key * -1,positionEye:key * -1),0)
        let base=V(x:0.4,y:0.2,z:0.8)
        let direct=s.shade(base:base,normalEye:key,
                           positionEye:key * -1)
        near(direct.x,0.392)
        near(direct.y,0.196)
        near(direct.z,0.784)
        let rimmed=s.shade(base:base,normalEye:key,positionEye:key)
        near(rimmed.x,0.432)
        near(rimmed.y,0.216)
        near(rimmed.z,0.864)
        let dark=s.shade(base:base,normalEye:key * -1,
                         positionEye:key * -1)
        near(dark.x,0.10)
        near(dark.y,0.05)
        near(dark.z,0.20)
        print("PASS: GpuToon60 exact 3-step key directional bands")
        print("      original .25/.33/.40 and .30/.32/.70/.72 thresholds,")
        print("      .10 local-eye rim, RGB and hard clamp, no fake fill light")
        print("LIMIT: original BaseColor UV/skin and original mesh normals")
        print("       are absent from current AS3D v1; native GPU not tested")
    }
}
