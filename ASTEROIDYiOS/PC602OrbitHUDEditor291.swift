import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Same UIKit touch-first interaction and bottom toolbar as HudLayoutEditor600.
/// H290 uses its OWN validated document; combat HUD v600 is never changed.
struct PC602OrbitHUDEditor291:View {
    @Binding var layout:PC602OrbitHUDLayout291
    let measuredFrames:[String:CGRect]
    let navigationFrames:[String:CGRect]
    let onSave:()->Bool
    let onCancel:()->Void

    @State private var selected="hud.mission.heading"
    @State private var inspectorOpen=false
    @State private var importingJSON=false
    @State private var exportingJSON=false
    @State private var exportDocument:PC602OrbitHUDDocument291?
    @State private var errorMessage:String?

    private var item:PC602OrbitHUDLayout291.Element {layout.item(selected)}
    private var frames:[String:CGRect] {
        // Both the UIKit hit detector and the drawn outlines use these
        // same physical CGRects. Navigation Path/Text each occupy a
        // FULL-SCREEN SwiftUI container, so use the true source arrow rects.
        measuredFrames.merging(navigationFrames){_,authored in authored}
    }
    private var selectionIDs:[String] {
        // Like the mission F6 selector, put the actual individual HUD
        // widgets before the five controls, and legacy whole-group
        // transforms last. This avoids hiding the useful widgets at the
        // bottom of a long picker list.
        let leaves=PC602OrbitHUDLayout291.ids.filter {
            $0.hasPrefix("hud.") &&
            !PC602OrbitHUDLayout291.legacyIDs.contains($0)
        }
        let controls=PC602OrbitHUDLayout291.ids.filter {
            $0.hasPrefix("control.")
        }
        let groups=PC602OrbitHUDLayout291.legacyIDs.filter {
            $0.hasPrefix("hud.")
        }
        return leaves+controls+groups
    }
    private func selectNeighbor(_ delta:Int) {
        let ids=selectionIDs
        guard let idx=ids.firstIndex(of:selected) else{selected=ids[0];return}
        selected=ids[(idx+delta+ids.count)%ids.count]
    }
    private func change(_ id:String,_ mutation:(inout PC602OrbitHUDLayout291.Element)->Void) {
        layout.change(id,mutation)
    }
    private func move(_ id:String,original:PC602OrbitHUDLayout291.Element,
                      dx:Double,dy:Double,frame:CGRect,
                      viewport:CGSize,safeInsets:EdgeInsets) {
        guard dx.isFinite,dy.isFinite else{return}
        let rect=PC602OrbitHUDLayout291.Rect(
            x:Double(frame.origin.x),y:Double(frame.origin.y),
            width:Double(frame.size.width),height:Double(frame.size.height))
        let clamped=PC602OrbitHUDLayout291.constrainedDrag(
            id,deltaX:dx,deltaY:dy,frame:rect,
            viewportWidth:Double(viewport.width),
            viewportHeight:Double(viewport.height),
            safeInsets:(left:Double(safeInsets.leading),
                        right:Double(safeInsets.trailing),
                        top:Double(safeInsets.top),
                        bottom:Double(safeInsets.bottom)))
        let width=max(1,Double(viewport.width))
        let height=max(1,Double(viewport.height))
        // Legacy H290 group transforms still enclose every individual
        // text. Convert gesture deltas through the parent group scale,
        // precisely as mission HudEditorGeometry.move converts the
        // physical delta using the active viewport transform.
        let parent:String?
        if id.hasPrefix("hud.mission.") {parent="hud.mission"}
        else if id.hasPrefix("hud.telemetry.") {parent="hud.telemetry"}
        else if id.hasPrefix("hud.dock.") {parent="hud.dock"}
        else if id=="hud.navigation.label" {parent="hud.navigation"}
        else {parent=nil}
        let inherited=parent.map{layout.item($0).scale} ?? 1
        let base=max(0.001,inherited)
        let nextX=original.x+clamped.x*1280/(width*base)
        let nextY=original.y+clamped.y*720/(height*base)
        change(id){e in
            // The on-screen safe-area clamp is authoritative. The older
            // ±600/±360 extra clamp prevented moving WEJDŹ and PAUZA
            // across a landscape iPad/phone and caused visible snapping.
            e.x=max(-1280,min(1280,nextX))
            e.y=max(-720,min(720,nextY))
        }
    }
    private func scale(_ id:String,original:Double,factor:Double) {
        guard original.isFinite,original>0,factor.isFinite,factor>0 else{return}
        let range=PC602OrbitHUDLayout291.scaleRange(for:id)
        change(id){item in
            item.scale=max(range.lowerBound,
                           min(range.upperBound,original*factor))
        }
    }
    private func slider(_ label:String,
                        key:WritableKeyPath<PC602OrbitHUDLayout291.Element,Double>,
                        range:ClosedRange<Double>,step:Double)->some View {
        VStack(alignment:.leading,spacing:5) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format:"%.2f",item[keyPath:key])).monospacedDigit()
            }
            Slider(value:Binding(
                get:{item[keyPath:key]},
                set:{value in change(selected){$0[keyPath:key]=value}}
            ),in:range,step:step)
            .tint(.cyan)
            .frame(minHeight:44)
        }
        .font(.system(size:15,weight:.semibold,design:.monospaced))
    }
    private var inspector:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:10) {
                Text("ZAZNACZONY ELEMENT")
                    .font(.system(size:16,weight:.bold,design:.monospaced))
                    .foregroundStyle(.yellow)
                Picker("ELEMENT",selection:$selected) {
                    Text("BRAK").tag("")
                    ForEach(selectionIDs,id:\.self){id in
                        Text(PC602OrbitHUDLayout291.title(id)).tag(id)
                    }
                }
                .pickerStyle(.menu)
                .frame(minHeight:48)
                Text(selected.isEmpty ? "Dotknij element HUD na ekranie" :
                     PC602OrbitHUDLayout291.title(selected))
                    .font(.system(size:14,design:.monospaced))
                if selected.hasPrefix("hud.") {
                    Toggle("WIDOCZNY",isOn:Binding(
                        get:{item.visible},
                        set:{value in change(selected){$0.visible=value}}
                    ))
                    .tint(.cyan)
                    .frame(minHeight:48)
                } else {
                    Text("PRZYCISK FUNKCYJNY / RZECZYWISTY OBSZAR DOTYKU")
                        .font(.system(size:12,weight:.medium,design:.monospaced))
                        .foregroundStyle(.cyan)
                }
                if !selected.isEmpty {
                    slider("PRZESUNIĘCIE X",key:\.x,range:-1280...1280,step:1)
                    slider("PRZESUNIĘCIE Y",key:\.y,range:-720...720,step:1)
                    slider("WIELKOŚĆ / SKALA",key:\.scale,
                           range:PC602OrbitHUDLayout291.scaleRange(for:selected),
                           step:0.01)
                    Button(selected.hasPrefix("hud.")
                           ? "PRZYWRÓĆ TEN ELEMENT":"PRZYWRÓĆ TEN PRZYCISK"){
                        change(selected){$0=PC602OrbitHUDLayout291.defaults().item(selected)}
                    }
                }
                Divider().overlay(Color.cyan.opacity(0.3))
                Button("EKSPORTUJ UKŁAD JSON") {
                    guard layout.valid else {errorMessage="Układ HUD jest nieprawidłowy.";return}
                    exportDocument=PC602OrbitHUDDocument291(layout:layout)
                    exportingJSON=true
                }
                .accessibilityIdentifier("pc602-orbit-hud-export-json")
                Button("IMPORTUJ UKŁAD JSON") {importingJSON=true}
                    .accessibilityIdentifier("pc602-orbit-hud-import-json")
                Button("PRZYWRÓĆ CAŁY UKŁAD PC v602") {layout = .defaults()}
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("pc602-orbit-hud-reset")
                if let errorMessage {
                    Text(errorMessage).font(.system(size:14))
                        .foregroundStyle(.orange)
                }
            }
            .padding(14)
            .frame(maxWidth:.infinity,alignment:.leading)
        }
        .font(.system(size:15,weight:.semibold,design:.monospaced))
        .foregroundStyle(.white)
        .buttonStyle(.bordered)
        .controlSize(.large)
        .background(Color(red:0.018,green:0.034,blue:0.056).opacity(0.97))
        .overlay(Rectangle().stroke(Color.cyan.opacity(0.6),lineWidth:1))
        .accessibilityIdentifier("pc602-orbit-hud-inspector")
    }
    private var toolbar:some View {
        // A content-sized tool strip: never cover the actual bottom-left
        // dock info or bottom-right WEJDŹ button with a full-screen spacer.
        VStack(spacing:0) {
            HStack(spacing:8) {
                Button("◀") {selectNeighbor(-1)}
                    .accessibilityIdentifier("pc602-orbit-hud-previous")
                Picker("ELEMENT HUD",selection:$selected) {
                    Text("BRAK").tag("")
                    ForEach(selectionIDs,id:\.self){id in
                        Text(PC602OrbitHUDLayout291.title(id)).tag(id)
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth:100,maxWidth:290,minHeight:48)
                .accessibilityIdentifier("pc602-orbit-hud-editor-selector")
                Button("▶") {selectNeighbor(1)}
                    .accessibilityIdentifier("pc602-orbit-hud-next")
                Spacer(minLength:0)
                Button(inspectorOpen ? "UKRYJ OPCJE":"OPCJE"){
                    inspectorOpen.toggle()
                }
                .accessibilityIdentifier("pc602-orbit-hud-inspector-toggle")
                Button("ZAPISZ") {
                    if !onSave() {
                        errorMessage="Nie zapisano układu HUD. Sprawdź ustawienia i spróbuj ponownie."
                    }
                }
                    .accessibilityIdentifier("pc602-orbit-hud-editor-save")
                Button("ANULUJ") {onCancel()}
            }
            .font(.system(size:14,weight:.semibold,design:.monospaced))
            .foregroundStyle(.white)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(minHeight:54)
            .padding(.horizontal,9)
            .background(Color(red:0.01,green:0.02,blue:0.04).opacity(0.97))
            Text("\(PC602OrbitHUDLayout291.ids.count) ELEMENTÓW / DOTKNIJ • PRZESUŃ • SZCZYPIJ • OPCJE")
                .font(.system(size:12,design:.monospaced))
                .foregroundStyle(.white)
                .frame(minHeight:24)
                .background(Color.black.opacity(0.83))
                .allowsHitTesting(false)
        }
    }

    var body:some View {
        GeometryReader { geo in
            ZStack(alignment:.topLeading) {
                OrbitEditorTouchCanvas291(
                    layout:layout,selection:selected,frames:frames,
                    onSelect:{selected=$0},
                    onMove:{id,origin,dx,dy,frame in
                        move(id,original:origin,dx:dx,dy:dy,
                             frame:frame,viewport:geo.size,
                             safeInsets:geo.safeAreaInsets)
                    },
                    onScale:{id,original,factor in
                        scale(id,original:original,factor:factor)
                    })
                    .frame(width:geo.size.width,height:geo.size.height)
                    .accessibilityIdentifier("pc602-orbit-hud-touch-canvas")
                // H290's source WEJDŹ sits in the bottom-right corner.
                // The previous full-width bottom toolbar blocked its touch
                // target. Keep all controls while docking the strip only
                // in the free center-bottom region of the viewport.
                toolbar
                    .frame(width:min(660,max(360,geo.size.width*0.62)))
                    .frame(maxWidth:.infinity,maxHeight:.infinity,
                           alignment:.bottom)
                    .zIndex(10)
                if inspectorOpen {
                    inspector
                        .frame(width:min(340,max(265,geo.size.width*0.38)),
                               height:max(155,geo.size.height-140))
                        .frame(maxWidth:.infinity,maxHeight:.infinity,
                               alignment:.topTrailing)
                        .padding(.top,12)
                        .padding(.trailing,12)
                        .padding(.bottom,95)
                        .zIndex(20)
                }
            }
            .frame(width:geo.size.width,height:geo.size.height)
        }
        .preferredColorScheme(.dark)
        .fileImporter(isPresented:$importingJSON,allowedContentTypes:[.json]){result in
            do {
                let url=try result.get()
                let scoped=url.startAccessingSecurityScopedResource()
                defer{if scoped{url.stopAccessingSecurityScopedResource()}}
                let handle=try FileHandle(forReadingFrom:url)
                defer{try? handle.close()}
                // The mission HUD editor uses a bounded read, not an
                // unrestricted Data(contentsOf:) on imported files.
                let data=try handle.read(upToCount:65_537) ?? Data()
                guard data.count<=65_536 else {
                    errorMessage="Układ JSON jest zbyt duży.";return
                }
                layout=try PC602OrbitHUDLayout291.decodeJSON(data)
                errorMessage=nil
            } catch {errorMessage="Nieprawidłowy plik JSON: \(error.localizedDescription)"}
        }
        .fileExporter(isPresented:$exportingJSON,document:exportDocument,
                      contentType:.json,defaultFilename:"h290-hud-layout"){
            if case .failure(let error)=$0 {
                errorMessage=error.localizedDescription
            }
        }
        .accessibilityIdentifier("pc602-orbit-hud-editor291")
    }
}

