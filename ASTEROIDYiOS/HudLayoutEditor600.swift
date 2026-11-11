import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Native editor of the paused, *real* combat HUD. The 46 markers share one
/// UIKit touch surface; no nested SwiftUI DragGesture or hit-test interception.
/// Selection, geometry and movement come from PC v602 HudLayout.SelectAt/Drag.
struct HudLayoutEditor600:View {
    @State private var document:HudLayout600
    @State private var controlDocument:HudControlLayout600
    @State private var selected="radar"
    @State private var inspectorOpen=false
    @State private var importingJSON=false
    @State private var exportingJSON=false
    @State private var exportDocument600:HudLayoutDocument600?
    @State private var exchangeError600:String?

    let viewport:CombatHUDViewport568
    let onPreview:(HudLayout600)->Void
    let onPreviewControls:(HudControlLayout600)->Void
    let onSave:(HudLayout600)->Void
    let onSaveControls:(HudControlLayout600)->Void
    let onCancel:()->Void

    init(initial:HudLayout600,initialControls:HudControlLayout600,
         viewport:CombatHUDViewport568,
         onPreview:@escaping (HudLayout600)->Void,
         onPreviewControls:@escaping (HudControlLayout600)->Void,
         onSaveControls:@escaping (HudControlLayout600)->Void,
         onSave:@escaping (HudLayout600)->Void,
         onCancel:@escaping ()->Void) {
        self.viewport=viewport
        self.onPreview=onPreview
        self.onPreviewControls=onPreviewControls
        self.onSave=onSave
        self.onSaveControls=onSaveControls
        self.onCancel=onCancel
        _document=State(initialValue:initial)
        _controlDocument=State(initialValue:initialControls)
    }

    private var selectedWidget:HudLayout600.Widget? {document.widget(selected)}
    private var selectedControl:HudControlLayout600.Control? {
        controlDocument.control(selected)
    }
    private var selection:Binding<String> {
        Binding(get:{selected},set:{selected=$0})
    }

    private func change(_ id:String,_ edit:(inout HudLayout600.Widget)->Void) {
        document.change(id,edit)
        onPreview(document)
    }
    private func move(_ id:String,from original:HudLayout600.Widget,
                      dx:Double,dy:Double) {
        HudEditorGeometry.move(id,from:original,deltaX:dx,deltaY:dy,
                               viewport:viewport,in:&document)
        onPreview(document)
    }
    private func zoom(_ id:String,from scale:Double,factor:Double) {
        HudEditorGeometry.zoom(id,originalScale:scale,factor:factor,in:&document)
        onPreview(document)
    }
    private func changeControl(_ id:String,
                               _ edit:(inout HudControlLayout600.Control)->Void) {
        controlDocument.change(id,edit)
        onPreviewControls(controlDocument)
    }
    private func moveControl(_ id:String,from original:HudControlLayout600.Control,
                             dx:Double,dy:Double) {
        controlDocument.move(id,from:original,deltaX:dx,deltaY:dy,
                             viewport:viewport,compact:viewport.height<550)
        onPreviewControls(controlDocument)
    }
    private func zoomControl(_ id:String,from scale:Double,factor:Double) {
        controlDocument.zoom(id,originalScale:scale,factor:factor,
                             viewport:viewport,compact:viewport.height<550)
        onPreviewControls(controlDocument)
    }
    private var selectionIDs600:[String] {
        document.widgets.map(\.id)+controlDocument.controls.map(\.id)
    }
    private func selectNeighbor600(_ delta:Int) {
        let ids=selectionIDs600
        guard !ids.isEmpty else{return}
        let current=ids.firstIndex(of:selected) ?? 0
        selected=ids[(current+delta+ids.count)%ids.count]
    }

