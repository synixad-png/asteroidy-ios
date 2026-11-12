import SwiftUI

/// H290 mode of the existing HUD/F6 editing workflow. One preview draft and
/// a single persistent layout; no duplicate game, camera or display clock.
/// Choose any actual element/button and drag on the preview or adjust sliders.
struct PC602OrbitHUDEditor291:View {
    @Binding var layout:PC602OrbitHUDLayout291
    let onSave:()->Void
    let onCancel:()->Void
    @State private var selected="hud.mission"
    @State private var dragStart:PC602OrbitHUDLayout291.Element?
    @State private var zoomStart:Double?
    private var current:PC602OrbitHUDLayout291.Element {layout.item(selected)}

    private func slider(_ title:String,_ axis:WritableKeyPath<PC602OrbitHUDLayout291.Element,Double>,
                        bounds:ClosedRange<Double>,step:Double)->some View {
        VStack(alignment:.leading,spacing:1) {
            Text(title+" "+String(format:"%.2f",current[keyPath:axis]))
                .font(.system(size:10,weight:.semibold,design:.monospaced))
                .lineLimit(1)
            Slider(value:Binding(
                get:{current[keyPath:axis]},
                set:{n in layout.change(selected){$0[keyPath:axis]=n}}
            ),in:bounds,step:step)
            .tint(.cyan)
        }
    }
    var body:some View {
        GeometryReader { screen in
            let width=max(1,Double(screen.size.width))
            let height=max(1,Double(screen.size.height))
            ZStack(alignment:.bottom) {
                Color.black.opacity(0.08)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance:2)
                        .onChanged { gesture in
                            if dragStart==nil {dragStart=current}
                            guard let origin=dragStart else{return}
                            layout.change(origin.id) {item in
                                item.x=max(-600,min(600,origin.x+
                                    Double(gesture.translation.width)*1280/width))
                                item.y=max(-360,min(360,origin.y+
                                    Double(gesture.translation.height)*720/height))
                            }
                        }
                        .onEnded {_ in dragStart=nil})
                    .simultaneousGesture(MagnificationGesture()
                        .onChanged { factor in
                            if zoomStart==nil {zoomStart=current.scale}
                            guard let original=zoomStart else{return}
                            layout.change(selected){item in
                                item.scale=max(0.55,min(2.5,original*Double(factor)))
                            }
                        }
                        .onEnded {_ in zoomStart=nil})
                VStack(spacing:4) {
                    HStack(spacing:8) {
                        Text("EDYTOR HUD / ORBITA")
                            .font(.system(size:12,weight:.bold,design:.monospaced))
                            .foregroundStyle(.yellow)
                        Picker("ELEMENT",selection:$selected) {
                            ForEach(PC602OrbitHUDLayout291.ids,id:\.self) { id in
                                Text(PC602OrbitHUDLayout291.title(id)).tag(id)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth:290)
                        .accessibilityIdentifier("pc602-orbit-hud-editor-selector")
                        Spacer(minLength:0)
                        Button("DOMYŚLNY") {layout = .defaults()}
                        Button("ANULUJ") {onCancel()}
                        Button("ZAPISZ") {onSave()}
                            .foregroundStyle(.green)
                            .accessibilityIdentifier("pc602-orbit-hud-editor-save")
                    }
                    HStack(spacing:12) {
                        slider("X",\.x,bounds:-600...600,step:1)
                        slider("Y",\.y,bounds:-360...360,step:1)
                        slider("SKALA",\.scale,bounds:0.55...2.5,step:0.05)
                    }
                    Text("WYBIERZ ELEMENT • PRZECIĄGNIJ PO EKRANIE LUB UŻYJ SUWAKÓW • SZCZYPNIJ ABY ZMIENIĆ SKALĘ")
                        .font(.system(size:9,design:.monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .font(.system(size:11,weight:.semibold,design:.monospaced))
                .foregroundStyle(.white)
                .buttonStyle(.bordered)
                .padding(10)
                .background(Color(red:0.01,green:0.025,blue:0.045).opacity(0.97))
                .overlay(Rectangle().stroke(Color.cyan.opacity(0.75),lineWidth:1))
                .padding(.horizontal,12)
                .padding(.bottom,CGFloat(max(10,screen.safeAreaInsets.bottom)))
            }
            .frame(width:screen.size.width,height:screen.size.height)
        }
        .accessibilityIdentifier("pc602-orbit-hud-editor291")
    }
}