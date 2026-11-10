import Foundation
import SceneKit
import SwiftUI
import UIKit

/// True PC v580-style GLB preview in SETTINGS > RĘKAWICE / BROŃ.
/// NOT a screenshot, primitive replacement or view inside gameplay.
/// Uses the same H55FPSScene580 source importer, triangle split, materials
/// and calibration as live first-person mode, with independent depth.
struct H55FPSPreview580:UIViewRepresentable {
    let settings:H55FPSSettings580
    /// PC GpuWeapon470 previews: 0=static, 2=walk, 3=run.
    let motion:Int
    let onStatus:(String)->Void

    func makeCoordinator()->Coordinator {
        Coordinator()
    }
    func makeUIView(context:Context)->SCNView {
        let view=SCNView(frame:.zero)
        let scene=SCNScene()
        scene.background.contents=UIColor(red:0.015,green:0.025,
                                          blue:0.042,alpha:1)
        let camera=SCNNode()
        let lens=SCNCamera()
        lens.zNear=0.06
        lens.zFar=20
        lens.fieldOfView=70
        camera.camera=lens
        scene.rootNode.addChildNode(camera)
        // Windows Weapon470 settings preview uses a soft neutral light.
        // This does not change original GLB textures or source PBR factors.
        let ambient=SCNNode()
        ambient.light=SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity=380
        ambient.light?.color=UIColor.white
        scene.rootNode.addChildNode(ambient)
        let key=SCNNode()
        key.light=SCNLight()
        key.light?.type = .omni
        key.light?.intensity=650
        key.position=SCNVector3(-1.5,1.5,1)
        scene.rootNode.addChildNode(key)
        view.scene=scene
        view.pointOfView=camera
        view.isOpaque=true
        view.backgroundColor=UIColor.black
        view.autoenablesDefaultLighting=false
        view.allowsCameraControl=false
        view.isUserInteractionEnabled=false
        view.preferredFramesPerSecond=30
        view.rendersContinuously=true
        view.isPlaying=true
        let c=context.coordinator
        c.onStatus=onStatus
        c.currentMotion=motion
        c.fps=H55FPSScene580(camera:camera,inform:{ [weak c] message in
            c?.onStatus?(message)
        })
        c.fps?.synchronizePreview(settings)
        c.start()
        return view
    }
    func updateUIView(_ view:SCNView,context:Context) {
        let c=context.coordinator
        c.currentMotion=motion
        c.onStatus=onStatus
        c.fps?.synchronizePreview(settings)
    }
    static func dismantleUIView(_ view:SCNView,coordinator:Coordinator) {
        coordinator.stop()
        coordinator.fps?.release()
        coordinator.fps=nil
        view.isPlaying=false
        view.scene=nil
    }

    @MainActor final class Coordinator:NSObject {
        var fps:H55FPSScene580?
        var onStatus:((String)->Void)?
        var currentMotion=0
        private var link:CADisplayLink?
        private var startTime:CFTimeInterval?

        func start() {
            guard link == nil else{return}
            let clock=CADisplayLink(target:self,selector:#selector(tick(_:)))
            clock.preferredFramesPerSecond=30
            clock.add(to:.main,forMode:.common)
            link=clock
        }
        func stop() {
            link?.invalidate()
            link=nil
            startTime=nil
        }
        @objc private func tick(_ link:CADisplayLink) {
            if startTime == nil {startTime=link.timestamp}
            let t=Float(link.timestamp-(startTime ?? link.timestamp))
            let bob:Float
            switch currentMotion {
            case 2:bob=1
            case 1:bob=0.55
            default:bob=0
            }
            fps?.advance(time:t,walking:true,bobPhase:t*5,
                         bobAmount:bob,bobPercent:100)
        }
    }
}
