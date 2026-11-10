import Foundation
import SwiftUI
import SceneKit
import GLTFKit2

/// The existing GLTFKit2/SceneKit importer also used by H55 renders the
/// genuine HUD glTF. Metal combat never instantiates a second world renderer.
struct HudPlanetariumScene600:UIViewRepresentable {
    let original:URL
    let capsule:HudCapsuleController600.Snapshot
    let pitch:Float
    let pose:HudMotion600.Pose

    func makeCoordinator()->Coordinator { Coordinator() }

    func makeUIView(context:Context)->SCNView {
        let view=SCNView(frame:.zero)
        view.backgroundColor = .clear
        view.isOpaque=false
        view.allowsCameraControl=false
        view.isUserInteractionEnabled=false
        view.autoenablesDefaultLighting=true
        view.preferredFramesPerSecond=60
        view.rendersContinuously=true
        view.delegate=context.coordinator
        context.coordinator.load(original,into:view)
        return view
    }
    func updateUIView(_ view:SCNView,context:Context) {
        context.coordinator.set(capsule, pitch:pitch,pose:pose)
    }
    static func dismantleUIView(_ view:SCNView,coordinator:Coordinator) {
        view.delegate=nil
        view.isPlaying=false
        coordinator.reset()
    }

    final class Coordinator:NSObject,SCNSceneRendererDelegate {
        private let mutex=NSLock()
        private var capsule=HudCapsuleController600.Snapshot(
            levels:[1,1,1],flashes:[0,0,0])
        private var pitch:Float = -20
        private var pose=HudMotion600.Pose()
        private var binding:HudCapsuleBinding600?
        private var bubbles:[Int:SCNNode]=[:]
        private var flashes=[SCNNode]()
        private var camera:SCNNode?
        private var scene:SCNScene?
        private var generation=0

        func set(_ updated:HudCapsuleController600.Snapshot,
                 pitch:Float,pose:HudMotion600.Pose) {
            mutex.lock()
            capsule=updated
            self.pitch=pitch
            self.pose=pose
            mutex.unlock()
        }
        func reset() {
            mutex.lock()
            generation += 1
            scene=nil;binding=nil
            bubbles.removeAll();flashes.removeAll()
            camera=nil
            mutex.unlock()
        }

        func load(_ url:URL,into view:SCNView) {
            guard let bytes=try? Data(contentsOf:url),
                  (try? HudPlanetariumAsset600.validate(bytes)) != nil,
                  let inventory=HudPlanetariumTracks600.inspect(bytes),
                  let capsuleBinding=HudCapsuleBinding600(
                      nodeNames:inventory.names,
                      translationX:inventory.bubbleExtents)
            else {return}
            let loadGeneration=generation
            GLTFAsset.load(with:url,options:[:]) { _,status,asset,_,_ in
                guard status == .complete,let asset else{return}
                let source=GLTFSCNSceneSource(asset:asset)
                DispatchQueue.main.async { [weak self,weak view] in
                    guard let self,let view,
                          self.generation==loadGeneration,
                          let model=source.defaultScene,
                          let clip=source.animations.first(where:{
                              $0.name == HudPlanetariumAsset600.clipName
                          }) else {return}
                    let nodesByName=Dictionary(
                        grouping:source.nodes.compactMap{node -> (String,SCNNode)? in
                            guard let name=node.name else{return nil}
                            return (name,node)
                        },by:{$0.0})
                    var resolved=[Int:SCNNode]()
                    var flashNodes=[SCNNode]()
                    for capsule in capsuleBinding.capsules {
                        for id in capsule.bubbles {
                            let key=inventory.names[id]
                            guard let node=nodesByName[key]?.first?.1,
                                  nodesByName[key]?.count==1 else{return}
                            resolved[id]=node
                        }
                        let key=inventory.names[capsule.flash]
                        guard let node=nodesByName[key]?.first?.1,
                              nodesByName[key]?.count==1 else{return}
                        flashNodes.append(node)
                    }
                    guard resolved.count==72 && flashNodes.count==3 else{return}
                    let cameraNode=SCNNode()
                    let lens=SCNCamera()
                    lens.usesOrthographicProjection=true
                    lens.zNear=0.01
                    lens.zFar=1000
                    cameraNode.camera=lens
                    let bounds=model.rootNode.boundingBox
                    let minPoint=bounds.min,maxPoint=bounds.max
                    let x=(minPoint.x+maxPoint.x)*0.5
                    let y=(minPoint.y+maxPoint.y)*0.5
                    let z=(minPoint.z+maxPoint.z)*0.5
                    let width=Double(maxPoint.x-minPoint.x)
                    let height=Double(maxPoint.y-minPoint.y)
                    let depth=Double(maxPoint.z-minPoint.z)
                    guard width.isFinite && height.isFinite && depth.isFinite,
                          width>0 && height>0 else{return}
                    lens.orthographicScale=max(height*1.2,width*1.2/(250.0/135.0))
                    cameraNode.position=SCNVector3(x,y,z+Float(max(10,depth*2)))
                    model.rootNode.addChildNode(cameraNode)
                    let player=clip.animationPlayer
                    player.animation.repeatCount = .greatestFiniteMagnitude
                    player.animation.usesSceneTimeBase=false
                    model.rootNode.addAnimationPlayer(player,forKey:"hud-planetarium-v600")
                    self.mutex.lock()
                    self.scene=model
                    self.binding=capsuleBinding
                    self.bubbles=resolved
                    self.flashes=flashNodes
                    self.camera=cameraNode
                    self.mutex.unlock()
                    view.scene=model
                    view.pointOfView=cameraNode
                    view.isPlaying=true
                    player.play()
                }
            }
        }

        /// Runs *after* the authored glTF clip is evaluated, on SceneKit's
        /// render queue. No GLB parsing, IO or dynamic GPU allocation.
        func renderer(_ renderer:SCNSceneRenderer,
                      didApplyAnimationsAtTime time:TimeInterval) {
            mutex.lock()
            defer{mutex.unlock()}
            guard let binding,capsule.levels.count==3,
                  capsule.flashes.count==3 else{return}
            for i in 0..<3 {
                let range=binding.capsules[i]
                let level=HudCapsuleController600.clamp(capsule.levels[i])
                let cutoff=range.xMin+(range.xMax-range.xMin)*level
                for id in range.bubbles {
                    guard let node=bubbles[id] else{continue}
                    let x=node.presentation.position.x
                    node.isHidden=level<=0 ||
                        (level<1 && (!x.isFinite || x>cutoff))
                }
                let flash=binding.flashScale(channel:i,flash:capsule.flashes[i]) ?? 0.001
                flashes[i].scale=SCNVector3(flash,flash,flash)
            }
            if let camera {
                let radians=(pitch+pose.roll*0.16)*Float.pi/180
                camera.eulerAngles=SCNVector3(radians,0,0)
            }
        }
    }
}