/// Actual H290 SwiftUI item bounds in the SAME coordinates as the touch canvas.
/// Never invent static rectangles that drift when iPad scaling or safe area changes.
struct OrbitHUDFramePreference291:PreferenceKey {
    static var defaultValue:[String:CGRect]=[:]
    static func reduce(value:inout [String:CGRect],
                       nextValue:()->[String:CGRect]) {
        for (id,rect) in nextValue() {
            if let prior=value[id] {value[id]=prior.union(rect)}
            else {value[id]=rect}
        }
    }
}

struct PC602OrbitHUDDocument291:FileDocument {
    static var readableContentTypes:[UTType] { [.json] }
    var layout:PC602OrbitHUDLayout291
    init(layout:PC602OrbitHUDLayout291) {self.layout=layout}
    init(configuration:ReadConfiguration)throws {
        layout=try PC602OrbitHUDLayout291.decodeJSON(
            configuration.file.regularFileContents ?? Data())
    }
    func fileWrapper(configuration:WriteConfiguration)throws->FileWrapper {
        guard layout.valid else {throw PC602OrbitHUDLayout291.LayoutError.invalid}
        let encoder=JSONEncoder()
        encoder.outputFormatting=[.prettyPrinted,.sortedKeys]
        return FileWrapper(regularFileWithContents:try encoder.encode(layout))
    }
}

