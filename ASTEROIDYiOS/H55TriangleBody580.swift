import Foundation

/// H04 — direct port of the original Windows PC v580
/// H55FullCollision379.Dist2 / BodyClear / Penetration382 /
/// ContactNormal401 / CameraClear406 in Windows/src/HubWalk375.cs.
/// Uses exact geometry from H02 and 2m H03 buckets, not SceneKit raycasts.
/// H05 owns the subsequent player-entry integration.
extension H55SpatialSupport580 {
    private static func dot(_ ax:Float,_ ay:Float,_ az:Float,
                            _ bx:Float,_ by:Float,_ bz:Float)->Float {
        ax*bx + ay*by + az*bz
    }
    /// Ericson region tests: exact squared distance between a real
    /// GLB triangle and a 3D point. Never project just onto triangle plane.
    func distanceSquared379(at i:Int,x px:Float,y py:Float,z pz:Float)->Float {
        let t=geometry.triangles
        let ax=t[i],ay=t[i+1],az=t[i+2],
            bx=t[i+3],by=t[i+4],bz=t[i+5],
            cx=t[i+6],cy=t[i+7],cz=t[i+8]
        let abx=bx-ax,aby=by-ay,abz=bz-az,
            acx=cx-ax,acy=cy-ay,acz=cz-az,
            apx=px-ax,apy=py-ay,apz=pz-az
        let d1=Self.dot(abx,aby,abz,apx,apy,apz)
        let d2=Self.dot(acx,acy,acz,apx,apy,apz)
        if d1<=0 && d2<=0 {
            return Self.dot(apx,apy,apz,apx,apy,apz)
        }
        let bpx=px-bx,bpy=py-by,bpz=pz-bz
        let d3=Self.dot(abx,aby,abz,bpx,bpy,bpz)
        let d4=Self.dot(acx,acy,acz,bpx,bpy,bpz)
        if d3>=0 && d4<=d3 {
            return Self.dot(bpx,bpy,bpz,bpx,bpy,bpz)
        }
        let vc=d1*d4-d3*d2
        if vc<=0 && d1>=0 && d3<=0 {
            let v=d1/(d1-d3)
            let dx=apx-v*abx,dy=apy-v*aby,dz=apz-v*abz
            return Self.dot(dx,dy,dz,dx,dy,dz)
        }
        let cpx=px-cx,cpy=py-cy,cpz=pz-cz
        let d5=Self.dot(abx,aby,abz,cpx,cpy,cpz)
        let d6=Self.dot(acx,acy,acz,cpx,cpy,cpz)
        if d6>=0 && d5<=d6 {
            return Self.dot(cpx,cpy,cpz,cpx,cpy,cpz)
        }
        let vb=d5*d2-d1*d6
        if vb<=0 && d2>=0 && d6<=0 {
            let w=d2/(d2-d6)
            let dx=apx-w*acx,dy=apy-w*acy,dz=apz-w*acz
            return Self.dot(dx,dy,dz,dx,dy,dz)
        }
        let va=d3*d6-d5*d4
        if va<=0 && (d4-d3)>=0 && (d5-d6)>=0 {
            let w=(d4-d3)/((d4-d3)+(d5-d6))
            let dx=bpx+w*(cx-bx),dy=bpy+w*(cy-by),dz=bpz+w*(cz-bz)
            return Self.dot(dx,dy,dz,dx,dy,dz)
        }
        let denom=va+vb+vc
        if abs(denom)<1e-10 {return 1e12}
        let inv:Float=1/denom,vv=vb*inv,ww=vc*inv
        let ex=apx-vv*abx-ww*acx
        let ey=apy-vv*aby-ww*acy
        let ez=apz-vv*abz-ww*acz
        return Self.dot(ex,ey,ez,ex,ey,ez)
    }

