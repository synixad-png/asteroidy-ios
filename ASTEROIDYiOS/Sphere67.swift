import Foundation

// Adaptation of Windows/src/SphereCombat67.cs (ASTEROIDY v556).
// Coordinate units: original world W=1280, H=720, sphere radius=H/pi.
// No UIKit/Metal dependencies; can be regression-tested on Linux.
struct SphereVector3: Equatable {
    var x: Float; var y: Float; var z: Float
    static func +(a: Self, b: Self) -> Self { .init(x:a.x+b.x,y:a.y+b.y,z:a.z+b.z) }
    static func -(a: Self, b: Self) -> Self { .init(x:a.x-b.x,y:a.y-b.y,z:a.z-b.z) }
    static func *(a: Self, b: Float) -> Self { .init(x:a.x*b,y:a.y*b,z:a.z*b) }
    static func /(a: Self, b: Float) -> Self { a * (1/b) }
    static func dot(_ a: Self, _ b: Self) -> Float { a.x*b.x+a.y*b.y+a.z*b.z }
    static func cross(_ a: Self, _ b: Self) -> Self { .init(x:a.y*b.z-a.z*b.y,y:a.z*b.x-a.x*b.z,z:a.x*b.y-a.y*b.x) }
    var length: Float { sqrt(Self.dot(self,self)) }
    var normalized: Self { let n=length; return n > 1e-12 ? self/n : .init(x:0,y:0,z:0) }
}

// Surface coordinates are the same 1280x720 coordinates as the C# game.
enum Sphere67 {
    static let width: Float = 1280
    static let height: Float = 720
    static let radius: Float = height / .pi
    private static func mod(_ x: Float, _ n: Float) -> Float { (x.truncatingRemainder(dividingBy:n)+n).truncatingRemainder(dividingBy:n) }

    static func canonical(_ p: Vec2) -> Vec2 {
        // Pole reflection translates longitude by half a revolution.
        var y=mod(p.y,2*height), x=p.x
        if y > height { y=2*height-y; x += width/2 }
        return Vec2(x:mod(x,width),y:y)
    }
    static func normal(_ point: Vec2) -> SphereVector3 {
        let p=canonical(point)
        let lon=p.x*2*Float.pi/width, lat=Float.pi/2-p.y*Float.pi/height, c=cos(lat)
        return .init(x:c*cos(lon),y:sin(lat),z:c*sin(lon))
    }
    static func coordinates(_ input: SphereVector3) -> Vec2 {
        let n=input.normalized
        let longitude=atan2(n.z,n.x)
        let latitude=atan2(n.y,sqrt(n.x*n.x+n.z*n.z))
        return canonical(Vec2(x:longitude*width/(2*Float.pi),y:(Float.pi/2-latitude)*radius))
    }
    static func basis(_ point: Vec2) -> (east: SphereVector3, south: SphereVector3) {
        let p=canonical(point); let lon=p.x*2*Float.pi/width
        let east=SphereVector3(x:-sin(lon),y:0,z:cos(lon))
        return (east,SphereVector3.cross(normal(p),east).normalized)
    }
    static func vector(_ point: Vec2, _ components: Vec2) -> SphereVector3 {
        let b=basis(point)
        return b.east*components.x+b.south*components.y
    }
    static func components(_ point: Vec2, _ v: SphereVector3) -> Vec2 {
        let b=basis(point)
        return Vec2(x:SphereVector3.dot(v,b.east),y:SphereVector3.dot(v,b.south))
    }
    // Rodrigues rotation takes a tangent vector from one normal to another.
    static func transport(_ v: SphereVector3, from: SphereVector3, to: SphereVector3) -> SphereVector3 {
        let axis=SphereVector3.cross(from,to), length=axis.length
        if length < 1e-6 { return v-to*SphereVector3.dot(v,to) }
        let unit=axis/length, theta=atan2(length,SphereVector3.dot(from,to))
        return v*cos(theta)+SphereVector3.cross(unit,v)*sin(theta)+unit*(SphereVector3.dot(unit,v)*(1-cos(theta)))
    }
    static func offset(_ origin: Vec2, by displacement: Vec2) -> Vec2 {
        let length=sqrt(displacement.lengthSquared)
        if length < 1e-6 { return canonical(origin) }
        let n=normal(origin),t=vector(origin,displacement)/length,angle=length/radius
        return coordinates(n*cos(angle)+t*sin(angle))
    }
    // Log map: shortest arc and direction measured in the origin's tangent plane.
    static func delta(target: Vec2, origin: Vec2) -> Vec2 {
        let a=normal(target),b=normal(origin),dot=max(-1,min(1,SphereVector3.dot(a,b)))
        let tangent=a-b*dot, len=tangent.length
        if len < 1e-6 { return dot>0 ? Vec2(x:0,y:0) : Vec2(x:Float.pi*radius,y:0) }
        let distance=atan2(len,dot)*radius
        return components(origin,tangent*(distance/len))
    }
    static func advance(_ point: Vec2, velocity: inout Vec2, dt: Float) -> Vec2 {
        let destination=offset(point,by:velocity*dt)
        let speed=sqrt(velocity.lengthSquared)
        if speed > 1e-6 {
            let moved=transport(vector(point,velocity),from:normal(point),to:normal(destination))
            velocity=components(destination,moved)
            let newSpeed=sqrt(velocity.lengthSquared)
            if newSpeed > 1e-6 { velocity=velocity*(speed/newSpeed) }
        }
        return destination
    }
}

