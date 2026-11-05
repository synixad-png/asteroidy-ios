import Foundation

/// Direct cross-checks for Windows/src/GpuIntro41.cs:
/// BuildBlackHoleDisk55, BuildBlackHoleCore55, DrawSkyBlackHole55.
/// Independent CPU fixture values are from the original C# equations;
/// alpha/rounding differences of <=3 bytes are tolerated per pixel.
@main struct BlackHoleSky55Tests {
    static func near(_ x:Float,_ y:Float,_ tol:Float=0.003) {
        precondition(x.isFinite && abs(x-y)<=tol,
            "Source v556 black-hole geometric value mismatch: \(x) / \(y)")
    }
    static func pixel(_ actual:(UInt8,UInt8,UInt8,UInt8),
                      _ expected:[Int],tol:Int=4) {
        let bytes=[Int(actual.0),Int(actual.1),
                   Int(actual.2),Int(actual.3)]
        precondition(bytes.count==4 && expected.count==4)
        for j in 0..<4 {
            precondition(abs(bytes[j]-expected[j])<=tol,
                         "Source pixel channel \(j): \(bytes[j]) vs \(expected[j])")
        }
    }
    static func main() {
        precondition(BlackHoleSky55.imageSize==640)
        near(BlackHoleSky55.sourceRadius,258)
        near(BlackHoleSky55.maxScale,3.10)
        near(BlackHoleSky55.smooth(0),0)
        near(BlackHoleSky55.smooth(0.5),0.5)
        near(BlackHoleSky55.smooth(1),1)
        near(BlackHoleSky55.smooth(-3),0)
        near(BlackHoleSky55.smooth(3),1)

        // C# BuildBlackHoleDisk55's rotated 25-degree split:
        // the rear gap is transparent at the core, while the FRONT
        // layer must cross the event horizon. Bitmap has true BGRA.
        pixel(BlackHoleSky55.diskPixel(x:0,y:0,front:false),[0,0,0,0])
        pixel(BlackHoleSky55.diskPixel(x:319,y:319,front:false),
              [0,0,0,0])
        pixel(BlackHoleSky55.corePixel(x:319,y:319),[0,0,0,255])
        pixel(BlackHoleSky55.diskPixel(x:319,y:319,front:true),
              [6,6,15,80])
        pixel(BlackHoleSky55.diskPixel(x:320,y:230,front:false),
              [54,39,55,103])
        pixel(BlackHoleSky55.corePixel(x:400,y:320),
              [197,190,186,197])
        pixel(BlackHoleSky55.diskPixel(x:250,y:320,front:true),
              [53,54,99,182])
        pixel(BlackHoleSky55.diskPixel(x:450,y:320,front:false),
              [92,48,87,187])
        pixel(BlackHoleSky55.diskPixel(x:320,y:400,front:true),
              [255,248,255,255])

        // Test all three complete PArgb layers and critical pixels.
        var images:[[UInt8]]=[]
        for layer in 0..<3 {
            let data=BlackHoleSky55.textureBGRA(slice:layer)
            precondition(data.count==640*640*4)
            precondition(data[0]==0 && data[1]==0 &&
                         data[2]==0 && data[3]==0)
            for (x,y) in [(319,319),(400,320),(320,400),(250,320)] {
                let p=(y*640+x)*4
                let px=Array(data[p..<(p+4)])
                precondition(px[0]<=px[3] && px[1]<=px[3] &&
                             px[2]<=px[3],
                    "Original Format32bppPArgb requires premultiplied BGRA")
            }
            images.append(data)
        }
        let p=(319*640+319)*4
        precondition(images[0][p+3]==0)
        precondition(images[1][p+3]==255)
        precondition(images[2][p+3]>0)

        let direction=BlackHoleSky55.animatedDirection(time:0)
        near(direction.length,1)
        let later=BlackHoleSky55.animatedDirection(time:42)
        precondition((later-direction).length>0.0001)
        let facing=SphereCamera67(at:Sphere67.coordinates(direction * -1))
        guard let projected=BlackHoleSky55.project(camera:facing,time:0)
        else {fatalError("Black hole should be projected at antipode")}
        near(projected.screen.x,640,0.02)
        near(projected.screen.y,360,0.02)
        near(projected.scale,1)
        let behind=SphereCamera67(at:Sphere67.coordinates(direction))
        precondition(BlackHoleSky55.project(camera:behind,time:0)==nil)

        let overlays=BlackHoleSky55.overlays(time:0,scale:1)
        precondition(overlays.count==10)
        near(overlays[0].radiusX,516)
        near(overlays[1].radiusX,258*1.54)
        near(overlays[2].radiusX,258*1.10)
        near(overlays[0].rgba.3,42/255)
        near(overlays[1].rgba.3,62/255)
        near(overlays[2].rgba.3,28/255)
        for i in 0..<3 {
            precondition(!overlays[i].isTexture && overlays[i].layer==3)
        }
        for i in 3..<7 {
            precondition(!overlays[i].isTexture)
            precondition(overlays[i].layer==3)
        }
        // Source pulsing/time based spin and 4 ray sizes in this order.
        near(overlays[3].radiusX,258*2.10*0.92)
        near(overlays[3].radiusY,258*0.20*0.5)
        near(overlays[3].rgba.3,44/255)
        near(overlays[4].angle,1.5708)
        near(overlays[4].rgba.3,30/255)
        near(overlays[5].angle,0.66)
        near(overlays[5].rgba.3,22/255)
        near(overlays[6].angle,2.20)
        near(overlays[6].rgba.3,20/255)
        for i in 7..<10 {
            precondition(overlays[i].isTexture && overlays[i].layer==i-7)
            near(overlays[i].radiusX,258)
            near(overlays[i].radiusY,258)
            near(overlays[i].rgba.3,1)
        }
        let noGlow=BlackHoleSky55.overlays(time:0,scale:1,glow:false)
        precondition(noGlow.count==7)
        precondition(noGlow[4].layer==0 && noGlow[6].layer==2)
        let moving=BlackHoleSky55.overlays(time:10,scale:2)
        precondition(abs(moving[3].radiusX-overlays[3].radiusX)>1)
        near(moving[3].angle,2.2)
        print("PASS: v556 GpuIntro41 three 640px PArgb black-hole")
        print("      layers, rear gap/core/front overlap, source pixel goldens,")
        print("      animated direction and 3 halo + 4 ray + 3 disk order")
        print("LIMITATION: Swift/Linux only, native Apple GPU not verified")
    }
}
