import Foundation

/// Full-screen orthographic HUD camera, in UIKit display points.
/// PC v602 HudGlbAssets.DrawHudGlb draws into ortho(0,1280,720,0) and
/// does NOT clip 3D assets to their F6 selection rectangle.
/// Keep its model scale and position separate from internal glTF animation.
enum HudPlanetariumProjection {
    struct Transform: Equatable {
        let x: Double
        let y: Double
        let pixelsPerModelUnit: Double
        let cameraHalfHeight: Double

        func screenPosition(viewport: CombatHUDViewport568) -> (x: Double,y: Double) {
            (x + viewport.width * 0.5, viewport.height * 0.5 - y)
        }
    }

    static func make(placement: HudWidgetPlacement600.Frame,
                     viewport: CombatHUDViewport568,
                     widget: HudLayout600.Widget,
                     modelRadius: Double) -> Transform? {
        guard widget.visible, widget.is3D,
              widget.scale.isFinite, widget.scale > 0,
              modelRadius.isFinite, modelRadius > 0,
              viewport.width.isFinite, viewport.height.isFinite,
              viewport.width > 0, viewport.height > 0,
              let size = HudWidgetGeometry600.size(widget.id),
              size.width > 0 else { return nil }

        // In PC source the 3D mesh scale is 0.44 * Width * Scale / radius.
        // F6 widget position is the centre of that whole, unclipped model.
        let pixels = 0.44 * size.width * widget.scale *
            viewport.scale / modelRadius
        guard pixels.isFinite, pixels > 0,
              placement.centerX.isFinite, placement.centerY.isFinite else { return nil }
        return Transform(x: placement.centerX - viewport.width * 0.5,
                         y: viewport.height * 0.5 - placement.centerY,
                         pixelsPerModelUnit: pixels,
                         cameraHalfHeight: viewport.height * 0.5)
    }
}
