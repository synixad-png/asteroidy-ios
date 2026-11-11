import Foundation
import SwiftUI
import UIKit

/// A playable native METAL PC602 orbital pilot page, not a screenshot,
/// HTML/WebView or W3 miniature. Actual 67 geodesic controls come from
/// PC602HomeWorldDriver291 and the EXISTING PC586 key/pad profile.
/// The existing H55ScenePage580 is shown full-screen after its physical
/// 43.2m source gate, without spawning a duplicate H55 model.
struct PC602HomeWorldPage291:View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var driver:PC602HomeWorldDriver291
    let onExitToW3:()->Void
    let onEnterMission:(Int)->Void
    private let gold=Color(red:0.89,green:0.67,blue:0.31)
    private let cyan=Color(red:0.39,green:0.75,blue:0.79)

    var body:some View {
        GeometryReader { screen in
            ZStack {
                Color(red:0.008,green:0.018,blue:0.03).ignoresSafeArea()
                if driver.presentingH55 {
                    H55ScenePage580(dismiss:{driver.exitH55()},
                                    exitTitle:"POWRÓT NA ORBITĘ")
                        .ignoresSafeArea()
                        .accessibilityIdentifier("pc602-real-h55-from-orbit")
                } else if let flight=driver.readFlight() {
                    PC602HomeScene291(
                        flight:flight,
                        onFrame:{dt in driver.frame(dt:dt)},
                        onRendererError:{error in
                            driver.reportRendererError(error)
                        })
                        .ignoresSafeArea()
                        .accessibilityIdentifier("pc602-orbit-live-metal")
                    overlay(screen:screen)
                } else {
                    VStack(spacing:12) {
                        Text("PC602 / ORBITA NIEGOTOWA")
                            .font(.system(size:16,weight:.bold,
                                          design:.monospaced))
                        Text(driver.error ?? "Brak zweryfikowanego H290")
                            .font(.system(size:12,design:.monospaced))
                            .multilineTextAlignment(.center)
                        Button("POWRÓT DO W3") {
                            driver.stop()
                            onExitToW3()
                        }
                    }
                    .foregroundStyle(gold)
                }
            }
            .frame(width:screen.size.width,height:screen.size.height)
        }
        .onAppear {
            driver.setSuspended(scenePhase != .active)
        }
        .onDisappear {
            driver.setSuspended(true)
            driver.setTouch(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0))
        }
        .onChange(of:scenePhase) { phase in
            driver.setSuspended(phase != .active)
        }
        .background(alignment:.topLeading) {
            if !driver.presentingH55 {
                SourceKeyboardCapture586 { key,held in
                    SourceHardwareInput586.shared.changeKey(key,pressed:held)
                }
                .frame(width:1,height:1)
                .opacity(0.01)
                .accessibilityHidden(true)
            }
        }
        .accessibilityIdentifier("pc602-orbit-real-gameplay-page")
    }

    private func panel(_ label:String)->some View {
        Text(label)
            .font(.system(size:11,weight:.semibold,design:.monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal,10)
            .frame(minHeight:38)
            .background(Color.black.opacity(0.72))
            .overlay(Rectangle().stroke(cyan.opacity(0.40),lineWidth:1))
    }

    @ViewBuilder private func overlay(screen:GeometryProxy)->some View {
        let compact=screen.size.height<450
        let leftInset=screen.safeAreaInsets.leading+12
        let rightInset=screen.safeAreaInsets.trailing+12
        let topInset=screen.safeAreaInsets.top+8
        let bottomInset=screen.safeAreaInsets.bottom+10
        VStack(spacing:0) {
            HStack(alignment:.top,spacing:8) {
                VStack(alignment:.leading,spacing:5) {
                    Text("ASTEROIDY / PC v602 / ORBITA")
                        .font(.system(size:compact ? 10:12,weight:.bold,
                                      design:.monospaced))
                        .foregroundStyle(gold)
                    HStack(spacing:6) {
                        panel("PRĘDKOŚĆ \(Int(driver.hud.speed))")
                        panel("SEKTOR \(String(format:"%02d",driver.hud.target))")
                        panel("DYST. \(Int(driver.hud.sectorDistance)) m")
                    }
                }
                Spacer(minLength:0)
                VStack(alignment:.trailing,spacing:5) {
                    Text("WRAK H55: \(Int(driver.hud.dockDistance)) m")
                        .font(.system(size:compact ? 10:12,weight:.bold,
                                      design:.monospaced))
                        .foregroundStyle(driver.hud.canDock ? .green : .white)
                    panel("MISJE \(driver.hud.completed) / 26")
                }
            }
            .padding(.leading,leftInset)
            .padding(.trailing,rightInset)
            .padding(.top,topInset)
            Spacer(minLength:0)
            if let error=driver.error {
                Text(error)
                    .font(.system(size:11,weight:.semibold,
                                  design:.monospaced))
                    .foregroundStyle(.orange)
                    .padding(10)
                    .background(Color.black.opacity(0.88))
                    .frame(maxWidth:screen.size.width*0.72)
            }
            HStack(alignment:.bottom) {
                OrbitTouchStick291(title:"LOT / RUCH",diameter:compact ? 116:148) {
                    driver.setTouch(move:$0)
                }
                Spacer(minLength:4)
                VStack(spacing:6) {
                    Button(driver.paused ? "WZNÓW":"PAUZA") {
                        driver.setPaused(!driver.paused)
                    }
                    .accessibilityIdentifier("pc602-orbit-pause")
                    Button("CEL +") {driver.cycleMission()}
                        .disabled(driver.paused)
                        .accessibilityIdentifier("pc602-orbit-next-sector")
                    Button("DOKUJ H55") {_=driver.requestH55()}
                        .disabled(!driver.hud.canDock || driver.paused)
                        .accessibilityIdentifier("pc602-orbit-dock")
                    Button("WEJDŹ W MISJĘ 01") {
                        let available=driver.requestAuthoredMission()
                        if available==1 {onEnterMission(available)}
                    }
                    .disabled(driver.hud.missionEntrance != 1 || driver.paused)
                    .accessibilityIdentifier("pc602-orbit-enter-carbonis01")
                    Button("MENU W3") {
                        driver.stop()
                        onExitToW3()
                    }
                    .accessibilityIdentifier("pc602-orbit-return-w3")
                }
                .font(.system(size:compact ? 10:12,weight:.bold,
                              design:.monospaced))
                .foregroundStyle(gold)
                .buttonStyle(.plain)
                .padding(.horizontal,9)
                .padding(.vertical,5)
                .background(Color.black.opacity(0.76))
                .overlay(Rectangle().stroke(gold.opacity(0.55),lineWidth:1))
                Spacer(minLength:4)
                OrbitTouchStick291(title:"CELOWANIE",
                                   diameter:compact ? 116:148) {
                    driver.setTouch(aim:$0)
                }
            }
            .padding(.leading,leftInset)
            .padding(.trailing,rightInset)
            .padding(.bottom,bottomInset)
        }
        .allowsHitTesting(true)
        .accessibilityIdentifier("pc602-orbit-live-touch-hud")
    }
}

