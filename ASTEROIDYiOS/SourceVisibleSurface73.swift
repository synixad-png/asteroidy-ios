import Foundation

/// Conservative iOS port of ORIGINAL GpuSphere67.VisibleSurface73.
/// The original PC renderer rejects offscreen rocks and fighters BEFORE
/// submitting meshes. The previous iOS port submitted every actor.
///
/// C279 immutable source mesh audit: minimum radial height 0.91967547,
/// maximum 1.09607506; missionScale523 = 1/max. Thus the actual
/// normalized *minimum* visible terrain radius is >0.839. The 0.80
/// occlusion sphere below is strictly INSIDE all source terrain; a ray
/// through this inner volume cannot see a surface actor on its far side.
/// The extra actor radius margin guards large rocks and enemy hulls.
/// Screen extents use the exact iPad/iPhone viewport projection.
enum SourceVisibleSurface73 {
    static let innerTerrainRadius:Float=0.80
    static let shellRadius:Float = (SphereCameraView556.originalPlanetOuterRadius+15)
        / SphereCameraView556.originalPlanetOuterRadius

    static func possiblyVisible(_ point:Vec2,worldRadius:Float,
                                camera:SphereCameraView556,
                                aspect:Float)->Bool {
        let radius=max(0,worldRadius)
        let center=Sphere67.normal(point)*shellRadius
        let ray=center-camera.eye
        let len2=SphereVector3.dot(ray,ray)
        if len2>0.000001 {
            let t = -SphereVector3.dot(camera.eye,ray)/len2
            // The original culls only if entire actor's conservative
            // bounding sphere is safely occluded by globe interior.
            let safe=max(0,innerTerrainRadius-radius)
            if safe>0 && t>0 && t<1 {
                let nearest=camera.eye+ray*t
                if SphereVector3.dot(nearest,nearest)<safe*safe {
                    return false
                }
            }
        }
        let p=camera.cameraSpace(center)
        let depth = -p.z
        if depth < -radius {return false}
        if depth <= radius {return true}
        let focal=MissionViewportFraming568.focals(
            aspect:aspect,
            sourceVerticalFocal:SphereProjection556.sourceVerticalFocal)
        // The old (abs(center)+radius)/(depth-radius) expression
        // incorrectly rejected a large luminous ring EVEN WHEN ITS
        // CENTRE WAS ON SCREEN. It tests full containment, not whether
        // any part of the sphere intersects the view. The correct
        // conservative frustum/plane test below uses the exact support
        // radius of a sphere against each perspective side plane:
        // |x|*fx-depth <= r*sqrt(1+fx*fx), likewise for y.
        // Only an ENTIRELY invisible object may skip rendering.
        let margin:Float=0.08
        let horizontal=abs(p.x)*focal.horizontal
        let vertical=abs(p.y)*focal.vertical
        let hLimit=depth*(1+margin)+radius*
            sqrt(1+focal.horizontal*focal.horizontal)
        let vLimit=depth*(1+margin)+radius*
            sqrt(1+focal.vertical*focal.vertical)
        return horizontal<=hLimit && vertical<=vLimit
    }

    static func rockWorldRadius(_ rock:SphereAsteroid556)->Float {
        let outer=SphereCameraView556.originalPlanetOuterRadius
        let shell=outer+15
        return rock.radius*(shell/Sphere67.radius)/outer * 1.4
    }
    static func shooterWorldRadius()->Float {
        // PC GpuSphere67.cs:422: normal shooter bound 19*Scale67.
        // Add 20% reserve for source muzzle and telegraph animation.
        let outer=SphereCameraView556.originalPlanetOuterRadius
        let shell=outer+15
        return 19*(shell/Sphere67.radius)/outer*1.20
    }
}
