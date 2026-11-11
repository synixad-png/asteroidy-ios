import Foundation
import Metal
import simd

/// Original PC v602 HUD glTF, decoded once into resident native Metal mesh
/// buffers. Unlike the four pickups, this asset has 159 *node* animation
/// channels: geometry is shared, and only TRS matrices change per frame.
///
/// This is a strict decoder for the SHA-verified original planetarium.glb,
/// not a generic second glTF engine and not a procedural replacement.
final class HudPlanetariumOriginal600 {
    enum Failure:Error {case invalidAsset, unsupportedSource, gpuAllocation}
    struct Part {
        let buffer:MTLBuffer
        let vertices:Int
        let material:Int
        let tint:SIMD4<Float>
    }
    struct Node {
        let name:String
        let parent:Int
        let mesh:Int?
        let translation:SIMD3<Float>
        let rotation:simd_quatf
        let scale:SIMD3<Float>
    }
    struct Track {
        enum Path {case translation,rotation,scale}
        let node:Int
        let path:Path
        let times:[Float]
        let values:[SIMD4<Float>]
        func at(_ time:Float)->SIMD4<Float> {
            guard values.count>1 else{return values[0]}
            if time<=times[0] {return values[0]}
            if time>=times[times.count-1] {return values[values.count-1]}
            var lo=0,hi=times.count-1
            while lo+1<hi {
                let mid=(lo+hi)/2
                if times[mid] <= time {lo=mid} else {hi=mid}
            }
            let duration=times[hi]-times[lo]
            let blend=duration>0 ? min(1,max(0,(time-times[lo])/duration)) : 0
            if case .rotation=path {
                let a=simd_quatf(vector:values[lo])
                let b=simd_quatf(vector:values[hi])
                return simd_normalize(simd_slerp(a,b,blend)).vector
            }
            return simd_mix(values[lo],values[hi],SIMD4<Float>(repeating:blend))
        }
    }
    struct Frame {
        let world:[simd_float4x4]
        let hidden:[Bool]
    }

    let parts:[[Part]]
    let nodes:[Node]
    let tracks:[Track]
    let drawOrder:[Int]
    let duration:Float
    private let capsuleNodes:[[Int]]
    private let capsuleExtents:[(min:Float,max:Float)]
    private let flashNodes:[Int]

    private struct Reader {
        let bytes:Data
        let binaryStart:Int
        let accessors:[[String:Any]]
        let views:[[String:Any]]
        private func u16(_ pos:Int)->UInt16 {
            UInt16(bytes[pos]) | UInt16(bytes[pos+1]) << 8
        }
        private func u32(_ pos:Int)->UInt32 {
            UInt32(bytes[pos]) | UInt32(bytes[pos+1]) << 8 |
            UInt32(bytes[pos+2]) << 16 | UInt32(bytes[pos+3]) << 24
        }
        func accessor(_ index:Int,component:Int,type:String)->[Float]? {
            guard accessors.indices.contains(index),
                  let accessor=accessors[index] as? [String:Any],
                  let count=accessor["count"] as? Int,
                  let ct=accessor["componentType"] as? Int,ct==component,
                  let kind=accessor["type"] as? String,kind==type,
                  let ref=accessor["bufferView"] as? Int,
                  views.indices.contains(ref),count>=0,
                  count<500_000,accessor["sparse"] == nil,
                  let off=views[ref]["byteOffset"] as? Int,
                  let length=views[ref]["byteLength"] as? Int,
                  (accessor["byteOffset"] as? Int ?? 0)==0,
                  views[ref]["byteStride"] == nil else{return nil}
            let width=type=="SCALAR" ? 1 : type=="VEC3" ? 3 : type=="VEC4" ? 4 : 0
            let bytesPer=component==5126 ? 4 : component==5123 ? 2 : component==5121 ? 1 : 0
            let size=count*width*bytesPer
            let begin=binaryStart+off
            guard width>0,bytesPer>0,size<=length,begin>=0,
                  begin+size<=bytes.count else{return nil}
            var result=[Float]()
            result.reserveCapacity(count*width)
            for n in 0..<(count*width) {
                let p=begin+n*bytesPer
                switch component {
                case 5126:result.append(Float(bitPattern:u32(p)))
                case 5123:result.append(Float(u16(p)))
                case 5121:result.append(Float(bytes[p]))
                default:return nil
                }
            }
            return result
        }
        func indices(_ index:Int)->[Int]? {
            guard accessors.indices.contains(index),
                  let kind=accessors[index]["componentType"] as? Int,
                  kind==5123 || kind==5125,
                  let count=accessors[index]["count"] as? Int,
                  let ref=accessors[index]["bufferView"] as? Int,
                  views.indices.contains(ref),
                  let off=views[ref]["byteOffset"] as? Int,
                  let length=views[ref]["byteLength"] as? Int,
                  count>=0,count<1_000_000,
                  accessors[index]["sparse"] == nil else{return nil}
            let stride=kind==5123 ? 2 : 4
            let begin=binaryStart+off+(accessors[index]["byteOffset"] as? Int ?? 0)
            guard count*stride<=length,begin>=0,
                  begin+count*stride<=bytes.count else{return nil}
            return (0..<count).map{n in
                let p=begin+n*stride
                return kind==5123 ? Int(u16(p)) : Int(u32(p))
            }
        }
    }

