import SwiftUI
import MetalKit
import QuartzCore

@main
struct AsteroidyMobileApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
                .preferredColorScheme(.dark)
                .persistentSystemOverlays(.hidden)
        }
    }
}

final class FlightInput: ObservableObject {
    @Published var thrust: Float = 0
    @Published var steer: Float = 0
    @Published var shooting = false
    // Windows Game.Input.Tarcza145 is a momentary held input.
    @Published var tarczaHeld = false
    // Start in the real v556 Boreas GLB renderer instead of the
    // independent 9-rock flat diagnostic arena. This is still a
    // test sector, NOT a port of the complete original mission.
    @Published var planetPreview = true
    // Explicit optional v568 ship 3. Never replace the default Vanguard556.
    @Published var sourceShip367Preview =
        ProcessInfo.processInfo.environment["ASTEROIDY_SHIP367_VERIFY"] == "1"
    // Real IntroScene41 camera/planet/ship positions, but cinematic
    // GPU rock meshes still need source-specific geometric detail.
    // An explicit rendering preview, NEVER a mission completion.
    @Published var introPreview41 =
        ProcessInfo.processInfo.environment["ASTEROIDY_SHIP367_VERIFY"] != "1"
    @Published var introProgress41: Float = 0
    // 0: diagnostics (Boreas); 1: genuine playable CARBONIS mission
    // uses the source C279 globe throughout the original Intro41.
    @Published var missionIntroSector = 0
    // Source-defined diagnostic cases: ordinary rocks (1), timed waves
    // (9/17) and AmigaOnly266 perpetual bouncing balls (25).
    // This is NOT a mission/campaign unlock selector.
    @Published var planetTestLevel = 1
    @Published var sectorTraining = false
    @Published var verifiedDamageLab = false
    @Published var verifiedGameOver = false
    @Published var verifiedDeaths = 0
    @Published var verifiedArmor = 25
    @Published var verifiedHull = 60
    @Published var verifiedTarczaEnergy: Float = 60
    @Published var verifiedTarczaActive = false
    @Published var trainingRockCount = 9
    @Published var score = 0
    @Published var hull = 3
    @Published var planetSectorCleared = false
    @Published var planetWave = 1
    @Published var planetIncomingNotice = false
    @Published var planetAmigaDemo = false
    @Published var planetAmigaHits = 0
    @Published var rendererError: String?
    // UI-only pause state; do not mutate saved campaign or physics.
    @Published var gameplayPaused = false

    // Touch gestures may not deliver onEnded if iOS backgrounds the app.
    // Clear only transient held inputs; never reset the game simulation.
    func releaseHeldControls() {
        thrust = 0
        steer = 0
        shooting = false
        tarczaHeld = false
    }
}

