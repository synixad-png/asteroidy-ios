import Foundation
import SwiftUI

/// Original Windows RendererHudEnergy.cs animated meters, in a SECOND
/// canvas only: heavy sector/radar/score text continues its existing 10 Hz
/// publication cadence. Plasma geometry and visual HUD motion update at
/// the display cadence, as they do in the PC OpenGL renderer.
/// No new gameplay state, texture copies or per-frame file access.
struct HudPlasmaLayer600:View {
    let hull:Int
    let armor:Int
    let maxHull:Int
    let maxArmor:Int
    let shield:Int?
    let insets:W3ScreenInsets568
    let layout:HudLayout600
    let active:Bool
    let livePose:()->HudMotion600.Pose
    let liveTime:()->Double

    private static let names=["hull.bar","armor.bar","shield.bar"]
    // Literal ARGB from RendererHudEnergy.cs.GaugeTint.
    private static let tints:[[Color]]=[
        [ink(18,255,32,23),ink(46,255,41,24),ink(128,231,20,11),
         ink(210,255,60,31),ink(235,255,205,150)],
        [ink(20,255,93,6),ink(53,255,124,17),ink(140,238,103,5),
         ink(223,255,178,38),ink(242,255,237,166)],
        [ink(18,37,255,50),ink(49,55,252,56),ink(129,16,205,47),
         ink(212,104,255,72),ink(236,228,255,187)]
    ]
    // PC DrawEnergyGauge uses explicit alpha=90, not premultiplication
    // of the layer-4 alpha (235/242/236) by another opacity.
    private static let terminals:[Color]=[
        ink(90,255,205,150),ink(90,255,237,166),ink(90,228,255,187)
    ]
    private static func ink(_ a:Int,_ r:Int,_ g:Int,_ b:Int)->Color {
        SourceCombatHUD331.color(a,r,g,b)
    }
    private static func shape(_ points:[CGPoint])->Path {
        var path=Path()
        if let first=points.first {
            path.move(to:first)
            for point in points.dropFirst(){path.addLine(to:point)}
            path.closeSubpath()
        }
        return path
    }

    var body:some View {
        TimelineView(.animation(minimumInterval:1.0/60.0,paused:!active)) { timeline in
            Canvas(opaque:false,rendersAsynchronously:false) { graphics,size in
                let screen=CombatHUDViewport568(
                    width:Double(size.width),height:Double(size.height),
                    safeLeft:insets.left,safeRight:insets.right,
                    safeTop:insets.top,safeBottom:insets.bottom)
                let pose=livePose()
                var bottom=graphics
                bottom.translateBy(x:CGFloat(screen.originX(for:.bottomLeft)),
                                   y:CGFloat(screen.originY(for:.bottomLeft)))
                bottom.scaleBy(x:CGFloat(screen.scale),y:CGFloat(screen.scale))
                // Windows RendererHudEnergy samples Game.Elapsed.
                // Unlike wall time this freezes on PAUZA, so the original
                // flow resumes smoothly without jumping to a new phase.
                let time=liveTime().truncatingRemainder(dividingBy:3600)
                let values:[Int?]=[hull,armor,shield]
                let maxima=[maxHull,maxArmor,100]
                for i in 0..<3 {
                    let y=CGFloat(565+48*i)
                    guard let bar=SourceCombatHUD331.widgetContext(
                        bottom,layout,pose:pose,id:Self.names[i],
                        baseX:191,baseY:y+19) else{continue}
                    Self.draw(bar,current:values[i],maximum:maxima[i],
                              x:191,y:y+19,style:i,time:time)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity)
        .allowsHitTesting(false)
        .accessibilityIdentifier("sector01-hud-v600-plasma-animated")
    }

    /// Exact 5 ribbons, 7 irregular external licks and a terminal flare.
    /// The dark guide and both rails are in SourceCombatHUD331, so they
    /// are not redrawn at 60 Hz. No guessing at game resource values.
    private static func draw(_ c:GraphicsContext,current:Int?,maximum:Int,
                             x:CGFloat,y:CGFloat,style:Int,time:Double) {
        let fraction=HudEnergy600.fraction(current,maximum:maximum)
        let width=148.0
        let left=Double(x)+1
        let barY=Double(y)
        let length=(width-2)*fraction
        guard length>=0.05 else{return}
        for layer in 0..<5 {
            let vertices=HudEnergy600.ribbon(
                x:left,y:barY,width:width-2,length:length,
                time:time,style:style,layer:layer)
            guard !vertices.isEmpty else{continue}
            let points=vertices.map{CGPoint(x:$0.x,y:$0.y)}
            c.fill(shape(points),with:.color(tints[style][layer]))
        }
        // Source has no regular particle grid; these independent flame
        // tongues have quasi-periodic, non-axial drift on both edges.
        for k in 0..<7 {
            let driftBase=Double(k)*0.61803398875
            let driftRate=time*(0.072+0.011*Double(k%3))
            let drift=(driftBase+driftRate+Double(style)*0.17)
                .truncatingRemainder(dividingBy:1)
            let local=drift*length
            if length-local<3.5 {continue}
            let xx=left+local
            let turbulence=abs(HudEnergy600.wave(local/(width-2),
                time:time,seed:Double(style)+Double(k)*0.89))
            let reach=2.5+5.3*turbulence
            let upper=k%2==0
            let edge=barY+(upper ? -0.3:9.3)
            let tip=edge+(upper ? -reach:reach)
            c.fill(shape([
                CGPoint(x:xx-1.6,y:edge),
                CGPoint(x:xx+0.8,y:tip),
                CGPoint(x:xx+4.4,y:edge+(upper ? 0.4:-0.4))
            ]),with:.color(tints[style][2]))
        }
        // PC RendererHudEnergy.cs: 2.8 x 3.2 alpha-90 terminal.
        let end=left+length
        c.fill(Path(ellipseIn:CGRect(x:end-1.65,y:barY+2.9,
                                     width:2.8,height:3.2)),
               with:.color(terminals[style]))
    }
}
