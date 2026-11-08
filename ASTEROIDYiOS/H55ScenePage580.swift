import Foundation
import SceneKit
import SwiftUI
import GLTFKit2
import UniformTypeIdentifiers

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
                            self.attach(source,inventory:metadata)
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
                        inventory:H55Asset580.Inventory) {
        guard let realScene=source.defaultScene else {
            phase = .failed("Plik nie zawiera sceny 3D.")
            return
        }
        // PC v580 Hub90.BeginHubScene397: camera enters at (0, 12.5)
        // at the physical floor; PC HubWalkEyes377 = 1.80 m.
        let pointOfView=SCNNode()
        pointOfView.name="H55_iOS_Camera580"
        let lens=SCNCamera()
        lens.zNear=0.06
        lens.zFar=250
        lens.fieldOfView=70
        pointOfView.camera=lens
        pointOfView.position=SCNVector3(0,1.80,12.5)
        pointOfView.eulerAngles.y=Float.pi // PC yaw=0 faces +Z
        realScene.rootNode.addChildNode(pointOfView)

        var clips:[String:GLTFSCNAnimation]=[:]
        for clip in source.animations where !clip.name.isEmpty {
            clips[clip.name]=clip
        }
        guard clips[H55Asset580.idleClip] != nil,
              clips[H55Asset580.walkClip] != nil else {
            phase = .failed("Wczytana scena nie zawiera animacji mechanika.")
            return
        }
        animations=clips
        animationNames=inventory.animations.filter{clips[$0] != nil}
        self.inventory=inventory
        scene=realScene
        camera=pointOfView
        phase = .ready
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

    func play(_ name:String,loop:Bool) {
        guard let scene,let source=animations[name] else{return}
        let key="source580_"+name
        // A shared source clip may be paused and resumed; never fabricate
        // procedural skeleton motion instead of GLB animation.
        let player=source.animationPlayer
        player.animation.repeatCount=loop ? .greatestFiniteMagnitude : 1
        player.animation.usesSceneTimeBase=false
        scene.rootNode.removeAnimationPlayer(forKey:key)
        scene.rootNode.addAnimationPlayer(player,forKey:key)
        player.play()
        activeKeys.insert(key)
        playingClip=name
    }
    func stop(_ name:String) {
        guard let scene else{return}
        let key="source580_"+name
        scene.rootNode.removeAnimationPlayer(forKey:key)
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
        generation=UUID()
        guard let scene else{return}
        for key in activeKeys {scene.rootNode.removeAnimationPlayer(forKey:key)}
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
                        Spacer()
                        HStack(spacing:8) {
                            Text("H55 · MODELE \(loader.inventory?.meshes ?? 0) · ANIMACJE \(loader.animationNames.count)")
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
