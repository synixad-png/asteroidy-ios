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
    @ObservedObject var audio:OriginalAudioAV568
    let onExitToW3:()->Void
    let onEnterMission:(Int)->Void
    let onProfileRestored:()->Void
    @State private var showingAtlas330=false
    @State private var previouslyPaused330=false
    @State private var showingSaves61=false
    @State private var previouslyPaused61=false
    @State private var loadingSave61=false
    @State private var saveMessage61=""
    @State private var showingOrbitOptions291=false
    @State private var showingOrbitSettings291=false
    @State private var previouslyPausedOptions291=false
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
                    SourceCombatTouchZones568(
                        onMove:{driver.setTouch(move:$0)},
                        onAim:{driver.setTouch(aim:$0)},
                        onFire:{driver.setFiring($0)})
                    overlay(screen:screen,flight:flight)
                    navigationCue50(screen:screen,flight:flight)
                    if showingAtlas330 {atlasPanel(screen:screen)}
                    if showingSaves61 {savesPanel61(screen:screen)}
                    if showingOrbitOptions291 {orbitOptionsPanel291(screen:screen)}
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
            // SaveManager61.CaptureResume61: persist the last verified
            // 67-pilot state BEFORE UIKit freezes MTKView on background.
            // Disk I/O is on this lifecycle event, never inside draw(in:).
            if phase != .active {
                _=driver.captureResume61()
            }
            driver.setSuspended(phase != .active)
        }
        // Original PC602 MusicAudio.TrackFor(Orbit)=0; engine/shot sound
        // never allocate AVAudioPlayer inside the Metal render callback.
        .onChange(of:driver.hud.enginePower) { _,power in
            audio.sourceEnginePower(power)
        }
        .onChange(of:driver.hud.shotEmissions) { old,next in
            if next>old {
                for _ in old..<next {
                    audio.sourceEffect(driver.hud.weaponSoundCode)
                }
            }
        }
        .onChange(of:driver.paused) { _,state in
            audio.orbitPause602(state)
        }
        .onChange(of:driver.presentingH55) { _,state in
            audio.orbitPause602(state)
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

    /// The original PC602 option/pause action. The same orbital session
    /// stays paused: no competing menu renderer or duplicated state.
    private func openOrbitOptions291() {
        previouslyPausedOptions291=driver.paused
        showingOrbitSettings291=false
        driver.setPaused(true)
        showingOrbitOptions291=true
    }

    private func closeOrbitOptions291() {
        showingOrbitSettings291=false
        showingOrbitOptions291=false
        driver.setPaused(previouslyPausedOptions291)
    }

    private func orbitOptionsPanel291(screen:GeometryProxy)->some View {
        let compact=screen.size.height<450
        return ZStack {
            Color.black.opacity(0.84).ignoresSafeArea()
            VStack(spacing:compact ? 8:14) {
                HStack {
                    Text(showingOrbitSettings291
                        ? "OPCJE / USTAWIENIA"
                        : "OPCJE / PLANETA GŁÓWNA")
                        .font(.system(size:compact ? 14:19,
                                      weight:.bold,design:.monospaced))
                        .foregroundStyle(gold)
                    Spacer(minLength:8)
                    Button(showingOrbitSettings291 ? "WRÓĆ DO OPCJI":"KONTYNUUJ") {
                        if showingOrbitSettings291 {showingOrbitSettings291=false}
                        else {closeOrbitOptions291()}
                    }
                    .accessibilityIdentifier("pc602-orbit-options-back")
                }
                if showingOrbitSettings291 {
                    // Reuse the authoritative W3 game settings.
                    CarbonisVisualSettingsPanel568(
                        compact:compact,initialTab:4)
                        .frame(maxWidth:.infinity,maxHeight:.infinity)
                } else {
                    Button("USTAWIENIA") {showingOrbitSettings291=true}
                        .accessibilityIdentifier("pc602-orbit-options-settings")
                    Button("ZAPISZ LOT") {
                        showingOrbitOptions291=false
                        openSaves61(load:false,
                                    restorePaused:previouslyPausedOptions291)
                    }
                    .accessibilityIdentifier("pc602-orbit-save61")
                    Button("WCZYTAJ LOT") {
                        showingOrbitOptions291=false
                        openSaves61(load:true,
                                    restorePaused:previouslyPausedOptions291)
                    }
                    .accessibilityIdentifier("pc602-orbit-load61")
                    Button("POWRÓT DO MENU GŁÓWNEGO") {
                        showingOrbitSettings291=false
                        showingOrbitOptions291=false
                        onExitToW3()
                    }
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("pc602-orbit-return-w3")
                }
            }
            .font(.system(size:compact ? 13:16,weight:.bold,
                          design:.monospaced))
            .foregroundStyle(cyan)
            .buttonStyle(.plain)
            .padding(compact ? 14:22)
            .frame(maxWidth:720,
                   maxHeight:showingOrbitSettings291 ? .infinity:nil)
            .background(Color(red:0.008,green:0.028,blue:0.048))
            .overlay(Rectangle().stroke(gold.opacity(0.8),lineWidth:1))
            .padding(12)
        }
        .zIndex(40)
        .accessibilityIdentifier("pc602-orbit-options291")
    }

    private func openSaves61(load:Bool,restorePaused:Bool?=nil) {
        // When opened from OPCJE, inherit the flight's state BEFORE
        // the menu paused it. Dismissing the slots must restore flight.
        previouslyPaused61=restorePaused ?? driver.paused
        loadingSave61=load
        saveMessage61=""
        driver.setPaused(true)
        showingSaves61=true
    }

    private func dismissSaves61() {
        showingSaves61=false
        driver.setPaused(previouslyPaused61)
    }

    /// SaveManager61 presents three native slots; the original H290 session
    /// and canonical profile records are persisted together, never a
    /// duplicate ship, mission completion or separate graphics renderer.
    private func savesPanel61(screen:GeometryProxy)->some View {
        let compact=screen.size.height<450
        return ZStack {
            Color.black.opacity(0.76).ignoresSafeArea()
            VStack(alignment:.leading,spacing:9) {
                HStack {
                    Text(loadingSave61 ? "WCZYTAJ ZAPIS / 3 SLOTY" :
                         "ZAPISZ ORBITĘ / 3 SLOTY")
                        .font(.system(size:compact ? 13:16,weight:.bold,
                                      design:.monospaced))
                        .foregroundStyle(gold)
                    Spacer()
                    Button("WRÓĆ") {dismissSaves61()}
                        .foregroundStyle(cyan)
                }
                ForEach(0..<3,id:\.self) { slot in
                    let record=try? PC602OrbitSave61.read(slot:slot)
                    let text=record.map { state in
                        "MISJA \(String(format:"%02d",state.target)) · " +
                        Date(timeIntervalSince1970:state.savedAt).formatted(
                            date:.numeric,time:.shortened)
                    } ?? "PUSTY SLOT"
                    Button {
                        if loadingSave61 {
                            if driver.loadOrbitSlot61(slot) {
                                onProfileRestored()
                                dismissSaves61()
                            } else {saveMessage61="WCZYTANIE NIEUDANE"}
                        } else {
                            if driver.saveOrbitSlot61(slot) {
                                saveMessage61="ZAPISANO SLOT \(slot+1)"
                            } else {saveMessage61="ZAPIS NIEUDANY"}
                        }
                    } label: {
                        HStack {
                            Text("SLOT \(slot+1)")
                                .font(.system(size:compact ? 12:15,
                                              weight:.bold,design:.monospaced))
                            Spacer(minLength:6)
                            Text(text)
                                .font(.system(size:compact ? 10:12,
                                              design:.monospaced))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Color(red:0.035,green:0.08,blue:0.12))
                        .overlay(Rectangle().stroke(cyan.opacity(0.6)))
                    }
                    .disabled(loadingSave61 && record == nil)
                    .accessibilityIdentifier("pc602-orbit-save61-slot-\(slot)")
                }
                if !saveMessage61.isEmpty {
                    Text(saveMessage61)
                        .font(.system(size:12,design:.monospaced))
                        .foregroundStyle(gold)
                }
            }
            .padding(14)
            .frame(maxWidth:580)
            .background(Color(red:0.008,green:0.028,blue:0.048))
            .overlay(Rectangle().stroke(gold.opacity(0.7)))
            .padding(12)
        }
        .zIndex(16)
        .accessibilityIdentifier("pc602-orbit-three-slot-saves61")
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

    // PC602 Orbit50.DrawOrbit50: unfilled navigation readouts over the
    // live world and a single contextual right-hand interaction key.
    /// Read-only source OrbitHud330 persistent atlas at its original
    /// upper-right virtual 1280x720 position; the actual selectable
    /// touch atlas remains the existing accessible overlay.
    private func compactAtlas330(scale:Float)->some View {
        let width:CGFloat=29*CGFloat(scale)
        let height:CGFloat=22*CGFloat(scale)
        let gapX:CGFloat=3*CGFloat(scale)
        let gapY:CGFloat=4*CGFloat(scale)
        return VStack(alignment:.trailing,spacing:2) {
            ForEach(0..<4,id:\.self) { row in
                HStack(spacing:gapX) {
                    ForEach(0..<8,id:\.self) { column in
                        let sector=row*8+column+1
                        if sector<=26 {
                            let cleared=PC602HomeFlight291.completed(
                                sector,mask:driver.hud.completedMask)
                            let available=PC602HomeFlight291.unlocked(
                                sector,mask:driver.hud.completedMask)
                            Text(String(format:"%02d",sector))
                                .font(.system(size:max(8,10*CGFloat(scale)),
                                              weight:.bold,design:.monospaced))
                                .foregroundStyle(sector==driver.hud.target
                                    ? gold:cleared ? .green:available ? cyan : .gray)
                                .frame(width:width,height:height)
                                .background(cleared
                                    ? Color(red:65/255,green:168/255,blue:139/255)
                                        .opacity(174/255)
                                    : available
                                    ? Color(red:28/255,green:75/255,blue:98/255)
                                        .opacity(170/255)
                                    : Color(red:17/255,green:30/255,blue:43/255)
                                        .opacity(165/255))
                                .overlay(Rectangle().stroke(
                                    sector==driver.hud.target ? cyan :
                                    Color.clear,lineWidth:1))
                        } else {
                            Color.clear.frame(width:width,height:height)
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .accessibilityIdentifier("pc602-orbit-compact-26-atlas330")
    }

    private func statusText(_ value:String,_ compact:Bool)->some View {
        Text(value)
            .font(.system(size:compact ? 10:12,weight:.semibold,
                          design:.monospaced))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    private func enterAvailable()->Bool {
        !driver.paused && (driver.hud.canDock ||
                          driver.hud.missionEntrance==1)
    }

    private func enterSourceLocation() {
        // Original Program.cs Enter: dock takes precedence over a beacon.
        if driver.hud.canDock {
            _=driver.requestH55()
        } else {
            let sector=driver.requestAuthoredMission()
            if sector==1 {onEnterMission(sector)}
            // No fabricated mission 2...26 before its actual PC port.
        }
    }

    @ViewBuilder private func navigationCue50(
        screen:GeometryProxy,flight:PC602HomeFlight291)->some View {
        if let arrow=PC602OrbitNavigation50.arrow(
            flight:flight,width:Float(screen.size.width),
            height:Float(screen.size.height)) {
            let x=CGFloat(arrow.x), y=CGFloat(arrow.y)
            let dx=CGFloat(arrow.dx),dy=CGFloat(arrow.dy)
            Path { path in
                let tip=CGPoint(x:x+dx*14,y:y+dy*14)
                let left=CGPoint(x:x-dx*9-dy*9,y:y-dy*9+dx*9)
                let right=CGPoint(x:x-dx*9+dy*9,y:y-dy*9-dx*9)
                path.move(to:left)
                path.addLine(to:tip)
                path.addLine(to:right)
                path.addLine(to:left)
            }
            .stroke(cyan,lineWidth:2.4)
            .allowsHitTesting(false)
            Text("CEL \(String(format:"%02d",driver.hud.target))")
                .font(.system(size:11,weight:.bold,design:.monospaced))
                .foregroundStyle(cyan)
                .position(x:x,y:y+26)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder private func overlay(
        screen:GeometryProxy,flight:PC602HomeFlight291)->some View {
        let compact=screen.size.height<450
        let leading=screen.safeAreaInsets.leading+12
        let trailing=screen.safeAreaInsets.trailing+12
        let top=screen.safeAreaInsets.top+8
        let bottom=screen.safeAreaInsets.bottom+9
        VStack(spacing:0) {
            HStack(alignment:.top,spacing:8) {
                VStack(alignment:.leading,spacing:3) {
                    Text("ATLAS \(String(format:"%02d",driver.hud.target)) · VANGUARD")
                        .font(.system(size:compact ? 12:15,weight:.bold,
                                      design:.monospaced))
                        .foregroundStyle(gold)
                    statusText("CEL: \(MissionCatalog568.title(for:driver.hud.target) ?? "")",compact)
                    Text("ODL: \(Int(driver.hud.sectorDistance)) m")
                        .foregroundStyle(cyan)
                    Text("KURS: \(Int(abs(driver.hud.courseDegrees)))° " +
                         (driver.hud.courseDegrees<0 ? "W LEWO" : "W PRAWO"))
                        .foregroundStyle(.white)
                    if driver.hud.selectedCompleted {
                        Text("UKOŃCZONA · MOŻNA POWTÓRZYĆ")
                            .foregroundStyle(.green)
                    }
                }
                .font(.system(size:compact ? 10:12,weight:.semibold,
                              design:.monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                Spacer(minLength:4)
                VStack(alignment:.trailing,spacing:4) {
                    Text("POSTĘP \(driver.hud.completed) / 26")
                        .foregroundStyle(cyan)
                    statusText("STREFA \(driver.hud.zone)",compact)
                    statusText("PUŁAP \(Int(driver.hud.altitude)) m",compact)
                    statusText("PRĘDKOŚĆ \(Int(driver.hud.speed))",compact)
                    // PC602 OrbitHud330: 8 columns x 4 rows, 29x22
                    // source tiles at x=1001,y=55 in virtual 1280x720.
                    // On small landscape displays the old touch-sized
                    // panel remains available via ATLAS instead.
                    if screen.size.width >= 680 && screen.size.height >= 320 {
                        compactAtlas330(scale:min(1,Float(screen.size.width/1280)))
                    }
                    Button("OPCJE") {openOrbitOptions291()}
                        .font(.system(size:compact ? 14:17,
                                      weight:.bold,design:.monospaced))
                        .frame(minWidth:100,minHeight:44)
                        .foregroundStyle(.white)
                        .background(Color(red:0.05,green:0.15,blue:0.22))
                        .overlay(Rectangle().stroke(gold,lineWidth:1))
                        .accessibilityIdentifier("pc602-orbit-open-options291")
                    HStack(spacing:9) {
                        Button("ATLAS") {
                            previouslyPaused330=driver.paused
                            showingAtlas330=true
                            driver.setPaused(true)
                        }
                        .accessibilityIdentifier("pc602-orbit-open-atlas330")
                        Button("CEL +") {driver.cycleMission()}
                            .disabled(driver.paused)
                            .accessibilityIdentifier("pc602-orbit-next-sector")
                    }
                    .font(.system(size:compact ? 10:12,weight:.bold,
                                  design:.monospaced))
                    .foregroundStyle(gold)
                    .buttonStyle(.plain)
                    .padding(.top,3)
                }
                .font(.system(size:compact ? 10:12,weight:.semibold,
                              design:.monospaced))
            }
            .padding(.leading,leading)
            .padding(.trailing,trailing)
            .padding(.top,top)

            Spacer(minLength:0)
            if let error=driver.error {
                Text(error)
                    .font(.system(size:11,weight:.semibold,
                                  design:.monospaced))
                    .foregroundStyle(.orange)
                    .padding(10)
                    .background(Color.black.opacity(0.86))
                    .allowsHitTesting(false)
            }
            HStack(alignment:.bottom) {
                VStack(alignment:.leading,spacing:4) {
                    Text("JEDYNY HANGAR · \(Int(driver.hud.dockDistance)) m")
                    Text(driver.hud.canDock ? "MOŻNA DOKOWAĆ" :
                         "POZA STREFĄ DOKOWANIA")
                        .foregroundStyle(driver.hud.canDock ? .green : cyan)
                    Text("LEWA STRONA: LOT · PRAWA: KIERUNEK I OGIEŃ")
                        .font(.system(size:compact ? 8:10))
                        .padding(.top,3)
                }
                .font(.system(size:compact ? 9:11,weight:.semibold,
                              design:.monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .allowsHitTesting(false)
                Spacer(minLength:5)
                VStack(alignment:.trailing,spacing:4) {
                    if driver.hud.canDock {
                        Text("HANGAR H55").foregroundStyle(.green)
                    } else if driver.hud.missionEntrance>0 {
                        Text("MISJA \(String(format:"%02d",driver.hud.missionEntrance))")
                            .foregroundStyle(cyan)
                    }
                    Button("WEJDŹ") {enterSourceLocation()}
                        .font(.system(size:compact ? 15:20,weight:.bold,
                                      design:.monospaced))
                        .foregroundStyle(enterAvailable() ? .white : .gray)
                        .frame(width:compact ? 110:142,
                               height:compact ? 52:62)
                        .background(enterAvailable()
                            ? Color(red:0.05,green:0.43,blue:0.28)
                            : Color.black.opacity(0.35))
                        .overlay(Rectangle().stroke(
                            enterAvailable() ? Color.green : cyan.opacity(0.4),
                            lineWidth:enterAvailable() ? 2:1))
                        .disabled(!enterAvailable())
                        .accessibilityIdentifier("pc602-orbit-enter-context")
                    if driver.hud.missionEntrance>1 && !driver.hud.canDock {
                        Text("SEKTOR NIEPRZENIESIONY")
                            .font(.system(size:9))
                            .foregroundStyle(.orange)
                    }
                }
                .font(.system(size:compact ? 10:12,weight:.semibold,
                              design:.monospaced))
            }
            .padding(.leading,leading)
            .padding(.trailing,trailing)
            .padding(.bottom,bottom)
        }
        .accessibilityIdentifier("pc602-orbit-live-touch-hud")
    }
}
