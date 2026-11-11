import Foundation

/// PC v602: GpuAmbient37.SpaceHash207/SpaceRand207 and
/// GpuIntro41.DrawDetailedResearchWreck211(seed:211, orbit:true),
/// source lines 398–415. This is the exact 146-piece spatial/debris
/// specification, NOT a made-up wreck GLB and NOT a complete hull renderer.
/// The hull's original panels, soot, scratches and warning lights still
/// have to be transferred before enabling this independent world view.
enum PC602WreckDebris209 {
    struct Fragment {
        let localCenter:SIMD3<Float>
        let localSize:SIMD3<Float>
        let color:SIMD4<Float>
        let originalIndex:Int
        let isAccent:Bool
    }

    static let wreckSeed=211
    static let primaryCount=PC602NewHome290.wreckDebrisCount295
    static let scale=PC602NewHome290.wreckScale295
    static let yawDegrees:Float=31
    static let rollDegrees:Float = -9

    /// C# uint overflow must be 32-bit, even when executed on ARM64.
    private static func spaceHash207(_ initial:UInt32)->UInt32 {
        var x=initial
        x ^= x >> 16
        x &*= 0x7feb352d
        x ^= x >> 15
        x &*= 0x846ca68b
        x ^= x >> 16
        return x
    }
    static func spaceRand207(_ a:Int,_ b:Int,_ c:Int)->Float {
        let x=UInt32(truncatingIfNeeded:Int64(a)*73856093)
        let y=UInt32(truncatingIfNeeded:Int64(b)*19349663)
        let z=UInt32(truncatingIfNeeded:Int64(c)*83492791)
        let value=spaceHash207(x ^ y ^ z) & 0x00ff_ffff
        return Float(value)/16777215
    }

    /// WreckBox209 authored box instructions. Every one corresponds to an
    /// actual source call. Do NOT replace the original source boxes with
    /// spheres or randomized debris drawn at different coordinates.
    static func fragments() -> [Fragment] {
        let count=primaryCount
        var result=[Fragment]()
        result.reserveCapacity(count+(count+9)/10)
        for index in 0..<count {
            let t=Float(index)/Float(count-1)
            let jx=spaceRand207(wreckSeed,index,8)-0.5
            let jy=spaceRand207(wreckSeed,index,14)-0.5
            let jz=spaceRand207(wreckSeed,index,29)-0.5
            let x = 20 + PC602NewHome290.wreckTrailLength295 * t + jx * (7 + 41*t)
            let y=14*t+jy*(6+28*t)+5.2*sin(t*7.2+Float(wreckSeed)*0.01)
            let z=7+15*t+jz*(6+36*t)+2.6*cos(t*8)
            let radius=(0.88+spaceRand207(wreckSeed,index,55)*3.8)*
                (1-0.62*t)
            let sizeY=radius*(index%5==0 ? 1.12 : 0.72)
            let sizeZ=radius*(index%4==0 ? 1.28 : 0.88)
            let hot=index%11==0 || index%13==0
            let red=index%7==0
            let cr:Float=hot ? 0.78 : red ? 0.50 : index%3==0 ? 0.38 : 0.30
            let cg:Float=hot ? 0.42 : red ? 0.18 : index%3==0 ? 0.40 : 0.36
            let cb:Float=hot ? 0.14 : red ? 0.15 : index%3==0 ? 0.47 : 0.43
            result.append(Fragment(
                localCenter:SIMD3(x,y,z),
                localSize:SIMD3(radius,sizeY,sizeZ),
                color:SIMD4(cr,cg,cb,1),
                originalIndex:index,isAccent:false))
            if index%10==0 {
                result.append(Fragment(
                    localCenter:SIMD3(x+radius*0.9,y+radius*0.2,
                                      z-radius*0.4),
                    localSize:SIMD3(radius*0.18,radius*1.45,radius*0.18),
                    color:SIMD4(0.74,0.48,0.20,1),
                    originalIndex:index,isAccent:true))
            }
        }
        return result
    }

    /// GpuIntro41.DrawOrbitResearchWreck209: glTranslate(WreckPosition),
    /// glRotate(31,Y), glRotate(-9,Z), glScale(.6048). GL postmultiplies
    /// the matrices in this exact order; using an arbitrary point as origin
    /// would make the wreck and docking gate drift apart.
    static func worldPosition(_ local:SIMD3<Float>,
                              dock:SIMD3<Float>)->SIMD3<Float> {
        let yaw=yawDegrees*Float.pi/180
        let roll=rollDegrees*Float.pi/180
        let cr=cos(roll),sr=sin(roll)
        let cy=cos(yaw),sy=sin(yaw)
        let xr=cr*local.x-sr*local.y
        let yr=sr*local.x+cr*local.y
        let xx=cy*xr+sy*local.z
        let zz = -sy*xr+cy*local.z
        return dock + SIMD3(xx,yr,zz)*scale
    }

    static func worldFragments(home:PC602NewHome290)->[Fragment]? {
        guard let dock=home.wreckPosition() else{return nil}
        return fragments().map {
            Fragment(localCenter:worldPosition($0.localCenter,dock:dock),
                     localSize:$0.localSize*scale,color:$0.color,
                     originalIndex:$0.originalIndex,isAccent:$0.isAccent)
        }
    }
}
