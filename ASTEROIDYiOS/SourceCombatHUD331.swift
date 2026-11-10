import SwiftUI

/// Faithful native drawing of Windows/src/RendererW3Combat331.cs (v568).
/// Source virtual canvas: 1280 x 720, with source UiScale336 aspect fit.
/// No textures, panels, animations, timers, audio work or hit-test surfaces.
struct SourceCombatHUD331: View {
    let hud: CarbonisSession568.HUD
    let insets: W3ScreenInsets568
    let render3DIcons:Bool

    private static let white = color(234, 228, 232, 231)
    private static let dim = color(196, 155, 180, 190)
    private static let cyan = color(255, 65, 205, 212)
    private static let gold = color(255, 215, 164, 67)
    private static let blue = color(255, 66, 153, 221)

    static func color(_ a: Int, _ r: Int, _ g: Int, _ b: Int) -> Color {
        Color(.sRGB, red: Double(r)/255, green: Double(g)/255,
              blue: Double(b)/255, opacity: Double(a)/255)
    }
    private static func clamp(_ v:CGFloat)->CGFloat { max(0,min(1,v)) }

    var body: some View {
        Canvas(opaque:false, rendersAsynchronously:false) { context, size in
            let layout=CombatHUDViewport568(
                width:Double(size.width),height:Double(size.height),
                safeLeft:insets.left,safeRight:insets.right,
                safeTop:insets.top,safeBottom:insets.bottom)
            let scale=CGFloat(layout.scale)

            // Separate transforms prevent top / bottom and left / right
            // from drifting together when the screen is not 16:9.
            var topLeft=context
            topLeft.translateBy(
                x:CGFloat(layout.originX(for:.topLeft)),
                y:CGFloat(layout.originY(for:.topLeft)))
            topLeft.scaleBy(x:scale,y:scale)
            Self.applyMotion(&topLeft,pose:hud.motion,widget:"status.mode")

            var topRight=context
            topRight.translateBy(
                x:CGFloat(layout.originX(for:.topRight)),
                y:CGFloat(layout.originY(for:.topRight)))
            topRight.scaleBy(x:scale,y:scale)
            Self.applyMotion(&topRight,pose:hud.motion,widget:"status.sector")

            var bottomLeft=context
            bottomLeft.translateBy(
                x:CGFloat(layout.originX(for:.bottomLeft)),
                y:CGFloat(layout.originY(for:.bottomLeft)))
            bottomLeft.scaleBy(x:scale,y:scale)
            Self.applyMotion(&bottomLeft,pose:hud.motion,widget:"radar")

            var bottomRight=context
            bottomRight.translateBy(
                x:CGFloat(layout.originX(for:.bottomRight)),
                y:CGFloat(layout.originY(for:.bottomRight)))
            bottomRight.scaleBy(x:scale,y:scale)
            Self.applyMotion(&bottomRight,pose:hud.motion,widget:"ion.icon")

            Self.top(topLeft,topRight,hud)
            Self.radar(bottomLeft,hud)
            Self.gauge(bottomLeft,"KADŁUB",hud.hull,60,191,565,0,Double(hud.seconds))
            Self.gauge(bottomLeft,"PANCERZ",hud.armor,25,191,613,1,Double(hud.seconds))
            Self.gauge(bottomLeft,"TARCZA",hud.tarczaEnergy,100,191,661,2,Double(hud.seconds))
            let counts=[hud.ionAmmo,hud.bombs,hud.shieldCharges,hud.boostCharges]
            let names=["JON","BOMBY","OSŁONY","DOPALACZ"]
            let tints=[Self.cyan,Self.dim,Self.cyan,Self.gold]
            for i in 0..<4 {
                Self.ability(bottomRight,type:i,cx:CGFloat(920+100*i),
                             count:counts[i],name:names[i],tint:tints[i],
                             renderModel:render3DIcons)
            }
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity)
        .allowsHitTesting(false)
        .accessibilityElement(children:.ignore)
        .accessibilityLabel("Sektor 01. Punkty \(hud.score). Żetony \(hud.tokenBalance). Życia \(hud.lives). Kadłub \(hud.hull). Pancerz \(hud.armor).")
        .accessibilityIdentifier("sector01-source-w3-hud331")
    }

