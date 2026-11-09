import Foundation

/// H12: a small, read-only sampler of the *original* H55 GLB animation
/// accessors. GLTFKit2 still owns geometry/materials/skins; this reads only
/// the six source machinery clips and optional data-only metadata loops.
/// Never duplicates the 126MB BIN or invents keyframes / drone geometry.
enum H55H12Tracks580 {
    typealias D=[String:Any]
    enum Failure:Error {case header,document,clip,channel,accessor,unsupported}
    enum Path:String {case translation,rotation,scale,weights}

    struct Track {
        let nodeName:String
        let path:Path
        let times:[Float]
        let values:[Float]
        let width:Int
        let step:Bool

        /// Compatibility for one-off analysis and deterministic tests.
        /// The per-frame SceneKit path uses the overload below, reusing
        /// one 64-float buffer for all H51/H39/arm/crane/morph channels.
        func sample(_ t:Float)->[Float] {
            var result=[Float](repeating:0,count:width)
            sample(t,into:&result)
            return result
        }
        /// No per-channel heap allocation in the 60/120 Hz H12 render loop.
        /// Parser restricts all valid source channels to at most 64 floats.
        func sample(_ t:Float,into output:inout [Float]) {
            precondition(output.count>=width && times.count>0)
            var lo=0,hi=times.count-1
            if t<=times[0] {hi=0}
            else if t>=times[hi] {lo=hi}
            else {
                while hi-lo>1 {
                    let mid=(hi+lo)/2
                    if times[mid]<=t {lo=mid} else {hi=mid}
                }
            }
            let f=lo==hi || step ? Float(0) :
                (t-times[lo])/max(0.00001,times[hi]-times[lo])
            let i=lo*width,j=hi*width
            if path == .rotation {
                // Original H55Renderer.Slerp: shortest-arc quaternion with
                // normalized interpolation near coincident rotations.
                let x0=values[i],y0=values[i+1],z0=values[i+2],w0=values[i+3]
                var x1=values[j],y1=values[j+1],z1=values[j+2],w1=values[j+3]
                var dot=x0*x1+y0*y1+z0*z1+w0*w1
                if dot<0 {dot = -dot;x1 = -x1;y1 = -y1;z1 = -z1;w1 = -w1}
                let a:Float,b:Float
                if dot>0.9995 {
                    a=1-f;b=f
                } else {
                    let angle=acos(max(-1,min(1,dot)))
                    let inv=1/max(0.000001,sin(angle))
                    a=sin((1-f)*angle)*inv
                    b=sin(f*angle)*inv
                }
                let x=x0*a+x1*b,y=y0*a+y1*b,z=z0*a+z1*b,w=w0*a+w1*b
                let n=max(0.000001,sqrt(x*x+y*y+z*z+w*w))
                output[0]=x/n;output[1]=y/n;output[2]=z/n;output[3]=w/n
                return
            }
            for k in 0..<width {
                output[k]=values[i+k]*(1-f)+values[j+k]*f
            }
        }
    }

    struct Clip {
        let name:String
        let duration:Float
        let tracks:[Track]
    }
    struct Library {
        let clips:[String:Clip]
        let durations:[String:Float]
        let morphIdle:String?
        let imported:[H55H12Timeline580.Loop]
        let metadata:[H55H12Timeline580.Loop]
        var animatedNodeNames:Set<String> {
            Set(clips.values.flatMap{$0.tracks.map{$0.nodeName}})
        }
        func frame(_ elapsed:Float)->[H55H12Timeline580.Sample] {
            H55H12Timeline580.sample(time:elapsed,durations:durations,
                                    idleMorph:morphIdle,
                                    imported:imported,metadata:metadata)
        }
    }
    private static func list(_ v:Any?)->[D] {(v as? [Any] ?? []).compactMap{$0 as? D}}
    private static func object(_ v:Any?)->D {v as? D ?? [:]}
    private static func int(_ v:Any?)->Int? {(v as? NSNumber)?.intValue}
    private static func float(_ v:Any?)->Float? {(v as? NSNumber)?.floatValue}
    private static func str(_ v:Any?)->String? {v as? String}
    private static func word(_ a:Data,_ i:Int)->UInt32 {
        UInt32(a[i]) | UInt32(a[i+1])<<8 |
        UInt32(a[i+2])<<16 | UInt32(a[i+3])<<24
    }
    private struct Accessor {
        let kind:String
        let count:Int
        let floats:[Float]
    }

