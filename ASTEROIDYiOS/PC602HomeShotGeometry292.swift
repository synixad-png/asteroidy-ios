import Foundation

/// Original PC v602 Combat69.DrawShipShots69 + ShotRibbon69 in the source
/// HomeShotPass292. This builder does not simulate new physics. It
/// projects bullets already advanced by PC602HomeWeaponTest292 and
/// creates the source's THREE screen-width geodesic ribbon layers:
/// 27-alpha halo, 165-alpha weapon tint, 240-alpha white core.
/// Each layer has 6 steps × 2 triangles × 3 vertices, no line-width
/// driver assumption. Color per vertex is RGBA; Metal blend SRC_ALPHA/ONE.
enum PC602HomeShotGeometry292 {
    static let floatsPerVertex=7
    static let ribbonSegments=6
    static let ribbonLayers=3
    static let ribbonVerticesPerShot=ribbonSegments*6*ribbonLayers
    static let orbVerticesPerShot=(32+28+24)*6
    static let verticesPerShot=ribbonVerticesPerShot+orbVerticesPerShot

    private static func vector(_ p:SphereVector3)->SIMD3<Float> {
        SIMD3(p.x,p.y,p.z)
    }
    private static func fromVector(_ p:SIMD3<Float>)->SphereVector3 {
        SphereVector3(x:p.x,y:p.y,z:p.z)
    }
    private static func cross(_ a:SIMD3<Float>,
                              _ b:SIMD3<Float>)->SIMD3<Float> {
        SIMD3(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x)
    }
    private static func length(_ p:SIMD3<Float>)->Float {
        sqrt(p.x*p.x+p.y*p.y+p.z*p.z)
    }
    private static func dot(_ a:SIMD3<Float>,_ b:SIMD3<Float>)->Float {
        a.x*b.x+a.y*b.y+a.z*b.z
    }
    private static func tint(_ kind:PC602HomeWeaponTest292.Weapon)
        ->SIMD3<Float> {
        switch kind {
        case .twin:return SIMD3<Float>(255,197,62)/255
        case .scatter:return SIMD3<Float>(255,92,190)/255
        case .rail:return SIMD3<Float>(181,123,255)/255
        case .swarm:return SIMD3<Float>(88,255,143)/255
        case .pulse:return SIMD3<Float>(55,215,255)/255
        }
    }

    /// Source ShotPosition292(point,3.3) uses original H290 relief
    /// +13 m H290 shot lift and +3.3 m ribbon lift. Not C279 shell.
    private static func shotPosition(_ point:Vec2,home:PC602NewHome290)
        ->SIMD3<Float>? {
        let n=vector(Sphere67.normal(point))
        guard let h=home.surface(n) else{return nil}
        return n*(h+13+3.3)
    }
    private static func append(_ p:SIMD3<Float>,_ color:SIMD4<Float>,
                               to data:inout [Float]) {
        data.append(contentsOf:[
            p.x,p.y,p.z,color.x,color.y,color.z,color.w])
    }

    private static func unit(_ v:SIMD3<Float>)->SIMD3<Float> {
        let d=length(v)
        return d>1e-6 ? v/d : SIMD3<Float>(1,0,0)
    }

    /// Source Combat69.OrbDisc150 from three source DrawShipShots69 calls,
    /// actual billboard normal and source pixels-per-unit from the shared
    /// IntroProjection (720px vertical focal length). No textured impostor.
    /// Source calls GL_TRIANGLE_STRIP, converted to exact two triangles per
    /// angular segment with original premultiplied colors for GL_ONE/GL_ONE.
    private static func disc(_ center:SIMD3<Float>,
                             _ right:SIMD3<Float>,
                             _ up:SIMD3<Float>,
                             inner:Float,outer:Float,
                             innerRGB:SIMD3<Float>,innerAlpha:Float,
                             outerRGB:SIMD3<Float>,outerAlpha:Float,
                             segments:Int,into out:inout [Float]) {
        let inTint=SIMD4<Float>(
            innerRGB.x*innerAlpha,innerRGB.y*innerAlpha,
            innerRGB.z*innerAlpha,innerAlpha)
        let outTint=SIMD4<Float>(
            outerRGB.x*outerAlpha,outerRGB.y*outerAlpha,
            outerRGB.z*outerAlpha,outerAlpha)
        for j in 0..<segments {
            let a=Float(j)*2*Float.pi/Float(segments)
            let b=Float(j+1)*2*Float.pi/Float(segments)
            let v0=right*cos(a)+up*sin(a)
            let v1=right*cos(b)+up*sin(b)
            let o0=center+v0*outer,i0=center+v0*inner
            let o1=center+v1*outer,i1=center+v1*inner
            append(o0,outTint,to:&out)
            append(i0,inTint,to:&out)
            append(o1,outTint,to:&out)
            append(o1,outTint,to:&out)
            append(i0,inTint,to:&out)
            append(i1,inTint,to:&out)
        }
    }