struct SphereCamera67 {
    var focus: SphereVector3
    var right: SphereVector3
    var up: SphereVector3
    init(at point: Vec2) {
        let basis=Sphere67.basis(point)
        focus=Sphere67.normal(point)
        right=basis.east
        up=SphereVector3.cross(focus,right).normalized
    }
    mutating func update(target: Vec2, dt: Float) {
        let desired=Sphere67.normal(target)
        let alpha=1-exp(-max(0,dt)*9)
        let previous=focus
        let blended=previous*(1-alpha)+desired*alpha
        focus=blended.length > 0.00001 ? blended.normalized : desired
        right=Sphere67.transport(right,from:previous,to:focus).normalized
        up=SphereVector3.cross(focus,right).normalized
    }
    func screenVector(at point: Vec2, screen: Vec2) -> Vec2 {
        let local=Sphere67.normal(point)
        let r=Sphere67.transport(right,from:focus,to:local)
        let down=Sphere67.transport(up * -1,from:focus,to:local)
        return Sphere67.components(point,r*screen.x+down*screen.y)
    }
}

/// Exact perspective slope from Windows/src/GpuIntro41.cs:455:
/// frustum(-.35555556,.35555556,-.2,.2,.4,1600).
/// In GpuSphere67.cs:420 the same IntroProjection() is used for planet mode.
/// For a normalized iOS aspect ratio, retain vertical 2*atan(.2/.4)
/// and use current drawable aspect for the horizontal frustum.
enum SphereProjection556 {
    static let sourceHalfHeight: Float = 0.2
    static let sourceNear: Float = 0.4
    static let sourceFar: Float = 1600
    static let sourceVerticalFocal: Float = sourceNear/sourceHalfHeight
    static let sourceVerticalFOV: Float = 2*atan(sourceHalfHeight/sourceNear)

    // Windows/src/GpuIntro41.cs:455 actually uses .4/1600 as its
    // near/far planes. The Boreas mesh and orbit eye in Metal are
    // scaled by HomeWorldOuterRadius523 = 100*1.4419674, so its
    // frustum MUST receive the very same normalization. Previously
    // Metal used its flat-arena .1/20 planes for both modes.
    static let normalizedNear: Float =
        sourceNear / SphereCameraView556.originalPlanetOuterRadius
    static let normalizedFar: Float =
        sourceFar / SphereCameraView556.originalPlanetOuterRadius

