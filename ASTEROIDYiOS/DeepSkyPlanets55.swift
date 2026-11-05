import Foundation

/// Literal source data and procedural pixel math from the real
/// Windows/src/GpuIntro41.cs:27-63 in ASTEROIDY v556. Source image is
/// a Windows System.Drawing Bitmap(320,220); its procedural PLANET
/// SURFACE colours are transcribed 1:1. The pen strokes/antialiasing
/// below emulate the source Graphics.DrawEllipse/DrawArc with analytic
/// ellipse coverage, so those GDI+ edge pixels are APPROXIMATIONS,
/// not falsely claimed bit-identical Windows GDI rasterization.
enum DeepSkyPlanets55 {
    static let textureWidth=320
    static let textureHeight=220
    static let count=3

    struct Profile {
        let style:Int
        let base:SphereVector3
        let amplitudeX:Float
        let amplitudeY:Float
        let speed:Float
        let phase:Float
        let halfWidth:Float
        let halfHeight:Float
        let maxScale:Float
        let glow:(Float,Float,Float,Float)
    }

    static func profile(_ style:Int)->Profile {
        precondition((0..<count).contains(style))
        switch style {
        case 0:
            return Profile(
                style:0,base:SphereVector3(x:0.94,y:0.02,z:-0.34),
                amplitudeX:0.006,amplitudeY:0.005,speed:0.10,phase:0.2,
                halfWidth:148,halfHeight:96,maxScale:2.05,
                glow:(255,208,140,28))
        case 1:
            return Profile(
                style:1,base:SphereVector3(x:0.18,y:-0.62,z:-0.76),
                amplitudeX:0.007,amplitudeY:0.006,speed:0.08,phase:1.6,
                halfWidth:176,halfHeight:116,maxScale:2.25,
                glow:(120,196,255,44))
        default:
            return Profile(
                style:2,base:SphereVector3(x:-0.78,y:0.42,z:-0.46),
                amplitudeX:0.006,amplitudeY:0.006,speed:0.06,phase:3.1,
                halfWidth:166,halfHeight:108,maxScale:2.18,
                glow:(255,142,116,34))
        }
    }

    struct Projection {
        let screen:Vec2
        let depth:Float
        let scale:Float
    }
    static func direction(style:Int,time:Float)->SphereVector3 {
        let p=profile(style)
        // Exact GpuIntro41.AnimatedSkyDirection55
        let t=time*p.speed+p.phase
        return SphereVector3(
            x:p.base.x+sin(t)*p.amplitudeX,
            y:p.base.y+cos(t*0.83+p.phase*0.6)*p.amplitudeY,
            z:p.base.z+sin(t*0.57+p.phase*0.3)*p.amplitudeX*0.4
        ).normalized
    }
    static func project(style:Int,time:Float,camera:SphereCamera67)
        ->Projection? {
        let frame=SphereCameraView556(camera:camera)
        let world=direction(style:style,time:time)*900
        let depth = -SphereVector3.dot(frame.back,world)
        guard depth>0.4 else {return nil}
        let screenX=640+SphereVector3.dot(frame.right,world)*720/max(0.01,depth)
        let screenY=360-SphereVector3.dot(frame.up,world)*720/max(0.01,depth)
        guard screenX > -260 && screenX < 1540 &&
              screenY > -170 && screenY < 900 else {return nil}
        return Projection(
            screen:Vec2(x:screenX,y:screenY),depth:depth,
            scale:min(profile(style).maxScale,900/depth))
    }

    /// Windows GpuIntro41.PlanetShade55: integer truncation,
    /// light * band clamped before lerping source A and B channels.
    static func shade(light:Float,band:Float,a:Int,b:Int)->UInt8 {
        let blend=max(Float(0),min(Float(1),light*band))
        return UInt8(max(0,min(255,Int(Float(a)+Float(b-a)*blend))))
    }

    struct Pixel {
        var r:Float=0
        var g:Float=0
        var b:Float=0
        var a:Float=0

