import Foundation
import SwiftUI

/// The one original 159-track glTF HUD model, using a lightweight display
/// timeline solely for screen positioning. Its SCNView is created ONCE;
/// GLTFKit2 never decodes or uploads anything per visual frame.
/// Windows HudGlbAssets.DrawHudGlb projects its screen-space center via
/// HudMotionPose.Project at render cadence, NOT the 10Hz radar snapshot.
struct HudPlanetariumHost600:View {
    let original:URL
    let widget:HudLayout600.Widget
    let placement:HudWidgetPlacement600.Frame
    let viewport:CombatHUDViewport568
    let session:CarbonisSession568
    let active:Bool

    var body:some View {
        TimelineView(.animation(minimumInterval:1.0/30.0,paused:!active)) { _ in
            let state=session.currentHudVisual600()
            let projected=HudMotionProject600.project(
                x:widget.x+125,y:widget.y+67.5,
                pose:state.pose,widget:"hud.planetarium")
            HudPlanetariumScene600(
                original:original,
                capsule:state.capsules,
                pitch:Float(widget.pitch ?? -20),
                yaw:Float(widget.yaw ?? 0),
                roll:Float(widget.roll ?? 0),
                pose:state.pose,
                playing:active,
                livePose:{ [weak session] in
                    session?.currentHudVisual600().pose ?? HudMotion600.Pose()
                },
                liveCapsules:{ [weak session] in
                    session?.currentHudVisual600().capsules ??
                        HudCapsuleController600.Snapshot(
                            levels:[1,1,1],flashes:[0,0,0])
                })
            .frame(width:CGFloat(placement.width),
                   height:CGFloat(placement.height))
            .position(x:CGFloat(viewport.x(projected.x,at:.bottomLeft)),
                      y:CGFloat(viewport.y(projected.y,at:.bottomLeft)))
            .allowsHitTesting(false)
            .accessibilityIdentifier("sector01-hud-v600-original-planetarium")
        }
        .allowsHitTesting(false)
    }
}
