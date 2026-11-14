import Foundation

/// Exact PC v609 BossMesh65 robot constructors (GpuRobot70.cs):
/// head=0, armored segment=1, connector=2. Original Shell/Armor/Face/
/// Tube/Ring/Core primitives, per-part transforms, palette and tessellation.
/// The existing Metal source-triangle ABI owns buffers and lighting.
enum SourceRobotMesh70 {
    struct Point {
        var x:Float,y:Float,z:Float
        init(_ x:Float,_ y:Float,_ z:Float){self.x=x;self.y=y;self.z=z}
        static func +(a:Self,b:Self)->Self {Self(a.x+b.x,a.y+b.y,a.z+b.z)}
        static func -(a:Self,b:Self)->Self {Self(a.x-b.x,a.y-b.y,a.z-b.z)}
        static func *(a:Self,b:Float)->Self {Self(a.x*b,a.y*b,a.z*b)}
        static func cross(_ a:Self,_ b:Self)->Self {
            Self(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x)
        }
        static func dot(_ a:Self,_ b:Self)->Float {a.x*b.x+a.y*b.y+a.z*b.z}
        var unit:Self {
            let n=sqrt(Self.dot(self,self))
            return n>0.000000001 ? self*(1/n):Self(0,0,0)
        }
    }
    struct Tint {
        let r:Float,g:Float,b:Float
        init(_ r:Float,_ g:Float,_ b:Float) {
            self.r=r/255;self.g=g/255;self.b=b/255
        }
        func shade(_ q:Float)->Self {
            // C# Shade truncates integer RGB and caps at 255.
            Self(Float(Int(min(255,r*255*q))),
                 Float(Int(min(255,g*255*q))),
                 Float(Int(min(255,b*255*q))))
        }
    }
    private static let steel=Tint(145,164,180)
    private static let dark=Tint(32,40,52)
    private static let bone=Tint(218,213,186)
    private static let red=Tint(230,72,35)
    private static let amber=Tint(255,171,56)