/// One clamp-to-unit touch stick. The same native vector feeds the
/// unchanged PC602HomeFlightInput291; touch never overrides a hardware
/// binding until the player actually drags this control.
private struct OrbitTouchStick291:View {
    let title:String
    let diameter:CGFloat
    let onMove:(Vec2)->Void
    @State private var movement=CGSize.zero
    private let ring=Color(red:0.39,green:0.75,blue:0.79)

    var body:some View {
        VStack(spacing:4) {
            Text(title)
                .font(.system(size:10,weight:.bold,design:.monospaced))
                .foregroundStyle(ring)
            GeometryReader { surface in
                let r=min(surface.size.width,surface.size.height)/2
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.55))
                        .overlay(Circle().stroke(ring.opacity(0.60),lineWidth:2))
                    Circle()
                        .fill(ring.opacity(0.65))
                        .frame(width:r*0.40,height:r*0.40)
                        .offset(movement)
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance:0)
                    .onChanged { drag in
                        let dx=drag.location.x-r
                        let dy=drag.location.y-r
                        let distance=max(0.0001,hypot(dx,dy))
                        let fraction=min(1,r*0.85/distance)
                        movement=CGSize(width:dx*fraction,height:dy*fraction)
                        onMove(Vec2(x:Float(dx*fraction/(r*0.85)),
                                    y:Float(dy*fraction/(r*0.85))))
                    }
                    .onEnded {_ in
                        movement=.zero
                        onMove(Vec2(x:0,y:0))
                    })
            }
            .frame(width:diameter,height:diameter)
        }
        .frame(width:diameter)
        .accessibilityIdentifier(title=="CELOWANIE"
           ? "pc602-touch-aim":"pc602-touch-move")
    }
}
