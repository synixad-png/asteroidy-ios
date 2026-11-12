import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Same UIKit touch-first interaction and bottom toolbar as HudLayoutEditor600.
/// H290 uses its OWN validated document; combat HUD v600 is never changed.
struct PC602OrbitHUDEditor291:View {
    @Binding var layout:PC602OrbitHUDLayout291
    @Binding var selected:String
    let onSave:()->Bool
    let onCancel:()->Void

    @State private var inspectorOpen=false
    @State private var importingJSON=false
    @State private var exportingJSON=false
    @State private var exportDocument:PC602OrbitHUDDocument291?
    @State private var errorMessage:String?

    private var item:PC602OrbitHUDLayout291.Element {layout.item(selected)}
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
                // The real H290 widgets now own their touch surfaces,
                // exactly like the working mission UIKit recognizers.
                // This editor ONLY renders the toolbar/inspector: a
                // full-screen transparent canvas must never swallow WEJDŹ.
                Color.clear
                    .frame(width:geo.size.width,height:geo.size.height)
                    .allowsHitTesting(false)
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

/// One native UIKit recognizer mounted DIRECTLY on each actual rendered
/// H290 widget/control. Unlike a remote whole-screen canvas, its UIKit bounds
/// inherit the same SwiftUI scale and offset as the displayed object.
/// The mission F6 editor uses this same UIKit touchesBegan/Moved and pinch
/// pattern. Its implementation is deliberately left unchanged.
struct OrbitHUDItemTouchSurface291:UIViewRepresentable {
    let id:String
    let element:PC602OrbitHUDLayout291.Element
    let onSelect:(String)->Void
    let onMove:(PC602OrbitHUDLayout291.Element,Double,Double,CGRect)->Void
    let onScale:(Double,Double)->Void

    func makeUIView(context:Context)->TouchSurface {
        TouchSurface(frame:.zero)
    }
    func updateUIView(_ view:TouchSurface,context:Context) {
        view.element=element
        view.onSelect=onSelect
        view.onMove=onMove
        view.onScale=onScale
        view.accessibilityIdentifier="pc602-orbit-edit-target-"+id
    }
    final class TouchSurface:UIView {
        var element=PC602OrbitHUDLayout291.Element(id:"")
        var onSelect:((String)->Void)?
        var onMove:((PC602OrbitHUDLayout291.Element,Double,Double,CGRect)->Void)?
        var onScale:((Double,Double)->Void)?
        private var drag:(origin:PC602OrbitHUDLayout291.Element,
                          start:CGPoint,frame:CGRect)?
        private var pinchScale:Double?
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
            isUserInteractionEnabled=true
            isMultipleTouchEnabled=true
            // A touch target is not an accessibility button, so the
            // original game buttons remain discoverable by XCUITest.
            isAccessibilityElement=false
            let pinch=UIPinchGestureRecognizer(
                target:self,action:#selector(handlePinch(_:)))
            pinch.cancelsTouchesInView=false
            addGestureRecognizer(pinch)
        }
        private func worldFrame()->CGRect {
            guard let window else{return bounds}
            return convert(bounds,to:window)
        }
        override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent?) {
            super.touchesBegan(touches,with:event)
            guard event?.allTouches?.count==1,
                  let touch=touches.first,let window else {
                drag=nil;return
            }
            onSelect?(element.id)
            drag=(element,touch.location(in:window),worldFrame())
        }
        override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent?) {
            super.touchesMoved(touches,with:event)
            guard event?.allTouches?.count==1,pinchScale==nil,
                  let touch=touches.first,let start=drag,let window else{return}
            let position=touch.location(in:window)
            onMove?(start.origin,
                    Double(position.x-start.start.x),
                    Double(position.y-start.start.y),start.frame)
        }
        override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent?) {
            super.touchesEnded(touches,with:event)
            drag=nil
        }
        override func touchesCancelled(_ touches:Set<UITouch>,with event:UIEvent?) {
            super.touchesCancelled(touches,with:event)
            drag=nil
        }
        @objc private func handlePinch(_ gesture:UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                drag=nil
                onSelect?(element.id)
                pinchScale=element.scale
            case .changed:
                if let initial=pinchScale {
                    onScale?(initial,Double(gesture.scale))
                }
            case .ended,.cancelled,.failed:pinchScale=nil
            default:break
            }
        }
    }
}
