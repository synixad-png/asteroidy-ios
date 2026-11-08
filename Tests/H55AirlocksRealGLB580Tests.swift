import Foundation

/// Run against the actual original 126419336-byte hangar_h55.glb or the
/// byte-preserving 126419340-byte cgltf-compatible copy. Never use mock mesh.
@main struct H55AirlocksRealGLB580Tests {
    static func main() throws {
        guard CommandLine.arguments.count==2 else {
            throw NSError(domain:"H07",code:1,userInfo:[
                NSLocalizedDescriptionKey:"Pass authenticated hangar_h55.glb path"
            ])
        }
        let url=URL(fileURLWithPath:CommandLine.arguments[1])
        let keys=try H55AirlockTracks580.load(from:url)
        precondition(keys.nodes.count==4,"H07 real GLB missing 4 leaf tracks")
        var checks=0
        for gate in 0..<2 {
            let x:Float=gate==0 ? 24.36 : 30.46
            for side in 0..<2 {
                let leaf=H55AirlockController580.leafNames[gate][side]
                guard let track=keys.nodes[leaf] else{preconditionFailure(leaf)}
                precondition(track.times.count==8,"8 original H70 keyframes")
                precondition(abs(track.times[1]-0.85)<0.00002 &&
                             abs(track.times[2]-1.85)<0.00002 &&
                             abs(track.times[7]-8.0)<0.00002,
                             "original 0.85,1.85,8.0 timestamps")
                let open=track.sample(0.85)
                let closed=track.sample(1.85)
                let half=track.sample(1.35)
                let openZ:Float=side==0 ? 4.67 : 9.63
                let shutZ:Float=side==0 ? 6.355 : 7.945
                precondition(abs(open.x-x)<0.0002 &&
                             abs(closed.x-x)<0.0002 &&
                             abs(open.y-1.65)<0.0002 &&
                             abs(closed.y-1.65)<0.0002 &&
                             abs(open.z-openZ)<0.0002 &&
                             abs(closed.z-shutZ)<0.0002 &&
                             abs(half.z-(openZ+shutZ)/2)<0.0002,
                             "authored left/right GLB leaf positions")
                checks+=9
            }
        }
        print("PASS H07 original GLB, 4 real translation tracks and \(checks) sampled coordinate/timestamp parity checks")
    }
}
