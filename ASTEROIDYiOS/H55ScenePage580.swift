import Foundation
import SceneKit
import SwiftUI
import GLTFKit2
import UniformTypeIdentifiers
import UIKit
import simd

/// The v580 H55 scene is distinct from GpuHangar91/99 (legacy).
/// GLTFKit2 performs glTF mesh/material/skin/animation decoding; no HTML.
/// This view never substitutes a procedural or old hangar for the user's GLB.
@MainActor final class H55SceneModel580: ObservableObject {
    enum Phase { case missing, loading, ready, failed(String) }
    @Published private(set) var phase: Phase = .missing
    @Published private(set) var scene: SCNScene?
    @Published private(set) var camera: SCNNode?
    @Published private(set) var firstFramePresented=false
    @Published private(set) var animationNames: [String] = []
    @Published private(set) var playingClip: String?
    @Published private(set) var inventory: H55Asset580.Inventory?
    private var animations: [String:GLTFSCNAnimation] = [:]
    private var activeKeys: Set<String> = []
    private var generation = UUID()
    private var movement=H55Walk580()
    private var physical:H55SpatialSupport580?
    private var npcSurface:H55NpcSurface580?
    // H07 source PC580 independent H70 doors, separate from static H02-H04.
    private var airlocks=H55AirlockController580()
    private var airlockTracks:H55AirlockTracks580.SceneKeys?
    private var airlockLeaves:[String:SCNNode]=[:]
    private var airlockLastApplied:[Float]=[Float.nan,Float.nan]
    private var h46LightNodes:[String:SCNNode]=[:]
    private var h46RawIntensities:[String:Float]=[:]
    private weak var exteriorSky:SCNNode?
    private weak var playerShip:SCNNode?
    private var lighting=H55LightingProfile580.saved()
    private var lightRefresh:Float=0
    private var pausedForSettings=false
    private var firstTickLogged=false
    private var arrival=H55Arrival580(spawnClear:false)
    @Published private(set) var arriving=false
    private var moveForward:Float=0
    private var moveRight:Float=0
    private var clock:CADisplayLink?
    private var lastTick:CFTimeInterval?
    @Published private(set) var mechanicNearby=false
    @Published private(set) var conversationOpen=false
    // H11 source Hub90.OpenHubPanel90: six native panels over active H55.
    @Published private(set) var showingWorkshop=false
    @Published private(set) var workshopInitialPanel=0
    @Published private(set) var conversationsFinished=0
    // H10 canonical source HubNpcInteract526 lifecycle; published flags mirror it.
    private var dialogue=H55NpcDialogue580()
    private var mechanic=H55Mechanic580()
    private weak var mechanicRoot:SCNNode?
    private var mechanicBaseOrientation:simd_quatf?
    // H09 exclusively samples the original GLB idle/walk on its 80 bones.
    // Never start concurrent automatic SceneKit NPC animation players.
    private var npcAnimator:H55NpcSceneAnimator580?
    private var machinery:H55H12SceneAnimator580?
    // H71 moves only the two source-selected GLB drone prefab roots.
    private var droneScene:H55DroneScene580?
    @Published private(set) var h71Status="H71: ODŁOŻONE DO PÓŹNIEJSZEGO ETAPU"
    @Published private(set) var h12Status="NIE WCZYTANO ANIMACJI H12"
    @Published private(set) var h13MaterialReport="H13: ORYGINALNY GLB NIE WCZYTANY"
    @Published private(set) var mechanicStatus="OCZEKUJE NA ROZMOWĘ"

    func jump() {
        guard !conversationOpen && !showingWorkshop && arrival.walking else{return}
        guard let physical else{return}
        _=movement.jump(collision:physical)
    }
    func setMove(forward:Float,right:Float) {
        // PC HubKey90 prioritizes open dialogue over all walking/jump input.
        if conversationOpen || showingWorkshop {moveForward=0;moveRight=0;return}
        moveForward=max(-1,min(1,forward))
        moveRight=max(-1,min(1,right))
    }
    func look(dx:Float,dy:Float) {
        guard arrival.walking && !showingWorkshop else{return}
        movement.look(deltaX:dx,deltaY:dy)
        camera?.eulerAngles=SCNVector3(H55TouchMapping580.scenePitch(for:movement.pitch),
                H55TouchMapping580.sceneYaw(for:movement.yaw),0)
    }
    func interact() {
        guard !showingWorkshop else{return}
        let action=dialogue.interact(walking:arrival.walking,
            playerX:movement.x,playerZ:movement.z,
            npcX:mechanic.x,npcZ:mechanic.z)
        switch action {
        case .ignored: return
        case .opened:
            setMove(forward:0,right:0) // zero existing left drag before lock
            conversationOpen=true
            mechanicStatus=H55NpcDialogue580.openNotice
        case .closed:
            conversationOpen=false
            conversationsFinished=dialogue.finished
            // PC H55Renderer v526 arms exactly ONE patrol on completion;
            // actual motion only starts once the player moves >2.5m away.
            mechanic.finishConversation()
            mechanicStatus="PATROL GOTOWY — ODDAL SIĘ"
        }
    }

    func openWorkshop() {
        guard arrival.walking && !conversationOpen && !showingWorkshop else{return}
        // PC HubWalk375.HubWalkInteract375: near console (9.4,9.85)
        // within 3.55m => SERWIS #4, otherwise STATEK #0.
        workshopInitialPanel=hypot(movement.x-9.4,movement.z-9.85)<3.55 ? 4 : 0
        setMove(forward:0,right:0)
        showingWorkshop=true
    }
    func closeWorkshop() {
        showingWorkshop=false
        setMove(forward:0,right:0)
    }
    func skipArrival() {arrival.skip()}

    /// Three SCNView render passes must complete before visual arrival t=0.
    /// GLB decode / scene attach is not proof that iOS has displayed a frame.
    func firstRenderedFramesReady(for rendered:SCNScene) {
        guard scene === rendered, !firstFramePresented,
              case .ready = phase else{return}
        firstFramePresented=true
        H55LoadDiagnostics580.mark("12A_GPU_TRZY_KLATKI_GOTOWE_START_DOLLOTU")
        beginClock()
    }

    func pauseForSettings(_ pause:Bool) {
        guard pausedForSettings != pause else{return}
        pausedForSettings=pause
        if pause {
            moveForward=0
            moveRight=0
            clock?.invalidate()
            clock=nil
            lastTick=nil
        } else if case .ready = phase,firstFramePresented {
            beginClock()
        }
    }

