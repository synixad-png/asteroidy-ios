import SwiftUI

/// Temporary animated sector-05 visual preview. The existing source
/// Metal renderer owns the 5s morph clock and triple GPU buffers.
/// This page neither advances campaign progress nor awards currency.
struct AnimatedPlanetTestPage556:View {
    @ObservedObject var input:FlightInput
    let onExit:()->Void

    var body:some View {
        ZStack(alignment:.top) {
            MetalScene(input:input).ignoresSafeArea()
            VStack(spacing:0) {
                HStack(spacing:12) {
                    VStack(alignment:.leading,spacing:3) {
                        Text("BOREAS / SEKTOR 05")
                            .font(.system(size:16,weight:.bold,design:.monospaced))
                            .foregroundStyle(Color(red:0.89,green:0.67,blue:0.31))
                        Text("PLANETA TESTOWA / ANIMACJA MORPH GLB")
                            .font(.system(size:10,weight:.medium,design:.monospaced))
                            .foregroundStyle(.cyan)
                    }
                    Spacer(minLength:0)
                    Button("WRÓĆ DO ATLASU") {onExit()}
                        .font(.system(size:12,weight:.bold,design:.monospaced))
                        .foregroundStyle(.black)
                        .frame(minHeight:44)
                        .padding(.horizontal,12)
                        .background(Color(red:0.39,green:0.75,blue:0.79))
                        .accessibilityIdentifier("boreas-test-return-atlas")
                }
                .padding(.horizontal,18)
                .padding(.top,12)
                .padding(.bottom,8)
                .background(Color(red:0.006,green:0.027,blue:0.047).opacity(0.92))
                Spacer()
                if let error=input.rendererError {
                    Text(error)
                        .font(.system(size:11,weight:.bold,design:.monospaced))
                        .foregroundStyle(.orange)
                        .padding(8)
                        .background(.black.opacity(0.8))
                } else {
                    Text("TYLKO TEST MODELU 3D · NIE JEST MISJĄ · BEZ ZMIAN POSTĘPU")
                        .font(.system(size:10,weight:.medium,design:.monospaced))
                        .foregroundStyle(.cyan)
                        .padding(8)
                        .background(.black.opacity(0.72))
                }
            }
        }
        .accessibilityIdentifier("boreas-sector05-animated-visual-test")
    }
}
