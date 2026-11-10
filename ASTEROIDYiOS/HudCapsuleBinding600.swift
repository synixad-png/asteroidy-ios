import Foundation

/// Authoritative glTF node binding for PC v600 planetarium HUD only.
/// The renderer supplies animated node translations after evaluating the
/// original 159 tracks; this filter never replaces or rebuilds animation.
struct HudCapsuleBinding600 {
    struct Capsule {
        let bubbles:[Int]
        let flash:Int
        let xMin:Float
        let xMax:Float
    }
    let capsules:[Capsule]
    let nodeCount:Int

    /// Translation samples contain original glTF X keyframes, indexed by node.
    /// Reject incomplete assets rather than silently attaching a wrong mesh.
    init?(nodeNames:[String],translationX:[Int:[Float]]) {
        var found=[Capsule]()
        for channel in 0..<3 {
            let prefix="CAPSULE_\(channel)_WATER_BUBBLE_"
            let nodeIDs=nodeNames.indices.filter{nodeNames[$0].hasPrefix(prefix)}
            guard nodeIDs.count==24 else{return nil}
            let socket=["DAMAGE_HULL_FLASH_SOCKET",
                        "DAMAGE_ARMOR_FLASH_SOCKET",
                        "DAMAGE_SHIELD_FLASH_SOCKET"][channel]
            guard let flash=nodeNames.firstIndex(of:socket) else{return nil}
            var low=Float.infinity,high = -Float.infinity
            for id in nodeIDs {
                guard let keys=translationX[id],!keys.isEmpty else{return nil}
                for x in keys {
                    guard x.isFinite else{return nil}
                    low=min(low,x);high=max(high,x)
                }
            }
            guard high>low+0.1 else{return nil}
            found.append(Capsule(bubbles:nodeIDs,flash:flash,
                                 xMin:low,xMax:high))
        }
        capsules=found
        nodeCount=nodeNames.count
    }

    /// PC HudCapsuleScene: mask only authored animated bubble nodes.
    /// Do not apply these flags to hangars or world GLBs.
    func visibleBubbles(levels:[Float],animatedX:[Float])->[Bool]? {
        guard levels.count==3,animatedX.count==nodeCount else{return nil}
        var visible=Array(repeating:true,count:nodeCount)
        for i in 0..<3 {
            let capsule=capsules[i]
            let level=HudCapsuleController600.clamp(levels[i])
            let cutoff=capsule.xMin+(capsule.xMax-capsule.xMin)*level
            for node in capsule.bubbles {
                visible[node] = level>0 && (level>=1 || animatedX[node]<=cutoff)
            }
        }
        return visible
    }

    func flashScale(channel:Int,flash:Float)->Float? {
        guard (0..<3).contains(channel) else{return nil}
        return 0.001+0.75*HudCapsuleController600.clamp(flash)
    }
}
