import Foundation

/// Original v568 Windows/src/GpuRobot70.cs + BossMesh65.cs "drone"
/// constructor: type 0 uses ShipMesh(0,false), type 1 uses
/// ShipMesh(1,false) (NOT the playable Vanguard431 GLB).
/// CARBONIS L1 uses Shooter71 type=0 ONLY (EnemyTier71 = 0).
/// All triangles are built from the procedural source primitives, with
/// 12 floats per corner for the existing Metal vertex pipeline. Coordinates,
/// per-part materials and authored source proportions are preserved.
/// Later enemy kinds 2–5 remain unported.
enum CarbonisShooterMesh71 {
    struct P {
        var x: Float, y: Float, z: Float
        init(_ x: Float=0,_ y: Float=0,_ z: Float=0) {
            self.x=x;self.y=y;self.z=z
        }
        static func +(a:P,b:P)->P {P(a.x+b.x,a.y+b.y,a.z+b.z)}
        static func -(a:P,b:P)->P {P(a.x-b.x,a.y-b.y,a.z-b.z)}
        static func *(a:P,b:Float)->P {P(a.x*b,a.y*b,a.z*b)}
        static func cross(_ a:P,_ b:P)->P {
            P(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x)
        }
        var length:Float {sqrt(x*x+y*y+z*z)}
        var unit:P { let n=length;return n>0.000000001 ? self*(1/n):P() }
        static func dot(_ a:P,_ b:P)->Float {a.x*b.x+a.y*b.y+a.z*b.z}
    }
    struct Triangle {
        var a:P,b:P,c:P,n:P
        var material:Int
    }
    struct Mesh {
        let vertices:[Float]
        let ranges:[Range<Int>]
        var triangleCount:Int {vertices.count/36}
    }
    private static func smoothPoint(_ before:P,_ a:P,_ b:P,
                                    _ after:P,_ t:Float)->P {
        let t2=t*t,t3=t2*t,tension:Float=0.72
        func curve(_ p:Float,_ q:Float,_ r:Float,_ s:Float)->Float {
            let a=(2*t3-3*t2+1)*q
            let b=(t3-2*t2+t)*tension*(r-p)*0.5
            let c=(-2*t3+3*t2)*r
            let d=(t3-t2)*tension*(s-q)*0.5
            return a+b+c+d
        }
        return P(curve(before.x,a.x,b.x,after.x),
                 a.y+(b.y-a.y)*t,
                 curve(before.z,a.z,b.z,after.z))
    }
    private static func ring(_ y:Float,_ w:Float,_ bottom:Float,
                             _ top:Float)->[P] {
        let base=[P(-w*0.62,y,bottom),P(-w,y,bottom*0.52),
                  P(-w,y,top*0.52),P(-w*0.58,y,top),
                  P(w*0.58,y,top),P(w,y,top*0.52),
                  P(w,y,bottom*0.52),P(w*0.62,y,bottom)]
        var result=[P]()
        for i in 0..<8 {
            for k in 0..<3 {
                result.append(smoothPoint(base[(i+7)%8],base[i],
                    base[(i+1)%8],base[(i+2)%8],Float(k)/3))
            }
        }
        return result
    }
    private static func curve55(_ a:[Float],_ r:Int,_ t:Float)->Float {
        let p=a[max(0,r-2)],q=a[r-1],v=a[r],w=a[min(a.count-1,r+1)]
        let term0=2*q
        let term1=(-p+v)*t
        let term2=(2*p-5*q+4*v-w)*t*t
        let term3=(-p+3*q-3*v+w)*t*t*t
        return 0.5*(term0+term1+term2+term3)
    }
    private struct Builder {
        let kind:Int
        var faces=[Triangle]()
        mutating func t(_ a:P,_ b:P,_ c:P,_ material:Int) {
            let aa=a*1.06,bb=b*1.06,cc=c*1.06
            let raw=P.cross(bb-aa,cc-aa)
            if raw.length>0.000000001 {
                faces.append(Triangle(a:aa,b:bb,c:cc,n:raw.unit,
                                      material:material))
            }
        }
        mutating func q(_ a:P,_ b:P,_ c:P,_ d:P,_ m:Int) {
            t(a,b,c,m);t(a,c,d,m)
        }
        mutating func poly(_ p:[P],_ m:Int,_ reverse:Bool) {
            for i in 1..<(p.count-1) {
                if reverse {t(p[0],p[i+1],p[i],m)}
                else{t(p[0],p[i],p[i+1],m)}
            }
        }
        mutating func box(_ x:Float,_ y:Float,_ z:Float,
                          _ w:Float,_ l:Float,_ h:Float,_ m:Int) {
            let a=P(x-w/2,y-l/2,z),b=P(x+w/2,y-l/2,z)
            let c=P(x+w/2,y+l/2,z),d=P(x-w/2,y+l/2,z)
            let aa=P(a.x,a.y,z+h),bb=P(b.x,b.y,z+h)
            let cc=P(c.x,c.y,z+h),dd=P(d.x,d.y,z+h)
            q(aa,bb,cc,dd,m);q(a,d,c,b,m);q(a,b,bb,aa,m)
            q(b,c,cc,bb,m);q(c,d,dd,cc,m);q(d,a,aa,dd,m)
        }
        mutating func wingPlate(_ outline:[P],_ sign:Int,
                                _ thickness:Float) {
            let count=outline.count*4
            var center=P()
            for p in outline { center=center+p }
            center=center*(1/Float(outline.count))
            let crown:Float=kind==0 ? 0.034 : 0.045
            center.z+=crown
            var edge=[P](),lower=[P]()
            for i in 0..<outline.count {
                for sub in 0..<4 {
                    let sample=CarbonisShooterMesh71.smoothPoint(
                        outline[(i+outline.count-1)%outline.count],
                        outline[i],outline[(i+1)%outline.count],
                        outline[(i+2)%outline.count],Float(sub)/4)
                    edge.append(sample)
                    lower.append(P(sample.x,sample.y,sample.z-thickness))
                }
            }
            var inner=[P](),middle=[P]()
            for i in 0..<count {
                var a=center+(edge[i]-center)*0.48
                a.z+=crown*0.22
                inner.append(a)
                var b=center+(edge[i]-center)*0.78
                b.z+=crown*0.07
                middle.append(b)
            }
            for i in 0..<count {
                let j=(i+1)%count
                if sign>0 {
                    t(center,inner[j],inner[i],0)
                    q(inner[i],inner[j],middle[j],middle[i],0)
                    q(middle[i],middle[j],edge[j],edge[i],0)
                    t(P(center.x,center.y,center.z-thickness),lower[i],lower[j],1)
                    q(edge[i],edge[j],lower[j],lower[i],3)
                }else{
                    t(center,inner[i],inner[j],0)
                    q(inner[i],middle[i],middle[j],inner[j],0)
                    q(middle[i],edge[i],edge[j],middle[j],0)
                    t(P(center.x,center.y,center.z-thickness),lower[j],lower[i],1)
                    q(edge[j],edge[i],lower[i],lower[j],3)
                }
            }
        }
        mutating func tube(_ x:Float,_ z:Float,_ ys:[Float],
                           _ radii:[Float],_ m:Int,_ sides:Int) {
            precondition(ys.count==radii.count)
            var previous:[P]?=nil
            for row in 0..<ys.count {
                var current=[P]()
                for i in 0..<sides {
                    let a=Float(i)*Float.pi*2/Float(sides)
                    current.append(P(x+cos(a)*radii[row],ys[row],
                                     z+sin(a)*radii[row]))
                }
                if let previous {
                    for i in 0..<sides {
                        let j=(i+1)%sides
                        q(previous[i],current[i],current[j],previous[j],m)
                    }
                }
                previous=current
            }
        }
        mutating func body() {
            let ys:[Float]=kind==0
                ? [-1.12,-0.72,-0.22,0.48,1.16,1.72,2.14]
                : [-1.08,-0.72,-0.22,0.38,1.02,1.48,1.94]
            let widths:[Float]=kind==0
                ? [0.20,0.27,0.29,0.24,0.15,0.075,0.008]
                : [0.30,0.43,0.44,0.34,0.23,0.13,0.012]
            let tops:[Float]=kind==0
                ? [0.14,0.20,0.24,0.26,0.15,0.07,0.005]
                : [0.16,0.24,0.25,0.27,0.18,0.09,0.006]
            var last=CarbonisShooterMesh71.ring(ys[0],widths[0],-0.13,tops[0])
            poly(last,1,true)
            for row in 1..<ys.count {
                for step in 1...4 {
                    let f=Float(step)/4
                    let next=CarbonisShooterMesh71.ring(
                        CarbonisShooterMesh71.curve55(ys,row,f),
                        max(0.006,CarbonisShooterMesh71.curve55(widths,row,f)),
                        -0.13*(1-(Float(row-1)+f)/7),
                        max(0.004,CarbonisShooterMesh71.curve55(tops,row,f)))
                    for i in 0..<24 {
                        let j=(i+1)%24
                        let band=i/3
                        q(last[i],last[j],next[j],next[i],
                          band==3 ? 0 : band==7 ? 1 : 3)
                    }
                    last=next
                }
            }
            poly(last,0,false)
        }
        mutating func wing(_ sign:Int) {
            if kind==1 {
                wingTypeOne(sign)
                return
            }
            var top=[P(0.19,0.40,0.05),P(0.88,-0.84,0.01),
                     P(0.73,-1.10,0.02),P(0.20,-0.82,0.09)]
            for i in top.indices { top[i].x*=Float(sign) }
            wingPlate(top,sign,0.07)
            let s=Float(sign)
            box(s*0.50,-0.62,0.056,0.07,0.54,0.018,4)
            box(s*0.72,-0.84,0.025,0.10,0.20,0.025,5)
        }
        /// Windows/src/ShipMesh.cs:60-65: distinct angular wing and
        /// titanium inlay of the SECOND source drone type.
        mutating func wingTypeOne(_ sign:Int) {
            let s=Float(sign)
            var outline=[P(0.27,0.64,0.025),P(1.19,-0.23,-0.03),
                         P(1.32,-0.83,-0.055),P(0.95,-0.99,-0.04),
                         P(0.29,-0.76,0.025)]
            for i in outline.indices { outline[i].x*=s }
            wingPlate(outline,sign,0.085)
            let a=P(s*0.49,0.24,0.038)
            let b=P(s*1.12,-0.38,-0.012)
            let c=P(s*1.16,-0.57,-0.026)
            let d=P(s*0.45,-0.02,0.044)
            if sign>0 {q(a,d,c,b,4)} else {q(a,b,c,d,4)}
            box(s*0.78,-0.66,-0.016,0.28,0.20,0.025,1)
            box(s*0.78,-0.66,0.011,0.19,0.11,0.008,3)
            for k in 0..<3 {
                box(s*(0.65+Float(k)*0.065),-0.80,-0.005,
                    0.034,0.095,0.008,4)
            }
            box(s*1.21,-0.76,0.004,0.055,0.20,0.04,1)
            box(s*1.21,-0.72,0.044,0.035,0.075,0.012,
                sign<0 ? 4:5)
        }

