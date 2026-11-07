import SwiftUI

/// Windows v568 Game.BeginLevelIntro -> Mode.Intro -> Game.FinishIntro.
/// The render scene and ship motion are genuine IntroOrbit41/GpuIntro41;
/// this UI is the original native W3 mission-arrival overlay (v319).
/// Only sectors with verified playable iOS geometry can be entered.
struct MissionCinematic568:View {
    let sector:Int
    @ObservedObject var input:FlightInput
    let onComplete:()->Void
    let onCancel:()->Void
    @State private var committed=false
    @State private var skipping=false

    private var progress:Float {
        min(1,max(0,input.introProgress41/IntroOrbit41.duration))
    }
    private var planetName:String {
        MissionCatalog568.title(for:sector) ?? "SEKTOR"
    }
    private func finish() {
        guard !committed, input.rendererError == nil else {return}
        committed=true
        onComplete()
    }
    private func skip() {
        // Windows Program.cs gamepad skip after 0.6 seconds. Touch
        // behaves as the original A/Enter action, never as a fire button.
        guard input.introProgress41>=0.6, !committed else {return}
        skipping=true
        finish()
    }
    var body:some View {
        GeometryReader { geo in
            let compact=geo.size.height<540
            let side:CGFloat=compact ? 18 : 33
            let gold=Color(red:0.89,green:0.67,blue:0.31)
            let cyan=Color(red:0.39,green:0.75,blue:0.79)
            ZStack {
                // This is the REAL 3D Intro41 renderer, not an image or
                // a W3 menu planet placed over a static background.
                MetalScene(input:input)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("intro41-source-3d-metal-scene")

                VStack(alignment:.leading,spacing:0) {
                    HStack(spacing:10) {
                        Text("SYNIXAD / ROZPOCZĘCIE MISJI")
                            .foregroundStyle(gold)
                            .font(.system(size:compact ? 12 : 18,weight:.bold,
                                          design:.monospaced))
                        Spacer()
                        Text(String(format:"SEKTOR %02d / PRZELOT ORBITALNY",sector))
                            .font(.system(size:compact ? 9 : 13,
                                          design:.monospaced))
                            .foregroundStyle(cyan)
                    }
                    .padding(.horizontal,side)
                    .frame(height:compact ? 50 : 74)
                    .frame(maxWidth:.infinity)
                    .background(Color.black.opacity(0.70))
                    .overlay(alignment:.bottom) {
                        Rectangle().fill(gold.opacity(0.7)).frame(height:1)
                    }

                    VStack(alignment:.leading,spacing:4) {
                        Text("CEL OPERACJI")
                            .foregroundStyle(gold)
                            .font(.system(size:compact ? 10 : 12,
                                          design:.monospaced))
                        Text(planetName)
                            .foregroundStyle(.white)
                            .font(.system(size:compact ? 15 : 20,
                                          weight:.semibold,design:.monospaced))
                        Text(String(format:"SEKTOR %02d",sector))
                            .foregroundStyle(cyan)
                            .font(.system(size:compact ? 10 : 13,
                                          design:.monospaced))
                    }
                    .padding(compact ? 10 : 16)
                    .frame(maxWidth:compact ? 235 : 335,alignment:.leading)
                    .background(Color(red:0.016,green:0.050,blue:0.078)
                        .opacity(0.80))
                    .overlay(Rectangle().stroke(cyan.opacity(0.48),lineWidth:1))
                    .padding(.leading,side)
                    .padding(.top,compact ? 12 : 26)

                    Spacer(minLength:0)

                    if let error=input.rendererError {
                        HStack {
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.system(size:12,weight:.bold,
                                              design:.monospaced))
                            Spacer()
                            Button("WRÓĆ DO MAPY") { onCancel() }
                                .foregroundStyle(gold)
                        }
                        .padding(14)
                        .background(.black.opacity(0.9))
                    }
                    VStack(alignment:.leading,spacing:8) {
                        HStack {
                            Text("PRZELOT / \(Int(progress*100))%")
                                .foregroundStyle(gold)
                            Spacer()
                            Text("\(Int(min(IntroOrbit41.duration,input.introProgress41))) / 16 s")
                                .foregroundStyle(cyan)
                        }
                        GeometryReader { bar in
                            ZStack(alignment:.leading) {
                                Rectangle().fill(cyan.opacity(0.23))
                                Rectangle().fill(gold)
                                    .frame(width:bar.size.width*CGFloat(progress))
                            }
                        }
                        .frame(height:7)
                        HStack {
                            Text("RZECZYWISTA SCENA 3D / INTRO41")
                                .foregroundStyle(cyan.opacity(0.8))
                            Spacer()
                            Button("POMIŃ / ENTER · A") {skip()}
                                .foregroundStyle(.white)
                                .disabled(input.introProgress41<0.6 || committed)
                                .accessibilityIdentifier("intro41-skip-to-real-mission")
                        }
                    }
                    .font(.system(size:compact ? 9 : 12,
                                  weight:.semibold,design:.monospaced))
                    .padding(.horizontal,side)
                    .padding(.vertical,compact ? 12 : 20)
                    .background(Color.black.opacity(0.78))
                    .overlay(alignment:.top) {
                        Rectangle().fill(gold.opacity(0.65)).frame(height:1)
                    }
                }

                // Windows Intro41.DrawIntro41: source fade in 0.5 s,
                // fade out during the last 0.65 s when transitions off.
                // It never changes the flight trajectory or mission state.
                let t=input.introProgress41
                let fade=t<0.5 ? 1-t/0.5 :
                    t>IntroOrbit41.duration-0.65
                    ? (t-(IntroOrbit41.duration-0.65))/0.65 : 0
                Color.black.opacity(Double(min(1,max(0,fade))))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .frame(width:geo.size.width,height:geo.size.height)
        }
        .onChange(of:input.introProgress41) { value in
            if value>=IntroOrbit41.duration-0.00001 {finish()}
        }
        .onDisappear {
            input.gameplayPaused=true
            input.releaseHeldControls()
        }
        .accessibilityIdentifier("mission-intro41-cinematic-568")
    }
}
