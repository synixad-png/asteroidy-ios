import Foundation

/// The original first-sector bullets are not simple colored triangles:
/// Windows/src/Combat69.cs:44-102: DrawShipShots69 (three six-part
/// geodesic ribbons + three radial alpha rings), HostileBolt72,
/// HostileOrb149 and ShotAppearance151 source fixed pixel dimensions.
/// Windows/src/GpuSphere67.cs:288-303,337-358: four planet light
/// layers, identical eight colors and 0–400% independent brightness.
/// Visual only: this renderer never moves a shot or affects collision.
enum CarbonisProjectileFX69 {
    struct RGB {
        var r:Float
        var g:Float
        var b:Float
    }
    private static let outer=SphereCameraView556.originalPlanetOuterRadius
    private static let shell=SphereSurfaceStamp556.normalizedShellRadius

    /// Source Combat69 / GpuSphere67 uses exactly these ring counts.
    /// The same sin/cos values previously recomputed for EVERY active
    /// shot on EVERY frame now live in one immutable geometry table.
    /// This is geometry caching, not lower fidelity or fewer layers.
    private static let sourceCircles:[Int:[SIMD2<Float>]] = {
        var result:[Int:[SIMD2<Float>]]=[:]
        for slices in [12,18,22,24,28,32] {
            result[slices]=(0...slices).map { i in
                let a=Float(i)*2*Float.pi/Float(slices)
                return SIMD2<Float>(cos(a),sin(a))
            }
        }
        return result
    }()

    private static func unitCircle(_ slices:Int)->[SIMD2<Float>] {
        if let cached=sourceCircles[slices] {return cached}
        // Preserve the source formula even if a future original preset
        // introduces a different segmentation count.
        return (0...slices).map { i in
            let a=Float(i)*2*Float.pi/Float(slices)
            return SIMD2<Float>(cos(a),sin(a))
        }
    }

    private struct GroundFrame {
        let normal:SphereVector3
        let east:SphereVector3
        let south:SphereVector3
        let scale:Float
        init(_ point:Vec2) {
            normal=Sphere67.normal(point)
            let basis=Sphere67.basis(point)
            east=basis.east
            south=basis.south
            scale=(outer+15)/Sphere67.radius/outer
        }
    }

    private struct OrbFrame {
        let center:SphereVector3
        let right:SphereVector3
        let up:SphereVector3
        init(_ center:SphereVector3,camera:SphereCameraView556) {
            self.center=center
            let forward=(camera.eye-center).normalized
            var right=SphereVector3.cross(camera.up,forward).normalized
            if right.length<0.01 {right=camera.right}
            self.right=right
            up=SphereVector3.cross(forward,right).normalized
        }
    }