    private func beginClock() {
        guard !pausedForSettings else{return}
        clock?.invalidate()
        lastTick=nil
        let link=CADisplayLink(target:self,selector:#selector(stepFrame(_:)))
        link.preferredFramesPerSecond=60
        link.add(to:.main,forMode:.common)
        clock=link
    }
    @objc private func stepFrame(_ link:CADisplayLink) {
        guard !pausedForSettings,let scene,camera != nil else{return}
        if !firstTickLogged {
            firstTickLogged=true
            H55LoadDiagnostics580.mark("13_PIERWSZY_TICK_CADISPLAYLINK")
        }
        let dt:Float
        if let last=lastTick {dt=Float(min(0.06,max(0,link.timestamp-last)))}
        else {dt=0}
        lastTick=link.timestamp
        guard dt>0 else{return}
        // PC Hub90.StepHub90: arrival clock runs before walking.
        arrival.advance(dt:dt)
        if arriving && !arrival.arriving {arriving=false}
        if !arrival.walking,let camera {
            // Windows GpuHub90: camera flies from (0,7.8,40) to (0,6.8,31)
            // while the ship approaches. H05 player physical spawn is fixed.
            let pose=H55DockingPresentation580.camera(time:arrival.time)
            camera.position=SCNVector3(pose.x,pose.y,pose.z)
            camera.look(at:SCNVector3(0,4,0))
        }
        if let craft=playerShip {
            H55PlayerShip580.pose(craft,time:arrival.time)
        }
        if arrival.walking && !conversationOpen,let physical {
        movement.step(dt:dt,
            forward:showingWorkshop ? 0 : moveForward,
            right:showingWorkshop ? 0 : moveRight,
            sprint:false,collision:physical,
            doorBlocks:{ax,az,bx,bz in
                self.airlocks.blockingGate(fromX:ax,fromZ:az,toX:bx,toZ:bz) != nil
            })
        // PC v580 GpuHub90: bob is visual only; physical capsule Y is untouched.
        // Original HangarBob400 default=50%, render sway at actual footfall.
        let bobPower:Float=0.5*movement.bobAmount
        let phase=movement.bobPhase
        let sway=sin(phase)*0.042*bobPower
        let bounce=sin(phase*2)*0.052*bobPower
        let cy=cos(movement.yaw),sy=sin(movement.yaw)
        camera?.position=SCNVector3(movement.x+cy*sway,
                movement.cameraFeet+H55Walk580.eyes+bounce,
                movement.z+sy*sway)
        let roll=(sin(phase)*0.0085+movement.lean*0.006)*bobPower
        camera?.eulerAngles=SCNVector3(H55TouchMapping580.scenePitch(for:movement.pitch),
                H55TouchMapping580.sceneYaw(for:movement.yaw),roll)
        if let npcSurface {
            // H08 original NpcSafeWalk530 (with authentic seam support).
            // The player controls cannot bypass the actor's validated floor.
            mechanic.step(dt:dt,playerX:movement.x,playerZ:movement.z,
                canWalk:{x,z in npcSurface.ground(x:x,z:z) != nil},
                groundAt:{x,z in npcSurface.ground(x:x,z:z)},
                doorBlocking:{ax,az,bx,bz in
                self.airlocks.blockingGate(fromX:ax,fromZ:az,toX:bx,toZ:bz)
                })
        }
        if let root=mechanicRoot {
            root.position=SCNVector3(mechanic.x,mechanic.y,mechanic.z)
            if let original=mechanicBaseOrientation {
                // Same quaternion product as Windows H55Renderer.cs:1618-22.
                root.simdOrientation=simd_quatf(angle:mechanic.yaw,
                     axis:SIMD3<Float>(0,1,0))*original
            }
        }
        // H09 mocap evaluated below, after the H08 collision/root update.
        let nextStatus:String
        switch mechanic.phase {
        case .idle: nextStatus="OCZEKUJE NA ROZMOWĘ"
        case .walking:
            nextStatus=mechanic.avoidingPlayer
                ? "MECHANIK OMIJA GRACZA"
                : "PATROL DO WARSZTATU I POWRÓT"
        case .workshop: nextStatus="WARSZTAT — POSTÓJ 5 s"
        case .blocked:
            if let gate=mechanic.doorFailure {
                nextStatus=gate==0
                    ? "MECHANIK: ŚLUZA HANGARU ZABLOKOWANA — PATROL PRZERWANY"
                    : "MECHANIK: ŚLUZA WARSZTATU ZABLOKOWANA — PATROL PRZERWANY"
            } else if mechanic.doorWait>0.20 {
                nextStatus="MECHANIK CZEKA NA OTWARCIE DRZWI"
            } else if mechanic.playerBlockedSeconds>0.9 {
                nextStatus="GRACZ BLOKUJE PRZEJŚCIE — MECHANIK CZEKA"
            } else {nextStatus="MECHANIK — KOLIZJA / TRASA ZABLOKOWANA"}
        case .completed: nextStatus="MECHANIK WRÓCIŁ"
        }
        if nextStatus != mechanicStatus {mechanicStatus=nextStatus}
        let near=hypot(movement.x-mechanic.x,movement.z-mechanic.z)<=2.7
        if near != mechanicNearby {mechanicNearby=near}
        }
        // The same source sky stays in camera space, without parallax.
        if let camera {exteriorSky?.position=camera.position}
        // Continue authentic idle during arrival and conversation.
        npcAnimator?.apply(dt:dt,mechanic:mechanic,
                           allowWalking:arrival.walking && !conversationOpen)
        // PC v580: update doors AFTER NPC movement; keep animating during
        // 3.25s arrival and while the conversation blocks walking.
        // PC GpuHub90: composite H51 then machinery, before H70 doors.
        // Authored bind/root first, current H51/H39/H46 animation next,
        // dynamic H71 pilot world delta last — exactly source PC rendering.
        droneScene?.restoreSourceRoots()
        machinery?.advance(dt:dt)
        if let droneScene {
            droneScene.advance(dt:dt,player:H55DroneFlight580.Player(
                walking:arrival.walking,position:SIMD3<Float>(
                    movement.x,movement.y,movement.z),yaw:movement.yaw))
            if h71Status != droneScene.status {h71Status=droneScene.status}
        }
        updateAirlocks(dt:dt)
        lightRefresh+=dt
        if lightRefresh>=0.16 {
            lightRefresh=0
            updateH46LightBudget()
        }
    }

    func setLighting(fill:Double,red:Double) {
        lighting=H55LightingProfile580(fill:Float(fill),red:Float(red))
        if let scene {H55SceneLighting580.update(scene:scene,profile:lighting)}
        updateH46LightBudget()
    }

    private func updateH46LightBudget() {
        guard !h46LightNodes.isEmpty else{return}
        // Preserve PC distance ranking within each family. SceneKit's PBR
        // response is different: cap RED slots to 2 so white/cyan H46 can
        // illuminate the hangar rather than eight red lamps taking over.
        let candidates=h46LightNodes.map { (name,node) -> H55LightBalance580.Candidate in
            let p=node.simdWorldPosition
            let dx=p.x-movement.x,dy=p.y-(movement.y+H55Walk580.eyes),dz=p.z-movement.z
            return .init(name:name,distanceSquared:dx*dx+dy*dy+dz*dz)
        }
        let selected=Set(H55LightBalance580.selectedNames(candidates))
        SCNTransaction.begin()
        SCNTransaction.disableActions=true
        for (name,node) in h46LightNodes {
            let next:CGFloat=selected.contains(name)
                ? CGFloat(H55LightBalance580.sceneIntensity(
                    name,raw:h46RawIntensities[name] ?? 0,redGain:lighting.red))
                : 0
            if node.light?.intensity != next {node.light?.intensity=next}
        }
        SCNTransaction.commit()
    }

    private func updateAirlocks(dt:Float) {
        airlocks.step(playerX:movement.x,playerZ:movement.z,
            playerPresent:arrival.walking && !conversationOpen,
            npcX:mechanic.x,npcZ:mechanic.z,
            npcPresent:mechanic.isPatrolling,dt:dt)
        guard let keys=airlockTracks else{return}
        // Stable open/closed leaves must not dirty 4 SCNNode transforms
        // every frame on iPhone. Only real controller changes redraw.
        if airlockLastApplied == airlocks.openness {return}
        SCNTransaction.begin()
        SCNTransaction.disableActions=true
        for gate in 0..<2 {
            let amount=airlocks.openness[gate]
            if amount==airlockLastApplied[gate] {continue}
            let t=H55AirlockController580.clipTime(for:amount)
            for leaf in H55AirlockController580.leafNames[gate] {
                guard let node=airlockLeaves[leaf],
                      let p=keys.sample(leaf:leaf,time:t) else{continue}
                node.position=SCNVector3(p.x,p.y,p.z)
            }
            airlockLastApplied[gate]=amount
        }
        SCNTransaction.commit()
    }

    func openIfAvailable() {
        guard let url=H55Asset580.availableURL() else {
            phase = .missing
            return
        }
        open(url)
    }
    func open(_ url: URL) {
        H55LoadDiagnostics580.mark("01_START_WCZYTYWANIA_H55")
        lighting=H55LightingProfile580.saved()
        firstTickLogged=false
        firstFramePresented=false
        generation=UUID()
        let request=generation
        clock?.invalidate()
        clock=nil
        lastTick=nil
        movement=H55Walk580()
        physical=nil
        npcSurface=nil
        airlocks=H55AirlockController580()
        airlockTracks=nil
        airlockLeaves.removeAll()
        airlockLastApplied=[Float.nan,Float.nan]
        h46LightNodes.removeAll()
        h46RawIntensities.removeAll()
        exteriorSky=nil
        playerShip=nil
        lightRefresh=0
        arrival=H55Arrival580(spawnClear:false)
        arriving=false
        mechanic=H55Mechanic580()
        mechanicRoot=nil
        mechanicBaseOrientation=nil
        npcAnimator=nil
        machinery=nil
        droneScene=nil
        h71Status="H71: ODŁOŻONE DO PÓŹNIEJSZEGO ETAPU"
        h12Status="NIE WCZYTANO ANIMACJI H12"
        h13MaterialReport="H13: ORYGINALNY GLB NIE WCZYTANY"
        mechanicStatus="OCZEKUJE NA ROZMOWĘ"
        showingWorkshop=false
        dialogue.reset()
        conversationOpen=false
        conversationsFinished=0
        mechanicNearby=false
        phase = .loading
        scene=nil
        camera=nil
        inventory=nil
        animationNames=[]
        animations.removeAll()
        activeKeys.removeAll()
        DispatchQueue.global(qos:.userInitiated).async {
            do {
                let metadata=try H55Asset580.inspect(url)
                H55LoadDiagnostics580.mark("02_GLB_ZWERYFIKOWANY")
                // Same authenticated active GLB for render and H02–H04 physics.
                // Build on background thread, fail-closed, no raycast fallback.
                let geometry=try H55CollisionGeometry580.fromGLB(url)
                let physical=H55SpatialSupport580(geometry:geometry)
                H55LoadDiagnostics580.mark("03_GEOMETRIA_KOLIZJI_GOTOWA")
                // H08 v531: test EVERY original approved patrol corridor
                // segment at 8 cm intervals on background thread before UI.
                let npcSurface=try H55NpcSurface580.prepare(collision:physical)
                // H70 tracks are from the same SHA-verified GLB as collision.
                let airlockKeys=try H55AirlockTracks580.load(from:url)
                let npcRig=try H55NpcTracks580.load(url)
                H55LoadDiagnostics580.mark("04_NPC_SLUSY_RIG_GOTOWE")
                // H13 inspects the already authenticated GLB off the display thread.
                // Diagnostic failure does not block entry, NPC or H12.
                let materialReport:String
                let materialSnapshot:H55H13MaterialReport580.Snapshot?
                do {
                    let inspected=try H55H13MaterialReport580.inspect(url)
                    materialSnapshot=inspected
                    materialReport=inspected.text
                } catch {
                    materialSnapshot=nil
                    materialReport="H13: ODCZYT METADANYCH NIEUDANY — "+String(describing:error)
                }
                // H12 must not regress H01–H11: an incomplete imported
                // animation library disables H12 alone, not the hangar.
                let h12=try? H55H12Tracks580.load(
                    url,excludeImportedDroneRoots:
                        !H55H12FeatureFlags580.autonomousDronesEnabled)
                // H71 builds its source flight lattice on the background
                // loading queue, never in the SceneKit display frame.
                let droneSpawns=H55H12FeatureFlags580.autonomousDronesEnabled
                    ? ((try? H55DroneImports580.load(url)) ?? []) : []
                let droneNavigation:H55DroneNavigation580? = droneSpawns.count==2
                    ? H55DroneNavigation580(clearance:{x,y,z,radius in
                        physical.cameraClear406(x,y,z,radius:radius)
                    }) : nil
                H55LoadDiagnostics580.mark("05_GLTFKIT2_DECODE_START")
                GLTFAsset.load(with:url,options:[:]) { _,status,asset,error,_ in
                    if status == .complete, let asset {
                        H55LoadDiagnostics580.mark("06_GLTF_ASSET_GOTOWY_SCENESOURCE_START")
                        let source=GLTFSCNSceneSource(asset:asset)
                        H55LoadDiagnostics580.mark("07_GLTF_SCENESOURCE_UTWORZONY")
                        DispatchQueue.main.async { [weak self] in
                            guard let self, self.generation == request else {return}
                            H55LoadDiagnostics580.mark("08_ATTACH_SCENEKIT_START")
                            self.attach(source,asset:asset,inventory:metadata,
                                        physical:physical,airlockKeys:airlockKeys,
                                        npcSurface:npcSurface,npcRig:npcRig,
                                        machineryLibrary:h12,
                                        droneSpawns:droneSpawns,
                                        droneNavigation:droneNavigation,
                                        materialReport:materialReport,
                                        materialSnapshot:materialSnapshot)
                        }
                    } else if status == .error {
                        H55LoadDiagnostics580.mark("BLAD_GLTFKIT2")
                        DispatchQueue.main.async { [weak self] in
                            guard let self,self.generation == request else {return}
                            self.phase = .failed(error?.localizedDescription
                                 ?? "Nie udało się wczytać oryginalnego GLB.")
                        }
                    }
                }
            } catch {
                H55LoadDiagnostics580.mark("BLAD_WSTEPNEGO_WCZYTYWANIA")
                DispatchQueue.main.async { [weak self] in
                    guard let self,self.generation == request else {return}
                    self.phase = .failed(error.localizedDescription)
                }
            }
        }
    }

    private func attach(_ source:GLTFSCNSceneSource,
                        asset:GLTFAsset,inventory:H55Asset580.Inventory,
                        physical:H55SpatialSupport580,
                        airlockKeys:H55AirlockTracks580.SceneKeys,
                        npcSurface:H55NpcSurface580,
                        npcRig:H55NpcTracks580.Rig,
                         machineryLibrary:H55H12Tracks580.Library?,
                         droneSpawns:[H55DroneImports580.Spawn],
                         droneNavigation:H55DroneNavigation580?,
                         materialReport:String,
                         materialSnapshot:H55H13MaterialReport580.Snapshot?) {
        guard let realScene=source.defaultScene else {
            phase = .failed("Plik nie zawiera sceny 3D.")
            return
        }
        // PC HubWalkPlaceAtEntry380: six exact candidates,
        // Support(-0.25,+0.45), BodyClear at four original heights.
        let pointOfView=SCNNode()
        pointOfView.name="H55_iOS_Camera580"
        let lens=SCNCamera()
        lens.zNear=0.06
        lens.zFar=250
        lens.fieldOfView=70
        pointOfView.camera=lens
        guard let candidate=H55Entry580.find(using:physical) else {
            phase = .failed("Nie znaleziono bezkolizyjnego wejścia H55 z PC v580 — sprawdzono 6 punktów i 4 wysokości kolizji.")
            return
        }
        var spawn=H55Walk580()
        spawn.x=candidate.x
        spawn.z=candidate.z
        spawn.placeAtSpawn(feet:candidate.feet)
        self.physical=physical
        arrival=H55Arrival580(spawnClear:true)
        arriving=true
        movement=spawn
        // Source GpuHub90 cinematic first. PC foot position remains spawn.
        let cameraStart=H55DockingPresentation580.camera(time:0)
        pointOfView.position=SCNVector3(cameraStart.x,cameraStart.y,cameraStart.z)
        pointOfView.look(at:SCNVector3(0,4,0))
        realScene.rootNode.addChildNode(pointOfView)
        H55LoadDiagnostics580.mark("09_KAMERA_WYKONANA_SWATLO_START")
        // H13-A: no dynamic IBL cubemap. Windows PC v580 H55Renderer.cs
        // uses its own GLSL light shader, not SceneKit environment textures.
        H55SceneLighting580.install(into:realScene,profile:lighting)
        installH46Lights(into:source)
        updateH46LightBudget()
        var clips:[String:GLTFSCNAnimation]=[:]
        for clip in source.animations where !clip.name.isEmpty {
            clips[clip.name]=clip
        }
        guard clips[H55Asset580.idleClip] != nil,
              clips[H55Asset580.walkClip] != nil else {
            phase = .failed("Wczytana scena nie zawiera animacji mechanika.")
            return
        }
        let importedNpcName="HL_Import_2023_space_suit_3d_model_ca_o_c_animacji_-_najleps"
        guard let importedNpc=source.nodes.first(where:{$0.name==importedNpcName})
        else {
            phase = .failed("Nie znaleziono właściwego mechanika H55 z PC v580.")
            return
        }
        // Source PC v580 Npc533 calibrates BOTH anatomical ankle->toe
        // vectors in original GLB bind pose before any animation plays.
        guard let heading=Self.npcHeadingFromBindPose(source) else {
            phase = .failed("Mechanik H55 nie ma prawidłowych kierunków stóp GLB.")
            return
        }
        // PC v580 NPC root is actual editable TRS from authenticated GLB.
        // Any mismatch with the source-driven route preflight fails closed.
        guard abs(importedNpc.position.x-H55NpcSurface580.rootX)<0.001,
              abs(importedNpc.position.y-H55NpcSurface580.rootY)<0.001,
              abs(importedNpc.position.z-H55NpcSurface580.rootZ)<0.001 else {
            phase = .failed("GLB H55: mechanik ma inne współrzędne niż oryginalna, zweryfikowana trasa PC v580.")
            return
        }
        // H70 clip nodes are driven by sampled original GLB translations.
        // Multiple or missing imported nodes are a hard error, not a fallback.
        var leaves:[String:SCNNode]=[:]
        for leaf in H55AirlockController580.leafNames.flatMap({$0}) {
            let matches=source.nodes.filter{$0.name==leaf}
            guard matches.count==1,airlockKeys.nodes[leaf] != nil else {
                phase = .failed("Oryginalny H55 nie zawiera skrzydła śluzy H70: "+leaf)
                return
            }
            leaves[leaf]=matches[0]
        }
        airlockTracks=airlockKeys
        airlockLeaves=leaves
        airlocks=H55AirlockController580()
        airlockLastApplied=[Float.nan,Float.nan]
        updateAirlocks(dt:0) // original 1.85s CLOSED door pose
        self.npcSurface=npcSurface
        mechanic.configureSpawn(x:importedNpc.position.x,
                                y:importedNpc.position.y,
                                z:importedNpc.position.z,
                                foot:npcSurface.foot)
        mechanic.calibrate(anatomicalHeading:heading)
        mechanicRoot=importedNpc
        mechanicBaseOrientation=importedNpc.simdOrientation
        do {
            npcAnimator=try H55NpcSceneAnimator580(
                rig:npcRig,allNodes:source.nodes,collision:physical,
                foot:npcSurface.foot,anatomicalHeading:heading)
        } catch {
            phase = .failed("H09: niekompletny szkielet mechanika GLB: " + String(describing:error))
            return
        }
        if let machineryLibrary {
            do {
                machinery=try H55H12SceneAnimator580(
                    library:machineryLibrary,allNodes:source.nodes,
                    excludedAirlockNames:Set(H55AirlockController580.leafNames.flatMap{$0}),
                    protectedNpcRoot:importedNpc)
                machinery?.apply(time:0)
                h12Status="H12: DOKOWANIE 0–32 s / SERWIS OD 32 s"
            } catch {
                machinery=nil
                h12Status="H12: BŁĄD WĘZŁÓW ORYGINALNEGO GLB — "+String(describing:error)
            }
        } else {
            machinery=nil
            h12Status="H12: BRAK ZGODNYCH KLIPÓW W DOSTARCZONYM GLB"
        }
        if H55H12FeatureFlags580.autonomousDronesEnabled,
           let droneNavigation,droneSpawns.count==2 {
            droneScene=H55DroneScene580(
                spawns:droneSpawns,navigation:droneNavigation,
                allNodes:source.nodes)
            h71Status=droneScene?.status ??
                "H71: START ZABLOKOWANY — KOLIZJA LUB NIEZGODNE WĘZŁY GLB"
        } else {
            droneScene=nil
            h71Status=H55H12FeatureFlags580.autonomousDronesEnabled
                ? "H71: BRAK DWÓCH ZWERYFIKOWANYCH PREFABÓW DRONÓW"
                : "H71: ODŁOŻONE DO PÓŹNIEJSZEGO ETAPU"
        }
        animations=clips
        animationNames=inventory.animations.filter {
            clips[$0] != nil && !H55AirlockController580.clipNames.contains($0)
        }
        self.inventory=inventory
        H55LoadDiagnostics580.mark("10_WERYFIKACJA_MATERIALOW_START")
        let visual=H55VisualScene580.apply(nodes:source.nodes)
        if let materialSnapshot,H55LightingProfile580.allowCustomEmissionShader {
            // Upstream GLTFKit2 omits KHR_materials_emissive_strength.
            // Correct only named, unambiguous source materials at load time.
            // Keep all eight BLEND materials, six clearcoat materials and
            // original H46 lights unchanged otherwise.
            let corrected=H55H13SceneMaterials580.apply(
                materialSnapshot,nodes:source.nodes)
            h13MaterialReport=materialReport+"\n"+corrected.text
        } else {
            h13MaterialReport=materialReport+"\nH13-A: BEZPIECZNY TRYB MATERIAŁÓW / DODATKOWE SHADERY WYŁĄCZONE"
        }
        h13MaterialReport += "\n"+visual.text+"\nH46: \(h46LightNodes.count)/24 oryginalnych źródeł światła"
        // PC GpuHub90 draws the outer space and actual ship OUTSIDE GLB.
        // Attach only AFTER machinery/NPC rigs capture authentic GLB nodes.
        H55LoadDiagnostics580.mark("11A_PC580_SKY_SHIP_ATTACH_START")
        realScene.background.contents=UIColor(red:0.012,green:0.021,blue:0.04,alpha:1)
        let sky=H55SpaceBackdrop580.make()
        sky.position=pointOfView.position
        realScene.rootNode.addChildNode(sky)
        exteriorSky=sky
        if let craft=H55PlayerShip580.make() {
            realScene.rootNode.addChildNode(craft)
            playerShip=craft
            h13MaterialReport += "\nSTATEK: ORYGINALNY VANGUARD431 / MESH I JPEG SHA256 OK"
        } else {
            h13MaterialReport += "\nSTATEK: BRAK ZWERYFIKOWANEGO ORYGINALNEGO VANGUARD431 (BEZ ZAMIENNIKA)"
        }
        H55LoadDiagnostics580.mark("11_MATERIALY_GOTOWE_ATTACH_KONIEC")
        scene=realScene
        camera=pointOfView
        firstFramePresented=false
        npcAnimator?.apply(dt:0,mechanic:mechanic,allowWalking:false)
        phase = .ready
        H55LoadDiagnostics580.mark("12_SCENA_GOTOWA_PRZED_PIERWSZYM_RENDEREM_GPU")
        // No CADisplayLink here: GPU shader/texture warmup used to consume
        // most of the 3.25s cinematic behind the initial pink frame.
        // H55SceneViewport580 reports the first THREE complete renders.

        // The H12 source-clock compositor supersedes the former ambient
        // CAAnimation players. If a particular imported GLB lacks H12
        // clips, preserve the previously verified H11 ambient animation
        // behaviour without blocking H55 entry or mixing pose writers.
        if machinery == nil {
            for name in ["04_TURBINE_ROTATION_LOOP",
                         "05_GIANT_REPAIR_ARMS_SERVICE_LOOP",
                         "H39_NO_SHIP_IDLE",
                         "H46_LIGHT_IDLE_20S"] {
                play(name,loop:true)
            }
        }
    }

    private static func npcHeadingFromBindPose(
        _ source:GLTFSCNSceneSource)->Float? {
        func joint(_ suffix:String)->SCNNode? {
            source.nodes.first(where:{$0.name?.hasSuffix(suffix) == true})
        }
        guard let la=joint("_foot_l"),let lt=joint("_ball_l"),
              let ra=joint("_foot_r"),let rt=joint("_ball_r") else{return nil}
        let l=lt.simdWorldPosition-la.simdWorldPosition
        let r=rt.simdWorldPosition-ra.simdWorldPosition
        let lm=hypot(l.x,l.z),rm=hypot(r.x,r.z)
        guard lm>0.02 && rm>0.02 else{return nil}
        let dot=(l.x*r.x+l.z*r.z)/(lm*rm)
        guard dot>0.4 else{return nil}
        return atan2(l.x/lm+r.x/rm,-(l.z/lm+r.z/rm))
    }

    /// Exact H46 light proxy metadata from the supplied H55 GLB.
    /// Nodes remain attached to their animated GLB parents (not fixed lights).
    /// SceneKit differs from the PC/OpenGL shader, so GPU visual parity
    /// must be measured on a real device; no claimed one-to-one luminance.
    /// PC v580 H55Renderer.cs: GLB has no KHR_lights_punctual and uses
    /// 24 named animated fallback proxies. Their names, powers, cone angles
    /// and colors are copied from the original user GLB, not generated lamps.
    private func installH46Lights(into source:GLTFSCNSceneSource) {
        for target in source.nodes {
            guard let name=target.name,
                  let proxy=H55VisualSource580.lightProxy(name),
                  target.light==nil else{continue}
            let light=SCNLight()
            light.name=name
            light.type=proxy.kind=="spot" ? .spot : .omni
            light.color=UIColor(red:proxy.red,green:proxy.green,
                                blue:proxy.blue,alpha:1)
            light.intensity=0
            light.castsShadow=false
            light.attenuationStartDistance=0
            light.attenuationEndDistance=CGFloat(proxy.range)
            if proxy.kind=="spot" {
                let angle=180.0/Double.pi
                light.spotInnerAngle=CGFloat(proxy.inner*angle)
                light.spotOuterAngle=CGFloat(proxy.outer*angle)
            }
            target.light=light
            h46RawIntensities[name]=proxy.power
            h46LightNodes[name]=target
        }
    }

    func play(_ name:String,loop:Bool) {
        // H09 manually samples the exact author mocap on these 80 nodes.
        if name == H55Asset580.idleClip || name == H55Asset580.walkClip {return}
        guard let scene,let source=animations[name] else{return}
        let key="source580_"+name
        // A shared source clip may be paused and resumed; never fabricate
        // procedural skeleton motion instead of GLB animation.
        let player=source.animationPlayer
        player.animation.repeatCount=loop ? .greatestFiniteMagnitude : 1
        player.animation.usesSceneTimeBase=false
        scene.rootNode.removeAnimation(forKey:key)
        scene.rootNode.addAnimationPlayer(player,forKey:key)
        player.play()
        activeKeys.insert(key)
        playingClip=name
    }
    func stop(_ name:String) {
        guard let scene else{return}
        let key="source580_"+name
        scene.rootNode.removeAnimation(forKey:key)
        activeKeys.remove(key)
        if playingClip==name {playingClip=nil}
    }
    func showAnimation(_ name:String) {
        // Never mix inspector CAAnimation with the live H12 pose writer.
        if machinery != nil {return}
        // Never play an autonomous H70 clip on nodes owned by the sensors.
        if H55AirlockController580.clipNames.contains(name) {return}
        // Selecting a special animation for inspection stops the previous
        // special clip. Ambient loops and the NPC idle remain unaffected.
        if let current=playingClip,![
            "04_TURBINE_ROTATION_LOOP",
            "05_GIANT_REPAIR_ARMS_SERVICE_LOOP",
            "H39_NO_SHIP_IDLE",
            "H46_LIGHT_IDLE_20S",
            H55Asset580.idleClip
        ].contains(current) {
            stop(current)
        }
        play(name,loop:!name.contains("DOOR_") &&
                       !name.contains("DOCK_") &&
                       !name.contains("DEPART"))
    }
    func close() {
        H55LoadDiagnostics580.mark("14_WYJSCIE_Z_HANGARU")
        clock?.invalidate()
        clock=nil
        lastTick=nil
        physical=nil
        npcSurface=nil
        airlocks=H55AirlockController580()
        airlockTracks=nil
        airlockLeaves.removeAll()
        airlockLastApplied=[Float.nan,Float.nan]
        h46LightNodes.removeAll()
        h46RawIntensities.removeAll()
        exteriorSky=nil
        playerShip=nil
        lightRefresh=0
        arrival=H55Arrival580(spawnClear:false)
        arriving=false
        firstFramePresented=false
        pausedForSettings=false
        firstTickLogged=false
        setMove(forward:0,right:0)
        mechanicRoot=nil
        mechanicBaseOrientation=nil
        npcAnimator=nil
        machinery=nil
        droneScene=nil
        h71Status="H71: ODŁOŻONE DO PÓŹNIEJSZEGO ETAPU"
        h12Status="NIE WCZYTANO ANIMACJI H12"
        showingWorkshop=false
        dialogue.reset()
        conversationOpen=false
        conversationsFinished=0
        generation=UUID()
        guard let scene else{return}
        for key in activeKeys {scene.rootNode.removeAnimation(forKey:key)}
        activeKeys.removeAll()
        animations.removeAll()
        scene.rootNode.removeAllAnimations()
        self.scene=nil
        camera=nil
        phase = .missing
    }
}

struct H55ScenePage580: View {
    let dismiss: () -> Void
    @StateObject private var loader=H55SceneModel580()
    @State private var choosingFile=false
    @State private var pickedClip=""
    @State private var importError:String?
    @State private var showingSettings=false
    @State private var showingPause=false
    @AppStorage("ASTEROIDY_H55_ENV_FILL_580") private var lightingFill=0.80
    @AppStorage("ASTEROIDY_H55_RED_GAIN_580") private var lightingRed=0.10
    private let gold=Color(red:0.89,green:0.67,blue:0.31)
    var body:some View {
        ZStack {
            Color(red:0.005,green:0.019,blue:0.033)
            switch loader.phase {
            case .missing:
                missingAsset
            case .loading:
                VStack(spacing:16) {
                    ProgressView().tint(gold)
                    Text("WCZYTYWANIE ORYGINALNEGO HANGARU H55")
                    Text("Modele, materiały, szkielety i animacje GLB")
                        .foregroundStyle(.secondary)
                }.font(.system(size:13,design:.monospaced))
            case .failed(let message):
                VStack(spacing:12) {
                    Text("BŁĄD SCENY H55").foregroundStyle(.orange)
                    Text(message).multilineTextAlignment(.center)
                    Button("WYBIERZ POPRAWNY GLB") {choosingFile=true}
                }.font(.system(size:13,design:.monospaced))
            case .ready:
                if let scene=loader.scene,let camera=loader.camera {
                    renderedHangar(scene:scene,camera:camera)
                }
            }
            topControls
            if showingPause && !showingSettings { pauseScreen }
            if showingSettings { settingsScreen }
        }
        .onAppear {
            loader.setLighting(fill:lightingFill,red:lightingRed)
            loader.openIfAvailable()
        }
        .onChange(of:lightingFill) { value in
            loader.setLighting(fill:value,red:lightingRed)
        }
        .onChange(of:lightingRed) { value in
            loader.setLighting(fill:lightingFill,red:value)
        }
        .onChange(of:showingPause) { _ in
            loader.pauseForSettings(showingPause || showingSettings)
        }
        .onChange(of:showingSettings) { visible in
            loader.pauseForSettings(showingPause || visible)
            if !visible {loader.setLighting(fill:lightingFill,red:lightingRed)}
        }
        .onDisappear {showingSettings=false;showingPause=false;loader.close()}
        .fileImporter(isPresented:$choosingFile,
            allowedContentTypes:[UTType(filenameExtension:"glb") ?? .data],
            allowsMultipleSelection:false) { result in
            do {
                guard let url=try result.get().first else {return}
                let stored=try H55Asset580.install(from:url)
                loader.open(stored)
            } catch {
                importError=error.localizedDescription
            }
        }
        .alert("NIE MOŻNA WCZYTAĆ SCENY",isPresented:Binding(
            get:{importError != nil},
            set:{if !$0 {importError=nil}})) {
            Button("OK",role:.cancel) {importError=nil}
        } message: {
            Text(importError ?? "")
        }
        .accessibilityIdentifier("h55-v580-page")
    }
    /// Render layer is typechecked independently of navigation, file import,
    /// menus and settings. Fixes Xcode SwiftUI generic typecheck timeout.
    /// Same central touch affordance as Sector01Scene568 (PC W3 pause).
    /// No critical controls trapped in iPhone's far upper-right corner.
    private var topControls:some View {
        GeometryReader { viewport in
            if case .ready = loader.phase {
                if loader.firstFramePresented && !showingPause && !showingSettings {
                    Button("PAUZA") { showingPause=true }
                        .font(.system(size:13,weight:.semibold,design:.monospaced))
                        .foregroundStyle(.white)
                        .frame(width:116,height:42)
                        .background(Color.black.opacity(0.68))
                        .overlay(Rectangle().stroke(gold.opacity(0.72),lineWidth:1))
                        .position(x:viewport.size.width*0.5,
                                  y:max(42,viewport.safeAreaInsets.top+29))
                        .accessibilityIdentifier("h55-pause-button")
                }
            } else {
                Button("‹ MENU") {loader.close();dismiss()}
                    .font(.system(size:14,weight:.bold,design:.monospaced))
                    .foregroundStyle(gold)
                    .padding(12)
                    .background(Color.black.opacity(0.82))
                    .accessibilityIdentifier("h55-v580-back")
            }
        }
    }

