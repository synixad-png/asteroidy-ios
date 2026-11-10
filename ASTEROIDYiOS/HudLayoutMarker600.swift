import SwiftUI

/// Passive PC v602 F6 widget outlines. The parent HUD editor owns ONE
/// shared hit-test/drag/pinch surface so overlapping SwiftUI marker views
/// cannot intercept touches outside their small source-space rectangles.
struct HudLayoutMarker600:View {
    let widget:HudLayout600.Widget
    let scale:Double
    let offsetX:Double
    let offsetY:Double
    let sourceWidth:Double
    let sourceHeight:Double
    let selected:Bool

    private var width:CGFloat {
        CGFloat(max(9,sourceWidth*widget.scale*scale))
    }
    private var height:CGFloat {
        CGFloat(max(7,sourceHeight*widget.scale*scale))
    }
    private var centerX:CGFloat {
        CGFloat(offsetX+(widget.x+sourceWidth*(widget.is3D ? 0.5 : widget.scale*0.5))*scale)
    }
    private var centerY:CGFloat {
        CGFloat(offsetY+(widget.y+sourceHeight*(widget.is3D ? 0.5 : widget.scale*0.5))*scale)
    }
    private var outline:Color {
        selected ? .yellow : widget.visible ? .cyan.opacity(0.5):.gray.opacity(0.4)
    }
    private var fill:Color {
        selected ? .yellow.opacity(0.12):.cyan.opacity(0.025)
    }
    var body:some View {
        Rectangle()
            .fill(fill)
            .overlay {Rectangle().stroke(outline,lineWidth:selected ? 2:0.7)}
            .frame(width:width,height:height)
            .overlay(alignment:.topLeading) {
                if selected {
                    Text(widget.id)
                        .font(.system(size:10,design:.monospaced))
                        .foregroundStyle(.yellow)
                        .fixedSize()
                        .offset(y:-14)
                }
            }
            .position(x:centerX,y:centerY)
            .allowsHitTesting(false)
            .accessibilityLabel(widget.id)
            .accessibilityIdentifier("hud-v600-widget-"+widget.id)
    }
}
