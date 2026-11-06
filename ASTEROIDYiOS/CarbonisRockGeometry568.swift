import Foundation

/// RockVertices75: exact two-level StoneSubdivide56 source shape construction
/// (Windows v568 GpuIntro41.cs:13-18, GpuSphere67.cs:123-124).
/// Source rock vertex stride 10 plus two unused UVs for existing Metal
/// CARBONIS pipeline stride 12; positions/normals/rgba stay source-derived.
enum CarbonisRockGeometry568 {
    struct V3 {
        var x:Float,y:Float,z:Float
        static func +(a:Self,b:Self)->Self { .init(x:a.x+b.x,y:a.y+b.y,z:a.z+b.z) }
        static func -(a:Self,b:Self)->Self { .init(x:a.x-b.x,y:a.y-b.y,z:a.z-b.z) }
        static func *(a:Self,k:Float)->Self { .init(x:a.x*k,y:a.y*k,z:a.z*k) }
        static func /(a:Self,k:Float)->Self { a*(1/k) }
        var length:Float { sqrt(x*x+y*y+z*z) }
        var unit:Self { let l=length;return l>1e-12 ? self/l : .init(x:0,y:0,z:0) }
        static func dot(_ a:Self,_ b:Self)->Float { a.x*b.x+a.y*b.y+a.z*b.z }
        static func cross(_ a:Self,_ b:Self)->Self {
            .init(x:a.y*b.z-a.z*b.y,y:a.z*b.x-a.x*b.z,z:a.x*b.y-a.y*b.x)
        }
    }
    static let ico:[V3] = [
        .init(x:-1,y:1.618,z:0),.init(x:1,y:1.618,z:0),
        .init(x:-1,y:-1.618,z:0),.init(x:1,y:-1.618,z:0),
        .init(x:0,y:-1,z:1.618),.init(x:0,y:1,z:1.618),
        .init(x:0,y:-1,z:-1.618),.init(x:0,y:1,z:-1.618),
        .init(x:1.618,y:0,z:-1),.init(x:1.618,y:0,z:1),
        .init(x:-1.618,y:0,z:-1),.init(x:-1.618,y:0,z:1)
    ]
    static let faces:[Int] = [
        0,11,5,0,5,1,0,1,7,0,7,10,0,10,11,1,5,9,5,11,4,
        11,10,2,10,7,6,7,1,8,3,9,4,3,4,2,3,2,6,3,6,8,
        3,8,9,4,9,5,2,4,11,6,2,10,8,6,7,9,8,1
    ]
    static let sourceVertexCount=20*16*3
    static let gpuStride=12
    private static let palette:[V3] = [
        .init(x:128,y:158,z:193),.init(x:235,y:174,z:73),
        .init(x:176,y:108,z:238),.init(x:226,y:83,z:108),
        .init(x:94,y:213,z:139)
    ]
    static func stone(_ d:V3,seed:Float)->V3 {
        let p=d.unit
        var radius:Float=0.91+0.065*sin(p.x*4+p.y*3+p.z*5+seed)
            +0.022*sin(p.x*21-p.y*18+p.z*16+seed*2)
        for i in 0..<3 {
            let k=Float(i)
            let crater=V3(x:sin(seed*1.3+k*4),
                          y:cos(seed*0.7+k*7),
                          z:sin(seed*0.9-k*3)).unit
            let q=(p-crater).length
            radius -= 0.095*exp(-q*q/(0.04+k*0.014))
        }
        return .init(x:p.x*radius*(0.8+0.25*sin(seed)),
                     y:p.y*radius,
                     z:p.z*radius*(1.1+0.2*cos(seed)))
    }
    static func stoneNormal(_ d:V3,seed:Float)->V3 {
        let p=d.unit
        let axis=abs(p.y)<0.9 ? V3(x:0,y:1,z:0) : V3(x:1,y:0,z:0)
        let r=V3.cross(p,axis).unit,f=V3.cross(r,p).unit
        let du=stone((p+r*0.001).unit,seed:seed) -
            stone((p-r*0.001).unit,seed:seed)
        let dv=stone((p+f*0.001).unit,seed:seed) -
            stone((p-f*0.001).unit,seed:seed)
        var n=V3.cross(du,dv).unit
        if V3.dot(n,p)<0 {n=n * -1}
        return n
    }
    private static func triangle(_ a:V3,_ b:V3,_ c:V3,seed:Float,
                                 tint:V3,result:inout [Float]) {
        let directions=[a.unit,b.unit,c.unit]
        var pts=directions.map{stone($0,seed:seed)}
        var axes=directions
        if V3.dot(V3.cross(pts[1]-pts[0],pts[2]-pts[0]),pts[0])<0 {
            pts.swapAt(1,2);axes.swapAt(1,2)
        }
        for i in 0..<3 {
            let p=pts[i],n=stoneNormal(axes[i],seed:seed)
            let shade:Float=0.70+0.08*sin(seed+axes[i].x*13+axes[i].z*11)
            let light:Float=0.85+shade*0.62*0.2
            result.append(contentsOf:[p.x,p.y,p.z,n.x,n.y,n.z,
                                      tint.x/255*light,tint.y/255*light,
                                      tint.z/255*light,1,0,0])
        }
    }
    private static func subdivide(_ a:V3,_ b:V3,_ c:V3,depth:Int,
                                  seed:Float,tint:V3,result:inout [Float]) {
        if depth==0 {triangle(a,b,c,seed:seed,tint:tint,result:&result);return}
        let ab=(a+b).unit,bc=(b+c).unit,ca=(c+a).unit
        subdivide(a,ab,ca,depth:depth-1,seed:seed,tint:tint,result:&result)
        subdivide(ab,b,bc,depth:depth-1,seed:seed,tint:tint,result:&result)
        subdivide(ca,bc,c,depth:depth-1,seed:seed,tint:tint,result:&result)
        subdivide(ab,bc,ca,depth:depth-1,seed:seed,tint:tint,result:&result)
    }
    static func shape(for rock:SphereAsteroid556)->Int {
        (rock.shapeSeed & 7)*5+max(0,min(4,rock.tier))+(rock.fragment ? 40 : 0)
    }
    static func vertices(shape:Int)->[Float] {
        precondition((0..<85).contains(shape))
        let color=palette[shape%5]
        let tint:V3
        if shape>=40 {
            let gray=Int((color.x*30+color.y*59+color.z*11)/100)
            let stone=90+gray/4
            tint=V3(x:Float(stone-7),y:Float(stone),z:Float(stone+9))
        } else {tint=color}
        let seed=Float((shape%40)/5+13)
        var result:[Float]=[]
        result.reserveCapacity(sourceVertexCount*gpuStride)
        for i in stride(from:0,to:faces.count,by:3) {
            subdivide(ico[faces[i]].unit,ico[faces[i+1]].unit,
                      ico[faces[i+2]].unit,depth:2,seed:seed,
                      tint:tint,result:&result)
        }
        return result
    }
}