    /// Source BodyClear and Penetration382 use the same exact
    /// spatial buckets and four overlapping 0.325m-radius spheres.
    /// At most the scan geometry differs: early return versus
    /// additive penetration energy.
    private func sphereScan(_ x:Float,_ footY:Float,_ z:Float,
                            sum:Bool)->Float {
        let radius:Float=0.34-0.015
        let rr=radius*radius
        let t=geometry.triangles
        var score:Float=0
        for ix in Self.cell(x-radius)...Self.cell(x+radius) {
            for iy in Self.cell(footY+0.02)...Self.cell(footY+2.0) {
                for iz in Self.cell(z-radius)...Self.cell(z+radius) {
                    guard let list=cells[Self.key(ix,iy,iz)] else{continue}
                    for i in list {
                        let miny=min(t[i+1],min(t[i+4],t[i+7]))
                        let maxy=max(t[i+1],max(t[i+4],t[i+7]))
                        // v409: floor trim below the existing 50cm step
                        // is handled by Support and is NOT a torso wall.
                        if maxy<=footY+0.50 || miny>=footY+2.28 {continue}
                        if max(t[i],max(t[i+3],t[i+6]))<x-radius ||
                           min(t[i],min(t[i+3],t[i+6]))>x+radius ||
                           max(t[i+2],max(t[i+5],t[i+8]))<z-radius ||
                           min(t[i+2],min(t[i+5],t[i+8]))>z+radius {
                            continue
                        }
                        for k in 0..<4 {
                            let sphereY=footY+(0.335+Float(k)*0.445)
                            if sphereY+radius<miny || sphereY-radius>maxy {
                                continue
                            }
                            let d2=distanceSquared379(at:i,x:x,y:sphereY,z:z)
                            if d2<rr-0.001 {
                                if !sum{return 1}
                                score+=rr-d2
                            }
                        }
                    }
                }
            }
        }
        return score
    }

    /// Source hard map bounds and docked ship are authoritative.
    func bodyClear379(_ x:Float,feet:Float,_ z:Float)->Bool {
        if !h72Bounds(x,z) || shipBlocks(x,feet,z) {return false}
        let radius:Float=0.34-0.015
        if proxyCapsule(x,feet,z,radius:radius)>0 {return false}
        if sphereScan(x,feet,z,sum:false)>0 {return false}
        return proxyCapsule(x,feet,z,radius:radius)<=0
    }

    /// Source v382 additive overlap; a blocked position can measure its
    /// true contact gradient and recover out of multiple rail triangles.
    func penetration382(_ x:Float,feet:Float,_ z:Float)->Float {
        if !h72Bounds(x,z) || shipBlocks(x,feet,z) {return 1_000_000}
        let radius:Float=0.34-0.015
        let proxy=proxyCapsule(x,feet,z,radius:radius)
        if proxy>0 {return proxy}
        return sphereScan(x,feet,z,sum:true) +
               proxyCapsule(x,feet,z,radius:radius)
    }

    /// PC v401 finite-difference outward contact normal. No speculative
    /// wall-slide if there is no source-verified penetration gradient.
    func contactNormal401(_ x:Float,feet:Float,_ z:Float)
         -> (x:Float,z:Float)? {
        let energy=penetration382(x,feet:feet,z)
        if energy<=0.000001 || energy>=100_000 {return nil}
        let h:Float=0.032
        let epx=penetration382(x+h,feet:feet,z)
        let emx=penetration382(x-h,feet:feet,z)
        let epz=penetration382(x,feet:feet,z+h)
        let emz=penetration382(x,feet:feet,z-h)
        if max(max(epx,emx),max(epz,emz))>=100_000 {return nil}
        let nx=emx-epx,nz=emz-epz
        let sq=nx*nx+nz*nz
        if sq<0.0000000001 {return nil}
        let inv:Float=1/sqrt(sq)
        return (nx*inv,nz*inv)
    }

    /// PC v406 small camera near-eye sphere. Player full four
    /// spheres remain authoritative and are NOT replaced by this.
    func cameraClear406(_ x:Float,_ y:Float,_ z:Float,
                        radius:Float)->Bool {
        if !h72Bounds(x,z) {return false}
        if proxyNear(x,y,z,radius:radius)>0 {return false}
        let rr=radius*radius
        let t=geometry.triangles
        for ix in Self.cell(x-radius)...Self.cell(x+radius) {
            for iy in Self.cell(y-radius)...Self.cell(y+radius) {
                for iz in Self.cell(z-radius)...Self.cell(z+radius) {
                    guard let list=cells[Self.key(ix,iy,iz)] else{continue}
                    for i in list {
                        if max(t[i],max(t[i+3],t[i+6]))<x-radius ||
                           min(t[i],min(t[i+3],t[i+6]))>x+radius ||
                           max(t[i+1],max(t[i+4],t[i+7]))<y-radius ||
                           min(t[i+1],min(t[i+4],t[i+7]))>y+radius ||
                           max(t[i+2],max(t[i+5],t[i+8]))<z-radius ||
                           min(t[i+2],min(t[i+5],t[i+8]))>z+radius {
                            continue
                        }
                        if distanceSquared379(at:i,x:x,y:y,z:z)<rr {
                            return false
                        }
                    }
                }
            }
        }
        return proxyNear(x,y,z,radius:radius)<=0
    }
}
