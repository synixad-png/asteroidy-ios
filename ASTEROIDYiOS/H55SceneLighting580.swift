import SceneKit
import UIKit

/// H13-A safe fallback only. Source PC v580 renders its own GLSL lights
/// (H55Renderer.cs); it does not construct SceneKit PBR cubemaps.
/// Building an IBL from UIImage during a 126 MB GLB import is intentionally
/// DISABLED after a physical-device loading crash report.
@MainActor enum H55SceneLighting580 {
    static let fillNodeName="H55_IOS_NEUTRAL_FILL"
    static let ambientNodeName="H55_IOS_SOURCE_ALBEDO_AMBIENT"

    static func install(into scene:SCNScene,profile:H55LightingProfile580) {
        // Do not assign scene.lightingEnvironment.contents, generate a
        // cubemap or force shader compilation at attach time.
        if scene.rootNode.childNode(withName:fillNodeName,recursively:false)==nil {
            let lamp=SCNLight()
            lamp.name=fillNodeName
            lamp.type = .directional
            lamp.color=UIColor(red:0.88,green:0.92,blue:1,alpha:1)
            lamp.castsShadow=false
            let node=SCNNode()
            node.name=fillNodeName
            node.light=lamp
            node.eulerAngles=SCNVector3(-0.75,0.45,0)
            scene.rootNode.addChildNode(node)
        }
        // PC H55Renderer.cs uses (albedo * 0.24 + localLights).
        // One cheap neutral ambient approximates the source ambient term.
        // No GPU cubemap or additional shader allocation.
        if scene.rootNode.childNode(withName:ambientNodeName,recursively:false)==nil {
            let lamp=SCNLight()
            lamp.name=ambientNodeName
            lamp.type = .ambient
            lamp.color=UIColor(white:0.92,alpha:1)
            let node=SCNNode()
            node.name=ambientNodeName
            node.light=lamp
            scene.rootNode.addChildNode(node)
        }
        update(scene:scene,profile:profile)
    }

    static func update(scene:SCNScene,profile:H55LightingProfile580) {
        // Conservative temporary SceneKit-only fill until H13-B ports the
        // original six-light and albedo*0.24 GLSL model. Not PC luminance.
        if let lamp=scene.rootNode.childNode(
              withName:fillNodeName,recursively:false)?.light {
            lamp.intensity=CGFloat(profile.fill)*750
        }
        if let ambient=scene.rootNode.childNode(
              withName:ambientNodeName,recursively:false)?.light {
            ambient.intensity=CGFloat(profile.fill)*235
        }
    }
}