    static func clipPlanes(spherical: Bool) -> (near: Float, far: Float) {
        spherical ? (normalizedNear, normalizedFar) : (0.1, 20)
    }

    static func horizontalFocal(aspect:Float) -> Float {
        sourceVerticalFocal / max(aspect,0.1)
    }
}

/// Source-verified camera frame for the existing spherical diagnostic.
/// Windows/src/SphereCombat67.cs:62 updates SphereFocus67 / Right67 / Up67.
/// Windows/src/GpuSphere67.cs:414 puts the view eye 310 original world units
/// away from the center and looks back to the origin with SphereUp67.
/// Windows/src/GpuPlanetGltf463.cs defines the original planet outer radius
/// as 100 * 1.4419674. Our Metal Boreas is normalized to a unit outer radius.
///
/// This is a CAMERA transform only. It never mutates flight, collision,
/// missions, asteroid positions, or the independent flat-space camera.
struct SphereCameraView556 {
    static let originalPlanetOuterRadius: Float = 100 * 1.4419674
    static let originalCameraRadius: Float = 310
    static let normalizedEyeDistance: Float =
        originalCameraRadius / originalPlanetOuterRadius

    let eye: SphereVector3
    let right: SphereVector3
    let up: SphereVector3
    let back: SphereVector3

    init(camera: SphereCamera67) {
        back = camera.focus.normalized
        right = camera.right.normalized
        up = SphereVector3.cross(back, right).normalized
        eye = back * Self.normalizedEyeDistance
    }

    /// EXACT column-major layout of Windows/src/Orbit50.cs:32
    /// OrbitWorld50.View(eye, origin, up). This is the shared matrix
    /// consumed by MetalRenderer, NOT a second, untested camera formula.
    /// Tested byte-column layout and projection on Linux.
    var viewColumnMajor: [Float] {
        [
            right.x, up.x, back.x, 0,
            right.y, up.y, back.y, 0,
            right.z, up.z, back.z, 0,
            -SphereVector3.dot(right,eye),
            -SphereVector3.dot(up,eye),
            -SphereVector3.dot(back,eye), 1
        ]
    }

    /// Apply EXACTLY the same matrix consumed by the Metal scene.
    /// This catches mistaken transposition and incorrect signs.
    func cameraSpace(_ world: SphereVector3) -> SphereVector3 {
        let m=viewColumnMajor
        return SphereVector3(
            x:m[0]*world.x+m[4]*world.y+m[8]*world.z+m[12],
            y:m[1]*world.x+m[5]*world.y+m[9]*world.z+m[13],
            z:m[2]*world.x+m[6]*world.y+m[10]*world.z+m[14])
    }
}

/// Original Windows/src/GpuAmbient37.cs:6–7 SpaceHash207/SpaceRand207
/// and GpuIntro41.cs:452 deterministic deep-space star distribution.
/// The C# source draws these 1,500 stars as screen-space halos. The Metal
/// diagnostic currently renders the SAME directions/tints as tiny 3D
/// camera-relative triangles; full textured halos are NOT ported yet.
struct SphereSkyStar207 {
    let direction: SphereVector3
    let pixelSize: Float
    let red: Float
    let green: Float
    let blue: Float
    let alpha: Float
}

enum SphereSky207 {
    static let count = 1500
    static let originalSkyRadius: Float = 900
    static let originalScreenHeight: Float = 720
    /// Direct Windows/src/GpuAmbient37.cs:5 StarTexture(), NOT a made-up
    /// radial shader. Format32bppPArgb stores all BGRA bytes as the same
    /// pre-multiplied white alpha. Original GL Texture() samples linearly.
    static let haloTextureSize = 64
    static func haloAlpha(x:Int,y:Int) -> UInt8 {
        precondition((0..<haloTextureSize).contains(x) &&
                     (0..<haloTextureSize).contains(y))
        let dx=(Double(x)-31.5)/31.5
        let dy=(Double(y)-31.5)/31.5
        let radius=sqrt(dx*dx+dy*dy)
        let edge=max(0,1-radius)
        let value=exp(-radius*radius*4)*edge*edge*255
        return UInt8(max(0,min(255,Int(value))))
    }
    static func haloTexelsBGRA() -> [UInt8] {
        let dim=haloTextureSize
        var texels=[UInt8](repeating:0,count:dim*dim*4)
        for y in 0..<dim {
            for x in 0..<dim {
                let a=haloAlpha(x:x,y:y)
                let i=(y*dim+x)*4
                texels[i]=a
                texels[i+1]=a
                texels[i+2]=a
                texels[i+3]=a
            }
        }
        return texels
    }

