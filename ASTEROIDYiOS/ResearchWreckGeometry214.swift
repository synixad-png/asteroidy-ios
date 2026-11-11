import Foundation

/// Direct transcription of Windows v568 GpuIntro41.cs: WreckBox209,
/// WreckSketchBox215, WreckPanelGrid213 and DrawDetailedResearchWreck211.
/// Opaque source geometry is built once, not recomputed per Metal frame.
/// Per-vertex 11th float is ONLY a runtime lamp phase; the ten source
/// coordinates/normal/colour components are kept in their original order.
enum ResearchWreckGeometry214 {
    struct Mesh {
        var triangles:[Float] = []
        var lines:[Float] = []
        var triangleCount:Int { triangles.count/11 }
        var lineCount:Int { lines.count/7 }
    }
    private final class Builder {
        var mesh=Mesh()
        private var strutOrigin=SIMD3<Float>(0,0,0)
        private var strutAngle:Float=0
        private var lampPhase:Float = -100
        private func converted(_ x:Float,_ y:Float,_ z:Float)
            -> SIMD3<Float> {
            if strutAngle == 0 {
                return SIMD3(x,y,z)+strutOrigin
            }
            let ca=cos(strutAngle),sa=sin(strutAngle)
            return SIMD3(x*ca-y*sa,x*sa+y*ca,z)+strutOrigin
        }
        private func convertedNormal(_ x:Float,_ y:Float,_ z:Float)
            -> SIMD3<Float> {
            if strutAngle == 0 { return SIMD3(x,y,z) }
            let ca=cos(strutAngle),sa=sin(strutAngle)
            return SIMD3(x*ca-y*sa,x*sa+y*ca,z)
        }
        private func triangleVertex(_ x:Float,_ y:Float,_ z:Float,
                    _ nx:Float,_ ny:Float,_ nz:Float,
                    _ r:Float,_ g:Float,_ b:Float,_ a:Float=1) {
            let p=converted(x,y,z),n=convertedNormal(nx,ny,nz)
            mesh.triangles += [p.x,p.y,p.z,n.x,n.y,n.z,
                               r,g,b,a,lampPhase]
        }
        private func tri(_ a:SIMD3<Float>,_ b:SIMD3<Float>,
                         _ c:SIMD3<Float>,n:SIMD3<Float>,
                         colour:SIMD4<Float>) {
            for p in [a,b,c] {
                triangleVertex(p.x,p.y,p.z,n.x,n.y,n.z,
                    colour.x,colour.y,colour.z,colour.w)
            }
        }
        private func quad(_ a:SIMD3<Float>,_ b:SIMD3<Float>,
                          _ c:SIMD3<Float>,_ d:SIMD3<Float>,
                          n:SIMD3<Float>,colour:SIMD4<Float>) {
            tri(a,b,c,n:n,colour:colour)
            tri(a,c,d,n:n,colour:colour)
        }
        private func scratch(_ a:SIMD3<Float>,_ b:SIMD3<Float>,
                             gray:Float) {
            let p=converted(a.x,a.y,a.z),q=converted(b.x,b.y,b.z)
            mesh.lines += [p.x,p.y,p.z,gray,gray,gray,1,
                           q.x,q.y,q.z,gray,gray,gray,1]
        }
        private static func hash217(_ a:Float,_ b:Float,_ c:Float)->Float {
            let v=sin(Double(a)*12.9898 + Double(b)*78.233 +
                      Double(c)*37.719)*43758.5453
            return Float(v-floor(v))
        }
        private static func clamp217(_ v:Float)->Float {
            max(0,min(1,v))
        }
        // Literal WreckSketchBox215: grime, soot, exposed metal, paint
        // chips, scratches and drips. Every offset comes from v568.
        private func sketchBox(_ x:Float,_ y:Float,_ z:Float,
                   _ sx:Float,_ sy:Float,_ sz:Float,
                   _ r:Float,_ g:Float,_ b:Float) {
            let xa=x-sx*0.5,ya=y-sy*0.5,yb=y+sy*0.5
            let za=z-sz*0.5,zb=z+sz*0.5
            let dirt=Self.hash217(x,y,z)
            let dirt2=Self.hash217(x+3.1,y-1.7,z+2.4)
            let dirt3=Self.hash217(x-2.2,y+4.3,z-1.1)
            let dirt4=Self.hash217(x+7,y+1.4,z-3)
            func front(_ x0:Float,_ x1:Float,_ y0:Float,_ y1:Float,
                       _ z:Float,_ cr:Float,_ cg:Float,_ cb:Float,
                       _ alpha:Float) {
                quad(SIMD3(x0,y0,z),SIMD3(x1,y0,z),
                     SIMD3(x1,y1,z),SIMD3(x0,y1,z),
                     n:SIMD3(0,0,1),colour:SIMD4(cr,cg,cb,alpha))
            }
            var gx0=xa+sx*(0.06+0.10*dirt)
            var gx1=xa+sx*(0.68+0.12*dirt2)
            var gy0=ya+sy*(0.66+0.05*dirt2)
            var gy1=ya+sy*(0.92+0.03*dirt2)
            front(gx0,gx1,gy0,gy1,zb+0.012,r*0.28,g*0.29,b*0.26,0.96)
            gx0=xa+sx*(0.40+0.06*dirt2)
            gx1=xa+sx*(0.92+0.02*dirt2)
            gy0=ya+sy*(0.06+0.04*dirt3)
            gy1=ya+sy*(0.34+0.04*dirt3)
            front(gx0,gx1,gy0,gy1,zb+0.013,r*0.16,g*0.15,b*0.14,0.94)
            gx0=xa+sx*(0.12+0.08*dirt3)
            gx1=gx0+sx*(0.36+0.04*dirt2)
            gy0=yb-sy*0.10;gy1=yb-sy*0.025
            front(gx0,gx1,gy0,gy1,zb+0.014,
                  Self.clamp217(r*1.28+0.10),
                  Self.clamp217(g*1.24+0.10),
                  Self.clamp217(b*1.22+0.10),0.99)
            gx0=xa+sx*(0.63+0.04*dirt)
            gx1=gx0+sx*0.18
            gy0=ya+sy*(0.50+0.03*dirt2)
            gy1=gy0+sy*0.22
            front(gx0,gx1,gy0,gy1,zb+0.014,0.62,0.66,0.72,0.98)
            gx0=xa+sx*(0.18+0.05*dirt4)
            gx1=gx0+sx*0.10
            gy0=ya+sy*(0.36+0.04*dirt3)
            gy1=gy0+sy*0.14
            front(gx0,gx1,gy0,gy1,zb+0.014,
                  0.62*0.95,0.66*0.95,0.72*0.98,0.97)
            if sx*sy>10 {
                let tz0=za+sz*(0.16+0.14*dirt2)
                let tz1=tz0+sz*(0.34+0.08*dirt3)
                let tx0=xa+sx*(0.18+0.08*dirt)
                let tx1=tx0+sx*(0.42+0.04*dirt2)
                quad(SIMD3(tx0,yb+0.012,tz0),
                     SIMD3(tx1,yb+0.012,tz0),
                     SIMD3(tx1,yb+0.012,tz1),
                     SIMD3(tx0,yb+0.012,tz1),
                     n:SIMD3(0,1,0),
                     colour:SIMD4(r*0.28,g*0.29,b*0.26,0.90))
            }
            let tone=max(0.12,min(0.36,0.30-0.08*(r+g+b)/3))
            var sx0=xa+sx*(0.18+0.12*dirt)
            var sy0=ya+sy*(0.22+0.18*dirt2)
            scratch(SIMD3(sx0,sy0,zb+0.016),
                    SIMD3(sx0+sx*0.19,sy0+sy*0.09,zb+0.016),gray:tone)
            sx0=xa+sx*(0.52+0.10*dirt2)
            sy0=ya+sy*(0.60+0.08*dirt3)
            scratch(SIMD3(sx0,sy0,zb+0.016),
                    SIMD3(sx0+sx*0.15,sy0-sy*0.08,zb+0.016),gray:tone+0.04)
            sx0=xa+sx*(0.34+0.08*dirt3)
            sy0=ya+sy*(0.78+0.03*dirt)
            scratch(SIMD3(sx0,sy0,zb+0.016),
                    SIMD3(sx0+sx*0.11,sy0-sy*0.05,zb+0.016),gray:tone+0.06)
            scratch(SIMD3(xa+sx*0.04,ya+sy*0.94,zb+0.015),
                    SIMD3(xa+sx*0.31,ya+sy*0.94,zb+0.015),gray:tone+0.10)
            scratch(SIMD3(xa+sx*0.66,ya+sy*0.07,zb+0.015),
                    SIMD3(xa+sx*0.95,ya+sy*0.07,zb+0.015),gray:tone+0.10)
            scratch(SIMD3(xa+sx*0.05,ya+sy*0.16,zb+0.015),
                    SIMD3(xa+sx*0.05,ya+sy*0.48,zb+0.015),gray:tone+0.07)
            if sx*sy>12 {
                for i in 0..<3 {
                    let fraction:Float=i==0 ? 0.18+0.18*dirt :
                        i==1 ? 0.46+0.14*dirt2 : 0.74+0.08*dirt3
                    let px=xa+sx*fraction
                    let py=yb-sy*(0.05+0.02*Float(i))
                    scratch(SIMD3(px,py,zb+0.016),
                            SIMD3(px-sx*0.018,
                                  py-sy*(0.18+0.04*Float(i)),zb+0.016),
                            gray:tone+0.02)
                }
            }
        }
        // Literal v568 WreckBox209: all six faces and source shading.
        func box(_ x:Float,_ y:Float,_ z:Float,
                 _ sx:Float,_ sy:Float,_ sz:Float,
                 _ r:Float,_ g:Float,_ b:Float) {
            let xa=x-sx*0.5,xb=x+sx*0.5
            let ya=y-sy*0.5,yb=y+sy*0.5
            let za=z-sz*0.5,zb=z+sz*0.5
            func face(_ p0:SIMD3<Float>,_ p1:SIMD3<Float>,
                      _ p2:SIMD3<Float>,_ p3:SIMD3<Float>,
                      _ n:SIMD3<Float>,_ cr:Float,_ cg:Float,_ cb:Float) {
                quad(p0,p1,p2,p3,n:n,colour:SIMD4(cr,cg,cb,1))
            }
            face(SIMD3(xa,ya,zb),SIMD3(xb,ya,zb),
                 SIMD3(xb,yb,zb),SIMD3(xa,yb,zb),
                 SIMD3(0,0,1),r,g,b)
            // reverse winding of the rear panel from GpuIntro41.
            tri(SIMD3(xa,ya,za),SIMD3(xb,yb,za),
                SIMD3(xb,ya,za),n:SIMD3(0,0,-1),
                colour:SIMD4(r*0.86,g*0.86,b*0.88,1))
            tri(SIMD3(xa,ya,za),SIMD3(xa,yb,za),
                SIMD3(xb,yb,za),n:SIMD3(0,0,-1),
                colour:SIMD4(r*0.86,g*0.86,b*0.88,1))
            face(SIMD3(xa,ya,za),SIMD3(xb,ya,za),
                 SIMD3(xb,ya,zb),SIMD3(xa,ya,zb),
                 SIMD3(0,-1,0),r*0.92,g*0.94,b*0.97)
            tri(SIMD3(xa,yb,za),SIMD3(xb,yb,zb),
                SIMD3(xb,yb,za),n:SIMD3(0,1,0),
                colour:SIMD4(r*0.93,g*0.94,b*0.96,1))
            tri(SIMD3(xa,yb,za),SIMD3(xa,yb,zb),
                SIMD3(xb,yb,zb),n:SIMD3(0,1,0),
                colour:SIMD4(r*0.93,g*0.94,b*0.96,1))
            face(SIMD3(xa,ya,za),SIMD3(xa,ya,zb),
                 SIMD3(xa,yb,zb),SIMD3(xa,yb,za),
                 SIMD3(-1,0,0),r*0.87,g*0.89,b*0.93)
            tri(SIMD3(xb,ya,za),SIMD3(xb,yb,zb),
                SIMD3(xb,ya,zb),n:SIMD3(1,0,0),
                colour:SIMD4(r*0.94,g*0.95,b*0.98,1))
            tri(SIMD3(xb,ya,za),SIMD3(xb,yb,za),
                SIMD3(xb,yb,zb),n:SIMD3(1,0,0),
                colour:SIMD4(r*0.94,g*0.95,b*0.98,1))
            sketchBox(x,y,z,sx,sy,sz,r,g,b)
        }
        func metalPanel(_ x:Float,_ y:Float,_ z:Float,
                        _ sx:Float,_ sy:Float,_ sz:Float,
                        _ r:Float,_ g:Float,_ b:Float) {
            box(x,y,z,sx,sy,sz,r,g,b)
            let px=sx*0.78,py=sy*0.16,pz=sz*0.12
            box(x,y+sy*0.36,z,px,max(0.22,py),max(0.18,pz),
                r*0.92+0.04,g*0.94+0.04,b*0.98+0.04)
            box(x,y-sy*0.36,z,px,max(0.22,py),max(0.18,pz),
                r*0.52,g*0.56,b*0.63)
            box(x-sx*0.28,y,z+sz*0.43,
                max(0.22,sx*0.12),max(0.22,sy*0.72),max(0.18,sz*0.10),
                r*0.80,g*0.84,b*0.88)
            box(x+sx*0.18,y,z+sz*0.43,
                max(0.22,sx*0.16),max(0.22,sy*0.66),max(0.18,sz*0.10),
                r*0.66,g*0.70,b*0.76)
        }
        func windowRow(_ x:Float,_ y:Float,_ z:Float,_ count:Int,
                       _ spacing:Float,_ w:Float,_ h:Float,_ d:Float) {
            for i in 0..<count {
                let ox=(Float(i)-Float(count-1)*0.5)*spacing
                box(x+ox,y,z,w,h,d,0.22,0.36,0.48)
                box(x+ox,y,z+d*0.30,w*0.68,h*0.68,max(0.12,d*0.42),
                    0.42,0.76,0.95)
            }
        }
        func airlock(_ x:Float,_ y:Float,_ z:Float,
                     _ sx:Float,_ sy:Float,_ sz:Float) {
            box(x,y,z,sx,sy,sz,0.19,0.25,0.31)
            box(x,y,z+sz*0.42,sx*0.86,sy*0.86,sz*0.20,0.58,0.63,0.69)
            box(x,y,z+sz*0.56,sx*0.56,sy*0.56,sz*0.22,0.14,0.18,0.24)
            box(x,y,z+sz*0.66,sx*0.32,sy*0.32,sz*0.16,0.35,0.72,0.92)
            box(x-sx*0.62,y,z,sx*0.16,sy*0.58,sz*0.36,0.38,0.46,0.55)
            box(x+sx*0.62,y,z,sx*0.16,sy*0.58,sz*0.36,0.38,0.46,0.55)
        }
        func antenna(_ x:Float,_ y:Float,_ z:Float,_ h:Float) {
            box(x,y+h*0.45,z,0.28,h,0.28,0.56,0.62,0.70)
            box(x,y+h*0.98,z,0.75,0.22,0.75,0.72,0.79,0.86)
            box(x,y+h*1.12,z,0.24,0.55,0.24,0.72,0.21,0.18)
            box(x-0.95,y+h*0.76,z,0.18,0.18,2.4,0.44,0.50,0.57)
            box(x+0.95,y+h*0.76,z,0.18,0.18,2.4,0.44,0.50,0.57)
        }
        func strut(_ x:Float,_ y:Float,_ z:Float,
                   _ len:Float,_ thick:Float,_ angleZ:Float) {
            // Original WreckStrut211 pushes a local transform and
            // flushes the legacy batch before changing GL matrices.
            strutOrigin=SIMD3(x,y,z)
            strutAngle=angleZ*Float.pi/180
            box(0,0,0,len,thick,thick,0.48,0.54,0.61)
            strutOrigin=SIMD3(0,0,0)
            strutAngle=0
        }
        func panelGrid(_ x:Float,_ y:Float,_ z:Float,
                       _ sx:Float,_ sy:Float,_ sz:Float,
                       _ cols:Int,_ rows:Int,_ r:Float,_ g:Float,_ b:Float) {
            metalPanel(x,y,z,sx,sy,sz,r,g,b)
            for c in 0..<cols {
                let tx=x-sx*0.38 +
                    (cols<=1 ? 0 : Float(c)*(sx*0.76/Float(cols-1)))
                box(tx,y,z+sz*0.52,
                    max(0.16,sx*0.04),max(0.18,sy*0.86),
                    max(0.14,sz*0.08),r*0.95+0.03,
                    g*0.97+0.03,b*1.02+0.02)
            }
            for row in 0..<rows {
                let ty=y-sy*0.34 +
                    (rows<=1 ? 0 : Float(row)*(sy*0.68/Float(rows-1)))
                box(x,ty,z+sz*0.49,
                    max(0.20,sx*0.84),max(0.14,sy*0.06),
                    max(0.14,sz*0.08),r*0.60,g*0.67,b*0.74)
            }
        }
        func bridge(_ x:Float,_ y:Float,_ z:Float) {
            panelGrid(x,y,z,15.2,5.2,6.8,5,3,0.36,0.44,0.54)
            metalPanel(x-4,y+2.2,z,7.2,1.5,4.4,0.44,0.52,0.61)
            windowRow(x,y+0.7,z+3.9,6,2.1,1.35,0.86,0.50)
            windowRow(x-1.1,y-1.1,z+4.05,5,2,1,0.62,0.40)
            box(x,y+0.2,z+4.85,13.8,0.24,0.24,0.72,0.82,0.90)
            box(x-7.9,y+0.35,z,1.2,4.3,4.2,0.28,0.36,0.45)
            box(x+7.9,y+0.35,z,1.2,4.3,4.2,0.28,0.36,0.45)
        }
        func warningLamp(_ x:Float,_ y:Float,_ z:Float,
                         orange:Bool,phase:Float) {
            box(x,y,z,0.52,0.52,0.52,0.18,0.20,0.24)
            lampPhase=phase
            // C# WreckWarningLamp213: color multiplier is applied in
            // the Metal shader at g.Time*4.8, no CPU mesh rebuild.
            box(x,y,z+0.16,0.26,0.26,0.26,
                orange ? 0.95 : 0.92,orange ? 0.52 : 0.14,
                orange ? 0.16 : 0.12)
            lampPhase = -100
        }
        func marking(_ x:Float,_ y:Float,_ z:Float,
                     _ len:Float,_ thick:Float,orange:Bool) {
            let rr:Float=orange ? 0.86 : 0.74
            let gg:Float=orange ? 0.44 : 0.12
            let bb:Float=0.12
            box(x,y,z,len,thick,0.18,rr,gg,bb)
            box(x,y,z+0.10,len*0.82,thick*0.46,0.14,
                rr*0.9+0.06,gg*0.9+0.05,bb*0.9+0.05)
        }
        func accent(_ x:Float,_ y:Float,_ z:Float,
                    _ sx:Float,_ sy:Float,_ sz:Float) {
            box(x,y,z,sx,sy,sz,0.70,0.76,0.84)
            box(x,y,z+sz*0.25,sx*0.88,sy*0.44,max(0.12,sz*0.24),
                0.86,0.91,0.97)
        }
        private static func spaceHash207(_ value:UInt32)->UInt32 {
            var x=value
            x ^= x >> 16
            x = x &* 0x7feb352d
            x ^= x >> 15
            x = x &* 0x846ca68b
            x ^= x >> 16
            return x
        }
        private static func spaceRand207(_ a:Int,_ b:Int,_ c:Int)->Float {
            let input=UInt32(truncatingIfNeeded:a &* 73856093) ^
                UInt32(truncatingIfNeeded:b &* 19349663) ^
                UInt32(truncatingIfNeeded:c &* 83492791)
            return Float(spaceHash207(input) & 0x00ffffff)/16777215
        }
        func drawSourceWreck214(seed:Int,debris:Int=112,trail:Float=118) {
            // Entire authored part list below is transcribed from the
            // original DrawDetailedResearchWreck211(..., orbit:false).
            bridge(-12,1,0)
            panelGrid(-24,-0.3,0,19.5,8,9.4,5,3,0.31,0.39,0.48)
            panelGrid(3,0.2,0.2,14,6.6,7.6,4,3,0.33,0.42,0.52)
            panelGrid(-35.5,-0.3,0,11,9.2,8.4,3,4,0.25,0.33,0.43)
            panelGrid(-7.2,5.4,0,13.5,2.2,4.8,4,2,0.41,0.49,0.58)
            panelGrid(-9,-5.4,0,16.2,1.6,5.2,5,1,0.55,0.60,0.67)
            windowRow(-24,1.4,5.2,6,2.7,1.18,0.72,0.44)
            windowRow(3,1,4.45,4,2.15,1.02,0.66,0.40)
            windowRow(-15.8,0.5,12.3,4,1.8,0.84,0.50,0.32)
            windowRow(-9.8,0.3,-5.8,3,2,0.82,0.48,0.30)
            airlock(-35.5,-0.1,4.95,3.7,4,0.92)
            airlock(12.6,-0.2,0,2.2,3.4,3.4)
            airlock(-3.3,-0.1,-9.2,2.3,2.8,2.8)
            accent(-35.5,-0.1,6,4.3,4.4,0.20)
            panelGrid(-16,0,9.7,8.6,4.4,6.5,3,2,0.33,0.41,0.50)
            panelGrid(-10.7,0,-8.8,7,4,5.9,3,2,0.28,0.36,0.45)
            panelGrid(7,-4.8,8.3,6.2,2.3,4.4,3,2,0.29,0.38,0.47)
            panelGrid(8.5,3.9,-6.9,4.5,2,3.2,2,2,0.31,0.39,0.48)
            accent(-25.5,3.8,4.9,14.5,0.28,0.34)
            accent(-21,-3.8,5,10.8,0.26,0.32)
            accent(3,3,4.2,9.6,0.24,0.30)
            accent(-11.8,6.3,-3.1,9,0.22,0.24)
            accent(-11.8,6.3,3.1,9,0.22,0.24)
            accent(-15.5,6.8,0,0.7,1.2,7)
            for i in 0..<8 {
                let angle=Float(i)*0.7853982
                box(19.2,cos(angle)*3.9,sin(angle)*3.5,
                    10.6,0.46,0.52,0.68,0.42,0.36)
            }
            for i in 0..<6 {
                strut(-39,-6+Float(i)*2.5,-4.3,12.8,0.44,0)
            }
            strut(-34.5,6.2,5.3,8,0.36,35)
            strut(-33.5,-5.9,5.2,7.2,0.32,-32)
            panelGrid(-46,0,0,1.8,17.5,13,1,5,0.18,0.30,0.44)
            panelGrid(-53.2,0,-0.2,0.82,15.5,11.6,1,4,0.12,0.24,0.36)
            panelGrid(18.4,0,0,4.8,19,1.6,2,5,0.28,0.36,0.44)
            panelGrid(22.8,0,0,0.95,14,11,1,4,0.14,0.20,0.28)
            antenna(-6,5.9,-0.5,8)
            antenna(5.7,3.9,1.8,5.2)
            box(-12,6.4,-3.1,9,0.8,0.8,0.58,0.64,0.72)
            box(-12,6.4,3.1,9,0.8,0.8,0.58,0.64,0.72)
            box(-13.8,7.3,0,0.9,1.3,7.4,0.50,0.56,0.63)
            box(-3,7.1,0,8.8,0.65,0.65,0.62,0.68,0.76)
            for i in 0..<7 {
                let v=Float(i)/6
                box(4.2+v*8.9,2.3-v*3.4,2.4+v*1.7,
                    3.4,0.34,0.38,0.79,0.28,0.18)
            }
            marking(-23,-4.7,4.9,11.5,0.34,orange:true)
            marking(-18,4.7,5,8,0.28,orange:false)
            marking(3.2,-3.9,4.3,6.5,0.26,orange:true)
            marking(-16.2,2.4,12.8,4.2,0.22,orange:false)
            marking(8.7,-5.7,8.6,3.2,0.18,orange:true)
            warningLamp(-28.5,4.2,5,orange:false,phase:0)
            warningLamp(-18.5,4.5,5.1,orange:true,phase:1.1)
            warningLamp(-7,4.7,4.8,orange:false,phase:2.2)
            warningLamp(5.5,3.6,4.3,orange:true,phase:2.7)
            warningLamp(-16,2.1,12.7,orange:true,phase:3.1)
            warningLamp(-10.4,1.6,-5.6,orange:false,phase:4.2)
            warningLamp(9,-4.1,8.4,orange:true,phase:4.9)
            // PC602 orbit:true = 146 source debris; combat = original 112.
            for i in 0..<debris {
                let t=Float(i)/Float(debris-1)
                let jx=Self.spaceRand207(seed,i,8)-0.5
                let jy=Self.spaceRand207(seed,i,14)-0.5
                let jz=Self.spaceRand207(seed,i,29)-0.5
                let x=20+trail*t+jx*(7+41*t)
                let y=14*t+jy*(6+28*t)+5.2*sin(t*7.2+Float(seed)*0.01)
                let z=7+15*t+jz*(6+36*t)+2.6*cos(t*8)
                let r=(0.88+Self.spaceRand207(seed,i,55)*3.8) *
                    (1-0.62*t)
                let sy=r*(i%5==0 ? 1.12:0.72)
                let sz=r*(i%4==0 ? 1.28:0.88)
                let hot=i%11==0 || i%13==0
                let red=i%7==0
                let cr:Float=hot ? 0.78 :
                    (red ? 0.50 : (i%3==0 ? 0.38:0.30))
                let cg:Float=hot ? 0.42 :
                    (red ? 0.18 : (i%3==0 ? 0.40:0.36))
                let cb:Float=hot ? 0.14 :
                    (red ? 0.15 : (i%3==0 ? 0.47:0.43))
                box(x,y,z,r,sy,sz,cr,cg,cb)
                if i%10==0 {
                    box(x+r*0.9,y+r*0.2,z-r*0.4,
                        r*0.18,r*1.45,r*0.18,0.74,0.48,0.20)
                }
            }
        }
    }
    /// Original PC v602 GpuIntro41.DrawDetailedResearchWreck211(211,true).
    /// Identical 3D hull, weathering, scratch lines and 7 phased lamps.
    /// Only source differences from orbit:false are the 146 debris boxes,
    /// seed 211 and the extended 178 m debris trail; no duplicate builder.
    static func makeOrbitHome602()->Mesh {
        let builder=Builder()
        builder.drawSourceWreck214(seed:211,debris:146,trail:178)
        return builder.mesh
    }

    static func make(sector:Int)->Mesh {
        let builder=Builder()
        builder.drawSourceWreck214(seed:sector+214)
        return builder.mesh
    }
}