    init(originalURL:URL,device:MTLDevice) throws {
        let raw=try Data(contentsOf:originalURL)
        try HudPlanetariumAsset600.validate(raw)
        guard raw.count>=28 else{throw Failure.invalidAsset}
        func u32(_ p:Int)->Int {
            Int(UInt32(raw[p]) | UInt32(raw[p+1]) << 8 |
                UInt32(raw[p+2]) << 16 | UInt32(raw[p+3]) << 24)
        }
        let jsonLength=u32(12)
        let binStart=20+jsonLength+8
        guard jsonLength>0,binStart<=raw.count,
              u32(20+jsonLength+4)==0x004E4942,
              let root=try JSONSerialization.jsonObject(
                with:raw.subdata(in:20..<(20+jsonLength))) as? [String:Any],
              let accessorRecords=root["accessors"] as? [[String:Any]],
              let viewRecords=root["bufferViews"] as? [[String:Any]],
              let meshRecords=root["meshes"] as? [[String:Any]],
              let nodeRecords=root["nodes"] as? [[String:Any]],
              let animationRecords=root["animations"] as? [[String:Any]],
              nodeRecords.count==HudPlanetariumAsset600.nodes,
              meshRecords.count==20,animationRecords.count==1,
              let channelRecords=animationRecords[0]["channels"] as? [[String:Any]],
              channelRecords.count==HudPlanetariumAsset600.channels,
              let samplerRecords=animationRecords[0]["samplers"] as? [[String:Any]]
        else{throw Failure.unsupportedSource}
        let reader=Reader(bytes:raw,binaryStart:binStart,
                          accessors:accessorRecords,views:viewRecords)
        let materialRecords=root["materials"] as? [[String:Any]] ?? []
        guard materialRecords.count==3 else{throw Failure.unsupportedSource}
        var builtParts=[[Part]]()
        for mesh in meshRecords {
            guard let primitives=mesh["primitives"] as? [[String:Any]]
            else{throw Failure.unsupportedSource}
            var shape=[Part]()
            for primitive in primitives {
                guard primitive["mode"] as? Int ?? 4 == 4,
                      let attrs=primitive["attributes"] as? [String:Int],
                      let posIndex=attrs["POSITION"],
                      let positions=reader.accessor(posIndex,
                            component:5126,type:"VEC3"),
                      let accessor=accessorRecords[safe:posIndex],
                      let count=accessor["count"] as? Int,
                      count*3==positions.count,
                      let index=primitive["indices"] as? Int,
                      let indices=reader.indices(index),
                      indices.count%3==0 else{throw Failure.unsupportedSource}
                let color:[Float]?
                if let ci=attrs["COLOR_0"] {
                    guard let rgb=reader.accessor(ci,component:5121,type:"VEC4"),
                          rgb.count==count*4 else{throw Failure.unsupportedSource}
                    color=rgb
                } else {color=nil}
                let material=primitive["material"] as? Int ?? 0
                guard materialRecords.indices.contains(material) else{
                    throw Failure.unsupportedSource
                }
                let pbr=materialRecords[material]["pbrMetallicRoughness"] as? [String:Any]
                let factors=pbr?["baseColorFactor"] as? [NSNumber] ?? [1,1,1,1]
                guard factors.count==4 else{throw Failure.unsupportedSource}
                let tint=SIMD4<Float>(Float(truncating:factors[0]),
                                       Float(truncating:factors[1]),
                                       Float(truncating:factors[2]),
                                       Float(truncating:factors[3]))
                var floats=[Float]()
                floats.reserveCapacity(indices.count*7)
                for vertex in indices {
                    guard vertex>=0,vertex<count else{throw Failure.unsupportedSource}
                    floats.append(contentsOf:positions[vertex*3..<(vertex*3+3)])
                    if let color {
                        floats.append(contentsOf:color[vertex*4..<(vertex*4+4)].map{$0/255})
                    } else {
                        floats.append(contentsOf:[1,1,1,1])
                    }
                }
                guard let gpu=floats.withUnsafeBytes({bytes in
                    device.makeBuffer(bytes:bytes.baseAddress!,
                                      length:bytes.count,
                                      options:.storageModeShared)
                }) else{throw Failure.gpuAllocation}
                shape.append(Part(buffer:gpu,vertices:indices.count,
                                  material:material,tint:tint))
            }
            builtParts.append(shape)
        }
        self.parts=builtParts

        var parent=[Int](repeating:-1,count:nodeRecords.count)
        for (idx,record) in nodeRecords.enumerated() {
            for child in record["children"] as? [Int] ?? [] {
                guard parent.indices.contains(child),parent[child] == -1
                else{throw Failure.unsupportedSource}
                parent[child]=idx
            }
        }
        self.nodes=try nodeRecords.enumerated().map{(index,record) in
            let t=record["translation"] as? [NSNumber] ?? [0,0,0]
            let r=record["rotation"] as? [NSNumber] ?? [0,0,0,1]
            let s=record["scale"] as? [NSNumber] ?? [1,1,1]
            guard t.count==3,r.count==4,s.count==3 else{
                throw Failure.unsupportedSource
            }
            let mesh=record["mesh"] as? Int
            if let mesh,!builtParts.indices.contains(mesh) {
                throw Failure.unsupportedSource
            }
            return Node(name:record["name"] as? String ?? "",
                        parent:parent[index],mesh:mesh,
                        translation:SIMD3(Float(truncating:t[0]),
                                          Float(truncating:t[1]),
                                          Float(truncating:t[2])),
                        rotation:simd_quatf(ix:Float(truncating:r[0]),
                                             iy:Float(truncating:r[1]),
                                             iz:Float(truncating:r[2]),
                                             r:Float(truncating:r[3])),
                        scale:SIMD3(Float(truncating:s[0]),
                                    Float(truncating:s[1]),
                                    Float(truncating:s[2])))
        }

        var visited=Set<Int>()
        var order=[Int]()
        func walk(_ n:Int) throws {
            guard nodeRecords.indices.contains(n),!visited.contains(n)
            else{throw Failure.unsupportedSource}
            visited.insert(n)
            order.append(n)
            for child in nodeRecords[n]["children"] as? [Int] ?? [] {
                try walk(child)
            }
        }
        guard let sceneRefs=root["scenes"] as? [[String:Any]],
              let roots=sceneRefs.first?["nodes"] as? [Int],
              roots==[0] else{throw Failure.unsupportedSource}
        for node in roots {try walk(node)}
        guard order.count==141 else{throw Failure.unsupportedSource}
        self.drawOrder=order

        var parsedTracks=[Track]()
        for channel in channelRecords {
            guard let target=channel["target"] as? [String:Any],
                  let node=target["node"] as? Int,
                  self.nodes.indices.contains(node),
                  let pathString=target["path"] as? String,
                  let samplerIndex=channel["sampler"] as? Int,
                  samplerRecords.indices.contains(samplerIndex),
                  let input=samplerRecords[samplerIndex]["input"] as? Int,
                  let output=samplerRecords[samplerIndex]["output"] as? Int,
                  let times=reader.accessor(input,component:5126,type:"SCALAR"),
                  !times.isEmpty,
                  samplerRecords[samplerIndex]["interpolation"] as? String ?? "LINEAR" == "LINEAR"
            else{throw Failure.unsupportedSource}
            let path:Track.Path
            let components:Int
            switch pathString {
            case "translation":path = .translation;components=3
            case "rotation":path = .rotation;components=4
            case "scale":path = .scale;components=3
            default:throw Failure.unsupportedSource
            }
            guard let data=reader.accessor(output,component:5126,
                                           type:components==4 ? "VEC4":"VEC3"),
                  data.count==times.count*components else {
                throw Failure.unsupportedSource
            }
            let values=(0..<times.count).map{n -> SIMD4<Float> in
                let base=n*components
                return SIMD4(data[base],data[base+1],data[base+2],
                             components==4 ? data[base+3] : 0)
            }
            parsedTracks.append(Track(node:node,path:path,times:times,values:values))
        }
        self.tracks=parsedTracks
        duration=parsedTracks.compactMap{$0.times.last}.max() ?? 0
        guard abs(duration-48)<0.001 else{throw Failure.unsupportedSource}

        var nodeGroups=[[Int]](repeating:[],count:3)
        var bounds=[(min:Float,max:Float)](
            repeating:(Float.infinity,-Float.infinity),count:3)
        for (idx,node) in nodes.enumerated() {
            for group in 0..<3 where
                node.name.hasPrefix("CAPSULE_\(group)_WATER_BUBBLE_") {
                nodeGroups[group].append(idx)
            }
        }
        for track in parsedTracks where track.path == .translation {
            for group in 0..<3 where nodeGroups[group].contains(track.node) {
                for value in track.values {
                    bounds[group].min=min(bounds[group].min,value.x)
                    bounds[group].max=max(bounds[group].max,value.x)
                }
            }
        }
        guard nodeGroups.allSatisfy({$0.count==24}),
              bounds.allSatisfy({$0.max>$0.min+0.1}) else {
            throw Failure.unsupportedSource
        }
        capsuleNodes=nodeGroups
        capsuleExtents=bounds
        // Resolve against the already-parsed local glTF JSON. Capturing
        // self.nodes here is invalid before every stored property is set.
        let sockets=["DAMAGE_HULL_FLASH_SOCKET","DAMAGE_ARMOR_FLASH_SOCKET",
                     "DAMAGE_SHIELD_FLASH_SOCKET"]
        flashNodes=try sockets.map{name in
            guard let idx=nodeRecords.firstIndex(where:{
                ($0["name"] as? String)==name
            }) else{throw Failure.unsupportedSource}
            return idx
        }
        let rendered=nodes.filter{$0.mesh != nil}.count
        guard rendered==91 else{throw Failure.unsupportedSource}
    }