    /// GpuIntro41.cs:452 IntroHalo(p,size*2,tint,halo) constructs
    /// a quad spanning [-radius,+radius], so pixel DIAMETER = size*4.
    /// For GlowEnabled (default true in Windows/Renderer.cs:25), bright
    /// stars also draw a preceding 10px/21px-radius halo with alpha 125.
    static func baseDiameterPixels(_ star:SphereSkyStar207) -> Float {
        star.pixelSize*4
    }
    static func hasBrightHalo(_ star:SphereSkyStar207) -> Bool {
        star.pixelSize>0.7
    }
    static func brightHaloDiameterPixels(_ star:SphereSkyStar207) -> Float {
        star.pixelSize==2.8 ? 42 : 20
    }
    /// Original SkyProject55 uses a 720-pixel reference image. iOS
    /// Metal point sizes are drawable PIXELS, not the C# virtual pixels.
    /// Scale source sizes by the drawable height so a 2.8px star retains
    /// its angular size on Retina resolutions. A real pixel cannot be
    /// smaller than 1px, which the Metal vertex shader clamps.
    static func drawableScale(height: Float) -> Float {
        guard height.isFinite && height > 0 else { return 1 }
        return height/originalScreenHeight
    }
    static var normalizedSkyRadius: Float {
        originalSkyRadius / SphereCameraView556.originalPlanetOuterRadius
    }

    static func spaceHash207(_ x: UInt32) -> UInt32 {
        var v=x
        v ^= v >> 16
        v = v &* 0x7feb352d
        v ^= v >> 15
        v = v &* 0x846ca68b
        v ^= v >> 16
        return v
    }
    static func spaceRand207(_ a: UInt32,_ b: UInt32,_ c: UInt32) -> Float {
        let x=spaceHash207((a &* 73856093) ^
                           (b &* 19349663) ^
                           (c &* 83492791))
        return Float(x & 0x00ffffff) / 16777215
    }
    static func star(_ i: Int) -> SphereSkyStar207 {
        precondition(i>=0 && i<count,"Source sky star index out of range")
        let index=UInt32(i)
        let longitude=spaceRand207(41,index,17)*6.2831853
        let y=spaceRand207(41,index,31)*2-1
        let latitudeRadius=sqrt(max(0,1-y*y))
        let brightness=spaceRand207(41,index,53)
        let warm=spaceRand207(41,index,71)>0.9
        return SphereSkyStar207(
            direction:SphereVector3(x:cos(longitude)*latitudeRadius,
                                    y:y,
                                    z:sin(longitude)*latitudeRadius),
            pixelSize:brightness>0.98 ? 2.8 :
                      (brightness>0.87 ? 1.4 : 0.7),
            red: warm ? 249/255 : 186/255,
            green:warm ? 205/255 : 214/255,
            blue: warm ? 161/255 : 244/255,
            alpha:warm ? 235/255 : 220/255)
    }
}

/// One original vertex of Windows/src/GpuCosmos39.cs RayVertex or
/// GpuIntro41.cs IntroHalo. Coordinates are RELATIVE to the projected sun
/// in source 1280x720 image pixels (Y positive downward); rgba is
/// original unpremultiplied Color converted to Float, texture UVs as GL.
struct SphereSolarVertex556 {
    let offset: Vec2
    let rgba: (Float,Float,Float,Float)
    let uv: Vec2
    let textured: Bool
}