    /// W3 RendererW3Pause317: translucent modal on top of the LIVE scene.
    /// Hub90 source supplies Return to Menu and six original workshops.
    /// No dead Save/Load/Scores keys: those Windows actions are not ported.
    private var pauseScreen:some View {
        GeometryReader { viewport in
            let compact=viewport.size.height<480
            ZStack {
                Color.black.opacity(0.80)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("h55-pause-touch-blocker")
                ScrollView {
                    VStack(alignment:.leading,spacing:compact ? 8:13) {
                        Text("SYNIXAD // SYSTEM HANGARU")
                            .font(.system(size:compact ? 10:12,weight:.bold,design:.monospaced))
                            .foregroundStyle(Color(red:0.55,green:0.77,blue:0.80))
                        Text("GRA WSTRZYMANA")
                            .font(.system(size:compact ? 22:30,weight:.heavy,design:.monospaced))
                            .foregroundStyle(.white)
                        Text("H55 / PC v580 · SCENA I CZAS GRY ZATRZYMANE")
                            .font(.system(size:compact ? 10:12,design:.monospaced))
                            .foregroundStyle(.gray)
                        Divider().overlay(gold)
                        pauseButton("KONTYNUUJ",primary:true) {showingPause=false}
                            .accessibilityIdentifier("h55-pause-resume")
                        pauseButton("USTAWIENIA") {showingSettings=true}
                            .accessibilityIdentifier("h55-open-settings")
                        pauseButton("STANOWISKA") {
                            showingPause=false
                            loader.openWorkshop()
                        }
                        .disabled(loader.arriving || loader.conversationOpen || loader.showingWorkshop)
                        .accessibilityIdentifier("h11-open-stations")
                        // Windows HubKey90 ESC in a dialogue closes the
                        // dialogue first, without leaving H55 or losing NPC state.
                        if loader.conversationOpen {
                            pauseButton("ZAKOŃCZ ROZMOWĘ") {
                                if loader.conversationOpen {loader.interact()}
                            }
                            .accessibilityIdentifier("h55-pause-close-conversation")
                        }
                        ShareLink(item:loader.h13MaterialReport) {
                            Text("RAPORT H13")
                                .frame(maxWidth:.infinity)
                                .padding(.vertical,compact ? 7:10)
                                .background(Color(red:0.05,green:0.15,blue:0.22))
                                .foregroundStyle(.white)
                                .overlay(Rectangle().stroke(gold.opacity(0.25),lineWidth:1))
                        }
                        .accessibilityIdentifier("h13-share-glb-report")
                        pauseButton("WYJDŹ DO MENU") {
                            if loader.showingWorkshop {loader.closeWorkshop()}
                            loader.close()
                            dismiss()
                        }
                        .accessibilityIdentifier("h55-pause-exit")
                    }
                    .font(.system(size:compact ? 12:14,weight:.bold,design:.monospaced))
                    .padding(compact ? 14:22)
                    .frame(maxWidth:550)
                    .background(Color(red:0.02,green:0.05,blue:0.09))
                    .overlay(Rectangle().stroke(Color(red:0.24,green:0.38,blue:0.44),lineWidth:1))
                    .frame(maxWidth:.infinity)
                }
                .frame(maxWidth:.infinity,maxHeight:.infinity)
            }
        }
        .zIndex(20)
        .accessibilityIdentifier("h55-pause-overlay")
    }

