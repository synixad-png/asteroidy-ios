import SwiftUI

/// Independent, source-default-safe PC580 first-person viewmodel calibration.
/// No GLB geometry, hangar lighting, physics or H71 drone state is modified.
struct H55FPSCalibration580:View {
    @ObservedObject var loader:H55SceneModel580
    let dismiss:()->Void
    @State private var hand=0
    private let labels=["X — POZIOMO","Y — PIONOWO","Z — GŁĘBOKOŚĆ",
                        "OBRÓT X","OBRÓT Y","OBRÓT Z","SKALA"]
    private var target:H55FPSSettings580.Target {
        if loader.fpsCalibration.mode == .weapon {return .weapon}
        return hand == 0 ? .left : .right
    }
    private func range(_ axis:Int)->ClosedRange<Double> {
        let limit=H55FPSSettings580.limits(axis)
        return Double(limit.lowerBound)...Double(limit.upperBound)
    }
    var body:some View {
        GeometryReader { viewport in
            let compact=viewport.size.height<480
            ZStack {
                Color.black.opacity(0.78).ignoresSafeArea()
                ScrollView {
                    VStack(alignment:.leading,spacing:compact ? 8:13) {
                        Text("H55 // KALIBRACJA MODELI")
                            .font(.system(size:compact ? 17:22,weight:.heavy,design:.monospaced))
                            .foregroundStyle(.white)
                        Text("ZMIANY POZYCJI, KĄTA I SKALI · ZAPIS AUTOMATYCZNY")
                            .font(.system(size:10,design:.monospaced))
                            .foregroundStyle(.gray)
                        if loader.fpsCalibration.mode == .gloves {
                            Text(loader.fpsCalibration.model == .tripo
                                 ? "ORYGINALNE RĘCE: TRIPO"
                                 : "ORYGINALNE RĘCE: MONOLIT")
                                .font(.system(size:12,weight:.semibold,design:.monospaced))
                            Picker("DŁOŃ",selection:$hand) {
                                Text("LEWA").tag(0)
                                Text("PRAWA").tag(1)
                            }.pickerStyle(.segmented)
                        } else {
                            Text("ORYGINALNA BROŃ: EXP-01")
                                .font(.system(size:12,weight:.semibold,design:.monospaced))
                        }
                        ForEach(0..<7,id:\.self) { axis in
                            let current=loader.fpsCalibration.pose(target)[axis]
                            HStack {
                                Text(labels[axis])
                                Spacer()
                                Text("\(current)\(axis == 6 ? "%" : axis >= 3 ? "°" : " cm")")
                                    .monospacedDigit()
                            }.font(.system(size:11,weight:.medium,design:.monospaced))
                            Slider(value:Binding(
                                get:{Double(loader.fpsCalibration.pose(target)[axis])},
                                set:{loader.setFPSCalibration(target,
                                            component:axis,value:Int($0.rounded()))}),
                                in:range(axis),step:1)
                            .tint(Color(red:0.89,green:0.67,blue:0.31))
                            .accessibilityIdentifier("h55-fps-calibration-axis-\(axis)")
                        }
                        HStack(spacing:10) {
                            Button("PRZYWRÓĆ ORYGINAŁ") {
                                loader.resetFPSCalibration(target)
                            }
                            Button("WRÓĆ DO PAUZY") {dismiss()}
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size:12,weight:.semibold,design:.monospaced))
                    }
                    .padding(compact ? 14:22)
                    .frame(maxWidth:550)
                    .background(Color(red:0.02,green:0.05,blue:0.09))
                    .overlay(Rectangle().stroke(
                        Color(red:0.24,green:0.38,blue:0.44),lineWidth:1))
                    .frame(maxWidth:.infinity)
                }
            }
        }
        .accessibilityIdentifier("h55-fps-calibration-panel")
    }
}
