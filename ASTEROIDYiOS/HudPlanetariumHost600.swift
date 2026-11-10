import SwiftUI

/// Original PC v602 glTF rendered on the entire HUD display plane.
/// Widget x/y/scale belong only to the F6 layout; authored animation moves
/// components *inside* the scene, never the display-plane anchor.
struct HudPlanetariumHost600: View {
    let original: URL
    let widget: HudLayout600.Widget
    let placement: HudWidgetPlacement600.Frame
    let viewport: CombatHUDViewport568
    let session: CarbonisSession568
    let active: Bool

    var body: some View {
        Group {
            if let projection = HudPlanetariumProjection.make(
                placement: placement,
                viewport: viewport,
                widget: widget,
                modelRadius: HudPlanetariumAsset600.pc602ModelRadius
            ) {
                HudPlanetariumScene600(
                    original: original,
                    projection: projection,
                    capsule: session.currentHudVisual600().capsules,
                    pitch: Float(widget.pitch ?? -20),
                    yaw: Float(widget.yaw ?? 0),
                    roll: Float(widget.roll ?? 0),
                    playing: active,
                    liveCapsules: { [weak session] in
                        session?.currentHudVisual600().capsules ??
                        HudCapsuleController600.Snapshot(
                            levels: [1,1,1], flashes: [0,0,0])
                    },
                    liveGameTime: { [weak session] in
                        session?.currentHudVisual600().seconds ?? 0
                    }
                )
                .frame(width: CGFloat(viewport.width),
                       height: CGFloat(viewport.height))
                .allowsHitTesting(false)
            }
        }
        .accessibilityIdentifier("sector01-hud-v600-original-planetarium")
    }
}