    private func number(_ label:String,_ key:WritableKeyPath<HudLayout600.Widget,Double>,
                        limits:ClosedRange<Double>,step:Double)->some View {
        VStack(alignment:.leading,spacing:3) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format:"%.2f",selectedWidget?[keyPath:key] ?? 0))
                    .monospacedDigit()
            }
            Slider(value:Binding(
                get:{selectedWidget?[keyPath:key] ?? 0},
                set:{value in change(selected){$0[keyPath:key]=value}}
            ),in:limits,step:step)
            .tint(.cyan)
        }
        .font(.system(size:11,design:.monospaced))
    }

    private func controlNumber(_ label:String,
                               _ key:WritableKeyPath<HudControlLayout600.Control,Double>,
                               limits:ClosedRange<Double>,step:Double)->some View {
        VStack(alignment:.leading,spacing:3) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format:"%.2f",selectedControl?[keyPath:key] ?? 0))
                    .monospacedDigit()
            }
            Slider(value:Binding(
                get:{selectedControl?[keyPath:key] ?? 0},
                set:{value in changeControl(selected){$0[keyPath:key]=value}}
            ),in:limits,step:step)
            .tint(.cyan)
        }
        .font(.system(size:11,design:.monospaced))
    }

    private func axis(_ label:String,_ key:WritableKeyPath<HudLayout600.Widget,Double?>)->some View {
        VStack(alignment:.leading,spacing:3) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format:"%.0f°",selectedWidget?[keyPath:key] ?? 0))
                    .monospacedDigit()
            }
            Slider(value:Binding(
                get:{selectedWidget?[keyPath:key] ?? 0},
                set:{value in change(selected){$0[keyPath:key]=value}}
            ),in:-180...180,step:1)
            .tint(.cyan)
        }
        .font(.system(size:11,design:.monospaced))
    }

    private var inspector:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:8) {
                Text("ZAZNACZONY ELEMENT")
                    .font(.system(size:11,weight:.bold,design:.monospaced))
                Picker("Element",selection:selection) {
                    Text("BRAK").tag("")
                    ForEach(document.widgets) { item in
                        Text(item.id).tag(item.id)
                    }
                    ForEach(controlDocument.controls) { control in
                        Text("PRZYCISK / "+HudControlLayout600.title(control.id))
                            .tag(control.id)
                    }
                }
                .pickerStyle(.menu)
                if let widget=selectedWidget {
                    Toggle("WIDOCZNY",isOn:Binding(
                        get:{selectedWidget?.visible ?? false},
                        set:{flag in change(widget.id){$0.visible=flag}}
                    ))
                    number("X",\.x,limits:HudWidgetGeometry600.xRange(for:widget) ?? 0...1268,
                           step:0.5)
                    number("Y",\.y,limits:HudWidgetGeometry600.yRange(for:widget) ?? 0...708,
                           step:0.5)
                    number("SKALA",\.scale,
                           limits:HudWidgetGeometry600.scaleRange(for:widget),step:0.01)
                    if widget.is3D {
                        axis("YAW",\.yaw)
                        axis("PITCH",\.pitch)
                        axis("ROLL",\.roll)
                    }
                    Button("PRZYWRÓĆ TEN ELEMENT") {
                        if let original=HudLayout600.defaults().widget(widget.id) {
                            change(widget.id){$0=original}
                        }
                    }
                } else if let control=selectedControl {
                    Text("PRZYCISK FUNKCYJNY / AKTYWNY OBSZAR DOTYKU")
                        .font(.system(size:10,weight:.semibold,design:.monospaced))
                    Text("Pozycja i wielkość przycisku zmieniają również jego rzeczywisty obszar dotyku.")
                        .font(.system(size:10))
                    let limits=HudControlLayout600.limits(
                        control.id,viewport:viewport,
                        compact:viewport.height<550,scale:control.scale)
                    controlNumber("PRZESUNIĘCIE X",\.x,limits:limits.x,step:0.5)
                    controlNumber("PRZESUNIĘCIE Y",\.y,limits:limits.y,step:0.5)
                    controlNumber("WIELKOŚĆ",\.scale,
                                  limits:HudControlLayout600.scaleRange(for:control.id),
                                  step:0.05)
                    Button("PRZYWRÓĆ TEN PRZYCISK") {
                        if let original=HudControlLayout600.defaults()
                            .control(control.id) {
                            changeControl(control.id){$0=original}
                        }
                    }
                }
                Divider()
                Button("EKSPORTUJ UKŁAD JSON") {
                    guard document.isValid else {
                        exchangeError600=HudLayout600.LayoutError.invalidLayout.localizedDescription
                        return
                    }
                    exportDocument600=HudLayoutDocument600(layout:document)
                    exportingJSON=true
                }
                .accessibilityIdentifier("hud-v600-export-json")
                Button("IMPORTUJ UKŁAD JSON") {importingJSON=true}
                    .accessibilityIdentifier("hud-v600-import-json")
                Button("PRZYWRÓĆ CAŁY UKŁAD PC v602") {
                    document=HudLayout600.defaults()
                    controlDocument=HudControlLayout600.defaults()
                    onPreview(document)
                    onPreviewControls(controlDocument)
                }
                .foregroundStyle(.orange)
                if let exchangeError600 {
                    Text(exchangeError600).foregroundStyle(.orange)
                        .font(.system(size:10))
                }
            }
            .padding(10)
        }
        .font(.system(size:11,design:.monospaced))
        .background(Color(red:0.018,green:0.034,blue:0.056).opacity(0.97))
        .overlay(Rectangle().stroke(Color.cyan.opacity(0.6),lineWidth:1))
        .accessibilityIdentifier("hud-v600-inspector")
    }

    private var toolbar:some View {
        VStack(spacing:0) {
            Spacer(minLength:0)
            HStack(spacing:7) {
                Button("◀") {selectNeighbor600(-1)}
                    .accessibilityIdentifier("hud-v602-previous-widget")
                Picker("ELEMENT HUD",selection:selection) {
                    Text("BRAK").tag("")
                    ForEach(document.widgets) {widget in
                        Text(widget.id).tag(widget.id)
                    }
                    ForEach(controlDocument.controls) {control in
                        Text("PRZYCISK / "+HudControlLayout600.title(control.id))
                            .tag(control.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth:120,maxWidth:245)
                .accessibilityIdentifier("hud-v602-always-visible-widget-selector")
                Button("▶") {selectNeighbor600(1)}
                    .accessibilityIdentifier("hud-v602-next-widget")
                Spacer(minLength:0)
                Button(inspectorOpen ? "UKRYJ OPCJE":"OPCJE") {
                    inspectorOpen.toggle()
                }
                .accessibilityIdentifier("hud-v600-editor-inspector-toggle")
                Button("ZAPISZ") {
                    guard document.isValid,controlDocument.isValid,
                          document.save(),controlDocument.save() else {
                        exchangeError600="Nieprawidłowe ustawienia HUD lub przycisków."
                        inspectorOpen=true
                        return
                    }
                    onSaveControls(controlDocument)
                    onSave(document)
                }
                .accessibilityIdentifier("hud-v600-save")
                Button("ANULUJ") {onCancel()}
            }
            .font(.system(size:11,weight:.semibold,design:.monospaced))
            .buttonStyle(.bordered)
            .padding(.horizontal,7)
            .padding(.vertical,5)
            .background(Color(red:0.01,green:0.02,blue:0.04).opacity(0.95))
            Text("46 ELEMENTÓW + 5 PRZYCISKÓW · PRZESUŃ / SZCZYPIJ / OPCJE")
                .font(.system(size:9,design:.monospaced))
                .foregroundStyle(.white)
                .padding(4)
                .background(Color.black.opacity(0.80))
                .allowsHitTesting(false)
        }
        .padding(.bottom,CGFloat(max(12,viewport.safeBottom+7)))
    }

    var body:some View {
        GeometryReader { geo in
            ZStack(alignment:.topLeading) {
                HudEditorTouchCanvas(
                    layout:document,controlLayout:controlDocument,
                    viewport:viewport,selection:selected,
                    onSelect:{selected=$0},
                    onMove:{id,original,dx,dy in
                        move(id,from:original,dx:dx,dy:dy)
                    },
                    onScale:{id,originalScale,factor in
                        zoom(id,from:originalScale,factor:factor)
                    },
                    onControlMove:{id,original,dx,dy in
                        moveControl(id,from:original,dx:dx,dy:dy)
                    },
                    onControlScale:{id,originalScale,factor in
                        zoomControl(id,from:originalScale,factor:factor)
                    })
                    .frame(width:geo.size.width,height:geo.size.height)
                    .accessibilityIdentifier("hud-v600-editing-canvas")
                toolbar
                if inspectorOpen {
                    inspector
                        .frame(width:min(310,max(235,geo.size.width*0.34)),
                               height:max(140,geo.size.height - CGFloat(max(88,viewport.safeBottom+65)) - CGFloat(max(46,viewport.safeTop+16))))
                        .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topTrailing)
                        .padding(.top,CGFloat(max(46,viewport.safeTop+16)))
                        .padding(.trailing,CGFloat(max(12,viewport.safeRight)))
                        .padding(.bottom,CGFloat(max(88,viewport.safeBottom+65)))
                        .zIndex(20)
                }
            }
            .frame(width:geo.size.width,height:geo.size.height)
        }
        .preferredColorScheme(.dark)
        .fileImporter(isPresented:$importingJSON,allowedContentTypes:[.json]) { result in
            do {
                let url=try result.get()
                let scoped=url.startAccessingSecurityScopedResource()
                defer {if scoped {url.stopAccessingSecurityScopedResource()}}
                let handle=try FileHandle(forReadingFrom:url)
                defer {try? handle.close()}
                let bytes=try handle.read(upToCount:65_537) ?? Data()
                document=try HudLayout600.decodeJSON(bytes)
                onPreview(document)
                exchangeError600=nil
            } catch {exchangeError600=error.localizedDescription}
        }
        .fileExporter(isPresented:$exportingJSON,document:exportDocument600,
                      contentType:.json,defaultFilename:"hud-layout-v602") { result in
            if case .failure(let error)=result {exchangeError600=error.localizedDescription}
        }
        .accessibilityIdentifier("hud-v600-editor")
    }
}

