import Foundation
import SceneKit
import simd

/// H71 v461: apply source DronePilot453 poses to TWO real, imported GLB
/// prefab roots. This is the same deltaWorld*bindWorld transform used by
/// H55Renderer.PlaceImportedDrones461; no new meshes, duplicate drone nodes
/// or SceneKit idle CAAnimations are created.
@MainActor final class H55DroneScene580 {
    private struct Binding {
        let root:SCNNode
        let authoredWorld:simd_float4x4
        let spawn:H55DroneImports580.Spawn
    }
    private let bindings:[Binding]
    private(set) var flight:H55DroneFlight580
    private var time:Float=0

    init?(spawns:[H55DroneImports580.Spawn],
          navigation:H55DroneNavigation580,
          allNodes:[SCNNode]) {
        guard spawns.count==2,
              let flight=H55DroneFlight580(navigation:navigation,
                                            spawns:spawns) else{return nil}
        var matches=[String:[SCNNode]]()
        for node in allNodes {
            if let name=node.name {matches[name,default:[]].append(node)}
        }
        var entries=[Binding](),seen=Set<ObjectIdentifier>()
        for spawn in spawns {
            guard let candidates=matches[spawn.name],candidates.count==1,
                  let root=candidates.first,
                  !root.childNodes.isEmpty,
                  seen.insert(ObjectIdentifier(root)).inserted else{return nil}
            entries.append(Binding(root:root,authoredWorld:root.simdWorldTransform,
                                    spawn:spawn))
        }
        self.bindings=entries
        self.flight=flight
        apply()
    }
    func advance(dt:Float,player:H55DroneFlight580.Player) {
        guard dt.isFinite,dt>0 else{return}
        time+=min(0.06,dt)
        flight.advance(dt:dt,player:player)
        apply()
    }
    private func apply() {
        for (i,b) in bindings.enumerated() {
            let pilot=flight.pilots[i]
            if !pilot.active {continue}
            let radians=Float.pi/180
            let orientation =
                simd_quatf(angle:pilot.yaw*radians,axis:SIMD3<Float>(0,1,0)) *
                simd_quatf(angle:pilot.pitch*radians,axis:SIMD3<Float>(1,0,0)) *
                simd_quatf(angle:pilot.roll*radians,axis:SIMD3<Float>(0,0,1))
            var delta=simd_float4x4(orientation)
            let visual=max(Float(0.001),min(1,pilot.visualScale))
            delta.columns.0*=visual
            delta.columns.1*=visual
            delta.columns.2*=visual
            let anchor=SIMD4<Float>(b.spawn.x,b.spawn.y,b.spawn.z,1)
            let moved=delta*anchor
            let hover:Float=0.03*sin(time*2.6+Float(pilot.id)*2)
            let targetY=b.spawn.y+(pilot.position.y-pilot.home.y)+hover
            delta.columns.3=SIMD4<Float>(
                pilot.position.x-moved.x,
                targetY-moved.y,
                pilot.position.z-moved.z,1)
            // Transform the authentic source parent once. Child primitives,
            // material/skin, GLB-authored rotors and alpha remain untouched.
            b.root.simdWorldTransform=delta*b.authoredWorld
            b.root.isHidden=pilot.visualScale<=0.001
        }
    }
    var status:String {
        let active=flight.pilots.filter{$0.active}.count
        let visiting=flight.pilots.filter{$0.visiting}.count
        return "H71: DRONY \(active)/2 · WIZYTY \(visiting) · POWROTY \(flight.returns)"
    }
}
