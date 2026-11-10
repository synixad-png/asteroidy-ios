import Foundation
import SwiftUI

/// Live original PC v602 animated GLB drawn in ONE full-screen HUD coordinate
/// space. Only the original model moves internally; its user-edited F6 screen
/// center stays stationary, including during combat HUD motion.
struct HudPlanetariumHost600:View {
    let original:URL
    let widget:HudLayout600.Widget
    let placement:HudWidgetPlacement600.Frame
    let viewport:CombatHUDViewport568
    let session:CarbonisSession568
    let active:Bool
    let motionActive:Bool

    var body:some View {
        // Before this fix, .position was applied inside an intrinsically small
        // TimelineView child rather than the actual full-screen 1280x720 HUD.
        // It made the original planetarium sometimes appear in the center
        // and sometimes outside the visible screen.
        HudPlanetariumScene600(
            original:original,
            capsule:session.currentHudVisual600().capsules,
            pitch:Float(widget.pitch ?? -20),
            yaw:Float(widget.yaw ?? 0),
            roll:Float(widget.roll ?? 0),
            pose:HudMotion600.Pose(),
            playing:active,
            livePose:{ HudMotion600.Pose() },
            liveCapsules:{ [weak session] in
                session?.currentHudVisual600().capsules ??
                    HudCapsuleController600.Snapshot(
                        levels:[1,1,1],flashes:[0,0,0])
            },
            liveGameTime:{ [weak session] in
                session?.currentHudVisual600().seconds ?? 0
            })
            .frame(width:CGFloat(placement.width),
                   height:CGFloat(placement.height))
            .position(x:CGFloat(placement.centerX),
                      y:CGFloat(placement.centerY))
            .frame(width:CGFloat(viewport.width),
                   height:CGFloat(viewport.height),alignment:.topLeading)
            .allowsHitTesting(false)
            .accessibilityIdentifier("sector01-hud-v600-original-planetarium")
    }
}
