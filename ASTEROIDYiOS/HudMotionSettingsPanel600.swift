import SwiftUI

/// PC v600 motion options 151–158; the editor changes only HUD appearance.
struct HudMotionSettingsPanel600:View {
    let onChange:(HudMotion600.Settings)->Void
    @Environment(\.dismiss) private var dismiss
    @State private var settings=HudMotion600.Settings.load()

    private func number(_ title:String,_ key:WritableKeyPath<HudMotion600.Settings,Int>,
                        maximum:Int,step:Int)->some View {
        VStack(alignment:.leading,spacing:5) {
            HStack {
                Text(title)
                Spacer()
                Text("\(settings[keyPath:key])%").monospacedDigit()
            }.font(.system(size:12,weight:.medium,design:.monospaced))
            Slider(value:Binding(
                get:{Double(settings[keyPath:key])},
                set:{settings[keyPath:key]=max(0,min(maximum,
                    Int(($0/Double(step)).rounded())*step))}
            ),in:0...Double(maximum),step:Double(step))
            .tint(.cyan)
        }
    }

    var body:some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:14) {
                    Picker("PROFIL RUCHU",selection:$settings.profile) {
                        Text("WYŁĄCZONY").tag(0)
                        Text("SUBTELNY").tag(1)
                        Text("DYNAMICZNY").tag(2)
                        Text("INTENSYWNY").tag(3)
                    }.pickerStyle(.menu)
                    number("INTENSYWNOŚĆ",\.strength,maximum:100,step:5)
                    number("BEZWŁADNOŚĆ",\.inertia,maximum:100,step:5)
                    number("SIŁA WSTRZĄSÓW",\.impact,maximum:100,step:5)
                    Toggle("PARALAKSA WARSTW",isOn:$settings.parallax)
                    Toggle("REAKCJE NA WALKĘ",isOn:$settings.reactions)
                    number("WYCHYLENIE W LEWO",\.leftSway,maximum:400,step:25)
                    number("WYCHYLENIE W PRAWO",\.rightSway,maximum:400,step:25)
                    Text("Zmienia wyłącznie animację nakładki HUD. Sterowanie i fizyka statku nie są modyfikowane.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .navigationTitle("HUD DYNAMICZNY")
            .toolbar {
                ToolbarItem(placement:.confirmationAction) {
                    Button("GOTOWE") {dismiss()}
                }
                ToolbarItem(placement:.cancellationAction) {
                    Button("DOMYŚLNE") {settings=HudMotion600.Settings()}
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of:settings) { _,newValue in
            if newValue.save() {onChange(newValue)}
        }
    }
}