struct GameView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var input = FlightInput()
    @StateObject private var missionIntroInput568 = FlightInput()
    @StateObject private var audio = OriginalAudioAV568()
    @StateObject private var homeWorld291=PC602HomeWorldDriver291()
    @State private var campaign = CampaignStore556.load()
    @State private var showingHomeWorld291=false
    @State private var showingBoreasTest05=false
    @State private var returnHomeWorldAfterCarbonis291=false
    // Native CARBONIS first mission runs an original source-driven state,
    // isolated from Boreas diagnostic scenes and unported later sectors.
    @State private var sourceSector01: Sector01Entry568?
    @State private var sourceSector01Setup: Sector01PreparedWave568?
    @State private var showingMissionIntro568 = false
    // PC602 SaveManager61 checkpoint61: BeginLevelIntro before live combat.
    @State private var missionCheckpoint61:PC602OrbitSave61.Snapshot?
    @State private var reopenAtlasAfterCarbonis = false

    /// PC602 SaveManager61.SaveSlot61 from Mode.Menu uses the most recent
    /// verified Orbit/Intro checkpoint, never live combat-frame data.
    private func menuCheckpoint61()->PC602OrbitSave61.Snapshot? {
        guard SourceNewGame568.canContinueActive358(),
              let run=SourceNewGame568.currentRunID(),
              let checkpoint=missionCheckpoint61,
              checkpoint.runID==run,checkpoint.valid else{return nil}
        return checkpoint
    }
    private func saveMenuCheckpoint61(_ slot:Int)->Bool {
        guard let checkpoint=menuCheckpoint61() else{return false}
        do {try PC602OrbitSave61.store(checkpoint,slot:slot);return true}
        catch{return false}
    }

    // The player starts physical orbit from the actual W3 campaign page.
    // A menu action must never manufacture a mission or reset the campaign.
    private func enterHomeWorld291()->String? {
        guard sourceSector01==nil else{return "MISJA JUŻ TRWA"}
        do {
            try homeWorld291.start(progress:campaign)
            input.releaseHeldControls()
            input.gameplayPaused=true
            audio.enterOrbit602()
            showingHomeWorld291=true
            showMainMenu=false
            return nil
        } catch {
            return "NIE MOŻNA OTWORZYĆ ORBITY: "+String(describing:error)
        }
    }

    // Authenticated PC v556 Boreas visual model at its original sector-05
    // slot. No sector unlock, checkpoint, reward or active mission is made.
    private func enterBoreasTest05() {
        guard sourceSector01==nil, !showingHomeWorld291,
              AnimatedPlanetTestSlot556.sourceAssetsVerified else{return}
        input.releaseHeldControls()
        input.introPreview41=false
        input.planetPreview=true
        input.planetTestLevel=AnimatedPlanetTestSlot556.sector
        input.sectorTraining=false
        input.verifiedDamageLab=false
        input.missionIntroSector=0
        input.rendererError=nil
        input.gameplayPaused=false
        audio.stopForDiagnostic()
        showingBoreasTest05=true
        showMainMenu=false
    }
    private func returnFromBoreasTest05() {
        input.releaseHeldControls()
        input.gameplayPaused=true
        showingBoreasTest05=false
        reopenAtlasAfterCarbonis=true
        showMainMenu=true
        audio.returnToMenu()
    }

    private func enterOrbitMission291(_ level:Int) {
        // Only source Carbonis 01 is available as playable combat on iOS.
        guard level==1,sourceSector01==nil,
              Sector01CarbonisPreview568.isAvailable else{return}
        returnHomeWorldAfterCarbonis291=true
        _=homeWorld291.captureResume61()
        homeWorld291.setSuspended(true)
        inspectSourceSector(1)
        if sourceSector01 != nil {
            showingHomeWorld291=false
        } else {
            returnHomeWorldAfterCarbonis291=false
            homeWorld291.setSuspended(scenePhase != .active)
        }
    }

    private func beginMissionIntro568(sector:Int) {
        // Source Intro41.BeginLevelIntro -> SaveManager61.RefreshCheckpoint61:
        // capture BEFORE combat modifies lives, tokens or transient shots.
        let sourceOrbit=homeWorld291.readFlight().flatMap {
            PC602OrbitSave61.capture($0)
        }
        missionCheckpoint61=PC602OrbitSave61.captureMissionStart61(
            level:sector,returnHome:returnHomeWorldAfterCarbonis291,
            baseOrbit:sourceOrbit)
        // Only launch after original mission assets, shop and Wave()
        // preparation succeeded. Intro does not advance Physics68.
        missionIntroInput568.releaseHeldControls()
        missionIntroInput568.rendererError=nil
        missionIntroInput568.introProgress41=0
        missionIntroInput568.missionIntroSector=sector
        missionIntroInput568.introPreview41=true
        missionIntroInput568.gameplayPaused=scenePhase != .active
        showingMissionIntro568=true
        audio.beginMissionIntro568(sector:sector)
    }

    private func finishMissionIntro568(sector:Int) {
        guard showingMissionIntro568,
              sourceSector01?.sector == sector else {return}
        showingMissionIntro568=false
        missionIntroInput568.gameplayPaused=true
        audio.finishMissionIntro568(sector:sector)
        // Only now is Sector01Scene568 constructed; its real combat
        // simulation and 120Hz timer have NOT been running during Intro41.
    }
    private func cancelMissionIntro568() {
        showingMissionIntro568=false
        missionIntroInput568.gameplayPaused=true
        sourceSector01=nil
        sourceSector01Setup=nil
        input.releaseHeldControls()
        if returnHomeWorldAfterCarbonis291 {
            returnHomeWorldAfterCarbonis291=false
            showingHomeWorld291=true
            showMainMenu=false
            homeWorld291.setSuspended(scenePhase != .active)
            audio.enterOrbit602()
        } else {
            reopenAtlasAfterCarbonis=true
            audio.returnToMenu()
            showMainMenu=true
        }
    }


    /// PC602 SaveManager61.LoadSlot61 for Mode.Intro: restore campaign,
    /// construct the source Wave(), then start BeginLevelIntro() from zero.
    /// Never replay mutable battle frames or grant a completed-mission reward.
    private func loadIntroCheckpoint61(_ state:PC602OrbitSave61.Snapshot)->Bool {
        guard state.isMissionIntro61,
              let difficulty=CombatBalance556.Difficulty(rawValue:state.difficultyRaw),
              Sector01CarbonisPreview568.isAvailable else{return false}
        let restored=CampaignProgress556(mask:state.completedMask,selectedSector:1)
        guard let entry=Sector01Entry568.open(
                  selectedSector:1,campaign:restored,hasOriginalC279Assets:true),
              let prepared=Sector01PreparedWave568.prepare(
                  entry:entry,campaign:restored,hasOriginalC279Assets:true,
                  difficulty:difficulty,seed:Int32.random(in:0...Int32.max),
                  currentLives:state.shop.lives,
                  startingLives:SourceNewGame568.startingLives(
                      difficulty:difficulty,shipType:state.shipType),
                  shopProfile:state.shop)
        else{return false}
        if state.returnHome61 == true {
            guard PC602HomeWorldDriver291.resourcesInstalled,
                  (try? PC602NewHome290.load()) != nil,
                  (try? PC602OrbitBelt51.load()) != nil else{return false}
        }
        guard SourceNewGame568.restoreOrbitProfile61(
            runID:state.runID,completedMask:state.completedMask,
            target:1,shop:state.shop,vitals:state.vitals,
            mechanics:state.mechanics,difficultyRaw:state.difficultyRaw,
            tarczaEnergy145:state.tarczaEnergy145)
        else{return false}
        campaign=CampaignStore556.load()
        if state.returnHome61 == true {
            // A loaded Intro is not an orbital position checkpoint.
            // Start real H290 solely for its later return after service.
            guard (try? homeWorld291.start(progress:campaign)) != nil
            else{return false}
            homeWorld291.setSuspended(true)
        }
        sourceSector01=entry
        sourceSector01Setup=prepared
        returnHomeWorldAfterCarbonis291=state.returnHome61 == true
        showingHomeWorld291=false
        input.releaseHeldControls()
        input.gameplayPaused=true
        beginMissionIntro568(sector:1)
        showMainMenu=true
        return true
    }

    /// Shared W3/paused mission slot dispatcher.
    private func loadManualSave61(_ slot:Int)->Bool {
        guard let state=try? PC602OrbitSave61.read(slot:slot) else{return false}
        if state.isMissionIntro61 {return loadIntroCheckpoint61(state)}
        guard state.isOrbit61,homeWorld291.loadOrbitSlot61(slot) else{return false}
        campaign=CampaignStore556.load()
        sourceSector01=nil
        sourceSector01Setup=nil
        showingMissionIntro568=false
        missionCheckpoint61=nil
        returnHomeWorldAfterCarbonis291=false
        input.releaseHeldControls()
        input.gameplayPaused=true
        homeWorld291.setPaused(false)
        showingHomeWorld291=true
        showMainMenu=false
        audio.enterOrbit602()
        return true
    }

    private func inspectSourceSector(_ sector: Int) {
        // OrbitClick51 writes the canonical CampaignStore556 immediately.
        // SwiftUI's @State campaign can still hold the PREVIOUS target after
        // choosing a completed stage on the orbit atlas; source game uses
        // live OrbitTarget50, never an outdated W3 selection snapshot.
        let current=CampaignStore556.load()
        guard let entry=Sector01Entry568.open(
            selectedSector:sector,campaign:current,
            hasOriginalC279Assets:Sector01CarbonisPreview568.isAvailable)
        else { return }
        // Original Game.Wave plus replay-safe real service profile.
        let sourceShop=Sector01Shop568.load()
        guard let preparedWave=Sector01PreparedWave568.prepare(
            entry:entry,campaign:current,
            hasOriginalC279Assets:Sector01CarbonisPreview568.isAvailable,
            difficulty:SourceNewGame568.selection().difficulty,
            seed:Int32.random(in:0...Int32.max),
            currentLives:sourceShop.lives,
            startingLives:SourceNewGame568.startingLives(
                difficulty:SourceNewGame568.selection().difficulty,
                shipType:H55SourceMechanics580.load().selectedShip),
            shopProfile:sourceShop)
        else { return }
        campaign=current
        input.releaseHeldControls()
        input.gameplayPaused = true
        reopenAtlasAfterCarbonis = false
        sourceSector01Setup = preparedWave
        sourceSector01 = entry
        beginMissionIntro568(sector:sector)
        showMainMenu = true
    }

    // Original W3 start action: preserve an active profile before reset.
    // Current iOS supports one actual CARBONIS ship. Source 2-player
    // gameplay and the 62-second story cinematic are NOT yet ported.
    private func startNewGameFromW3(_ choice:SourceNewGameSelection568)->String? {
        // PC609 ProgramW3Native315.NativeStartFresh342 and Campaign37:
        // preserve old profile until ALL source assets and the original orbit
        // session for the explicitly selected new ship have passed preflight.
        guard sourceSector01==nil,choice.players==1 else {
            return "TRWA INNA MISJA LUB NIEDOSTĘPNY TRYB ZAŁOGI"
        }
        guard let craft=PC602HomeFlight291.Craft(rawValue:choice.shipType),
              (0...2).contains(choice.shipType),
              H55SourceMechanics580.registeredModelName(
                  forShip:choice.shipType) != nil,
              PC602HomeFlight291.Equipment(craft:craft) != nil else {
            return "BRAK ORYGINALNEGO MODELU WYBRANEGO STATKU PC609"
        }
        guard Sector01CarbonisPreview568.isAvailable else {
            return "BRAK ZWERYFIKOWANYCH ZASOBÓW CARBONIS 01 — PROFIL NIEZMIENIONY"
        }
        guard PC602HomeWorldDriver291.resourcesInstalled(
                  forShip:choice.shipType) else {
            return "BRAK ZASOBÓW H290 LUB WYBRANEGO STATKU — PROFIL NIEZMIENIONY"
        }
        // Use the same one canonical PC602 orbit constructor, but with
        // the new campaign's initial ship and service profile. This MUST
        // precede destructive profile reset: no split-brain previous craft.
        var freshMechanics=H55SourceMechanics580.State()
        freshMechanics.selectedShip=choice.shipType
        let freshShop=Sector01Shop568.State(lives:SourceNewGame568.startingLives(
            difficulty:choice.difficulty,shipType:choice.shipType))
        do {
            try homeWorld291.start(
                progress:CampaignProgress556(),
                mechanicsOverride:freshMechanics,
                shopOverride:freshShop)
        } catch {
            return "NIE MOŻNA URUCHOMIĆ ORYGINALNEJ ORBITY H290: " +
                   String(describing:error) + " — PROFIL NIEZMIENIONY"
        }
        guard SourceNewGame568.create(choice) else {
            homeWorld291.stop()
            return "NIE UDAŁO SIĘ ZABEZPIECZYĆ POPRZEDNIEGO PROFILU — BRAK ZMIAN"
        }
        campaign=CampaignStore556.load()
        sourceSector01=nil
        sourceSector01Setup=nil
        returnHomeWorldAfterCarbonis291=false
        showingMissionIntro568=false
        missionCheckpoint61=nil
        input.releaseHeldControls()
        input.gameplayPaused=true
        reopenAtlasAfterCarbonis=false
        PC602OrbitSave61.clearResume()
        audio.enterOrbit602()
        showingHomeWorld291=true
        showMainMenu=false
        return nil
    }
    // Windows Program.cs:94 + UiW3NativeLayout315.DrawW3Splash323:
    // music preparation -> persistent press-Enter W3 splash -> HOME.
    // Existing explicit GPU/UI verification still enters its requested scene.
    @State private var startupSplashPassed568 = W3StartupPolicy568
        .skipForDiagnostic(ProcessInfo.processInfo.environment)
    // Test-only simulator access to the real W3/H290 touch interfaces.
    // A CI simulator needs >360 seconds to synthesize source menu music;
    // unrelated UI tests must not fail before they reach the HUD editor.
    // iPhone Release cannot enable this bypass (compile-time excluded).
    private var h290SimulatorUITest291:Bool {
        #if targetEnvironment(simulator)
        ProcessInfo.processInfo.environment["ASTEROIDY_H290_SIMULATOR_UI_VERIFY"]=="1"
        #else
        false
        #endif
    }
    // The genuine W3 navigation is the normal entry point.
    // Existing source-GPU verification remains an explicit simulator mode.
    @State private var showMainMenu =
        ProcessInfo.processInfo.environment["ASTEROIDY_RENDER_VERIFY"] != "1" &&
        ProcessInfo.processInfo.environment["ASTEROIDY_SHIP367_VERIFY"] != "1"
    var body: some View {
        GeometryReader { g in
            ZStack {
                if let sourceEntry=sourceSector01,
                   let preparedWave=sourceSector01Setup {
                    if showingMissionIntro568 {
                        MissionCinematic568(sector:sourceEntry.sector,
                                           input:missionIntroInput568,
                                           onComplete:{
                            finishMissionIntro568(sector:sourceEntry.sector)
                        },onCancel:cancelMissionIntro568)
                    } else {
                    Sector01Scene568(entry:sourceEntry,returnToAtlas:{
                        sourceSector01 = nil
                        sourceSector01Setup = nil
                        input.releaseHeldControls()
                        input.gameplayPaused = true
                        if returnHomeWorldAfterCarbonis291 {
                            returnHomeWorldAfterCarbonis291=false
                            homeWorld291.refreshCampaign(campaign)
                            showingHomeWorld291=true
                            showMainMenu=false
                            homeWorld291.setSuspended(scenePhase != .active)
                            audio.enterOrbit602()
                        } else {
                            reopenAtlasAfterCarbonis = true
                            audio.returnToMenu()
                            showMainMenu = true
                        }
                    },onExitToMainMenu:{
                        // A deliberate pause-menu exit is not the source
                        // mission completion/service return to orbit.
                        sourceSector01=nil
                        sourceSector01Setup=nil
                        showingMissionIntro568=false
                        returnHomeWorldAfterCarbonis291=false
                        showingHomeWorld291=false
                        reopenAtlasAfterCarbonis=false
                        input.releaseHeldControls()
                        input.gameplayPaused=true
                        missionIntroInput568.releaseHeldControls()
                        missionIntroInput568.gameplayPaused=true
                        homeWorld291.stop()
                        audio.returnToMenu()
                        showMainMenu=true
                    },onMissionCompleted:{ report in
                        // Only the real Game.FinishLevel source outcome can
                        // persist completed sector 1 and its token reward.
                        var changed=campaign
                        _ = Sector01MissionSettlement568.commit(
                            report,campaign:&changed)
                        campaign=changed
                        // PC Talents78.CompleteTimeTrial78: only actual
                        // Game.FinishLevel may award this (including a replay
                        // without a previous fast clear). No artificial
                        // trophies from menu, test preview or mere HUD event.
                        var source=H55SourceMechanics580.load()
                        if H55SourceMechanics580.awardTimeTrophy(
                            sector:report.sector,elapsed:report.elapsedSeconds,
                            objective:.normal,state:&source) {
                            _=H55SourceMechanics580.save(source)
                        }
                    },onSurvivalChanged:{ lives,charges,hull,armor in
                        Sector01Shop568.persistSurvival(
                            lives:lives,shieldCharges:charges)
                        // H11: real C279 battle gauges, available for actual
                        // H55 service/repair on return to hangar.
                        H55Workshop580.updateFromCombat(hull:hull,armor:armor)
                    },onAudioEvent:{ code in
                        audio.sourceEffect(code)
                    },onEnginePower:{ power in
                        audio.sourceEnginePower(power)
                    },onMissionPause:{ paused in
                        audio.missionUserPause568(paused)
                    },onMissionPhase:{ phase in
                        audio.missionPhase568(phase)
                    },onReplay:{
                        // A retry starts a NEW real mission, so replay
                        // must pass through Intro41 again before creating
                        // the fresh combat scene. Do not re-grant tokens
                        // for a sector already completed in the profile.
                        var retry=preparedWave
                        retry.isReplay=campaign.completed(sourceEntry.sector)
                            || preparedWave.isReplay
                        sourceSector01Setup=retry
                        beginMissionIntro568(sector:sourceEntry.sector)
                    },onSaveCheckpoint61:{ slot in
                        guard let checkpoint=missionCheckpoint61,
                              checkpoint.isMissionIntro61 else{return false}
                        do {
                            try PC602OrbitSave61.store(checkpoint,slot:slot)
                            return true
                        } catch {return false}
                    },onLoadSave61:{slot in
                        loadManualSave61(slot)
                    },preparedWave:preparedWave)
                    }
                } else if showingBoreasTest05 {
                    AnimatedPlanetTestPage556(input:input,
                                               onExit:returnFromBoreasTest05)
                        .ignoresSafeArea()
                } else if showingHomeWorld291 {
                    PC602HomeWorldPage291(
                        driver:homeWorld291,
                        audio:audio,
                        onExitToW3:{
                            _=homeWorld291.captureResume61()
                            missionCheckpoint61=homeWorld291.readFlight().flatMap {
                                PC602OrbitSave61.capture($0)
                            }
                            homeWorld291.stop()
                            showingHomeWorld291=false
                            returnHomeWorldAfterCarbonis291=false
                            showMainMenu=true
                            audio.returnToMenu()
                        },
                        onEnterMission:enterOrbitMission291,
                        onLoadIntro61:{slot in loadManualSave61(slot)},
                        onProfileRestored:{
                            campaign=CampaignStore556.load()
                        })
                        .ignoresSafeArea()
                } else if showMainMenu {
                    if !audio.startupComplete && !h290SimulatorUITest291 {
                        OriginalAudioLoadingView568(audio:audio)
                    } else {
                    ZStack {
                    W3MainMenu568(progress:campaign,selectMission:{ sector in
                        if campaign.selectUnlocked(sector) {
                            CampaignStore556.save(campaign)
                        }
                    },inspectSector: { sector in
                        inspectSourceSector(sector)
                    },openBoreasTest:enterBoreasTest05,openDiagnostic:{
                        input.releaseHeldControls()
                        input.gameplayPaused = false
                        reopenAtlasAfterCarbonis = false
                        audio.stopForDiagnostic()
                        showMainMenu = false
                    },openCampaignOnEntry:reopenAtlasAfterCarbonis,
                    startNewGame:startNewGameFromW3,
                    openOrbit:enterHomeWorld291,
                    loadManualOrbit:{ slot in
                        loadManualSave61(slot)
                    },
                    canSaveMenu61:menuCheckpoint61() != nil,
                    saveMenuSlot61:saveMenuCheckpoint61,
                     continueOrbit:{
                        // PC602 ContinueActive358: use a valid flight checkpoint
                        // when available; otherwise restart H290 from the
                        // independently validated active61 campaign profile.
                        if !PC602OrbitSave61.exists() ||
                           !homeWorld291.loadOrbitSlot61(nil) {
                            guard SourceNewGame568.canContinueActive358()
                            else{return "BRAK PRAWIDŁOWEGO PROFILU AUTOMATYCZNEGO"}
                            do {
                                try homeWorld291.start(progress:CampaignStore556.load())
                            } catch {
                                return "NIE MOŻNA PRZYWRÓCIĆ KAMPANII: " +
                                    String(describing:error)
                            }
                        }
                        campaign=CampaignStore556.load()
                        input.releaseHeldControls()
                        input.gameplayPaused=true
                        homeWorld291.setPaused(false)
                        showingHomeWorld291=true
                        showMainMenu=false
                        audio.enterOrbit602()
                        return nil
                    },
                    restoreArchivedGame:{ archive in
                        // A restore is initiated only by a confirmed W3
                        // user action. Refresh the actual campaign state
                        // after the archive coordinator validates the file.
                        guard sourceSector01==nil,
                              SourceNewGame568.restoreArchive(at:archive)
                        else{return false}
                        campaign=CampaignStore556.load()
                        PC602OrbitSave61.clearResume()
                        input.releaseHeldControls()
                        input.gameplayPaused=true
                        return true
                    })
                        .allowsHitTesting(startupSplashPassed568)
                        .accessibilityHidden(!startupSplashPassed568)
                    if !startupSplashPassed568 {
                        W3StartupSplash568(onContinue:{
                            startupSplashPassed568=true
                        })
                        .zIndex(1)
                    }
                    }
                    }
                } else {
                MetalScene(input: input)
                    .ignoresSafeArea()
                VStack {
                    if let error = input.rendererError { Text(error).font(.system(size: 12, weight: .bold)).foregroundStyle(.red).padding(8).background(.black.opacity(0.9)) }
                    // Two compact rows keep the native source-scene
                    // switch reachable in landscape on BOTH iPhone/iPad.
                    HStack {
                        Text("ASTEROIDY  •  iOS v21")
                            .font(.system(size: 17, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.cyan)
                        Spacer(minLength: 8)
                        Button(input.introPreview41 ? "BOREAS 3D" : "PRZELOT 3D") {
                            input.introPreview41.toggle()
                            input.planetPreview = true
                            input.tarczaHeld = false
                            input.shooting = false
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.cyan)
                        Button("MENU W3") {
                            input.releaseHeldControls()
                            input.gameplayPaused = true
                            showMainMenu = true
                            audio.returnToMenu()
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.cyan)
                        Button("KAMPANIA / W3") {
                            input.releaseHeldControls()
                            reopenAtlasAfterCarbonis = true
                            input.gameplayPaused = true
                            showMainMenu = true
                            audio.returnToMenu()
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.cyan)
                        .accessibilityIdentifier("diagnostic-return-w3-campaign")
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    if !input.introPreview41 {
                        HStack(spacing: 12) {
                            Button(input.planetPreview ? "ARENA • DIAGNOSTYKA" : "BOREAS GLB • TEST") {
                                input.planetPreview.toggle()
                                input.tarczaHeld = false
                                input.shooting = false
                            }
                            Spacer(minLength: 4)
                            Button(input.sectorTraining ? "SEKTOR 01 • TEST" : "9 ASTEROID • TEST") {
                                input.sectorTraining.toggle()
                            }
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 18)
                    }
                    if input.introPreview41 {
                        Text("PRZELOT ORBITALNY / ŹRÓDŁOWA KAMERA • \(Int(input.introProgress41)) / 16 s")
                            .font(.system(size: 11, weight: .medium,
                                          design: .monospaced))
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 18)
                        Text("SCENA ROBOCZA • NIE JEST PEŁNĄ MISJĄ")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 18)
                    } else {
                    HStack {
                        Text("WYNIK: \(input.score)")
                        Spacer()
                        Text("ASTEROIDY: \(input.trainingRockCount)")
                        Spacer()
                        Text(input.planetPreview && input.verifiedDamageLab
                             ? "ŻYCIA V556: \(input.hull)" : "KADŁUB: \(input.hull)")
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.horizontal, 18)
                    if input.planetPreview {
                        Menu {
                            Button("SEKTOR 01 · ASTEROIDY") {
                                input.planetTestLevel = 1
                                input.tarczaHeld = false
                                input.shooting = false
                            }
                            Button("SEKTOR 09 · FALE WALKI") {
                                input.planetTestLevel = 9
                                input.tarczaHeld = false
                                input.shooting = false
                            }
                            Button("SEKTOR 17 · FALE WALKI") {
                                input.planetTestLevel = 17
                                input.tarczaHeld = false
                                input.shooting = false
                            }
                            Button("SEKTOR 25 · AMIGA / PIŁKI ODBIJANE") {
                                input.planetTestLevel = 25
                                input.tarczaHeld = false
                                input.shooting = false
                            }
                        } label: {
                            Text("WYBIERZ SEKTOR TESTOWY: \(input.planetTestLevel)")
                                .font(.system(size: 11, weight: .medium,
                                              design: .monospaced))
                                .foregroundStyle(.cyan)
                        }
                        Button(input.sourceShip367Preview
                               ? "STATEK 03 · ORYGINAŁ v568 (TEST)"
                               : "STATEK v556 · TEST") {
                            input.sourceShip367Preview.toggle()
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.cyan)
                        HStack {
                            Button(input.verifiedDamageLab
                                   ? "TEST OBRAŻEŃ v556: WŁ." : "TEST OBRAŻEŃ v556: WYŁ.") {
                                input.verifiedDamageLab.toggle()
                                input.tarczaHeld = false
                            }
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.orange)
                            if input.verifiedDamageLab {
                                Text(input.verifiedGameOver
                                     ? "KONIEC GRY • TEST" :
                                     "BEZ STRAŻNIKA • UTRATY ŻYCIA: \(input.verifiedDeaths)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(input.verifiedGameOver ? .red : .yellow)
                            }
                        }
                        if input.verifiedDamageLab {
                            Text("PANCERZ: \(input.verifiedArmor)/25 · KADŁUB: \(input.verifiedHull)/60")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.yellow)
                            Text("TARCZA v556: \(Int(input.verifiedTarczaEnergy.rounded()))/100")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(input.verifiedTarczaActive ? .cyan : .gray)
                        }
                        if input.planetAmigaDemo {
                            Text("AMIGA / PIŁKI ODBIJANE")
                                .font(.system(size: 11, weight: .medium,
                                              design: .monospaced))
                                .foregroundStyle(.cyan)
                            Text("TRAFIENIA: \(input.planetAmigaHits) · POKAZ DEMO · STRZELAJ, ABY NADAĆ PĘD")
                                .font(.system(size: 10,design:.monospaced))
                                .foregroundStyle(.white)
                        } else {
                            Text(input.planetSectorCleared
                                 ? "TEST SEKTORA UKOŃCZONY"
                                 : input.planetIncomingNotice
                                 ? "NOWE ASTEROIDY NA ORBICIE"
                                 : "BOREAS • SYMULACJA WALKI • FALA \(input.planetWave)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(input.planetSectorCleared ? .green :
                                             input.planetIncomingNotice ? .orange : .cyan)
                        }
                    }
                    Spacer()
                    HStack(alignment: .bottom) {
                        TouchPad(input: input)
                            .frame(width: input.planetPreview && input.verifiedDamageLab
                                   ? min(120, max(95, g.size.width * 0.28)) : 150,
                                   height: input.planetPreview && input.verifiedDamageLab
                                   ? min(120, max(95, g.size.width * 0.28)) : 150)
                        Spacer(minLength: 4)
                        if input.planetPreview && input.verifiedDamageLab {
                            Text("TARCZA")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .frame(width: 68, height: 68)
                                .background(input.tarczaHeld
                                    ? Color.cyan.opacity(0.65) : Color.cyan.opacity(0.2),
                                    in: Circle())
                                .overlay(Circle().stroke(.cyan, lineWidth: 2))
                                .gesture(DragGesture(minimumDistance: 0)
                                    .onChanged { _ in input.tarczaHeld = true }
                                    .onEnded { _ in input.tarczaHeld = false })
                                .accessibilityLabel("Przytrzymaj tarczę v556")
                        }
                        Text("OGIEŃ")
                            .font(.system(.headline, design: .monospaced))
                            .frame(width: input.planetPreview && input.verifiedDamageLab
                                   ? min(86, max(72, g.size.width * 0.22)) : 100,
                                   height: input.planetPreview && input.verifiedDamageLab
                                   ? min(86, max(72, g.size.width * 0.22)) : 100)
                            .background(input.shooting ? Color.orange.opacity(0.8) : Color.orange.opacity(0.25), in: Circle())
                            .overlay(Circle().stroke(.orange, lineWidth: 2))
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { _ in input.shooting = true }
                                .onEnded { _ in input.shooting = false })
                            .accessibilityLabel("Strzelaj")
                    }.padding(.horizontal,
                               input.planetPreview && input.verifiedDamageLab ? 16 : 45)
                     .padding(.bottom, 30)
                    }
                }
                .foregroundStyle(.white)
                }
                // The original does not display FPS in W3 main menu.
                // The diagnostic scene is separate from CARBONIS mission.
                if !showMainMenu && sourceSector01 == nil {
                    SourcePerformanceOverlay568()
                        .frame(maxWidth:.infinity,maxHeight:.infinity,
                               alignment:.bottomTrailing)
                        .padding(.trailing,14)
                        .padding(.bottom,18)
                        .allowsHitTesting(false)
                }
            }.frame(width: g.size.width, height: g.size.height)
        }
        .onAppear {
            if !h290SimulatorUITest291 {audio.prepareMenuAtStartup()}
        }
        .onChange(of: scenePhase) { phase in
            audio.sceneIsActive(phase == .active)
            input.gameplayPaused = phase != .active || showMainMenu
            missionIntroInput568.gameplayPaused =
                phase != .active || !showingMissionIntro568
            homeWorld291.setSuspended(
                phase != .active || !showingHomeWorld291)
            if phase != .active {
                input.releaseHeldControls()
                missionIntroInput568.releaseHeldControls()
            }
        }
        .onChange(of: showMainMenu) { visible in
            input.gameplayPaused = visible || scenePhase != .active
            if visible {
                input.releaseHeldControls()
                homeWorld291.setSuspended(true)
            }
            if visible && sourceSector01 == nil { audio.returnToMenu() }
        }
    }
}

