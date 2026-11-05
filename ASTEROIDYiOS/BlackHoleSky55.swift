import Foundation

/// Source port of Windows/src/GpuIntro41.cs BuildBlackHoleDisk55,
/// BuildBlackHoleCore55, AnimatedSkyDirection55, DrawSkyBlackHole55.
/// Black hole art is three separately composited 640x640 premultiplied
/// BGRA textures: rear accretion disk, event-horizon core, front disk.
/// The original splits the disk on rotated v and lets the foreground
/// cross the dark core. Never flatten them into a single black circle.
enum BlackHoleSky55 {
    static let imageSize=640
    static let sourceRadius:Float=258
    static let maxScale:Float=3.10
    static let originalSkyDistance:Float=900

    static func clamp(_ v:Float)->Float { max(0,min(1,v)) }
    static func smooth(_ v:Float)->Float {
        let c=clamp(v)
        return c*c*(3-2*c)
    }
    private static func gaussian(_ v:Float)->Float { exp(-v*v) }
    static func bgra(_ red:Float,_ green:Float,_ blue:Float,
                     _ alpha:Float)->(UInt8,UInt8,UInt8,UInt8) {
        // Original Texture(Bitmap) locks Format32bppPArgb even though
        // BuildBlackHole creates a default Bitmap(640,640): convert
        // straight Color.FromArgb to premultiplied BGRA upload bytes.
        let a=max(0,min(255,Int(alpha)))
        if a==0 {return (0,0,0,0)}
        let r=max(0,min(255,Int(red)))
        let g=max(0,min(255,Int(green)))
        let b=max(0,min(255,Int(blue)))
        return (UInt8(b*a/255),UInt8(g*a/255),
                UInt8(r*a/255),UInt8(a))
    }

    /// Actual GpuIntro41.cs BuildBlackHoleDisk55(front).
    static func diskPixel(x:Int,y:Int,front:Bool)
        -> (UInt8,UInt8,UInt8,UInt8) {
        precondition(x>=0 && x<imageSize && y>=0 && y<imageSize)
        let dx=Float(x)-319.5,dy=Float(y)-319.5
        let r=sqrt(dx*dx+dy*dy)
        // Source inclination: 25 degrees.
        let ca:Float=0.9063078,sa:Float=0.4226183
        let u=ca*dx+sa*dy,v = -sa*dx+ca*dy
        let eu=u/214,ev=v/54
        let er=sqrt(eu*eu+ev*ev),ang=atan2(v,u)
        let feather=gaussian(max(0,r-165)/97) *
            (1-smooth((r-284)/37))
        let disk=gaussian((er-1)/0.22)
        let leftFade=smooth((u+270)/110)
        let rightFade=smooth((196-u)/88)
        let stream=exp(-v*v/(2*34*34)) * leftFade * rightFade *
            (0.48+0.52*smooth((-u+130)/350))
        let asym=0.55+0.45*(1-smooth((u+120)/340))
        let swirl=0.5+0.5*sin(ang*2.6+er*10)
        let whiteHot=gaussian((er-0.92)/0.12) *
            smooth((-u+120)/260)
        let blueArc=gaussian((er-1.02)/0.16) *
            smooth((u+70)/250)
        let halo=exp(-(r*r)/(2*114*114))
        let lens=gaussian((r-80)/7)
        let lensLeft=gaussian((r-87)/13) *
            (0.60+0.40*smooth(-dx/135))
        let layerMask=front
            ? smooth((v+9)/18) : (1-smooth((v+9)/18))
        let rearGap=front ? Float(1) : smooth((r-76)/10)
        let alpha=min(Float(1),disk*0.95+stream*0.90+
                      halo*0.075+lens*0.78+lensLeft*0.32) *
            feather*layerMask*rearGap
        if alpha<0.001 {return (0,0,0,0)}
        let red=255*(disk*(0.18+0.64*asym+0.22*swirl)+
                     stream*0.55+whiteHot*0.70+halo*0.045+
                     lens*0.78+lensLeft*0.62)*layerMask*rearGap
        let green=255*(disk*(0.08+0.30*asym+0.10*swirl)+
                       stream*0.20+whiteHot*0.62+
                       blueArc*0.08+halo*0.055+
                       lens*0.72+lensLeft*0.38)*layerMask*rearGap
        let blue=255*(disk*(0.02+0.09*asym)+whiteHot*0.66+
                      blueArc*0.85+halo*0.18+
                      lens*0.69+lensLeft*0.50)*layerMask*rearGap
        return bgra(min(255,red),min(255,green),min(255,blue),
                    min(255,alpha*255))
    }