/// A single native view receives touches in the same logical space as the
/// original F6 selector. It never intercepts pause/options controls layered
/// above it and never changes the actual Metal combat camera or physics.
private struct HudEditorTouchCanvas:UIViewRepresentable {
    let layout:HudLayout600
    let controlLayout:HudControlLayout600
    let viewport:CombatHUDViewport568
    let selection:String
    let onSelect:(String)->Void
    let onMove:(String,HudLayout600.Widget,Double,Double)->Void
    let onScale:(String,Double,Double)->Void
    let onControlMove:(String,HudControlLayout600.Control,Double,Double)->Void
    let onControlScale:(String,Double,Double)->Void

    func makeUIView(context:Context)->TouchSurface {
        TouchSurface(frame:.zero)
    }
    func updateUIView(_ view:TouchSurface,context:Context) {
        view.layout=layout
        view.controlLayout=controlLayout
        view.viewport=viewport
        view.selection=selection
        view.onSelect=onSelect
        view.onMove=onMove
        view.onScale=onScale
        view.onControlMove=onControlMove
        view.onControlScale=onControlScale
        view.setNeedsDisplay()
    }

    final class TouchSurface:UIView {
        var layout=HudLayout600.defaults()
        var controlLayout=HudControlLayout600.defaults()
        var viewport=CombatHUDViewport568(width:1280,height:720)
        var selection=""
        var onSelect:((String)->Void)?
        var onMove:((String,HudLayout600.Widget,Double,Double)->Void)?
        var onScale:((String,Double,Double)->Void)?
        var onControlMove:((String,HudControlLayout600.Control,Double,Double)->Void)?
        var onControlScale:((String,Double,Double)->Void)?
        private var dragStart:(widget:HudLayout600.Widget,point:CGPoint)?
        private var controlDragStart:(control:HudControlLayout600.Control,point:CGPoint)?
        private var pinchStart:(id:String,scale:Double)?
        private var controlPinchStart:(id:String,scale:Double)?

