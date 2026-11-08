import Foundation

/// PC v580: Windows/src/HubWalk375.cs H55FullCollision379.
/// H03 builds the original 2m spatial triangle and prefab grids, calculates
/// barycentric Support/SupportLowest403 and physical map boundaries.
/// H04 separately ports exact four-sphere triangle BodyClear/Dist2.
final class H55SpatialSupport580 {
    typealias Geometry=H55CollisionGeometry580.Geometry
    static let cellSize:Float=2
    private(set) var geometry:Geometry
    let cells:[Int64:[Int]]
    let proxyCells:[Int64:[Int]]
    var triangleCount:Int {geometry.triangles.count/9}
    var proxyCount:Int {geometry.objects.count}
    var cellCount:Int {cells.count}
    var proxyCellCount:Int {proxyCells.count}
    static func cell(_ p:Float)->Int {Int(floor(p/2))}
    static func key(_ x:Int,_ y:Int,_ z:Int)->Int64 {
        (Int64(x+1024)<<42) | (Int64(y+1024)<<21) | Int64(UInt32(truncatingIfNeeded:z+1024))
    }
    init(geometry:Geometry) {
        self.geometry=geometry
        let t=geometry.triangles
        var built=[Int64:[Int]](minimumCapacity:5000)
        for i in stride(from:0,to:t.count,by:9) {
            let minX=min(t[i],min(t[i+3],t[i+6]))
            let maxX=max(t[i],max(t[i+3],t[i+6]))
            let minY=min(t[i+1],min(t[i+4],t[i+7]))
            let maxY=max(t[i+1],max(t[i+4],t[i+7]))
            let minZ=min(t[i+2],min(t[i+5],t[i+8]))
            let maxZ=max(t[i+2],max(t[i+5],t[i+8]))
            for x in Self.cell(minX)...Self.cell(maxX) {
                for y in Self.cell(minY)...Self.cell(maxY) {
                    for z in Self.cell(minZ)...Self.cell(maxZ) {
                        built[Self.key(x,y,z),default:[]].append(i)
                    }
                }
            }
        }
        cells=built
        var proxies=[Int64:[Int]]()
        for (id,b) in geometry.objects.enumerated() {
            let minX=Self.cell(b.x0-0.40),maxX=Self.cell(b.x1+0.40)
            let minZ=Self.cell(b.z0-0.40),maxZ=Self.cell(b.z1+0.40)
            if maxX-minX>64 || maxZ-minZ>64 {continue}
            for x in minX...maxX {
                for z in minZ...maxZ {
                    proxies[Self.key(x,0,z),default:[]].append(id)
                }
            }
        }
        proxyCells=proxies
    }
    func h72Bounds(_ x:Float,_ z:Float,externalGLB:Bool=true)->Bool {
        if externalGLB {
            return x>=geometry.minX-0.5 && x<=geometry.maxX+0.5 &&
                   z>=geometry.minZ-0.5 && z<=geometry.maxZ+0.5
        }
        if x>=(-23.55) && x<=23.55 && z>=(-16.96) && z<=17.62 {return true}
        if x>=23.2 && x<=31.6 && z>=4.45 && z<=9.85 {return true}
        if x>=30.9 && x<=53.3 && z>=(-1.10) && z<=15.15 {return true}
        return false
    }
    func shipBlocks(_ x:Float,_ feet:Float,_ z:Float)->Bool {
        sqrt(x*x+z*z)<3.95 && feet<2.4 && feet+2.0>0.8
    }
    /// Original ProxyNear441: exact 3D point-to-AABB, with 50cm step trim.
    func proxyNear(_ x:Float,_ y:Float,_ z:Float,radius:Float,
                   feetLimit:Bool=false,footY:Float=0)->Float {
        guard let list=proxyCells[Self.key(Self.cell(x),0,Self.cell(z))]
        else{return 0}
        let rr=radius*radius
        var score:Float=0
        for id in list {
            let b=geometry.objects[id]
            if feetLimit && (b.y1<=footY+0.5 || b.y0>=footY+2.28) {continue}
            let dx=x<b.x0 ? b.x0-x : (x>b.x1 ? x-b.x1 : 0)
            let dy=y<b.y0 ? b.y0-y : (y>b.y1 ? y-b.y1 : 0)
            let dz=z<b.z0 ? b.z0-z : (z>b.z1 ? z-b.z1 : 0)
            let d2=dx*dx+dy*dy+dz*dz
            if d2<rr-0.001 {score+=rr-d2}
        }
        return score
    }
    func proxyCapsule(_ x:Float,_ feet:Float,_ z:Float,radius:Float)->Float {
        var score:Float=0
        for k in 0..<4 {
            score+=proxyNear(x,feet+(0.335+Float(k)*0.445),z,
                             radius:radius,feetLimit:true,footY:feet)
        }
        return score
    }
    /// Source Support/SupportLowest403: sample x/z ±4cm, slope squared,
    /// barycentric height and highest/lowest valid surface, regardless winding.
    private func support(_ x:Float,_ z:Float,_ low:Float,_ high:Float,
                         highest:Bool)->Float? {
        guard [x,z,low,high].allSatisfy({$0.isFinite}),low<=high else{return nil}
        let t=geometry.triangles
        var height=highest ? -Float.infinity : Float.infinity
        for ix in Self.cell(x-0.04)...Self.cell(x+0.04) {
            for iy in Self.cell(low-0.015)...Self.cell(high+0.015) {
                for iz in Self.cell(z-0.04)...Self.cell(z+0.04) {
                    guard let list=cells[Self.key(ix,iy,iz)] else{continue}
                    for i in list {
                        let ax=t[i],az=t[i+2],bx=t[i+3],bz=t[i+5],cx=t[i+6],cz=t[i+8]
                        let det=(bz-cz)*(ax-cx)+(cx-bx)*(az-cz)
                        if abs(det)<0.00000001 {continue}
                        let v=((bz-cz)*(x-cx)+(cx-bx)*(z-cz))/det
                        let w=((cz-az)*(x-cx)+(ax-cx)*(z-cz))/det
                        if v < -0.00001 || w < -0.00001 || v+w>1.00001 {continue}
                        let h=v*t[i+1]+w*t[i+4]+(1-v-w)*t[i+7]
                        if h<low-0.002 || h>high+0.002 {continue}
                        let abx=bx-ax,aby=t[i+4]-t[i+1],abz=bz-az
                        let acx=cx-ax,acy=t[i+7]-t[i+1],acz=cz-az
                        let nx=aby*acz-abz*acy,ny=abz*acx-abx*acz,nz=abx*acy-aby*acx
                        if ny*ny<(nx*nx+nz*nz)*0.65 {continue}
                        if highest ? (h>height) : (h<height) {height=h}
                    }
                }
            }
        }
        return height.isInfinite ? nil : height
    }
    func support(_ x:Float,_ z:Float,low:Float,high:Float)->Float? {
        support(x,z,low,high,highest:true)
    }
    func supportLowest403(_ x:Float,_ z:Float,low:Float,high:Float)->Float? {
        support(x,z,low,high,highest:false)
    }
}