    /// Actual GpuIntro41.cs BuildBlackHoleCore55(), 640x640.
    static func corePixel(x:Int,y:Int)
        -> (UInt8,UInt8,UInt8,UInt8) {
        precondition(x>=0 && x<imageSize && y>=0 && y<imageSize)
        let dx=Float(x)-319.5,dy=Float(y)-319.5
        let r=sqrt(dx*dx+dy*dy)
        let core=1-smooth((r-69)/4)
        let rim=gaussian((r-80)/6)
        let rimBlue=gaussian((r-86)/10) *
            (0.35+0.65*smooth((dx+10)/120))
        let alpha=max(core,max(rim*0.78,rimBlue*0.32))
        if alpha<0.001 {return (0,0,0,0)}
        let red=255*(rim*0.82+rimBlue*0.20)*(1-core)
        let green=255*(rim*0.76+rimBlue*0.32)*(1-core)
        let blue=255*(rim*0.72+rimBlue*0.88)*(1-core)
        return bgra(min(255,red),min(255,green),min(255,blue),
                    min(255,alpha*255))
    }

    /// slice 0=back, 1=core, 2=front; this ordering is essential.
    static func textureBGRA(slice:Int)->[UInt8] {
        precondition(slice>=0 && slice<3)
        var data=[UInt8](repeating:0,count:imageSize*imageSize*4)
        for y in 0..<imageSize {
            for x in 0..<imageSize {
                let (b,g,r,a)=slice==1
                    ? corePixel(x:x,y:y)
                    : diskPixel(x:x,y:y,front:slice==2)
                let p=(y*imageSize+x)*4
                data[p]=b
                data[p+1]=g
                data[p+2]=r
                data[p+3]=a
            }
        }
        return data
    }

    static func animatedDirection(time:Float)->SphereVector3 {
        // GpuIntro41.AnimatedSkyDirection55(original base,
        // ampX=.005, ampY=.006, speed=.05, phase=2.4).
        let t=time*0.05+2.4
        return SphereVector3(
            x:-0.46+sin(t)*0.005,
            y:-0.70+cos(t*0.83+2.4*0.6)*0.006,
            z:-0.55+sin(t*0.57+2.4*0.3)*0.005*0.4
        ).normalized
    }

    struct Projection {
        let screen:Vec2
        let scale:Float
        let depth:Float
    }
    static func project(camera:SphereCamera67,time:Float)->Projection? {
        let frame=SphereCameraView556(camera:camera)
        let p=animatedDirection(time:time)*originalSkyDistance
        let depth = -SphereVector3.dot(frame.back,p)
        guard depth>0.4 else {return nil}
        let x=640+SphereVector3.dot(frame.right,p)*720/max(0.01,depth)
        let y=360-SphereVector3.dot(frame.up,p)*720/max(0.01,depth)
        guard x > -260 && x < 1540 && y > -180 && y < 920
        else {return nil}
        return Projection(screen:Vec2(x:x,y:y),
                          scale:min(maxScale,originalSkyDistance/depth),
                          depth:depth)
    }

    struct Overlay {
        let isTexture:Bool
        let layer:Int
        let radiusX:Float
        let radiusY:Float
        let angle:Float
        let rgba:(Float,Float,Float,Float)
    }

    /// Painter order directly from DrawSkyBlackHole55:
    /// 3 optional StarTexture halos, 4 animated StarTexture rays,
    /// then back/core/front disk. Each ray is a rotated rectangle
    /// centred at the hole and uses source Color.FromArgb.
    static func overlays(time:Float,scale:Float,glow:Bool=true)
        -> [Overlay] {
        var out:[Overlay]=[]
        func tint(_ a:Float,_ r:Float,_ g:Float,_ b:Float)
            ->(Float,Float,Float,Float) {
            (r/255,g/255,b/255,a/255)
        }
        func halo(_ radius:Float,_ a:Float,_ r:Float,
                  _ g:Float,_ b:Float) {
            out.append(Overlay(isTexture:false,layer:3,
                radiusX:radius*scale,radiusY:radius*scale,
                angle:0,rgba:tint(a,r,g,b)))
        }
        if glow {
            halo(sourceRadius*2.0,42,120,186,255)
            halo(sourceRadius*1.54,62,255,164,84)
            halo(sourceRadius*1.10,28,255,242,225)
        }
        let pulse=0.92+0.08*sin(time*1.10)
        let spin=time*0.22
        func ray(_ angle:Float,_ length:Float,_ width:Float,
                 _ a:Float,_ r:Float,_ g:Float,_ b:Float) {
            // DrawRay55: distance from center along angle is length;
            // thickness is width in total, thus half width for mesh.
            out.append(Overlay(isTexture:false,layer:3,
                radiusX:length,radiusY:width*0.5,angle:angle,
                rgba:tint(a,r,g,b)))
        }
        ray(spin,sourceRadius*2.10*scale*pulse,
            sourceRadius*0.20*scale,44,255,184,98)
        ray(spin+1.5708,sourceRadius*1.74*scale*
            (0.95+0.05*cos(time*0.8)),
            sourceRadius*0.14*scale,30,110,176,255)
        ray(spin+0.66,sourceRadius*1.48*scale,
            sourceRadius*0.08*scale,22,255,238,180)
        ray(spin+2.20,sourceRadius*1.34*scale,
            sourceRadius*0.07*scale,20,170,214,255)
        for layer in 0..<3 {
            out.append(Overlay(isTexture:true,layer:layer,
                radiusX:sourceRadius*scale,
                radiusY:sourceRadius*scale,angle:0,
                rgba:(1,1,1,1)))
        }
        return out
    }
}
