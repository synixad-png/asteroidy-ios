import Foundation
import simd

/// The other 96 glTF channels authored in the ORIGINAL v609 Boreas GLB:
/// 48 translation and 48 scale tracks on 24 droplets + 24 liquid necks.
/// Morph deformation remains in BoreasMorphRenderer556. All 97 original
/// channels now share the same five-second clock and three existing GPU
/// vertex buffers; there is no SceneKit overlay, synthetic motion or
/// per-frame MTLBuffer allocation.
struct BoreasNodeTracks556 {
    enum SourceError:Error {
        case wrongHeader,invalidData,mismatch
    }
    private struct Key {
        let time:Float
        let translation:SIMD3<Float>
        let scale:SIMD3<Float>
    }
    private struct Node {
        let sourceID:Int
        let first:Int
        let count:Int
        let rotation:simd_quatf
        let positions:[SIMD3<Float>]
        let normals:[SIMD3<Float>]
        let keys:[Key]
    }
    let dynamicVertexRange:Range<Int>
    private let nodes:[Node]
    private let center:SIMD3<Float>
    private let radius:Float
    private let duration:Float=5

    /// ASNT1 is the exact, losslessly exported GLB tracks and original
    /// local mesh coordinates. The original source GLB is needed only
    /// when exporting, not on iOS at 60/120 FPS.
    init(data:Data,mesh:AssetMesh) throws {
        guard data.count>=40,
              Array(data.prefix(4))==Array("ASNT".utf8)
        else {throw SourceError.wrongHeader}
        func word(_ at:Int)->UInt32 {
            data.withUnsafeBytes {
                $0.loadUnaligned(fromByteOffset:at,as:UInt32.self)
            }
        }
        func float(_ at:Int)->Float {
            Float(bitPattern:word(at))
        }
        guard word(4)==1,word(8)==48,
              word(12)==4320,word(16)==31355,
              mesh.vertices.count==31355,word(20)==130752
        else {throw SourceError.wrongHeader}
        let originalCenter=SIMD3(float(24),float(28),float(32))
        let originalRadius=float(36)
        guard originalRadius.isFinite,originalRadius>0,
              originalCenter.x.isFinite,originalCenter.y.isFinite,
              originalCenter.z.isFinite else {throw SourceError.wrongHeader}
        let decompressed:Data
        do {
            decompressed=try ((Data(data.dropFirst(40)) as NSData)
                .decompressed(using:.zlib) as Data)
        } catch {throw SourceError.invalidData}
        guard decompressed.count==Int(word(20)) else {
            throw SourceError.invalidData
        }
        var cursor=0
        func readWord() throws->UInt32 {
            guard cursor+4<=decompressed.count else {
                throw SourceError.invalidData
            }
            let value=decompressed.withUnsafeBytes {
                $0.loadUnaligned(fromByteOffset:cursor,as:UInt32.self)
            }
            cursor+=4
            return value
        }
        func readFloat() throws->Float {
            let v=Float(bitPattern:try readWord())
            guard v.isFinite else {throw SourceError.invalidData}
            return v
        }
        func readVec3() throws->SIMD3<Float> {
            SIMD3(try readFloat(),try readFloat(),try readFloat())
        }
        var nextVertex=0
        var records:[Node]=[]
        records.reserveCapacity(48)
        var observed=Set<Int>()
        for _ in 0..<48 {
            let id=Int(try readWord())
            let first=Int(try readWord())
            let count=Int(try readWord())
            let keyCount=Int(try readWord())
            guard (1...48).contains(id),observed.insert(id).inserted,
                  first==nextVertex,
                  (count==72 || count==108),
                  keyCount==13 || keyCount==25,
                  first+count<=4320 else {
                throw SourceError.invalidData
            }
            let quaternion=simd_quatf(ix:try readFloat(),
                                       iy:try readFloat(),
                                       iz:try readFloat(),
                                       r:try readFloat())
            guard abs(simd_length(quaternion.vector)-1)<0.001
            else {throw SourceError.invalidData}
            var positions:[SIMD3<Float>]=[]
            var normals:[SIMD3<Float>]=[]
            positions.reserveCapacity(count)
            normals.reserveCapacity(count)
            for _ in 0..<count {positions.append(try readVec3())}
            for _ in 0..<count {normals.append(try readVec3())}
            var keys:[Key]=[]
            keys.reserveCapacity(keyCount)
            for k in 0..<keyCount {
                let time=try readFloat()
                let trans=try readVec3()
                let size=try readVec3()
                guard time>=0,time<=5,
                      (k==0 && time==0 ||
                       k>0 && time>keys[k-1].time),
                      simd_min(size,SIMD3<Float>(repeating:0))
                          == SIMD3<Float>(repeating:0)
                else {throw SourceError.invalidData}
                keys.append(Key(time:time,translation:trans,scale:size))
            }
            guard abs(keys.last!.time-5)<0.00001 else {
                throw SourceError.invalidData
            }
            // Source glTF default node transform is exactly the t=0
            // authored keyframe. Prove the exported part still matches
            // the real previously verified static AS3D vertex range.
            for i in 0..<count {
                let actual=mesh.vertices[first+i].position
                let rotated=quaternion.act(positions[i]*keys[0].scale)
                let expected=(keys[0].translation+rotated-originalCenter)/
                    originalRadius
                let observed=SIMD3(actual.x,actual.y,actual.z)
                guard simd_length(expected-observed)<0.0001 else {
                    throw SourceError.mismatch
                }
            }
            records.append(Node(sourceID:id,first:first,count:count,
                                rotation:quaternion,positions:positions,
                                normals:normals,keys:keys))
            nextVertex+=count
        }
        guard nextVertex==4320,observed.count==48,
              cursor==decompressed.count else {
            throw SourceError.invalidData
        }
        center=originalCenter
        radius=originalRadius
        nodes=records
        dynamicVertexRange=0..<nextVertex
    }

    /// Strict glTF LINEAR interpolation at the authored key times, with
    /// exactly the original node rotations and non-uniform scales.
    /// No noise, fake droplets or reconstructed random trajectories.
    func updateVertices(seconds:Double,
                        into result:inout [AssetMesh.Vertex]) {
        precondition(result.count==31355)
        guard seconds.isFinite else{return}
        let t=Float(seconds.truncatingRemainder(dividingBy:Double(duration)))
        for node in nodes {
            let keys=node.keys
            var upper=1
            while upper<keys.count-1 && keys[upper].time<t {upper+=1}
            let a=keys[upper-1],b=keys[upper]
            let delta=max(0.0000001,b.time-a.time)
            let blend=max(0,min(1,(t-a.time)/delta))
            let translation=a.translation+(b.translation-a.translation)*blend
            let scale=a.scale+(b.scale-a.scale)*blend
            let inverse=SIMD3<Float>(1/max(scale.x,0.0000001),
                                      1/max(scale.y,0.0000001),
                                      1/max(scale.z,0.0000001))
            for i in 0..<node.count {
                let world=node.rotation.act(node.positions[i]*scale)+translation
                let p=(world-center)/radius
                let n=node.rotation.act(node.normals[i]*inverse)
                let length=simd_length(n)
                let normal=length>0.0000001 ? n/length :
                    SIMD3<Float>(0,0,1)
                let index=node.first+i
                result[index].position=SIMD4(p.x,p.y,p.z,1)
                result[index].normal=SIMD4(normal.x,normal.y,normal.z,0)
            }
        }
    }
}
