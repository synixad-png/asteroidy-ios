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
        guard !conversationOpen else{return}
        _=movement.jump()
    }
    func setMove(forward:Float,right:Float) {
        moveForward=max(-1,min(1,forward))
        moveRight=max(-1,min(1,right))
    }
    func look(dx:Float,dy:Float) {
        movement.look(deltaX:dx,deltaY:dy)
        camera?.eulerAngles=SCNVector3(-movement.pitch,movement.yaw,0)
    }
    func interact() {
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
        if let last=lastTick {dt=Float(min(0.05,max(0,link.timestamp-last)))}
        else {dt=0}
        lastTick=link.timestamp
        guard dt>0 && !conversationOpen else{return}
        movement.step(dt:dt,forward:moveForward,right:moveRight,
            sprint:false,
            bodyClear:{x,y,z in Self.bodyClear(scene,x:x,feet:y,z:z)},
            support:{x,z,feet in Self.supportHeight(scene,x:x,z:z,feet:feet)})
        camera?.position=SCNVector3(movement.x,movement.y+H55Walk580.eyes,movement.z)
        mechanic.step(dt:dt,playerX:movement.x,playerZ:movement.z,
            canWalk:{x,z in
                guard let floor=Self.supportHeight(scene,x:x,z:z,feet:0),
                      Self.bodyClear(scene,x:x,feet:floor,z:z)
                else{return false}
                return true
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

    /// Physical samples raycast the ACTIVE H55 GLB, not an outdated
    /// baked proxy. Full triangle-capsule parity to PC H55FullCollision379
    /// still requires a dedicated spatial-index port.
    private static func hits(_ scene:SCNScene,from:SCNVector3,to:SCNVector3)
        -> [SCNHitTestResult] {
        scene.rootNode.hitTestWithSegment(from:from,to:to,
               options:["backFaceCulling":false,"firstFoundOnly":false])
    }
    /// Windows HubWalk375.cs:139 and H55FullCollision379.Support():787-810.
    /// The *actual* user H55 mesh has the TOP of its original floor tiles
    /// at Y=0.085 with a -Y normal (and the underside at Y=0.005, +Y).
    /// The old +Y-only predicate rejected the physical top floor.
    /// PC deliberately accepts BOTH windings (normalY squared) and
    /// selects the highest valid support within the requested interval.
    private static func supportHeight(_ scene:SCNScene,
                                      x:Float,z:Float,feet:Float,
                                      spawn:Bool=false)->Float? {
        let low=feet-(spawn ? 0.25 : H55Walk580.stepDown+0.05)
        let high=feet+(spawn ? 0.45 : H55Walk580.stepUp+0.05)
        let from=SCNVector3(x,high+0.002,z)
        let to=SCNVector3(x,low-0.002,z)
        let floors=hits(scene,from:from,to:to).map{
            H55FloorRule580.Sample(x:$0.worldCoordinates.x,
                y:$0.worldCoordinates.y,z:$0.worldCoordinates.z,
                normalX:$0.worldNormal.x,normalY:$0.worldNormal.y,
                normalZ:$0.worldNormal.z)
        }
        return H55FloorRule580.highest(floors,low:low,high:high)
    }
    /// Windows H55FullCollision379.BodyClear():887-920:
    /// decorative ankle-height floor trims (Y<=feet+stepUp) are not
    /// blocking torso walls. Unlike old iOS 0.25m ray, these probes
    /// exclude everything below the already-source-defined 50cm step.
    /// This is still a SceneKit approximate cylinder, not PC's exact
    /// 4-sphere triangle-distance collision.
    private static func bodyClear(_ scene:SCNScene,
                                  x:Float,feet:Float,z:Float)->Bool {
        let radius=H55Walk580.bodyRadius
        for height:Float in [0.335,0.78,1.225,1.67] {
            let cy=feet+height
            for (dx,dz):(Float,Float) in [(1,0),(-1,0),(0,1),(0,-1)] {
                let start=SCNVector3(x,cy,z)
                let end=SCNVector3(x+dx*radius,cy,z+dz*radius)
                if hits(scene,from:start,to:end).contains(where:{
                    $0.worldCoordinates.y>feet+H55Walk580.stepUp+0.001 &&
                    $0.worldCoordinates.y<feet+H55Walk580.bodyHeight+0.28
                }) {return false}
            }
        }
        return true
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
                GLTFAsset.load(with:url,options:[:]) { _,status,asset,error,_ in
                    if status == .complete, let asset {
                        let source=GLTFSCNSceneSource(asset:asset)
                        DispatchQueue.main.async { [weak self] in
                            guard let self, self.generation == request else {return}
                            self.attach(source,asset:asset,inventory:metadata)
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
                        asset:GLTFAsset,inventory:H55Asset580.Inventory) {
        guard let realScene=source.defaultScene else {
            phase = .failed("Plik nie zawiera sceny 3D.")
            return
        }
        // PC v580 HubWalkPlaceAtEntry380: (0,12.5) was embedded in
        // copper geometry. Pick the first clear GLB floor candidate.
        let pointOfView=SCNNode()
        pointOfView.name="H55_iOS_Camera580"
        let lens=SCNCamera()
        lens.zNear=0.06
        lens.zFar=250
        lens.fieldOfView=70
        pointOfView.camera=lens
        let candidates:[(Float,Float)]=[(2,14),(3,14),(-2,14),
                                         (4,15),(-4,15),(6,15)]
        var chosen:H55Walk580?
        for (x,z) in candidates {
            guard let floor=Self.supportHeight(realScene,x:x,z:z,feet:0,spawn:true),
                  Self.bodyClear(realScene,x:x,feet:floor,z:z) else{continue}
            var trial=H55Walk580()
            trial.x=x;trial.z=z;trial.y=floor
            chosen=trial
            break
        }
        guard let spawn=chosen else {
            phase = .failed("Nie znaleziono bezkolizyjnego wejścia H55 z PC v580.")
            return
        }
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
