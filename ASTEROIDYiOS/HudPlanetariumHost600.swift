import SwiftUI

/// A genuine screen-space HUD element, never a child of the Metal mission
/// camera or of any animated glTF node. Its only layout input is the saved
/// PC v602 F6 rectangle from HudWidgetPlacement600. Internal animations remain
/// on the source GLB hierarchy and cannot translate this full-screen host.
struct HudPlanetariumHost600:View {
    let original:URL
    let widget:HudLayout600.Widget
    let placement:HudWidgetPlacement600.Frame
    let viewport:CombatHUDViewport568
    let session:CarbonisSession568
    let active:Bool

    var body:some View {
        // GeometryReader establishes ONE immutable display-point origin.
        // Unlike SwiftUI .position applied to a proposed-size subview,
        // this frame is not reinterpreted relative to the 3D model bounds.
        GeometryReader { _ in
            HudPlanetariumScene600(
                original:original,
                capsule:session.currentHudVisual600().capsules,
                pitch:Float(widget.pitch ?? -20),
                yaw:Float(widget.yaw ?? 0),
                roll:Float(widget.roll ?? 0),
                pose:HudMotion600.Pose(),
                playing:active,
                livePose:{HudMotion600.Pose()},
                liveCapsules:{[weak session] in
                    session?.currentHudVisual600().capsules ??
                        HudCapsuleController600.Snapshot(
                            levels:[1,1,1],flashes:[0,0,0])
                },
                liveGameTime:{[weak session] in
                    session?.currentHudVisual600().seconds ?? 0
                })
                .frame(width:CGFloat(placement.width),
                       height:CGFloat(placement.height))
                .offset(x:CGFloat(placement.centerX-placement.width*0.5),
                        y:CGFloat(placement.centerY-placement.height*0.5))
        }
        .frame(width:CGFloat(viewport.width),
               height:CGFloat(viewport.height),alignment:.topLeading)
        .clipped()
        .allowsHitTesting(false)
        .accessibilityIdentifier("sector01-hud-v600-original-planetarium")
    }
}
