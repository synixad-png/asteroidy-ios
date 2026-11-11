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
    @State private var showingAtlas330=false
    @State private var previouslyPaused330=false
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
                        onProjectiles:{driver.readProjectiles()},
                        onRendererError:{error in
                            driver.reportRendererError(error)
                        })
                        .ignoresSafeArea()
                        .accessibilityIdentifier("pc602-orbit-live-metal")
                    overlay(screen:screen)
                    if showingAtlas330 {atlasPanel(screen:screen)}
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

    private func dismissAtlas330() {
        showingAtlas330=false
        driver.setPaused(previouslyPaused330)
    }

    /// Original PC602 OrbitHud330: eight columns, four rows, 26 authored
    /// source mission numbers, dark 170/165-alpha locked/unlocked cards.
    /// On 932pt iPhone the 29px source tiles are too small for touch, so
    /// they are enlarged ONLY while the modal atlas is explicitly open.
    /// This is the exact same CampaignStore556, NOT another save file.
    private func atlasPanel(screen:GeometryProxy)->some View {
        let compact=screen.size.height<450
        let cell:CGFloat=compact ? 40:44
        return ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture {dismissAtlas330()}
            VStack(spacing:7) {
                HStack {
                    Text("ATLAS / 26 SEKTORÓW")
                        .font(.system(size:compact ? 12:16,
                                      weight:.bold,design:.monospaced))
                        .foregroundStyle(gold)
                    Spacer()
                    Button("WRÓĆ DO LOTU") {dismissAtlas330()}
                        .foregroundStyle(cyan)
                        .font(.system(size:compact ? 10:13,
                                      weight:.bold,design:.monospaced))
                        .accessibilityIdentifier("pc602-orbit-close-atlas330")
                }
                Text("CEL \(String(format:"%02d",driver.hud.target)) · " +
                     "POSTĘP \(driver.hud.completed)/26")
                    .font(.system(size:10,design:.monospaced))
                    .foregroundStyle(cyan)
                LazyVGrid(columns:Array(repeating:GridItem(.fixed(cell),
                                 spacing:4),count:8),spacing:4) {
                    ForEach(1...26,id:\.self) { level in
                        let finished=PC602HomeFlight291.completed(
                            level,mask:driver.hud.completedMask)
                        let available=PC602HomeFlight291.unlocked(
                            level,mask:driver.hud.completedMask)
                        let selected=level==driver.hud.target
                        Button {
                            if available && driver.selectMission(level) {
                                dismissAtlas330()
                            }
                        } label: {
                            Text(String(format:"%02d",level))
                                .font(.system(size:12,weight:.bold,
                                              design:.monospaced))
                                .foregroundStyle(selected ? gold :
                                    finished ? .green :
                                    available ? cyan : .gray)
                                .frame(width:cell,height:cell)
                                .background(finished
                                    ? Color(red:65/255,green:168/255,
                                            blue:139/255).opacity(174/255)
                                    : available
                                    ? Color(red:28/255,green:75/255,
                                            blue:98/255).opacity(170/255)
                                    : Color(red:17/255,green:30/255,
                                            blue:43/255).opacity(165/255))
                                .overlay(Rectangle().stroke(
                                    selected ? cyan : cyan.opacity(0.12),
                                    lineWidth:selected ? 2:1))
                        }
                        .buttonStyle(.plain)
                        .disabled(!available)
                        .accessibilityIdentifier(
                            "pc602-orbit-sector-\(level)")
                    }
                }
                Text("WYBÓR NIE ZALICZA MISJI · BLOKADY Z KAMPANII PC")
                    .font(.system(size:compact ? 9:11,
                                  design:.monospaced))
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.center)
            }
            .padding(compact ? 12:18)
            .frame(maxWidth:500)
            .background(Color(red:0.008,green:0.028,blue:0.048))
            .overlay(Rectangle().stroke(gold.opacity(0.75),lineWidth:1))
        }
        .zIndex(15)
        .accessibilityIdentifier("pc602-orbit-original-26-tile-atlas330")
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
                    panel("BROŃ \(driver.hud.weaponName) / POCISKI \(driver.hud.projectiles)")
                }
            }
            .padding(.leading,leftInset)
            .padding(.trailing,rightInset)
            .padding(.top,topInset)
            HStack(spacing:12) {
                Text("STREFA \(driver.hud.zone)")
                Text("PUŁAP \(Int(driver.hud.altitude)) m")
                Text("KURS \(Int(abs(driver.hud.courseDegrees)))° " +
                     (driver.hud.courseDegrees<0 ? "W LEWO":"W PRAWO"))
                Spacer(minLength:0)
            }
            .font(.system(size:compact ? 9:11,
                          weight:.semibold,design:.monospaced))
            .foregroundStyle(cyan)
            .padding(.leading,leftInset)
            .padding(.trailing,rightInset)
            .padding(.top,4)
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
                    Button("ATLAS 26") {
                        previouslyPaused330=driver.paused
                        showingAtlas330=true
                        driver.setPaused(true)
                    }
                    .accessibilityIdentifier("pc602-orbit-open-atlas330")
                    Button("CEL +") {driver.cycleMission()}
                        .disabled(driver.paused)
                        .accessibilityIdentifier("pc602-orbit-next-sector")
                    Text("OGIEŃ")
                        .font(.system(size:12,weight:.bold,design:.monospaced))
                        .foregroundStyle(.white)
                        .frame(minWidth:86,minHeight:44)
                        .background(Color(red:0.34,green:0.08,blue:0.08))
                        .overlay(Rectangle().stroke(gold,lineWidth:1))
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance:0)
                            .onChanged {_ in driver.setFiring(true)}
                            .onEnded {_ in driver.setFiring(false)})
                        .accessibilityIdentifier("pc602-orbit-fire")
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
