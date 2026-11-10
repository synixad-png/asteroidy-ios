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
                                liveCapsules:liveCapsules,
                                liveGameTime:liveGameTime)
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
                  (try? HudPlanetariumAsset600.validate(bytes)) != nil
            else {
                NSLog("HUD602 planetarium: missing or non-original GLB at %@",url.path)
                return
            }
            // PC v602 HudGlbAssets.EnsureHudAsset loads and displays the
            // original scene regardless of optional capsule-masking binding.
            // Only this iOS version incorrectly rejected the ENTIRE GLB
            // whenever bubble names/accessors were not imported as expected.
            let inventory=HudPlanetariumTracks600.inspect(bytes)
            let capsuleBinding=inventory.flatMap {
                HudCapsuleBinding600(nodeNames:$0.names,
                                     translationX:$0.bubbleExtents)
            }
            let loadGeneration=generation
            GLTFAsset.load(with:url,options:[:]) { _,status,asset,error,_ in
                if status != .complete {return}
                guard let asset else {
                    NSLog("HUD602 planetarium: GLTFKit2 import failed: %@",
                          String(describing:error))
                    return
                }
                let source=GLTFSCNSceneSource(asset:asset)
                DispatchQueue.main.async { [weak self,weak view] in
                    guard let self,let view,
                          self.generation==loadGeneration else{return}
                    guard let model=source.defaultScene else {
                        NSLog("HUD602 planetarium: original GLB has no imported default scene")
                        return
                    }
                    let clip=source.animations.first(where:{
                        $0.name == HudPlanetariumAsset600.clipName
                    })
                    let nodesByName=Dictionary(
                        grouping:source.nodes.compactMap{node -> (String,SCNNode)? in
                            guard let name=node.name else{return nil}
                            return (name,node)
                        },by:{$0.0})
                    var resolved=[Int:SCNNode]()
                    var flashNodes=[SCNNode]()
                    var completeCapsules=true
                    if let capsuleBinding,let inventory {
                        for capsule in capsuleBinding.capsules {
                            for id in capsule.bubbles {
                                let key=inventory.names[id]
                                guard let node=nodesByName[key]?.first?.1,
                                      nodesByName[key]?.count==1 else {
                                    completeCapsules=false;break
                                }
                                resolved[id]=node
                            }
                            let key=inventory.names[capsule.flash]
                            if let node=nodesByName[key]?.first?.1,
                               nodesByName[key]?.count==1 {
                                flashNodes.append(node)
                            } else {completeCapsules=false}
                        }
                    } else {completeCapsules=false}
                    // PC HudCapsuleScene.BindHudCapsules is OPTIONAL to
                    // H55Scene.Render: if missing, show every original mesh
                    // rather than returning an empty transparent SCNView.
                    let activeBinding=(completeCapsules && resolved.count==72 &&
                                       flashNodes.count==3) ? capsuleBinding : nil
                    if activeBinding == nil {
                        NSLog("HUD602 planetarium: bubble mask not bound; original geometry remains visible")
                    }
                    // Attaches to original outer sphere; never to global
                    // planetarium bounds or the three status capsules.
                    // Keep GLTFKit2's original animation root and all its
                    // 159 authored key paths unchanged. Transform ONLY the
                    // complete scene instance above that root.
                    let rendered=SCNScene()
                    let corona=HudPlanetariumCorona600(scene:rendered,nodes:source.nodes)
                    // PC v602 HudGlbAssets.DrawHudGlb:
                    // Translate(widget center) -> Rotate Y/X/Z ->
                    // Scale(.44*width*scale/PlanetModelRadius463) ->
                    // Translate(-PlanetModelCenter463).
                    // Preserve EVERY imported authored glTF node/animation.
                    // Only re-parent the complete original hierarchy once.
                    let centered=SCNNode()
                    centered.name="PC602_PLANET_MODEL_CENTER"
                    centered.position=SCNVector3(
                        -HudPlanetariumAsset600.pc602ModelCenterX,
                        -HudPlanetariumAsset600.pc602ModelCenterY,
                        -HudPlanetariumAsset600.pc602ModelCenterZ)
                    centered.addChildNode(model.rootNode)
                    let rollPivot=SCNNode()
                    let pitchPivot=SCNNode()
                    let yawPivot=SCNNode()
                    rollPivot.name="PC602_HUD_ROLL"
                    pitchPivot.name="PC602_HUD_PITCH"
                    yawPivot.name="PC602_HUD_YAW"
                    rollPivot.addChildNode(centered)
                    pitchPivot.addChildNode(rollPivot)
                    yawPivot.addChildNode(pitchPivot)
                    rendered.rootNode.addChildNode(yawPivot)
                    let cameraNode=SCNNode()
                    let lens=SCNCamera()
                    lens.usesOrthographicProjection=true
                    lens.zNear=0.01
                    lens.zFar=1000
                    // PC v602 HudGlbAssets.DrawHudGlb:
                    // pixels/modelUnit = 0.44 * 250 * scale / radius.
                    // SCNCamera.orthographicScale is a HALF vertical view
                    // extent; a full-height value made the entire authored
                    // GLB appear 2x too small on real iPhones.
                    // UIView already incorporates widget.Scale.
                    lens.orthographicScale=(135.0 * 0.5) *
                        HudPlanetariumAsset600.pc602ModelRadius /
                        (0.44*250.0)
                    cameraNode.camera=lens
                    cameraNode.position=SCNVector3(0,0,20)
                    rendered.rootNode.addChildNode(cameraNode)
                    var importedPlayer:SCNAnimationPlayer?
                    if let clip {
                        let player=clip.animationPlayer
                        player.animation.repeatCount = .greatestFiniteMagnitude
                        player.animation.usesSceneTimeBase=false
                        model.rootNode.addAnimationPlayer(player,forKey:"hud-planetarium-v600")
                        importedPlayer=player
                    } else {
                        NSLog("HUD602 planetarium: original clip not imported by GLTFKit2")
                    }
                    self.mutex.lock()
                    self.scene=rendered
                    self.binding=activeBinding
                    self.bubbles=activeBinding == nil ? [:] : resolved
                    self.flashes=activeBinding == nil ? [] : flashNodes
                    self.camera=cameraNode
                    self.yawPivot=yawPivot
                    self.pitchPivot=pitchPivot
                    self.rollPivot=rollPivot
                    self.corona=corona
                    self.mutex.unlock()
                    view.scene=rendered
                    view.pointOfView=cameraNode
                    view.isPlaying=playing
                    importedPlayer?.play()
                    NSLog("HUD602 planetarium: original GLB attached, nodes=%ld, animation=%@, capsules=%@",
                          source.nodes.count,clip == nil ? "unavailable" : "bound",
                          activeBinding == nil ? "unavailable" : "bound")
                }
            }
        }

        /// Runs *after* the authored glTF clip is evaluated, on SceneKit's
        /// render queue. No GLB parsing, IO or dynamic GPU allocation.
        func renderer(_ renderer:SCNSceneRenderer,
                      didApplyAnimationsAtTime time:TimeInterval) {
            mutex.lock()
            defer{mutex.unlock()}
            // PC v602 preserves original GLB rendering even when optional
            // capsule filtering could not be bound. Rotation and corona still
            // advance independently of the bubble mask.
            if let binding {
                let frameCapsules=liveCapsules?() ?? capsule
                if frameCapsules.levels.count==3 && frameCapsules.flashes.count==3 {
                    for i in 0..<3 {
                        let range=binding.capsules[i]
                        let level=HudCapsuleController600.clamp(frameCapsules.levels[i])
                        let cutoff=range.xMin+(range.xMax-range.xMin)*level
                        for id in range.bubbles {
                            guard let node=bubbles[id] else{continue}
                            let x=node.presentation.position.x
                            let shouldHide=level<=0 ||
                                (level<1 && (!x.isFinite || x>cutoff))
                            if node.isHidden != shouldHide {node.isHidden=shouldHide}
                        }
                        let flash=binding.flashScale(
                            channel:i,flash:frameCapsules.flashes[i]) ?? 0.001
                        flashes[i].scale=SCNVector3(flash,flash,flash)
                    }
                }
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
