import SwiftUI

/// One pause-menu visual standard for CARBONIS 01 and PC602 H290. All
/// actions are supplied by the real game sessions: no placeholder navigation
/// and no second source of pause state or HUD settings.
struct SourcePauseMenu568:View {
    let compact:Bool
    let subtitle:String
    let details:String
    let settingsID:String
    let slotsID:String
    let continueID:String
    let exitID:String
    let onSettings:()->Void
    let onSlots:()->Void
    let onContinue:()->Void
    let onExit:()->Void

    private let cyan=Color(red:0.55,green:0.77,blue:0.80)
    private let gold=Color(red:0.88,green:0.67,blue:0.31)
    private let dark=Color(red:0.05,green:0.15,blue:0.22)

    private func action(_ label:String,primary:Bool=false,
                        identifier:String,perform:@escaping ()->Void)->some View {
        Button(action:perform) {
            Text(label)
                .font(.system(size:compact ? 15:18,
                              weight:.bold,design:.monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.92)
                .frame(maxWidth:.infinity,minHeight:compact ? 48:58)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(primary ? Color(red:0.07,green:0.13,blue:0.17):.white)
        .background(primary ? gold : dark,
                    in:RoundedRectangle(cornerRadius:5))
        .overlay(RoundedRectangle(cornerRadius:5)
            .stroke(primary ? gold:cyan.opacity(0.4),lineWidth:1))
        .accessibilityIdentifier(identifier)
    }

    var body:some View {
        ZStack {
            Color.black.opacity(0.80).ignoresSafeArea()
            VStack(alignment:.leading,spacing:compact ? 10:16) {
                Text("SYNIXAD // SYSTEM ROZGRYWKI")
                    .font(.system(size:compact ? 14:16,weight:.bold,
                                  design:.monospaced))
                    .foregroundStyle(cyan)
                Text("GRA WSTRZYMANA")
                    .font(.system(size:compact ? 23:35,weight:.heavy,
                                  design:.monospaced))
                    .foregroundStyle(.white)
                Text("SYTUACJA ZACHOWANA / CZAS ROZGRYWKI ZATRZYMANY")
                    .font(.system(size:compact ? 13:15,design:.monospaced))
                    .foregroundStyle(.gray)
                Divider().overlay(gold)
                action("USTAWIENIA",identifier:settingsID,perform:onSettings)
                action("ZAPISY / 3 SLOTY",identifier:slotsID,perform:onSlots)
                action("KONTYNUUJ",primary:true,identifier:continueID,
                       perform:onContinue)
                action("WYJDŹ DO MENU",identifier:exitID,perform:onExit)
                Text(subtitle+"    "+details)
                    .font(.system(size:compact ? 13:15,design:.monospaced))
                    .foregroundStyle(.gray)
                    .lineLimit(2)
            }
            .padding(compact ? 16:28)
            .frame(maxWidth:650)
            .background(Color(red:0.02,green:0.05,blue:0.09),
                        in:RoundedRectangle(cornerRadius:12))
            .overlay(RoundedRectangle(cornerRadius:12)
                .stroke(Color(red:0.24,green:0.38,blue:0.44),lineWidth:1))
            .padding(12)
        }
    }
}
