import Foundation

/// Procedural cratered asteroid meshes ported from the ACTUAL
/// Windows/src/GpuIntro41.cs:13-21 (IntroStone, StoneNormal56,
/// StoneFace, StoneSubdivide56) and PlanetLife52.Basis.
///
/// Pure Swift: no Metal dependency. Each rock keeps its source seed,
/// size, face subdivision (2/3) and per-vertex normal/tint. On iOS,
/// create geometry for only visible rocks, cache up to a bounded count.
/// The world-space orbit is supplied separately by IntroOrbit41.
enum IntroRockGeometry41 {
    typealias V = SphereVector3
    private static let golden:Float=1.618
    private static let originalVertices:[V] = [
        V(x:-1,y:golden,z:0),V(x:1,y:golden,z:0),
        V(x:-1,y:-golden,z:0),V(x:1,y:-golden,z:0),
        V(x:0,y:-1,z:golden),V(x:0,y:1,z:golden),
        V(x:0,y:-1,z:-golden),V(x:0,y:1,z:-golden),
        V(x:golden,y:0,z:-1),V(x:golden,y:0,z:1),
        V(x:-golden,y:0,z:-1),V(x:-golden,y:0,z:1)
    ]
    private static let faces:[Int] = [
        0,11,5, 0,5,1, 0,1,7, 0,7,10, 0,10,11,
        1,5,9, 5,11,4, 11,10,2, 10,7,6, 7,1,8,
        3,9,4, 3,4,2, 3,2,6, 3,6,8, 3,8,9,
        4,9,5, 2,4,11, 6,2,10, 8,6,7, 9,8,1
    ]
    // Source Windows GpuIntro41.IntroStone; three craters at their
    // original world angles, and seed-specific roughness/polar shapes.
    static func stone(_ direction:V,seed:Float)->V {
        let p=direction.normalized
        var radius:Float=0.91
        radius+=0.065*sin(p.x*4+p.y*3+p.z*5+seed)
        radius+=0.022*sin(p.x*21-p.y*18+p.z*16+seed*2)
        for i in 0..<3 {
            let f=Float(i)
            let crater=V(x:sin(seed*1.3+f*4),
                         y:cos(seed*0.7+f*7),
                         z:sin(seed*0.9-f*3)).normalized
            let q=(p-crater).length
            radius-=0.095*exp(-q*q/(0.04+f*0.014))
        }
        return V(x:p.x*radius*(0.8+0.25*sin(seed)),
                 y:p.y*radius,
                 z:p.z*radius*(1.1+0.2*cos(seed)))
    }
    // Exactly PlanetLife52.Basis: r=cross(n, y/up) except at poles;
    // f=cross(r,n). Then source finite differences and outward fix.
    static func stoneNormal(_ direction:V,seed:Float)->V {
        let p=direction.normalized
        let axis=abs(p.y)<0.9 ? V(x:0,y:1,z:0) : V(x:1,y:0,z:0)
        let right=V.cross(p,axis).normalized
        let forward=V.cross(right,p).normalized
        let dx=stone((p+right*0.001).normalized,seed:seed) -
               stone((p-right*0.001).normalized,seed:seed)
        let dy=stone((p+forward*0.001).normalized,seed:seed) -
               stone((p-forward*0.001).normalized,seed:seed)
        let normal=V.cross(dx,dy).normalized
        return V.dot(normal,p)<0 ? normal * -1 : normal
    }
    private static func addFace(_ a:V,_ b:V,_ c:V,size:Float,seed:Float,
                                vertices:inout [AssetMesh.Vertex],
                                indices:inout [UInt32]) {
        var dirs=[a.normalized,b.normalized,c.normalized]
        var local=[stone(dirs[0],seed:seed)*size,
                   stone(dirs[1],seed:seed)*size,
                   stone(dirs[2],seed:seed)*size]
        if V.dot(V.cross(local[1]-local[0],local[2]-local[0]),
                 local[0])<0 {
            local.swapAt(1,2)
            dirs.swapAt(1,2)
        }
        let inv=IntroOrbit41.radiusNormalization
        for i in 0..<3 {
            let d=dirs[i],p=local[i]*inv
            let n=stoneNormal(d,seed:seed)
            let shade:Float=0.70+0.08*sin(seed+d.x*13+d.z*11)
            var red=shade*0.58,green=shade*0.62,blue=shade*0.69
            if Int(seed)%7==0 {red *= 1.3;green *= 1.13;blue *= 0.9}
            let vertex=AssetMesh.Vertex(
                position:SIMD4<Float>(p.x,p.y,p.z,1),
                color:SIMD4<Float>(red,green,blue,1),
                normal:SIMD4<Float>(n.x,n.y,n.z,0))
            indices.append(UInt32(vertices.count))
            vertices.append(vertex)
        }
    }
    private static func subdivide(_ a:V,_ b:V,_ c:V,
                                  size:Float,seed:Float,depth:Int,
                                  vertices:inout [AssetMesh.Vertex],
                                  indices:inout [UInt32]) {
        if depth==0 {
            addFace(a,b,c,size:size,seed:seed,vertices:&vertices,indices:&indices)
            return
        }
        let ab=(a+b).normalized,bc=(b+c).normalized,ca=(c+a).normalized
        subdivide(a,ab,ca,size:size,seed:seed,depth:depth-1,
                  vertices:&vertices,indices:&indices)
        subdivide(ab,b,bc,size:size,seed:seed,depth:depth-1,
                  vertices:&vertices,indices:&indices)
        subdivide(ca,bc,c,size:size,seed:seed,depth:depth-1,
                  vertices:&vertices,indices:&indices)
        subdivide(ab,bc,ca,size:size,seed:seed,depth:depth-1,
                  vertices:&vertices,indices:&indices)
    }
    static func geometry(_ rock:IntroOrbit41.Stone)
        -> (vertices:[AssetMesh.Vertex],indices:[UInt32]) {
        let depth=rock.size>1.15 ? 3 : 2 // original >1.15 threshold
        let triangles=20*(depth==3 ? 64 : 16)
        var vertices:[AssetMesh.Vertex]=[]
        var indices:[UInt32]=[]
        vertices.reserveCapacity(triangles*3)
        indices.reserveCapacity(triangles*3)
        for f in stride(from:0,to:faces.count,by:3) {
            subdivide(originalVertices[faces[f]].normalized,
                      originalVertices[faces[f+1]].normalized,
                      originalVertices[faces[f+2]].normalized,
                      size:rock.size,seed:rock.seed,depth:depth,
                      vertices:&vertices,indices:&indices)
        }
        return (vertices,indices)
    }
}
