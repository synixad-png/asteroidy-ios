import Foundation

/// Shared placement for real GLB HUD widgets. The approved PC v600 x/y
/// coordinates describe the TOP-LEFT edge of the unscaled widget; scaling
/// extends its width and height to the right and bottom. This preserves the
/// same positioning semantics in SwiftUI, SceneKit and the Metal drawable.
/// Never assume drawable pixels equal UIKit points (adaptive iPhone GPU scale).
enum HudWidgetPlacement600 {
    struct Frame:Equatable {
        let centerX:Double
        let centerY:Double
        let width:Double
        let height:Double
    }

    static func frame(_ widget:HudLayout600.Widget,
                      sourceWidth:Double,sourceHeight:Double,
                      anchor:CombatHUDViewport568.Anchor,
                      viewport:CombatHUDViewport568)->Frame? {
        guard widget.x.isFinite,widget.y.isFinite,widget.scale.isFinite,
              widget.scale>0,sourceWidth>0,sourceHeight>0,
              sourceWidth.isFinite,sourceHeight.isFinite else{return nil}
        let width=sourceWidth*widget.scale*viewport.scale
        let height=sourceHeight*widget.scale*viewport.scale
        let cx=viewport.x(widget.x+sourceWidth*widget.scale/2,at:anchor)
        let cy=viewport.y(widget.y+sourceHeight*widget.scale/2,at:anchor)
        guard width.isFinite,height.isFinite,cx.isFinite,cy.isFinite
        else{return nil}
        return Frame(centerX:cx,centerY:cy,width:width,height:height)
    }

    /// Logical UIKit screen points -> physical/adaptively downscaled MTKView
    /// drawable. The renderer may halve drawable dimensions to protect FPS.
    static func pixels(_ placement:Frame,viewport:CombatHUDViewport568,
                       drawableWidth:Double,drawableHeight:Double)->Frame? {
        guard drawableWidth.isFinite,drawableHeight.isFinite,
              drawableWidth>0,drawableHeight>0 else{return nil}
        let sx=drawableWidth/viewport.width
        let sy=drawableHeight/viewport.height
        return Frame(centerX:placement.centerX*sx,centerY:placement.centerY*sy,
                     width:placement.width*sx,height:placement.height*sy)
    }
}
