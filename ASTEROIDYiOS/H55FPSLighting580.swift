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
    static let gloveBrightnessKey="ASTEROIDY_H55_GLOVE_BRIGHTNESS_602"
    // AppStorage/UI controls this exact same persisted value. The original
    // glTF textures/PBR are never baked or overwritten.
    static var gloveBrightness:CGFloat {
        let stored=UserDefaults.standard.object(forKey:gloveBrightnessKey) as? Double ?? 0.65
        return CGFloat(max(0.20,min(1.50,stored.isFinite ? stored:0.65)))
    }
    private static let lightSpecs:[(SCNVector3,UIColor,CGFloat)]=[
        (SCNVector3(-1,2,-0.6),UIColor(red:0.8,green:0.8,blue:0.8,alpha:1),720),
        (SCNVector3(2,1,-1),UIColor(red:0.5,green:0.5,blue:0.6,alpha:1),450),
        (SCNVector3(0,3,-3),UIColor(red:0.2,green:0.2,blue:0.25,alpha:1),220),
    ]

    /// Only gloves use the lower gain: leave the original EXP-01 weapon
    /// preview and first-person lighting unchanged.
    static func configure(scene:SCNScene,mode:H55FPSSettings580.Mode) {
        let gain:CGFloat = mode == .gloves ? sceneKitLightGain*gloveBrightness : 1
        scene.rootNode.childNode(withName:"FPS_AMBIENT_LIGHT",
                                 recursively:false)?.light?.intensity=220*gain
        for (i,spec) in lightSpecs.enumerated() {
            scene.rootNode.childNode(withName:"FPS_SOURCE_LIGHT_\(i)",
                                     recursively:false)?.light?.intensity=spec.2*gain
        }
    }

    static func install(into scene:SCNScene) {
        let ambient=SCNNode()
        ambient.name="FPS_AMBIENT_LIGHT"
        let ambientLight=SCNLight()
        ambientLight.type = .ambient
        ambientLight.color=UIColor.white
        ambientLight.intensity=220
        ambient.light=ambientLight
        scene.rootNode.addChildNode(ambient)

        for (i,spec) in lightSpecs.enumerated() {
            let node=SCNNode()
            node.name="FPS_SOURCE_LIGHT_\(i)"
            node.position=spec.0
            let lamp=SCNLight()
            lamp.type = .omni
            lamp.color=spec.1
            lamp.intensity=spec.2
            node.light=lamp
            scene.rootNode.addChildNode(node)
        }
        configure(scene:scene,mode:.gloves)
    }
}
