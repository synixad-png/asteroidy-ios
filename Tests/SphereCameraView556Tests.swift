import Foundation

/// Source-based render-camera parity:
/// Windows/src/SphereCombat67.cs:62 UpdateSphereCamera67
/// Windows/src/GpuSphere67.cs:414 SphereScene67:
///    eye=SphereFocus67*310, OrbitWorld50.View(eye, 0, SphereUp67).
/// Windows/src/GpuPlanetGltf463.cs:
///    HomeWorldOuterRadius523=100*1.4419674.
@main struct SphereCameraView556Tests {
    static func near(_ actual:Float,_ expected:Float,
                     tolerance:Float=0.0002) {
        precondition(actual.isFinite &&
                     abs(actual-expected)<tolerance,
                     "Camera frame diverged from original v556")
    }
    static func main() {
        near(SphereCameraView556.normalizedEyeDistance,
             310/(100*1.4419674))

        // Source GpuIntro41.cs:455 frustum(...,-.2,.2,.4,1600)
        // and GpuSphere67.cs:420 IntroProjection() for spherical scenes.
        // Guard against regression to the previously invented 36-degree FOV.
        near(SphereProjection556.sourceVerticalFocal,2)
        near(SphereProjection556.sourceVerticalFOV,
             2*atan(Float(0.5)))
        near(SphereProjection556.horizontalFocal(aspect:16/9),
             2/(Float(16)/9))
        near(SphereProjection556.horizontalFocal(aspect:4/3),
             1.5)

        // Original GpuIntro41.cs:455 not only fixes FOV; it fixes
        // near=.4 and far=1600 in the ORIGINAL world coordinate frame.
        // The iOS model/eye uses outer-radius-normalized coordinates.
        // Check the two boundaries independently of the renderer's
        // depth matrix and protect the separate old flat camera.
        near(SphereProjection556.sourceNear,0.4)
        near(SphereProjection556.sourceFar,1600)
        let sourceRadius: Float = 100*1.4419674
        let sphereClip=SphereProjection556.clipPlanes(spherical:true)
        near(sphereClip.near,0.4/sourceRadius,tolerance:0.000001)
        near(sphereClip.far,1600/sourceRadius,tolerance:0.00001)
        near(SphereProjection556.normalizedNear,
             sphereClip.near,tolerance:0.000001)
        near(SphereProjection556.normalizedFar,
             sphereClip.far,tolerance:0.00001)
        let flatClip=SphereProjection556.clipPlanes(spherical:false)
        near(flatClip.near,0.1)
        near(flatClip.far,20)
        precondition(sphereClip.near>0 && sphereClip.far>sphereClip.near)
        // Metal perspective uses z=A*zView+B, w=-zView.
        // Source near must map to NDC z=0, source far to NDC z=1.
        func depthNDC(_ distance:Float,_ clip:(near:Float,far:Float))->Float {
            let a=clip.far/(clip.near-clip.far)
            let b=clip.near*clip.far/(clip.near-clip.far)
            return (a * -distance + b) / distance
        }
        near(depthNDC(sphereClip.near,sphereClip),0,tolerance:0.00001)
        near(depthNDC(sphereClip.far,sphereClip),1,tolerance:0.00001)
        near(depthNDC(flatClip.near,flatClip),0,tolerance:0.00001)
        near(depthNDC(flatClip.far,flatClip),1,tolerance:0.00001)

        // Direct original Orbit50.cs:32 column-major matrix at the
        // equator, longitude zero; unlike self-derived assertions this
        // explicitly catches a transpose of the Metal uniform layout.
        let equator=SphereCameraView556(
            camera:SphereCamera67(at:Vec2(x:0,y:360)))
        let exact:[Float] = [
            0,0,1,0,
            0,-1,0,0,
            1,0,0,0,
            0,0,-SphereCameraView556.normalizedEyeDistance,1
        ]
        let raw=equator.viewColumnMajor
        precondition(raw.count==16)
        for i in exact.indices {near(raw[i],exact[i])}

        let points=[
            Vec2(x:0,y:360),Vec2(x:320,y:360),
            Vec2(x:640,y:360),Vec2(x:960,y:360),
            Vec2(x:0,y:5),Vec2(x:700,y:715),
            Vec2(x:1123,y:168),Vec2(x:20,y:500)]
        for point in points {
            let source=SphereCamera67(at:point)
            let frame=SphereCameraView556(camera:source)
            near(frame.eye.length,SphereCameraView556.normalizedEyeDistance)
            near(frame.right.length,1)
            near(frame.up.length,1)
            near(frame.back.length,1)
            near(SphereVector3.dot(frame.right,frame.up),0)
            near(SphereVector3.dot(frame.right,frame.back),0)
            near(SphereVector3.dot(frame.up,frame.back),0)

            let center=frame.cameraSpace(.init(x:0,y:0,z:0))
            near(center.x,0)
            near(center.y,0)
            near(center.z,-SphereCameraView556.normalizedEyeDistance)
            let shipSurface=frame.back * 1.09
            let viewShip=frame.cameraSpace(shipSurface)
            near(viewShip.x,0)
            near(viewShip.y,0)
            near(viewShip.z,
                 1.09-SphereCameraView556.normalizedEyeDistance)
            // The orbit camera's +right, +up and -forward basis must
            // survive the view transformation without sign inversions.
            let offAxis=frame.eye + frame.right*0.31 + frame.up*0.42 - frame.back*1.25
            let viewPoint=frame.cameraSpace(offAxis)
            near(viewPoint.x,0.31)
            near(viewPoint.y,0.42)
            near(viewPoint.z,-1.25)
        }

        // GpuSphere67.cs:4,63,133,368 source StampSphere67. The
        // original planet outer radius is 100*1.4419674, shell adds
        // exactly 15 source units, and tangent axes are right/forward/up.
        near(SphereSurfaceStamp556.sourceShellRadius,
             100*1.4419674+15)
        near(SphereSurfaceStamp556.normalizedShellRadius,
             1+15/(100*1.4419674))
        near(SphereSurfaceStamp556.normalizedScalePerArcUnit,
             SphereSurfaceStamp556.normalizedShellRadius/Sphere67.radius)
        near(SphereSurfaceStamp556.sourceCraftRadius,10*1.12*0.65)

        // Standalone fixed reference, not derived from the tested helper:
        // at lon=0/equator, forward points +Z; right=forward×normal=+Y.
        let fixedStamp=SphereSurfaceStamp556(
            point:Vec2(x:0,y:360),angle:0)
        let scale:Float=10*SphereSurfaceStamp556.normalizedScalePerArcUnit
        let fixed:[Float]=[
            0,scale,0,0,
            0,0,scale,0,
            scale,0,0,0,
            1+15/(100*1.4419674),0,0,1
        ]
        let columns=fixedStamp.columnMajor(size:10)
        precondition(columns.count==16)
        for i in fixed.indices {near(columns[i],fixed[i])}

        // Source heading must really rotate the whole local craft
        // basis, not just spin a sprite in the camera plane.
        let north=SphereSurfaceStamp556(
            point:Vec2(x:0,y:360),angle:Float.pi/2)
        near(north.forward.x,0)
        near(north.forward.y,-1)
        near(north.forward.z,0)
        near(north.right.x,0)
        near(north.right.y,0)
        near(north.right.z,1)

        for point in points {
            for angle in [Float(0),Float.pi/2,Float.pi,Float(5.2)] {
                let stamp=SphereSurfaceStamp556(
                    point:point,angle:angle,lift:35)
                near(stamp.normal.length,1)
                near(stamp.right.length,1)
                near(stamp.forward.length,1)
                near(SphereVector3.dot(stamp.right,stamp.forward),0)
                near(SphereVector3.dot(stamp.right,stamp.normal),0)
                near(SphereVector3.dot(stamp.forward,stamp.normal),0)
                let expectedLift=SphereSurfaceStamp556.normalizedShellRadius + 35*SphereSurfaceStamp556.normalizedScalePerArcUnit
                near(stamp.position.length,expectedLift)
                let m=stamp.columnMajor(size:31)
                near(sqrt(m[0]*m[0]+m[1]*m[1]+m[2]*m[2]),
                     31*SphereSurfaceStamp556.normalizedScalePerArcUnit)
                near(sqrt(m[4]*m[4]+m[5]*m[5]+m[6]*m[6]),
                     31*SphereSurfaceStamp556.normalizedScalePerArcUnit)
                near(sqrt(m[8]*m[8]+m[9]*m[9]+m[10]*m[10]),
                     31*SphereSurfaceStamp556.normalizedScalePerArcUnit)
                near(m[12],stamp.position.x)
                near(m[13],stamp.position.y)
                near(m[14],stamp.position.z)
            }
        }

        // Windows GpuAmbient37.cs SpaceHash207 / SpaceRand207 and
        // GpuIntro41.cs:452. Fixed independent hash/coordinate fixtures
        // were computed from the original C# uint-overflow formula, not
        // from the Swift helper itself. Star array is never randomized
        // from a different LCG (the old flat arena still keeps its LCG).
        precondition(SphereSky207.count==1500)
        // Source SkyProject55 assumes a 720 px projection; Metal uses
        // native drawable pixels. Retina scaling preserves angular size
        // without changing original 0.7/1.4/2.8px source attributes.
        near(SphereSky207.drawableScale(height:720),1)
        near(SphereSky207.drawableScale(height:1440),2)
        near(SphereSky207.drawableScale(height:360),0.5)
        near(SphereSky207.drawableScale(height:0),1)
        near(SphereSky207.drawableScale(height:.nan),1)
        near(SphereSky207.normalizedSkyRadius,
             900/(100*1.4419674))
        near(SphereSky207.spaceRand207(41,0,17),0.890627497,
             tolerance:0.000002)
        near(SphereSky207.spaceRand207(41,0,31),0.323639829,
             tolerance:0.000002)
        near(SphereSky207.spaceRand207(41,1,17),0.155577550,
             tolerance:0.000002)
        near(SphereSky207.spaceRand207(41,1499,53),0.362408600,
             tolerance:0.000002)
        let star0=SphereSky207.star(0)
        near(star0.direction.x,0.72333744,tolerance:0.00002)
        near(star0.direction.y,-0.35272034,tolerance:0.00002)
        near(star0.direction.z,-0.59360871,tolerance:0.00002)
        near(star0.pixelSize,0.7)
        near(star0.red,186/255)
        near(star0.green,214/255)
        near(star0.blue,244/255)
        near(star0.alpha,220/255)
        var bright=0,large=0,warm=0
        for i in 0..<SphereSky207.count {
            let star=SphereSky207.star(i)
            near(star.direction.length,1,tolerance:0.00002)
            precondition(star.red>=0 && star.red<=1)
            precondition(star.green>=0 && star.green<=1)
            precondition(star.blue>=0 && star.blue<=1)
            precondition(star.pixelSize==0.7 ||
                         star.pixelSize==1.4 ||
                         star.pixelSize==2.8)
            if star.pixelSize>0.7 {bright+=1}
            if star.pixelSize==2.8 {large+=1}
            if star.alpha>0.9 {warm+=1}
        }
        // Original C# uint SpaceHash207 over all 1500 source indices:
        // exactly 1294 ordinary, 172 bright, 34 very bright and
        // 161 warm stars. With GlowEnabled=true the batched GPU points
        // must contain 1500 main halos + 206 preceding bright halos.
        precondition(bright==206 && large==34 && warm==161)

        // Independent C# GpuAmbient37.StarTexture goldens. Bitmap uses
        // 64x64 PArgb with premultiplied BGRA bytes equal to alpha.
        let sourceTexels=SphereSky207.haloTexelsBGRA()
        precondition(sourceTexels.count==64*64*4)
        let golden:[(Int,Int,UInt8)]=[
            (0,0,0),(31,31,243),(32,32,243),
            (31,0,0),(31,10,3),(31,16,24),(31,20,60),
            (31,24,117),(31,28,191),(35,35,164)
        ]
        for (x,y,a) in golden {
            precondition(SphereSky207.haloAlpha(x:x,y:y)==a)
            let base=(y*64+x)*4
            for c in 0..<4 { precondition(sourceTexels[base+c]==a) }
        }
        // GpuIntro41.cs:452: base IntroHalo(radius:size*2)
        // => 4*size diameter; for glow && bright a preceding 10 or
        // 21 radius halo with tint alpha 125/255. Original default
        // Renderer.GlowEnabled is true.
        let sourceSmall=SphereSkyStar207(
            direction:star0.direction,pixelSize:0.7,
            red:star0.red,green:star0.green,
            blue:star0.blue,alpha:star0.alpha)
        let sourceMedium=SphereSkyStar207(
            direction:star0.direction,pixelSize:1.4,
            red:star0.red,green:star0.green,
            blue:star0.blue,alpha:star0.alpha)
        let sourceLarge=SphereSkyStar207(
            direction:star0.direction,pixelSize:2.8,
            red:star0.red,green:star0.green,
            blue:star0.blue,alpha:star0.alpha)
        near(SphereSky207.baseDiameterPixels(sourceSmall),2.8)
        near(SphereSky207.baseDiameterPixels(sourceMedium),5.6)
        near(SphereSky207.baseDiameterPixels(sourceLarge),11.2)
        precondition(!SphereSky207.hasBrightHalo(sourceSmall))
        precondition(SphereSky207.hasBrightHalo(sourceMedium))
        precondition(SphereSky207.hasBrightHalo(sourceLarge))
        near(SphereSky207.brightHaloDiameterPixels(sourceMedium),20)
        near(SphereSky207.brightHaloDiameterPixels(sourceLarge),42)

        // The camera MUST follow ship flight across the globe. Previously
        // MetalRenderer displayed the whole planet from a fixed (0,0,4)
        // viewpoint despite SphereCamera67 being updated every physics tick.
        var camera=SphereCamera67(at:Vec2(x:0,y:360))
        let target=Vec2(x:320,y:360)
        let initialEye=SphereCameraView556(camera:camera).eye
        for _ in 0..<240 {camera.update(target:target,dt:1/120)}
        let moved=SphereCameraView556(camera:camera)
        precondition((moved.eye-initialEye).length>0.5)
        precondition(SphereVector3.dot(moved.back,Sphere67.normal(target))>0.999)
        near(moved.eye.length,SphereCameraView556.normalizedEyeDistance)

        print("PASS: source GpuIntro41 53.13-degree planet frustum + GpuSphere67 310-unit orbit camera, 8 sphere positions, exact original Orbit50.cs view columns, GpuSphere67 surface stamp basis/scale and 240 tracked flight frames")
    }
}
