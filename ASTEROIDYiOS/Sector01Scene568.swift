import Foundation
import SwiftUI

/// CARBONIS 01 native interactive combat on the verified source planet C279.
/// Wave actors, player flight, shots and HUD share the persistent combat state.
/// The complete 25-sector PC campaign and late-game features are NOT ported.
struct Sector01Scene568: View {
    let entry:Sector01Entry568
    let returnToAtlas:()->Void
    let onMissionCompleted:(Sector01MissionSummary568)->Void
    let onSurvivalChanged:(Int,Int)->Void
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

    init(entry:Sector01Entry568,returnToAtlas:@escaping ()->Void,
         onMissionCompleted:@escaping (Sector01MissionSummary568)->Void,
         onSurvivalChanged:@escaping (Int,Int)->Void,
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
        userPaused=false
        session.paused=scenePhase != .active
        onMissionPause(false)
        if scenePhase == .active {onEnginePower(0.16)}
    }
    private func exitMission568() {
        session.release()
        userPaused=false
        session.paused=true
        onMissionPause(false)
        onEnginePower(0)
        onSurvivalChanged(session.game.lives,session.game.shieldCharges)
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
                VStack(spacing:0) {
                    HStack(spacing:10) {
                        VStack(alignment:.leading,spacing:2) {
                            Text("SEKTOR 01 / CARBONIS")
                                .font(.system(size:compact ? 14:20,weight:.bold,design:.monospaced))
                                .foregroundStyle(.orange)
                            Text("ORYGINALNA PLANETA C279 · VANGUARD · WAVE 01")
                                .font(.system(size:compact ? 9:11,design:.monospaced))
                                .foregroundStyle(.cyan)
                        }
                        Spacer()
                        if session.hud.phase == .playing && !showingService {
                            Button("PAUZA") {pauseMission568()}
                                .font(.system(size:compact ? 10:13,weight:.bold,
                                              design:.monospaced))
                                .padding(10)
                                .foregroundStyle(Color(red:0.10,green:0.15,blue:0.20))
                                .background(Color(red:0.88,green:0.67,blue:0.31),
                                            in:RoundedRectangle(cornerRadius:6))
                                .accessibilityIdentifier("sector01-pause-button")
                        }
                        Button("WRÓĆ DO MAPY") {exitMission568()}
                        .font(.system(size:compact ? 10:13,weight:.bold,design:.monospaced))
                        .padding(10)
                        .foregroundStyle(.white)
                        .background(Color(red:0.05,green:0.15,blue:0.22),
                                    in:RoundedRectangle(cornerRadius:6))
                        .accessibilityIdentifier("sector01-back-to-atlas")
                    }
                    .padding(.horizontal,compact ? 12:24)
                    .padding(.vertical,6)
                    .background(.black.opacity(0.78))
                    Spacer()
                    HStack {
                        Spacer()
                        Canvas { context,size in
                            let radius=min(size.width,size.height)*0.44
                            let center=CGPoint(x:size.width/2,y:size.height/2)
                            let circle=CGRect(x:center.x-radius,y:center.y-radius,
                                              width:radius*2,height:radius*2)
                            context.stroke(Path(ellipseIn:circle),
                                with:.color(.cyan.opacity(0.5)),lineWidth:1)
                            let cross=Path(ellipseIn:CGRect(
                                x:center.x-3,y:center.y-3,width:6,height:6))
                            context.fill(cross,with:.color(.green))
                            for p in session.hud.hazards {
                                let x=center.x+CGFloat(p.x/400)*radius
                                let y=center.y+CGFloat(p.y/400)*radius
                                guard hypot(x-center.x,y-center.y)<=radius else {continue}
                                context.fill(Path(ellipseIn:CGRect(
                                    x:x-2,y:y-2,width:4,height:4)),
                                    with:.color(.orange.opacity(0.76)))
                            }
                            for p in session.hud.tokenPickups {
                                let x=center.x+CGFloat(p.x/400)*radius
                                let y=center.y+CGFloat(p.y/400)*radius
                                guard hypot(x-center.x,y-center.y)<=radius else {continue}
                                context.fill(Path(ellipseIn:CGRect(
                                    x:x-3,y:y-3,width:6,height:6)),
                                    with:.color(.yellow))
                            }
                            for p in session.hud.targets {
                                let x=center.x+CGFloat(p.x/400)*radius
                                let y=center.y+CGFloat(p.y/400)*radius
                                guard hypot(x-center.x,y-center.y)<=radius else {continue}
                                context.fill(Path(ellipseIn:CGRect(
                                    x:x-4,y:y-4,width:8,height:8)),
                                    with:.color(.red))
                            }
                        }
                        .frame(width:compact ? 120:162,height:compact ? 100:142)
                        .background(.black.opacity(0.73),
                                    in:RoundedRectangle(cornerRadius:9))
                        .padding(.trailing,compact ? 15:28)
                        .accessibilityIdentifier("sector01-live-enemy-radar")
                        .allowsHitTesting(false)
                    }
                    HStack(alignment:.bottom) {
                        VStack(alignment:.leading,spacing:5) {
                            Text("KADŁUB \(session.hud.hull)  PANCERZ \(session.hud.armor)  ŻYCIA \(session.hud.lives)")
                                .foregroundStyle(.cyan)
                            Text("ASTEROIDY \(session.hud.rocks)  MYŚLIWCE \(session.hud.fighters)")
                                .foregroundStyle(.orange)
                            Text("PUNKTY \(session.hud.score)  ŻETONY \(session.hud.collectedTokens)  DO ZEBRANIA \(session.hud.tokenPickups.count)")
                                .foregroundStyle(.yellow)
                            Text("CZAS \(Int(session.hud.seconds)) s  ·  LEWA: LOT / PRAWA: SKRĘT + OGIEŃ")
                                .foregroundStyle(.white)
                        }
                        .font(.system(size:compact ? 10:12,weight:.bold,design:.monospaced))
                        .padding(10)
                        .background(.black.opacity(0.70),in:RoundedRectangle(cornerRadius:7))
                        Spacer()

                    }
                    .padding(.horizontal,compact ? 14:28)
                    .padding(.bottom,compact ? 9:20)
                    .allowsHitTesting(false)
                    Text("PORT MISJI 01 · POZOSTAŁE SEKTORY I MECHANIKI PC NADAL W OPRACOWANIU")
                        .font(.system(size:compact ? 8:10,design:.monospaced))
                        .foregroundStyle(.yellow)
                        .frame(maxWidth:.infinity,alignment:.leading)
                        .padding(.horizontal,compact ? 12:24)
                        .padding(.vertical,5)
                        .background(.black.opacity(0.9))
                        .allowsHitTesting(false)
                }

                // Windows Renderer.cs:200: performance overlay only during
                // active combat, not victory/defeat/service screens.
                if session.hud.phase == .playing && !showingService {
                    SourcePerformanceOverlay568()
                        .frame(maxWidth:.infinity,maxHeight:.infinity,
                               alignment:.bottomTrailing)
                        .padding(.trailing,compact ? 15 : 28)
                        .padding(.bottom,compact ? 74 : 102)
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
                                    onSurvivalChanged(session.game.lives,
                                                      session.game.shieldCharges)
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
                        Button("KONTYNUUJ") {resumeMission568()}
                            .frame(maxWidth:.infinity)
                            .padding(compact ? 9:13)
                            .background(Color(red:0.88,green:0.67,blue:0.31),
                                        in:RoundedRectangle(cornerRadius:5))
                            .foregroundStyle(Color(red:0.07,green:0.13,blue:0.17))
                            .accessibilityIdentifier("sector01-resume-button")
                        Button("WYJDŹ DO MENU") {exitMission568()}
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
        }
        // Source CompleteMission50: persist only after the genuine
        // 0.20 s full clear gate and one-shot FinishLevel settlement.
        .onChange(of:session.hud.phase) { phase in
            onMissionPhase(phase)
            guard phase == .victory, !completionReported,
                  let report=session.hud.summary else {return}
            completionReported=true
            session.release()
            onSurvivalChanged(session.game.lives,
                              session.game.shieldCharges)
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
                session.paused=true
            } else {
                session.release()
                session.paused=userPaused
            }
        }
        .onAppear {
            session.onAudioEvents = { sourceCodes in
                for code in sourceCodes { onAudioEvent(code) }
            }
        }
        .onDisappear {
            onEnginePower(0)
            onMissionPause(false)
            session.onAudioEvents=nil
            session.paused=true
            session.release()
        }
        .accessibilityIdentifier("sector01-real-source-scene")
    }
}