        mutating func engine(_ sign:Int) {
            let x=Float(sign)*0.43,z:Float=0.035
            tube(x,z,[-0.42,-0.64,-0.94,-1.17],[0.14,0.22,0.205,0.18],1,32)
            tube(x,z,[-0.76,-0.90,-1.07,-1.18],[0.221,0.217,0.193,0.182],3,32)
            tube(x,z,[-1.18,-1.19,-1.00],[0.182,0.125,0.10],7,32)
            let center=P(x,-1.001,z)
            for i in 0..<32 {
                let a=Float(i)*Float.pi/16,b=Float(i+1)*Float.pi/16
                t(center,P(x+cos(b)*0.104,-1.006,z+sin(b)*0.104),
                  P(x+cos(a)*0.104,-1.006,z+sin(a)*0.104),6)
            }
            tube(x,z,[-1.18,-1.191],[0.126,0.124],5,32)
            for k in 0..<8 {
                let a=Float(k)*Float.pi/4
                box(x+cos(a)*0.208,-0.91,z+sin(a)*0.208,0.018,0.17,0.018,7)
            }
            box(x,-0.46,0.17,0.14,0.28,0.065,0)
        }
        mutating func gun(_ sign:Int) {
            let x=Float(sign)*(kind==0 ? 0.62 : 0.93)
            tube(x,0.045,[0.48,0.37,0.14,-0.17,-0.43,-0.66],
                 [0.025,0.05,0.075,0.085,0.065,0.03],1,16)
            tube(x,0.045,[0.35,0.37,0.40],[0.066,0.066,0.044],3,16)
            box(x,-0.11,0.10,0.09,0.26,0.04,4)
            tube(x,0.045,[0.43,0.485],[0.026,0.026],5,16)
        }
        mutating func canopy() {
            let low=[P(0,0.98,0.194),P(-0.18,0.58,0.265),
                     P(-0.21,0.10,0.270),P(-0.12,-0.20,0.270),
                     P(0.12,-0.20,0.270),P(0.21,0.10,0.270),
                     P(0.18,0.58,0.265)]
            let high=[P(0,0.83,0.34),P(-0.125,0.48,0.49),
                      P(-0.145,0.14,0.515),P(-0.085,-0.11,0.39),
                      P(0.085,-0.11,0.39),P(0.145,0.14,0.515),
                      P(0.125,0.48,0.49)]
            for i in low.indices {
                let j=(i+1)%low.count
                q(low[i],low[j],high[j],high[i],i==3 ? 1:2)
            }
            poly(high,2,false)
            q(P(-0.146,0.13,0.518),P(0.146,0.13,0.518),
              P(0.146,0.163,0.518),P(-0.146,0.163,0.518),3)
            box(0,-0.16,0.28,0.21,0.045,0.018,7)
        }
        mutating func fin(_ sign:Int) {
            let s=Float(sign)
            let a=P(s*0.26,-0.90,0.19),
                b=P(s*0.26,-0.23,0.23),
                c=P(s*0.40,-0.76,0.69)
            let aa=P(a.x+s*0.045,a.y,a.z),
                bb=P(b.x+s*0.045,b.y,b.z),
                cc=P(c.x+s*0.045,c.y,c.z)
            t(a,b,c,0);t(aa,cc,bb,1);q(a,c,cc,aa,3)
            q(b,bb,cc,c,3);q(a,aa,bb,b,1)
            q(P(c.x,-0.77,0.60),P(c.x+s*0.046,-0.77,0.60),cc,c,4)
        }
        mutating func detail() {
            for sign:Int in [-1,1] {
                let s=Float(sign),x=s*0.43
                tube(x,0.035,[-0.41,-0.39,-0.37],
                     [0.143,0.147,0.126],3,32)
                tube(x,0.035,[-0.38,-0.44],[0.122,0.111],1,32)
                for i in 0..<24 {
                    let a=Float(i)*Float.pi/12,c=a+0.14
                    q(P(x+cos(a)*0.04,-0.425,0.035+sin(a)*0.04),
                      P(x+cos(c)*0.12,-0.43,0.035+sin(c)*0.12),
                      P(x+cos(c+0.06)*0.12,-0.43,0.035+sin(c+0.06)*0.12),
                      P(x+cos(a+0.1)*0.04,-0.425,0.035+sin(a+0.1)*0.04),3)
                }
                tube(x,0.035,[-0.43,-0.34,-0.32],
                     [0.042,0.018,0.002],3,24)
                for i in 0..<4 {
                    let k=Float(i)
                    tube(x,0.035,[-0.72-k*0.085,-0.73-k*0.085],
                         [0.225-k*0.009,0.225-k*0.009],7,32)
                }
                for i in 0..<6 {
                    let k=Float(i)
                    box(s*0.23,-0.73+k*0.075,0.25,0.075,0.025,0.024,1)
                    box(s*0.23,-0.73+k*0.075,0.275,0.06,0.009,0.006,3)
                }
                let detailX=s*(kind==0 ? 0.55 : 1.05)
                box(detailX,-0.82,0.065,0.08,0.15,0.035,3)
                box(detailX,-0.80,0.102,0.045,0.03,0.01,sign<0 ? 4:5)
                box(s*0.14,0.62,0.23,0.026,0.23,0.018,3)
            }
            box(0,-0.46,0.27,0.035,0.18,0.18,3)
            tube(0,0.18,[1.12,1.26,1.32],
                 [0.04,0.028,0.005],1,16)
        }
        mutating func build() {
            body()
            for sign:Int in [-1,1] {
                let s=Float(sign)
                wing(sign);engine(sign);gun(sign);fin(sign)
                box(s*0.31,0.02,0.205,0.12,0.45,0.05,1)
                for i in 0..<5 {
                    box(s*0.31,-0.15+Float(i)*0.078,0.263,
                        0.12,0.019,0.021,3)
                }
                box(s*0.30,0.73,0.12,0.035,0.12,0.01,5)
            }
            canopy()
            if kind==0 {
                box(0,-0.66,0.30,0.055,0.42,0.30,3)
            }
            box(0,1.30,0.11,0.07,0.22,0.018,4)
            box(0,-0.63,0.247,0.075,0.38,0.025,7)
            detail()
        }
    }

