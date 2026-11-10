import Foundation
import SceneKit
import simd

/// PC580 Tools/bake_gloves417.py parity: divide original triangles at
/// authored centroid X=-0.0002 (TRIPO) / Y=.4929 (MONOLIT).
/// Unlike grouping full mesh parts, this preserves every authored face.
/// Reuses source SCNGeometrySource buffers, normals, UV and PBR materials.
/// PC GpuGloves417 swaps MONOLIT VBO ranges anatomically.
@MainActor enum H55FPSMeshSplit580 {
    enum Failure:Error {case noMeshes,unsupportedGeometry,noPair}
    struct Result {
        let left:[SCNNode],right:[SCNNode]
        let triangles:Int,parts:Int
    }
    private struct Recipe {
        let axis:Int,threshold:Float
        let centres:[SIMD3<Float>]
        let reverse:Bool
    }
    private static func recipe(_ kind:H55FPSAssets580.Kind)->Recipe? {
        switch kind {
        case .tripo:
            return Recipe(axis:0,threshold:-0.0002,
                centres:[SIMD3<Float>(-0.3280,0.1703,0.0680),
                         SIMD3<Float>(0.3225,0.1799,0.0718)],reverse:false)
        case .monolith:
            return Recipe(axis:1,threshold:0.4929,
                centres:[SIMD3<Float>(0.0165,0.1794,0.0043),
                         SIMD3<Float>(-0.0182,0.7922,-0.0002)],reverse:true)
        case .weapon:
            return nil // Weapon stays whole and never passes through glove splitter
        }
    }
    private static func u32(_ bytes:[UInt8],_ i:Int)->UInt32 {
        UInt32(bytes[i]) | (UInt32(bytes[i+1]) << 8) |
            (UInt32(bytes[i+2]) << 16) | (UInt32(bytes[i+3]) << 24)
    }
    private static func index(_ bytes:[UInt8],_ i:Int,_ width:Int)->UInt32 {
        switch width {
        case 1:return UInt32(bytes[i])
        case 2:return UInt32(bytes[i]) | (UInt32(bytes[i+1]) << 8)
        default:return u32(bytes,i)
        }
    }
    static func build(scene:SCNScene,kind:H55FPSAssets580.Kind)throws->Result {
        guard let r=recipe(kind) else{throw Failure.unsupportedGeometry}
        var halves=[[SCNNode](),[SCNNode]()]
        var triangles=0,parts=0,failed=false
        scene.rootNode.enumerateHierarchy { node,_ in
            guard let geometry=node.geometry else{return}
            guard let source=geometry.sources.first(where:{$0.semantic == .vertex}),
                  source.usesFloatComponents,source.bytesPerComponent==4,
                  source.componentsPerVector>=3,source.vectorCount>0,
                  !geometry.materials.isEmpty else{failed=true;return}
            let data=[UInt8](source.data)
            let stride=source.dataStride,offset=source.dataOffset
            guard stride>=12,offset>=0,
                  offset+(source.vectorCount-1)*stride+12<=data.count
            else {failed=true;return}
            let m=node.simdWorldTransform
            var axisPositions=[Float](repeating:0,count:source.vectorCount)
            for v in 0..<source.vectorCount {
                let start=offset+v*stride
                let px=Float(bitPattern:u32(data,start))
                let py=Float(bitPattern:u32(data,start+4))
                let pz=Float(bitPattern:u32(data,start+8))
                let a=r.axis
                axisPositions[v] = m.columns.0[a] * px + m.columns.1[a] * py + m.columns.2[a] * pz + m.columns.3[a]
            }
            var elements=[[SCNGeometryElement](),[SCNGeometryElement]()]
            var mats=[[SCNMaterial](),[SCNMaterial]()]
            for (materialIndex,element) in geometry.elements.enumerated() {
                guard element.primitiveType == .triangles,
                      [1,2,4].contains(element.bytesPerIndex) else {
                    failed=true;return
                }
                let bytes=[UInt8](element.data)
                let w=element.bytesPerIndex
                guard element.primitiveCount*3*w<=bytes.count else {
                    failed=true;return
                }
                var lists=[[UInt32](),[UInt32]()]
                for f in 0..<element.primitiveCount {
                    let base=f*3*w
                    let i0=index(bytes,base,w),i1=index(bytes,base+w,w)
                    let i2=index(bytes,base+2*w,w)
                    let v0=Int(i0),v1=Int(i1),v2=Int(i2)
                    guard v0<axisPositions.count && v1<axisPositions.count &&
                          v2<axisPositions.count else{failed=true;return}
                    let centre=(axisPositions[v0]+axisPositions[v1]+axisPositions[v2])/3
                    let geometric=centre>=r.threshold ? 1:0
                    let hand=r.reverse ? 1-geometric : geometric
                    lists[hand].append(contentsOf:[i0,i1,i2])
                    triangles+=1
                }
                let mat=geometry.materials[min(materialIndex,geometry.materials.count-1)]
                for hand in 0..<2 where !lists[hand].isEmpty {
                    let buffer=lists[hand].withUnsafeBytes{Data($0)}
                    elements[hand].append(SCNGeometryElement(data:buffer,
                       primitiveType:.triangles,
                       primitiveCount:lists[hand].count/3,bytesPerIndex:4))
                    mats[hand].append(mat)
                }
            }
            for hand in 0..<2 where !elements[hand].isEmpty {
                let partial=SCNGeometry(sources:geometry.sources,
                    elements:elements[hand])
                partial.materials=mats[hand]
                let copy=SCNNode(geometry:partial)
                copy.name=(node.name ?? "GLB")+(hand==0 ? "_LEFT" : "_RIGHT")
                copy.simdTransform=m
                let authored=r.reverse ? 1-hand : hand
                copy.simdPosition-=r.centres[authored]
                halves[hand].append(copy)
                parts+=1
            }
        }
        guard !failed else{throw Failure.unsupportedGeometry}
        guard parts>0 else{throw Failure.noMeshes}
        guard !halves[0].isEmpty && !halves[1].isEmpty else{throw Failure.noPair}
        return Result(left:halves[0],right:halves[1],
                      triangles:triangles,parts:parts)
    }
}
