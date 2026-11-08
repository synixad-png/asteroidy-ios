import Foundation

/// Original PC v580 Windows/src/HubWalk375.cs:
/// HubWalkSlide401 + HubWalkSweepSlide401.
/// H04 supplies source-correct collision/normal/sweep. H06 supplies the
/// original MoveHubAxis379 step/snap implementation as a closure.
/// Does not alter iOS player state until H05/H06 integration.
enum H55Sweep401580 {
    struct Position {
        var x:Float
        var feet:Float
        var z:Float
    }
    static func slide(dx:Float,dz:Float,nx:Float,nz:Float)
          -> (x:Float,z:Float) {
        let inward=dx*nx+dz*nz
        if inward<0 {return (dx-inward*nx,dz-inward*nz)}
        return (dx,dz)
    }
    static func sweep(collision:H55SpatialSupport580,
                      from original:Position,vx:Float,vz:Float,
                      moveHubAxis:(Position,Float,Float)->Position)->Position {
        let len=sqrt(vx*vx+vz*vz)
        if len<0.000001 {return original}
        let count=max(1,min(20,Int(ceil(len/0.05))))
        let dx=vx/Float(count),dz=vz/Float(count)
        var state=original
        for _ in 0..<count {
            let oldX=state.x,oldZ=state.z,feet=state.feet
            state=moveHubAxis(state,dx,dz)
            if abs(state.x-oldX)+abs(state.z-oldZ)>0.000001 {continue}
            if collision.bodyClear379(oldX,feet:feet,oldZ),
               let normal=collision.contactNormal401(oldX+dx,feet:feet,oldZ+dz) {
                let projected=slide(dx:dx,dz:dz,nx:normal.x,nz:normal.z)
                let magnitude=projected.x*projected.x+projected.z*projected.z
                if magnitude>0.000001 &&
                   magnitude<=dx*dx+dz*dz+0.000001 {
                    state=moveHubAxis(state,projected.x,projected.z)
                    if abs(state.x-oldX)+abs(state.z-oldZ)>0.000001 {
                        continue
                    }
                }
            }
            // PC v580: only validated independent axis motions are tried.
            state=moveHubAxis(state,dx,0)
            state=moveHubAxis(state,0,dz)
        }
        return state
    }
}
