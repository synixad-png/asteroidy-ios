import Foundation

/// PC v602 HomeScene291 world camera contract:
/// OrbitWorld50.View(sphereEye67, origin, SphereUp67) followed by the
/// actual GpuIntro41.IntroProjection frustum. The Metal projection adapts
/// only OpenGL depth (-1...+1) to Metal depth (0...1); the source vertical
/// FOV, camera radius and all original world units stay unchanged.
struct PC602HomeWorldView291 {
    static let cameraRadius:Float=400
    static let near:Float=0.4
    static let far:Float=1600
    static let verticalFocal:Float=2
    let view:[Float]          // column-major OrbitWorld50.View
    let projection:[Float]    // column-major Metal depth [0,1]
    let eye:SIMD3<Float>

    init?(camera:SphereCamera67,aspect:Float) {
        guard aspect.isFinite,aspect>0 else{return nil}
        let origin=SphereVector3(x:0,y:0,z:0)
        let position=camera.focus.normalized*Self.cameraRadius
        guard let view=Self.view(
            eye:position,target:origin,up:camera.up)
        else{return nil}
        self.view=view
        self.projection=Self.metalProjection(aspect:aspect)
        self.eye=SIMD3<Float>(position.x,position.y,position.z)
    }

    /// Exact OrbitWorld50.View look-at basis, including the PC pole fallback.
    static func view(eye:SphereVector3,target:SphereVector3,
                     up:SphereVector3)->[Float]? {
        let forward=(target-eye).normalized
        guard forward.length>0.1 else{return nil}
        var right=SphereVector3.cross(forward,up).normalized
        if right.length<0.1 {
            let axis=abs(forward.y)<0.9
                ? SphereVector3(x:0,y:1,z:0)
                : SphereVector3(x:1,y:0,z:0)
            right=SphereVector3.cross(forward,axis).normalized
        }
        guard right.length>0.1 else{return nil}
        let actualUp=SphereVector3.cross(right,forward)
        return [
            right.x,actualUp.x,-forward.x,0,
            right.y,actualUp.y,-forward.y,0,
            right.z,actualUp.z,-forward.z,0,
            -SphereVector3.dot(right,eye),
            -SphereVector3.dot(actualUp,eye),
            SphereVector3.dot(forward,eye),1
        ]
    }

    /// OpenGL GpuIntro41.frustum(-.35555556,.35555556,-.2,.2,.4,1600)
    /// at 16:9. On iPhone/iPad the original 53.13° vertical FOV is kept
    /// while the horizontal frustum follows the live Metal drawable aspect.
    static func metalProjection(aspect:Float)->[Float] {
        let x=verticalFocal/aspect
        let z=far/(near-far)
        let w=(far*near)/(near-far)
        return [
            x,0,0,0,
            0,verticalFocal,0,0,
            0,0,z,-1,
            0,0,w,0
        ]
    }

    /// Exact original OrbitWorld50.Visible: 21 physical sight-line samples.
    /// This uses actual imported terrain, not a fictional sphere.
    static func visible(from eye:SIMD3<Float>,to point:SIMD3<Float>,
                        on home:PC602NewHome290)->Bool {
        let delta=point-eye
        for k in 1..<22 {
            let sample=eye+delta*(Float(k)/22)
            let distance=sqrt(sample.x * sample.x + sample.y * sample.y + sample.z * sample.z)
            guard let terrain=home.surface(sample) else{return false}
            if distance<terrain+0.6 {return false}
        }
        return true
    }
}
