import SwiftUI
import UniformTypeIdentifiers

/// Touch alternative to PC F6. Edits ALL 46 approved source widgets.
/// Paused mission owns this view; input zones and physics are never touched.
struct HudLayoutEditor600:View {
    @State private var document:HudLayout600
    @State private var inspectorOpen=false
    @State private var selected="hud.planetarium"
    @State private var importingJSON=false
    @State private var exportingJSON=false
    @State private var exportDocument600:HudLayoutDocument600?
    @State private var exchangeError600:String?
    let viewport:CombatHUDViewport568
    let onPreview:(HudLayout600)->Void
    let onSave:(HudLayout600)->Void
    let onCancel:()->Void

    init(initial:HudLayout600,viewport:CombatHUDViewport568,
         onPreview:@escaping (HudLayout600)->Void,
         onSave:@escaping (HudLayout600)->Void,
         onCancel:@escaping ()->Void) {
        self.viewport=viewport
        self.onPreview=onPreview
        self.onSave=onSave
        self.onCancel=onCancel
        _document=State(initialValue:initial)
    }

    private var selectedWidget:HudLayout600.Widget? {document.widget(selected)}
    private var selection:Binding<String> {
        Binding(get:{selected},set:{selected=$0})
    }
    private func mutate(_ edit:@escaping (inout HudLayout600.Widget)->Void) {
        document.change(selected,edit)
        onPreview(document)
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
    // Actual PC v602 HUD groups have independent safe-area origins.
    private func anchor(_ id:String)->CombatHUDViewport568.Anchor {
        if ["status.sector","status.score","status.money","status.lives"].contains(id)
            || id.hasPrefix("coop.") {return .topRight}
        if id == "radar" || id == "hud.planetarium"
            || id.hasPrefix("hull.") || id.hasPrefix("armor.")
            || id.hasPrefix("shield.") {return .bottomLeft}
        if ["ion.","bomb.","shield_charge.","boost."].contains(where:id.hasPrefix) {
            return .bottomRight
        }
        return .topLeft
    }
    private func changeWidget(_ id:String,_ edit:(inout HudLayout600.Widget)->Void) {
        document.change(id,edit)
        onPreview(document)
    }
    private func visual(_ bounds:CGSize)->some View {
        ZStack(alignment:.topLeading) {
            Color.clear.contentShape(Rectangle())
                .accessibilityIdentifier("hud-v600-editor-touch-blocker")
            ForEach(document.widgets) { widget in
                if let size=HudWidgetGeometry600.size(widget.id) {
                    let group=anchor(widget.id)
                    HudLayoutMarker600(
                        widget:widget,scale:viewport.scale,
                        offsetX:viewport.originX(for:group),
                        offsetY:viewport.originY(for:group),
                        sourceWidth:size.width,sourceHeight:size.height,
                        selected:$selected,
                        onMove:{x,y in
                            changeWidget(widget.id){$0.x=x;$0.y=y}
                        },
                        onScale:{newScale in
                            changeWidget(widget.id){ value in
                                let limit=HudWidgetGeometry600.scaleRange(for:value)
                                value.scale=min(limit.upperBound,max(limit.lowerBound,newScale))
                            }
                        })
                        // PC F6 prefers small overlapping elements.
                        .zIndex(selected==widget.id ? 10000 :
                                1.0/max(1,size.width*size.height))
                }
            }
        }
        .frame(width:bounds.width,height:bounds.height)
        .clipped()
        .accessibilityIdentifier("hud-v600-editing-canvas")
    }
    private var inspector:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:7) {
                Text("ZAZNACZONY ELEMENT")
                    .font(.system(size:11,weight:.bold,design:.monospaced))
                Picker("Element",selection:selection) {
                    ForEach(document.widgets) {widget in Text(widget.id).tag(widget.id)}
                }.pickerStyle(.menu)
                if let w=selectedWidget {
                    Toggle("WIDOCZNY",isOn:Binding(
                        get:{w.visible},set:{value in mutate{$0.visible=value}}
                    ))
                    number("X",\.x,
                        bounds:HudWidgetGeometry600.xRange(for:w) ?? 0...1268,step:0.5)
                    number("Y",\.y,
                        bounds:HudWidgetGeometry600.yRange(for:w) ?? 0...708,step:0.5)
                    number("SKALA",\.scale,
                        bounds:HudWidgetGeometry600.scaleRange(for:w),step:0.01)
                    if w.is3D {
                        axis("YAW",\.yaw)
                        axis("PITCH",\.pitch)
                        axis("ROLL",\.roll)
                    }
                    Button("PRZYWRÓĆ TEN ELEMENT") {
                        if let source=HudLayout600.defaults().widget(selected) {
                            changeWidget(selected){$0=source}
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
                }.accessibilityIdentifier("hud-v600-export-json")
                Button("IMPORTUJ UKŁAD JSON") {importingJSON=true}
                    .accessibilityIdentifier("hud-v600-import-json")
                Button("PRZYWRÓĆ CAŁY UKŁAD PC v602") {
                    document=HudLayout600.defaults()
                    onPreview(document)
                }.foregroundStyle(.orange)
                if let exchangeError600 {
                    Text(exchangeError600).font(.system(size:10))
                        .foregroundStyle(.orange)
                }
            }.padding(10)
        }
        .font(.system(size:11,design:.monospaced))
        .background(Color(red:0.018,green:0.034,blue:0.056).opacity(0.97))
        .overlay(Rectangle().stroke(Color.cyan.opacity(0.6),lineWidth:1))
        .accessibilityIdentifier("hud-v600-inspector")
    }
    var body:some View {
        GeometryReader { geo in
            ZStack(alignment:.topLeading) {
                visual(geo.size)
                VStack(spacing:0) {
                    HStack(spacing:8) {
                        Text("EDYTOR HUD · GRA WSTRZYMANA")
                            .font(.system(size:11,weight:.bold,design:.monospaced))
                            .foregroundStyle(.yellow)
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Spacer(minLength:4)
                        Button(inspectorOpen ? "UKRYJ OPCJE":"OPCJE") {
                            inspectorOpen.toggle()
                        }.accessibilityIdentifier("hud-v600-editor-inspector-toggle")
                        Button("ZAPISZ") {
                            guard document.save() else {
                                exchangeError600=HudLayout600.LayoutError.invalidLayout.localizedDescription
                                inspectorOpen=true
                                return
                            }
                            onSave(document)
                        }.accessibilityIdentifier("hud-v600-save")
                        Button("ANULUJ") {onCancel()}
                    }
                    .font(.system(size:11,weight:.semibold,design:.monospaced))
                    .buttonStyle(.bordered)
                    .padding(.horizontal,7).padding(.vertical,4)
                    .background(Color(red:0.01,green:0.02,blue:0.04).opacity(0.94))
                    Spacer(minLength:0)
                    if !inspectorOpen {
                        Text("PRZESUŃ PALCEM · SKALUJ SZCZYPIĄC DWOMA PALCAMI")
                            .font(.system(size:9,design:.monospaced))
                            .foregroundStyle(.white).padding(5)
                            .background(Color.black.opacity(0.77))
                            .allowsHitTesting(false)
                    }
                }
                if inspectorOpen {
                    inspector
                        .frame(width:min(310,max(235,geo.size.width*0.34)),
                               height:max(140,geo.size.height-52))
                        .frame(maxWidth:.infinity,maxHeight:.infinity,
                               alignment:.topTrailing)
                        .padding(.top,45)
                        .zIndex(20000)
                }
            }
        }
        .preferredColorScheme(.dark)
        .fileImporter(isPresented:$importingJSON,
                      allowedContentTypes:[.json]) { result in
            do {
                let url=try result.get()
                let scoped=url.startAccessingSecurityScopedResource()
                defer {if scoped {url.stopAccessingSecurityScopedResource()}}
                let handle=try FileHandle(forReadingFrom:url)
                defer{try? handle.close()}
                // Never load an arbitrary multi-megabyte Files document
                // into the UI. Approved PC v600 JSON is only a few KiB.
                let bytes=try handle.read(upToCount:65_537) ?? Data()
                document=try HudLayout600.decodeJSON(bytes)
                onPreview(document)
                exchangeError600=nil
            } catch {
                exchangeError600=error.localizedDescription
            }
        }
        .fileExporter(isPresented:$exportingJSON,
                      document:exportDocument600,
                      contentType:.json,
                      defaultFilename:"hud-layout-v600") { result in
            if case .failure(let error)=result {
                exchangeError600=error.localizedDescription
            }
        }
        .accessibilityIdentifier("hud-v600-editor")
    }
}
