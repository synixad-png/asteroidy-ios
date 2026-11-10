import Foundation

@main enum HudEditorGeometryTests {
    static func verify(_ condition:@autoclosure ()->Bool,_ label:String) {
        precondition(condition(),label)
    }
    static func main() {
        let source=HudLayout600.defaults()
        let flat=CombatHUDViewport568(width:1280,height:720)
        verify(source.widgets.count==46,"PC602 must expose all 46 widgets")
        for widget in source.widgets {
            guard let rect=HudEditorGeometry.rect(widget,viewport:flat) else {
                preconditionFailure("missing original rectangle: "+widget.id)
            }
            verify(rect.width>0 && rect.height>0 && rect.area.isFinite,
                   "all original hit regions must be finite")
        }
        let radar=source.widget("radar")!
        let radarRect=HudEditorGeometry.rect(radar,viewport:flat)!
        verify(HudEditorGeometry.hit(x:radarRect.x+30,y:radarRect.y+50,
                                     layout:source,viewport:flat)=="radar",
               "smallest visible widget wins over overlapping planetarium")
        let planet=source.widget("hud.planetarium")!
        let globe=HudEditorGeometry.rect(planet,viewport:flat)!
        verify(abs(globe.x-(planet.x+(250-250*planet.scale)*0.5 + flat.originX(for:.bottomLeft)))<0.00001,
               "GLB scaled about immutable PC widget centre")
        verify(HudEditorGeometry.hit(x:210,y:550,layout:source,
                                     viewport:flat)=="hud.planetarium",
               "planetarium independently selectable outside radar")
        verify(HudEditorGeometry.hit(x:650,y:450,layout:source,
                                     viewport:flat)==nil,
               "a blank canvas clears selection")
        var draft=source
        HudEditorGeometry.move("hud.planetarium",from:planet,
                               deltaX:19,deltaY:-13,viewport:flat,in:&draft)
        verify(draft.widget("hud.planetarium")!.x==planet.x+19 &&
               draft.widget("hud.planetarium")!.y==planet.y-13,
               "drag affects only selected GLB widget")
        verify(draft.widget("radar")==radar,"drag must not move radar")
        HudEditorGeometry.zoom("hud.planetarium",originalScale:planet.scale,
                               factor:100,in:&draft)
        verify(draft.widget("hud.planetarium")!.scale==6,
               "scale clamped to source 3D range")
        var hidden=source
        hidden.change("radar"){$0.visible=false}
        verify(HudEditorGeometry.hit(x:radarRect.x+30,y:radarRect.y+50,
                                     layout:hidden,viewport:flat) != "radar",
               "hidden widgets cannot steal touch selection")
        for (width,height,left,right,top,bottom) in [
            (956.0,440.0,60.0,0.0,0.0,21.0),
            (1024.0,768.0,0.0,0.0,0.0,20.0)
        ] {
            let vp=CombatHUDViewport568(width:width,height:height,
                                        safeLeft:left,safeRight:right,
                                        safeTop:top,safeBottom:bottom)
            let r=HudEditorGeometry.rect(planet,viewport:vp)!
            verify(HudEditorGeometry.hit(x:r.x+r.width*0.75,y:r.y+r.height*0.3,
                                         layout:source,viewport:vp) != nil,
                   "layout hit test uses actual UIKit screen coordinates")
            verify(abs((r.x+r.width/2)-vp.x(planet.x+125,at:.bottomLeft))<0.001,
                   "planetarium never acquires mission/world camera coordinates")
        }
        print("PASS PC602 HUD editor: 46 widgets, overlap precedence, source drag, zoom, screen anchors")
    }
}