        /// GDI+ source-over pen drawing on a transparent/opaque Bitmap.
        /// Uses straight RGB during compositing; output is converted
        /// to premultiplied BGRA for Metal as GpuRenderer.Texture does.
        mutating func over(_ red:Float,_ green:Float,_ blue:Float,
                           _ alpha:Float,_ coverage:Float) {
            let sa=max(0,min(1,alpha*max(0,min(1,coverage))))
            if sa<=0 {return}
            let da=a
            let outA=sa+da*(1-sa)
            guard outA>0 else {return}
            r=(red*sa+r*da*(1-sa))/outA
            g=(green*sa+g*da*(1-sa))/outA
            b=(blue*sa+b*da*(1-sa))/outA
            a=outA
        }
        func bgra()->(UInt8,UInt8,UInt8,UInt8) {
            let a8=max(0,min(255,Int(a*255)))
            let r8=max(0,min(255,Int(r)))
            let g8=max(0,min(255,Int(g)))
            let b8=max(0,min(255,Int(b)))
            return (UInt8(b8*a8/255),UInt8(g8*a8/255),
                    UInt8(r8*a8/255),UInt8(a8))
        }
    }

    static func baseColours(_ style:Int)->(
        a:(Int,Int,Int),b:(Int,Int,Int),
        light:(Float,Float,Float),freq:Float,warp:Float) {
        switch style {
        case 1:
            return ((20,45,78),(158,215,255),
                    (0.60,0.18,0.76),18,4.8)
        case 2:
            return ((68,26,38),(235,133,96),
                    (0.42,0.36,0.78),9,6.4)
        default:
            return ((66,45,28),(205,160,104),
                    (0.56,0.42,0.66),28,5.6)
        }
    }

    /// Source's exact per-pixel SetPixel body (before DrawArc pens).
    /// Returns nil outside the planetary circle. Note this OVERWRITES
    /// back-ring GDI pixels, just like source Bitmap.SetPixel.
    static func body(x:Int,y:Int,style:Int)->Pixel? {
        precondition((0..<count).contains(style))
        let nx=(Float(x)-160)/88
        let ny=(Float(y)-110)/88
        let rad=nx*nx+ny*ny
        guard x>=70 && x<250 && y>=20 && y<200 && rad<1
        else {return nil}
        let cfg=baseColours(style)
        let z=sqrt(1-rad)
        let lightDot=(-nx*cfg.light.0-ny*cfg.light.1+z*cfg.light.2)
        let lit:Float=0.10+0.90*max(0,lightDot)
        let opacity=Float(min(255,Int((1-rad)*3900)))/255
        let bands:Float
        if style==0 {
            let band=0.77+0.18*sin(ny*cfg.freq+0.65*sin(nx*cfg.warp))
            let storm:Float=0.06*sin(nx*12-ny*8)
            bands=band+storm
        } else if style==1 {
            let band=0.84+0.12*sin(ny*cfg.freq+0.35*sin(nx*cfg.warp))
            let cloudA:Float=0.10*exp(-pow(ny+0.16,2)*14)
            let cloudB:Float=0.07*exp(-pow(ny-0.28,2)*18)
            let capA:Float=0.16*exp(-pow(ny+0.72,2)*40)
            let capB:Float=0.10*exp(-pow(ny-0.70,2)*44)
            let cloud=cloudA+cloudB
            let cap=capA+capB
            bands=band+cloud+cap
        } else {
            let lavaA:Float=0.12*sin(nx*9+ny*11)
            let lavaB:Float=0.08*sin(nx*22-ny*14)
            let scarA:Float=0.18*exp(-(pow(nx+0.22,2)+pow(ny-0.16,2))*18)
            let scarB:Float=0.12*exp(-(pow(nx-0.38,2)+pow(ny+0.10,2))*26)
            let lava=lavaA+lavaB
            let scar=scarA+scarB
            let dust:Float=0.80+0.10*sin((nx-ny)*cfg.freq)
            bands=dust+lava+scar
        }
        return Pixel(
            r:Float(shade(light:lit,band:bands,a:cfg.a.0,b:cfg.b.0)),
            g:Float(shade(light:lit,band:bands,a:cfg.a.1,b:cfg.b.1)),
            b:Float(shade(light:lit,band:bands,a:cfg.a.2,b:cfg.b.2)),
            a:opacity)
    }

    /// A pixel-distance approximation of GDI+ AA ellipse stroke.
    /// Original DrawEllipse pen centers correspond to Rectangle:
    /// (12,90,296,50) and (26,95,268,40).
    static func strokeCoverage(x:Float,y:Float,
                               cx:Float,cy:Float,
                               rx:Float,ry:Float,
                               width:Float)->Float {
        let dx=x-cx,dy=y-cy
        let implicitRadius=(dx*dx)/(rx*rx)+(dy*dy)/(ry*ry)-1
        let gradient=2*sqrt(pow(dx/(rx*rx),2)+pow(dy/(ry*ry),2))
        let distance=abs(implicitRadius)/max(gradient,0.001)
        return max(0,min(1,width*0.5+0.5-distance))
    }

