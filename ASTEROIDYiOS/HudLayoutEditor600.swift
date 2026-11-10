import SwiftUI

/// Touch alternative to PC F6. Edits ALL 46 approved source widgets.
/// Paused mission owns this view; input zones and physics are never touched.
struct HudLayoutEditor600:View {
    @Environment(\.dismiss) private var dismiss
    @State private var document=HudLayout600.load()
    @State private var selected="hud.planetarium"
    @State private var dragOrigin:(Double,Double)?
    let onSave:(HudLayout600)->Void

    private var selectedWidget:HudLayout600.Widget? {document.widget(selected)}
    private var selection:Binding<String> {
        Binding(get:{selected},set:{selected=$0})
    }
    private func mutate(_ edit:@escaping (inout HudLayout600.Widget)->Void) {
        document.change(selected,edit)
    }
    private func number(_ title:String,_ key:WritableKeyPath<HudLayout600.Widget,Double>,
                        bounds:ClosedRange<Double>,step:Double)->some View {
        VStack(alignment:.leading,spacing:2) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format:"%.2f",selectedWidget?[keyPath:key] ?? 0))
                    .monospacedDigit()
            }
            Slider(value:Binding(
                get:{selectedWidget?[keyPath:key] ?? 0},
                set:{newValue in mutate{$0[keyPath:key]=newValue}}
            ),in:bounds,step:step).tint(.cyan)
        }
        .font(.system(size:11,design:.monospaced))
    }
    private func axis(_ title:String,_ key:WritableKeyPath<HudLayout600.Widget,Double?>)->some View {
        VStack(alignment:.leading,spacing:2) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format:"%.0f°",selectedWidget?[keyPath:key] ?? 0))
                    .monospacedDigit()
            }
            Slider(value:Binding(
                get:{selectedWidget?[keyPath:key] ?? 0},
                set:{newValue in mutate{$0[keyPath:key]=newValue}}
            ),in:-180...180,step:1).tint(.cyan)
        }.font(.system(size:11,design:.monospaced))
    }
    private func widgetSize(_ id:String)->(Double,Double) {
        switch id {
        case "radar":return (178,192)
        case "hud.planetarium":return (250,135)
        case "status.frame":return (1242,65)
        case "status.weapon":return (550,24)
        case "boss.panel":return (545,105)
        default:
            if id.hasSuffix(".bar"){return (148,12)}
            if id.hasSuffix(".icon"){return (50,50)}
            return (100,24)
        }
    }
    private func visual(_ bounds:CGSize)->some View {
        let scale=min(Double(bounds.width)/1280,Double(bounds.height)/720)
        let offsetX=(Double(bounds.width)-1280*scale)/2
        let offsetY=(Double(bounds.height)-720*scale)/2
        return ZStack(alignment:.topLeading) {
            Rectangle().fill(Color(red:0.012,green:0.026,blue:0.045))
            ForEach(document.widgets){widget in
                let dims=widgetSize(widget.id)
                let chosen=widget.id==selected
                let w=max(9,dims.0*widget.scale*scale)
                let h=max(7,dims.1*widget.scale*scale)
                let x=offsetX+widget.x*scale
                let y=offsetY+widget.y*scale
                Rectangle()
                    .fill(chosen ? Color.yellow.opacity(0.12):Color.cyan.opacity(0.025))
                    .overlay {
                        Rectangle().stroke(
                            chosen ? Color.yellow :
                                (widget.visible ? Color.cyan.opacity(0.5):
                                 Color.gray.opacity(0.4)),
                            lineWidth:chosen ? 2:0.7)
                    }
                    .frame(width:CGFloat(w),height:CGFloat(h))
                    .overlay(alignment:.topLeading) {
                        if chosen {
                            Text(widget.id)
                                .font(.system(size:10,design:.monospaced))
                                .foregroundStyle(.yellow)
                                .fixedSize()
                                .offset(y:-14)
                        }
                    }
                    .position(x:CGFloat(x+w/2),y:CGFloat(y+h/2))
                    .contentShape(Rectangle())
                    .onTapGesture {selected=widget.id}
                    .gesture(DragGesture(minimumDistance:1)
                        .onChanged {gesture in
                            if selected != widget.id {
                                selected=widget.id
                                dragOrigin=(widget.x,widget.y)
                            }
                            if dragOrigin==nil {
                                dragOrigin=(widget.x,widget.y)
                            }
                            guard let origin=dragOrigin else{return}
                            document.change(widget.id) { item in
                                item.x=origin.0+Double(gesture.translation.width)/scale
                                item.y=origin.1+Double(gesture.translation.height)/scale
                            }
                        }
                        .onEnded {_ in dragOrigin=nil})
                    .accessibilityLabel(widget.id)
                    .accessibilityIdentifier("hud-v600-widget-"+widget.id)
            }
        }
        .clipped()
        .accessibilityIdentifier("hud-v600-editing-canvas")
    }

    var body:some View {
        GeometryReader {geo in
            HStack(spacing:10) {
                visual(CGSize(width:max(160,geo.size.width*0.67),
                              height:geo.size.height-20))
                    .frame(width:max(160,geo.size.width*0.67))
                    .padding(.vertical,10)
                ScrollView {
                    VStack(alignment:.leading,spacing:10) {
                        Text("EDYTOR HUD v600")
                            .font(.system(size:16,weight:.bold,design:.monospaced))
                        Text("46 ELEMENTÓW · PC 1280×720")
                            .font(.system(size:10,design:.monospaced))
                            .foregroundStyle(.secondary)
                        Picker("Element",selection:selection) {
                            ForEach(document.widgets) {widget in
                                Text(widget.id).tag(widget.id)
                            }
                        }.pickerStyle(.menu)
                        if let w=selectedWidget {
                            Toggle("WIDOCZNY",isOn:Binding(
                                get:{w.visible},
                                set:{value in mutate{$0.visible=value}}
                            ))
                            number("X",\.x,bounds:-250...1530,step:0.5)
                            number("Y",\.y,bounds:-250...970,step:0.5)
                            number("SKALA",\.scale,bounds:0.25...4,step:0.01)
                            if w.is3D {
                                axis("YAW",\.yaw)
                                axis("PITCH",\.pitch)
                                axis("ROLL",\.roll)
                            }
                            Button("PRZYWRÓĆ TEN ELEMENT") {
                                if let original=HudLayout600.defaults().widget(selected) {
                                    document.change(selected){$0=original}
                                }
                            }
                            .font(.system(size:11,design:.monospaced))
                        }
                        Divider()
                        Button("ZAPISZ UKŁAD") {
                            guard document.save() else{return}
                            onSave(document)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("hud-v600-save")
                        Button("PRZYWRÓĆ CAŁY UKŁAD PC v600") {
                            document=HudLayout600.defaults()
                        }
                        .foregroundStyle(.orange)
                        Button("ANULUJ") {dismiss()}
                    }
                    .padding(10)
                }
                .frame(maxWidth:.infinity)
            }
            .padding(.horizontal,8)
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("hud-v600-editor")
    }
}