/// GPU-independent source reconstruction of Windows GpuIntro41.cs:454
/// and GpuCosmos39.cs:8–10, at the original fixed 1280x720 resolution.
/// Source RaysEnabled/GlowEnabled default TRUE (Renderer.cs:240/25).
/// WIP diagnostic uses those original defaults; user settings remain task14.
enum SphereSolarOverlay556 {
    static let rayCount = 5
    static let columns = 6
    static let rows = 4
    static let haloVertexCount = 3*6
    static let rayVertexCount = rayCount*rows*columns*6
    static let totalVertices = haloVertexCount+rayVertexCount
    static let rayDistances:[Float] = [0,0.12,0.35,0.72,1]
    static let rayStrengths:[Float] = [0,1,0.72,0.31,0]
    static let sunDirection = SphereVector3(x:0.6,y:0.8,z:0.32).normalized
    static let sourceDistance:Float = 900
    static let focal:Float = 720

    /// Original SkyProject55: uses ORIENTATION only, not camera eye
    /// translation. Reject rays behind eye and outside source visibility
    /// rectangle [-400,1680]×[-400,1120] in 1280×720 image space.
    static func project(camera:SphereCamera67) -> Vec2? {
        let frame=SphereCameraView556(camera:camera)
        let point=sunDirection*sourceDistance
        let px=SphereVector3.dot(frame.right,point)
        let py=SphereVector3.dot(frame.up,point)
        let depth = -SphereVector3.dot(frame.back,point)
        guard depth>0.4 else {return nil}
        let x:Float=640+px*focal/max(0.01,depth)
        let y:Float=360-py*focal/max(0.01,depth)
        guard x > -400 && x < 1680 && y > -400 && y < 1120
        else {return nil}
        return Vec2(x:x,y:y)
    }

    static func vertex(_ x:Float,_ y:Float,
                       _ red:Float,_ green:Float,_ blue:Float,
                       _ alpha:Float,
                       _ u:Float=0,_ v:Float=0,
                       textured:Bool=false) -> SphereSolarVertex556 {
        .init(offset:Vec2(x:x,y:y),rgba:(red/255,green/255,blue/255,alpha/255),
              uv:Vec2(x:u,y:v),textured:textured)
    }

    /// GpuIntro41.IntroHalo => Gpu2DRenderer.Quad2D UV winding.
    private static func appendHalo(_ target:inout [SphereSolarVertex556],
                                   radius:Float,red:Float,green:Float,
                                   blue:Float,alpha:Float) {
        let tl=vertex(-radius,-radius,red,green,blue,alpha,0,0,textured:true)
        let tr=vertex(radius,-radius,red,green,blue,alpha,1,0,textured:true)
        let br=vertex(radius,radius,red,green,blue,alpha,1,1,textured:true)
        let bl=vertex(-radius,radius,red,green,blue,alpha,0,1,textured:true)
        target.append(contentsOf:[tl,tr,br,tl,br,bl])
    }

    /// GpuCosmos39.cs:9 exactly. Per-vertex alpha is TRUNCATED to
    /// integer Color.FromArgb, not Float interpolated by the shader.
    static func rayVertex(angle:Float,row:Int,column:Int) -> SphereSolarVertex556 {
        precondition((0...rows).contains(row) &&
                     (0...columns).contains(column))
        let distance=rayDistances[row]*750
        let side=Float(column)/3-1
        let spread=(3+rayDistances[row]*30)*side
        let fade=pow(cos(side*Float.pi/2),2)
        let x=cos(angle)*distance-sin(angle)*spread
        let y=sin(angle)*distance+cos(angle)*spread
        let a=Float(Int(18*rayStrengths[row]*fade))
        return vertex(x,y,255,202,139,a)
    }

