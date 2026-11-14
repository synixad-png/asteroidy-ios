import SwiftUI

/// Sector 05 uses the existing source combat simulation and Metal Boreas
/// model. This view owns controls and lifecycle, not a second physics world.
/// Mission completion is withheld while original RobotSnake actors remain
/// unported; their encounter count is never silently erased.
struct BoreasMission05Scene:View {
    let prepared:Sector01PreparedWave568
    let onExit:()->Void
    let onCompleted:(Sector01MissionSummary568)->Void
    let onAudioEvent:(Int)->Void
    let onEnginePower:(Float)->Void
    let onMissionPause:(Bool)->Void
    let onMissionPhase:(CarbonisCombat568.Phase)->Void

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session:CarbonisSession568
    @StateObject private var input=FlightInput()
    @State private var userPaused=false
    @State private var completionReported=false
    @State private var safe=W3ScreenInsets568()
    @State private var layout=HudLayout600.load()

    init(prepared:Sector01PreparedWave568,
         onExit:@escaping ()->Void,
         onCompleted:@escaping (Sector01MissionSummary568)->Void,
         onAudioEvent:@escaping (Int)->Void,
         onEnginePower:@escaping (Float)->Void,
         onMissionPause:@escaping (Bool)->Void,
         onMissionPhase:@escaping (CarbonisCombat568.Phase)->Void) {
        self.prepared=prepared
        self.onExit=onExit
        self.onCompleted=onCompleted
        self.onAudioEvent=onAudioEvent
        self.onEnginePower=onEnginePower
        self.onMissionPause=onMissionPause
        self.onMissionPhase=onMissionPhase
        _session=StateObject(wrappedValue:CarbonisSession568(prepared:prepared))
    }

    private func pause(_ shouldPause:Bool) {
        session.release()
        userPaused=shouldPause
        session.paused=shouldPause
        input.gameplayPaused=shouldPause
        onMissionPause(shouldPause)
        if shouldPause {onEnginePower(0)}
    }

    private func leave() {
        session.release()
        session.paused=true
        input.gameplayPaused=true
        _=SourceTarcza145.savePersistentEnergy(session.game.tarcza145.energy)
        Sector01Shop568.persistSurvival(
            lives:session.game.lives,
            shieldCharges:session.game.shieldCharges)
        H55Workshop580.updateFromCombat(
            hull:session.game.hull,armor:session.game.armor)
        onEnginePower(0)
        onMissionPause(false)
        onExit()
    }