        override init(frame:CGRect) {
            super.init(frame:frame)
            configure()
        }
        required init?(coder:NSCoder) {
            super.init(coder:coder)
            configure()
        }
        private func configure() {
            isOpaque=false
            backgroundColor = .clear
            isMultipleTouchEnabled=true
            contentMode = .redraw
            accessibilityIdentifier="hud-v600-editor-touch-blocker"
            let pinch=UIPinchGestureRecognizer(
                target:self,action:#selector(handlePinch(_:)))
            pinch.cancelsTouchesInView=false
            addGestureRecognizer(pinch)
        }

        override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?) {
            super.touchesBegan(touches,with:event)
            guard event?.allTouches?.count == 1,let touch=touches.first else {
                dragStart=nil
                controlDragStart=nil
                return
            }
            let point=touch.location(in:self)
            let controlID=HudControlLayout600.hit(
                x:Double(point.x),y:Double(point.y),
                layout:controlLayout,viewport:viewport,
                compact:viewport.height<550)
            if let id=controlID,let control=controlLayout.control(id) {
                onSelect?(id)
                controlDragStart=(control:control,point:point)
                dragStart=nil
            } else {
                let id=HudEditorGeometry.hit(
                    x:Double(point.x),y:Double(point.y),
                    layout:layout,viewport:viewport)
                onSelect?(id ?? "")
                dragStart=id.flatMap { key in
                    layout.widget(key).map {(widget:$0,point:point)}
                }
                controlDragStart=nil
            }
        }