    private func pauseButton(_ title:String,primary:Bool=false,
                             action:@escaping ()->Void)->some View {
        Button(action:action) {
            Text(title)
                .frame(maxWidth:.infinity)
                .padding(.vertical,9)
                .background(primary ? gold : Color(red:0.05,green:0.15,blue:0.22))
                .foregroundStyle(primary ? Color(red:0.07,green:0.13,blue:0.17) : .white)
                .overlay(Rectangle().stroke(gold.opacity(0.25),lineWidth:1))
        }
    }

    private var settingsScreen:some View {
                GeometryReader { frame in
                    VStack(spacing:0) {
                        VStack(spacing:3) {
                            Text("USTAWIENIA / HANGAR")
                                .font(.system(size:12,weight:.bold,design:.monospaced))
                                .foregroundStyle(gold)
                            Button("‹ WRÓĆ DO PAUZY") {showingSettings=false}
                                .font(.system(size:14,weight:.bold,design:.monospaced))
                                .frame(maxWidth:250,minHeight:38)
                                .foregroundStyle(.white)
                                .background(Color(red:0.05,green:0.15,blue:0.22))
                                .accessibilityIdentifier("h55-settings-back")
                        }
                        .frame(maxWidth:.infinity)
                        .padding(4)
                        .background(Color(red:0.008,green:0.028,blue:0.048))
                        CarbonisVisualSettingsPanel568(
                            compact:frame.size.width<850,initialTab:9)
                            .frame(maxWidth:.infinity,maxHeight:.infinity)
                    }
                    .background(Color(red:0.005,green:0.018,blue:0.034))
                    .ignoresSafeArea()
                }
                .zIndex(30)
                .accessibilityIdentifier("h55-settings-fullscreen")
    }