    static let presets:[RGB]=[
        RGB(r:1,g:1,b:1),
        RGB(r:92/255,g:190/255,b:1),
        RGB(r:1,g:205/255,b:102/255),
        RGB(r:112/255,g:242/255,b:132/255),
        RGB(r:196/255,g:118/255,b:1),
        RGB(r:1,g:96/255,b:118/255),
        RGB(r:172/255,g:242/255,b:1),
        RGB(r:1,g:178/255,b:72/255)]
    /// Combat69.ShotTint69
    static func playerTint(_ kind:Int)->RGB {
        switch kind {
        case 1:return RGB(r:1,g:197/255,b:62/255)
        case 2:return RGB(r:1,g:92/255,b:190/255)
        case 3:return RGB(r:181/255,g:123/255,b:1)
        case 4:return RGB(r:88/255,g:1,b:143/255)
        default:return RGB(r:55/255,g:215/255,b:1)
        }
    }
    /// Combat69.HostileBolt72 / GpuSphere67.HostileGroundTint170.
    static func hostileTint(_ kind:Int)->RGB {
        switch kind {
        case 2:return RGB(r:126/255,g:243/255,b:77/255)
        case 3:return RGB(r:200/255,g:112/255,b:254/255)
        default:return RGB(r:72/255,g:185/255,b:1)
        }
    }
    static func groundTint(_ base:RGB,
                           settings:CarbonisVisualSettings568)->RGB {
        let index=max(0,min(7,settings.projectileColor))
        if index==0 {return base}
        let chosen=presets[index]
        if !settings.projectileMixed {return chosen}
        let mix:Float=0.48
        return RGB(r:base.r*(1-mix)+chosen.r*mix,
                   g:base.g*(1-mix)+chosen.g*mix,
                   b:base.b*(1-mix)+chosen.b*mix)
    }
    private static func rgba(_ tint:RGB,_ a:Float)->[Float] {
        [tint.r,tint.g,tint.b,max(0,min(1,a))]
    }
    private static func vert(_ p:SphereVector3,_ color:[Float],
                             _ into:inout [Float]) {
        let n=p.normalized
        into.append(contentsOf:[
            p.x,p.y,p.z,n.x,n.y,n.z,
            color[0],color[1],color[2],color[3],0,0])
    }
    private static func tri(_ a:SphereVector3,_ b:SphereVector3,
                            _ c:SphereVector3,_ color:[Float],
                            _ into:inout [Float]) {
        vert(a,color,&into);vert(b,color,&into);vert(c,color,&into)
    }
    private static func line(_ a:SphereVector3,_ b:SphereVector3,
                             _ width:Float,_ color:[Float],
                             _ eye:SphereVector3,_ into:inout [Float]) {
        let travel=b-a
        if travel.length<0.000001{return}
        let center=(a+b)*0.5
        let side=SphereVector3.cross(travel,eye-center).normalized *
            max(0.000005,width*0.5)
        let p=a-side,q=b-side,r=b+side,t=a+side
        tri(p,q,r,color,&into);tri(p,r,t,color,&into)
    }
    private static func worldPoint(_ point:Vec2,_ height:Float)->SphereVector3 {
        Sphere67.normal(point)*(shell+height/outer)
    }
    private static func pxPerWorld(_ at:SphereVector3,
                                   camera:SphereCameraView556,
                                   height:Float)->Float {
        let depth=max(0.02,SphereVector3.dot(camera.eye-at,camera.back))
        return max(1,height*SphereProjection556.sourceVerticalFocal /
                   (2*depth))
    }
    /// Combat69.ShotRibbon69 six geodesic subdivisions, stable on-screen
    /// width and exact 27/165/240-alpha three-source-layer strip.
    private static func ribbon(_ shot:CarbonisCombat568.Projectile,
                               tint:RGB,width:Float,
                               camera:SphereCameraView556,
                               drawableHeight:Float,_ into:inout [Float]) {
        let trailing=shot.hostile ? Float(-0.025) : Float(-0.024)
        let tail=Sphere67.offset(shot.point,by:shot.velocity*trailing)
        let delta=Sphere67.delta(target:shot.point,origin:tail)
        let sourceWidth=shot.hostile ?
            (shot.kind==2 ? Float(3.3) : shot.kind==3 ? 3.5:3.1)
            : (shot.kind==3 ? Float(3.6):3.1)
        for step in 0..<6 {
            let a=worldPoint(Sphere67.offset(tail,
                by:delta*(Float(step)/6)),3.3)
            let b=worldPoint(Sphere67.offset(tail,
                by:delta*(Float(step+1)/6)),3.3)
            let px=pxPerWorld((a+b)*0.5,camera:camera,
                              height:drawableHeight)
            let perWorld=sourceWidth/px
            let outerWidth:Float=shot.hostile ? 2.45:2.50
            let middleWidth=shot.hostile ? Float(1.45):1.40
            let innerWidth=shot.hostile ? Float(0.67):0.70
            if width>0 {
                line(a,b,perWorld*outerWidth,
                     rgba(tint,27/255),camera.eye,&into)
            }
            line(a,b,perWorld*middleWidth,
                 rgba(tint,shot.hostile ? 160/255:165/255),
                 camera.eye,&into)
            line(a,b,perWorld*innerWidth,
                 rgba(RGB(r:242/255,g:251/255,b:1),
                      shot.hostile ? 235/255:240/255),
                 camera.eye,&into)
        }
    }
    private static func disc(_ p:SphereVector3,
                             inner:Float,outer:Float,
                             innerColor:[Float],outerColor:[Float],
                             slices:Int,
                             camera:SphereCameraView556,
                             _ into:inout [Float]) {
        let forward=(camera.eye-p).normalized
        var right=SphereVector3.cross(camera.up,forward).normalized
        if right.length<0.01 {right=camera.right}
        let up=SphereVector3.cross(forward,right).normalized
        func point(_ radius:Float,_ a:Float)->SphereVector3 {
            p+(right*cos(a)+up*sin(a))*radius
        }
        for i in 0..<slices {
            let a=Float(i)*2*Float.pi/Float(slices)
            let b=Float(i+1)*2*Float.pi/Float(slices)
            let outerA=point(outer,a),outerB=point(outer,b)
            let innerA=point(inner,a),innerB=point(inner,b)
            // Per-vertex radial alpha fading requires a shader capable
            // of smooth interpolation. Current original tracer vertex
            // path interpolates RGBA, including this alpha gradient.
            vert(outerA,outerColor,&into)
            vert(innerA,innerColor,&into)
            vert(innerB,innerColor,&into)
            vert(outerA,outerColor,&into)
            vert(innerB,innerColor,&into)
            vert(outerB,outerColor,&into)
        }
    }
    /// Source ShotOrb151 — player3.6px (heavy4.2), enemy3.3px,
    /// boss3.9px; source halo radius = core*2.3.
    private static func orb(_ shot:CarbonisCombat568.Projectile,
                            tint:RGB,glow:Bool,
                            camera:SphereCameraView556,
                            drawableHeight:Float,_ into:inout [Float]) {
        let p=worldPoint(shot.point,shot.hostile ? 2.8:3.0)
        let corePx:Float=shot.hostile ?
            (shot.kind==3 ? 3.9:3.3) :
            (shot.kind==3 ? 4.2:3.6)
        let core=corePx/pxPerWorld(p,camera:camera,
                                   height:drawableHeight)
        if glow {
            disc(p,inner:core*0.67,outer:core*2.3,
                 innerColor:rgba(tint,48/255),
                 outerColor:rgba(tint,0),
                 slices:32,camera:camera,&into)
        }
        disc(p,inner:core*0.30,outer:core,
             innerColor:rgba(tint,178/255),
             outerColor:rgba(tint,0),
             slices:28,camera:camera,&into)
        disc(p,inner:0,outer:core*0.48,
             innerColor:rgba(RGB(r:249/255,g:253/255,b:1),250/255),
             outerColor:rgba(RGB(r:230/255,g:246/255,b:1),66/255),
             slices:24,camera:camera,&into)
    }
    // Exact source rings with indexed, shared corners. No change to
    // source tessellation counts (32/28/24), radial alpha or world size.
    private static func indexedDisc(_ frame:OrbFrame,
                                    inner:Float,outer:Float,
                                    innerColor:[Float],outerColor:[Float],
                                    slices:Int,
                                    _ mesh:inout CarbonisIndexedFXMesh568) {
        let first=UInt32(mesh.vertexCount)
        for direction in unitCircle(slices) {
            let axis=frame.right*direction.x+frame.up*direction.y
            vert(frame.center+axis*outer,outerColor,&mesh.vertices)
            vert(frame.center+axis*inner,innerColor,&mesh.vertices)
        }
        for i in 0..<slices {
            let a=first+UInt32(i*2)
            let b=a+2
            mesh.indices.append(contentsOf:[a,a+1,b+1,a,b+1,b])
        }
    }

