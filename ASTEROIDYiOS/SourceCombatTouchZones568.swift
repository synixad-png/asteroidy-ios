import SwiftUI

/// One touch-input surface shared by Carbonis 01 and PC602 H290.
/// The two TRANSPARENT half-screen drag gestures are the original working
/// iOS mission controls: left translation /110, right aim /100 + held fire.
/// No painted or simulated joysticks. Keep the actual game-specific state
/// and release path in the caller instead of creating a second input owner.
struct SourceCombatTouchZones568:View {
    let onMove:(Vec2)->Void
    let onAim:(Vec2)->Void
    let onFire:(Bool)->Void

    private func clamped(_ raw:Float)->Float {
        max(-1,min(1,raw))
    }

    var body:some View {
        HStack(spacing:0) {
            Color.clear.contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance:0)
                    .onChanged { value in
                        onMove(Vec2(x:clamped(Float(value.translation.width)/110),
                                    y:clamped(Float(value.translation.height)/110)))
                    }
                    .onEnded { _ in onMove(Vec2(x:0,y:0)) })
                .accessibilityLabel("Lewy obszar: lot i przemieszczanie statku")
                .accessibilityIdentifier("source-combat-left-touch-zone")
            Color.clear.contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance:0)
                    .onChanged { value in
                        onAim(Vec2(x:clamped(Float(value.translation.width)/100),
                                   y:clamped(Float(value.translation.height)/100)))
                        onFire(true)
                    }
                    .onEnded { _ in
                        onAim(Vec2(x:0,y:0))
                        onFire(false)
                    })
                .accessibilityLabel("Prawy obszar: skręt i ciągły ostrzał")
                .accessibilityIdentifier("sector01-right-steer-auto-fire")
        }
    }
}