    private func renderedHangar(scene:SCNScene,camera:SCNNode)->some View {
                    ZStack {
                        // SceneKit draws only. It MUST NOT eat the left/right
                        // drag gestures, otherwise H06 sees zero input.
                        H55SceneViewport580(scene:scene,pointOfView:camera,
                            onFirstRenderedFrames:{ rendered in
                                loader.firstRenderedFramesReady(for:rendered)
                            })
                            .allowsHitTesting(false)
                            .accessibilityIdentifier("h55-v580-native-scenekit")
                        if loader.firstFramePresented {
                        H55TouchControls580(
                            onWalk:{forward,right in
                                loader.setMove(forward:forward,right:right)
                            },
                            onLook:{dx,dy in loader.look(dx:dx,dy:dy)},
                            onJump:{loader.jump()},
                            onTalk:{loader.interact()},
                            canTalk:loader.mechanicNearby,
                            conversationOpen:loader.conversationOpen,
                            mechanicStatus:loader.mechanicStatus
                        )
                        }

                         if loader.showingWorkshop {
                            H55WorkshopPanel580(initialTab:loader.workshopInitialPanel,
                                                onClose:{loader.closeWorkshop()})
                                .zIndex(5)
                        }
                        if loader.arriving && loader.firstFramePresented { arrivalOverlay }
                        if !loader.firstFramePresented {
                            // Mask SceneKit's first GPU shader/texture uploads.
                            // No arrival time is lost behind the startup screen.
                            Color(red:0.005,green:0.019,blue:0.033)
                                .ignoresSafeArea()
                                .overlay {
                                    VStack(spacing:9) {
                                        ProgressView().tint(gold)
                                        Text("PRZYGOTOWYWANIE OBRAZU HANGARU")
                                            .font(.system(size:12,weight:.semibold,
                                                design:.monospaced))
                                            .foregroundStyle(gold)
                                        Text("Dolot rozpocznie się po przygotowaniu GPU")
                                            .font(.system(size:10,design:.monospaced))
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                }
                                .accessibilityIdentifier("h55-gpu-first-frame-mask")
                                .zIndex(9)
                        }
                        if loader.conversationOpen { conversationOverlay }

                        if ProcessInfo.processInfo.environment["ASTEROIDY_DEBUG_MENU"] == "1" { debugOverlay }
                    }
                    .frame(maxWidth:.infinity,maxHeight:.infinity)
    }

    private var arrivalOverlay:some View {
                            VStack(spacing:9) {
                                Text("H55 — PRZYLOT · 3,25 s")
                                    .font(.system(size:12,weight:.bold,design:.monospaced))
                                Button("POMIŃ PRZYLOT") {loader.skipArrival()}
                                    .accessibilityIdentifier("h55-v580-skip-arrival")
                            }
                            .padding(13)
                            .foregroundStyle(gold)
                            .background(Color.black.opacity(0.88))
                            .cornerRadius(8)
    }

    private var conversationOverlay:some View {
                            VStack(spacing:9) {
                                Text("MECHANIK")
                                    .font(.system(size:14,weight:.bold,design:.monospaced))
                                Text(H55NpcDialogue580.spokenLine)
                                    .font(.system(size:12,design:.monospaced))
                                Button("ZAKOŃCZ ROZMOWĘ") {loader.interact()}
                                    .accessibilityIdentifier("h55-v580-npc-end-dialogue")
                            }
                            .foregroundStyle(gold)
                            .padding(15)
                            .background(Color.black.opacity(0.91))
                            .cornerRadius(8)
                            .accessibilityIdentifier("h55-v580-npc-dialogue")
    }

    private var debugOverlay:some View {
                            VStack {
                                HStack(spacing:8) {
                                    Text("H55 · ANIMACJE \(loader.animationNames.count)")
                                    Spacer()
                                    if loader.h12Status.hasPrefix("H12:") {
                                        // The runtime uses a single H51/H39 timeline.
                                        // Don't display an inert picker that would
                                        // overwrite animated nodes or break H70.
                                        VStack(alignment:.trailing,spacing:3) {
                                            Text(loader.h12Status)
                                            Text(loader.h71Status)
                                        }
                                            .accessibilityIdentifier("h12-source-clock-active")
                                    } else {
                                        Picker("ANIMACJA GLB",selection:$pickedClip) {
                                            Text("WYBIERZ").tag("")
                                            ForEach(loader.animationNames,id:\.self) {
                                                Text($0).tag($0)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .frame(maxWidth:270)
                                        .onChange(of:pickedClip) { value in
                                            if !value.isEmpty {loader.showAnimation(value)}
                                        }
                                    }
                                }
                                .font(.system(size:10,design:.monospaced))
                                .padding(10)
                                .foregroundStyle(gold)
                                .background(Color.black.opacity(0.83))
                                Spacer()
                            }
    }

    private var missingAsset:some View {
        VStack(spacing:15) {
            Text("HANGAR H55 / PC v580")
                .font(.system(size:22,weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
            Text("Do otwarcia oryginalnej sceny potrzebny jest plik hangar_h55.glb.\nWybierz przesłany plik w aplikacji Pliki. Zostanie zapisany na tym urządzeniu.")
                .multilineTextAlignment(.center)
                .font(.system(size:13,design:.monospaced))
                .foregroundStyle(.white)
            Button("IMPORTUJ ORYGINALNY HANGAR GLB") {choosingFile=true}
                .padding(14)
                .foregroundStyle(.black)
                .background(gold)
                .accessibilityIdentifier("h55-v580-import")
        }
        .padding(20)
    }
}
