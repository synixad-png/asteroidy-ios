import SceneKit
import UIKit

/// One-time SceneKit translation of verified Windows v580 H55 render rules.
/// Edits existing imported SCNMaterial instances. No copied meshes, cubemaps,
/// shader modifiers, bloom or per-frame allocations.
@MainActor enum H55VisualScene580 {
    struct Outcome {
        var panes=0,ceilings=0,emitters=0
        var text:String {
            "H13-B / PC580: szkło \(panes), teksturowany sufit \(ceilings), świecące materiały lamp \(emitters). Światło SceneKit jest przybliżeniem; wygląd wymaga testu na urządzeniu."
        }
    }

    static func apply(nodes:[SCNNode])->Outcome {
        var result=Outcome()
        var seen=Set<ObjectIdentifier>()
        for node in nodes {
            guard let geometry=node.geometry else{continue}
            for material in geometry.materials {
                let materialName=material.name ?? ""
                let nodeName=node.name ?? ""
                let pane=H55VisualSource580.isGlassPane(node:nodeName,material:materialName)
                let ceiling=H55VisualSource580.isTexturedCeiling(node:nodeName,material:materialName)
                let sourceEmission=H55VisualSource580.lampEmission(materialName)
                guard pane || ceiling || sourceEmission != nil,
                      seen.insert(ObjectIdentifier(material)).inserted else{continue}
                if pane {
                    // PC Glass548 defaults: ALPHA=.05, TINT=.20,
                    // REFLECTION=.75, TEXTURE=false. Frames stay opaque.
                    // Windows Glass548: source pane alpha 5%. PBR glass
                    // reflects SceneKit's neutral fill as opaque grey.
                    // Transmit the separately rendered IntroSky background.
                    material.lightingModel = .constant
                    material.diffuse.contents=UIColor(red:0.68,green:0.86,
                                                     blue:1,alpha:0.05)
                    material.emission.contents=UIColor.clear
                    material.reflective.contents=UIColor.clear
                    material.transparency=0.05
                    material.blendMode = .alpha
                    material.isDoubleSided=true
                    material.writesToDepthBuffer=false
                    material.readsFromDepthBuffer=true
                    result.panes += 1
                } else if ceiling {
                    // H34 source ceiling has real baseColor textures and
                    // metallic=1/roughness=1. Without IBL it goes black.
                    // Windows adds albedo*0.24 independent of light direction.
                    // Blinn + neutral ambient preserves authored texture.
                    material.lightingModel = .blinn
                    material.ambient.contents=UIColor(white:0.35,alpha:1)
                    material.isDoubleSided=true
                    result.ceilings += 1
                } else if let emission=sourceEmission {
                    // Genuine H46 bulb mesh is self-luminous in Windows.
                    // SceneKit .constant avoids a new per-material shader.
                    let color=UIColor(red:emission.r,green:emission.g,
                                      blue:emission.b,alpha:1)
                    material.lightingModel = .constant
                    material.diffuse.contents=color
                    material.emission.contents=color
                    material.isDoubleSided=true
                    result.emitters += 1
                }
            }
        }
        return result
    }
}
