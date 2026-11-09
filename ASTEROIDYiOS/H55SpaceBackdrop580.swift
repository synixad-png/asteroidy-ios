import Foundation
import SceneKit
import UIKit
import CoreGraphics

/// PC GpuHub90.cs:161-169 draws IntroSky BEFORE the GLB. No sky is
/// embedded in the imported hangar. SceneKit translates existing original
/// SphereSky207, SphereNebula556 and DeepSkyPlanets55 source assets into
/// one reusable direction-locked panoramic background, not a fake GLB.
/// The PC draws 2D quads, so projection pixels are not identical here.
@MainActor enum H55SpaceBackdrop580 {
    static let nodeName="H55_PC580_INTRO_SKY"
    private static let width=2048, height=1024

    private static func uv(_ source:SphereVector3)->CGPoint {
        let n=source.normalized
        let lon=atan2(Double(n.z),Double(n.x))
        let lat=asin(Double(max(-1,min(1,n.y))))
        var u=0.5+lon/(2*Double.pi)
        u-=floor(u)
        return CGPoint(x:u*Double(width),
                       y:(0.5-lat/Double.pi)*Double(height))
    }
    private static func imageBGRA(_ data:[UInt8],w:Int,h:Int)->CGImage? {
        guard data.count==w*h*4,
              let provider=CGDataProvider(data:Data(data) as CFData)
        else{return nil}
        let bits=CGBitmapInfo(rawValue:
            CGImageAlphaInfo.premultipliedFirst.rawValue |
            CGBitmapInfo.byteOrder32Little.rawValue)
        return CGImage(width:w,height:h,bitsPerComponent:8,bitsPerPixel:32,
               bytesPerRow:w*4,space:CGColorSpaceCreateDeviceRGB(),
               bitmapInfo:bits,provider:provider,decode:nil,
               shouldInterpolate:true,intent:.defaultIntent)
    }

    /// Allocate once, share texture and GPU geometry on repeated entry.
    private static let panoramicTexture:UIImage = {
        let fmt=UIGraphicsImageRendererFormat()
        fmt.opaque=true
        fmt.scale=1
        let renderer=UIGraphicsImageRenderer(
            size:CGSize(width:width,height:height),format:fmt)
        let clouds=(0..<SphereNebula556.orbitThemeCount).map{theme in
            imageBGRA(SphereNebula556.textureBGRA(theme:theme),
                      w:SphereNebula556.imageSize,
                      h:SphereNebula556.imageSize)
        }
        let planets=(0..<DeepSkyPlanets55.count).map{style in
            imageBGRA(DeepSkyPlanets55.textureBGRA(style:style),
                      w:DeepSkyPlanets55.textureWidth,
                      h:DeepSkyPlanets55.textureHeight)
        }
        return renderer.image { state in
            let c=state.cgContext
            c.setFillColor(UIColor(red:0.012,green:0.021,
                                   blue:0.04,alpha:1).cgColor)
            c.fill(CGRect(x:0,y:0,width:width,height:height))

            func projected(_ image:CGImage?,at p:CGPoint,
                           width w:CGFloat,height h:CGFloat,
                           alpha:CGFloat) {
                guard let image else{return}
                c.saveGState()
                c.setAlpha(alpha)
                // Draw across the equirectangular UV seam as needed.
                for shift in [-CGFloat(width),0,CGFloat(width)] {
                    c.draw(image,in:CGRect(x:p.x-w/2+shift,
                          y:p.y-h/2,width:w,height:h))
                }
                c.restoreGState()
            }
            // Same PC painter order: 24 far clouds, 3 distant worlds,
            // then 12 near source clouds and all 1500 original stars.
            for i in 0..<24 {
                let n=SphereNebula556.layer(i)
                projected(clouds[n.theme],at:uv(n.direction),
                          width:195,height:87,alpha:CGFloat(n.alpha))
            }
            for i in 0..<DeepSkyPlanets55.count {
                projected(planets[i],at:uv(DeepSkyPlanets55.direction(style:i,time:0)),
                          width:148,height:105,alpha:1)
            }
            for i in 24..<SphereNebula556.orbitLayerCount {
                let n=SphereNebula556.layer(i)
                projected(clouds[n.theme],at:uv(n.direction),
                          width:250,height:138,alpha:CGFloat(n.alpha))
            }
            for i in 0..<SphereSky207.count {
                let star=SphereSky207.star(i)
                let p=uv(star.direction)
                let color=UIColor(red:CGFloat(star.red),green:CGFloat(star.green),
                                  blue:CGFloat(star.blue),alpha:CGFloat(star.alpha))
                if SphereSky207.hasBrightHalo(star) {
                    let radius:CGFloat=star.pixelSize==2.8 ? 8:4
                    c.setFillColor(color.withAlphaComponent(0.16).cgColor)
                    c.fillEllipse(in:CGRect(x:p.x-radius,y:p.y-radius,
                                            width:2*radius,height:2*radius))
                }
                let radius:CGFloat=star.pixelSize==2.8 ? 2.7 :
                    (star.pixelSize>1 ? 1.7:0.9)
                c.setFillColor(color.cgColor)
                c.fillEllipse(in:CGRect(x:p.x-radius,y:p.y-radius,
                                        width:radius*2,height:radius*2))
            }
        }
    }()

    static func make()->SCNNode {
        let sphere=SCNSphere(radius:110)
        sphere.segmentCount=96
        let material=SCNMaterial()
        material.name="PC580_IntroSky547_source_assets"
        material.lightingModel = .constant
        material.diffuse.contents=panoramicTexture
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .clamp
        material.isDoubleSided=true
        material.writesToDepthBuffer=false
        material.readsFromDepthBuffer=false
        sphere.materials=[material]
        let node=SCNNode(geometry:sphere)
        node.name=nodeName
        node.renderingOrder = -100
        return node
    }
}