    private static func indexedOrb(_ shot:CarbonisCombat568.Projectile,
                                   tint:RGB,glow:Bool,
                                   camera:SphereCameraView556,
                                   drawableHeight:Float,
                                   _ mesh:inout CarbonisIndexedFXMesh568) {
        let p=worldPoint(shot.point,shot.hostile ? 2.8:3.0)
        let corePx:Float=shot.hostile ?
            (shot.kind==3 ? 3.9:3.3) :
            (shot.kind==3 ? 4.2:3.6)
        let core=corePx/pxPerWorld(p,camera:camera,height:drawableHeight)
        // The three original 32/28/24-radius fans share one camera
        // orientation; formerly this was recalculated three times.
        let frame=OrbFrame(p,camera:camera)
        if glow {
            indexedDisc(frame,inner:core*0.67,outer:core*2.3,
                innerColor:rgba(tint,48/255),outerColor:rgba(tint,0),
                slices:32,&mesh)
        }
        indexedDisc(frame,inner:core*0.30,outer:core,
            innerColor:rgba(tint,178/255),outerColor:rgba(tint,0),
            slices:28,&mesh)
        indexedDisc(frame,inner:0,outer:core*0.48,
            innerColor:rgba(RGB(r:249/255,g:253/255,b:1),250/255),
            outerColor:rgba(RGB(r:230/255,g:246/255,b:1),66/255),
            slices:24,&mesh)
    }