    static func vertices() -> [SphereSolarVertex556] {
        var out:[SphereSolarVertex556]=[]
        out.reserveCapacity(totalVertices)
        // GpuIntro41.cs:454: 2 glow layers, always-visible core, then
        // 5 SoftRay calls. Keep original painter order in one draw.
        appendHalo(&out,radius:130,red:255,green:199,blue:127,alpha:170)
        appendHalo(&out,radius:55,red:255,green:217,blue:164,alpha:220)
        appendHalo(&out,radius:15,red:255,green:245,blue:207,alpha:255)
        for i in 0..<rayCount {
            let angle:Float=2.5+(Float(i)-2)*0.17
            for row in 0..<rows {
                for col in 0..<columns {
                    // EXACT original two triangles per 4×6 cell.
                    out.append(rayVertex(angle:angle,row:row,column:col))
                    out.append(rayVertex(angle:angle,row:row+1,column:col))
                    out.append(rayVertex(angle:angle,row:row+1,column:col+1))
                    out.append(rayVertex(angle:angle,row:row,column:col))
                    out.append(rayVertex(angle:angle,row:row+1,column:col+1))
                    out.append(rayVertex(angle:angle,row:row,column:col+1))
                }
            }
        }
        precondition(out.count==totalVertices)
        return out
    }
}

/// Original Windows/src/GpuCosmos39.cs:4–7 NebulaTexture and CloudLayer
/// and GpuIntro41.cs:122,451 cloud placement. NOT an invented sky shader.
/// The orbit path uses ONLY themes 0 and 1, shared by 24 far and 12 near
/// quads. Theme generation is independent of UIKit/Metal and is cached
/// as a real two-slice 256x256 PArgb cloud texture in MetalRenderer.
enum SphereNebula556 {
    static let imageSize = 256
    static let orbitLayerCount = 36
    static let orbitThemeCount = 2
    static let palette:[(Float,Float,Float)]=[
        (167,67,212),(36,139,199),(209,68,108),
        (90,87,212),(35,162,144),(188,118,44)
    ]

    static func hash(_ x:Int,_ y:Int,_ seed:Int)->Float {
        // C# unchecked int arithmetic in GpuCosmos39.CloudHash.
        let n0=UInt32(truncatingIfNeeded:x) &* 374761393
        let n1=UInt32(truncatingIfNeeded:y) &* 668265263
        let n2=UInt32(truncatingIfNeeded:seed) &* 144269
        var n=n0 &+ n1 &+ n2
        n=(n ^ (n >> 13)) &* 1274126177
        n ^= n >> 16
        return Float(n & 65535)/65535
    }
    static func noise(_ x:Float,_ y:Float,_ seed:Int)->Float {
        let ix=Int(floor(x)),iy=Int(floor(y))
        var fx=x-Float(ix),fy=y-Float(iy)
        fx=fx*fx*(3-2*fx)
        fy=fy*fy*(3-2*fy)
        let a=hash(ix,iy,seed),b=hash(ix+1,iy,seed)
        let c=hash(ix,iy+1,seed),d=hash(ix+1,iy+1,seed)
        return (a+(b-a)*fx)*(1-fy)+(c+(d-c)*fx)*fy
    }

