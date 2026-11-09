import SceneKit
import SwiftUI
import UIKit

/// SceneView has no frame-presented notification. This native SCNView
/// bridge reports three completed GPU render passes so Hub90 arrival
/// starts at t=0 only when the actual H55 picture can be shown.
/// No input ownership: invisible left/right SwiftUI zones remain on top.
struct H55SceneViewport580:UIViewRepresentable {
    let scene:SCNScene
    let pointOfView:SCNNode
    let onFirstRenderedFrames:(SCNScene)->Void

    func makeCoordinator()->Coordinator {
        Coordinator(onFirstRenderedFrames:onFirstRenderedFrames)
    }
    func makeUIView(context:Context)->SCNView {
        let view=SCNView(frame:.zero)
        view.backgroundColor=UIColor(red:0.005,green:0.019,
                                     blue:0.033,alpha:1)
        view.scene=scene
        view.pointOfView=pointOfView
        view.allowsCameraControl=false
        view.autoenablesDefaultLighting=false
        view.isUserInteractionEnabled=false
        view.preferredFramesPerSecond=60
        view.rendersContinuously=true
        view.delegate=context.coordinator
        view.isPlaying=true
        return view
    }
    func updateUIView(_ view:SCNView,context:Context) {
        if view.scene !== scene {view.scene=scene}
        if view.pointOfView !== pointOfView {view.pointOfView=pointOfView}
    }
    static func dismantleUIView(_ view:SCNView,coordinator:Coordinator) {
        view.delegate=nil
        view.isPlaying=false
    }

    final class Coordinator:NSObject,SCNSceneRendererDelegate {
        private let onFirstRenderedFrames:(SCNScene)->Void
        private var currentScene:SCNScene?
        private var gate=H55RenderStartGate580()

        init(onFirstRenderedFrames:@escaping (SCNScene)->Void) {
            self.onFirstRenderedFrames=onFirstRenderedFrames
        }
        func renderer(_ renderer:SCNSceneRenderer,
                      didRenderScene rendered:SCNScene,
                      atTime time:TimeInterval) {
            // This delegate runs on SceneKit's render queue.
            if currentScene !== rendered {
                currentScene=rendered
                gate.reset()
            }
            guard gate.didRenderFrame() else{return}
            DispatchQueue.main.async { [onFirstRenderedFrames] in
                onFirstRenderedFrames(rendered)
            }
        }
    }
}
