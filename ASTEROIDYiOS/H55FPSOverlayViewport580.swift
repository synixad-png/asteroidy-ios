import SceneKit
import SwiftUI
import UIKit

/// PC GpuGloves417 / GpuWeapon470 execute AFTER H55 world rendering and
/// reset GL_DEPTH_BUFFER_BIT before the original first-person geometry.
/// A separate transparent native SCNView gives the viewmodel its own real
/// depth buffer, while preserving all source PBR/alpha/UV material settings.
/// Unlike disabling depth, the two hands cannot flicker through one another.
struct H55FPSOverlayViewport580:UIViewRepresentable {
    let scene:SCNScene
    let pointOfView:SCNNode

    func makeUIView(context:Context)->SCNView {
        let view=SCNView(frame:.zero)
        view.isOpaque=false
        view.backgroundColor=.clear
        view.scene=scene
        view.scene?.background.contents=UIColor.clear
        view.pointOfView=pointOfView
        view.allowsCameraControl=false
        view.autoenablesDefaultLighting=false
        view.isUserInteractionEnabled=false
        view.preferredFramesPerSecond=60
        view.rendersContinuously=true
        view.isPlaying=true
        return view
    }
    func updateUIView(_ view:SCNView,context:Context) {
        if view.scene !== scene {view.scene=scene}
        if view.pointOfView !== pointOfView {view.pointOfView=pointOfView}
    }
    static func dismantleUIView(_ view:SCNView,coordinator:()) {
        view.isPlaying=false
        view.scene=nil
    }
}
