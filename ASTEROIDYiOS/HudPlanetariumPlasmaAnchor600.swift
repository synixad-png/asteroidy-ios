import Foundation

/// Screen-space attachment of the authored planetarium's three status
/// capsules to the three PC v602 plasma gauge widgets.
///
/// The approved F6 coordinates stay independent/editable. The original
/// model has one rigid transform, so a shared gauge-group displacement
/// (not three conflicting per-capsule transforms) is applied at draw time.
/// Live HUD inertia uses exactly the same 0.78 group weight and virtual
/// 1280x720 centre as SourceCombatHUD331.widgetContext for each gauge.
enum HudPlanetariumPlasmaAnchor600 {
    struct Point: Equatable {
        let x: Double
        let y: Double
    }

    private static let ids = ["hull.bar", "armor.bar", "shield.bar"]
    private static let approved = HudLayout600.defaults()

    /// Plasma begins at its *left* end, directly beside the three
    /// CAPUSLE_X sockets in the original planetarium GLB. The centreline
    /// of PC RendererHudEnergy.DrawEnergyGauge is 4.5 logical pixels down.
    static func gaugeOrigin(_ bar: HudLayout600.Widget) -> Point {
        Point(x:bar.x+bar.scale, y:bar.y+4.5*bar.scale)
    }

    /// Original F6 placement plus common live displacement of the three
    /// gauge-bar origins. No edits to the saved planetarium X/Y/scale.
    /// This cannot rigidly match bars subsequently moved *individually*;
    /// such independent edits remain available in the F6 editor.
    static func sourceCenter(widget:HudLayout600.Widget,
                             layout:HudLayout600)->Point? {
        guard widget.id=="hud.planetarium",
              let dimensions=HudWidgetGeometry600.size(widget.id),
              widget.visible else{return nil}
        var deltaX=0.0,deltaY=0.0,count=0
        for name in ids {
            guard let current=layout.widget(name),current.visible,
                  let baseline=approved.widget(name) else{continue}
            let actual=gaugeOrigin(current)
            let reference=gaugeOrigin(baseline)
            deltaX += actual.x-reference.x
            deltaY += actual.y-reference.y
            count += 1
        }
        // If all three gauges are hidden, retain the independently edited
        // planetarium position and avoid fabricating an anchor.
        let shiftX=count>0 ? deltaX/Double(count) : 0
        let shiftY=count>0 ? deltaY/Double(count) : 0
        return Point(x:widget.x+dimensions.width*0.5+shiftX,
                     y:widget.y+dimensions.height*0.5+shiftY)
    }

    static func screenCenter(widget:HudLayout600.Widget,
                             layout:HudLayout600,
                             pose:HudMotion600.Pose,
                             viewport:CombatHUDViewport568)->Point? {
        guard let origin=sourceCenter(widget:widget,layout:layout)
        else{return nil}
        // All three plasma gauges have the same PC HudMotionPose.Weight:
        // 0.78 when parallax is active, 1.0 otherwise. The separate
        // planetarium's former 1.18 causes visible detachment in flight.
        let moving=HudMotionProject600.project(
            x:origin.x,y:origin.y,pose:pose,widget:"armor.bar")
        return Point(x:viewport.x(moving.x,at:.bottomLeft),
                     y:viewport.y(moving.y,at:.bottomLeft))
    }

    static func visualRoll(pose:HudMotion600.Pose)->Float {
        pose.roll*pose.weight("armor.bar")
    }
}
