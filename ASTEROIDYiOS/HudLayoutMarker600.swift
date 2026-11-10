import SwiftUI

/// One isolated SwiftUI element per approved PC v600 HUD widget.
/// Keeping the 46 drag views small avoids enormous ViewBuilder type graphs.
struct HudLayoutMarker600:View {
    let widget:HudLayout600.Widget
    let scale:Double
    let offsetX:Double
    let offsetY:Double
    let sourceWidth:Double
    let sourceHeight:Double
    @Binding var selected:String
    let onMove:(Double,Double)->Void

    @State private var startPoint:(Double,Double)?

    private var width:CGFloat {
        CGFloat(max(9,sourceWidth*widget.scale*scale))
    }
    private var height:CGFloat {
        CGFloat(max(7,sourceHeight*widget.scale*scale))
    }
    private var centerX:CGFloat {
        CGFloat(offsetX+(widget.x+sourceWidth*widget.scale*0.5)*scale)
    }
    private var centerY:CGFloat {
        CGFloat(offsetY+(widget.y+sourceHeight*widget.scale*0.5)*scale)
    }
    private var isSelected:Bool {selected==widget.id}
    private var outline:Color {
        if isSelected {return .yellow}
        return widget.visible ? .cyan.opacity(0.5):.gray.opacity(0.4)
    }
    private var fill:Color {
        isSelected ? .yellow.opacity(0.12):.cyan.opacity(0.025)
    }

    var body:some View {
        Rectangle()
            .fill(fill)
            .overlay {Rectangle().stroke(outline,lineWidth:isSelected ? 2:0.7)}
            .frame(width:width,height:height)
            .overlay(alignment:.topLeading) {
                if isSelected {
                    Text(widget.id)
                        .font(.system(size:10,design:.monospaced))
                        .foregroundStyle(.yellow)
                        .fixedSize()
                        .offset(y:-14)
                }
            }
            .position(x:centerX,y:centerY)
            .contentShape(Rectangle())
            .onTapGesture {selected=widget.id}
            .gesture(DragGesture(minimumDistance:1)
                .onChanged {gesture in
                    if selected != widget.id {selected=widget.id}
                    if startPoint == nil {startPoint=(widget.x,widget.y)}
                    guard let start=startPoint,scale>0 else{return}
                    let newX=start.0+Double(gesture.translation.width)/scale
                    let newY=start.1+Double(gesture.translation.height)/scale
                    onMove(newX,newY)
                }
                .onEnded {_ in startPoint=nil})
            .accessibilityLabel(widget.id)
            .accessibilityIdentifier("hud-v600-widget-"+widget.id)
    }
}
