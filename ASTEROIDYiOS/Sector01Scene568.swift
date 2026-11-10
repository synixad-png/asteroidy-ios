import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// CARBONIS 01 native interactive combat on the verified source planet C279.
/// Wave actors, player flight, shots and HUD share the persistent combat state.
/// The complete 25-sector PC campaign and late-game features are NOT ported.
struct Sector01Scene568: View {
    let entry:Sector01Entry568
    let returnToAtlas:()->Void
    let onMissionCompleted:(Sector01MissionSummary568)->Void
    let onSurvivalChanged:(Int,Int,Int,Int)->Void
    let onAudioEvent:(Int)->Void
    let onEnginePower:(Float)->Void
    let onMissionPause:(Bool)->Void
    let onMissionPhase:(CarbonisCombat568.Phase)->Void
    let onReplay:()->Void
    let preparedWave:Sector01PreparedWave568
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session:CarbonisSession568
    @State private var completionReported=false
    @State private var showingService=false
    // Windows v568 Game.Mode.Paused / PausedFrom=Playing:
    // user pause is independent from an iOS lock-screen suspension.
    @State private var userPaused=false
    @State private var showingHudMotion600=false
    @State private var showingPlanetariumImport600=false
    @State private var planetariumURL600:URL?
    @State private var planetariumIssue600:String?
    // Window safe areas survive a full-bleed mission view on iPad/iPhone.
    @State private var missionSafeInsets568=W3ScreenInsets568()

