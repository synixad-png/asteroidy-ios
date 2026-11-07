import Foundation

/// Source viewport: GpuIntro41.cs:455 frustum(.35555556,.2,.4)
/// and the original 1280×720 frame in Sphere67.cs / GpuPlanet.cs.
/// Only the optical projection is adapted to a narrower iPad viewport.
/// Never alter source camera eye (310), world scale (v523), radius,
/// planet geometry, Atmosphere47 mesh or projectile/actor transforms.
enum MissionViewportFraming568 {
    static let sourceWidth:Float=1280
    static let sourceHeight:Float=720
    static let sourceAspect:Float=sourceWidth/sourceHeight

    static func focals(aspect:Float,sourceVerticalFocal:Float)
        -> (horizontal:Float,vertical:Float) {
        // Preserve the original vertical FOV at 16:9 and all wider iPhones.
        // In a narrower viewport preserve the original horizontal field
        // of view by widening the vertical FOV. A 4:3 iPad gets 75% of
        // the source vertical focal; no device-specific arbitrary zoom.
        let a=aspect.isFinite && aspect>0 ? max(0.35,aspect) : sourceAspect
        let scale=min(1,a/sourceAspect)
        let vertical=sourceVerticalFocal*scale
        return (horizontal:vertical/a,vertical:vertical)
    }
}
