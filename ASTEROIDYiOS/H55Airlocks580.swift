import Foundation

/// H07: literal PC v580 Windows/src/H55Renderer.cs H72AirlockController393.
/// No legacy hangar and no SceneKit raycast is used for door collision.
struct H55AirlockController580 {
    static let clipNames = [
        "H70_HANGAR_AIRLOCK_SLIDING_DOORS_8S",
        "H70_WORKSHOP_AIRLOCK_SLIDING_DOORS_8S"
    ]
    static let leafNames = [
        ["H70_HANGAR_AIRLOCK_LEFT", "H70_HANGAR_AIRLOCK_RIGHT"],
        ["H70_WORKSHOP_AIRLOCK_LEFT", "H70_WORKSHOP_AIRLOCK_RIGHT"]
    ]
    private static let gateX:[Float] = [24.36,30.46]
    private static let gateZ:Float = 7.15
    private(set) var openness:[Float] = [0,0]
    private(set) var playerHeld:[Bool] = [false,false]
    private(set) var npcHeld:[Bool] = [false,false]

    private static func ellipse(_ dx:Float,_ dz:Float,
                                _ rx:Float,_ rz:Float)->Float {
        dx*dx/(rx*rx)+dz*dz/(rz*rz)
    }

    static func clipTime(for amount:Float)->Float {
        1.85 - max(0,min(1,amount))
    }

    /// Source v544 independent sensors: 6.6 x 4.4 enter, 8.3 x 5.6 leave.
    /// Source rise .85 s and fall 1.15 s; simulation dt limited to .1 s.
    mutating func step(playerX:Float,playerZ:Float,playerPresent:Bool,
                       npcX:Float,npcZ:Float,npcPresent:Bool,dt raw:Float) {
        let dt=max(0,min(0.1,raw))
        for i in 0..<2 {
            let dx=playerX-Self.gateX[i],dz=playerZ-Self.gateZ
            if !playerPresent {playerHeld[i]=false}
            else if !playerHeld[i] && Self.ellipse(dx,dz,6.6,4.4)<=1 {
                playerHeld[i]=true
            } else if playerHeld[i] && Self.ellipse(dx,dz,8.3,5.6)>1 {
                playerHeld[i]=false
            }
            let nx=npcX-Self.gateX[i],nz=npcZ-Self.gateZ
            if !npcPresent {npcHeld[i]=false}
            else if !npcHeld[i] && Self.ellipse(nx,nz,6.6,4.4)<=1 {
                npcHeld[i]=true
            } else if npcHeld[i] && Self.ellipse(nx,nz,8.3,5.6)>1 {
                npcHeld[i]=false
            }
            let target:Float = (playerHeld[i] || npcHeld[i]) ? 1 : 0
            if target>openness[i] {openness[i]=min(1,openness[i]+dt/0.85)}
            else if target<openness[i] {openness[i]=max(0,openness[i]-dt/1.15)}
        }
    }

    /// Exactly H72AirlockController393.BlocksNpc544: shut if open <.90.
    /// In PC v580 only NPC uses this physical barrier; H07 iOS also uses
    /// the SAME checked boundary for the player (documented adaptation).
    func blockingGate(fromX ax:Float,fromZ az:Float,
                      toX bx:Float,toZ bz:Float)->Int? {
        for i in 0..<2 {
            if openness[i]>=0.90 {continue}
            let x=Self.gateX[i]
            if max(abs(az-Self.gateZ),abs(bz-Self.gateZ))>2.15 {continue}
            let low=min(ax,bx),high=max(ax,bx)
            if low<=x+0.30 && high>=x-0.30 {return i}
        }
        return nil
    }
}

/// H07: source GLB keyframes, never a guessed sine or SceneKit repeat loop.
/// Two H70 clips contain ONLY two translation tracks each. Runtime reads
/// their tiny accessor ranges from the already authenticated 126MB GLB.
/// The full BIN remains untouched and is not loaded twice into RAM.
enum H55AirlockTracks580 {
    typealias D=[String:Any]
    enum Invalid:Error {case header, structure, clips, accessor, time}

    struct Track {
        let nodeName:String
        let times:[Float]
        let points:[SIMD3<Float>]

        /// Same LINEAR interval search as PC v580 AnimateAirlocks392.
        func sample(_ time:Float)->SIMD3<Float> {
            if time<=times[0] {return points[0]}
            if time>=times[times.count-1] {return points[points.count-1]}
            var lo=0,hi=times.count-1
            while hi-lo>1 {
                let mid=(lo+hi)/2
                if times[mid]<=time {lo=mid}
                else {hi=mid}
            }
            let f=(time-times[lo])/(times[hi]-times[lo])
            return points[lo]*(1-f)+points[hi]*f
        }
    }
    struct SceneKeys {
        let nodes:[String:Track]
        func sample(leaf:String,time:Float)->SIMD3<Float>? {
            nodes[leaf]?.sample(time)
        }
    }

    private static func word(_ bytes:Data,_ i:Int)->UInt32 {
        UInt32(bytes[i]) | (UInt32(bytes[i+1])<<8) |
        (UInt32(bytes[i+2])<<16) | (UInt32(bytes[i+3])<<24)
    }
    private static func list(_ value:Any?)->[D] {
        (value as? [Any] ?? []).compactMap{$0 as? D}
    }
    private static func number(_ value:Any?)->Int? {
        (value as? NSNumber)?.intValue
    }
    private static func name(_ value:Any?)->String? {
        value as? String
    }

