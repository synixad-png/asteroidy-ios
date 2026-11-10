import SceneKit
import UIKit

/// Shared neutral SceneKit lighting for the physically separate FPS depth
/// pass. Positions and RGB ratios are from PC GpuWeapon470
/// RenderWeaponPreview470, lines 89-91. SceneKit photometric intensities
/// are calibrated for visibility, not claimed bit-identical to PC GLSL.
/// Does not touch or replace source glTF material, UV, PBR or emission.
@MainActor enum H55FPSLighting580 {
    // SceneKit intensity units are not equivalent to PC GpuGloves417's
    // explicitly tone-mapped GLSL lights. The former 1.0 photometric gain
    // clipped the authored glove highlights to white in the FPS overlay.
    // Keep original light positions, RGB ratios and glTF PBR unchanged.
    private static let sceneKitLightGain:CGFloat=0.35

    static func install(into scene:SCNScene) {
        let ambient=SCNNode()
        ambient.name="FPS_AMBIENT_LIGHT"
        let ambientLight=SCNLight()
        ambientLight.type = .ambient
        ambientLight.color=UIColor.white
        ambientLight.intensity=220*sceneKitLightGain
        ambient.light=ambientLight
        scene.rootNode.addChildNode(ambient)

        let lights:[(SCNVector3,UIColor,CGFloat)]=[
            (SCNVector3(-1,2,-0.6),UIColor(red:0.8,green:0.8,blue:0.8,alpha:1),720),
            (SCNVector3(2,1,-1),UIColor(red:0.5,green:0.5,blue:0.6,alpha:1),450),
            (SCNVector3(0,3,-3),UIColor(red:0.2,green:0.2,blue:0.25,alpha:1),220),
        ]
        for (i,spec) in lights.enumerated() {
            let node=SCNNode()
            node.name="FPS_SOURCE_LIGHT_\(i)"
            node.position=spec.0
            let lamp=SCNLight()
            lamp.type = .omni
            lamp.color=spec.1
            lamp.intensity=spec.2*sceneKitLightGain
            node.light=lamp
            scene.rootNode.addChildNode(node)
        }
    }
}