    /// The user deferred autonomous H71 drones. When excluded, neither
    /// their imported GLB loops nor their metadata loops may start
    /// incidentally while machinery H39–H51 continues normally.
    static func load(_ url:URL,
                     excludeImportedDroneRoots:Bool=false)throws->Library {
        let file=try FileHandle(forReadingFrom:url)
        defer {try? file.close()}
        let header=try file.read(upToCount:20) ?? Data()
        guard header.count==20,word(header,0)==0x46546c67,
              word(header,4)==2,word(header,16)==0x4e4f534a
        else{throw Failure.header}
        let jsonSize=Int(word(header,12))
        guard jsonSize>0,jsonSize<32*1024*1024 else{throw Failure.header}
        let raw=try file.read(upToCount:jsonSize) ?? Data()
        let binHeader=try file.read(upToCount:8) ?? Data()
        guard raw.count==jsonSize,binHeader.count==8,
              word(binHeader,4)==0x004e4942,
              let doc=try JSONSerialization.jsonObject(with:raw) as? D,
              let size=(try FileManager.default.attributesOfItem(atPath:url.path)[.size] as? NSNumber)?.uint64Value,
              size==UInt64(word(header,8)),UInt64(jsonSize)+28+UInt64(word(binHeader,0))==size
        else{throw Failure.document}
        let binOffset=UInt64(jsonSize+28),binLength=UInt64(word(binHeader,0))
        let nodes=list(doc["nodes"]),animations=list(doc["animations"])
        let views=list(doc["bufferViews"]),accessors=list(doc["accessors"])
        guard !nodes.isEmpty,!animations.isEmpty else{throw Failure.document}
        var byName=[String:D]()
        for a in animations {
            guard let name=str(a["name"]),!name.isEmpty,
                  byName.updateValue(a,forKey:name)==nil else{throw Failure.clip}
        }
        let expected=Set(H55H12Timeline580.obligatory)
        guard expected.isSubset(of:Set(byName.keys)) else{throw Failure.clip}
        let idleNames=byName.keys.filter{$0.hasSuffix(H55H12Timeline580.idleMorphSuffix)}
        guard idleNames.count<=1 else{throw Failure.clip}
        let idle=idleNames.first
        // Windows HangarMetadata443.FromDocument / AddLoop:
        // actual glTF animation extras AND node extras of ACTIVE scene nodes,
        // one data-only known clip each, speed within [0.1,4], at most 64.
        // Reject H51/H70/NPC and airlock/autodocking overrides.
        var loops=[H55H12Timeline580.Loop]()
        var metadataAdded=Set<String>()
        func addMetadata(_ name:String,_ speed:Float) {
            guard byName[name] != nil,
                  H55H12Timeline580.eligibleMetadata(name),
                  speed.isFinite,speed>=0.1,speed<=4,
                  metadataAdded.insert(name).inserted,
                  loops.count<64 else{return}
            loops.append(.init(name,speed))
        }
        for animation in animations {
            guard let name=str(animation["name"]),
                  (object(animation["extras"])["ANIMATION_LOOP"] as? Bool)==true
            else{continue}
            let speed=float(object(animation["extras"])["ANIMATION_SPEED"]) ?? 1
            addMetadata(name,speed)
        }
        // Windows H55Renderer.ConfigureImportedAutoLoops462:
        // a single autonomous clip per HL_Import_ root, never the NPC,
        // H51, H70, explicitly declared metadata loop or idle morph.
        // Prefer LOOP (10) then IDLE (5), keep the first on a tie.
        var parents=[Int](repeating:-1,count:nodes.count)
        for (parent,node) in nodes.enumerated() {
            for child in (node["children"] as? [NSNumber] ?? []) {
                let id=child.intValue
                guard id>=0,id<nodes.count,parents[id]<0,id != parent else {
                    throw Failure.document
                }
                parents[id]=parent
            }
        }
        // PC v443 enumerates only nodes reachable from doc.scenes[scene].
        // A bounded queue and a seen set prevent malformed cyclic graphs
        // from scheduling infinite traversal or activating orphan clips.
        let scenes=list(doc["scenes"])
        let selectedScene=int(doc["scene"]) ?? 0
        if scenes.indices.contains(selectedScene) {
            var active=Set<Int>(),queue=[Int](),head=0
            for root in (scenes[selectedScene]["nodes"] as? [NSNumber] ?? []) {
                let id=root.intValue
                if nodes.indices.contains(id),active.insert(id).inserted {
                    queue.append(id)
                }
            }
            while head<queue.count {
                let id=queue[head];head+=1
                for child in (nodes[id]["children"] as? [NSNumber] ?? []) {
                    let next=child.intValue
                    if nodes.indices.contains(next),
                       active.insert(next).inserted {
                        queue.append(next)
                    }
                }
            }
            // Match original C# node index enumeration, not BFS order.
            for id in nodes.indices where active.contains(id) {
                let extra=object(nodes[id]["extras"])
                let speed=float(extra["ANIMATION_SPEED"]) ?? 1
                if let clip=str(extra["ANIMATION_LOOP"]) {
                    addMetadata(clip,speed)
                } else if let names=extra["ANIMATION_LOOP"] as? [String] {
                    for clip in names {addMetadata(clip,speed)}
                }
            }
        }
        func importRoot(_ id:Int)->Int {
            var ancestor=id,root = -1,steps=0
            while ancestor>=0 && ancestor<nodes.count && steps<=nodes.count {
                if (str(nodes[ancestor]["name"]) ?? "")
                    .lowercased().hasPrefix("hl_import_") {
                    root=ancestor
                }
                ancestor=parents[ancestor]
                steps+=1
            }
            return steps>nodes.count ? -1 : root
        }
        func isDroneImported(_ id:Int)->Bool {
            let root=importRoot(id)
            guard root>=0 else{return false}
            let extra=object(nodes[root]["extras"])
            let origin=(str(extra["hangarLabImportName"]) ?? "").lowercased()
            let rootName=(str(nodes[root]["name"]) ?? "").lowercased()
            return origin.contains("drone") || origin.contains("dron") ||
                   rootName.contains("drone") || rootName.contains("dron")
        }
        // Keep any unrelated H39/ramps/lamps metadata, but never activate
        // the deferred H71 imported drone tracks (even by metadata).
        if excludeImportedDroneRoots {
            loops.removeAll { loop in
                guard let animation=byName[loop.name] else{return false}
                let channels=list(animation["channels"])
                return channels.contains { ch in
                    guard let id=int(object(ch["target"])["node"]) else {
                        return false
                    }
                    return isDroneImported(id)
                }
            }
        }
        let metadataNames=Set(loops.map{$0.name})
        var blockedIdleNodes=Set<Int>()
        if let idle,let authored=byName[idle] {
            for ch in list(authored["channels"]) {
                if let id=int(object(ch["target"])["node"]) {
                    blockedIdleNodes.insert(id)
                }
            }
        }
        var importedBest=[Int:(name:String,score:Int)]()
        for authored in animations {
            guard let name=str(authored["name"]),!name.isEmpty,
                  H55H12Timeline580.eligibleMetadata(name),
                  !metadataNames.contains(name),
                  name != idle,!expected.contains(name),
                  !(name.uppercased().hasPrefix("NPC525_")),
                  !(name.uppercased().hasPrefix("H51_")) else{continue}
            let channels=list(authored["channels"])
            guard !channels.isEmpty else{continue}
            var root:Int?,valid=true
            for ch in channels {
                guard let node=int(object(ch["target"])["node"]),
                      node>=0,node<nodes.count,
                      !blockedIdleNodes.contains(node) else {
                    valid=false;break
                }
                let importedRoot=importRoot(node)
                if importedRoot<0 || (root != nil && root != importedRoot) {
                    valid=false;break
                }
                root=importedRoot
            }
            guard valid,let root else{continue}
            if excludeImportedDroneRoots && isDroneImported(root) {continue}
            let upper=name.uppercased()
            let score=(upper.contains("LOOP") ? 10 : 0)
                +(upper.contains("IDLE") ? 5 : 0)
            if importedBest[root] == nil || score>importedBest[root]!.score {
                importedBest[root]=(name,score)
            }
        }
        let imported=importedBest.keys.sorted().compactMap {
            importedBest[$0].map{H55H12Timeline580.Loop($0.name)}
        }
        let required=expected.union(idle.map{[$0]} ?? [])
        let selected=required.union(loops.map{$0.name})
            .union(imported.map{$0.name})
        var cache=[Int:Accessor]()
        var sampleCount=0
        func accessor(_ index:Int)throws->Accessor {
            if let cached=cache[index]{return cached}
            guard index>=0,index<accessors.count else{throw Failure.accessor}
            let a=accessors[index]
            guard int(a["componentType"])==5126,a["sparse"]==nil,
                  let kind=str(a["type"]),
                  ["SCALAR","VEC2","VEC3","VEC4"].contains(kind),
                  let count=int(a["count"]),count>0,count<=150_000,
                  let vId=int(a["bufferView"]),vId>=0,vId<views.count else {
                throw Failure.unsupported
            }
            let width=kind=="SCALAR" ? 1 : kind=="VEC2" ? 2 :
                      kind=="VEC3" ? 3 : 4
            guard sampleCount<=3_000_000-count*width else{throw Failure.accessor}
            sampleCount+=count*width
            let v=views[vId],base=int(v["byteOffset"]) ?? 0,
                vo=int(a["byteOffset"]) ?? 0,
                length=int(v["byteLength"]) ?? -1
            let stride=int(v["byteStride"]) ?? width*4
            guard int(v["buffer"]) == 0,base>=0,vo>=0,length>=0,
                  stride>=width*4,stride<=1024,
                  Int64(vo)+Int64(count-1)*Int64(stride)+Int64(width*4)<=Int64(length),
                  UInt64(base)+UInt64(length)<=binLength else{throw Failure.accessor}
            let len=(count-1)*stride+width*4
            try file.seek(toOffset:binOffset+UInt64(base+vo))
            let bytes=try file.read(upToCount:len) ?? Data()
            guard bytes.count==len else{throw Failure.accessor}
            var floats=[Float]()
            floats.reserveCapacity(count*width)
            for i in 0..<count {
                for k in 0..<width {
                    let f=Float(bitPattern:word(bytes,i*stride+k*4))
                    guard f.isFinite else{throw Failure.accessor}
                    floats.append(f)
                }
            }
            let result=Accessor(kind:kind,count:count,floats:floats)
            cache[index]=result
            return result
        }
        var parsed=[String:Clip]()
        for name in selected.sorted() {
            guard let anim=byName[name] else{throw Failure.clip}
            let channels=list(anim["channels"]),samplers=list(anim["samplers"])
            guard !channels.isEmpty,channels.count<=1460 else{throw Failure.clip}
            var tracks=[Track](),maxDuration:Float=0
            var occupied=Set<String>()
            for channel in channels {
                let target=object(channel["target"])
                guard let id=int(target["node"]),id>=0,id<nodes.count,
                      let nodeName=str(nodes[id]["name"]),!nodeName.isEmpty,
                      let namePath=str(target["path"]),
                      let path=Path(rawValue:namePath),
                      let samplerId=int(channel["sampler"]),
                      samplerId>=0,samplerId<samplers.count else {
                    throw Failure.channel
                }
                let key="\(id):\(path.rawValue)"
                guard occupied.insert(key).inserted else{throw Failure.channel}
                let sampler=samplers[samplerId]
                let mode=str(sampler["interpolation"]) ?? "LINEAR"
                guard mode=="LINEAR" || mode=="STEP",
                      let input=int(sampler["input"]),let output=int(sampler["output"])
                else{throw Failure.unsupported}
                let ti=try accessor(input),v=try accessor(output)
                guard ti.kind=="SCALAR",ti.count>=2,ti.count<=20000,
                      ti.floats.first!>=0,v.count>=ti.count,
                      v.count%ti.count==0 else{throw Failure.accessor}
                let width=v.floats.count/ti.count
                guard (path == .rotation && width==4 && v.kind=="VEC4") ||
                      ((path == .translation || path == .scale) &&
                       width==3 && v.kind=="VEC3") ||
                      (path == .weights && v.kind=="SCALAR" && width>=1 && width<=64)
                else{throw Failure.channel}
                for i in 1..<ti.floats.count {
                    if ti.floats[i]<=ti.floats[i-1]{throw Failure.accessor}
                }
                maxDuration=max(maxDuration,ti.floats.last!)
                tracks.append(Track(nodeName:nodeName,path:path,
                          times:ti.floats,values:v.floats,width:width,
                          step:mode=="STEP"))
            }
            guard maxDuration>0 else{throw Failure.clip}
            parsed[name]=Clip(name:name,duration:maxDuration,tracks:tracks)
        }
        // Anchor the source authored timings; never invent replacement keys
        // if a different or corrupted H55 GLB was imported.
        let sourceDurations:[String:Float]=[
            H55H12Timeline580.docking:32,
            H55H12Timeline580.service:96,
            H55H12Timeline580.turbines:2.4,
            H55H12Timeline580.arms:96,
            H55H12Timeline580.lighting:20,
            H55H12Timeline580.crane:16
        ]
        for (name,expected) in sourceDurations {
            guard let actual=parsed[name]?.duration,
                  abs(actual-expected)<0.1 else{throw Failure.clip}
        }
        return Library(clips:parsed,
            durations:parsed.mapValues{$0.duration},
            morphIdle:idle,imported:imported,metadata:loops)
    }
}
