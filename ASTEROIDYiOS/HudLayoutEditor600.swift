import SwiftUI
import UniformTypeIdentifiers

/// Touch alternative to PC F6. Edits ALL 46 approved source widgets.
/// Paused mission owns this view; input zones and physics are never touched.
struct HudLayoutEditor600:View {
    @Environment(\.dismiss) private var dismiss
    @State private var document=HudLayout600.load()
    @State private var selected="hud.planetarium"
    @State private var importingJSON=false
    @State private var exportingJSON=false
    @State private var exportDocument600:HudLayoutDocument600?
    @State private var exchangeError600:String?
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
    private func visual(_ bounds:CGSize)->some View {
        let scale=min(Double(bounds.width)/1280,Double(bounds.height)/720)
        let offsetX=(Double(bounds.width)-1280*scale)/2
        let offsetY=(Double(bounds.height)-720*scale)/2
        return ZStack(alignment:.topLeading) {
            Rectangle().fill(Color(red:0.012,green:0.026,blue:0.045))
            ForEach(document.widgets) { widget in
                if let dims=HudWidgetGeometry600.size(widget.id) {
                    HudLayoutMarker600(
                        widget:widget,scale:scale,offsetX:offsetX,offsetY:offsetY,
                        sourceWidth:dims.width,sourceHeight:dims.height,
                        selected:$selected
                    ) { x,y in
                        document.change(widget.id) {
                            $0.x=x
                            $0.y=y
                        }
                    }
                }
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
                            number("X",\.x,bounds:HudWidgetGeometry600.xRange(for:w) ?? 0...1268,step:0.5)
                            number("Y",\.y,bounds:HudWidgetGeometry600.yRange(for:w) ?? 0...708,step:0.5)
                            number("SKALA",\.scale,bounds:HudWidgetGeometry600.scaleRange(for:w),step:0.01)
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
                        Button("EKSPORTUJ UKŁAD JSON") {
                            guard document.isValid else {
                                exchangeError600=HudLayout600.LayoutError.invalidLayout.localizedDescription
                                return
                            }
                            exportDocument600=HudLayoutDocument600(layout:document)
                            exportingJSON=true
                        }
                        .accessibilityIdentifier("hud-v600-export-json")
                        Button("IMPORTUJ UKŁAD JSON") {
                            importingJSON=true
                        }
                        .accessibilityIdentifier("hud-v600-import-json")
                        if let exchangeError600 {
                            Text(exchangeError600)
                                .font(.system(size:10,design:.monospaced))
                                .foregroundStyle(.orange)
                        }
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
        .fileImporter(isPresented:$importingJSON,
                      allowedContentTypes:[.json]) { result in
            do {
                let url=try result.get()
                let scoped=url.startAccessingSecurityScopedResource()
                defer {if scoped {url.stopAccessingSecurityScopedResource()}}
                let bytes=try Data(contentsOf:url)
                document=try HudLayout600.decodeJSON(bytes)
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
