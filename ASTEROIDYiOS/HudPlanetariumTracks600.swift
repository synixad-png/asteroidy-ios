import Foundation

/// Reads only animation translation accessor bounds from the exact verified
/// glTF 2.0 HUD planetarium. All actual animation playback remains GLTFKit2's.
enum HudPlanetariumTracks600 {
    enum Problem:Error { case invalidGlb, invalidMetadata, invalidAccessor }
    struct Inventory {
        let names:[String]
        let bubbleExtents:[Int:[Float]]
    }
    private static func u32(_ b:Data,_ i:Int)->UInt32? {
        guard i>=0 && i<=b.count-4 else{return nil}
        return UInt32(b[i]) | UInt32(b[i+1])<<8 |
               UInt32(b[i+2])<<16 | UInt32(b[i+3])<<24
    }
    static func inspect(_ bytes:Data)->Inventory? {
        guard u32(bytes,0)==0x46546c67,u32(bytes,4)==2,
              u32(bytes,8)==UInt32(bytes.count),
              let jsonLength=u32(bytes,12),u32(bytes,16)==0x4e4f534a else{return nil}
        let binaryHeader=20+Int(jsonLength)
        guard binaryHeader>=20,binaryHeader<=bytes.count-8,
              u32(bytes,binaryHeader+4)==0x004e4942,
              let binaryLength=u32(bytes,binaryHeader),
              Int(binaryLength)<=bytes.count-binaryHeader-8,
              let json=try? JSONSerialization.jsonObject(
                with:Data(bytes[20..<binaryHeader])) as? [String:Any],
              let nodes=json["nodes"] as? [[String:Any]],
              let views=json["bufferViews"] as? [[String:Any]],
              let accessors=json["accessors"] as? [[String:Any]],
              let animations=json["animations"] as? [[String:Any]],
              animations.count==1,
              let channels=animations[0]["channels"] as? [[String:Any]],
              let samplers=animations[0]["samplers"] as? [[String:Any]],
              channels.count==HudPlanetariumAsset600.channels else{return nil}
        let names=nodes.map{$0["name"] as? String ?? ""}
        guard names.count==HudPlanetariumAsset600.nodes else{return nil}
        var extents=[Int:[Float]]()
        let binaryStart=binaryHeader+8
        for channel in channels {
            guard let target=channel["target"] as? [String:Any],
                  target["path"] as? String == "translation",
                  let node=target["node"] as? Int,node>=0,node<names.count,
                  names[node].contains("_WATER_BUBBLE_"),
                  let samplerIndex=channel["sampler"] as? Int,
                  samplerIndex>=0,samplerIndex<samplers.count,
                  let output=samplers[samplerIndex]["output"] as? Int,
                  output>=0,output<accessors.count else {continue}
            let accessor=accessors[output]
            guard accessor["type"] as? String == "VEC3",
                  accessor["componentType"] as? Int == 5126,
                  let count=accessor["count"] as? Int,
                  count>0 && count<=100_000,
                  let viewIndex=accessor["bufferView"] as? Int,
                  viewIndex>=0 && viewIndex<views.count else{return nil}
            let view=views[viewIndex]
            guard let viewOffset=view["byteOffset"] as? Int,
                  let viewLength=view["byteLength"] as? Int,
                  viewOffset>=0,viewLength>=12,
                  let strideValue=view["byteStride"] as? Int ?? 12,
                  strideValue>=12,strideValue<=256,
                  let accessorOffset=accessor["byteOffset"] as? Int ?? 0,
                  accessorOffset>=0 else{return nil}
            let last=accessorOffset+(count-1)*strideValue+12
            guard last<=viewLength,
                  viewOffset<=Int(binaryLength),
                  viewLength<=Int(binaryLength)-viewOffset else{return nil}
            let start=binaryStart+viewOffset+accessorOffset
            var minX=Float.infinity,maxX = -Float.infinity
            for index in 0..<count {
                guard let raw=u32(bytes,start+index*strideValue) else{return nil}
                let value=Float(bitPattern:raw)
                guard value.isFinite else{return nil}
                minX=min(minX,value)
                maxX=max(maxX,value)
            }
            extents[node]=[minX,maxX]
        }
        guard extents.count==72 else{return nil}
        return Inventory(names:names,bubbleExtents:extents)
    }
}