// Real unlocked-only 26-sector selection from Orbit50.MissionUnlocked50.
// LaunchOrbitMission50 / StartHubMission261 combat are NOT ported yet.
// Full CARBONIS first mission completion is earned from the actual
// combat world; later sectors are still under active porting.
struct CampaignAtlas556: View {
    let progress: CampaignProgress556
    let dismiss: () -> Void
    let onSelect: (Int) -> Void
    let onInspect: (Int) -> Void
    let onEnterOrbit:()->String?
    let onBoreasTest:()->Void
    @State private var orbitLaunchIssue=""
    private let columns = [GridItem(.adaptive(minimum:52,maximum:90),spacing:8)]

    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:12) {
                HStack {
                    Text("KAMPANIA / 26 SEKTORÓW")
                        .font(.system(size:18,weight:.bold,design:.monospaced))
                        .foregroundStyle(Color(red:0.89,green:0.67,blue:0.31))
                    Spacer()
                    Text("ATLAS / W3")
                        .font(.system(size:11,design:.monospaced))
                        .foregroundStyle(Color(red:0.39,green:0.75,blue:0.79))
                }
                Text("UKOŃCZONE: \(progress.completedCount) / 26")
                    .font(.system(.subheadline,design:.monospaced))
                    .foregroundStyle(.cyan)
                Text("WYBRANY SEKTOR: \(String(format:"%02d",progress.selectedSector))")
                    .font(.system(size:13,weight:.bold,design:.monospaced))
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("campaign-selected-sector")
                Text(MissionCatalog568.title(for:progress.selectedSector) ?? "BRAK SEKTORA")
                    .font(.system(size:11,weight:.semibold,design:.monospaced))
                    .foregroundStyle(.cyan)
                    .accessibilityIdentifier("campaign-selected-planet")
                // Original Boreas is sector 05 on PC. Offer a separate
                // authenticated visual test without selecting/unlocking it.
                if AnimatedPlanetTestSlot556.sourceAssetsVerified {
                    Button("BOREAS 05 · TEST ANIMOWANEJ PLANETY GLB") {
                        onBoreasTest()
                    }
                    .font(.system(size:12,weight:.bold,design:.monospaced))
                    .foregroundStyle(.black)
                    .frame(maxWidth:.infinity,minHeight:46)
                    .background(Color(red:0.39,green:0.75,blue:0.79))
                    .accessibilityIdentifier("campaign-boreas05-animated-test")
                    Text("TYMCZASOWY MODEL DO PÓŹNIEJSZEJ PODMIANY · NIE ODBLOKOWUJE MISJI 05")
                        .font(.system(size:10,design:.monospaced))
                        .foregroundStyle(.secondary)
                } else {
                    Text("BOREAS 05 · BRAK WERYFIKACJI ORYGINALNYCH DANYCH ANIMACJI")
                        .font(.system(size:11,design:.monospaced))
                        .foregroundStyle(.orange)
                }
                if progress.selectedSector == 1 {
                    VStack(alignment:.leading,spacing:5) {
                        Text("CARBONIS — ORYGINALNA PLANETA 3D / ŹRÓDŁOWA SIATKA")
                            .font(.system(size:10,weight:.semibold,design:.monospaced))
                            .foregroundStyle(.orange)
                        if Sector01CarbonisPreview568.isAvailable {
                            Sector01CarbonisPreview568()
                                .frame(height:166)
                                .accessibilityLabel("Źródłowa planeta CARBONIS, podgląd 3D")
                        } else {
                            Text("BRAK ZWERYFIKOWANEJ SIATKI C279 W PAKIECIE")
                                .font(.system(size:10,design:.monospaced))
                                .foregroundStyle(.secondary)
                        }
                        Text("GRAJ W CARBONIS 01 · UKOŃCZENIE ODBLOKOWUJE SEKTOR 02")
                            .font(.system(size:10,design:.monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth:.infinity,alignment:.leading)
                }
                LazyVGrid(columns:columns,spacing:8) {
                    ForEach(1...CampaignProgress556.missionCount,id:\.self) { sector in
                        let finished=progress.completed(sector)
                        let available=progress.unlocked(sector)
                        let current=progress.selectedSector == sector
                        Button {
                            // Protect original orbit unlock state, also in
                            // case a programmatic callback invokes this.
                            if available { onSelect(sector) }
                        } label: {
                            VStack(spacing:4) {
                                Text(String(format:"%02d",sector))
                                    .font(.system(.headline,design:.monospaced))
                                Image(systemName:finished ? "checkmark.circle.fill"
                                      : current ? "location.circle.fill"
                                      : available ? "circle" : "lock.fill")
                            }
                            .foregroundStyle(current ? Color.orange :
                                             finished ? Color.green :
                                             available ? Color.cyan : Color.gray)
                            .frame(maxWidth:.infinity,minHeight:48)
                            .background(current
                                ? Color(red:0.11,green:0.077,blue:0.031)
                                : Color(red:0.013,green:0.055,blue:0.081))
                            .overlay {
                                Rectangle()
                                    .stroke(current
                                        ? Color(red:0.89,green:0.67,blue:0.31)
                                        : Color(red:0.39,green:0.75,blue:0.79).opacity(0.22),
                                            lineWidth:current ? 2 : 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!available)
                        .accessibilityIdentifier("campaign-sector-\(sector)")
                        .accessibilityLabel(
                            "Sektor \(sector), \(MissionCatalog568.title(for:sector) ?? "brak nazwy"), " +
                            "\(finished ? "ukończony" : available ? "odblokowany" : "zablokowany")")
                        .accessibilityAddTraits(.isButton)
                    }
                }
                Button("WEJDŹ DO ORBITY 3D / PC v602") {
                    orbitLaunchIssue=onEnterOrbit() ?? ""
                }
                .font(.system(size:12,weight:.bold,design:.monospaced))
                .foregroundStyle(.black)
                .frame(maxWidth:.infinity,minHeight:44)
                .background(Color(red:0.39,green:0.75,blue:0.79))
                .disabled(!PC602HomeWorldDriver291.resourcesInstalled)
                .opacity(PC602HomeWorldDriver291.resourcesInstalled ? 1 : 0.45)
                .accessibilityIdentifier("campaign-enter-original-orbit291")
                if !orbitLaunchIssue.isEmpty {
                    Text(orbitLaunchIssue)
                        .foregroundStyle(.orange)
                        .font(.system(size:11,design:.monospaced))
                }
                if !PC602HomeWorldDriver291.resourcesInstalled {
                    Text("BRAK ZWERYFIKOWANYCH ZASOBÓW ORBITY PC602")
                        .font(.system(size:10,design:.monospaced))
                        .foregroundStyle(.orange)
                }
                Text("Dotknij odblokowanego sektora, aby go wybrać. Wybór jest zapisywany, ale nie zalicza misji.")
                    .font(.system(size:11,design:.monospaced))
                    .foregroundStyle(.secondary)
                if progress.selectedSector == 1 &&
                   progress.unlocked(1) &&
                   Sector01CarbonisPreview568.isAvailable {
                    Button("ROZPOCZNIJ CARBONIS 01 / PEŁNA WALKA") {
                        onInspect(1)
                    }
                    .font(.system(size:12,weight:.bold,design:.monospaced))
                    .foregroundStyle(.black)
                    .frame(maxWidth:.infinity,minHeight:46)
                    .background(Color(red:0.89,green:0.67,blue:0.31))
                    .accessibilityIdentifier("campaign-enter-source-sector01")
                }
                Text("SEKTOR 01: WALKA, RAPORT, ŻETONY I ZAPIS · POZOSTAŁE SEKTORY W OPRACOWANIU")
                    .font(.system(size:11,weight:.bold,design:.monospaced))
                    .foregroundStyle(.orange)
            }
            .padding(18)
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity)
        .background(Color(red:0.006,green:0.027,blue:0.047).opacity(0.96))
        .overlay(Rectangle().stroke(
            Color(red:0.39,green:0.75,blue:0.79).opacity(0.24),lineWidth:1))
        .accessibilityElement(children:.contain)
        .accessibilityIdentifier("campaign-26-sector-selector")
    }
}

struct TouchPad: View {
    @ObservedObject var input: FlightInput
    @State private var offset: CGSize = .zero
    var body: some View {
        GeometryReader { proxy in
            let r = min(proxy.size.width, proxy.size.height) * 0.31
            Circle().fill(.cyan.opacity(0.08)).overlay(Circle().stroke(.cyan.opacity(0.4)))
                .overlay(
                    Circle().fill(.cyan.opacity(0.35))
                        .frame(width: 54, height: 54)
                        .offset(offset)
                )
                .contentShape(Circle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let dx = value.location.x - proxy.size.width / 2
                        let dy = value.location.y - proxy.size.height / 2
                        let length = max(1, sqrt(dx * dx + dy * dy))
                        let scale = min(1, r / length)
                        offset = CGSize(width: dx * scale, height: dy * scale)
                        input.steer = Float(offset.width / r)
                        input.thrust = Float(-offset.height / r)
                    }
                    .onEnded { _ in offset = .zero; input.steer = 0; input.thrust = 0 })
        }
    }
}

struct MetalScene: UIViewRepresentable {
    @ObservedObject var input: FlightInput
    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.sampleCount = 1
        view.clearColor = MTLClearColor(red: 0.01, green: 0.025, blue: 0.07, alpha: 1)
        view.preferredFramesPerSecond = 60
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        if let device = view.device {
            do {
                let renderer = try MetalRenderer(device: device, input: input)
                context.coordinator.renderer = renderer
                view.delegate = renderer
            } catch {
                DispatchQueue.main.async { input.rendererError = "Metal: \(error.localizedDescription)" }
            }
        } else {
            DispatchQueue.main.async { input.rendererError = "Metal nie jest dostępny na tym urządzeniu" }
        }
        return view
    }
    func updateUIView(_ uiView: MTKView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var renderer: MetalRenderer? }
}