    private static func translation(_ v:SIMD3<Float>)->simd_float4x4 {
        var a=matrix_identity_float4x4
        a.columns.3=SIMD4(v,1)
        return a
    }
    private static func scaling(_ v:SIMD3<Float>)->simd_float4x4 {
        var a=matrix_identity_float4x4
        a.columns.0.x=v.x;a.columns.1.y=v.y;a.columns.2.z=v.z
        return a
    }
    func sample(at seconds:Double,capsules:HudCapsuleController600.Snapshot)->Frame {
        let t=Float(seconds.isFinite ? seconds.truncatingRemainder(
            dividingBy:Double(duration)) : 0)
        var positions=nodes.map{$0.translation}
        var rotations=nodes.map{$0.rotation}
        var scales=nodes.map{$0.scale}
        for track in tracks {
            let value=track.at(t)
            switch track.path {
            case .translation:
                positions[track.node]=SIMD3(value.x,value.y,value.z)
            case .rotation:
                rotations[track.node]=simd_quatf(vector:value)
            case .scale:
                scales[track.node]=SIMD3(value.x,value.y,value.z)
            }
        }
        var hidden=[Bool](repeating:false,count:nodes.count)
        for i in 0..<3 {
            let level=HudCapsuleController600.clamp(capsules.levels[i])
            let extent=capsuleExtents[i]
            let limit=extent.min+(extent.max-extent.min)*level
            for node in capsuleNodes[i] {
                hidden[node]=level<=0 || (level<1 && positions[node].x>limit)
            }
            let glow=0.001+0.75*HudCapsuleController600.clamp(capsules.flashes[i])
            scales[flashNodes[i]]=SIMD3(repeating:glow)
        }
        var world=[simd_float4x4](
            repeating:matrix_identity_float4x4,count:nodes.count)
        for idx in drawOrder {
            let local=Self.translation(positions[idx]) *
                simd_float4x4(rotations[idx]) * Self.scaling(scales[idx])
            let parent=nodes[idx].parent
            world[idx]=parent<0 ? local : world[parent]*local
        }
        return Frame(world:world,hidden:hidden)
    }
}

// The exact original asset contains contiguous, non-sparse accessors.
// Bounds checks above deliberately reject other glTF variants rather than
// silently interpreting their memory layouts as the approved PC v602 asset.
private extension Array {
    subscript(safe index:Int)->Element? {
        indices.contains(index) ? self[index] : nil
    }
}
