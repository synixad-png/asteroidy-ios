import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// PC v602: Windows/src/NewHome290.cs + Orbit50.cs + OrbitWorld51.cs.
///
/// Strictly the actual imported H290 height map, not the C279 mission planet,
/// the W3 preview globe or the 100 m procedural legacy planet. Source geometry
/// and the rendered textures are staged by Tools/stage_pc602_newhome290.py.
/// This pure data model does NOT pretend that the HomeFlight291 game loop is
/// already installed; flight and gameplay must bind to it separately.
struct PC602NewHome290 {
    enum SourceError: Error {
        case missing, invalidLength, invalidSHA256, nonfinite, invalidDirection
    }
    static let width=512
    static let height=256
    static let bytes=width*height*MemoryLayout<Float>.size
    static let heightSHA256 =
        "12d56a99634e4fc28ded9e03bcac34de05020750cc18e86d1086db8542b2d18d"
    static let originalTriangles=172208
    static let wreckScale295:Float=0.504*1.20
    static let dockRadius295:Float=36*1.20
    static let wreckDebrisCount295=146
    static let wreckTrailLength295:Float=178

    private let heights:[Float]

    init(heightMapBytes raw:Data) throws {
        guard raw.count==Self.bytes else {throw SourceError.invalidLength}
        #if canImport(CryptoKit)
        let actual=SHA256.hash(data:raw).map {
            String(format:"%02x",$0)
        }.joined()
        guard actual==Self.heightSHA256 else {throw SourceError.invalidSHA256}
        #endif
        var decoded=[Float]()
        decoded.reserveCapacity(Self.width*Self.height)
        for i in 0..<(Self.width*Self.height) {
            let bits=raw.withUnsafeBytes {
                $0.loadUnaligned(fromByteOffset:i*4,as:UInt32.self)
            }
            let value=Float(bitPattern:UInt32(littleEndian:bits))
            guard value.isFinite else {throw SourceError.nonfinite}
            decoded.append(value)
        }
        heights=decoded
    }

    static func load(bundle:Bundle = .main) throws -> Self {
        guard let location=bundle.url(
            forResource:"PC602Home290HeightMap",withExtension:"bin")
             ?? bundle.url(forResource:"PC602Home290HeightMap",
                           withExtension:"bin",subdirectory:"Assets")
        else {throw SourceError.missing}
        return try Self(heightMapBytes:Data(contentsOf:location))
    }

    private static func normalized(_ p:SIMD3<Float>) -> SIMD3<Float>? {
        guard p.x.isFinite && p.y.isFinite && p.z.isFinite else{return nil}
        let norm=sqrt(p.x*p.x+p.y*p.y+p.z*p.z)
        guard norm.isFinite && norm>1e-7 else{return nil}
        return p/norm
    }
    private static func dot(_ a:SIMD3<Float>,_ b:SIMD3<Float>)->Float {
        a.x*b.x+a.y*b.y+a.z*b.z
    }
    private static func cross(_ a:SIMD3<Float>,_ b:SIMD3<Float>)->SIMD3<Float> {
        SIMD3(a.y*b.z-a.z*b.y,
              a.z*b.x-a.x*b.z,
              a.x*b.y-a.y*b.x)
    }

    /// NewHome290.HeightAt: source longitude/latitude projection, longitude
    /// repeat, latitude clamp, exact bilinear interpolation, 100x terrain.
    func surface(_ direction:SIMD3<Float>) -> Float? {
        guard let n=Self.normalized(direction) else{return nil}
        let longitude=atan2(n.z,n.x)
        let latitude=asin(min(1,max(-1,n.y)))
        let u=(longitude+Float.pi)/(2*Float.pi)*Float(Self.width)-0.5
        let v=(latitude+Float.pi*0.5)/Float.pi*Float(Self.height)-0.5
        let xx=Int(floor(u)),yy=Int(floor(v))
        let tx=u-Float(xx),ty=v-Float(yy)
        let x0=((xx % Self.width)+Self.width) % Self.width
        let x1=(x0+1) % Self.width
        let y0=min(Self.height-1,max(0,yy))
        let y1=min(Self.height-1,max(0,yy+1))
        let a=heights[y0*Self.width+x0]
        let b=heights[y0*Self.width+x1]
        let c=heights[y1*Self.width+x0]
        let d=heights[y1*Self.width+x1]
        return 100*((a+(b-a)*tx)*(1-ty)+(c+(d-c)*tx)*ty)
    }

    /// NewHome290.SpawnPosition: clearance is 12 m, minimum radius 150 m.
    func spawnPosition(_ direction:SIMD3<Float>)->SIMD3<Float>? {
        guard let n=Self.normalized(direction),let h=surface(n)
        else {return nil}
        return n*max(150,h+12)
    }

    /// NewHome290.SafePosition: original 8 m radial ground clearance.
    func safePosition(_ p:SIMD3<Float>)->SIMD3<Float>? {
        guard let n=Self.normalized(p),let h=surface(n)
        else {return nil}
        let length=sqrt(Self.dot(p,p))
        return length<h+8 ? n*(h+8) : p
    }

    /// Original OrbitWorld50.Beacon: 24 authored latitudinal markers and
    /// two polar final levels. Not a procedural replacement for the atlas.
    func beacon(_ level:Int)->SIMD3<Float>? {
        guard (1...26).contains(level) else{return nil}
        let n:SIMD3<Float>
        if level==26 {
            n=SIMD3<Float>(-0.48,0.87,-0.20)
        } else if level==25 {
            n=SIMD3<Float>(0.38,0.90,0.22)
        } else {
            let index=level-1, row=index/8
            let y:Float=row==0 ? 0 : row==1 ? 2/3 : -2/3
            let angle=(Float(index%8)+0.5)*Float.pi/4
            let r=sqrt(1-y*y)
            n=SIMD3<Float>(cos(angle)*r,y,sin(angle)*r)
        }
        guard let direction=Self.normalized(n),let h=surface(direction)
        else {return nil}
        return direction*(h+4)
    }

    /// NewHome290.WreckPosition: unchanged authored drifting docking wreck.
    func wreckPosition()->SIMD3<Float>? {
        let n=SIMD3<Float>(cos(Float.pi/8),0,sin(Float.pi/8))
        let up=SIMD3<Float>(0,1,0)
        guard let tangent=Self.normalized(Self.cross(up,n)),
              let side=Self.normalized(Self.cross(n,tangent)),
              let direction=Self.normalized(n*142-tangent*126+side*12),
              let h=surface(direction) else {return nil}
        return direction*(h+15)
    }

    /// OrbitWorld51.SurfaceDistance51 uses 137 m arc-length radius.
    func distanceToSector(_ position:SIMD3<Float>,level:Int)->Float? {
        guard let a=Self.normalized(position),
              let b=beacon(level).flatMap(Self.normalized)
        else {return nil}
        return acos(max(-1,min(1,Self.dot(a,b))))*137
    }

    /// OrbitWorld51.MissionArea51: [surface+4, surface+34] and arc <=26.
    func isInMissionArea(_ p:SIMD3<Float>,level:Int)->Bool {
        guard let h=surface(p),let distance=distanceToSector(p,level:level)
        else {return false}
        let radius=sqrt(Self.dot(p,p))
        return radius>=h+4 && radius<=h+34 && distance<=26
    }
}
