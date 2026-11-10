import SceneKit
import UIKit
import Foundation

/// PC v600 RendererHudEnergy.DrawPlanetariumCorona is attached ONLY to
/// the original SPHERE_OUTER_DOTTED_SKIN (mesh six, radius 2.1958).
/// The arcs and eleven tongues are SceneKit geometry allocated once.
/// Per-frame movement changes transforms, never meshes or GPU textures.
final class HudPlanetariumCorona600 {
    static let originalSphereNode = "SPHERE_OUTER_DOTTED_SKIN"
    static let originalSphereRadius:Float = 2.1958
    let root = SCNNode()
    private weak var sphere:SCNNode?
    private let flames:[SCNNode]

    private static func color(_ r:Int,_ g:Int,_ b:Int,_ a:Int)->UIColor {
        UIColor(red:CGFloat(r)/255,green:CGFloat(g)/255,
                blue:CGFloat(b)/255,alpha:CGFloat(a)/255)
    }
    private static func material(_ tint:UIColor)->SCNMaterial {
        let m=SCNMaterial()
        m.name="HUD600_CORONA_SOURCE_COLOR"
        m.lightingModel = .constant
        // Apply authored alpha exactly once (24/255 and 37/255),
        // otherwise a tinted diffuse AND transparency square opacity.
        let opaqueTint=tint.withAlphaComponent(1)
        m.diffuse.contents=opaqueTint
        m.emission.contents=opaqueTint
        m.transparency=CGFloat(tint.cgColor.alpha)
        m.blendMode = .alpha
        m.isDoubleSided=true
        m.readsFromDepthBuffer=false
        m.writesToDepthBuffer=false
        return m
    }
    private static func geometry(points:[SIMD3<Float>],indices:[Int32],
                                 tint:UIColor)->SCNGeometry {
        let vectors=points.map{SCNVector3($0.x,$0.y,$0.z)}
        let source=SCNGeometrySource(vertices:vectors)
        let element=SCNGeometryElement(indices:indices,primitiveType:.triangles)
        let shape=SCNGeometry(sources:[source],elements:[element])
        shape.materials=[material(tint)]
        return shape
    }
    private static func arc(start:Float,sweep:Float,
                            thickness:Float,tint:UIColor)->SCNNode {
        let count=48
        var points=[SIMD3<Float>]()
        var indices=[Int32]()
        points.reserveCapacity((count+1)*2)
        indices.reserveCapacity(count*6)
        let r:Float=105
        for i in 0...count {
            let angle=(start+sweep*Float(i)/Float(count))*Float.pi/180
            let x=cos(angle),y=sin(angle)
            points.append(SIMD3((r-thickness*0.5)*x,(r-thickness*0.5)*y,0))
            points.append(SIMD3((r+thickness*0.5)*x,(r+thickness*0.5)*y,0))
            if i>0 {
                let n=Int32(i*2)
                indices.append(contentsOf:[n-2,n-1,n,n-1,n+1,n])
            }
        }
        return SCNNode(geometry:geometry(points:points,indices:indices,tint:tint))
    }
    private static func tongue(index:Int)->SCNNode {
        let amber=index==2 || index==7
        // PC 600: source ray spans theta ±0.054rad at a reference radius
        // 100, with a tip that travels from 103 to 109.5.
        let edge:Float=100.5*0.054
        let vertices:[SIMD3<Float>]=[
            SIMD3(0,-edge,0),SIMD3(9.5,0,0),SIMD3(0,edge,0)
        ]
        let tint=amber ? color(254,136,46,37):color(38,191,214,37)
        let node=SCNNode(geometry:geometry(
            points:vertices,indices:[0,1,2],tint:tint))
        node.name="HUD600_CORONA_TONGUE_\(index)"
        return node
    }
    init?(scene:SCNScene,nodes:[SCNNode]) {
        let candidates=nodes.filter{$0.name==Self.originalSphereNode &&
            $0.geometry != nil}
        guard candidates.count==1 else{return nil}
        self.sphere=candidates[0]
        root.name="HUD600_CORONA_ORIGINAL_OUTER_SPHERE"
        root.renderingOrder=70
        root.constraints=[SCNBillboardConstraint()]
        root.addChildNode(Self.arc(start:-45,sweep:172,thickness:3.6,
                                    tint:Self.color(43,183,214,24)))
        root.addChildNode(Self.arc(start:149,sweep:152,thickness:3.1,
                                    tint:Self.color(50,172,202,21)))
        flames=(0..<11).map(Self.tongue(index:))
        for flame in flames {root.addChildNode(flame)}
        scene.rootNode.addChildNode(root)
    }
    func advance(at time:TimeInterval) {
        guard let globe=sphere else {
            root.isHidden=true
            return
        }
        let presentation=globe.presentation
        let center=presentation.convertPosition(SCNVector3Zero,to:nil)
        let edge=presentation.convertPosition(
            SCNVector3(Self.originalSphereRadius,0,0),to:nil)
        let dx=edge.x-center.x,dy=edge.y-center.y,dz=edge.z-center.z
        let radius=sqrt(dx*dx+dy*dy+dz*dz)
        guard radius.isFinite,radius>0.0001,time.isFinite else {
            root.isHidden=true
            return
        }
        root.isHidden=false
        root.position=center
        // Corona follows the actual outer globe scale, not planetarium
        // panel or nearby capsule bounds; no guessed screen-space center.
        let factor=radius/100
        root.scale=SCNVector3(factor,factor,factor)
        let t=Double(time)
        for i in 0..<flames.count {
            let base=(Double(i)+0.35)*Double.pi*2/11
            let theta=base+0.075*sin(t*0.43+Double(i)*1.41)
            let pulse=0.5+0.5*sin(t*(1.15+0.13*Double(i%3))+Double(i)*2.1)
            let flame=3.0+6.5*pulse
            let node=flames[i]
            node.position=SCNVector3(Float(100.5*cos(theta)),Float(100.5*sin(theta)),0)
            node.eulerAngles.z=Float(theta+0.034*sin(t*0.83+Double(i)*0.7))
            node.scale=SCNVector3(Float(flame/9.5),1,1)
        }
    }
}
