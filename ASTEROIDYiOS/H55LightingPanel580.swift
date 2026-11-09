import SwiftUI

/// Compact H55-only lighting calibration. Binds to AppStorage on the host
/// page; no extra game settings or GLB edits. Square, unobtrusive W3 styling.
struct H55LightingPanel580: View {
    @Binding var fill:Double
    @Binding var red:Double
    let onClose:()->Void
    private let accent=Color(red:0.89,green:0.67,blue:0.31)

    var body:some View {
        VStack(alignment:.leading,spacing:7) {
            HStack {
                Text("H55 / OŚWIETLENIE")
                    .font(.system(size:13,weight:.bold,design:.monospaced))
                Spacer(minLength:8)
                Button("ZAMKNIJ",action:onClose)
                    .accessibilityIdentifier("h55-light-close")
            }
            Text("JASNOŚĆ OTOCZENIA: \(Int((fill*100).rounded()))%")
                .font(.system(size:11,design:.monospaced))
            Slider(value:$fill,
                   in:Double(H55LightingProfile580.minimumFill)...Double(H55LightingProfile580.maximumFill),
                   step:0.05)
                .accessibilityIdentifier("h55-light-fill")
            Text("CZERWONE LAMPY: \(Int((red*100).rounded()))%")
                .font(.system(size:11,design:.monospaced))
            Slider(value:$red,
                   in:0...Double(H55LightingProfile580.maximumRed),
                   step:0.02)
                .accessibilityIdentifier("h55-light-red")
            HStack {
                Button("PRZYWRÓĆ DOMYŚLNE") {
                    fill=Double(H55LightingProfile580.defaultFill)
                    red=Double(H55LightingProfile580.defaultRed)
                }
                .accessibilityIdentifier("h55-light-reset")
                Spacer()
            }
            .font(.system(size:10,design:.monospaced))
            Text("Zmiany są widoczne na żywo i zapisywane na tym urządzeniu.")
                .font(.system(size:10,design:.monospaced))
                .foregroundStyle(.white.opacity(0.73))
        }
        .tint(accent)
        .foregroundStyle(accent)
        .padding(12)
        .frame(width:292)
        .background(Color(red:0.035,green:0.044,blue:0.065).opacity(0.97))
        .overlay(Rectangle().stroke(Color.white.opacity(0.2),lineWidth:1))
        .accessibilityIdentifier("h55-light-panel")
    }
}
