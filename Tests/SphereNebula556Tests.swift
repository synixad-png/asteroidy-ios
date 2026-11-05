import Foundation

/// Original v556 Windows/src/GpuCosmos39.cs:4–7 and
/// GpuIntro41.cs:122,451. Only the original two sky themes are used
/// by orbit mode; other six-theme LivingCosmos belongs to other UI.
@main struct SphereNebula556Tests {
    static func near(_ x:Float,_ y:Float,_ tolerance:Float=0.005) {
        precondition(x.isFinite && abs(x-y)<=tolerance,
            "v556 GpuCosmos39 cloud coordinate/alpha diverged: \(x) vs \(y)")
    }
    static func main() {
        precondition(SphereNebula556.imageSize==256)
        precondition(SphereNebula556.orbitThemeCount==2)
        precondition(SphereNebula556.orbitLayerCount==36)
        // Independent C# unchecked CloudHash goldens, including
        // negative coordinates and a high-valued seed.
        for (x,y,seed,bits) in [
            (0,0,0,0),(12,-7,5,45748),(255,255,1,5606),
            (-4,9,19,47861),(21,88,7,13439)] {
            near(SphereNebula556.hash(x,y,seed),
                 Float(bits)/65535,tolerance:0.0000005)
        }
        let golden:[(Int,Int,Int,[Int])]=[
            (0,127,127,[68,21,53,82]),
            (0,64,128,[121,40,96,143]),
            (0,127,145,[156,49,123,187]),
            (1,127,127,[136,95,24,175]),
            (1,64,128,[31,21,5,40]),
            (1,127,145,[132,94,26,166])
        ]
        for (theme,x,y,bgra) in golden {
            let result=SphereNebula556.pixel(x:x,y:y,theme:theme)
            let values=[Int(result.0),Int(result.1),
                        Int(result.2),Int(result.3)]
            for i in 0..<4 {
                // Float32 path in original C# may differ by at most a
                // byte at an alpha rounding boundary vs Swift's Double
                // Math.Pow. Any larger error is a source discrepancy.
                precondition(abs(values[i]-bgra[i])<=2,
                    "Original nebula theme \(theme), px \(x),\(y) differs")
            }
        }
        for theme in 0..<SphereNebula556.orbitThemeCount {
            let texels=SphereNebula556.textureBGRA(theme:theme)
            precondition(texels.count==256*256*4)
            for (x,y) in [(0,0),(255,0),(0,255),(255,255)] {
                let p=(y*256+x)*4
                precondition(texels[p]==0 && texels[p+1]==0 &&
                             texels[p+2]==0 && texels[p+3]==0,
                             "PArgb texture border must be transparent")
            }
            let p=(127*256+127)*4
            precondition(texels[p+3]>0)
            precondition(texels[p]<=texels[p+3] &&
                         texels[p+1]<=texels[p+3] &&
                         texels[p+2]<=texels[p+3],
                         "BGRA cloud must be premultiplied")
        }
        let far=SphereNebula556.layer(0)
        precondition(!far.near && far.theme==0)
        near(far.direction.x,900)
        near(far.direction.y,0)
        near(far.direction.z,0)
        near(far.alpha,37/255)
        let farSecond=SphereNebula556.layer(1)
        precondition(!farSecond.near && farSecond.theme==1)
        let close=SphereNebula556.layer(24)
        precondition(close.near && close.theme==0)
        near(close.direction.x,380)
        near(close.direction.y,0)
        near(close.direction.z,0)
        near(close.alpha,140/255)
        precondition(SphereNebula556.layer(35).near)
        precondition(SphereNebula556.layer(35).theme==1)

        // Original SkyProject55 looks only at orientation (no eye).
        // At the antipode of the cloud's direction it must project
        // exactly to the screen centre; behind the camera it must go.
        for i in 0..<SphereNebula556.orbitLayerCount {
            let layer=SphereNebula556.layer(i)
            precondition(layer.theme==(i%2))
            precondition(layer.near==(i>=24))
            let cam=SphereCamera67(at:Sphere67.coordinates(
                layer.direction.normalized * -1))
            guard let projection=layer.projected(camera:cam) else {
                fatalError("Original source cloud must face camera")
            }
            near(projection.center.x,640,0.03)
            near(projection.center.y,360,0.03)
            near(projection.width,projection.size*2)
            near(projection.height,projection.size*(layer.near ? 1.1:0.48))
            let back=SphereCamera67(at:Sphere67.coordinates(
                layer.direction.normalized))
            precondition(layer.projected(camera:back)==nil)
        }
        let farCenter=far.projected(camera:SphereCamera67(
            at:Sphere67.coordinates(SphereVector3(x:-1,y:0,z:0))))!
        near(farCenter.size,152)
        near(farCenter.height,72.96)
        let nearCenter=close.projected(camera:SphereCamera67(
            at:Sphere67.coordinates(SphereVector3(x:-1,y:0,z:0))))!
        near(nearCenter.size,720*220/380)
        print("PASS: source GpuCosmos39 CloudHash/noise and PArgb256,")
        print("      2 real cloud textures, 24 far +12 near GpuIntro41 layers,")
        print("      all 36 SkyProject55 camera/culling and source screen sizes")
        print("LIMITATION: tests Swift/Linux only; native Metal GPU not verified")
    }
}
