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
    @Published private(set) var animationNames: [String] = []
    @Published private(set) var playingClip: String?
    @Published private(set) var inventory: H55Asset580.Inventory?
    private var animations: [String:GLTFSCNAnimation] = [:]
    private var activeKeys: Set<String> = []
    private var generation = UUID()
    private var movement=H55Walk580()
    private var physical:H55SpatialSupport580?
    private var arrival=H55Arrival580(spawnClear:false)
    @Published private(set) var arriving=false
    private var moveForward:Float=0
    private var moveRight:Float=0
    private var clock:CADisplayLink?
    private var lastTick:CFTimeInterval?
    @Published private(set) var mechanicNearby=false
    @Published private(set) var conversationOpen=false
    @Published private(set) var conversationsFinished=0
    private var mechanic=H55Mechanic580()
    private weak var mechanicRoot:SCNNode?
    private var mechanicBaseY:Float=0.1095
    private var mechanicBaseOrientation:simd_quatf?
    private var mechanicMotionPlaying=false
    @Published private(set) var mechanicStatus="OCZEKUJE NA ROZMOWĘ"

    func jump() {
        guard !conversationOpen && arrival.walking else{return}
        guard let physical else{return}
        _=movement.jump(collision:physical)
    }
    func setMove(forward:Float,right:Float) {
        moveForward=max(-1,min(1,forward))
        moveRight=max(-1,min(1,right))
    }
    func look(dx:Float,dy:Float) {
        guard arrival.walking else{return}
        movement.look(deltaX:dx,deltaY:dy)
        camera?.eulerAngles=SCNVector3(-movement.pitch,movement.yaw,0)
    }
    func interact() {
        guard arrival.walking else{return}
        if conversationOpen {
            conversationOpen=false
            conversationsFinished+=1
            mechanic.finishConversation()
            mechanicStatus="PATROL GOTOWY — ODDAL SIĘ"
            return
        }
        let distance=hypot(movement.x-mechanic.x,movement.z-mechanic.z)
        guard distance<=2.7 else{return}
        conversationOpen=true
        setMove(forward:0,right:0)
    }

    func skipArrival() {arrival.skip()}

    private func beginClock() {
        clock?.invalidate()
        lastTick=nil
        let link=CADisplayLink(target:self,selector:#selector(stepFrame(_:)))
        link.preferredFramesPerSecond=60
        link.add(to:.main,forMode:.common)
        clock=link
    }
    @objc private func stepFrame(_ link:CADisplayLink) {
        guard let scene,camera != nil else{return}
        let dt:Float
        if let last=lastTick {dt=Float(min(0.06,max(0,link.timestamp-last)))}
        else {dt=0}
        lastTick=link.timestamp
        guard dt>0 else{return}
        // PC Hub90.StepHub90: arrival clock runs before walking.
        arrival.advance(dt:dt)
        if arriving && !arrival.arriving {arriving=false}
        guard arrival.walking && !conversationOpen,let physical else{return}
        movement.step(dt:dt,forward:moveForward,right:moveRight,
            sprint:false,collision:physical)
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
        camera?.eulerAngles=SCNVector3(-movement.pitch,movement.yaw,roll)
        mechanic.step(dt:dt,playerX:movement.x,playerZ:movement.z,
            canWalk:{x,z in
                guard let floor=physical.support(x,z,low:-0.25,high:0.45)
                else{return false}
                return physical.bodyClear379(x,feet:floor,z)
            })
        if let root=mechanicRoot {
            root.position=SCNVector3(mechanic.x,mechanicBaseY,mechanic.z)
            if let original=mechanicBaseOrientation {
                // Same quaternion product as Windows H55Renderer.cs:1618-22.
                root.simdOrientation=simd_quatf(angle:mechanic.yaw,
                     axis:SIMD3<Float>(0,1,0))*original
            }
        }
        let walking=mechanic.moving
        if walking != mechanicMotionPlaying {
            mechanicMotionPlaying=walking
            if walking {
                stop(H55Asset580.idleClip)
                play(H55Asset580.walkClip,loop:true)
            } else {
                stop(H55Asset580.walkClip)
                play(H55Asset580.idleClip,loop:true)
            }
        }
        let nextStatus:String
        switch mechanic.phase {
        case .idle: nextStatus="OCZEKUJE NA ROZMOWĘ"
        case .walking: nextStatus="PATROL DO WARSZTATU I POWRÓT"
        case .workshop: nextStatus="WARSZTAT — POSTÓJ 5 s"
        case .blocked: nextStatus="MECHANIK — KOLIZJA / TRASA ZABLOKOWANA"
        case .completed: nextStatus="MECHANIK WRÓCIŁ"
        }
        if nextStatus != mechanicStatus {mechanicStatus=nextStatus}
        let near=hypot(movement.x-mechanic.x,movement.z-mechanic.z)<=2.7
        if near != mechanicNearby {mechanicNearby=near}
    }

    func openIfAvailable() {
        guard let url=H55Asset580.availableURL() else {
            phase = .missing
            return
        }
        open(url)
    }
    func open(_ url: URL) {
        generation=UUID()
        let request=generation
        clock?.invalidate()
        clock=nil
        lastTick=nil
        movement=H55Walk580()
        physical=nil
        arrival=H55Arrival580(spawnClear:false)
        arriving=false
        mechanic=H55Mechanic580()
        mechanicRoot=nil
        mechanicBaseOrientation=nil
        mechanicMotionPlaying=false
        mechanicStatus="OCZEKUJE NA ROZMOWĘ"
        conversationOpen=false
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
                // Same authenticated active GLB for render and H02–H04 physics.
                // Build on background thread, fail-closed, no raycast fallback.
                let geometry=try H55CollisionGeometry580.fromGLB(url)
                let physical=H55SpatialSupport580(geometry:geometry)
                GLTFAsset.load(with:url,options:[:]) { _,status,asset,error,_ in
                    if status == .complete, let asset {
                        let source=GLTFSCNSceneSource(asset:asset)
                        DispatchQueue.main.async { [weak self] in
                            guard let self, self.generation == request else {return}
                            self.attach(source,asset:asset,inventory:metadata,physical:physical)
                        }
                    } else if status == .error {
                        DispatchQueue.main.async { [weak self] in
                            guard let self,self.generation == request else {return}
                            self.phase = .failed(error?.localizedDescription
                                 ?? "Nie udało się wczytać oryginalnego GLB.")
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self,self.generation == request else {return}
                    self.phase = .failed(error.localizedDescription)
                }
            }
        }
    }

    private func attach(_ source:GLTFSCNSceneSource,
                        asset:GLTFAsset,inventory:H55Asset580.Inventory,
                        physical:H55SpatialSupport580) {
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
        pointOfView.position=SCNVector3(spawn.x,spawn.y+H55Walk580.eyes,spawn.z)
        pointOfView.eulerAngles.y=0 // PC yaw=0 looks toward -Z
        realScene.rootNode.addChildNode(pointOfView)

        installH46Lights(from:asset,into:source)
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
        mechanic.calibrate(anatomicalHeading:heading)
        mechanicRoot=importedNpc
        mechanicBaseY=importedNpc.position.y
        mechanicBaseOrientation=importedNpc.simdOrientation
        animations=clips
        animationNames=inventory.animations.filter{clips[$0] != nil}
        self.inventory=inventory
        scene=realScene
        camera=pointOfView
        phase = .ready
        beginClock()
        // PC H55Renderer: never trigger the docking or departure
        // 146 s composites while simply visiting the hangar from menu.
        for name in ["04_TURBINE_ROTATION_LOOP",
                     "05_GIANT_REPAIR_ARMS_SERVICE_LOOP",
                     "H39_NO_SHIP_IDLE",
                     "H46_LIGHT_IDLE_20S",
                     H55Asset580.idleClip] {
            play(name,loop:true)
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
    private func installH46Lights(from asset:GLTFAsset,
                                  into source:GLTFSCNSceneSource) {
        for node in asset.nodes {
            guard let name=node.name,
                  let extra=node.extras as? [String:Any],
                  let proxy=extra["H46_BABYLON_COMPAT_lightProxy"] as? [String:Any],
                  let target=source.nodes.first(where:{$0.name==name}),
                  target.light==nil else {continue}
            let kind=proxy["type"] as? String ?? ""
            guard kind=="spot" || kind=="point" else {continue}
            let light=SCNLight()
            light.name=name
            light.type=kind=="spot" ? .spot : .omni
            if let components=proxy["color"] as? [NSNumber],
               components.count>=3 {
                light.color=UIColor(red:CGFloat(components[0].doubleValue),
                      green:CGFloat(components[1].doubleValue),
                      blue:CGFloat(components[2].doubleValue),alpha:1)
            }
            if let strength=proxy["intensity"] as? NSNumber {
                light.intensity=CGFloat(strength.doubleValue)
            }
            if let range=proxy["range"] as? NSNumber {
                light.attenuationStartDistance=0
                light.attenuationEndDistance=CGFloat(range.doubleValue)
            }
            if kind=="spot",let cone=proxy["spot"] as? [String:Any],
               let inner=cone["innerConeAngle"] as? NSNumber,
               let outer=cone["outerConeAngle"] as? NSNumber {
                let degrees=180.0/Double.pi
                light.spotInnerAngle=CGFloat(inner.doubleValue*degrees)
                light.spotOuterAngle=CGFloat(outer.doubleValue*degrees)
            }
            target.light=light
        }
    }

    func play(_ name:String,loop:Bool) {
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
        clock?.invalidate()
        clock=nil
        lastTick=nil
        physical=nil
        arrival=H55Arrival580(spawnClear:false)
        arriving=false
        setMove(forward:0,right:0)
        mechanicRoot=nil
        mechanicBaseOrientation=nil
        mechanicMotionPlaying=false
        conversationOpen=false
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
    @State private var lookLast:CGSize = .zero
    @State private var importError:String?
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
                    SceneView(scene:scene,pointOfView:camera,
                              options:[.rendersContinuously])
                        .accessibilityIdentifier("h55-v580-native-scenekit")
                    VStack {
                        Spacer(minLength:0)
                        if loader.arriving {
                            VStack(spacing:8) {
                                Text("H55 — PRZYLOT · 3,25 s")
                                    .font(.system(size:12,weight:.bold,design:.monospaced))
                                Button("POMIŃ PRZYLOT") {loader.skipArrival()}
                                    .accessibilityIdentifier("h55-v580-skip-arrival")
                            }
                            .padding(12)
                            .foregroundStyle(gold)
                            .background(Color.black.opacity(0.85))
                        }
                        if loader.conversationOpen {
                            VStack(spacing:8) {
                                Text("MECHANIK")
                                    .font(.system(size:13,weight:.bold,design:.monospaced))
                                    .foregroundStyle(gold)
                                Text("WSZYSTKO W PORZĄDKU.")
                                    .font(.system(size:12,design:.monospaced))
                                Button("ZAKOŃCZ ROZMOWĘ") {loader.interact()}
                                    .accessibilityIdentifier("h55-v580-npc-end-dialogue")
                            }
                            .padding(15)
                            .background(Color.black.opacity(0.87))
                            .accessibilityIdentifier("h55-v580-npc-dialogue")
                        }
                        HStack(spacing:10) {
                            Text(loader.mechanicStatus)
                                .font(.system(size:10,weight:.bold,design:.monospaced))
                            Spacer()
                            Button("SKOK") {loader.jump()}
                                .accessibilityIdentifier("h55-v580-jump")
                            Button(loader.mechanicNearby ? "ROZMAWIAJ" : "MECHANIK 2,7 m") {
                                loader.interact()
                            }
                            .disabled(!loader.mechanicNearby && !loader.conversationOpen)
                            .accessibilityIdentifier("h55-v580-npc-interact")
                        }
                        .padding(.horizontal,12)
                        .foregroundStyle(gold)
                        HStack(spacing:5) {
                            Rectangle().fill(Color.white.opacity(0.035))
                                .overlay(alignment:.bottomLeading) {
                                    Text("LEWA · CHODZENIE")
                                        .font(.system(size:9,design:.monospaced))
                                        .foregroundStyle(gold)
                                        .padding(8)
                                }
                                .contentShape(Rectangle())
                                .gesture(DragGesture(minimumDistance:0)
                                    .onChanged{value in
                                        let right=Float(value.translation.width/90)
                                        let forward=Float(-value.translation.height/90)
                                        loader.setMove(forward:forward,right:right)
                                    }
                                    .onEnded{_ in
                                        loader.setMove(forward:0,right:0)
                                    })
                                .accessibilityIdentifier("h55-v580-left-walk")
                            Rectangle().fill(Color.white.opacity(0.035))
                                .overlay(alignment:.bottomTrailing) {
                                    Text("PRAWA · ROZGLĄDANIE")
                                        .font(.system(size:9,design:.monospaced))
                                        .foregroundStyle(gold)
                                        .padding(8)
                                }
                                .contentShape(Rectangle())
                                .gesture(DragGesture(minimumDistance:0)
                                    .onChanged{value in
                                        let deltaX=Float(value.translation.width-lookLast.width)
                                        let deltaY=Float(value.translation.height-lookLast.height)
                                        loader.look(dx:deltaX,dy:deltaY)
                                        lookLast=value.translation
                                    }
                                    .onEnded{_ in lookLast = .zero})
                                .accessibilityIdentifier("h55-v580-right-look")
                        }
                        .frame(height:105)
                        // The source PC v580 H55 has no manual 62-clip
                        // animation picker. Expose this only in diagnostics;
                        // production animation is controlled by world state.
                        if ProcessInfo.processInfo.environment["ASTEROIDY_DEBUG_MENU"] == "1" {
                            HStack(spacing:8) {
                                Text("H55 · ANIMACJE \(loader.animationNames.count)")
                                    .font(.system(size:10,design:.monospaced))
                                Spacer()
                                Picker("ANIMACJA GLB",selection:$pickedClip) {
                                    Text("WYBIERZ").tag("")
                                    ForEach(loader.animationNames,id:\.self) {
                                        Text($0).tag($0)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth:280)
                                .onChange(of:pickedClip) { value in
                                    if !value.isEmpty {loader.showAnimation(value)}
                                }
                            }
                            .padding(10)
                            .foregroundStyle(gold)
                            .background(Color.black.opacity(0.83))
                        }
                    }
                }
            }
            VStack {
                HStack {
                    Button("‹ MENU") {
                        loader.close()
                        dismiss()
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.82))
                    .accessibilityIdentifier("h55-v580-back")
                    Spacer()
                }
                Spacer()
            }
            .font(.system(size:14,weight:.bold,design:.monospaced))
            .foregroundStyle(gold)
        }
        .onAppear {loader.openIfAvailable()}
        .onDisappear {loader.close()}
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