    /// Exact GpuCosmos39.NebulaTexture. Generate only on initial load.
    /// BGRA output is premultiplied, same as Format32bppPArgb.
    static func pixel(x:Int,y:Int,theme:Int) -> (UInt8,UInt8,UInt8,UInt8) {
        precondition(x>=0 && x<imageSize && y>=0 && y<imageSize)
        precondition(theme>=0 && theme<palette.count)
        let nx=Float(x)/Float(imageSize-1)
        let ny=Float(y)/Float(imageSize-1)
        let warp=noise(nx*3,ny*3,theme+5)*2-1
        var value:Float=0,weight:Float=0.57,frequency:Float=3
        for octave in 0..<5 {
            value += noise(nx*frequency+warp*0.8,
                           ny*frequency-warp*0.5,
                           theme*19+octave)*weight
            frequency *= 2.05
            weight *= 0.48
        }
        // Source uses Math.Sin/Math.Pow/Math.Exp (Double).
        let edgeProduct=sin(Double(nx)*Double.pi)*sin(Double(ny)*Double.pi)
        let edge=pow(max(0,edgeProduct),0.75)
        let ribbonAxis=Double(ny)-0.48-Double(sin(nx*5+Float(theme)))*0.16-Double(warp)*0.13
        let ribbon=exp(-pow(ribbonAxis*3.1,2))
        let cloud=Double(max(0,value-0.34))*3.5
        let alpha=max(0,min(190,Int(edge*ribbon*cloud*220)))
        let hot=max(0,value-0.58)*2
        let rgb=palette[theme]
        let red=max(0,min(255,Int(rgb.0+hot*95)))
        let green=max(0,min(255,Int(rgb.1+hot*110)))
        let blue=max(0,min(255,Int(rgb.2+hot*85)))
        return (UInt8(blue*alpha/255),UInt8(green*alpha/255),
                UInt8(red*alpha/255),UInt8(alpha))
    }
    static func textureBGRA(theme:Int)->[UInt8] {
        precondition(theme>=0 && theme<orbitThemeCount)
        var bytes=[UInt8](repeating:0,count:imageSize*imageSize*4)
        for y in 0..<imageSize {
            for x in 0..<imageSize {
                let (b,g,r,a)=pixel(x:x,y:y,theme:theme)
                let at=(y*imageSize+x)*4
                bytes[at]=b
                bytes[at+1]=g
                bytes[at+2]=r
                bytes[at+3]=a
            }
        }
        return bytes
    }

    struct Layer {
        let direction:SphereVector3
        let theme:Int
        let alpha:Float
        let near:Bool
        func projected(camera:SphereCamera67)->(
            center:Vec2,size:Float,width:Float,height:Float)? {
            let f=SphereCameraView556(camera:camera)
            let depth = -SphereVector3.dot(f.back,direction)
            guard depth>0.4 else {return nil}
            let x:Float=640+SphereVector3.dot(f.right,direction)*720/max(0.01,depth)
            let y:Float=360-SphereVector3.dot(f.up,direction)*720/max(0.01,depth)
            if near {
                guard x > -900 && x < 2180 &&
                      y > -600 && y < 1320 else {return nil}
                let size=720*220/depth
                return (Vec2(x:x,y:y),size,size*2,size*1.1)
            }
            guard x > -500 && x < 1780 &&
                  y > -400 && y < 1120 else {return nil}
            let size=min(650,720*190/depth)
            return (Vec2(x:x,y:y),size,size*2,size*0.48)
        }
    }
    static func layer(_ index:Int)->Layer {
        precondition(index>=0 && index<orbitLayerCount)
        if index<24 {
            let a=Float(index)*Float.pi/12
            // DrawDeepSpace55 first pass: angular ring, y*.38.
            let d=SphereVector3(x:cos(a),y:sin(a)*0.38,
                                z:sin(a)).normalized*900
            return Layer(direction:d,theme:index%2,
                         alpha:37/255,near:false)
        }
        let i=index-24
        let a=Float(i)*Float.pi/6
        // IntroSky second pass: 12 near clouds, sin(i*2.3)*90.
        let d=SphereVector3(x:cos(a)*380,
                            y:sin(Float(i)*2.3)*90,
                            z:sin(a)*380)
        return Layer(direction:d,theme:i%2,
                     alpha:140/255,near:true)
    }
}

