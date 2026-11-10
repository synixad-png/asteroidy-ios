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
    let yaw:Float
    let roll:Float
    let pose:HudMotion600.Pose
    let playing:Bool
    let livePose:()->HudMotion600.Pose
    let liveCapsules:()->HudCapsuleController600.Snapshot
    let liveGameTime:()->Double

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
        context.coordinator.set(capsule,pitch:pitch,yaw:yaw,roll:roll,
                                pose:pose,livePose:livePose,
                                liveCapsules:liveCapsules,
                                liveGameTime:liveGameTime)
        context.coordinator.load(original,into:view,playing:playing)
        return view
    }
    func updateUIView(_ view:SCNView,context:Context) {
        context.coordinator.set(capsule,pitch:pitch,yaw:yaw,roll:roll,
                                pose:pose,livePose:livePose,
                                liveCapsules:liveCapsules)
        if view.isPlaying != playing {view.isPlaying=playing}
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
        private var yaw:Float = 0
        private var roll:Float = 0
        private var pose=HudMotion600.Pose()
        private var livePose:(()->HudMotion600.Pose)?
        private var liveCapsules:(()->HudCapsuleController600.Snapshot)?
        private var liveGameTime:(()->Double)?
        private var binding:HudCapsuleBinding600?
        private var bubbles:[Int:SCNNode]=[:]
        private var flashes=[SCNNode]()
        private var camera:SCNNode?
        private var yawPivot:SCNNode?
        private var pitchPivot:SCNNode?
        private var rollPivot:SCNNode?
        private var scene:SCNScene?
        private var corona:HudPlanetariumCorona600?
        private var generation=0

        func set(_ updated:HudCapsuleController600.Snapshot,
                 pitch:Float,yaw:Float,roll:Float,
                 pose:HudMotion600.Pose,livePose:@escaping ()->HudMotion600.Pose,
                 liveCapsules:@escaping ()->HudCapsuleController600.Snapshot,
                 liveGameTime:@escaping ()->Double) {
            mutex.lock()
            capsule=updated
            self.pitch=pitch
            self.yaw=yaw
            self.roll=roll
            self.pose=pose
            self.livePose=livePose
            self.liveCapsules=liveCapsules
            self.liveGameTime=liveGameTime
            mutex.unlock()
        }
        func reset() {
            mutex.lock()
            generation += 1
            scene=nil;binding=nil
            bubbles.removeAll();flashes.removeAll()
            camera=nil
            yawPivot=nil;pitchPivot=nil;rollPivot=nil
            corona=nil
            livePose=nil
            liveCapsules=nil
            liveGameTime=nil
            mutex.unlock()
        }

        func load(_ url:URL,into view:SCNView,playing:Bool) {
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
                    // Attaches to original outer sphere; never to global
                    // planetarium bounds or the three status capsules.
                    let corona=HudPlanetariumCorona600(scene:model,nodes:source.nodes)
                    // PC v602 HudGlbAssets.DrawHudGlb:
                    // Translate(widget center) -> Rotate Y/X/Z ->
                    // Scale(.44*width*scale/PlanetModelRadius463) ->
                    // Translate(-PlanetModelCenter463).
                    // Preserve EVERY imported authored glTF node/animation.
                    // Only re-parent the complete original hierarchy once.
                    let sourceRoots=model.rootNode.childNodes
                    let centered=SCNNode()
                    centered.name="PC602_PLANET_MODEL_CENTER"
                    centered.position=SCNVector3(
                        -HudPlanetariumAsset600.pc602ModelCenterX,
                        -HudPlanetariumAsset600.pc602ModelCenterY,
                        -HudPlanetariumAsset600.pc602ModelCenterZ)
                    for root in sourceRoots {centered.addChildNode(root)}
                    let rollPivot=SCNNode()
                    let pitchPivot=SCNNode()
                    let yawPivot=SCNNode()
                    rollPivot.name="PC602_HUD_ROLL"
                    pitchPivot.name="PC602_HUD_PITCH"
                    yawPivot.name="PC602_HUD_YAW"
                    rollPivot.addChildNode(centered)
                    pitchPivot.addChildNode(rollPivot)
                    yawPivot.addChildNode(pitchPivot)
                    model.rootNode.addChildNode(yawPivot)
                    let cameraNode=SCNNode()
                    let lens=SCNCamera()
                    lens.usesOrthographicProjection=true
                    lens.zNear=0.01
                    lens.zFar=1000
                    // Source exact: pixels/modelUnit =
                    // .44 * widget.Width * Scale / PlanetModelRadius463.
                    // UIView scales with widget.Scale, so it cancels here.
                    lens.orthographicScale=135.0 *
                        HudPlanetariumAsset600.pc602ModelRadius /
                        (0.44*250.0)
                    cameraNode.camera=lens
                    cameraNode.position=SCNVector3(0,0,20)
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
                    self.yawPivot=yawPivot
                    self.pitchPivot=pitchPivot
                    self.rollPivot=rollPivot
                    self.corona=corona
                    self.mutex.unlock()
                    view.scene=model
                    view.pointOfView=cameraNode
                    view.isPlaying=playing
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
            guard let binding else{return}
            // The 159-track original glTF is animated at scene frame rate;
            // sample its 3 current resource levels and hit flashes at the
            // same cadence, independent of 10Hz text/radar publication.
            let frameCapsules=liveCapsules?() ?? capsule
            guard frameCapsules.levels.count==3,
                  frameCapsules.flashes.count==3 else{return}
            for i in 0..<3 {
                let range=binding.capsules[i]
                let level=HudCapsuleController600.clamp(frameCapsules.levels[i])
                let cutoff=range.xMin+(range.xMax-range.xMin)*level
                for id in range.bubbles {
                    guard let node=bubbles[id] else{continue}
                    let x=node.presentation.position.x
                    let shouldHide=level<=0 ||
                        (level<1 && (!x.isFinite || x>cutoff))
                    // PC v602 updates a cached HudHidden[] mask instead of
                    // reparenting all 72 bubbles each render. Avoid writing
                    // an unchanged SceneKit node flag on every frame.
                    if node.isHidden != shouldHide {node.isHidden=shouldHide}
                }
                let flash=binding.flashScale(channel:i,flash:frameCapsules.flashes[i]) ?? 0.001
                flashes[i].scale=SCNVector3(flash,flash,flash)
            }
            if let yawPivot,let pitchPivot,let rollPivot {
                // In PC v602 the GLB object, NOT the camera, receives the
                // authored F6 yaw/pitch/roll. The original glTF animation
                // remains independent and runs in the same render callback.
                let framePose=livePose?() ?? pose
                let weight=framePose.weight("hud.planetarium")
                yawPivot.eulerAngles.y=yaw*Float.pi/180
                pitchPivot.eulerAngles.x=pitch*Float.pi/180
                rollPivot.eulerAngles.z=(roll+framePose.roll*weight)*Float.pi/180
            }
            // PC v602 DrawPlanetariumCorona takes Game.Time, not the
            // independent renderer clock used by AnimatePlanet463.
            corona?.advance(at:liveGameTime?() ?? 0)
        }
    }
}
