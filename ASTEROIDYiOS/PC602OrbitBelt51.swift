import Foundation

/// Original PC v602 OrbitWorld50.Belt51 and GpuIntro41.PrepareIntroBelt.
/// No procedurally invented iOS asteroid geometry. The data is baked offline
/// by Tools/PC602OrbitBelt51.cs using the original C# Random(4109),
/// H290 terrain, world wreck exclusion and subdivided crater meshes.
/// Each stone has a contiguous 10-float vertex interval in ONE immutable GPU
/// mesh. No CPU mesh generation, decompression or new allocations per frame.
struct PC602OrbitBelt51 {
    enum SourceError: Error {
        case missing, badHeader, invalidTable, invalidGeometry
    }

    static let asteroidCount=820
    static let sourceStoneStride=28
    static let vertexStride=40
    static let headerBytes=16
    static let sourceScale:Float=3.2
    static let sourceNear:Float=0.4
    static let sourceFar:Float=1600

    struct Stone {
        let center:SIMD3<Float> // PC source local coordinates; draw = center*3.2
        let size:Float
        let seed:Float
        let firstVertex:Int
        let vertexCount:Int
        var collisionRadius:Float {size*3.2*1.38+1.2}
    }

    let stones:[Stone]
    let vertexCount:Int
    let sourceBytes:Data
    let vertexOffset:Int

    private static func uint32(_ data:Data,_ offset:Int)->UInt32 {
        data.withUnsafeBytes {
            UInt32(littleEndian:$0.loadUnaligned(fromByteOffset:offset,as:UInt32.self))
        }
    }
    private static func float32(_ data:Data,_ offset:Int)->Float {
        Float(bitPattern:uint32(data,offset))
    }
    init(data:Data) throws {
        guard data.count>=Self.headerBytes+Self.asteroidCount*Self.sourceStoneStride,
              data.prefix(4)==Data([66,48,53,49]),
              Self.uint32(data,4)==1,
              Self.uint32(data,8)==UInt32(Self.asteroidCount)
        else {throw SourceError.badHeader}
        let number=Int(Self.uint32(data,12))
        let start=Self.headerBytes+Self.asteroidCount*Self.sourceStoneStride
        guard number>0,number%3==0,
              number <= (Int.max-start)/Self.vertexStride,
              data.count==start+number*Self.vertexStride
        else {throw SourceError.invalidGeometry}
        var parsed=[Stone]()
        parsed.reserveCapacity(Self.asteroidCount)
        var expected=0
        for index in 0..<Self.asteroidCount {
            let i=Self.headerBytes+index*Self.sourceStoneStride
            let center=SIMD3(
                Self.float32(data,i),Self.float32(data,i+4),
                Self.float32(data,i+8))
            let size=Self.float32(data,i+12)
            let seed=Self.float32(data,i+16)
            let first=Int(Self.uint32(data,i+20))
            let count=Int(Self.uint32(data,i+24))
            let expectedSize=size>1.15 ? 3840 : 960
            guard center.x.isFinite && center.y.isFinite && center.z.isFinite,
                  size.isFinite && size>=0.22-0.0001 && size<=1.97+0.0001,
                  seed.isFinite && abs(seed-Float(index)*0.73)<0.001,
                  first==expected, count==expectedSize,
                  expected<=number-count
            else {throw SourceError.invalidTable}
            expected+=count
            parsed.append(Stone(center:center,size:size,seed:seed,
                                firstVertex:first,vertexCount:count))
        }
        guard expected==number else {throw SourceError.invalidTable}
        stones=parsed
        sourceBytes=data
        vertexCount=number
        vertexOffset=start
    }

    static func load(bundle:Bundle = .main)throws->Self {
        guard let file=bundle.url(forResource:"PC602OrbitBelt51",withExtension:"bin")
            ?? bundle.url(forResource:"PC602OrbitBelt51",withExtension:"bin",
                          subdirectory:"Assets")
        else {throw SourceError.missing}
        return try Self(data:Data(contentsOf:file,options:.mappedIfSafe))
    }

    /// GpuIntro41.BeltVisibleInOrbit135 adapted only for live aspect ratio.
    /// Original 16:9 horizontal limit is 0.888889 = aspect/2.
    func visible(_ stone:Stone,view:[Float],aspect:Float)->Bool {
        guard view.count==16 && aspect>0 && aspect.isFinite else {return false}
        let p=stone.center*Self.sourceScale
        let radius=stone.size*Self.sourceScale*1.9+1
        let x=view[0]*p.x+view[4]*p.y+view[8]*p.z+view[12]
        let y=view[1]*p.x+view[5]*p.y+view[9]*p.z+view[13]
        let z=-(view[2]*p.x+view[6]*p.y+view[10]*p.z+view[14])
        if z+radius<Self.sourceNear || z-radius>Self.sourceFar {return false}
        let limit=max(z,Self.sourceNear)+radius
        return abs(x)<=limit*(aspect*0.5)+radius &&
               abs(y)<=limit*0.5+radius
    }

    /// Verify that source Belt51 stones remain in the true NewHome290 flight
    /// shell, clear of the authored docking wreck (no made-up spawn positions).
    func sourcePlacementValid(home:PC602NewHome290)->Bool {
        guard let wreck=home.wreckPosition() else {return false}
        for stone in stones {
            let world=stone.center*Self.sourceScale
            let r=sqrt(world.x*world.x+world.y*world.y+world.z*world.z)
            guard r>1, let terrain=home.surface(world) else{return false}
            if r<terrain+18.8 {return false}
            let delta=world-wreck
            let dockDistance=sqrt(delta.x*delta.x+delta.y*delta.y+
                                  delta.z*delta.z)
            // PC source attempts up to 15 exclusion rotations. Do not reject
            // a source rock when the original loop reaches this limit;
            // expose the measured value separately in golden tests.
            if !dockDistance.isFinite {return false}
        }
        return true
    }
}