    /// GpuRobot70.cs:5-6: source drone color grouping. All material
    /// slots 4–7 share (255,80+kind*12,45); kind 0/1 differ.
    private static func palette(_ kind:Int)->[(Float,Float,Float)] {
        let accent:Float=Float(80+kind*12)
        return [(100,115,130),(32,40,52),(240,100,45),(145,164,180),
                (255,accent,45),(255,accent,45),(255,accent,45),(255,accent,45)]
    }
    private struct Key:Hashable {
        let x:Int,y:Int,z:Int,material:Int
        init(_ p:P,_ mat:Int) {
            x=Int((p.x*10000).rounded(.toNearestOrEven))
            y=Int((p.y*10000).rounded(.toNearestOrEven))
            z=Int((p.z*10000).rounded(.toNearestOrEven))
            material=mat
        }
    }
    static func typeZero()->Mesh {build(kind:0)}
    static func typeOne()->Mesh {build(kind:1)}

    /// Only source types actually implemented in this function may be used.
    /// The playable player craft is handled separately by Vanguard431Source.
    private static func build(kind:Int)->Mesh {
        precondition(kind==0 || kind==1)
        var builder=Builder(kind:kind)
        builder.build()
        let palette=palette(kind)
        // Source ShipMesh.CacheNormal and Add: smooth only 1,2,3,7,
        // with per-material/per-position normalization threshold dot>.74.
        var normals:[Key:[P]] = [:]
        for face in builder.faces {
            for p in [face.a,face.b,face.c] {
                normals[Key(p,face.material),default:[]].append(face.n)
            }
        }
        var vertices:[Float]=[]
        vertices.reserveCapacity(builder.faces.count*36)
        var ranges=[Range<Int>]()
        for material in 0..<8 {
            let start=vertices.count/12
            for f in builder.faces where f.material==material {
                let rgb=palette[material]
                for p in [f.a,f.b,f.c] {
                    var n=f.n
                    if [1,2,3,7].contains(material) {
                        var sum=P()
                        for entry in normals[Key(p,material),default:[]] {
                            if P.dot(n,entry)>0.74 {sum=sum+entry}
                        }
                        if sum.length>0 {n=sum.unit}
                    }
                    vertices.append(contentsOf:[
                        p.x,p.y,p.z,n.x,n.y,n.z,
                        rgb.0/255,rgb.1/255,rgb.2/255,1,0,0
                    ])
                }
            }
            ranges.append(start..<(vertices.count/12))
        }
        return Mesh(vertices:vertices,ranges:ranges)
    }
}