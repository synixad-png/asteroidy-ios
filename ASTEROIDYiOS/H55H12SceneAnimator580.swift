import Foundation
import SceneKit
import simd

/// H12: one exclusive, deterministic SceneKit writer for H55 machinery.
/// The GLB remains the only source of node poses/keys. PC GpuHub90.cs
/// selects exactly one H51 composite; H55Renderer.Animate then overlays
/// turbine/arms/light/crane/metadata loops in its original order.
///
/// H07 airlocks and H08/H09 NPC have their own controllers; they must not
/// be reset, retimed or driven again by a competing H51 channel.
@MainActor final class H55H12SceneAnimator580 {
    enum Failure:Error {case missingNode(String),ambiguousNode(String)}
    private struct Pose {
        let node:SCNNode
        let position:SIMD3<Float>
        let rotation:simd_quatf
        let scale:SIMD3<Float>
        let morph:[CGFloat]
    }
    private struct Binding {
        let track:H55H12Tracks580.Track
        let pose:Int
    }
    private struct Part {
        let clip:String
        let tracks:[Binding]
    }
    private let library:H55H12Tracks580.Library
    private let poses:[Pose]
    private let bindings:[String:Part]
    private var active:Set<String>=[]
    private var time:Float=0

    init(library:H55H12Tracks580.Library,allNodes:[SCNNode],
         excludedAirlockNames:Set<String>,
         protectedNpcRoot:SCNNode)throws {
        self.library=library
        var names=[String:[SCNNode]]()
        for node in allNodes {
            if let name=node.name {names[name,default:[]].append(node)}
        }
        func isNpc(_ node:SCNNode)->Bool {
            var current:SCNNode?=node
            while let n=current {
                if n === protectedNpcRoot {return true}
                current=n.parent
            }
            return false
        }
        var captured=[ObjectIdentifier:Int]()
        var snapshots=[Pose](),resolved=[String:Part]()
        for clip in library.clips.values.sorted(by:{$0.name<$1.name}) {
            var tracks=[Binding]()
            for track in clip.tracks {
                guard let matches=names[track.nodeName],matches.count==1,
                      let node=matches.first else {
                    throw (names[track.nodeName]?.count ?? 0)>1
                        ? Failure.ambiguousNode(track.nodeName)
                        : Failure.missingNode(track.nodeName)
                }
                // The PC compositor applies its own airlocks/NPC AFTER H51;
                // on iOS those are owned by separate source-verified samplers.
                if excludedAirlockNames.contains(track.nodeName) || isNpc(node) {
                    continue
                }
                let identity=ObjectIdentifier(node)
                let index:Int
                if let existing=captured[identity] {index=existing}
                else {
                    var morph=[CGFloat]()
                    if let m=node.morpher {
                        for n in 0..<m.targets.count {
                            morph.append(m.weight(forTargetAt:n))
                        }
                    }
                    index=snapshots.count
                    captured[identity]=index
                    snapshots.append(Pose(node:node,position:node.simdPosition,
                        rotation:node.simdOrientation,scale:node.simdScale,morph:morph))
                }
                if track.path == .weights {
                    guard node.morpher != nil,
                          node.morpher?.targets.count==track.width else {
                        throw Failure.missingNode(track.nodeName+" / morph targets")
                    }
                }
                tracks.append(Binding(track:track,pose:index))
            }
            resolved[clip.name]=Part(clip:clip.name,tracks:tracks)
        }
        poses=snapshots
        bindings=resolved
    }
    func advance(dt:Float) {
        guard dt.isFinite,dt>=0 else{return}
        time+=dt
        apply(time:time)
    }
    func apply(time current:Float) {
        guard current.isFinite,current>=0 else{return}
        let samples=library.frame(current)
        // Match original Animate reset from immutable GLB bind pose:
        // reset ONLY owned machinery channels. No per-frame allocations
        // of scene nodes or independent CAAnimation playback.
        for pose in poses {
            pose.node.simdPosition=pose.position
            pose.node.simdOrientation=pose.rotation
            pose.node.simdScale=pose.scale
            if let morpher=pose.node.morpher {
                for i in pose.morph.indices {
                    morpher.setWeight(pose.morph[i],forTargetAt:i)
                }
            }
        }
        var names=Set<String>()
        for sample in samples {
            guard let part=bindings[sample.clip] else{continue}
            names.insert(part.clip)
            for binding in part.tracks {
                let values=binding.track.sample(sample.at)
                let node=poses[binding.pose].node
                switch binding.track.path {
                case .translation:
                    node.simdPosition=SIMD3<Float>(values[0],values[1],values[2])
                case .rotation:
                    node.simdOrientation=simd_quatf(
                        vector:SIMD4<Float>(values[0],values[1],values[2],values[3]))
                case .scale:
                    node.simdScale=SIMD3<Float>(values[0],values[1],values[2])
                case .weights:
                    if let morpher=node.morpher {
                        for i in values.indices {
                            morpher.setWeight(CGFloat(values[i]),forTargetAt:i)
                        }
                    }
                }
            }
        }
        active=names
    }
    var activeClips:[String] {active.sorted()}
    var elapsed:Float {time}
}