    /// Reuses caller-owned capacity. The Metal renderer allocates fixed
    /// triple GPU buffers at initialization, never during the draw loop.
    static func build(home:PC602NewHome290,
                      bullets:[PC602HomeWeaponTest292.Bullet],
                      camera:SIMD3<Float>,
                      view:[Float],into result:inout [Float])->Int {
        result.removeAll(keepingCapacity:true)
        guard view.count==16 && view.allSatisfy({$0.isFinite}),
              camera.x.isFinite && camera.y.isFinite && camera.z.isFinite
        else{return 0}
        result.reserveCapacity(max(result.capacity,
            bullets.count*verticesPerShot*floatsPerVertex))
        for bullet in bullets {
            let tail=Sphere67.offset(bullet.position,
                by:bullet.velocity * -0.024)
            let travel=Sphere67.delta(target:bullet.position,origin:tail)
            let baseWidth:Float=bullet.kind == .rail ? 3.6:3.1
            let hue=tint(bullet.kind)
            for layer in 0..<ribbonLayers {
                let width:Float
                let color:SIMD4<Float>
                switch layer {
                case 0:
                    width=baseWidth*2.5
                    color=SIMD4(hue.x,hue.y,hue.z,27/255)
                case 1:
                    width=baseWidth*1.4
                    color=SIMD4(hue.x,hue.y,hue.z,165/255)
                default:
                    width=baseWidth*0.70
                    color=SIMD4(242/255,251/255,255/255,240/255)
                }
                for i in 0..<ribbonSegments {
                    let u0=Float(i)/Float(ribbonSegments)
                    let u1=Float(i+1)/Float(ribbonSegments)
                    let pa=Sphere67.offset(tail,by:travel*u0)
                    let pb=Sphere67.offset(tail,by:travel*u1)
                    guard let a=shotPosition(pa,home:home),
                          let b=shotPosition(pb,home:home)
                    else {continue}
                    let middle=(a+b)*0.5
                    let sideRaw=cross(b-a,camera-middle)
                    let sideLength=length(sideRaw)
                    guard sideLength>1e-6 else {continue}
                    let side=sideRaw/sideLength
                    // Original IntroProject: -eye Z = front-facing depth.
                    let eyeZ = view[2]*middle.x+view[6]*middle.y+view[10]*middle.z+view[14]
                    let depth=max(1,-eyeZ)
                    let half=width*depth/1440
                    let q0=half*(0.90+0.10*u0)
                    let q1=half*(0.90+0.10*u1)
                    let aa=a+side*q0,ab=a-side*q0
                    let ba=b+side*q1,bb=b-side*q1
                    // Six exact source ShotRibbon69 GL_TRIANGLES vertices.
                    append(aa,color,to:&result)
                    append(ab,color,to:&result)
                    append(ba,color,to:&result)
                    append(ba,color,to:&result)
                    append(ab,color,to:&result)
                    append(bb,color,to:&result)
                }
            }
        }
        // Source DrawShipShots69 renders ALL ribbon calls first, flushes,
        // then renders the three separate OrbDisc150 concentric source discs.
        let ribbonCount=result.count/floatsPerVertex
        for bullet in bullets {
            let n=vector(Sphere67.normal(bullet.position))
            guard let h=home.surface(n) else {continue}
            let center=n*(h+13+3.8) // ShotPosition292(p,.8 + 3)
            let eye=camera-center
            var right=cross(eye,SIMD3<Float>(0,1,0))
            if length(right)<0.01 {right=SIMD3<Float>(1,0,0)}
            right=unit(right)
            let up=unit(cross(right,eye))
            let eyeZ = view[2]*center.x+view[6]*center.y+view[10]*center.z+view[14]
            let depth=max(1,-eyeZ)
            let corePixels:Float=bullet.kind == .rail ? 4.2:3.6
            let pixelsPerUnit=max(0.01,720/depth)
            let radius = (corePixels/pixelsPerUnit) * PC602HomeShipPose291.originalWorldScale
            let hue=tint(bullet.kind)
            let opaqueWhite=SIMD3<Float>(249,253,255)/255
            let paleEdge=SIMD3<Float>(230,246,255)/255
            // Three original rounds, in source order: halo 32 segments,
            // weapon tinted shell 28, intense white-blue core 24.
            disc(center,right,up,inner:radius*0.67,
                 outer:radius*2.3,
                 innerRGB:hue,innerAlpha:48/255,
                 outerRGB:hue,outerAlpha:0,segments:32,into:&result)
            disc(center,right,up,inner:radius*0.30,
                 outer:radius,
                 innerRGB:hue,innerAlpha:178/255,
                 outerRGB:hue,outerAlpha:0,segments:28,into:&result)
            disc(center,right,up,inner:0,
                 outer:radius*0.48,
                 innerRGB:opaqueWhite,innerAlpha:250/255,
                 outerRGB:paleEdge,outerAlpha:66/255,
                 segments:24,into:&result)
        }
        return ribbonCount
    }
}
