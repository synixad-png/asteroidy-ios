import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Same UIKit touch-first interaction and bottom toolbar as HudLayoutEditor600.
/// H290 uses its OWN validated document; combat HUD v600 is never changed.
struct PC602OrbitHUDEditor291:View {
    @Binding var layout:PC602OrbitHUDLayout291
    let measuredFrames:[String:CGRect]
    let navigationFrame:CGRect?
    let onSave:()->Void
    let onCancel:()->Void

    @State private var selected="hud.mission"
    @State private var inspectorOpen=false
    @State private var importingJSON=false
    @State private var exportingJSON=false
    @State private var exportDocument:PC602OrbitHUDDocument291?
    @State private var errorMessage:String?

    private var item:PC602OrbitHUDLayout291.Element {layout.item(selected)}
    private var frames:[String:CGRect] {
        var copy=measuredFrames
        if let navigationFrame {copy["hud.navigation"]=navigationFrame}
        return copy
    }
    private func selectNeighbor(_ delta:Int) {
        let ids=PC602OrbitHUDLayout291.ids
        guard let idx=ids.firstIndex(of:selected) else{selected=ids[0];return}
        selected=ids[(idx+delta+ids.count)%ids.count]
    }
    private func change(_ id:String,_ mutation:(inout PC602OrbitHUDLayout291.Element)->Void) {
        layout.change(id,mutation)
    }
    private func move(_ id:String,original:PC602OrbitHUDLayout291.Element,
                      dx:Double,dy:Double,viewport:CGSize) {
        let width=max(1,Double(viewport.width))
        let height=max(1,Double(viewport.height))
        change(id){e in
            e.x=max(-600,min(600,original.x+dx*1280/width))
            e.y=max(-360,min(360,original.y+dy*720/height))
        }
    }
    private func scale(_ id:String,original:Double,factor:Double) {
        change(id){e in e.scale=max(0.55,min(2.5,original*factor))}
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
                    ForEach(PC602OrbitHUDLayout291.ids,id:\.self){id in
                        Text(PC602OrbitHUDLayout291.title(id)).tag(id)
                    }
                }
                .pickerStyle(.menu)
                .frame(minHeight:48)
                Text(PC602OrbitHUDLayout291.title(selected))
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
                slider("PRZESUNIĘCIE X",key:\.x,range:-600...600,step:1)
                slider("PRZESUNIĘCIE Y",key:\.y,range:-360...360,step:1)
                slider("WIELKOŚĆ / SKALA",key:\.scale,range:0.55...2.5,step:0.01)
                Button(selected.hasPrefix("hud.")
                       ? "PRZYWRÓĆ TEN ELEMENT":"PRZYWRÓĆ TEN PRZYCISK"){
                    change(selected){$0=PC602OrbitHUDLayout291.defaults().item(selected)}
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
        VStack(spacing:0) {
            Spacer(minLength:0)
            HStack(spacing:8) {
                Button("◀") {selectNeighbor(-1)}
                    .accessibilityIdentifier("pc602-orbit-hud-previous")
                Picker("ELEMENT HUD",selection:$selected) {
                    ForEach(PC602OrbitHUDLayout291.ids,id:\.self){id in
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
                Button("ZAPISZ") {onSave()}
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
            Text("11 ELEMENTÓW / DOTKNIJ • PRZESUŃ • SZCZYPIJ • OPCJE")
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
                    onMove:{id,origin,dx,dy in
                        move(id,original:origin,dx:dx,dy:dy,
                             viewport:geo.size)
                    },
                    onScale:{id,original,factor in
                        scale(id,original:original,factor:factor)
                    })
                    .frame(width:geo.size.width,height:geo.size.height)
                    .accessibilityIdentifier("pc602-orbit-hud-touch-canvas")
                toolbar
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
                let data=try Data(contentsOf:url)
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
        return FileWrapper(regularFileContents:try encoder.encode(layout))
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
    let onMove:(String,PC602OrbitHUDLayout291.Element,Double,Double)->Void
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
        var onMove:((String,PC602OrbitHUDLayout291.Element,Double,Double)->Void)?
        var onScale:((String,Double,Double)->Void)?
        private var dragStart:(element:PC602OrbitHUDLayout291.Element,point:CGPoint)?
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
        private func tapFrame(_ r:CGRect)->CGRect {
            let w=max(44,r.width),h=max(44,r.height)
            return CGRect(x:r.midX-w/2,y:r.midY-h/2,width:w,height:h)
        }
        private func hit(_ point:CGPoint)->String? {
            // Interactive buttons win over overlapping text widgets.
            let ids=PC602OrbitHUDLayout291.ids.filter{
                $0.hasPrefix("control.")
            }+PC602OrbitHUDLayout291.ids.filter{$0.hasPrefix("hud.")}
            for id in ids {
                guard let r=frames[id],tapFrame(r).contains(point) else{continue}
                return id
            }
            return nil
        }
        override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?) {
            super.touchesBegan(touches,with:event)
            guard event?.allTouches?.count==1,let touch=touches.first else {
                dragStart=nil;return
            }
            let point=touch.location(in:self)
            if let id=hit(point) {
                onSelect?(id)
                dragStart=(layout.item(id),point)
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
                    Double(point.y-start.point.y))
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
                let location=gesture.location(in:self)
                let id=hit(location) ?? selection
                guard PC602OrbitHUDLayout291.ids.contains(id) else {
                    pinchStart=nil;return
                }
                onSelect?(id)
                pinchStart=(id,layout.item(id).scale)
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
            for id in PC602OrbitHUDLayout291.ids {
                guard let raw=frames[id] else{continue}
                let border=tapFrame(raw)
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
