import Foundation

/// H12 scope decision: H71 autonomous drones are postponed.
/// Keep the verified source implementation available for later reactivation;
/// do not initialize the graph or animate drones in normal H55 gameplay.
enum H55H12FeatureFlags580 {
    static let autonomousDronesEnabled=false
}

/// PC v580 H71DroneImports461.Select: ONLY the two explicitly imported
/// GLB prefab roots within 6m of the authored mechanic may become drones.
/// A third imported model remains static. Never create mesh substitutes.
enum H55DroneImports580 {
    struct Spawn:Equatable {
        let index:Int
        let name:String
        let prefab:String
        let x:Float
        let y:Float
        let z:Float
    }
    enum Error:Swift.Error {case glbHeader,document}
    private static func map(_ value:Any?)->[String:Any] {
        value as? [String:Any] ?? [:]
    }
    private static func list(_ value:Any?)->[Any] {value as? [Any] ?? []}
    private static func number(_ v:Any?)->Float {
        guard let n=v as? NSNumber else{return 0}
        return n.floatValue
    }
    private static func word(_ b:Data,_ i:Int)->UInt32 {
        UInt32(b[i]) | UInt32(b[i+1])<<8 |
        UInt32(b[i+2])<<16 | UInt32(b[i+3])<<24
    }
    /// Selection is pure and testable with the same original glTF nodes.
    static func select(from doc:[String:Any])->[Spawn] {
        let nodes=list(doc["nodes"]).map{map($0)}
        var mx:Float=10.194016,mz:Float=12.696275
        for n in nodes {
            let name=n["name"] as? String ?? ""
            guard name.range(of:"Mechanik_",options:.caseInsensitive) != nil,
                  n["mesh"] == nil else{continue}
            let m=list(n["matrix"])
            if m.count==16 {
                mx=number(m[12]);mz=number(m[14]);break
            }
        }
        var candidates=[(distance:Float,spawn:Spawn)]()
        for (i,n) in nodes.enumerated() {
            let extras=map(n["extras"])
            guard extras["hangarLabImported"] as? Bool == true else{continue}
            let origin=(extras["hangarLabImportName"] as? String ?? "").lowercased()
            guard origin.contains("dron") || origin.contains("drone") else{continue}
            let m=list(n["matrix"])
            guard m.count==16,!list(n["children"]).isEmpty else{continue}
            let x=number(m[12]),y=number(m[13]),z=number(m[14])
            guard x.isFinite,y.isFinite,z.isFinite else{continue}
            let d=(x-mx)*(x-mx)+(z-mz)*(z-mz)
            guard d<=36 else{continue}
            let name=n["name"] as? String ?? ""
            guard !name.isEmpty else{continue}
            candidates.append((d,Spawn(index:i,name:name,
                prefab:extras["hangarLabPrefabId"] as? String ?? "",
                x:x,y:y,z:z)))
        }
        candidates.sort{
            $0.distance == $1.distance
                ? $0.spawn.index<$1.spawn.index
                : $0.distance<$1.distance
        }
        guard candidates.count>=2 else{return []}
        return candidates.prefix(2).map{$0.spawn}
    }

    /// Read the small JSON chunk only; GLTFKit2 owns mesh/material/BIN data.
    static func load(_ url:URL)throws->[Spawn] {
        let file=try FileHandle(forReadingFrom:url)
        defer {try? file.close()}
        let header=try file.read(upToCount:20) ?? Data()
        guard header.count==20,word(header,0)==0x46546c67,
              word(header,4)==2,word(header,16)==0x4e4f534a,
              word(header,12)>0,word(header,12)<32*1024*1024 else {
            throw Error.glbHeader
        }
        let size=Int(word(header,12))
        let payload=try file.read(upToCount:size) ?? Data()
        guard payload.count==size,
              let doc=try JSONSerialization.jsonObject(with:payload)
                as? [String:Any] else{throw Error.document}
        return select(from:doc)
    }
}
