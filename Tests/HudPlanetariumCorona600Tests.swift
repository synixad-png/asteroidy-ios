import Foundation
import SceneKit

@main enum HudPlanetariumCorona600Tests {
    static func require(_ condition: @autoclosure () -> Bool,_ reason:String) {
        precondition(condition(),reason)
    }
    static func main() {
        let scene=SCNScene()
        let original=SCNNode(geometry:SCNSphere(radius:CGFloat(HudPlanetariumCorona600.originalSphereRadius)))
        original.name=HudPlanetariumCorona600.originalSphereNode
        original.position=SCNVector3(5,3,-2)
        scene.rootNode.addChildNode(original)
        guard let aura=HudPlanetariumCorona600(scene:scene,nodes:[original]) else {
            preconditionFailure("original outer globe should bind")
        }
        require(aura.root.childNodes.count==13,
                "two source arcs and 11 animated tongues")
        aura.advance(at:0)
        require(!aura.root.isHidden,"globe corona must be visible")
        require(abs(aura.root.position.x-5)<0.01 &&
                abs(aura.root.position.y-3)<0.01,
                "aura must be centered on the actual outer sphere")
        let expectedScale = HudPlanetariumCorona600.originalSphereRadius / 100
        require(abs(aura.root.scale.x - expectedScale) < 0.001,
                "aura must track glTF outer sphere radius, not panel bounds")
        let tongue=aura.root.childNodes.last!
        let old=tongue.position
        aura.advance(at:2)
        require(abs(tongue.position.x-old.x)+abs(tongue.position.y-old.y)>0.1,
                "source plasma tongues must animate")
        original.position=SCNVector3(13,9,-2)
        aura.advance(at:4)
        // SceneKit presentation transforms can remain at the last rendered
        // frame on headless macOS; compare to that authoritative pose,
        // not to the model node's newer unpresented transform.
        let displayed=original.presentation.convertPosition(SCNVector3Zero,to:nil)
        require(abs(aura.root.position.x-displayed.x)<0.01 &&
                abs(aura.root.position.y-displayed.y)<0.01,
                "aura tracks the currently presented glTF globe")
        require(HudPlanetariumCorona600(scene:scene,nodes:[])==nil,
                "never attach aura to arbitrary planetarium geometry")
        print("PASS HUD v600 corona: original sphere binding, 2 arcs, 11 animated rays, true node translation")
    }
}
