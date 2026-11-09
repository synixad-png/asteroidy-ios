import Foundation

/// Exact PC v580 HangarDrone451.cs DroneNav453 lattice and collision gates.
/// The sole collision callback is H55SpatialSupport580.cameraClear406;
/// no SceneKit hitTest/raycast and no invented clearance geometry.
final class H55DroneNavigation580 {
    struct Node {
        let x:Float,y:Float,z:Float
        var open:Bool
        var edges:[Int]=[]
        var component:Int = -1
    }
    static let radius:Float=0.63
    private static let nx=37,nz=16,ny=3
    private static let levels:[Float]=[2.8,4.25,5.7]
    private let clearance:(Float,Float,Float,Float)->Bool
    private(set) var nodes:[Node]=[]
    private(set) var edgeCount=0
    private(set) var componentCount=0
    private(set) var reachable=0
    private(set) var openCount=0

    private static func index(_ x:Int,_ z:Int,_ y:Int)->Int {
        (y*nz+z)*nx+x
    }
    static func interior(_ x:Float,_ z:Float)->Bool {
        (x >= -19.2 && x <= 20.8 && z >= -13.2 && z <= 15.2) ||
        (x >= 19.3 && x <= 33.9 && z >= 5.2 && z <= 9.0) ||
        (x >= 32.5 && x <= 51.0 && z >= 0.65 && z <= 13.5)
    }
    init(clearance:@escaping (Float,Float,Float,Float)->Bool) {
        self.clearance=clearance
        build()
    }
    func clear(_ x:Float,_ y:Float,_ z:Float,
               takeoff:Bool=false)->Bool {
        guard x.isFinite,y.isFinite,z.isFinite,
              Self.interior(x,z),
              y >= (takeoff ? 0.77 : 1.96),y<=6.9,
              clearance(x,y,z,Self.radius) else {return false}
        // The docked central ship is separately rendered, and its
        // collision is not part of the GLB static triangle scene.
        if x*x+z*z<4.8*4.8 && y<5.7 {return false}
        return true
    }
    func airspace(_ x:Float,_ y:Float,_ z:Float)->Bool {
        let side:Float=0.75
        return clear(x,y,z) && clear(x+side,y,z) &&
            clear(x-side,y,z) && clear(x,y,z+side) &&
            clear(x,y,z-side)
    }
    func segment(_ a:SIMD3<Float>,_ b:SIMD3<Float>,
                 takeoff:Bool=false)->Bool {
        let d=b-a
        let len=sqrt(d.x*d.x+d.y*d.y+d.z*d.z)
        guard len.isFinite else{return false}
        let steps=max(1,Int(ceil(len/0.42)))
        for i in 1...steps {
            let p=a+d*(Float(i)/Float(steps))
            if takeoff {
                if !clear(p.x,p.y,p.z,takeoff:true){return false}
            } else if !airspace(p.x,p.y,p.z){return false}
        }
        return true
    }
    private func build() {
        // PC 37*16*3 fixed 2-metre nodes, not a runtime generated NavMesh.
        for iy in 0..<Self.ny {
            for iz in 0..<Self.nz {
                for ix in 0..<Self.nx {
                    let x:Float = -21+Float(ix)*2
                    let z:Float = -15+Float(iz)*2
                    let y=Self.levels[iy]
                    let open=airspace(x,y,z)
                    nodes.append(Node(x:x,y:y,z:z,open:open))
                    if open {openCount+=1}
                }
            }
        }
        for iy in 0..<Self.ny {
            for iz in 0..<Self.nz {
                for ix in 0..<Self.nx {
                    let id=Self.index(ix,iz,iy)
                    guard nodes[id].open else{continue}
                    let neighborIndices=[
                        (ix+1,iz,iy),(ix-1,iz,iy),
                        (ix,iz+1,iy),(ix,iz-1,iy),
                        (ix,iz,iy+1),(ix,iz,iy-1)
                    ]
                    let point=position(id)
                    for (x,z,y) in neighborIndices {
                        if x<0 || x>=Self.nx || z<0 || z>=Self.nz ||
                           y<0 || y>=Self.ny {continue}
                        let j=Self.index(x,z,y)
                        if nodes[j].open && segment(point,position(j)) {
                            nodes[id].edges.append(j)
                            edgeCount+=1
                        }
                    }
                }
            }
        }
        // Source H71 connector dogleg over the lower lip, not a teleport.
        let bridgeBase=nodes.count
        let bridgeHeights:[Float]=[4.25,3.7,3.2,2.8]
        for height in bridgeHeights {
            let open=airspace(20,height,7)
            nodes.append(Node(x:20,y:height,z:7,open:open))
            if open {openCount+=1}
        }
        link(Self.index(20,11,1),bridgeBase)
        for i in 1..<4 {link(bridgeBase+i-1,bridgeBase+i)}
        link(bridgeBase+3,Self.index(21,11,0))
        link(bridgeBase+2,Self.index(21,11,0))
        // Exact bounded FIFO flood fill: each vertex enqueued once.
        for first in nodes.indices where nodes[first].open &&
                                   nodes[first].component<0 {
            var queue=[first],head=0,count=0
            nodes[first].component=componentCount
            while head<queue.count {
                let here=queue[head]
                head+=1;count+=1
                for neighbor in nodes[here].edges {
                    if nodes[neighbor].component>=0 {continue}
                    nodes[neighbor].component=componentCount
                    queue.append(neighbor)
                }
            }
            reachable=max(reachable,count)
            componentCount+=1
        }
    }
    private func link(_ a:Int,_ b:Int) {
        guard nodes.indices.contains(a),nodes.indices.contains(b),
              nodes[a].open,nodes[b].open,
              segment(position(a),position(b)) else{return}
        if !nodes[a].edges.contains(b) {
            nodes[a].edges.append(b);edgeCount+=1
        }
        if !nodes[b].edges.contains(a) {
            nodes[b].edges.append(a);edgeCount+=1
        }
    }
    func position(_ id:Int)->SIMD3<Float> {
        let n=nodes[id]
        return SIMD3<Float>(n.x,n.y,n.z)
    }
    func closest(to point:SIMD3<Float>,component:Int?=nil)->Int? {
        var best:Float = .infinity,result:Int?
        for i in nodes.indices where nodes[i].open {
            let node=nodes[i]
            if let component,node.component != component {continue}
            let d=position(i)-point
            let dist=d.x*d.x+d.y*d.y+d.z*d.z
            if dist<best && dist<64 &&
               segment(point,position(i)) {
                best=dist;result=i
            }
        }
        return result
    }
    func egress(from point:SIMD3<Float>)->Int? {
        var best:Float=81,result:Int?
        for i in nodes.indices where nodes[i].open {
            let d=position(i)-point
            let dist=d.x*d.x+d.y*d.y+d.z*d.z
            if dist<best &&
               segment(point,position(i),takeoff:true) {
                best=dist;result=i
            }
        }
        return result
    }
    /// PC v545: 0.72m above original root, then ten 0.2m elevations;
    /// verify 2m vertical takeoff and a reachable egress node.
    func launch(_ root:SIMD3<Float>)->(y:Float,exit:Int)? {
        guard root.y.isFinite,root.y >= -0.5,root.y<=3.2 else {
            return nil
        }
        let start=max(Float(0.80),root.y+0.72)
        for i in 0...10 {
            let y=start+Float(i)*0.20
            if y>4.2 || y+2>6.9 {break}
            let a=SIMD3<Float>(root.x,y,root.z)
            let b=SIMD3<Float>(root.x,y+2,root.z)
            guard clear(a.x,a.y,a.z,takeoff:true),
                  segment(a,b,takeoff:true),
                  let exit=egress(from:b) else{continue}
            return (y,exit)
        }
        return nil
    }
    func route(from start:Int,to goal:Int)->[Int] {
        guard nodes.indices.contains(start),nodes.indices.contains(goal),
              nodes[start].open,nodes[goal].open,
              nodes[start].component==nodes[goal].component else {
            return []
        }
        var previous=[Int](repeating:-1,count:nodes.count)
        var queue=[start],head=0
        previous[start]=start
        while head<queue.count && previous[goal]<0 {
            let here=queue[head];head+=1
            for next in nodes[here].edges where previous[next]<0 {
                previous[next]=here;queue.append(next)
            }
        }
        guard previous[goal]>=0 else{return []}
        var reversed=[Int](),at=goal
        while at != start {
            reversed.append(at)
            at=previous[at]
            if reversed.count>nodes.count{return []}
        }
        reversed.append(start)
        return reversed.reversed()
    }
}