    init(entry:Sector01Entry568,returnToAtlas:@escaping ()->Void,
         onMissionCompleted:@escaping (Sector01MissionSummary568)->Void,
         onSurvivalChanged:@escaping (Int,Int,Int,Int)->Void,
         onAudioEvent:@escaping (Int)->Void = {_ in},
         onEnginePower:@escaping (Float)->Void = {_ in},
         onMissionPause:@escaping (Bool)->Void = {_ in},
         onMissionPhase:@escaping (CarbonisCombat568.Phase)->Void = {_ in},
         onReplay:@escaping ()->Void = {},
         preparedWave:Sector01PreparedWave568) {
        self.entry=entry
        self.returnToAtlas=returnToAtlas
        self.onMissionCompleted=onMissionCompleted
        self.onSurvivalChanged=onSurvivalChanged
        self.onAudioEvent=onAudioEvent
        self.onEnginePower=onEnginePower
        self.onMissionPause=onMissionPause
        self.onMissionPhase=onMissionPhase
        self.onReplay=onReplay
        self.preparedWave=preparedWave
        _session=StateObject(wrappedValue:CarbonisSession568(prepared:preparedWave))
    }
    private func clamp(_ a:Float)->Float {max(-1,min(1,a))}
    // Source Windows/src/BossTunnelGame.cs: Pause/Resume. Physics in
    // CarbonisSession568.frame is already gated by session.paused.
    private func pauseMission568() {
        guard !userPaused && session.game.phase == .playing else {return}
        session.release()
        userPaused=true
        session.paused=true
        onEnginePower(0)
        onMissionPause(true)
    }
    private func resumeMission568() {
        guard userPaused else {return}
        session.release() // never resurrect a held auto-fire after pause
        session.refreshControls586()
        userPaused=false
        session.paused=scenePhase != .active
        onMissionPause(false)
        if scenePhase == .active {onEnginePower(0.16)}
    }
    private func persistConsumables580() {
        Sector01Shop568.persistConsumables(
            ionAmmo:session.game.ionAmmo,bombs:session.game.bombs)
    }
    private func exitMission568() {
        session.release()
        userPaused=false
        session.paused=true
        // returnToAtlas -> OriginalAudioAV568.returnToMenu() changes
        // the context atomically. Do not briefly restart combat sound.
        onEnginePower(0)
        persistConsumables580()
        onSurvivalChanged(session.game.lives,session.game.shieldCharges,
                           session.game.hull,session.game.armor)
        returnToAtlas()
    }
    private var movement:some Gesture {
        DragGesture(minimumDistance:0).onChanged { v in
            session.input(move:Vec2(x:clamp(Float(v.translation.width)/110),
                                    y:clamp(Float(v.translation.height)/110)))
        }.onEnded { _ in session.input(move:Vec2(x:0,y:0)) }
    }
    // RIGHT half starts firing at touch-down and continues while held.
    // Preserve the original drag-to-turn sensitivity and both-axis aim.
    private var aiming:some Gesture {
        DragGesture(minimumDistance:0).onChanged { v in
            session.input(aim:Vec2(x:clamp(Float(v.translation.width)/100),
                                    y:clamp(Float(v.translation.height)/100)),
                          shooting:true)
        }.onEnded { _ in
            session.input(aim:Vec2(x:0,y:0),shooting:false)
        }
    }
    var body:some View {
        GeometryReader { geo in
            let compact=geo.size.height<550
            let combatHUDLayout=CombatHUDViewport568(
                width:Double(geo.size.width),height:Double(geo.size.height),
                safeLeft:missionSafeInsets568.left,
                safeRight:missionSafeInsets568.right,
                safeTop:missionSafeInsets568.top,
                safeBottom:missionSafeInsets568.bottom)
            ZStack {
                Color(red:0.008,green:0.014,blue:0.032).ignoresSafeArea()
                Sector01CarbonisPreview568(
                    yawOffset:0,pitchOffset:0,
                    initialRocks:preparedWave.encounter.rocks,
                    gameSession:session)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("sector01-carbonis-native-combat-3d")

                // The control zones are gestures, not on-screen analog images.
                HStack(spacing:0) {
                    Color.clear.contentShape(Rectangle())
                        .gesture(movement)
                        .accessibilityLabel("Lewy obszar: lot i przemieszczanie statku")
                    Color.clear.contentShape(Rectangle())
                        .gesture(aiming)
                        .accessibilityLabel("Prawy obszar: skręt i ciągły ostrzał")
                        .accessibilityIdentifier("sector01-right-steer-auto-fire")
                }
                // RendererW3Combat331.cs: native, transparent, screen-anchored
                // HUD at the exact original 1280x720 virtual positions.
                // All readings come from the genuine active combat snapshot.
                SourceCombatHUD331(hud:session.hud,insets:missionSafeInsets568,
                                   render3DIcons:session.hud3DIconsReady600)
                    .allowsHitTesting(false)
                    .onAppear {
                        if planetariumURL600 == nil {
                            planetariumURL600=HudPlanetariumAsset600.availableURL()
                        }
                    }

                // One original 3D asset, rendered by GLTFKit2 + SceneKit.
                // No procedural replacement if the signed-off GLB is absent.
                if let planetariumURL600 {
                    HudPlanetariumScene600(
                        original:planetariumURL600,
                        capsule:session.hud.capsuleLevels,
                        pitch:-20,
                        pose:session.hud.motion)
                    .frame(
                        width:CGFloat(250*1.4702*combatHUDLayout.scale),
                        height:CGFloat(135*1.4702*combatHUDLayout.scale))
                    .position(
                        x:CGFloat(combatHUDLayout.x(64.7882+125,
                            at:.bottomLeft)+Double(session.hud.motion.x)*1.18*combatHUDLayout.scale),
                        y:CGFloat(combatHUDLayout.y(553.0863+67.5,
                            at:.bottomLeft)+Double(session.hud.motion.y)*1.18*combatHUDLayout.scale))
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("sector01-hud-v600-original-planetarium")
                }

                // The touch-only pause affordance is separate from the PC HUD.
                // Keep the real source Game.Paused action and preserve
                // both full-screen drag zones, including iPhone safe areas.
                if session.hud.phase == .playing && !showingService && !userPaused {
                    Button("PAUZA") {pauseMission568()}
                        .font(.system(size:compact ? 10:12,weight:.semibold,
                                      design:.monospaced))
                        .padding(.horizontal,compact ? 7:11)
                        .padding(.vertical,compact ? 4:7)
                        .foregroundStyle(Color(red:0.85,green:0.88,blue:0.90))
                        .background(Color.black.opacity(0.36),
                                    in:RoundedRectangle(cornerRadius:4))
                        .overlay(RoundedRectangle(cornerRadius:4)
                            .stroke(.cyan.opacity(0.45),lineWidth:1))
                        .position(x:CGFloat(combatHUDLayout.pauseCenterX),
                                  y:CGFloat(combatHUDLayout.pauseCenterY))
                        .accessibilityIdentifier("sector01-pause-button")
                    // PC Game.UseBomb is a discrete action (R / pad Y),
                    // not a held drag. Touch location follows the pause
                    // control without shrinking either steering half.
                    if session.hud.bombs>0 {
                        Button("BOMBA \(session.hud.bombs)") {
                            _=session.useBomb()
                        }
                        .font(.system(size:compact ? 10:12,
                                      weight:.bold,design:.monospaced))
                        .padding(.horizontal,compact ? 7:11)
                        .padding(.vertical,compact ? 5:8)
                        .foregroundStyle(.white)
                        .background(Color.red.opacity(0.75),
                                    in:RoundedRectangle(cornerRadius:5))
                        .position(x:CGFloat(combatHUDLayout.pauseCenterX),
                                  y:CGFloat(combatHUDLayout.pauseCenterY+45))
                        .accessibilityIdentifier("sector01-active-bomb-button")
                    }
                    // PC Tarcza145: held action, NOT the passive shield
                    // purchased at the shop. Keep the source HUD untouched.
                    if let energy=session.hud.tarczaEnergy,energy>0 {
                        Text("TARCZA \(energy)/100")
                            .font(.system(size:compact ? 10:12,
                                          weight:.bold,design:.monospaced))
                            .padding(.horizontal,compact ? 7:11)
                            .padding(.vertical,compact ? 5:8)
                            .foregroundStyle(.white)
                            .background(Color.cyan.opacity(0.55),
                                        in:RoundedRectangle(cornerRadius:5))
                            .contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance:0)
                                .onChanged {_ in session.holdShield145(true)}
                                .onEnded {_ in session.holdShield145(false)})
                            .position(x:CGFloat(combatHUDLayout.pauseCenterX),
                                      y:CGFloat(combatHUDLayout.pauseCenterY+90))
                            .accessibilityLabel("Przytrzymaj: tarcza energetyczna")
                            .accessibilityIdentifier("sector01-active-tarcza145-hold")
                    }
                    // PC Boost71: one press consumes one charge; real
                    // 0.9 s movement and ram impacts remain in simulation.
                    if session.hud.boostCharges>0 {
                        Button("DOPALACZ \(session.hud.boostCharges)/3") {
                            _=session.useBoost71()
                        }
                        .font(.system(size:compact ? 10:12,
                                      weight:.bold,design:.monospaced))
                        .padding(.horizontal,compact ? 7:11)
                        .padding(.vertical,compact ? 5:8)
                        .foregroundStyle(.white)
                        .background(Color.blue.opacity(0.65),
                                    in:RoundedRectangle(cornerRadius:5))
                        .position(x:CGFloat(combatHUDLayout.pauseCenterX),
                                  y:CGFloat(combatHUDLayout.pauseCenterY+135))
                        .accessibilityIdentifier("sector01-active-boost71-button")
                    }
                }
                // Windows Renderer.cs:200: performance overlay only during
                // active combat, not victory/defeat/service screens.
                if session.hud.phase == .playing && !showingService {
                    SourcePerformanceOverlay568()
                        .frame(maxWidth:.infinity,maxHeight:.infinity,
                               alignment:.bottomTrailing)
                        .padding(.trailing,compact ? 15 : 28)
                        .padding(.bottom,compact ? 112 : 144)
                        .allowsHitTesting(false)
                }
                if showingService {
                    Color.black.opacity(0.88).ignoresSafeArea()
                    Sector01ShopPanel568(onReturnAtlas:returnToAtlas)
                        .padding(compact ? 6:20)
                } else if session.hud.phase != .playing {
                    Color.black.opacity(0.80).ignoresSafeArea()
                    ScrollView {
                        VStack(spacing:14) {
                            Text(session.hud.phase == .victory ?
                                 "MISJA UKOŃCZONA" : "STATEK ZNISZCZONY")
                                .font(.system(size:compact ? 21:30,weight:.heavy,
                                              design:.monospaced))
                                .foregroundStyle(session.hud.phase == .victory ? .cyan : .red)
                            if let report=session.hud.summary {
                                Text("POZIOM 1 / RAPORT MISJI")
                                    .foregroundStyle(.cyan)
                                Text("ZESTRZELENI PRZECIWNICY  \(report.enemiesDestroyed)")
                                Text("ZNISZCZONE ASTEROIDY       \(report.rocksDestroyed)")
                                Text("PUNKTY ZA POZIOM          +\(report.scoreGained)")
                                Text("ZEBRANE ŻETONY            +\(report.collectedTokens)")
                                Text("PREMIA ZA MISJĘ           +\(report.clearBonus)")
                                Text("ŁĄCZNIE: +\(report.earnedTokens) ŻETONÓW")
                                    .foregroundStyle(.yellow)
                                    .fontWeight(.bold)
                                if report.isReplay {
                                    Text("POWTÓRKA MISJI — BEZ KOLEJNYCH NAGRÓD")
                                        .foregroundStyle(.orange)
                                }
                                if session.hud.summarySeconds>=4.2 {
                                    Button("DALEJ / SERWIS") {
                                        showingService=true
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .accessibilityIdentifier("sector01-result-to-service")
                                } else {
                                    Text("RAPORT MISJI · \(Int(max(0,4.2-session.hud.summarySeconds)+1)) s")
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Text("MISJA NIEZALICZONA · BRAK ZAPISU POSTĘPU")
                                    .foregroundStyle(.orange)
                                Button("SPRÓBUJ PONOWNIE") {
                                    completionReported=false
                                    session.restart(prepared:preparedWave)
                                    onReplay()
                                }
                                .buttonStyle(.borderedProminent)
                                .accessibilityIdentifier("sector01-retry-after-defeat")
                                Button("POWRÓT DO ATLASU") {
                                    persistConsumables580()
                                    onSurvivalChanged(session.game.lives,session.game.shieldCharges,
                           session.game.hull,session.game.armor)
                                    returnToAtlas()
                                }
                                    .buttonStyle(.bordered)
                            }
                        }
                        .font(.system(size:compact ? 11:14,
                                      design:.monospaced))
                        .foregroundStyle(.white)
                        .padding(compact ? 15:28)
                        .background(Color(red:0.02,green:0.04,blue:0.10),
                                    in:RoundedRectangle(cornerRadius:12))
                    }
                    .frame(maxWidth:650,maxHeight:compact ? 400:550)
                }
                // Source Windows/src/RendererW3Pause317.cs: translucent
                // full-screen modal over the FROZEN real 3D mission.
                // Save/Load/Highscores remain absent until their source
                // behaviour is genuinely ported; do not display dead keys.
                if userPaused && session.hud.phase == .playing && !showingService {
                    Color.black.opacity(0.80).ignoresSafeArea()
                        .accessibilityIdentifier("sector01-pause-touch-blocker")
                    VStack(alignment:.leading,spacing:compact ? 11:18) {
                        Text("SYNIXAD // SYSTEM ROZGRYWKI")
                            .font(.system(size:compact ? 10:12,weight:.bold,
                                          design:.monospaced))
                            .foregroundStyle(Color(red:0.55,green:0.77,blue:0.80))
                        Text("GRA WSTRZYMANA")
                            .font(.system(size:compact ? 23:35,weight:.heavy,
                                          design:.monospaced))
                            .foregroundStyle(.white)
                        Text("SYTUACJA ZACHOWANA / CZAS ROZGRYWKI ZATRZYMANY")
                            .font(.system(size:compact ? 10:13,
                                          design:.monospaced))
                            .foregroundStyle(.gray)
                        Divider().overlay(Color(red:0.88,green:0.67,blue:0.31))
                        if planetariumURL600 == nil {
                            Button("WCZYTAJ PLANETARIUM GLB v600") {
                                showingPlanetariumImport600=true
                            }
                            .fileImporter(
                                isPresented:$showingPlanetariumImport600,
                                allowedContentTypes:[UTType(filenameExtension:"glb") ?? .data]
                            ) { result in
                                do {
                                    let source=try result.get()
                                    planetariumURL600=try HudPlanetariumAsset600.install(from:source)
                                    planetariumIssue600=nil
                                } catch {
                                    planetariumIssue600=error.localizedDescription
                                }
                            }
                            .frame(maxWidth:.infinity)
                            .padding(compact ? 7:10)
                            .background(Color(red:0.05,green:0.15,blue:0.22),
                                        in:RoundedRectangle(cornerRadius:5))
                            .foregroundStyle(.cyan)
                        }
                        if let planetariumIssue600 {
                            Text(planetariumIssue600)
                                .font(.system(size:10))
                                .foregroundStyle(.orange)
                        }
                        Button("HUD DYNAMICZNY / USTAWIENIA") {
                            showingHudMotion600=true
                        }
                        .frame(maxWidth:.infinity)
                        .padding(compact ? 7:10)
                        .background(Color(red:0.05,green:0.15,blue:0.22),
                                    in:RoundedRectangle(cornerRadius:5))
                        .foregroundStyle(.cyan)
                        .accessibilityIdentifier("sector01-hud-v600-settings")
                        .sheet(isPresented:$showingHudMotion600) {
                            HudMotionSettingsPanel600 {settings in
                                session.applyHudMotion600(settings)
                            }
                        }
                        Button("KONTYNUUJ") {resumeMission568()}
                            .frame(maxWidth:.infinity)
                            .padding(compact ? 9:13)
                            .background(Color(red:0.88,green:0.67,blue:0.31),
                                        in:RoundedRectangle(cornerRadius:5))
                            .foregroundStyle(Color(red:0.07,green:0.13,blue:0.17))
                            .accessibilityIdentifier("sector01-resume-button")
                        Button("WYJDŹ DO MENU") {exitMission568()}
                            .accessibilityIdentifier("sector01-back-to-atlas")
                            .frame(maxWidth:.infinity)
                            .padding(compact ? 9:13)
                            .background(Color(red:0.05,green:0.15,blue:0.22),
                                        in:RoundedRectangle(cornerRadius:5))
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("sector01-pause-exit-button")
                        Text("SEKTOR 01    PUNKTY \(session.hud.score)    ŻYCIA \(session.hud.lives)")
                            .font(.system(size:compact ? 10:12,design:.monospaced))
                            .foregroundStyle(.gray)
                    }
                    .font(.system(size:compact ? 13:16,weight:.bold,design:.monospaced))
                    .padding(compact ? 16:28)
                    .frame(maxWidth:min(geo.size.width-32,650))
                    .background(Color(red:0.02,green:0.05,blue:0.09),
                                in:RoundedRectangle(cornerRadius:12))
                    .overlay(RoundedRectangle(cornerRadius:12)
                        .stroke(Color(red:0.24,green:0.38,blue:0.44),lineWidth:1))
                    .accessibilityIdentifier("sector01-source-pause-overlay")
                }
            }
            .background {
                W3SafeAreaReader568(insets:$missionSafeInsets568)
                    .frame(width:0,height:0)
                    .allowsHitTesting(false)
            }
            .background(alignment:.topLeading) {
                // 1px invisible UIKit first-responder for hardware keys.
                // Full-screen touch halves and original HUD are untouched.
                SourceKeyboardCapture586 {key,held in
                    SourceHardwareInput586.shared.changeKey(
                        key,pressed:held)
                }
                .frame(width:1,height:1)
                .opacity(0.01)
                .accessibilityHidden(true)
            }
        }
        // Full-bleed mission uses the entire physical viewport; only the
        // four HUD corners are inset via actual UIWindow.safeAreaInsets.
        // Touch zones continue covering both halves edge to edge.
        .ignoresSafeArea()
        // Source CompleteMission50: persist only after the genuine
        // 0.20 s full clear gate and one-shot FinishLevel settlement.
        .onChange(of:session.hud.phase) { phase in
            onMissionPhase(phase)
            guard phase == .victory, !completionReported,
                  let report=session.hud.summary else {return}
            completionReported=true
            session.release()
            persistConsumables580()
            onSurvivalChanged(session.game.lives,session.game.shieldCharges,
                           session.game.hull,session.game.armor)
            onMissionCompleted(report)
        }
        // MusicAudio.cs engineLevel: active thrust=1; no thrust idle=.16.
        // Subscribe to actual simulation HUD updates at 10 Hz, not the
        // render thread. Physics and touch control remain unchanged.
        .onChange(of:session.hud.seconds) { _ in
            let engine:Float=session.game.phase == .playing && !userPaused
                ? (session.move.lengthSquared>0.01 ? 1 : 0.16) : 0
            onEnginePower(engine)
        }
        // Interrupted iOS touches (Control Center, app switcher, call)
        // cannot leave auto-fire held after returning to the mission.
        .onChange(of:scenePhase) { phase in
            if phase != .active {
                session.release()
                SourceHardwareInput586.shared.clearKeyboard()
                session.paused=true
            } else {
                session.release()
                session.paused=userPaused
            }
        }
        .onAppear {
            // PC action 9 (P / gamepad START) toggles the genuine pause
            // transaction, never a second fake pause state.
            session.onPauseRequested = {
                if userPaused {resumeMission568()}
                else {pauseMission568()}
            }
            session.onAudioEvents = { sourceCodes in
                for code in sourceCodes { onAudioEvent(code) }
            }
        }
        .onDisappear {
            onEnginePower(0)
            SourceHardwareInput586.shared.clearKeyboard()
            session.onPauseRequested=nil
            session.onAudioEvents=nil
            session.paused=true
            session.release()
        }
        .accessibilityIdentifier("sector01-real-source-scene")
    }
}
