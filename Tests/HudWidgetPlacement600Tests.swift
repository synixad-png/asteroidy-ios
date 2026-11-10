import Foundation

/// Source-exact geometry verification, no screenshots or device access.
/// Windows HudLayout.HudWidget.ScreenLeft/ScreenTop center GLB scaling
/// at fixed unscaled F6 X/Y. UIKit safe areas and MTKView pixels must agree.
@main enum HudWidgetPlacement600Tests {
    static func check(_ condition:@autoclosure ()->Bool,_ why:String) {
        precondition(condition(),why)
    }
    static func near(_ a:Double,_ b:Double,_ why:String,epsilon:Double=0.002) {
        check(abs(a-b)<epsilon,why)
    }
    static func main() {
        let approved=HudLayout600.defaults()
        let desktop=CombatHUDViewport568(width:1280,height:720)
        let planet=approved.widget("hud.planetarium")!
        guard let source=HudWidgetPlacement600.frame(
            planet,sourceWidth:250,sourceHeight:135,
            anchor:.bottomLeft,viewport:desktop) else {
            preconditionFailure("original planetarium missing")
        }
        near(source.centerX,desktop.x(planet.x+125,at:.bottomLeft),
             "PC v600 original planetarium x-center independent of scaling")
        near(source.centerY,desktop.y(planet.y+67.5,at:.bottomLeft),
             "PC v600 original planetarium y-center independent of scaling")
        near(source.width,250*planet.scale*desktop.scale,
             "original frame width")
        near(source.height,135*planet.scale*desktop.scale,
             "original frame height")

        var edited=approved
        edited.change("hud.planetarium"){$0.scale=3}
        let enlarged=HudWidgetPlacement600.frame(
            edited.widget("hud.planetarium")!,
            sourceWidth:250,sourceHeight:135,
            anchor:.bottomLeft,viewport:desktop)!
        near(enlarged.centerX,source.centerX,
             "PC GLB scale changes width but never x-center")
        near(enlarged.centerY,source.centerY,
             "PC GLB scale changes height but never y-center")
        near(enlarged.width,250*3*desktop.scale,
             "original GLB threefold scale")

        let iphone=CombatHUDViewport568(width:1179,height:255,
            safeLeft:59,safeRight:59,safeTop:0,safeBottom:0)
        let icon=approved.widget("boost.icon")!
        let p=HudWidgetPlacement600.frame(icon,sourceWidth:50,sourceHeight:50,
            anchor:.bottomRight,viewport:iphone)!
        near(p.centerX,iphone.x(icon.x+25,at:.bottomRight),
             "right HUD uses notch-safe optical margin without letterboxing")
        near(p.centerY,iphone.y(icon.y+25,at:.bottomRight),
             "bottom HUD source y preserved")
        let pixels=HudWidgetPlacement600.pixels(p,viewport:iphone,
            drawableWidth:1768.5,drawableHeight:382.5)!
        near(pixels.centerX,p.centerX*1.5,"Metal adaptive draw pixels x")
        near(pixels.centerY,p.centerY*1.5,"Metal adaptive draw pixels y")
        let ipad=CombatHUDViewport568(width:1024,height:768,
            safeLeft:0,safeRight:0,safeTop:24,safeBottom:20)
        let iPadFrame=HudWidgetPlacement600.frame(icon,
            sourceWidth:50,sourceHeight:50,
            anchor:.bottomRight,viewport:ipad)!
        near(iPadFrame.centerX,ipad.x(icon.x+25,at:.bottomRight),
             "iPad 4:3 independent right HUD corner")
        near(iPadFrame.centerY,ipad.y(icon.y+25,at:.bottomRight),
             "iPad lower safe inset")

        var biggerIcon=approved
        biggerIcon.change("boost.icon"){$0.scale=2}
        let large=HudWidgetPlacement600.frame(biggerIcon.widget("boost.icon")!,
            sourceWidth:50,sourceHeight:50,
            anchor:.bottomRight,viewport:iphone)!
        near(large.centerX,p.centerX,"PC center anchored icon after scale")
        near(large.centerY,p.centerY,"PC center anchored icon after scale")
        near(large.width,2*p.width,"icon doubles pixel width only")
        check(HudWidgetPlacement600.pixels(p,viewport:iphone,
            drawableWidth:0,drawableHeight:255)==nil,
            "invalid zero drawable is rejected")
        print("PASS iOS v600 GLB: original PC centered scale, 19.5:9 safe screen, iPad 4:3, adaptive Metal pixel ratio")
    }
}