    /// Production Metal path. Same ordered triangle stream as vertices()
    /// but 2 indexed corners per ring step instead of 6 full GPU vertices.
    static func indexedVertices(_ shots:[CarbonisCombat568.Projectile],
                                camera:SphereCamera67,
                                drawableHeight:Float,glow:Bool=true)
        -> CarbonisIndexedFXMesh568 {
        var mesh=CarbonisIndexedFXMesh568()
        mesh.vertices.reserveCapacity(shots.count*3500)
        mesh.indices.reserveCapacity(shots.count*650)
        let view=SphereCameraView556(camera:camera)
        for shot in shots {
            let tint=shot.hostile ? hostileTint(shot.kind) :
                                      playerTint(shot.kind)
            // Ribbon strips remain untouched, including their six
            // geodesic subdivisions and three different alpha layers.
            let begin=mesh.vertexCount
            ribbon(shot,tint:tint,width:glow ? 1:0,camera:view,
                   drawableHeight:drawableHeight,&mesh.vertices)
            let end=mesh.vertexCount
            if end>begin {
                for v in begin..<end {mesh.indices.append(UInt32(v))}
            }
            indexedOrb(shot,tint:tint,glow:glow,camera:view,
                       drawableHeight:drawableHeight,&mesh)
        }
        return mesh
    }

    static func vertices(_ shots:[CarbonisCombat568.Projectile],
                         camera:SphereCamera67,
                         drawableHeight:Float,glow:Bool=true)->[Float] {
        var output:[Float]=[]
        output.reserveCapacity(shots.count*1800)
        let view=SphereCameraView556(camera:camera)
        for shot in shots {
            let tint=shot.hostile ? hostileTint(shot.kind) :
                                      playerTint(shot.kind)
            ribbon(shot,tint:tint,width:glow ? 1:0,
                   camera:view,drawableHeight:drawableHeight,&output)
            orb(shot,tint:tint,glow:glow,camera:view,
                drawableHeight:drawableHeight,&output)
        }
        return output
    }
    /// GpuSphere67.PlanetLightLayer170 — four source radial fans,
    /// zero alpha edge, rendered close to the real spherical surface.
    private static func groundDisc(_ point:Vec2,radius:Float,
                                   tint:RGB,alpha:Float,lift:Float,
                                   slices:Int,_ into:inout [Float]) {
        let center=worldPoint(point,0.4+lift*0.10)
        let normal=Sphere67.normal(point)
        let basis=Sphere67.basis(point)
        let scale=(outer+15)/Sphere67.radius/outer
        for i in 0..<slices {
            let a=2*Float.pi*Float(i)/Float(slices)
            let b=2*Float.pi*Float(i+1)/Float(slices)
            let offset1=(basis.east*cos(a)+basis.south*sin(a))*radius*scale
            let offset2=(basis.east*cos(b)+basis.south*sin(b))*radius*scale
            let v1=center+offset1
            let v2=center+offset2
            let c1=rgba(tint,alpha)
            let c0=rgba(tint,0)
            vert(center,c1,&into);vert(v1,c0,&into);vert(v2,c0,&into)
        }
    }
    static func groundLights(_ shots:[CarbonisCombat568.Projectile],
                             settings:CarbonisVisualSettings568)->[Float] {
        let brightness=settings.projectileBrightnessFactor
        if brightness<=0{return []}
        let radiusScale=0.85+brightness*0.55
        let powerScale=brightness*3.2
        var output:[Float]=[]
        output.reserveCapacity(shots.count*720)
        let widths:[Float]=[3.9,2.4,1.5,0.85]
        let weights:[Float]=[0.18,0.55,1.10,1.80]
        let lifts:[Float]=[3.0,1.35,0.55,0.10]
        let slices=[28,24,22,18]
        for shot in shots {
            let native=shot.hostile ? hostileTint(shot.kind) :
                                      playerTint(shot.kind)
            let tint=groundTint(native,settings:settings)
            let radius:Float=shot.hostile ?
                (shot.kind==2 ? 17.5 : shot.kind==3 ? 19:15.5) :
                (shot.kind==3 ? 20.5 :
                 shot.kind==4 ? 17.5 :
                 shot.kind==2 ? 16:14.5)
            let strength:Float=shot.hostile ?
                (shot.kind==2 ? 0.30:shot.kind==3 ? 0.34:0.26) :
                (shot.kind==3 ? 0.42 :
                 shot.kind==4 ? 0.32 :
                 shot.kind==2 ? 0.28:0.24)
            for layer in 0..<4 {
                groundDisc(shot.point,
                    radius:radius*widths[layer]*radiusScale,
                    tint:tint,
                    alpha:min(1,strength*weights[layer]*powerScale),
                    lift:(shot.hostile ? 1.6:1.2)+lifts[layer],
                    slices:slices[layer],&output)
            }
        }
        return output
    }
    /// Combat69: EnemyShots72 muzzle emission at enemy +18 local units,
    /// during its original 0.10 seconds after actual firing.
    private static func indexedGroundDisc(
        _ frame:GroundFrame,radius:Float,tint:RGB,alpha:Float,
        lift:Float,slices:Int,
        _ mesh:inout CarbonisIndexedFXMesh568) {
        let center=frame.normal*(shell+(0.4+lift*0.10)/outer)
        let first=UInt32(mesh.vertexCount)
        let centerColor=rgba(tint,alpha)
        let edgeColor=rgba(tint,0)
        vert(center,centerColor,&mesh.vertices)
        for direction in unitCircle(slices) {
            let offset=(frame.east*direction.x+frame.south*direction.y)
                * radius * frame.scale
            vert(center+offset,edgeColor,&mesh.vertices)
        }
        for i in 0..<slices {
            mesh.indices.append(contentsOf:[
                first,first+UInt32(i+1),first+UInt32(i+2)])
        }
    }

