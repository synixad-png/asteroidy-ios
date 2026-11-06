import SwiftUI

/// Stage C: actual source CARBONIS / C279 scene reached from mission selection.
///
/// This screen renders the genuine 270249-triangle indexed planet, with the
/// same audited material buffers and three original textures as in the atlas.
/// It is *not* a replacement for Game.StartHubMission261, the real Wave(),
/// spherical ship flight or PC mission success/defeat. No fake enemies,
/// completion flags, reward or saved mission progress are generated.
struct Sector01Scene568: View {
    let entry: Sector01Entry568
    let returnToAtlas: () -> Void

    @State private var yaw: Float = 0
    @State private var pitch: Float = 0
    @State private var anchorYaw: Float = 0
    @State private var anchorPitch: Float = 0
    @State private var dragging = false

    // This is the genuine CPU height-map lookup, not active ship collisions.
    // Availability also requires SHA-256 of the original C279 height bytes.
    private static let sourceHeightProbe277: Float? = {
        guard Sector01CarbonisPreview568.isAvailable,
              let url=Bundle.main.url(forResource:"Sector01CarbonisHeightMap",withExtension:"dat")
                ?? Bundle.main.url(forResource:"Sector01CarbonisHeightMap",
                                   withExtension:"dat",subdirectory:"Assets"),
              let data=try? Data(contentsOf:url),
              let surface=CarbonisSurface277(data:data)
        else { return nil }
        return surface.surfaceRadius(x:1,y:0,z:0)
    }()

    var body: some View {
        GeometryReader { geo in
            let compact=geo.size.height < 550
            ZStack {
                Color(red:0.006,green:0.018,blue:0.035)
                    .ignoresSafeArea()
                Sector01CarbonisPreview568(yawOffset:yaw,pitchOffset:pitch)
                    .frame(width:geo.size.width,height:geo.size.height)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance:3)
                        .onChanged { gesture in
                            if !dragging {
                                anchorYaw=yaw
                                anchorPitch=pitch
                                dragging=true
                            }
                            let sensitivity:Float=0.005
                            yaw=anchorYaw+Float(gesture.translation.width)*sensitivity
                            pitch=max(-1.0,min(1.0,
                                anchorPitch+Float(gesture.translation.height)*sensitivity))
                        }
                        .onEnded { _ in dragging=false })
                    .accessibilityIdentifier("sector01-source-carbonis-gpu")
                    .accessibilityLabel(
                        "Oryginalna planeta CARBONIS 3D, obróć palcem")
                VStack(spacing:0) {
                    HStack(spacing:12) {
                        VStack(alignment:.leading,spacing:3) {
                            Text("SEKTOR 01 / CARBONIS")
                                .font(.system(size:compact ? 14 : 20,
                                              weight:.bold,design:.monospaced))
                                .foregroundStyle(.orange)
                            Text("ŹRÓDŁOWA PLANETA v568 / C279")
                                .font(.system(size:compact ? 9 : 12,
                                              design:.monospaced))
                                .foregroundStyle(.cyan)
                        }
                        Spacer()
                        Button("WRÓĆ DO MAPY") {
                            returnToAtlas()
                        }
                        .font(.system(size:compact ? 10 : 13,
                                      weight:.bold,design:.monospaced))
                        .padding(11)
                        .foregroundStyle(.white)
                        .background(Color(red:0.05,green:0.15,blue:0.22),
                                    in:RoundedRectangle(cornerRadius:6))
                        .accessibilityIdentifier("sector01-back-to-atlas")
                    }
                    .padding(.horizontal,compact ? 12 : 24)
                    .padding(.vertical,8)
                    .background(.black.opacity(0.82))

                    Spacer()

                    HStack {
                        VStack(alignment:.leading,spacing:4) {
                            Text("270 249 TRÓJKĄTÓW / 2 MATERIAŁY")
                                .foregroundStyle(.cyan)
                            Text(Self.sourceHeightProbe277.map {
                                "MAPA TERENU 512×256 / ODCZYT +X: " +
                                String(format:"%.5f",$0)
                            } ?? "MAPA TERENU C279: NIEDOSTĘPNA")
                                .foregroundStyle(.cyan)
                            Text("GEOMETRIA I TEKSTURY: ORYGINAŁ WINDOWS v568")
                                .foregroundStyle(.white)
                            Text("GEST: PRZECIĄGNIJ, ABY OBRÓCIĆ PLANETĘ")
                                .foregroundStyle(.orange)
                        }
                        Spacer()
                    }
                    .font(.system(size:compact ? 9 : 11,design:.monospaced))
                    .padding(.horizontal,compact ? 12 : 24)
                    .padding(.vertical,7)
                    .background(.black.opacity(0.75))

                    Text("ETAP C: WIDOK PRAWDZIWEJ PLANETY. LOT, FALA WALKI, KOLIZJE TERENU I UKOŃCZENIE MISJI SĄ JESZCZE W TRAKCIE PORTOWANIA.")
                        .font(.system(size:compact ? 9 : 11,design:.monospaced))
                        .foregroundStyle(.yellow)
                        .frame(maxWidth:.infinity,alignment:.leading)
                        .padding(.horizontal,compact ? 12 : 24)
                        .padding(.vertical,8)
                        .background(.black.opacity(0.91))
                        .accessibilityIdentifier("sector01-stage-c-scope")
                }
            }
        }
        .accessibilityIdentifier("sector01-real-source-scene")
    }
}
