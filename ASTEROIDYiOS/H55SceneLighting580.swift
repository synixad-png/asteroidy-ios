import SceneKit
import UIKit

/// H13 iOS-only non-red fill for GLTFKit2 PBR hangar surfaces.
/// One tiny shared cubemap is created once; no art/GLB edits, no per-frame
/// texture creation and no lights attached to animated source nodes.
@MainActor enum H55SceneLighting580 {
    static let fillNodeName="H55_IOS_NEUTRAL_FILL"

    // Apple SceneKit accepts a single vertical 1x6 cube strip.
    // Same one small UIImage for all H55 load cycles; intentionally neutral.
    private static let neutralCube:UIImage = {
        let format=UIGraphicsImageRendererFormat()
        format.opaque=true
        format.scale=1
        let width:CGFloat=8
        let colors:[UIColor]=[
            UIColor(red:0.80,green:0.84,blue:0.91,alpha:1), // +X
            UIColor(red:0.80,green:0.84,blue:0.91,alpha:1), // -X
            UIColor(red:0.88,green:0.92,blue:0.99,alpha:1), // +Y
            UIColor(red:0.53,green:0.57,blue:0.63,alpha:1), // -Y
            UIColor(red:0.81,green:0.85,blue:0.93,alpha:1), // +Z
            UIColor(red:0.81,green:0.85,blue:0.93,alpha:1)  // -Z
        ]
        return UIGraphicsImageRenderer(size:CGSize(width:width,height:width*6),
                                      format:format).image { context in
            for (index,color) in colors.enumerated() {
                color.setFill()
                context.fill(CGRect(x:0,y:CGFloat(index)*width,
                                    width:width,height:width))
            }
        }
    }()

    static func install(into scene:SCNScene,profile:H55LightingProfile580) {
        // Preserve a genuine authored IBL if one exists in the imported scene.
        if scene.lightingEnvironment.contents == nil {
            scene.lightingEnvironment.contents=neutralCube
        }
        if scene.rootNode.childNode(withName:fillNodeName,recursively:false)==nil {
            // IBL illuminates PBR; one modest white/cool directional source
            // also covers non-PBR Blinn surfaces. No extra source H46 proxies.
            let light=SCNLight()
            light.name=fillNodeName
            light.type = .directional
            light.color=UIColor(red:0.88,green:0.92,blue:1,alpha:1)
            light.castsShadow=false
            let node=SCNNode()
            node.name=fillNodeName
            node.light=light
            node.eulerAngles=SCNVector3(-0.75,0.45,0)
            scene.rootNode.addChildNode(node)
        }
        update(scene:scene,profile:profile)
    }

    static func update(scene:SCNScene,profile:H55LightingProfile580) {
        // SceneKit IBL intensity is bounded to 0...1.
        scene.lightingEnvironment.intensity=CGFloat(profile.fill)
        if let light=scene.rootNode.childNode(
                withName:fillNodeName,recursively:false)?.light {
            light.intensity=CGFloat(profile.fill)*950
        }
    }
}
