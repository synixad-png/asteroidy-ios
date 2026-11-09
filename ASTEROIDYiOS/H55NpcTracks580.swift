import Foundation

/// Only the two 80-node authored H55 NPC clips from the verified PC v580 GLB.
/// Decodes their 480 glTF channels on demand; does not duplicate the 126 MB BIN
/// or synthesize a replacement skeleton. All interpolation follows glTF 2.0.
enum H55NpcTracks580 {
    struct Quaternion: Equatable {
        var x:Float, y:Float, z:Float, w:Float
        static let identity = Quaternion(x:0,y:0,z:0,w:1)
        var norm:Float {sqrt(x*x+y*y+z*z+w*w)}
        func normalized()->Self {
            let n=norm
            return n>0.000001 ? .init(x:x/n,y:y/n,z:z/n,w:w/n):.identity
        }
        func conjugate()->Self {.init(x:-x,y:-y,z:-z,w:w)}
        static func * (a:Self,b:Self)->Self {
            .init(x:a.w*b.x+a.x*b.w+a.y*b.z-a.z*b.y,
                  y:a.w*b.y-a.x*b.z+a.y*b.w+a.z*b.x,
                  z:a.w*b.z+a.x*b.y-a.y*b.x+a.z*b.w,
                  w:a.w*b.w-a.x*b.x-a.y*b.y-a.z*b.z)
        }
        static func slerp(_ a:Self,_ b:Self,_ t:Float)->Self {
            let f=max(0,min(1,t))
            var dot=a.x*b.x+a.y*b.y+a.z*b.z+a.w*b.w
            let sign:Float=dot<0 ? -1 : 1
            dot=abs(dot)
            if dot>0.9995 {
                return Self(x:a.x*(1-f)+b.x*sign*f,
                            y:a.y*(1-f)+b.y*sign*f,
                            z:a.z*(1-f)+b.z*sign*f,
                            w:a.w*(1-f)+b.w*sign*f).normalized()
            }
            let angle=acos(max(-1,min(1,dot)))
            let s=sin(angle)
            guard s>0.000001 else{return a}
            let aF=sin((1-f)*angle)/s,bF=sign*sin(f*angle)/s
            return Self(x:a.x*aF+b.x*bF,y:a.y*aF+b.y*bF,
                        z:a.z*aF+b.z*bF,w:a.w*aF+b.w*bF).normalized()
        }
        static func axisAngle(_ axis:SIMD3<Float>,_ angle:Float)->Self {
            let m=sqrt(axis.x*axis.x+axis.y*axis.y+axis.z*axis.z)
            if m<0.000001 || abs(angle)<0.000001{return .identity}
            let s=sin(angle*0.5)/m
            return .init(x:axis.x*s,y:axis.y*s,z:axis.z*s,w:cos(angle*0.5))
        }
        var components:[Float] {[x,y,z,w]}
    }
    struct Pose:Equatable {
        var position:SIMD3<Float>
        var rotation:Quaternion
        var scale:SIMD3<Float>
        static let identity=Pose(position:.zero,rotation:.identity,scale:SIMD3(1,1,1))
        static func interpolate(_ a:Pose,_ b:Pose,_ t:Float)->Pose {
            let f=max(0,min(1,t))
            return Pose(position:a.position+(b.position-a.position)*f,
                        rotation:.slerp(a.rotation,b.rotation,f),
                        scale:a.scale+(b.scale-a.scale)*f)
        }
    }
    struct Bone {
        let nodeIndex:Int
        let name:String
        let parent:Int  // index in bones, -1 for authored imported parent
        let base:Pose
    }
    struct Track {
        let bone:Int
        let kind:Int  // 0 translation, 1 rotation, 2 scale
        let times:[Float]
        let values:[Float]
        let width:Int
        let step:Bool
        func value(_ t:Float)->[Float] {
            let n=times.count
            if n==0{return []}
            var lo=0,hi=n-1
            if t<=times[0] {hi=0}
            else if t>=times[n-1]{lo=hi}
            else {
                while hi-lo>1 {
                    let mid=(lo+hi)/2
                    if times[mid]<=t {lo=mid} else {hi=mid}
                }
            }
            let f:Float=lo==hi || step ? 0 :
                (t-times[lo])/max(0.00001,times[hi]-times[lo])
            if kind==1 {
                let a=Quaternion(x:values[4*lo],y:values[4*lo+1],z:values[4*lo+2],w:values[4*lo+3])
                let b=Quaternion(x:values[4*hi],y:values[4*hi+1],z:values[4*hi+2],w:values[4*hi+3])
                return Quaternion.slerp(a,b,f).components
            }
            var out=[Float]()
            for j in 0..<width {
                let start=values[lo*width+j]
                let end=values[hi*width+j]
                out.append(start*(1-f)+end*f)
            }
            return out
        }
    }
    struct Clip {
        let name:String
        let duration:Float
        let tracks:[Track]
    }
    struct Rig {
        let bones:[Bone]
        let idle:Clip
        let walk:Clip
        let names:[String:Int]
        func sample(walk moving:Bool,time raw:Float)->[Pose] {
            let clip=moving ? walk : idle
            let t=max(0,min(clip.duration,raw))
            var output=bones.map{$0.base}
            for tr in clip.tracks {
                let val=tr.value(t)
                if tr.kind==0 {output[tr.bone].position=SIMD3(val[0],val[1],val[2])}
                else if tr.kind==1 {output[tr.bone].rotation=Quaternion(x:val[0],y:val[1],z:val[2],w:val[3])}
                else {output[tr.bone].scale=SIMD3(val[0],val[1],val[2])}
            }
            return output
        }
        func named(_ suffix:String)->Int? {
            let ids=bones.indices.filter{bones[$0].name.hasSuffix(suffix)}
            return ids.count==1 ? ids[0] : nil
        }
    }
    enum Invalid:Error,LocalizedError {
        case header,document,track,bone,accessor,clips
        var errorDescription:String? {"H55: oryginalny rig NPC525 idle/walk nie ma poprawnych danych glTF (\(self))."}
    }
    typealias Dict=[String:Any]
    private static func dict(_ a:Any?)->Dict? {a as? Dict}
    private static func array(_ a:Any?)->[Dict] {(a as? [Any] ?? []).compactMap{dict($0)}}
    private static func num(_ a:Any?)->Int? {(a as? NSNumber)?.intValue}
    private static func str(_ a:Any?)->String? {a as? String}
    private static func word(_ data:Data,_ i:Int)->UInt32 {
        UInt32(data[i]) | (UInt32(data[i+1])<<8) | (UInt32(data[i+2])<<16) | (UInt32(data[i+3])<<24)
    }
    static func load(_ url:URL) throws -> Rig {
        let f=try FileHandle(forReadingFrom:url)
        defer {try? f.close()}
        let header=try f.read(upToCount:20) ?? Data()
        guard header.count==20,word(header,0)==0x46546c67,word(header,4)==2,
              word(header,16)==0x4e4f534a else{throw Invalid.header}
        let jsonCount=Int(word(header,12))
        guard jsonCount>0,jsonCount<32*1024*1024 else{throw Invalid.header}
        let jsonBytes=try f.read(upToCount:jsonCount) ?? Data()
        let chunk=try f.read(upToCount:8) ?? Data()
        guard jsonBytes.count==jsonCount,chunk.count==8,word(chunk,4)==0x004e4942,
              let doc=try JSONSerialization.jsonObject(with:jsonBytes) as? Dict else{
            throw Invalid.document
        }
        let binStart=UInt64(jsonCount+28),binSize=UInt64(word(chunk,0))
        let fileSize=(try FileManager.default.attributesOfItem(atPath:url.path)[.size] as? NSNumber)?.uint64Value ?? 0
        guard binStart+binSize<=fileSize,
              fileSize==UInt64(word(header,8)) else{throw Invalid.header}
        let nodes=array(doc["nodes"]),views=array(doc["bufferViews"]),accessors=array(doc["accessors"]),clips=array(doc["animations"])
        guard nodes.count>2000,clips.count>50 else{throw Invalid.document}
        let idleName="NPC525_standing_relax.001",walkName="NPC525_walk.003"
        let sourceClips=clips.filter{[idleName,walkName].contains(str($0["name"]) ?? "")}
        guard sourceClips.count==2 else{throw Invalid.clips}
        let idleClip=sourceClips.first{str($0["name"])==idleName}!
        let walkClip=sourceClips.first{str($0["name"])==walkName}!
        func animatedIDs(_ clip:Dict) throws -> Set<Int> {
            var ids=Set<Int>()
            for c in array(clip["channels"]) {
                guard let t=dict(c["target"]),let id=num(t["node"]),
                      id>=0,id<nodes.count,
                      (str(nodes[id]["name"]) ?? "").hasPrefix("HL_Import_2023_space_suit_3d_model_ca_o_c_animacji_-_najleps_") else{throw Invalid.bone}
                ids.insert(id)
            }
            return ids
        }
        let indexes=try animatedIDs(idleClip).sorted()
        guard indexes.count==80,try animatedIDs(walkClip)==Set(indexes) else{throw Invalid.bone}
        var idMap=[Int:Int]();for (i,id) in indexes.enumerated(){idMap[id]=i}
        var parents=[Int](repeating:-1,count:nodes.count)
        for (n,node) in nodes.enumerated() {
            for any in node["children"] as? [Int] ?? [] {
                guard any>=0,any<nodes.count,parents[any]<0 else{throw Invalid.bone}
                parents[any]=n
            }
        }
        func vec3(_ node:Dict,_ key:String,_ defaultValue:SIMD3<Float>)->SIMD3<Float> {
            guard let a=node[key] as? [NSNumber],a.count==3 else{return defaultValue}
            return SIMD3(a[0].floatValue,a[1].floatValue,a[2].floatValue)
        }
        var bones=[Bone]();var names=[String:Int]()
        for id in indexes {
            let node=nodes[id]
            guard node["matrix"]==nil,let name=str(node["name"]),names[name]==nil else{throw Invalid.bone}
            let q:[NSNumber]=node["rotation"] as? [NSNumber] ?? [0,0,0,1]
            guard q.count==4 else{throw Invalid.bone}
            let b=Bone(nodeIndex:id,name:name,parent:idMap[parents[id]] ?? -1,
                base:Pose(position:vec3(node,"translation",.zero),
                          rotation:Quaternion(x:q[0].floatValue,y:q[1].floatValue,z:q[2].floatValue,w:q[3].floatValue).normalized(),
                          scale:vec3(node,"scale",SIMD3(1,1,1))))
            names[name]=bones.count;bones.append(b)
        }
        var cache=[Int:[Float]]()
        func values(_ index:Int,_ width:Int) throws ->[Float] {
            guard index>=0,index<accessors.count else{throw Invalid.accessor}
            if let cached=cache[index] {return cached}
            let acc=accessors[index]
            guard num(acc["componentType"])==5126,
                  str(acc["type"])==(width==1 ? "SCALAR" : width==3 ? "VEC3" : "VEC4"),
                  acc["sparse"]==nil,acc["normalized"]==nil,
                  let count=num(acc["count"]),count>=1,count<=5000,
                  let vi=num(acc["bufferView"]),vi>=0,vi<views.count else{throw Invalid.accessor}
            let view=views[vi],base=num(view["byteOffset"]) ?? 0,offset=num(acc["byteOffset"]) ?? 0
            let length=num(view["byteLength"]) ?? -1,stride=num(view["byteStride"]) ?? width*4
            guard num(view["buffer"])==0,base>=0,offset>=0,length>=0,
                  stride>=width*4,stride<=1024,
                  Int64(offset)+Int64(count-1)*Int64(stride)+Int64(width*4)<=Int64(length),
                  UInt64(base)+UInt64(length)<=binSize else{throw Invalid.accessor}
            let bytesNeeded=(count-1)*stride+width*4
            try f.seek(toOffset:binStart+UInt64(base+offset))
            let raw=try f.read(upToCount:bytesNeeded) ?? Data()
            guard raw.count==bytesNeeded else{throw Invalid.accessor}
            var result=[Float]();result.reserveCapacity(count*width)
            for i in 0..<count {for j in 0..<width {
                let n=Float(bitPattern:word(raw,i*stride+j*4))
                guard n.isFinite else{throw Invalid.accessor}
                result.append(n)
            }}
            cache[index]=result
            return result
        }
        func parsedClip(_ clip:Dict)throws->Clip {
            let samplers=array(clip["samplers"]),channels=array(clip["channels"])
            guard samplers.count==240,channels.count==240 else{throw Invalid.track}
            var result=[Track](),duration:Float=0
            var seen=Set<String>()
            for ch in channels {
                guard let target=dict(ch["target"]),let id=num(target["node"]),
                      let bone=idMap[id],let kindName=str(target["path"]),
                      let si=num(ch["sampler"]),si>=0,si<samplers.count else{throw Invalid.track}
                let kind:Int
                switch kindName {case "translation":kind=0;case "rotation":kind=1;case "scale":kind=2;default:throw Invalid.track}
                let key="\(id)_\(kind)"
                guard seen.insert(key).inserted else{throw Invalid.track}
                let s=samplers[si],interpolation=str(s["interpolation"]) ?? "LINEAR"
                guard interpolation=="STEP" || interpolation=="LINEAR",
                      let ti=num(s["input"]),let vi=num(s["output"]) else{throw Invalid.track}
                let width=kind==1 ? 4 : 3
                let ts=try values(ti,1),vs=try values(vi,width)
                guard ts.count>=2,ts.count*width==vs.count else{throw Invalid.track}
                for k in 1..<ts.count where ts[k]<=ts[k-1] {throw Invalid.track}
                duration=max(duration,ts.last!)
                result.append(Track(bone:bone,kind:kind,times:ts,values:vs,width:width,step:interpolation=="STEP"))
            }
            guard seen.count==240,duration>0 else{throw Invalid.track}
            return Clip(name:str(clip["name"]) ?? "",duration:duration,tracks:result)
        }
        let idle=try parsedClip(idleClip),walk=try parsedClip(walkClip)
        return Rig(bones:bones,idle:idle,walk:walk,names:names)
    }
}
