import Foundation
import SwiftUI

/// iOS combat HUD driven exclusively by the live CarbonisSession568.HUD.
/// The Windows v568 graphical skin is not embedded in this repository.
/// This view does not invent mission values, modify combat, or poll the GPU.
struct Sector01MissionHUD568: View {
    let hud:CarbonisSession568.HUD
    let compact:Bool

    private var panel:Color {Color(red:0.015,green:0.034,blue:0.055)}
    private var ink:Color {Color(red:0.83,green:0.94,blue:0.99)}
    private var accent:Color {Color(red:0.18,green:0.85,blue:0.91)}

    var body:some View {
        HStack(alignment:.bottom,spacing:compact ? 8:14) {
            VStack(alignment:.leading,spacing:compact ? 5:9) {
                HStack(spacing:compact ? 9:15) {
                    stat("PUNKTY",String(hud.score),color:.yellow)
                    stat("ŻYCIA",String(hud.lives),color:ink)
                    stat("TARCZE",String(hud.shieldCharges),color:accent)
                    stat("CZAS","\(Int(hud.seconds)) s",color:ink)
                }
                HStack(spacing:compact ? 8:12) {
                    meter("KADŁUB",value:hud.hull,maximum:60,tint:accent)
                    meter("PANCERZ",value:hud.armor,maximum:25,tint:.orange)
                }
                HStack(spacing:compact ? 8:15) {
                    stat("ASTEROIDY",String(hud.rocks),color:.orange)
                    stat("WROGOWIE",String(hud.fighters),color:.red)
                    stat("ŻETONY","\(hud.collectedTokens) (+\(hud.tokenPickups.count))",
                         color:.yellow)
                }
            }
            .padding(compact ? 8:13)
            .background(panel.opacity(0.89),in:RoundedRectangle(cornerRadius:9))
            .overlay(RoundedRectangle(cornerRadius:9).stroke(accent.opacity(0.35),
                                                             lineWidth:1))
            .frame(maxWidth:compact ? 425:580,alignment:.leading)

            Spacer(minLength:0)
            radar
        }
        .padding(.horizontal,compact ? 10:24)
        .padding(.bottom,compact ? 7:18)
        .accessibilityElement(children:.contain)
        .accessibilityIdentifier("sector01-source-data-mission-hud")
        .allowsHitTesting(false)
    }

    private func stat(_ caption:String,_ value:String,color:Color)->some View {
        VStack(alignment:.leading,spacing:2) {
            Text(caption)
                .font(.system(size:compact ? 8:10,weight:.semibold,design:.monospaced))
                .foregroundStyle(ink.opacity(0.75))
                .lineLimit(1)
            Text(value)
                .font(.system(size:compact ? 11:16,weight:.bold,design:.monospaced))
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .accessibilityElement(children:.combine)
    }

    private func meter(_ caption:String,value:Int,maximum:Int,tint:Color)->some View {
        let bounded=max(0,min(maximum,value))
        return VStack(alignment:.leading,spacing:3) {
            HStack(spacing:5) {
                Text(caption)
                Spacer(minLength:0)
                Text("\(value)/\(maximum)").monospacedDigit()
            }
            .font(.system(size:compact ? 8:10,weight:.bold,design:.monospaced))
            .foregroundStyle(ink)
            GeometryReader { g in
                ZStack(alignment:.leading) {
                    RoundedRectangle(cornerRadius:2).fill(.white.opacity(0.12))
                    RoundedRectangle(cornerRadius:2).fill(tint)
                        .frame(width:g.size.width * CGFloat(bounded)/CGFloat(maximum))
                }
            }
            .frame(height:compact ? 5:8)
        }
        .frame(maxWidth:compact ? 150:208)
        .accessibilityLabel("\(caption): \(value) z \(maximum)")
    }

    private var radar:some View {
        Canvas { context,size in
            let radius=min(size.width,size.height)*0.43
            let center=CGPoint(x:size.width/2,y:size.height/2)
            let circle=CGRect(x:center.x-radius,y:center.y-radius,
                              width:radius*2,height:radius*2)
            context.stroke(Path(ellipseIn:circle),with:.color(accent.opacity(0.7)),
                           lineWidth:1)
            var cross=Path()
            cross.move(to:CGPoint(x:center.x-radius,y:center.y))
            cross.addLine(to:CGPoint(x:center.x+radius,y:center.y))
            cross.move(to:CGPoint(x:center.x,y:center.y-radius))
            cross.addLine(to:CGPoint(x:center.x,y:center.y+radius))
            context.stroke(cross,with:.color(accent.opacity(0.20)),lineWidth:0.8)
            context.fill(Path(ellipseIn:CGRect(x:center.x-3,y:center.y-3,
                                                width:6,height:6)),
                         with:.color(.green))
            for p in hud.hazards {plot(p,color:.orange,diameter:3,
                                       center:center,radius:radius,context:context)}
            for p in hud.tokenPickups {plot(p,color:.yellow,diameter:5,
                                            center:center,radius:radius,context:context)}
            for p in hud.targets {plot(p,color:.red,diameter:6,
                                       center:center,radius:radius,context:context)}
        }
        .frame(width:compact ? 106:156,height:compact ? 106:156)
        .background(panel.opacity(0.89),in:RoundedRectangle(cornerRadius:9))
        .overlay(RoundedRectangle(cornerRadius:9).stroke(accent.opacity(0.4),
                                                         lineWidth:1))
        .accessibilityLabel("Radar: \(hud.targets.count) przeciwników, \(hud.hazards.count) asteroid w podglądzie, \(hud.tokenPickups.count) żetonów")
        .accessibilityIdentifier("sector01-live-enemy-radar")
    }

    private func plot(_ point:Vec2,color:Color,diameter:CGFloat,
                      center:CGPoint,radius:CGFloat,context:GraphicsContext) {
        // Same 400-unit range as the previous live radar; no fake targets.
        let x=center.x+CGFloat(point.x/400)*radius
        let y=center.y+CGFloat(point.y/400)*radius
        guard hypot(x-center.x,y-center.y)<=radius else{return}
        context.fill(Path(ellipseIn:CGRect(x:x-diameter/2,y:y-diameter/2,
                                           width:diameter,height:diameter)),
                     with:.color(color))
    }
}