        override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent?) {
            super.touchesMoved(touches,with:event)
            guard event?.allTouches?.count == 1,
                  pinchStart == nil,controlPinchStart == nil,
                  let touch=touches.first else{return}
            let point=touch.location(in:self)
            if let start=controlDragStart {
                onControlMove?(start.control.id,start.control,
                               Double(point.x-start.point.x),
                               Double(point.y-start.point.y))
            } else if let start=dragStart {
                onMove?(start.widget.id,start.widget,
                        Double(point.x-start.point.x),
                        Double(point.y-start.point.y))
            }
        }

        override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?) {
            super.touchesEnded(touches,with:event)
            dragStart=nil
            controlDragStart=nil
        }
        override func touchesCancelled(_ touches:Set<UITouch>,with event:UIEvent?) {
            super.touchesCancelled(touches,with:event)
            dragStart=nil
            controlDragStart=nil
        }

        @objc private func handlePinch(_ gesture:UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                dragStart=nil
                controlDragStart=nil
                if let control=controlLayout.control(selection) {
                    controlPinchStart=(control.id,control.scale)
                    pinchStart=nil
                } else if let item=layout.widget(selection) {
                    pinchStart=(item.id,item.scale)
                    controlPinchStart=nil
                }
            case .changed:
                if let start=controlPinchStart {
                    onControlScale?(start.id,start.scale,Double(gesture.scale))
                } else if let start=pinchStart {
                    onScale?(start.id,start.scale,Double(gesture.scale))
                }
            case .ended,.cancelled,.failed:
                pinchStart=nil
                controlPinchStart=nil
            default:break
            }
        }

        override func draw(_ rect:CGRect) {
            guard let ctx=UIGraphicsGetCurrentContext() else{return}
            for widget in layout.widgets {
                guard let f=HudEditorGeometry.rect(widget,viewport:viewport) else{continue}
                let border=CGRect(x:f.x,y:f.y,width:f.width,height:f.height)
                let chosen=widget.id==selection
                let color:UIColor=chosen ? .systemYellow :
                    (widget.visible ? .cyan.withAlphaComponent(0.5) :
                     .lightGray.withAlphaComponent(0.32))
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineWidth(chosen ? 2 : 0.8)
                ctx.stroke(border)
                if chosen {
                    (widget.id as NSString).draw(
                        at:CGPoint(x:border.minX+3,y:max(0,border.minY-18)),
                        withAttributes:[
                            .font:UIFont.monospacedSystemFont(ofSize:11,weight:.medium),
                            .foregroundColor:UIColor.systemYellow
                        ])
                }
            }

            // Actual button hitboxes, not decorative markers. The pause
            // options action is normally hidden while editing, therefore
            // its frame is also shown here for direct drag and pinch.
            for control in controlLayout.controls {
                let frame=HudControlLayout600.frame(
                    control,viewport:viewport,compact:viewport.height<550)
                let border=CGRect(x:frame.centerX-frame.width/2,
                                  y:frame.centerY-frame.height/2,
                                  width:frame.width,height:frame.height)
                let chosen=control.id==selection
                ctx.setStrokeColor((chosen ? UIColor.systemYellow :
                                    UIColor.systemOrange.withAlphaComponent(0.86)).cgColor)
                ctx.setLineWidth(chosen ? 2:1.2)
                ctx.stroke(border)
                if chosen {
                    (HudControlLayout600.title(control.id) as NSString).draw(
                        at:CGPoint(x:border.minX+3,y:max(0,border.minY-18)),
                        withAttributes:[
                            .font:UIFont.monospacedSystemFont(ofSize:11,weight:.semibold),
                            .foregroundColor:UIColor.systemYellow
                        ])
                }
            }
        }
    }
}
