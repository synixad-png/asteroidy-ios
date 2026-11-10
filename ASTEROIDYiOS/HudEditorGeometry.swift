import Foundation

/// Single source-space hit test for the real 46-widget HUD.
/// Based on PC v602 Windows/src/HudLayout.cs: ScreenLeft/ScreenTop,
/// SelectAt (smallest visible area wins, reverse order on ties),
/// and StartDrag/Drag (source 1280x720, 12px kept on screen).
enum HudEditorGeometry {
    struct Rect:Equatable {
        let x:Double
        let y:Double
        let width:Double
        let height:Double

        func contains(_ x:Double,_ y:Double)->Bool {
            x>=self.x && x<=self.x+width &&
            y>=self.y && y<=self.y+height
        }
        var area:Double {width*height}
    }

    static func anchor(_ id:String)->CombatHUDViewport568.Anchor {
        if ["status.sector","status.score","status.money","status.lives"].contains(id)
            || id.hasPrefix("coop.") {return .topRight}
        if id=="radar" || id=="hud.planetarium" ||
            id.hasPrefix("hull.") || id.hasPrefix("armor.") ||
            id.hasPrefix("shield.") {return .bottomLeft}
        if ["ion.","bomb.","shield_charge.","boost."].contains(where:id.hasPrefix) {
            return .bottomRight
        }
        return .topLeft
    }

    static func rect(_ widget:HudLayout600.Widget,
                     viewport:CombatHUDViewport568)->Rect? {
        guard let size=HudWidgetGeometry600.size(widget.id),
              widget.scale.isFinite && widget.scale>0,
              viewport.scale.isFinite && viewport.scale>0 else{return nil}
        // The original PC HUD keeps X/Y fixed on scaling a 2D widget,
        // but scales GLB about the source rectangle's center.
        let x=widget.x+(widget.is3D ? (size.width-size.width*widget.scale)*0.5 : 0)
        let y=widget.y+(widget.is3D ? (size.height-size.height*widget.scale)*0.5 : 0)
        let anchor=anchor(widget.id)
        return Rect(x:viewport.x(x,at:anchor),
                    y:viewport.y(y,at:anchor),
                    width:size.width*widget.scale*viewport.scale,
                    height:size.height*widget.scale*viewport.scale)
    }

    static func hit(x:Double,y:Double,layout:HudLayout600,
                    viewport:CombatHUDViewport568)->String? {
        var chosen:String?
        var smallest=Double.infinity
        for widget in layout.widgets.reversed() where widget.visible {
            guard let bounds=rect(widget,viewport:viewport),
                  bounds.contains(x,y) else{continue}
            if bounds.area<smallest {
                smallest=bounds.area
                chosen=widget.id
            }
        }
        return chosen
    }

    static func move(_ id:String,from original:HudLayout600.Widget,
                     deltaX:Double,deltaY:Double,
                     viewport:CombatHUDViewport568,
                     in layout:inout HudLayout600) {
        guard original.id==id,viewport.scale>0,
              deltaX.isFinite,deltaY.isFinite,
              let xr=HudWidgetGeometry600.xRange(for:original),
              let yr=HudWidgetGeometry600.yRange(for:original) else{return}
        let x=min(xr.upperBound,max(xr.lowerBound,
                                   original.x+deltaX/viewport.scale))
        let y=min(yr.upperBound,max(yr.lowerBound,
                                   original.y+deltaY/viewport.scale))
        layout.change(id){widget in
            widget.x=x
            widget.y=y
        }
    }

    static func zoom(_ id:String,originalScale:Double,factor:Double,
                     in layout:inout HudLayout600) {
        guard let original=layout.widget(id),
              originalScale.isFinite,originalScale>0,
              factor.isFinite,factor>0 else{return}
        let range=HudWidgetGeometry600.scaleRange(for:original)
        layout.change(id){widget in
            widget.scale=min(range.upperBound,max(range.lowerBound,
                                                 originalScale*factor))
        }
    }
}