    static func load(from url:URL)throws->SceneKeys {
        let attributes=try FileManager.default.attributesOfItem(atPath:url.path)
        guard let size=(attributes[.size] as? NSNumber)?.uint64Value else {
            throw Invalid.header
        }
        let file=try FileHandle(forReadingFrom:url)
        defer {try? file.close()}
        let header=try file.read(upToCount:20) ?? Data()
        guard header.count==20,word(header,0)==0x46546C67,
              word(header,4)==2,UInt64(word(header,8))==size,
              word(header,16)==0x4E4F534A else{throw Invalid.header}
        let jsonLen=Int(word(header,12))
        guard jsonLen>0,jsonLen<32*1024*1024,
              UInt64(jsonLen)+28<=size else{throw Invalid.structure}
        let encoded=try file.read(upToCount:jsonLen) ?? Data()
        let binHeader=try file.read(upToCount:8) ?? Data()
        guard encoded.count==jsonLen,binHeader.count==8,
              word(binHeader,4)==0x004E4942,
              UInt64(jsonLen)+28+UInt64(word(binHeader,0))==size,
              let json=try JSONSerialization.jsonObject(with:encoded) as? D
        else{throw Invalid.structure}
        let binStart=UInt64(jsonLen+28)
        let binLength=UInt64(word(binHeader,0))
        let accessors=list(json["accessors"]), views=list(json["bufferViews"])
        let nodes=list(json["nodes"]),clips=list(json["animations"])
        guard nodes.count>1203,clips.count>=2 else{throw Invalid.structure}

        func accessor(_ index:Int,_ components:Int)throws->[Float] {
            guard index>=0,index<accessors.count else{throw Invalid.accessor}
            let a=accessors[index]
            guard number(a["componentType"])==5126,
                  name(a["type"]) == (components==1 ? "SCALAR" : "VEC3"),
                  a["sparse"] == nil, a["normalized"] == nil,
                  let count=number(a["count"]),count>=2,count<=256,
                  let viewIndex=number(a["bufferView"]),
                  viewIndex>=0,viewIndex<views.count else {
                throw Invalid.accessor
            }
            let v=views[viewIndex], width=components*4
            guard number(v["buffer"]) == 0,
                  let base=number(v["byteOffset"]) ?? Optional(0),
                  let offset=number(a["byteOffset"]) ?? Optional(0),
                  let viewLength=number(v["byteLength"]),
                  base>=0,offset>=0,viewLength>=0 else{
                throw Invalid.accessor
            }
            let stride=number(v["byteStride"]) ?? width
            guard stride>=width,stride<=1024,
                  Int64(offset)+Int64(count-1)*Int64(stride)+Int64(width)<=Int64(viewLength),
                  UInt64(base)+UInt64(viewLength)<=binLength else{
                throw Invalid.accessor
            }
            let readLength=(count-1)*stride+width
            try file.seek(toOffset:binStart+UInt64(base+offset))
            let raw=try file.read(upToCount:readLength) ?? Data()
            guard raw.count==readLength else{throw Invalid.accessor}
            var out=[Float]()
            out.reserveCapacity(count*components)
            for i in 0..<count {
                for c in 0..<components {
                    let v=Float(bitPattern:word(raw,i*stride+c*4))
                    guard v.isFinite else{throw Invalid.accessor}
                    out.append(v)
                }
            }
            return out
        }

        var result=[String:Track]()
        for gate in 0..<2 {
            let clipName=H55AirlockController580.clipNames[gate]
            let matches=clips.filter{name($0["name"])==clipName}
            guard matches.count==1,
                  let channels=matches[0]["channels"] as? [D],
                  let samplers=matches[0]["samplers"] as? [D],
                  channels.count==2 else{throw Invalid.clips}
            let expected=Set(H55AirlockController580.leafNames[gate])
            var found=Set<String>()
            for ch in channels {
                guard let target=ch["target"] as? D,
                      name(target["path"])=="translation",
                      let nodeIndex=number(target["node"]),
                      nodeIndex>=0,nodeIndex<nodes.count,
                      let leaf=name(nodes[nodeIndex]["name"]),
                      expected.contains(leaf),found.insert(leaf).inserted,
                      let sampleIndex=number(ch["sampler"]),
                      sampleIndex>=0,sampleIndex<samplers.count
                else{throw Invalid.clips}
                let s=samplers[sampleIndex]
                guard name(s["interpolation"]) == nil ||
                      name(s["interpolation"])=="LINEAR",
                      let ti=number(s["input"]),
                      let vi=number(s["output"]) else{throw Invalid.clips}
                let times=try accessor(ti,1)
                let floats=try accessor(vi,3)
                guard times.count*3==floats.count,
                      times.first!<=0.85,times.last!>=1.85 else{
                    throw Invalid.time
                }
                for i in 1..<times.count {
                    if times[i]<=times[i-1] {throw Invalid.time}
                }
                var points=[SIMD3<Float>]()
                for k in 0..<times.count {
                    points.append(SIMD3(floats[k*3],floats[k*3+1],floats[k*3+2]))
                }
                result[leaf]=Track(nodeName:leaf,times:times,points:points)
            }
            guard found==expected else{throw Invalid.clips}
        }
        guard result.count==4 else{throw Invalid.clips}
        return SceneKeys(nodes:result)
    }
}
