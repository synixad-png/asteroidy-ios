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

        print("PASS: source GpuIntro41 53.13-degree planet frustum + GpuSphere67 310-unit orbit camera, 8 sphere positions, exact original Orbit50.cs matrix columns and view basis and 240 tracked flight frames")
    }
}
