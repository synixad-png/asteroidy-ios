import Foundation

/// H06 repair: same original H55 GLB and real four-sphere geometry.
@main struct H55TouchRealGLB580Tests {
    static func main() throws {
        guard CommandLine.arguments.count==2 else {
            throw NSError(domain:"H55Touch",code:1,userInfo:[
                NSLocalizedDescriptionKey:"Supply exact original hangar_h55.glb"
            ])
        }
        let physical=H55SpatialSupport580(geometry:
            try H55CollisionGeometry580.fromGLB(
                URL(fileURLWithPath:CommandLine.arguments[1])))
        guard let spawn=H55Entry580.find(using:physical) else{
            preconditionFailure("H05 spawn missing")
        }
        precondition(spawn.x==2 && spawn.z==14 &&
                     abs(spawn.feet-0.1)<0.001)
        let inputs:[(String,Float,Float)]=[
            ("FORWARD",0,-78),("BACK",0,78),
            ("STRAFE_LEFT",-78,0),("STRAFE_RIGHT",78,0)
        ]
        for (name,dx,dy) in inputs {
            let axis=H55TouchMapping580.walk(dx:dx,dy:dy)
            var state=H55Walk580()
            state.x=spawn.x;state.z=spawn.z
            state.placeAtSpawn(feet:spawn.feet)
            for _ in 0..<120 {
                state.step(dt:1/60,forward:axis.forward,
                           right:axis.right,sprint:false,collision:physical)
            }
            let sx=state.x-spawn.x,sz=state.z-spawn.z
            switch name {
            case "FORWARD": precondition(sz < -1)
            case "BACK": precondition(sz > 1)
            case "STRAFE_LEFT":precondition(sx < -1)
            case "STRAFE_RIGHT":precondition(sx > 1)
            default: preconditionFailure()
            }
            precondition(physical.bodyClear379(
                state.x,feet:state.y,state.z))
            print("PASS \(name): (x=\(state.x), z=\(state.z), feet=\(state.y))")
        }
        print("PASS REAL H55: H05 spawn -> four independent correct touch directions with source H06 original 4-sphere collision")
    }
}