    var body:some View {
        GeometryReader { geo in
            let compact=geo.size.height<550
            ZStack {
                Color.black.ignoresSafeArea()
                MetalScene(input:input,combatSession05:session)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                SourceCombatTouchZones568(
                    onMove:{session.input(move:$0)},
                    onAim:{session.input(aim:$0)},
                    onFire:{session.input(shooting:$0)})
                    .allowsHitTesting(!userPaused &&
                                      session.hud.phase == .playing)
                SourceCombatHUD331(
                    hud:session.hud,insets:safe,render3DIcons:false,
                    layout600:layout,
                    active:!userPaused && session.hud.phase == .playing,
                    liveRadar:{ [weak session] in
                        session?.currentHudRadarFrame600() ??
                            CarbonisSession568.RadarFrame600(
                                pose:HudMotion600.Pose(),contacts:[])
                    })
                    .allowsHitTesting(false)
                HudPlasmaLayer600(
                    hull:session.hud.hull,armor:session.hud.armor,
                    maxHull:session.hud.maxHull,maxArmor:session.hud.maxArmor,
                    shield:session.hud.tarczaEnergy,
                    liveGauges:{ [weak session] in
                        session?.currentHudGauges600() ??
                            (hull:0,armor:0,shield:0,maxHull:1,maxArmor:1)
                    },
                    insets:safe,layout:layout,
                    active:!userPaused && session.hud.phase == .playing,
                    livePose:{ [weak session] in
                        session?.currentHudVisual600().pose ??
                            HudMotion600.Pose()
                    },
                    liveTime:{ [weak session] in
                        session?.currentHudVisual600().seconds ?? 0
                    })
                    .allowsHitTesting(false)
                VStack(spacing:8) {
                    HStack(spacing:10) {
                        Text("BOREAS / SEKTOR 05 · OBRONA")
                            .font(.system(size:compact ? 12:16,
                                          weight:.bold,design:.monospaced))
                            .foregroundStyle(.cyan)
                        Spacer()
                        Button(userPaused ? "WZNÓW" : "PAUZA") {
                            pause(!userPaused)
                        }
                        .font(.system(size:compact ? 14:18,weight:.bold))
                        .frame(minWidth:85,minHeight:48)
                        .foregroundStyle(.white)
                        .background(Color(red:0.03,green:0.18,blue:0.25))
                        .accessibilityIdentifier("boreas05-pause-toggle")
                    }
                    .padding(.top,CGFloat(safe.top+6))
                    .padding(.horizontal,CGFloat(max(14,safe.left+12)))
                    Spacer()
                    if !userPaused && session.hud.phase == .playing {
                        HStack(spacing:12) {
                            if session.hud.bombs>0 {
                                Button("BOMBA \(session.hud.bombs)") {
                                    _=session.useBomb()
                                }
                                .frame(minWidth:86,minHeight:48)
                                .background(Color.red.opacity(0.6))
                            }
                            if let shield=session.hud.tarczaEnergy,shield>0 {
                                Text("TARCZA \(shield)")
                                    .frame(minWidth:90,minHeight:48)
                                    .background(Color.cyan.opacity(0.45))
                                    .contentShape(Rectangle())
                                    .gesture(DragGesture(minimumDistance:0)
                                        .onChanged { _ in session.holdShield145(true) }
                                        .onEnded { _ in session.holdShield145(false) })
                            }
                            if session.hud.boostCharges>0 {
                                Button("DOPALACZ \(session.hud.boostCharges)") {
                                    _=session.useBoost71()
                                }
                                .frame(minWidth:90,minHeight:48)
                                .background(Color.blue.opacity(0.55))
                            }
                        }
                        .font(.system(size:compact ? 11:14,
                                      weight:.bold,design:.monospaced))
                        .foregroundStyle(.white)
                        .padding(.bottom,CGFloat(max(12,safe.bottom+8)))
                    }
                }
                if userPaused {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    VStack(spacing:15) {
                        Text("PAUZA · BOREAS 05")
                            .font(.system(size:24,weight:.heavy,
                                          design:.monospaced))
                        Button("KONTYNUUJ") {pause(false)}
                            .frame(minWidth:190,minHeight:52)
                        Button("WRÓĆ DO KAMPANII") {leave()}
                            .frame(minWidth:190,minHeight:52)
                    }
                    .foregroundStyle(.white)
                    .buttonStyle(.borderedProminent)
                } else if session.hud.phase != .playing {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    VStack(spacing:14) {
                        Text(session.hud.phase == .victory
                             ? "MISJA 05 UKOŃCZONA" : "STATEK ZNISZCZONY")
                            .font(.system(size:compact ? 19:28,weight:.heavy,
                                          design:.monospaced))
                            .foregroundStyle(session.hud.phase == .victory
                                             ? Color.cyan : Color.red)
                        if let report=session.hud.summary {
                            Text("ZESTRZELENI: \(report.enemiesDestroyed) · SKAŁY: \(report.rocksDestroyed)")
                            Text("PUNKTY: \(report.scoreGained) · ŻETONY: +\(report.earnedTokens)")
                        } else {
                            Text("MISJA NIEZALICZONA")
                            Button("SPRÓBUJ PONOWNIE") {
                                completionReported=false
                                session.restart(prepared:prepared)
                            }
                            .frame(minHeight:50)
                        }
                        Button("WRÓĆ DO KAMPANII") {leave()}
                            .frame(minHeight:50)
                    }
                    .foregroundStyle(.white)
                    .font(.system(size:compact ? 12:16,design:.monospaced))
                    .buttonStyle(.borderedProminent)
                    .padding(24)
                }
                // Visible engineering limitation, never a fake level clear.
                if !session.game.robots.isEmpty && session.hud.phase == .playing {
                    VStack {
                        Spacer()
                        Text("WERSJA ROBOCZA · OCZEKUJE NA ORYGINALNĄ AI WĘŻY")
                            .font(.system(size:10,weight:.medium,design:.monospaced))
                            .foregroundStyle(.orange)
                            .padding(.bottom,CGFloat(safe.bottom+60))
                            .allowsHitTesting(false)
                    }
                }
                if let error=input.rendererError {
                    Text(error).foregroundStyle(.red)
                        .padding(10).background(.black.opacity(0.9))
                }
            }
            .background {
                W3SafeAreaReader568(insets:$safe)
                    .frame(width:0,height:0)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            input.planetPreview=true
            input.planetTestLevel=BoreasMission05Source.sector
            input.gameplayPaused=false
            session.paused=false
            session.refreshControls586()
            session.onAudioEvents={ events in
                for code in events {onAudioEvent(code)}
            }
        }
        .onChange(of:session.hud.phase) { _,phase in
            onMissionPhase(phase)
            guard phase == .victory,!completionReported,
                  let report=session.hud.summary else{return}
            completionReported=true
            onCompleted(report)
        }
        .onChange(of:session.hud.seconds) { _,_ in
            let power:Float=session.game.phase == .playing && !userPaused
                ? (session.move.lengthSquared>0.01 ? 1:0.16) : 0
            onEnginePower(power)
        }
        .onChange(of:scenePhase) { _,phase in
            if phase != .active {
                session.release()
                session.paused=true
                input.gameplayPaused=true
                onEnginePower(0)
            } else {
                session.release()
                session.paused=userPaused
                input.gameplayPaused=userPaused
            }
        }
        .onDisappear {
            session.release()
            session.onAudioEvents=nil
            session.paused=true
            input.gameplayPaused=true
            onEnginePower(0)
        }
        .accessibilityIdentifier("boreas05-source-combat-scene")
    }
}