    // PC HudMotionPose.Apply: independent visual matrix per anchored group.
    // Gameplay reticle and screen-touch gesture zones are intentionally outside
    // this drawing context and never inherit decorative HUD movement.
    private static func applyMotion(_ context:inout GraphicsContext,
                                    pose:HudMotion600.Pose,widget:String) {
        let weight=CGFloat(pose.weight(widget))
        let dx=CGFloat(pose.x)*weight,dy=CGFloat(pose.y)*weight
        let rotation=Double(pose.roll*Float(weight))
        guard dx != 0 || dy != 0 || rotation != 0 else {return}
        context.translateBy(x:dx,y:dy)
        context.translateBy(x:640,y:360)
        context.rotate(by:.degrees(rotation))
        context.translateBy(x:-640,y:-360)
    }

    private static func line(_ c:GraphicsContext,_ x0:CGFloat,_ y0:CGFloat,
                             _ x1:CGFloat,_ y1:CGFloat,_ col:Color,_ width:CGFloat) {
        var p=Path()
        p.move(to:CGPoint(x:x0,y:y0))
        p.addLine(to:CGPoint(x:x1,y:y1))
        c.stroke(p,with:.color(col),lineWidth:width)
    }
    private static func polygon(_ points:[CGPoint])->Path {
        var p=Path()
        if let first=points.first {
            p.move(to:first)
            for pt in points.dropFirst() {p.addLine(to:pt)}
            p.closeSubpath()
        }
        return p
    }
    private static func arc(_ c:GraphicsContext,_ cx:CGFloat,_ cy:CGFloat,
                            _ radius:CGFloat,_ start:CGFloat,_ sweep:CGFloat,
                            _ color:Color,_ width:CGFloat) {
        var p=Path()
        p.addArc(center:CGPoint(x:cx,y:cy),radius:radius,
                 startAngle:.degrees(Double(start)),
                 endAngle:.degrees(Double(start+sweep)),clockwise:false)
        c.stroke(p,with:.color(color),lineWidth:width)
    }
    private static func circle(_ c:GraphicsContext,_ cx:CGFloat,_ cy:CGFloat,
                               _ r:CGFloat,_ col:Color) {
        c.fill(Path(ellipseIn:CGRect(x:cx-r,y:cy-r,width:r*2,height:r*2)),
               with:.color(col))
    }
    private static func text(_ c:GraphicsContext,_ s:String,
                             _ x:CGFloat,_ y:CGFloat,_ col:Color,
                             right:Bool=false,center:Bool=false) {
        let resolved=c.resolve(Text(s).font(.system(size:14,weight:.regular))
                                    .foregroundColor(col))
        c.draw(resolved,at:CGPoint(x:x,y:y),
               anchor:center ? .top : (right ? .topTrailing : .topLeading))
    }
    private static func label(_ c:GraphicsContext,_ s:String,
                              _ x:CGFloat,_ y:CGFloat,_ col:Color) {
        // Windows Hud331Label uses one dark-offset copy for readability.
        text(c,s,x+1,y+1,color(200,1,7,11))
        text(c,s,x,y,col)
    }
    private static func top(_ c:GraphicsContext,_ right:GraphicsContext,
                            _ hud:CarbonisSession568.HUD) {
        line(c,20,17,20,81,color(190,215,164,67),1.5)
        label(c,"SYNIXAD / WALKA 3D",34,17,white)
        label(c,"BROŃ: \(hud.weaponName)  ·  POZIOM \(hud.weaponLevel)  ·  TEMPO \(hud.rapidLevel)",
              34,42,cyan)
        label(right,"SEKTOR 01 / 26",777,17,white)
        label(right,"PKT \(hud.score)",936,17,cyan)
        label(right,"ŻETONY \(hud.tokenBalance)",1050,17,gold)
        label(right,"ŻYCIA \(hud.lives)",1195,17,white)
        line(right,776,46,1262,46,color(67,109,145,156),0.8)
    }
    // PC v600 screen-space gauge. Uses the real HUD snapshot and source
    // turbulence; no square segments, no images and no game-state writes.
    private static func gauge(_ c:GraphicsContext,_ name:String,_ current:Int?,
                              _ maximum:Int,_ x:CGFloat,_ y:CGFloat,
                              _ style:Int,_ time:Double) {
        label(c,name,x,y,dim)
        let value=max(0,current ?? 0)
        let width:Double=148
        let fraction=HudEnergy600.fraction(current,maximum:maximum)
        let left=Double(x)+1
        let baseY=Double(y)+19
        let guide=polygon([
            CGPoint(x:left,y:baseY),
            CGPoint(x:left+width,y:baseY),
            CGPoint(x:left+width-2,y:baseY+9),
            CGPoint(x:left,y:baseY+9)
        ])
        c.fill(guide,with:.color(color(160,8,22,31)))
        if fraction>0 {
            let length=(width-2)*fraction
            let palette:[[Color]]=[
                [color(18,255,32,23),color(46,255,41,24),
                 color(128,231,20,11),color(210,255,60,31),color(235,255,205,150)],
                [color(20,255,93,6),color(53,255,124,17),
                 color(140,238,103,5),color(223,255,178,38),color(242,255,237,166)],
                [color(18,37,255,50),color(49,55,252,56),
                 color(129,16,205,47),color(212,104,255,72),color(236,228,255,187)]
            ]
            for layer in 0..<5 {
                let vertices=HudEnergy600.ribbon(
                    x:left,y:baseY,width:width-2,length:length,
                    time:time,style:style,layer:layer)
                let points=vertices.map{CGPoint(x:$0.x,y:$0.y)}
                c.fill(polygon(points),with:.color(palette[style][layer]))
            }
            // Independent flame tongues trace the irregular edges.
            for k in 0..<7 {
                let drift = (Double(k) * 0.61803398875
                    + time * (0.072 + 0.011 * Double(k % 3))
                    + Double(style) * 0.17).truncatingRemainder(dividingBy: 1)
                let local=drift*length
                if length-local<3.5 {continue}
                let xx=left+local
                let turbulence=abs(HudEnergy600.wave(local/(width-2),
                    time:time,seed:Double(style)+Double(k)*0.89))
                let reach=2.5+5.3*turbulence
                let upper=k%2==0
                let edge=baseY+(upper ? -0.3:9.3)
                let tip=edge+(upper ? -reach:reach)
                c.fill(polygon([
                    CGPoint(x:xx-1.6,y:edge),
                    CGPoint(x:xx+0.8,y:tip),
                    CGPoint(x:xx+4.4,y:edge+(upper ? 0.4 : -0.4))
                ]),with:.color(palette[style][2]))
            }
        }
        text(c,current.map{String(max(0,$0))} ?? "—",x+183,y+2,white,right:true)
    }
    private static func radarDot(_ c:GraphicsContext,_ center:CGPoint,
                                 _ contact:CarbonisSession568.HUD.RadarContact) {
        let radius:CGFloat=69
        var dx=CGFloat(contact.x)*61,dy=CGFloat(contact.y)*61
        let d=hypot(dx,dy)
        if d>radius-7 && d>0.00001 {
            dx*=((radius-7)/d)
            dy*=((radius-7)/d)
        }
        let x=center.x+dx,y=center.y+dy
        let dot:CGFloat=contact.kind==0 ? 1.7 : contact.kind==1 ? 2.3 : 1.6
        let tint=contact.kind==0 ? gold : contact.kind==1
            ? color(255,228,116,94) : color(255,113,216,179)
        circle(c,x,y,dot+1,color(150,3,11,17))
        circle(c,x,y,dot,tint)
    }
    private static func radar(_ c:GraphicsContext,_ hud:CarbonisSession568.HUD) {
        let cx:CGFloat=91,cy:CGFloat=612,r:CGFloat=69
        arc(c,cx,cy+1.8,r+4,0,360,color(130,3,12,19),3.2)
        arc(c,cx,cy,r+3,128,234,color(148,134,162,171),1.7)
        arc(c,cx,cy,r+3,-52,128,color(180,27,167,186),1.9)
        arc(c,cx,cy,r-2,0,360,color(117,19,121,141),0.9)
        arc(c,cx,cy,r-24,0,360,color(78,17,111,128),0.85)
        arc(c,cx,cy,r-42,0,360,color(48,18,106,122),0.7)
        for i in 0..<32 {
            let angle=CGFloat(i) * CGFloat.pi / 16
            let length:CGFloat=i%8==0 ? 7 : i%4==0 ? 4 : 2
            let x0=cx+CGFloat(cos(Double(angle)))*(r-2), y0=cy+CGFloat(sin(Double(angle)))*(r-2)
            let x1=cx+CGFloat(cos(Double(angle)))*(r-2-length), y1=cy+CGFloat(sin(Double(angle)))*(r-2-length)
            line(c,x0,y0,x1,y1,i%8==0 ? color(191,72,192,205)
                 :color(77,62,127,140),i%8==0 ? 1.2:0.7)
        }
        line(c,cx-(r-8),cy,cx+(r-8),cy,color(30,28,104,116),0.7)
        line(c,cx,cy-(r-8),cx,cy+(r-8),color(30,28,104,116),0.7)
        let center=CGPoint(x:cx,y:cy)
        for contact in hud.radarContacts {radarDot(c,center,contact)}
        c.fill(polygon([CGPoint(x:cx,y:cy-14),CGPoint(x:cx-11,y:cy+10),
                        CGPoint(x:cx,y:cy+5),CGPoint(x:cx+11,y:cy+10)]),
               with:.color(color(170,1,15,21)))
        c.fill(polygon([CGPoint(x:cx,y:cy-13),CGPoint(x:cx-8,y:cy+8),
                        CGPoint(x:cx,y:cy+3),CGPoint(x:cx+8,y:cy+8)]),
               with:.color(cyan))
        label(c,"N",cx-4,cy-r-22,cyan)
        label(c,"S",cx-4,cy+r+4,cyan)
        label(c,"W",cx-r-18,cy-9,cyan)
        label(c,"E",cx+r+8,cy-9,cyan)
    }
    private static func badge(_ c:GraphicsContext,_ type:Int,_ x:CGFloat,
                              _ y:CGFloat,_ tint:Color,_ progress:CGFloat) {
        let r:CGFloat=20
        arc(c,x,y+1,r+2,0,360,color(136,0,6,12),3)
        arc(c,x,y,r+1,125,212,color(164,92,132,144),1.3)
        arc(c,x,y,r,0,360,color(152,23,54,64),2.7)
        arc(c,x,y,r,-91,360*clamp(progress),tint,2.8)
        if type==0 {
            c.fill(polygon([CGPoint(x:x+1,y:y-11),CGPoint(x:x-7,y:y+1),
                            CGPoint(x:x-1,y:y+1),CGPoint(x:x-4,y:y+11),
                            CGPoint(x:x+8,y:y-3),CGPoint(x:x+2,y:y-3)]),
                   with:.color(white))
        } else if type==1 {
            c.stroke(Path(ellipseIn:CGRect(x:x-6,y:y-3,width:12,height:12)),
                     with:.color(white),lineWidth:1.6)
            line(c,x+1,y-5,x+4,y-9,white,1.7)
            line(c,x-2,y-8,x+1,y-8,white,1.5)
        } else if type==2 {
            let shield=polygon([CGPoint(x:x,y:y-11),CGPoint(x:x+10,y:y-7),
                                CGPoint(x:x+8,y:y+5),CGPoint(x:x,y:y+12),
                                CGPoint(x:x-8,y:y+5),CGPoint(x:x-10,y:y-7)])
            c.fill(shield,with:.color(color(165,116,181,194)))
            c.stroke(shield,with:.color(white),lineWidth:1.2)
        } else {
            c.fill(polygon([CGPoint(x:x-6,y:y+9),CGPoint(x:x-5,y:y),
                            CGPoint(x:x-2,y:y-6),CGPoint(x:x+1,y:y-11),
                            CGPoint(x:x+6,y:y-2),CGPoint(x:x+7,y:y+9)]),
                   with:.color(white))
            c.fill(polygon([CGPoint(x:x-2,y:y+8),CGPoint(x:x,y:y-2),
                            CGPoint(x:x+3,y:y+8)]),with:.color(tint))
        }
    }
    private static func ability(_ c:GraphicsContext,type:Int,cx:CGFloat,
                                count:Int,name:String,tint:Color,
                                renderModel:Bool) {
        let progress:CGFloat = type<2 ? (count>0 ? 0.7:0)
            : clamp(CGFloat(count)/3)
        if !renderModel {badge(c,type,cx,628,tint,progress)}
        text(c,name,cx,658,white,center:true)
        text(c,type>=2 ? "\(count) / 3" : "\(count)",cx,680,cyan,center:true)
    }
}