    /// Original Windows GDI+ angles increase clockwise in image
    /// coordinates (0°=right, 90°=down). Arc clipping is an AA
    /// approximation and is NOT asserted to be GDI+-pixel-identical.
    static func arcIncluded(x:Float,y:Float,
                            cx:Float,cy:Float,
                            rx:Float,ry:Float,
                            start:Float,span:Float)->Bool {
        let angle=atan2((y-cy)/ry,(x-cx)/rx)*180/Float.pi
        let norm=angle>=0 ? angle : angle+360
        let delta=norm>=start ? norm-start : norm+360-start
        return delta<=span
    }

    static func textureBGRA(style:Int)->[UInt8] {
        precondition((0..<count).contains(style))
        var image=[UInt8](repeating:0,count:textureWidth*textureHeight*4)
        let gas=style==0
        // The original bitmap has GDI ring strokes BEHIND the sphere
        // only for style0, while front arcs/glints overlay afterwards.
        for y in 0..<textureHeight {
            for x in 0..<textureWidth {
                let fx=Float(x),fy=Float(y)
                var p=Pixel()
                if gas {
                    let outer=strokeCoverage(
                        x:fx,y:fy,cx:160,cy:115,rx:148,ry:25,width:7)
                    let inner=strokeCoverage(
                        x:fx,y:fy,cx:160,cy:115,rx:134,ry:20,width:7)
                    p.over(161,149,126,110/255,outer)
                    p.over(161,149,126,110/255,inner)
                }
                // Bitmap.SetPixel, not blending: sphere overwrites
                // underlying back ring even at its transparent limb.
                if let planet=body(x:x,y:y,style:style) {p=planet}
                if gas {
                    let outer=strokeCoverage(
                        x:fx,y:fy,cx:160,cy:115,rx:148,ry:25,width:5)
                    let inner=strokeCoverage(
                        x:fx,y:fy,cx:160,cy:115,rx:134,ry:20,width:5)
                    if arcIncluded(x:fx,y:fy,cx:160,cy:115,
                                   rx:148,ry:25,start:0,span:180) {
                        p.over(188,169,137,160/255,outer)
                    }
                    if arcIncluded(x:fx,y:fy,cx:160,cy:115,
                                   rx:134,ry:20,start:0,span:180) {
                        p.over(188,169,137,160/255,inner)
                    }
                }
                // Source DrawArc(Pen(white glow,2),96,46,128,128,212,86)
                let white=strokeCoverage(x:fx,y:fy,cx:160,cy:110,
                                         rx:64,ry:64,width:2)
                if arcIncluded(x:fx,y:fy,cx:160,cy:110,
                               rx:64,ry:64,start:212,span:86) {
                    p.over(255,255,255,(style==1 ? 120:90)/255,white)
                }
                if style==2 {
                    // Source crimson haze arc at (74,30,172,154).
                    let haze=strokeCoverage(x:fx,y:fy,cx:160,cy:107,
                                            rx:86,ry:77,width:3)
                    if arcIncluded(x:fx,y:fy,cx:160,cy:107,
                                   rx:86,ry:77,start:194,span:110) {
                        p.over(255,158,120,90/255,haze)
                    }
                }
                let (b,g,r,a)=p.bgra()
                let offset=(y*textureWidth+x)*4
                image[offset]=b
                image[offset+1]=g
                image[offset+2]=r
                image[offset+3]=a
            }
        }
        return image
    }

    struct Overlay {
        let textureSlice:Int // -1 source StarTexture glow, 0..2 planet
        let radiusX:Float
        let radiusY:Float
        let rgba:(Float,Float,Float,Float)
    }

    /// DrawSkyPlanet55 draws IntroHalo FIRST and original planet
    /// texture SECOND for EACH individual planet, in style order 0,1,2.
    static func overlays(style:Int,scale:Float,glow:Bool=true)->[Overlay] {
        let p=profile(style)
        var result:[Overlay]=[]
        if glow {
            let radius=max(p.halfWidth,p.halfHeight)*0.54*scale
            result.append(Overlay(
                textureSlice:-1,radiusX:radius,radiusY:radius,
                rgba:(p.glow.0/255,p.glow.1/255,
                      p.glow.2/255,p.glow.3/255)))
        }
        result.append(Overlay(
            textureSlice:style,
            radiusX:p.halfWidth*scale,radiusY:p.halfHeight*scale,
            rgba:(1,1,1,1)))
        return result
    }
}