    private struct Builder {
        var floats=[Float]()
        var shift=Point(0,0,0)
        var tiltX90=false
        mutating func part(_ x:Float=0,_ y:Float=0,_ z:Float=0,
                           rotateX90:Bool=false,_ build:(inout Self)->Void) {
            let previous=shift,rotated=tiltX90
            shift=Point(x,y,z)
            tiltX90=rotateX90
            build(&self)
            shift=previous;tiltX90=rotated
        }
        func transformed(_ p:Point)->Point {
            let q=tiltX90 ? Point(p.x,-p.z,p.y):p
            return q+shift
        }
        mutating func tri(_ p:Point,_ q:Point,_ r:Point,_ tint:Tint) {
            let a=transformed(p),b=transformed(q),c=transformed(r)
            let raw=Point.cross(b-a,c-a)
            if Point.dot(raw,raw)<0.000000000000001 {return}
            let n=raw.unit
            for v in [a,b,c] {
                floats.append(contentsOf:[
                    v.x,v.y,v.z,n.x,n.y,n.z,
                    tint.r,tint.g,tint.b,1,0,0
                ])
            }
        }
        mutating func quad(_ a:Point,_ b:Point,_ c:Point,_ d:Point,_ t:Tint) {
            tri(a,b,c,t);tri(a,c,d,t)
        }
        func ball(_ c:Point,_ x:Float,_ y:Float,_ z:Float,
                  _ a:Float,_ b:Float)->Point {
            c+Point(x*cos(a)*cos(b),y*sin(a)*cos(b),z*sin(b))
        }
        mutating func shell(_ x:Float,_ y:Float,_ z:Float,
                            _ rx:Float,_ ry:Float,_ rz:Float,
                            _ color:Tint,_ rows:Int=12,_ cols:Int=32) {
            let center=Point(x,y,z)
            for row in 0..<rows {
                for i in 0..<cols {
                    let a=Float(i)*2*Float.pi/Float(cols)
                    let aa=Float(i+1)*2*Float.pi/Float(cols)
                    let b = -Float.pi/2+Float(row)*Float.pi/Float(rows)
                    let bb = -Float.pi/2+Float(row+1)*Float.pi/Float(rows)
                    let p=ball(center,rx,ry,rz,a,b)
                    let q=ball(center,rx,ry,rz,aa,b)
                    let s=ball(center,rx,ry,rz,aa,bb)
                    let t=ball(center,rx,ry,rz,a,bb)
                    if row>0 {tri(p,q,s,color.shade(0.94+Float(i%5)*0.024))}
                    if row<rows-1 {tri(p,s,t,color)}
                }
            }
        }
        mutating func tube(_ a:Point,_ b:Point,
                           _ radius:Float,_ tip:Float,
                           _ color:Tint,_ sides:Int=24) {
            let y=(b-a).unit
            let x=Point.cross(y,abs(y.z)<0.9
                ? Point(0,0,1):Point(0,1,0)).unit
            let z=Point.cross(x,y)
            for i in 0..<sides {
                let v=Float(i)*2*Float.pi/Float(sides)
                let w=Float(i+1)*2*Float.pi/Float(sides)
                let p=x*cos(v)+z*sin(v)
                let q=x*cos(w)+z*sin(w)
                quad(a+p*radius,a+q*radius,b+q*tip,b+p*tip,color)
                tri(a,a+q*radius,a+p*radius,color.shade(0.65))
                if tip>0 {tri(b,b+p*tip,b+q*tip,color.shade(1.15))}
            }
        }
        func torus(_ x:Float,_ y:Float,_ z:Float,_ r:Float,
                   _ t:Float,_ a:Float,_ b:Float)->Point {
            let rt=r+t*cos(b)
            return Point(x+rt*cos(a),y+rt*sin(a),z+t*sin(b))
        }
        mutating func ring(_ x:Float,_ y:Float,_ z:Float,
                           _ radius:Float,_ tube:Float,
                           _ color:Tint,_ sides:Int=48) {
            for i in 0..<sides {
                for j in 0..<10 {
                    let a=Float(i)*2*Float.pi/Float(sides)
                    let b=Float(i+1)*2*Float.pi/Float(sides)
                    let c=Float(j)*2*Float.pi/10
                    let d=Float(j+1)*2*Float.pi/10
                    quad(torus(x,y,z,radius,tube,a,c),
                         torus(x,y,z,radius,tube,b,c),
                         torus(x,y,z,radius,tube,b,d),
                         torus(x,y,z,radius,tube,a,d),color)
                }
            }
        }
        mutating func plate(_ outline:[Float],_ low:Float,_ high:Float,
                            _ color:Tint) {
            let n=outline.count/2
            var cx:Float=0,cy:Float=0
            for i in 0..<n {
                cx+=outline[2*i]/Float(n)
                cy+=outline[2*i+1]/Float(n)
            }
            let center=Point(cx,cy,high)
            for i in 0..<n {
                let j=(i+1)%n
                let a=Point(outline[i*2],outline[i*2+1],low)
                let b=Point(outline[j*2],outline[j*2+1],low)
                let p=Point(cx+(a.x-cx)*0.84,cy+(a.y-cy)*0.84,high)
                let q=Point(cx+(b.x-cx)*0.84,cy+(b.y-cy)*0.84,high)
                quad(a,b,q,p,color.shade(0.70))
                tri(center,p,q,color)
                tri(Point(cx,cy,low-0.12),b,a,color.shade(0.55))
            }
        }
        mutating func armor(_ x:Float,_ y:Float,_ w:Float,
                            _ h:Float,_ z:Float,_ color:Tint) {
            plate([x-w*0.72,y-h,x+w*0.72,y-h,x+w,y-h*0.6,
                   x+w,y+h*0.58,x+w*0.56,y+h,x-w*0.56,y+h,
                   x-w,y+h*0.58,x-w,y-h*0.6],z,z+0.14,color)
            for sign:Float in [-1,1] {
                for i in 0..<3 {
                    shell(x+sign*w*0.72,y+Float(i-1)*h*0.53,
                          z+0.15,0.025,0.025,0.020,
                          SourceRobotMesh70.steel,4,12)
                }
            }
        }
        mutating func face(_ x:Float,_ y:Float,_ z:Float,
                           _ w:Float,_ color:Tint,_ eyes:Tint) {
            shell(x,y,z,w,0.30,0.23,color)
            armor(x,y-0.1,w*0.86,0.18,z+0.14,color)
            for sign:Float in [-1,1] {
                shell(x+sign*w*0.47,y+0.08,z+0.21,
                      w*0.24,0.09,0.06,SourceRobotMesh70.dark,8,20)
                plate([x+sign*w*0.70,y+0.028,
                       x+sign*w*0.19,y+0.11,
                       x+sign*w*0.23,y+0.18,
                       x+sign*w*0.66,y+0.14],
                      z+0.245,z+0.270,eyes)
                tube(Point(x+sign*w*0.78,y-0.08,z),
                     Point(x+sign*w*1.14,y-0.48,z+0.22),
                     0.09,0,SourceRobotMesh70.steel)
                tube(Point(x+sign*w*0.78,y+0.12,z),
                     Point(x+sign*w*0.95,y+0.58,z+0.16),
                     0.075,0,SourceRobotMesh70.bone)
            }
            armor(x,y+0.28,w*0.7,0.16,z+0.03,SourceRobotMesh70.dark)
            for i in 0..<7 {
                let q=x+Float(i-3)*w*0.17
                tube(Point(q,y+0.17,z+0.16),Point(q,y+0.39,z+0.19),
                     0.04,0,SourceRobotMesh70.bone,12)
            }
        }
        mutating func core(_ x:Float,_ y:Float,_ z:Float,_ radius:Float) {
            ring(x,y,z,radius+0.07,0.055,SourceRobotMesh70.steel)
            shell(x,y,z+0.025,radius,radius,0.14,SourceRobotMesh70.red,12,40)
            ring(x,y,z+0.16,radius*0.62,0.019,
                 SourceRobotMesh70.red.shade(1.5))
            shell(x,y,z+0.18,radius*0.22,radius*0.22,0.04,
                  SourceRobotMesh70.bone,6,20)
        }
        mutating func head() {
            part { b in
                b.shell(0,0.05,0,0.92,1.02,0.58,SourceRobotMesh70.dark,12,32)
                b.armor(0,-0.30,0.91,0.50,0.29,SourceRobotMesh70.steel)
                b.armor(0,-0.83,0.60,0.17,0.15,SourceRobotMesh70.dark)
                b.face(0,0.48,0.24,0.67,
                       SourceRobotMesh70.steel,SourceRobotMesh70.red)
                for sign:Float in [-1,1] {
                    b.tube(Point(sign*0.66,0.14,0.22),
                           Point(sign*1.08,0.85,0.25),
                           0.11,0.035,SourceRobotMesh70.steel,20)
                    b.tube(Point(sign*1.08,0.85,0.25),
                           Point(sign*0.55,1.32,0.27),
                           0.035,0,SourceRobotMesh70.steel,16)
                    for i in 0..<4 {
                        b.armor(sign*0.72,-0.60+Float(i)*0.20,
                                0.13,0.07,0.38,Tint(105,125,144))
                    }
                }
                for i in 0..<5 {
                    let x=Float(i-2)*0.18
                    b.tube(Point(x,-0.64,0.55),Point(x,-0.12,0.59),
                           0.025,0.025,Tint(234,137,50),12)
                }
            }
            part(0,0.59,0.51) { b in
                for sign:Float in [-1,1] {
                    b.shell(sign*0.31,0.05,0,0.13,0.057,0.048,
                            SourceRobotMesh70.red,6,20)
                }
            }
            part(0,-0.35,0.59) { b in b.core(0,0,0,0.20) }
        }
        mutating func segment() {
            part { b in
                b.shell(0,0,0,0.89,0.55,0.64,SourceRobotMesh70.dark,8,28)
                b.armor(0,0,0.78,0.43,0.36,Tint(135,156,171))
                for sign:Float in [-1,1] {
                    b.armor(sign*0.75,0,0.16,0.33,0.19,
                            SourceRobotMesh70.steel)
                    b.tube(Point(sign*0.64,-0.2,0.32),
                           Point(sign*1.05,-0.3,0.75),
                           0.10,0,SourceRobotMesh70.steel,16)
                }
                for i in 0..<4 {
                    b.armor(Float(i)*0.30-0.45,0,0.09,0.30,0.54,
                            Tint(75,97,113))
                }
            }
            for sign:Float in [-1,1] {
                part(0,sign*0.39,0,rotateX90:true) { b in
                    b.ring(0,0,0,0.73,0.13,SourceRobotMesh70.steel,32)
                    b.ring(0,0,0.02,0.64,0.025,Tint(199,133,56),24)
                }
            }
            part(0,0,0.66) { b in
                b.shell(0,0,0,0.23,0.17,0.055,
                        SourceRobotMesh70.amber,8,24)
                b.ring(0,0,0.045,0.19,0.025,SourceRobotMesh70.dark,24)
            }
        }
        mutating func connector() {
            part { b in
                b.tube(Point(0,-1,0),Point(0,1,0),
                       1,1,SourceRobotMesh70.dark,16)
            }
        }
    }

    /// 0=head, 1=segment, 2=source connector; no geometry duplication
    /// per ring. One GPU buffer per model, shared by all actors.
    static func vertices(kind:Int)->[Float] {
        guard (0...2).contains(kind) else{return []}
        var b=Builder()
        switch kind {
        case 0:b.head()
        case 1:b.segment()
        default:b.connector()
        }
        return b.floats
    }
}