/// Exact surface-local basis of Windows/src/GpuSphere67.cs:63
/// StampSphere67(point,angle,scale,lift). Ported in dimensionless
/// Metal units using the ORIGINAL terrain outer radius 100*1.4419674
/// from GpuPlanetGltf463.cs and Shell67 = outer+15.
/// Local X=right, local Y=forward, local Z=surface normal. The static
/// Vanguard556 exporter explicitly maps the source GLB into this XY plane.
struct SphereSurfaceStamp556 {
    static let sourceShellRadius: Float =
        SphereCameraView556.originalPlanetOuterRadius + 15
    static let normalizedShellRadius: Float =
        sourceShellRadius / SphereCameraView556.originalPlanetOuterRadius
    static let normalizedScalePerArcUnit: Float =
        normalizedShellRadius / Sphere67.radius
    static let sourceShipContactRadius: Float = 10 * 1.12
    static let sourceCraftRadius: Float =
        sourceShipContactRadius * 0.65

    let right: SphereVector3
    let forward: SphereVector3
    let normal: SphereVector3
    let position: SphereVector3

    init(point: Vec2, angle: Float, lift: Float = 0) {
        normal = Sphere67.normal(point)
        // Original Game.Direction(angle) -> Sphere67.Vector().
        forward = Sphere67.vector(
            point,Vec2(x:cos(angle),y:sin(angle))).normalized
        right = SphereVector3.cross(forward,normal).normalized
        position = normal * (Self.normalizedShellRadius +
                            lift*Self.normalizedScalePerArcUnit)
    }

    /// Matrix identical in axis order to original StampSphere67, after
    /// division by outer terrain radius. "size" is a source world
    /// radius or unit size, never an arbitrary visual percentage.
    func columnMajor(size: Float) -> [Float] {
        let s = size*Self.normalizedScalePerArcUnit
        return [
            right.x*s,right.y*s,right.z*s,0,
            forward.x*s,forward.y*s,forward.z*s,0,
            normal.x*s,normal.y*s,normal.z*s,0,
            position.x,position.y,position.z,1
        ]
    }
}

// Independent v556 spherical flight testbed. Do not replace GameCore until
// platform render projection and v556 combat units have been calibrated.
struct SphereFlight67 {
    var position=Vec2(x:640,y:360)
    var velocity=Vec2(x:0,y:0)
    var heading: Float=0
    var flight=FlightDynamics556()
    var camera=SphereCamera67(at:Vec2(x:640,y:360))
    mutating func tick(move: Vec2, aim: Vec2, dt: Float,
                       boostMultiplier:Float?=nil) {
        guard dt > 0 else { return }
        let inputLength=min(1,sqrt(move.lengthSquared))
        let localMove=camera.screenVector(at:position,screen:move)
        let desired=localMove * (inputLength > 0 ? flight.configuration.cruiseSpeed/max(1e-6,sqrt(localMove.lengthSquared)) : 0)
        let acceleration=flight.motion(velocity:&velocity,desired:desired,inputLength:inputLength,dt:dt)
        // Original Boost71 is a real movement override (not HUD motion).
        // With nil, the frozen v556 flight path above is byte-for-byte
        // identical in arithmetic and behavior to the previous release.
        if let multiplier=boostMultiplier,multiplier>0 {
            let forward=Vec2(x:cos(heading),y:sin(heading))
            velocity=forward*(flight.configuration.cruiseSpeed*multiplier)
        }
        let old=position
        let oldHeading=Vec2(x:cos(heading),y:sin(heading))
        let headingWorld=Sphere67.vector(old,oldHeading)
        position=Sphere67.advance(position,velocity:&velocity,dt:dt)
        let movedHeading=Sphere67.components(position,Sphere67.transport(headingWorld,from:Sphere67.normal(old),to:Sphere67.normal(position)))
        heading=atan2(movedHeading.y,movedHeading.x)
        camera.update(target:position,dt:dt)
        let direction=aim.lengthSquared > 0.0225 ? camera.screenVector(at:position,screen:aim) : inputLength > 0.01 ? camera.screenVector(at:position,screen:move) : Vec2(x:cos(heading),y:sin(heading))
        if direction.lengthSquared > 0.0001 { heading=atan2(direction.y,direction.x) }
        flight.attitude(angle:heading,velocity:velocity,acceleration:acceleration,dt:dt)
    }
}