/// Same UIKit touch routing as the original mission HudEditorTouchCanvas:
/// hit an element directly, drag that element, pinch its scale, and draw a
/// marker on the actual active hit rectangle. No SwiftUI background gesture.
private struct OrbitEditorTouchCanvas291:UIViewRepresentable {
    let layout:PC602OrbitHUDLayout291
    let selection:String
    let frames:[String:CGRect]
    let onSelect:(String)->Void
    let onMove:(String,PC602OrbitHUDLayout291.Element,Double,Double,CGRect)->Void
    let onScale:(String,Double,Double)->Void

    func makeUIView(context:Context)->TouchSurface {TouchSurface(frame:.zero)}
    func updateUIView(_ view:TouchSurface,context:Context) {
        view.layout=layout
        view.selection=selection
        view.frames=frames
        view.onSelect=onSelect
        view.onMove=onMove
        view.onScale=onScale
        view.setNeedsDisplay()
    }

    final class TouchSurface:UIView {
        var layout=PC602OrbitHUDLayout291.defaults()
        var selection=""
        var frames:[String:CGRect]=[:]
        var onSelect:((String)->Void)?
        var onMove:((String,PC602OrbitHUDLayout291.Element,Double,Double,CGRect)->Void)?
        var onScale:((String,Double,Double)->Void)?
        private var dragStart:(element:PC602OrbitHUDLayout291.Element,
                              point:CGPoint,frame:CGRect)?
        private var pinchStart:(id:String,scale:Double)?
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
            let pinch=UIPinchGestureRecognizer(
                target:self,action:#selector(handlePinch(_:)))
            pinch.cancelsTouchesInView=false
            addGestureRecognizer(pinch)
        }
        private func modelRect(_ f:CGRect)->PC602OrbitHUDLayout291.Rect {
            PC602OrbitHUDLayout291.Rect(
                x:Double(f.origin.x),y:Double(f.origin.y),
                width:Double(f.size.width),height:Double(f.size.height))
        }
        private func hit(_ point:CGPoint)->String? {
            // Identical source-space hit algorithm to HudEditorGeometry.hit;
            // convert actual SwiftUI CGRects only at the UIKit boundary.
            let converted=frames.mapValues{modelRect($0)}
            return PC602OrbitHUDLayout291.hit(
                x:Double(point.x),y:Double(point.y),
                frames:converted,layout:layout)
        }
        override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?) {
            super.touchesBegan(touches,with:event)
            guard event?.allTouches?.count==1,let touch=touches.first else {
                dragStart=nil;return
            }
            let point=touch.location(in:self)
            if let id=hit(point),let frame=frames[id] {
                onSelect?(id)
                dragStart=(layout.item(id),point,frame)
            } else {
                onSelect?("")
                dragStart=nil
            }
        }
        override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent?) {
            super.touchesMoved(touches,with:event)
            guard event?.allTouches?.count==1,pinchStart==nil,
                  let touch=touches.first,let start=dragStart else{return}
            let point=touch.location(in:self)
            onMove?(start.element.id,start.element,
                    Double(point.x-start.point.x),
                    Double(point.y-start.point.y),start.frame)
        }
        override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?) {
            super.touchesEnded(touches,with:event)
            dragStart=nil
        }
        override func touchesCancelled(_ touches:Set<UITouch>,with event:UIEvent?) {
            super.touchesCancelled(touches,with:event)
            dragStart=nil
        }
        @objc private func handlePinch(_ gesture:UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                dragStart=nil
                // Match working HudLayoutEditor600: a pinch always
                // transforms the CURRENTLY SELECTED widget/control.
                // Picking a different item mid-pinch changed selection and
                // made scale feel unreliable on the iPad.
                guard PC602OrbitHUDLayout291.ids.contains(selection) else {
                    pinchStart=nil;return
                }
                pinchStart=(selection,layout.item(selection).scale)
            case .changed:
                if let start=pinchStart {
                    onScale?(start.id,start.scale,Double(gesture.scale))
                }
            case .ended,.cancelled,.failed:pinchStart=nil
            default:break
            }
        }
        override func draw(_ rect:CGRect) {
            guard let ctx=UIGraphicsGetCurrentContext() else{return}
            // Selected child is drawn AFTER groups, for a visible yellow
            // outline even when a nested legacy group overlaps it.
            let ordered=PC602OrbitHUDLayout291.ids.filter{$0 != selection} +
                        (PC602OrbitHUDLayout291.ids.contains(selection)
                         ? [selection] : [])
            for id in ordered {
                guard let raw=frames[id] else{continue}
                guard let source=PC602OrbitHUDLayout291.touchFrame(
                    modelRect(raw)) else{continue}
                let border=CGRect(x:source.x,y:source.y,
                                  width:source.width,height:source.height)
                let current=id==selection
                let isControl=id.hasPrefix("control.")
                let color:UIColor=current ? .systemYellow :
                    (isControl ? .systemOrange.withAlphaComponent(0.86) :
                     .cyan.withAlphaComponent(0.55))
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineWidth(current ? 2:1.1)
                ctx.stroke(border)
                if current {
                    (PC602OrbitHUDLayout291.title(id) as NSString).draw(
                        at:CGPoint(x:max(2,border.minX+3),
                                   y:max(2,border.minY-19)),
                        withAttributes:[
                            .font:UIFont.monospacedSystemFont(ofSize:13,
                                                             weight:.semibold),
                            .foregroundColor:UIColor.systemYellow
                        ])
                }
            }
        }
    }
}
