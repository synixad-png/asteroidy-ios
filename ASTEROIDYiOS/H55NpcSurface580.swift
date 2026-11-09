import Foundation

/// PC v580 Windows/src/H55Renderer.cs NpcGround526, NpcGround530,
/// NpcSafeWalk530 and PrepareNpc525 route audit. Uses the original
/// 2-metre H02/H03 triangle index and four-sphere H04 capsule.
/// No guessed floors, navmesh, invisible walls or static-GLB A* bypasses.
struct H55NpcSurface580 {
    enum RouteError: Error, LocalizedError {
        case invalidStart
        case blocked(segment:Int,step:Int,total:Int)
        var errorDescription:String? {
            switch self {
            case .invalidStart: return "Brak źródłowej podpory mechanika H55."
            case .blocked(let segment,let step,let total):
                return "Oryginalna trasa mechanika H55 zablokowana: odcinek \(segment), próbka \(step)/\(total)."
            }
        }
    }
    static let rootX:Float=9.9248, rootY:Float=0.1095, rootZ:Float=12.155
    let collision:H55SpatialSupport580
    let foot:Float
    let samples:Int

    /// Original NPC start foot = source Support(rootY-.24, rootY+.18),
    /// fallback rootY-.0095 if the source collision has no support.
    static func prepare(collision p:H55SpatialSupport580)throws->Self {
        let foot=p.support(rootX,rootZ,low:rootY-0.24,high:rootY+0.18)
                 ?? (rootY-0.0095)
        let surface=Self(collision:p,foot:foot,samples:0)
        guard surface.ground(x:rootX,z:rootZ) != nil else {
            throw RouteError.invalidStart
        }
        var x=rootX,z=rootZ,count=0
        for i in H55Mechanic580.routeX.indices {
            let dx=H55Mechanic580.routeX[i]-x
            let dz=H55Mechanic580.routeZ[i]-z
            let n=max(1,Int(ceil(hypot(dx,dz)/0.08)))
            for j in 0...n {
                let f=Float(j)/Float(n)
                guard surface.ground(x:x+dx*f,z:z+dz*f) != nil else {
                    throw RouteError.blocked(segment:i,step:j,total:n)
                }
                count+=1
            }
            x=H55Mechanic580.routeX[i]
            z=H55Mechanic580.routeZ[i]
        }
        return Self(collision:p,foot:foot,samples:count)
    }

    private func ground526(_ x:Float,_ z:Float)->Float? {
        guard let h=collision.support(x,z,low:foot-0.10,high:foot+0.12),
              abs(h-foot)<=0.12,abs(h-0.10)<=0.16,
              collision.bodyClear379(x,feet:h,z) else{return nil}
        return h
    }

    /// PC NpcGround530: only when the central support is missing,
    /// accept an equal-height floor backed by BOTH side samples.
    /// The center capsule itself still must pass BodyClear379.
    func ground(x:Float,z:Float)->Float? {
        if let center=ground526(x,z) {return center}
        for d:Float in [0.045,0.07] {
            for (ax,az,bx,bz) in [
                (x-d,z,x+d,z),(x,z-d,x,z+d)
            ] {
                guard let a=collision.support(ax,az,low:foot-0.10,high:foot+0.12),
                      let b=collision.support(bx,bz,low:foot-0.10,high:foot+0.12),
                      abs(a-b)<0.045 else{continue}
                let y=(a+b)*0.5
                if abs(y-foot)<0.12,abs(y-0.10)<0.16,
                   collision.bodyClear379(x,feet:y,z) {return y}
            }
        }
        return nil
    }
}