    /// Four *unchanged* physical-source sphere light fans per shot.
    /// Indexed sectors share each ring edge; blend and triangle winding
    /// are identical to groundLights(), including all 4 radii and lifts.
    static func indexedGroundLights(
        _ shots:[CarbonisCombat568.Projectile],
        settings:CarbonisVisualSettings568,
        budget:CarbonisIOSFXBudget568 = .original
    )->CarbonisIndexedFXMesh568 {
        var mesh=CarbonisIndexedFXMesh568()
        let brightness=settings.projectileBrightnessFactor
        if brightness<=0 {return mesh}
        mesh.vertices.reserveCapacity(shots.count*1250)
        mesh.indices.reserveCapacity(shots.count*276)
        let radiusScale=0.85+brightness*0.55
        let powerScale=brightness*3.2
        let widths:[Float]=[3.9,2.4,1.5,0.85]
        let weights:[Float]=[0.18,0.55,1.10,1.80]
        let lifts:[Float]=[3.0,1.35,0.55,0.10]
        let slices=[28,24,22,18]
        for shot in shots {
            // Four original ground-light radii share the very same
            // spherical basis; no per-layer recalculation or temp mesh.
            let frame=GroundFrame(shot.point)
            let native=shot.hostile ? hostileTint(shot.kind) :
                                        playerTint(shot.kind)
            let tint=groundTint(native,settings:settings)
            let radius:Float=shot.hostile ?
                (shot.kind==2 ? 17.5 : shot.kind==3 ? 19:15.5) :
                (shot.kind==3 ? 20.5 :
                 shot.kind==4 ? 17.5 :
                 shot.kind==2 ? 16:14.5)
            let strength:Float=shot.hostile ?
                (shot.kind==2 ? 0.30:shot.kind==3 ? 0.34:0.26) :
                (shot.kind==3 ? 0.42 :
                 shot.kind==4 ? 0.32 :
                 shot.kind==2 ? 0.28:0.24)
            for layer in budget.groundLightLayers {
                indexedGroundDisc(frame,
                    radius:radius*widths[layer]*radiusScale,
                    tint:tint,
                    alpha:min(1,strength*weights[layer]*powerScale),
                    lift:(shot.hostile ? 1.6:1.2)+lifts[layer],
                    slices:budget.groundSlices(slices[layer]),&mesh)
            }
        }
        return mesh
    }
    static func muzzleFlashes(
        _ shooters:[CarbonisCombat568.Shooter],
        camera:SphereCamera67,drawableHeight:Float)->[Float] {
        let view=SphereCameraView556(camera:camera)
        var output:[Float]=[]
        for enemy in shooters where enemy.muzzle>0 {
            let point=Sphere67.offset(enemy.core.position,
                by:Vec2(x:cos(enemy.aim),y:sin(enemy.aim))*18)
            let p=worldPoint(point,2.5)
            let strength=min(1,enemy.muzzle/0.10)
            let radius=10*strength/pxPerWorld(p,camera:view,
                                               height:drawableHeight)
            disc(p,inner:0,outer:radius,
                 innerColor:rgba(RGB(r:1,g:165/255,b:80/255),220/255),
                 outerColor:rgba(RGB(r:1,g:165/255,b:80/255),0),
                 slices:24,camera:view,&output)
        }
        return output
    }
}