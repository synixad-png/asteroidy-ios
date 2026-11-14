import Foundation
import MetalKit
import simd
import QuartzCore
import CryptoKit

private struct GPUModel {
    let vertices: MTLBuffer
    let indices: MTLBuffer
    let count: Int
}

// Perspective renderer. This intentionally reuses the independent v2 gameplay
// while the real C# v556 simulation and PBR shaders remain to be ported.
final class MetalRenderer: NSObject, MTKViewDelegate {
    let input: FlightInput
    // Optional authoritative sector-05 source combat; never use the
    // independent SphereSector sandbox to score a campaign victory.
    private weak var combatSession05:CarbonisSession568?
    private var sourceShooterModels05:[Int:GPUModel]=[:]
    private let sourceMissionScale05=SourceMissionSize580.load()
    // Original separate visual-only scale; IntroScene41 cinematic is not
    // affected, exactly as the source uses it only in CraftSphere67/Orbit50.
    private var shipScale472=SourceShipScale472.load()
    private var shipScaleRevision472=UserDefaults.standard.integer(
        forKey:SourceShipScale472.revisionKey)
    let device: MTLDevice
    let queue: MTLCommandQueue
    let pipeline: MTLRenderPipelineState
    let depthState: MTLDepthStencilState
    let skyPointPipeline: MTLRenderPipelineState
    let solarOverlayPipeline: MTLRenderPipelineState
    let nebulaOverlayPipeline: MTLRenderPipelineState
    let blackHolePipeline: MTLRenderPipelineState
    let skyDepthState: MTLDepthStencilState
    // Source GpuPlanet.DrawAtmosphere47 uses SRC_ALPHA/ONE_MINUS_SRC_ALPHA,
    // depth test ON, depth writes OFF, with no PBR illumination.
    let atmospherePipeline: MTLRenderPipelineState
    // Windows GpuShip.cs v491 twin-engine additive flame triangles:
    // entirely source-defined and GPU procedural, 1728 vertices.
    let fighterPlasmaPipeline491: MTLRenderPipelineState
    // Original GpuToon60 default key-light bands, solely the
    // Vanguard431 during cinematic. No sphere/PBR changes.
    let sourceFighterToonPipeline60: MTLRenderPipelineState
    // Genuine v568 vanguard431.mesh + base.jpg, used only when
    // BOTH source resources are bundled. Previous v556 AS3D stays.
    let sourceFighterTexturedPipeline431: MTLRenderPipelineState
    private let sourceVanguard431: (buffer:MTLBuffer,count:Int,skin:MTLTexture)?
    // Selected source ship (0 KESTREL, 1 VANGUARD, 2 BASTION).
    // Verified once at startup, never fallback to an incorrect craft.
    private var combatCraft05:(buffer:MTLBuffer,count:Int,skin:MTLTexture)?
    // Separate v568 player craft, loaded ONLY on explicit diagnostic selection.
    private var sourcePlayerShip367: (buffer:MTLBuffer,count:Int,skin:MTLTexture)?
    private var sourcePlayerShip367LoadAttempted = false
    private let sourceShip367DrawProofRequested =
        ProcessInfo.processInfo.environment["ASTEROIDY_SHIP367_VERIFY"] == "1"
    private var sourceShip367DrawProofScheduled = false
    // Debug evidence is explicitly enabled only by an Apple Simulator
    // process environment flag, not during the normal user's game.
    private let sourceDrawProofRequested =
        ProcessInfo.processInfo.environment["ASTEROIDY_RENDER_VERIFY"] == "1"
    private var sourceDrawProofScheduled = false
    let atmosphereDepthState: MTLDepthStencilState
    private let atmosphereMesh: GPUModel
    private let carbonisAtmosphereMesh568: GPUModel
    // Source C279 is loaded only for a real sector-01 flight cinematic;
    // the level-5 Boreas diagnostic remains a separate original scene.
    private var carbonisIntroPlanet568: CarbonisIntroPlanet568?
    private var carbonisIntroLoadAttempted568 = false
    private let shipMesh: GPUModel
    private let asteroidMesh: GPUModel
    private let bulletMesh: GPUModel
    private let starMesh: GPUModel
    private let sphereSkyMesh: GPUModel
    private let sphereHaloTexture: MTLTexture
    private let solarOverlayMesh: GPUModel
    private let nebulaOverlayMesh: GPUModel
    private var nebulaTexture: MTLTexture?
    private var blackHoleTextures: MTLTexture?
    private var deepPlanetTextures: MTLTexture?
    private var nebulaLoadGate = SkyTextureGate55()
    private var nebulaSliceCache55 = SkyTextureSliceCache55(count: SphereNebula556.orbitThemeCount)
    private var blackHoleLoadGate = SkyTextureGate55()
    private var deepPlanetLoadGate = SkyTextureGate55()
    private var deepPlanetSliceCache55 = SkyTextureSliceCache55(count: DeepSkyPlanets55.count)
    private let planetVertexBuffers: [MTLBuffer]
    private let planetBufferSlots = MorphBufferSlots(count: 3)
    private let planetIndices: MTLBuffer
    private let planetIndexCount: Int
    private let planetAnimator: BoreasMorphRenderer556
    private let planetNodeTracks: BoreasNodeTracks556
    private var planetMorphScratch: [AssetMesh.Vertex]
    private var planetAnimationTime: Double = 0
    private var lastPlanetMorphUpload: Double = -1
    private let telemetry = RenderTelemetry()
    private var lastTelemetryLog: Double = 0
    // Original IntroScene41 cinematic; not a mission or campaign unlock.
    private var introTime41: Float = 0
    private var wasIntroPreview41 = false
    // Lazy, bounded cache of real GpuIntro41 seed-specific stone meshes.
    // The old octahedron is retained ONLY as the loading placeholder.
    // Generating at most one new mesh per frame bounds CPU frame spikes.
    private var introRockMeshes41: [Int:GPUModel] = [:]
    private var introRockLoadOrder41: [Int] = []
    private var introRockFailed41: Set<Int> = []
    private let introRockMaxCached41 = 256
    private var sphereFlight: SphereFlight67 = {
        var f = SphereFlight67()
        f.position = Vec2(x:320,y:360) // +Z, visible from diagnostic globe camera
        f.camera = SphereCamera67(at:f.position)
        return f
    }()
    var game = GameCore()
    // Separate sphere sandbox: actual Sphere67 motion and contact queries.
    // Does not claim to run a real v556 planet mission.
    private var sphereSector = SphereSector556(
        balance: CombatBalance556(level: 1, difficulty: .normal, spherical: true)!)
    private var damageLab = PlanetDamageLab556()
    private var previousDamageLabEnabled = false
    private var previousSectorTraining = false
    private var activePlanetTestLevel = 1
    private var lastTime = CACurrentMediaTime()
    private var fixedClock = FixedStepClock()
    private let fixedClockStep: Double = 1.0 / 120.0
    private var lastHUDTime: CFTimeInterval = 0

    init(device: MTLDevice, input: FlightInput,
         combatSession05:CarbonisSession568? = nil) throws {
        self.device = device
        self.input = input
        self.combatSession05=combatSession05
        guard let q = device.makeCommandQueue() else { throw NSError(domain:"ASTEROIDY iOS",code:1) }
        queue = q
        let library = try device.makeDefaultLibrary(bundle: .main)
        // Fail with the exact missing entrypoint instead of returning a
        // generic pipeline error. The source stars use a separate Metal
        // shader program but must never silently replace the PBR pipeline.
        func requireShader(_ name:String) throws -> MTLFunction {
            guard let fn=library.makeFunction(name:name) else {
                throw NSError(domain:"ASTEROIDY iOS Metal",code:11,
                              userInfo:[NSLocalizedDescriptionKey:
                                "Brak funkcji Metal: \(name)"])
            }
            return fn
        }
        let sceneVertex=try requireShader("sceneVertex")
        let sceneFragment=try requireShader("sceneFragment")
        let fighterToonFragment=try requireShader("sourceFighterToonFragment60")
        let originalFighterVertex=try requireShader("sourceVanguardVertex431")
        let originalFighterFragment=try requireShader(
            "sourceVanguardTexturedToonFragment431")
        let fighterPlasmaVertex=try requireShader("fighterPlasmaVertex491")
        let fighterPlasmaFragment=try requireShader("fighterPlasmaFragment491")
        let skyVertex=try requireShader("skyPointVertex")
        let skyFragment=try requireShader("skyPointFragment")
        let solarVertex=try requireShader("solarOverlayVertex")
        let solarFragment=try requireShader("solarOverlayFragment")
        let nebulaVertex=try requireShader("nebulaOverlayVertex")
        let nebulaFragment=try requireShader("nebulaOverlayFragment")
        let blackHoleVertex=try requireShader("blackHoleVertex55")
        let blackHoleFragment=try requireShader("blackHoleFragment55")
        let p = MTLRenderPipelineDescriptor()
        p.vertexFunction = sceneVertex
        p.fragmentFunction = sceneFragment
        p.colorAttachments[0].pixelFormat = .bgra8Unorm
        p.depthAttachmentPixelFormat = .depth32Float
        pipeline = try device.makeRenderPipelineState(descriptor:p)
        let fighterToonDesc=MTLRenderPipelineDescriptor()
        fighterToonDesc.vertexFunction=sceneVertex
        fighterToonDesc.fragmentFunction=fighterToonFragment
        fighterToonDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        fighterToonDesc.depthAttachmentPixelFormat = .depth32Float
        sourceFighterToonPipeline60=try device.makeRenderPipelineState(
            descriptor:fighterToonDesc)
        let fighterTexturedDesc=MTLRenderPipelineDescriptor()
        fighterTexturedDesc.vertexFunction=originalFighterVertex
        fighterTexturedDesc.fragmentFunction=originalFighterFragment
        fighterTexturedDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        fighterTexturedDesc.depthAttachmentPixelFormat = .depth32Float
        sourceFighterTexturedPipeline431=try device.makeRenderPipelineState(
            descriptor:fighterTexturedDesc)
        let atmosphereDesc=MTLRenderPipelineDescriptor()
        atmosphereDesc.vertexFunction=sceneVertex
        atmosphereDesc.fragmentFunction=sceneFragment
        guard let atmosphereBlend=atmosphereDesc.colorAttachments[0] else {
            throw MetalBlendAttachmentError.missingColorAttachment
        }
        atmosphereBlend.pixelFormat = .bgra8Unorm
        atmosphereDesc.depthAttachmentPixelFormat = .depth32Float
        atmosphereBlend.isBlendingEnabled=true
        atmosphereBlend.sourceRGBBlendFactor = .sourceAlpha
        atmosphereBlend.destinationRGBBlendFactor = .oneMinusSourceAlpha
        atmosphereBlend.sourceAlphaBlendFactor = .sourceAlpha
        atmosphereBlend.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        atmospherePipeline=try device.makeRenderPipelineState(
            descriptor:atmosphereDesc)
        let plasmaDescriptor=MTLRenderPipelineDescriptor()
        plasmaDescriptor.vertexFunction=fighterPlasmaVertex
        plasmaDescriptor.fragmentFunction=fighterPlasmaFragment
        guard let plasmaBlend=plasmaDescriptor.colorAttachments[0] else {
            throw MetalBlendAttachmentError.missingColorAttachment
        }
        plasmaBlend.pixelFormat = .bgra8Unorm
        plasmaDescriptor.depthAttachmentPixelFormat = .depth32Float
        plasmaBlend.isBlendingEnabled=true
        // Original GpuShip.cs:22 glBlendFunc(GL_SRC_ALPHA,GL_ONE).
        plasmaBlend.sourceRGBBlendFactor = .sourceAlpha
        plasmaBlend.destinationRGBBlendFactor = .one
        plasmaBlend.sourceAlphaBlendFactor = .sourceAlpha
        plasmaBlend.destinationAlphaBlendFactor = .one
        fighterPlasmaPipeline491=try device.makeRenderPipelineState(
            descriptor:plasmaDescriptor)
        // Source GpuIntro41 stars use RGBA and pixel dimensions. Keep a
        // dedicated blended POINT pipeline, independent of the existing
        // opaque PBR and flat training arena pipelines.
        let skyDescriptor=MTLRenderPipelineDescriptor()
        skyDescriptor.vertexFunction=skyVertex
        skyDescriptor.fragmentFunction=skyFragment
        guard let blend=skyDescriptor.colorAttachments[0] else {
            throw MetalBlendAttachmentError.missingColorAttachment
        }
        blend.pixelFormat = .bgra8Unorm
        skyDescriptor.depthAttachmentPixelFormat = .depth32Float
        blend.isBlendingEnabled = true
        blend.rgbBlendOperation = .add
        blend.alphaBlendOperation = .add
        // Windows/src/Gpu2DRenderer.cs:68,70: premultiplied
        // glBlendFunc(ONE,ONE_MINUS_SRC_ALPHA).
        blend.sourceRGBBlendFactor = .one
        blend.destinationRGBBlendFactor = .oneMinusSourceAlpha
        blend.sourceAlphaBlendFactor = .one
        blend.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        skyPointPipeline=try device.makeRenderPipelineState(descriptor:skyDescriptor)
        let solarDescriptor=MTLRenderPipelineDescriptor()
        solarDescriptor.vertexFunction=solarVertex
        solarDescriptor.fragmentFunction=solarFragment
        solarDescriptor.depthAttachmentPixelFormat = .depth32Float
        try SourceSkyPremultipliedBlend.configure(solarDescriptor)
        solarOverlayPipeline=try device.makeRenderPipelineState(
            descriptor:solarDescriptor)
        let nebulaDescriptor=MTLRenderPipelineDescriptor()
        nebulaDescriptor.vertexFunction=nebulaVertex
        nebulaDescriptor.fragmentFunction=nebulaFragment
        nebulaDescriptor.depthAttachmentPixelFormat = .depth32Float
        try SourceSkyPremultipliedBlend.configure(nebulaDescriptor)
        nebulaOverlayPipeline=try device.makeRenderPipelineState(
            descriptor:nebulaDescriptor)
        // Source GpuIntro41 DrawSkyBlackHole55 uses the same
        // premultiplied Blend(ONE,ONE_MINUS_SRC_ALPHA) as IntroSky.
        let blackDesc=MTLRenderPipelineDescriptor()
        blackDesc.vertexFunction=blackHoleVertex
        blackDesc.fragmentFunction=blackHoleFragment
        blackDesc.depthAttachmentPixelFormat = .depth32Float
        try SourceSkyPremultipliedBlend.configure(blackDesc)
        blackHolePipeline=try device.makeRenderPipelineState(
            descriptor:blackDesc)
        let skyDS=MTLDepthStencilDescriptor()
        // Sky first, no depth writes; later real planet geometry occludes
        // it with the unchanged .less depth test.
        skyDS.depthCompareFunction = .always
        skyDS.isDepthWriteEnabled = false
        guard let skyDepth=device.makeDepthStencilState(descriptor:skyDS)
        else {throw NSError(domain:"ASTEROIDY iOS",code:8,
                            userInfo:[NSLocalizedDescriptionKey:"Brak sky depth state"])}
        skyDepthState=skyDepth
        let ds = MTLDepthStencilDescriptor()
        ds.depthCompareFunction = .less
        ds.isDepthWriteEnabled = true
        guard let depth = device.makeDepthStencilState(descriptor:ds) else { throw NSError(domain:"ASTEROIDY iOS",code:2) }
        depthState = depth
        let atmoDepth=MTLDepthStencilDescriptor()
        atmoDepth.depthCompareFunction = .less
        atmoDepth.isDepthWriteEnabled = false
        guard let atmosphericState=device.makeDepthStencilState(
            descriptor:atmoDepth) else {
            throw NSError(domain:"ASTEROIDY iOS",code:18,
                userInfo:[NSLocalizedDescriptionKey:
                    "Brak prawidłowego depth state atmosfery Boreas"])
        }
        atmosphereDepthState=atmosphericState
        let atmosphericSource=IntroAtmosphere47.geometry()
        atmosphereMesh=try Self.makeMesh(
            device,atmosphericSource.vertices,atmosphericSource.indices)
        // PlanetBiome.ForLevel(1) => Carbonis277, Glow #EC4E19.
        // Keep exact Atmosphere47 positions/alpha; change ONLY the
        // authenticated per-planet colour of the light scatter.
        var carbonisHaze=atmosphericSource.vertices
        for i in carbonisHaze.indices {
            carbonisHaze[i].color.x=236.0/255.0
            carbonisHaze[i].color.y=78.0/255.0
            carbonisHaze[i].color.z=25.0/255.0
        }
        carbonisAtmosphereMesh568=try Self.makeMesh(
            device,carbonisHaze,atmosphericSource.indices)
        guard let url = Bundle.main.url(forResource:"Vanguard556",withExtension:"as3d")
            ?? Bundle.main.url(forResource:"Vanguard556",withExtension:"as3d",subdirectory:"Assets") else {
            throw NSError(domain:"ASTEROIDY iOS",code:3,userInfo:[NSLocalizedDescriptionKey:"Brak autentycznego modelu Vanguard556.as3d w aplikacji"])
        }
        let asset = try AssetMesh(data: Data(contentsOf:url))
        shipMesh = try Self.makeMesh(device, asset.vertices, asset.indices)

        // Source-faithful path is optional until the exact PC resource
        // pack is committed. NEVER silently substitute other textures.
        let originalMeshURL=Bundle.main.url(
            forResource:"Vanguard431Source",withExtension:"mesh")
            ?? Bundle.main.url(forResource:"Vanguard431Source",
                withExtension:"mesh",subdirectory:"Assets")
        let originalSkinURL=Bundle.main.url(
            forResource:"Vanguard431Base",withExtension:"jpg")
            ?? Bundle.main.url(forResource:"Vanguard431Base",
                withExtension:"jpg",subdirectory:"Assets")
        if let meshURL=originalMeshURL,let jpegURL=originalSkinURL {
            let sourceBytes=try Data(contentsOf:meshURL)
            let imageBytes=try Data(contentsOf:jpegURL)
            func sourceSHA256(_ data:Data)->String {
                SHA256.hash(data:data).map { String(format:"%02x",$0) }.joined()
            }
            // Never silently load a different ship or recoloured skin.
            guard sourceSHA256(sourceBytes) == SourceVanguardMesh431.exactMeshSHA256,
                  sourceSHA256(imageBytes) == SourceVanguardMesh431.exactBaseJPEG_SHA256 else {
                throw NSError(domain:"ASTEROIDY iOS",code:433,
                    userInfo:[NSLocalizedDescriptionKey:
                        "Oryginalny PC Vanguard431: błędny SHA256 modelu lub tekstury"])
            }
            let native=try SourceVanguardMesh431(
                data:sourceBytes)
            guard let sourceVB=native.vertices.withUnsafeBytes({
                $0.baseAddress.map {
                    device.makeBuffer(bytes:$0,length:native.vertices.count,
                                      options:[])
                } ?? nil
            }) else {
                throw NSError(domain:"ASTEROIDY iOS",code:431,
                    userInfo:[NSLocalizedDescriptionKey:
                        "Brak GPU bufora oryginalnej siatki Vanguard431"])
            }
            // Windows/src/GpuRenderer.cs:144-146 uses GL_RGBA8
            // with GL_BGRA bytes, not SRGB8_ALPHA8. GLSL receives
            // raw UNORM channels (no hardware sRGB decode), with
            // GL_LINEAR and GL_CLAMP_TO_EDGE, no mipmap generation.
            // Preserve the top-left uploaded Bitmap ordering and
            // the source glTexCoord0 UVs without an invented V-flip.
            let skin=try MTKTextureLoader(device:device).newTexture(
                URL:jpegURL,options:[
                    .SRGB:false,
                    .generateMipmaps:false,
                    .origin:MTKTextureLoader.Origin.topLeft
                ])
            sourceVanguard431=(
                buffer:sourceVB,count:native.vertexCount,skin:skin)
            NSLog("ASTEROIDY: real PC Vanguard431 UV/BaseColor active: %d vertices",
                  native.vertexCount)
        } else if originalMeshURL != nil || originalSkinURL != nil {
            throw NSError(domain:"ASTEROIDY iOS",code:432,
                userInfo:[NSLocalizedDescriptionKey:
                    "Niekompletne oryginalne zasoby Vanguard431 — potrzebne mesh i jpg"])
        } else {
            sourceVanguard431=nil
            NSLog("ASTEROIDY: original Vanguard431 texture assets not in app;"
                + " using previous v556 AS3D model, no texture fidelity claim")
        }
        if let combatSession05 {
            let type=combatSession05.game.sourceMechanics.selectedShip
            if type==1 {
                guard let original=sourceVanguard431 else {
                    throw NSError(domain:"ASTEROIDY source VANGUARD",code:431,
                        userInfo:[NSLocalizedDescriptionKey:
                            "Brak oryginalnego VANGUARD431 do misji 05"])
                }
                combatCraft05=original
            } else {
                // The exact same SHA-checked packs as live CARBONIS,
                // H290 and H55: no duplicated mesh or asset import code.
                let parsed:SourceBakedShipMesh
                let jpeg:Data
                if type==0,let pack=SourceKestrel603.load() {
                    parsed=pack.mesh
                    jpeg=pack.jpeg
                } else if type==2,let pack=SourceBastion606.load() {
                    parsed=pack.mesh
                    jpeg=pack.jpeg
                } else {
                    throw NSError(domain:"ASTEROIDY source craft",code:609,
                        userInfo:[NSLocalizedDescriptionKey:
                            "Wybrany statek nie ma zweryfikowanego modelu PC609"])
                }
                guard let vb=parsed.vertices.withUnsafeBytes({ raw in
                    raw.baseAddress.flatMap {
                        device.makeBuffer(bytes:$0,length:parsed.vertices.count,
                                          options:[])
                    }
                }) else {
                    throw NSError(domain:"ASTEROIDY source craft GPU",code:431)
                }
                let texture=try MTKTextureLoader(device:device).newTexture(
                    data:jpeg,options:[
                        .SRGB:false,.generateMipmaps:false,
                        .origin:MTKTextureLoader.Origin.topLeft])
                combatCraft05=(buffer:vb,count:parsed.vertexCount,skin:texture)
            }
        }
        // Two authentic ShipMesh kinds from GpuRobot70, once at startup.
        // BOREAS 05 currently generates kinds 0 and 1 only. Never fake
        // unported kinds 2-5 by silently substituting another kind.
        if combatSession05 != nil {
            for kind in 0...1 {
                let mesh=kind==0 ? CarbonisShooterMesh71.typeZero() :
                                     CarbonisShooterMesh71.typeOne()
                guard mesh.vertices.count % 12 == 0 else {
                    throw NSError(domain:"ASTEROIDY source enemy mesh",code:71)
                }
                var vertices:[AssetMesh.Vertex]=[]
                vertices.reserveCapacity(mesh.vertices.count/12)
                for i in stride(from:0,to:mesh.vertices.count,by:12) {
                    let v=mesh.vertices
                    vertices.append(AssetMesh.Vertex(
                        position:SIMD4<Float>(v[i],v[i+1],v[i+2],1),
                        color:SIMD4<Float>(v[i+6],v[i+7],v[i+8],v[i+9]),
                        normal:SIMD4<Float>(v[i+3],v[i+4],v[i+5],0)))
                }
                let indices=(0..<vertices.count).map { UInt32($0) }
                sourceShooterModels05[kind]=try Self.makeMesh(
                    device,vertices,indices)
            }
        }
        asteroidMesh = try Self.makeMesh(device, Self.asteroidVertices(), Self.octahedronIndices())
        bulletMesh = try Self.makeMesh(device, Self.bulletVertices(), Self.octahedronIndices())
        let starData = Self.stars()
        starMesh = try Self.makeMesh(device, starData.0, starData.1)
        let sphereSkyData=SourceSkyAssetFactory568.sphereSky207()
        sphereSkyMesh=try Self.makeMesh(device,sphereSkyData.0,sphereSkyData.1)
        sphereHaloTexture=try SourceSkyAssetFactory568.makeSphereHaloTexture(device)
        let overlayData=SourceSkyAssetFactory568.solarOverlaySource556()
        solarOverlayMesh=try Self.makeMesh(device,overlayData.0,overlayData.1)
        let cloudData=SourceSkyAssetFactory568.nebulaSource556()
        nebulaOverlayMesh=try Self.makeMesh(device,cloudData.0,cloudData.1)
        // Source GpuIntro41.cs generates large sky Bitmaps only after
        // their first visible SkyProject55. Do not eagerly allocate
        // 5.76MB of mostly unseen textures in the flat training arena.
        // MTLTexture resources are loaded on their first visible use.
        // Only use the verified v556 Boreas GLB conversion when bundled.
        // Never silently claim that the diagnostic UV sphere is an imported asset.
        guard AnimatedPlanetTestSlot556.sourceAssetsVerified,
              let planetURL=AnimatedPlanetTestSlot556.resourceURL(
                AnimatedPlanetTestSlot556.meshName,"as3d") else {
            throw NSError(domain:"ASTEROIDY iOS",code:5,userInfo:[NSLocalizedDescriptionKey:"Brak planety Boreas556.as3d — GLB z v556 nie został zapakowany"])
        }
        let planet = try AssetMesh(data: Data(contentsOf:planetURL))
        let initialPlanetMesh = try Self.makeMesh(device, planet.vertices, planet.indices)
        let vertexLength = planet.vertices.count * MemoryLayout<AssetMesh.Vertex>.stride
        var ring: [MTLBuffer] = [initialPlanetMesh.vertices]
        for _ in 1..<3 {
            guard let b = device.makeBuffer(bytes: planet.vertices, length: vertexLength, options: .storageModeShared) else {
                throw NSError(domain:"ASTEROIDY iOS",code:7,userInfo:[NSLocalizedDescriptionKey:"Nie udało się zaalokować buforów animacji Boreas"])
            }
            ring.append(b)
        }
        planetVertexBuffers = ring
        planetIndices = initialPlanetMesh.indices
        planetIndexCount = initialPlanetMesh.count
        guard let animURL=AnimatedPlanetTestSlot556.resourceURL(
                    AnimatedPlanetTestSlot556.animationName,"asmo"),
              let bindingURL=AnimatedPlanetTestSlot556.resourceURL(
                    AnimatedPlanetTestSlot556.bindingName,"json") else {
            throw NSError(domain:"ASTEROIDY iOS",code:6,userInfo:[NSLocalizedDescriptionKey:"Brak danych animacji lub wiązania Boreas"])
        }
        planetAnimator = try BoreasMorphRenderer556(source:BoreasMorph556(data:Data(contentsOf:animURL)),
                                                    bindingData:Data(contentsOf:bindingURL), mesh:planet)
        guard let tracksURL=AnimatedPlanetTestSlot556.resourceURL(
                AnimatedPlanetTestSlot556.nodeTracksName,"asnt") else {
            throw NSError(domain:"ASTEROIDY iOS",code:563,
                userInfo:[NSLocalizedDescriptionKey:
                    "Brak oryginalnych 96 kanałów animacji BOREAS / ASNT"])
        }
        planetNodeTracks=try BoreasNodeTracks556(
            data:Data(contentsOf:tracksURL),mesh:planet)
        planetMorphScratch = planetAnimator.makeScratchVertices()
    }

    private static func makeMesh(_ device: MTLDevice, _ v: [AssetMesh.Vertex], _ idx: [UInt32]) throws -> GPUModel {
        guard !v.isEmpty, !idx.isEmpty,
              let vb = device.makeBuffer(bytes:v,length:v.count * MemoryLayout<AssetMesh.Vertex>.stride,options:[]),
              let ib = device.makeBuffer(bytes:idx,length:idx.count * MemoryLayout<UInt32>.stride,options:[]) else {
            throw NSError(domain:"ASTEROIDY iOS",code:4,userInfo:[NSLocalizedDescriptionKey:"Nie udało się zaalokować siatki Metal"])
        }
        return GPUModel(vertices:vb,indices:ib,count:idx.count)
    }
    private struct SceneUniforms {
        var mvp: simd_float4x4
        var model: simd_float4x4
        var lighting: SIMD4<Float>
    }
    private struct FighterSourceUniform431 {
        var mvp:simd_float4x4
        var model:simd_float4x4
        var eyeView:simd_float4x4
    }
    private struct FighterPlasmaUniforms491 {
        var mvp: simd_float4x4
        var engine0: SIMD4<Float>
        var engine1: SIMD4<Float>
        // Original GpuShip.DrawFighterMesh(time,power=1,side=0).
        var frame: SIMD4<Float>
    }
    private static func octahedronIndices() -> [UInt32] { [0,2,4, 2,1,4, 1,3,4, 3,0,4, 2,0,5, 1,2,5, 3,1,5, 0,3,5] }
    private static func asteroidVertices() -> [AssetMesh.Vertex] {
        let pts: [SIMD3<Float>] = [SIMD3(1,0,0),SIMD3(-1,0,0),SIMD3(0,1,0),SIMD3(0,-1,0),SIMD3(0,0,0.8),SIMD3(0,0,-0.8)]
        return pts.enumerated().map { i,p in
            let k: Float = i % 2 == 0 ? 0.82 : 1.0
            return AssetMesh.Vertex(position:SIMD4(p.x,p.y,p.z,1),color:SIMD4(0.45*k,0.56*k,0.64*k,1),normal:SIMD4(p.x,p.y,p.z,0))
        }
    }
    private static func bulletVertices() -> [AssetMesh.Vertex] {
        let pts: [SIMD3<Float>] = [SIMD3(1,0,0),SIMD3(-1,0,0),SIMD3(0,1,0),SIMD3(0,-1,0),SIMD3(0,0,1),SIMD3(0,0,-1)]
        return pts.map { AssetMesh.Vertex(position:SIMD4($0.x,$0.y,$0.z,1),color:SIMD4(1,0.55,0.12,1),normal:SIMD4($0.x,$0.y,$0.z,0)) }
    }
    private static func stars() -> ([AssetMesh.Vertex],[UInt32]) {
        var vertices: [AssetMesh.Vertex] = [], indices: [UInt32] = []
        var state: UInt32 = 0x55612026
        func rnd() -> Float { state = state &* 1664525 &+ 1013904223; return Float(state >> 8) / Float(1 << 24) }
        for _ in 0..<130 {
            let x = (rnd()-0.5)*5.5, y = (rnd()-0.5)*3.6
            let r: Float = 0.004 + rnd()*0.006
            let base = UInt32(vertices.count)
            let color: SIMD4<Float> = SIMD4(0.38+rnd()*0.5,0.55,0.85,1)
            for p in [SIMD3<Float>(x-r,y-r,-0.9),SIMD3<Float>(x+r,y-r,-0.9),SIMD3<Float>(x,y+r,-0.9)] {
                vertices.append(.init(position:SIMD4(p.x,p.y,p.z,1),color:color,normal:SIMD4(0,0,1,0)))
            }
            indices.append(contentsOf:[base,base+1,base+2])
        }
        return (vertices,indices)
    }
    /// Windows/src/GpuAmbient37.cs:5 uses 64x64 premultiplied white
    /// pixels BGRA=(a,a,a,a). A single immutable texture is created at
    /// startup and sampled linearly, exactly like GL SetFilter(true).
    





    /// The original GpuCosmos39.CloudLayer and GpuIntro41.DrawSkyPlanet55/
    /// DrawSkyBlackHole55 allocate their images only on first visible use.
    /// All three texture arrays remain cached within this renderer for
    /// the rest of the session, regardless of flat/sphere toggling.
    /// Errors log once, and gameplay continues without that sky layer.
    private static let sourceCloudLayers55: [SphereNebula556.Layer] =
        (0..<SphereNebula556.orbitLayerCount).map {SphereNebula556.layer($0)}

    private func ensureCloudTextures55(camera: SphereCamera67) -> MTLTexture? {
        return SourceSkyTextureLifecycle55.ensureCloudTextures55(
            device:device,camera:camera,sourceCloudLayers55:Self.sourceCloudLayers55,
            nebulaTexture:&nebulaTexture,nebulaLoadGate:&nebulaLoadGate,
            nebulaSliceCache55:&nebulaSliceCache55)
    }

    private func ensureDeepPlanetTextures55(style: Int) -> MTLTexture? {
        return SourceSkyTextureLifecycle55.ensureDeepPlanetTextures55(
            device:device,style:style,deepPlanetTextures:&deepPlanetTextures,
            deepPlanetLoadGate:&deepPlanetLoadGate,
            deepPlanetSliceCache55:&deepPlanetSliceCache55)
    }

    private func ensureBlackHoleTextures55() -> MTLTexture? {
        return SourceSkyTextureLifecycle55.ensureBlackHoleTextures55(
            device:device,blackHoleTextures:&blackHoleTextures,
            blackHoleLoadGate:&blackHoleLoadGate)
    }

    /// Two immutable original GpuCosmos39 PArgb NebulaTexture themes
    /// used by GpuIntro41.IntroSky. Share one 2-slice texture array across
    /// all 36 distant/near cloud layers, allocated exactly once. Each
    /// 256px CPU bitmap is generated only when its theme is visible.
    

    

    /// Original DrawDeepSpace55 emits 24 distant clouds, IntroSky adds
    /// 12 near layers. A static 216-vertex stream stores the exact
    /// source 3D sky directions, UV, alpha, theme and layer type; the
    /// original SkyProject55 is evaluated in the GPU vertex stage with
    /// the LIVE camera, without rebuilding the geometry every frame.
    

    /// Original BuildBlackHoleDisk55(false), BuildBlackHoleCore55(),
    /// BuildBlackHoleDisk55(true) from actual v556 GpuIntro41.cs. One
    /// three-slice GPU texture shared by all 3 black-hole image passes.
    /// Source GpuRenderer.Texture(Bitmap) uploads Format32bppPArgb.
    /// Never flatten the original rear/core/front ordering.
    

    /// Real GpuIntro41.BuildDeepPlanet55(0/1/2): all images are
    /// 320x220 Format32bppPArgb. Allocate only ONCE in a single GPU
    /// array. The array is allocated once at first visible planet; each
    /// actual CPU image/slice is uploaded only when THAT style is visible.
    /// Reuse BlackHole55's generic premultiplied 2D shader: texture slice
    /// -1 uses the original shared StarTexture halo.
    

    

    private static func translation(_ x: Float,_ y: Float,_ z: Float) -> simd_float4x4 {
        simd_float4x4(columns:(SIMD4(1,0,0,0),SIMD4(0,1,0,0),SIMD4(0,0,1,0),SIMD4(x,y,z,1)))
    }
    private static func scale(_ s: Float) -> simd_float4x4 {
        simd_float4x4(diagonal:SIMD4(s,s,s,1))
    }
    private static func rotated(_ angle: Float) -> simd_float4x4 {
        simd_float4x4(columns:(SIMD4(cos(angle),sin(angle),0,0),SIMD4(-sin(angle),cos(angle),0,0),SIMD4(0,0,1,0),SIMD4(0,0,0,1)))
    }
    private static func rotateXDegrees(_ degrees: Float) -> simd_float4x4 {
        let a=degrees * Float.pi / 180
        let c=cos(a), v=sin(a)
        return simd_float4x4(columns:(
            SIMD4(1,0,0,0),SIMD4(0,c,v,0),
            SIMD4(0,-v,c,0),SIMD4(0,0,0,1)))
    }
    private static func rotateYDegrees(_ degrees: Float) -> simd_float4x4 {
        let a=degrees * Float.pi / 180
        let c=cos(a), v=sin(a)
        return simd_float4x4(columns:(
            SIMD4(c,0,-v,0),SIMD4(0,1,0,0),
            SIMD4(v,0,c,0),SIMD4(0,0,0,1)))
    }
    private static func sphereStamp(_ point: Vec2,
                                    angle: Float, size: Float,
                                    lift: Float = 0) -> simd_float4x4 {
        // GpuSphere67.StampSphere67: local X=right, local Y=forward,
        // local Z=normal. No independent guessed renderer transform.
        let m=SphereSurfaceStamp556(
            point:point,angle:angle,lift:lift).columnMajor(size:size)
        return simd_float4x4(columns:(
            SIMD4(m[0],m[1],m[2],m[3]),
            SIMD4(m[4],m[5],m[6],m[7]),
            SIMD4(m[8],m[9],m[10],m[11]),
            SIMD4(m[12],m[13],m[14],m[15])))
    }
    private static func perspective(_ aspect: Float, spherical: Bool) -> simd_float4x4 {
        // Original GpuIntro41.IntroProjection uses near=.4, far=1600,
        // half-height=.2 (vertical FOV 53.1301°). In sphere mode
        // normalize BOTH clip planes by original Boreas outer radius,
        // just like the view eye and all model positions. Keep the
        // independent flat arena's unchanged .1/20 clipping planes.
        let clip = SphereProjection556.clipPlanes(spherical:spherical)
        let near = clip.near, far = clip.far
        let y: Float = spherical
            ? SphereProjection556.sourceVerticalFocal
            : 1 / tan(Float.pi/5.0 / 2)
        let x = y / max(aspect,0.1)
        return simd_float4x4(columns:(SIMD4(x,0,0,0),SIMD4(0,y,0,0),
                                        SIMD4(0,0,far/(near-far),-1),
                                        SIMD4(0,0,near*far/(near-far),0)))
    }
    // Source GpuSphere67.SphereScene67 -> OrbitWorld50.View(eye, 0, up).
    // The pure frame is tested on Linux in SphereCameraView556Tests.
    // Keep our original flat arena's fixed (0,0,4) view unchanged.
    private static func sphereView(_ camera: SphereCamera67)
        -> (view: simd_float4x4, eye: SIMD3<Float>) {
        let b = SphereCameraView556(camera: camera)
        let m = b.viewColumnMajor
        // One source of truth: OrbitWorld50.View column-major values are
        // verified by SphereCameraView556Tests and used directly by Metal.
        let view = simd_float4x4(columns:(
            SIMD4(m[0],m[1],m[2],m[3]),
            SIMD4(m[4],m[5],m[6],m[7]),
            SIMD4(m[8],m[9],m[10],m[11]),
            SIMD4(m[12],m[13],m[14],m[15])
        ))
        return (view,SIMD3(b.eye.x,b.eye.y,b.eye.z))
    }
    // Windows GpuIntro41.DrawPlanetSolid -> DrawReplacedPlanet463(time,true):
    // the original Boreas glTF morph plays in BOTH cinematic and combat.
    // The ring and dynamic-range upload are the existing, proven mechanism.
    // Only the timeline source differs (IntroTime vs planetAnimationTime).
    private func uploadBoreasMorphIfNeeded(seconds: Double) {
        guard seconds.isFinite, seconds >= 0 else { return }
        guard lastPlanetMorphUpload < 0 ||
              seconds < lastPlanetMorphUpload ||
              seconds - lastPlanetMorphUpload >= 1.0/30.0
        else { return }
        guard let slot = planetBufferSlots.reserveWrite() else {
            telemetry.noteUpload(success: false)
            return
        }
        let morphStarted = ProcessInfo.processInfo.systemUptime
        planetAnimator.updateVertices(seconds: seconds, into: &planetMorphScratch)
        // The other 96 authored GLB channels animate the 24 droplets and
        // 24 liquid necks using this SAME clock and GPU triple-buffer.
        // No second scene, independent GPU renderer or fake particles.
        planetNodeTracks.updateVertices(seconds:seconds,
                                        into:&planetMorphScratch)
        telemetry.record(.morphCPU,
            seconds: ProcessInfo.processInfo.systemUptime - morphStarted)
        let range = planetAnimator.dynamicVertexRange
        let strideBytes = MemoryLayout<AssetMesh.Vertex>.stride
        let startByte = range.lowerBound * strideBytes
        let dynamicBytes = range.count * strideBytes
        let nodes = planetNodeTracks.dynamicVertexRange
        let nodeStartByte = nodes.lowerBound * strideBytes
        let nodeBytes = nodes.count * strideBytes
        let target = planetVertexBuffers[slot]
        guard startByte <= target.length &&
              dynamicBytes <= target.length - startByte &&
              nodeStartByte <= target.length &&
              nodeBytes <= target.length - nodeStartByte else {
            telemetry.noteUpload(success: false)
            planetBufferSlots.cancelWrite(slot)
            return
        }
        // Preserve immutable source vertices and the GPU in-flight lifetime.
        let copyStarted = ProcessInfo.processInfo.systemUptime
        planetMorphScratch.withUnsafeBytes { bytes in
            if let p = bytes.baseAddress {
                memcpy(target.contents().advanced(by:startByte),
                       p.advanced(by:startByte),dynamicBytes)
                memcpy(target.contents().advanced(by:nodeStartByte),
                       p.advanced(by:nodeStartByte),nodeBytes)
            }
        }
        telemetry.record(.uploadCPU,
            seconds: ProcessInfo.processInfo.systemUptime - copyStarted)
        telemetry.noteUpload(success: true)
        planetBufferSlots.publish(slot)
        lastPlanetMorphUpload = seconds
    }

    private static func introView41(_ time:Float)
        -> (view: simd_float4x4, eye: SIMD3<Float>) {
        let f=IntroOrbit41.frame(time)
        let m=f.viewColumnMajor
        let view=simd_float4x4(columns:(
            SIMD4(m[0],m[1],m[2],m[3]),
            SIMD4(m[4],m[5],m[6],m[7]),
            SIMD4(m[8],m[9],m[10],m[11]),
            SIMD4(m[12],m[13],m[14],m[15])
        ))
        let e=f.eyeNormalized
        return (view,SIMD3(e.x,e.y,e.z))
    }
    /// Load only the source-audited PlayerShip367 GPU stream and its matching
    /// texture. Missing resources do not trigger a misleading substitute model.
    private func verifiedPlayerShip367() ->
        (buffer: MTLBuffer, count: Int, skin: MTLTexture)? {
        if sourcePlayerShip367LoadAttempted { return sourcePlayerShip367 }
        sourcePlayerShip367LoadAttempted = true
        let file = Bundle.main.url(
            forResource: "PlayerShip367OriginalGPU", withExtension: "bin")
            ?? Bundle.main.url(
                forResource: "PlayerShip367OriginalGPU",
                withExtension: "bin", subdirectory: "Assets")
        let jpeg = Bundle.main.url(
            forResource: "PlayerShip363Base", withExtension: "jpg")
            ?? Bundle.main.url(
                forResource: "PlayerShip363Base",
                withExtension: "jpg", subdirectory: "Assets")
        guard let meshURL=file, let skinURL=jpeg else {
            DispatchQueue.main.async { [weak input] in
                input?.rendererError =
                    "Statek 03 wymaga oryginalnych zasobów PlayerShip367 v568"
            }
            return nil
        }
        do {
            let original=try SourcePlayerShip367(
                data: Data(contentsOf:meshURL))
            let jpegBytes=try Data(contentsOf:skinURL)
            guard SourcePlayerShip367.verifiedTexture(jpegBytes) else {
                throw SourcePlayerShip367.AssetError.wrongSource
            }
            guard let buffer=original.gpuBytes.withUnsafeBytes({
                raw in raw.baseAddress.flatMap {
                    device.makeBuffer(bytes:$0,length:original.gpuBytes.count,
                                      options:[])
                }
            }) else {
                throw NSError(domain:"ASTEROIDY v568 PlayerShip367",code:1)
            }
            let texture=try MTKTextureLoader(device:device).newTexture(
                URL:skinURL,options:[
                    .SRGB:false,
                    .generateMipmaps:false,
                    .origin:MTKTextureLoader.Origin.topLeft
                ])
            sourcePlayerShip367=(buffer:buffer,count:SourcePlayerShip367.vertexCount,
                                 skin:texture)
            NSLog("ASTEROIDY: original PlayerShip367 v568 GPU/UV/JPEG loaded")
            return sourcePlayerShip367
        } catch {
            NSLog("ASTEROIDY: original PlayerShip367 rejected: %@",
                  String(describing:error))
            DispatchQueue.main.async { [weak input] in
                input?.rendererError =
                    "Nieprawidłowy oryginalny model PlayerShip367 v568"
            }
            return nil
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        // 120 Hz fixed-step simulation decoupled from 60/120 Hz display refresh.
        // A bounded catch-up prevents an unbounded simulation spiral after resume.
        let frameElapsed = min(0.25, max(0, now - lastTime))
        lastTime = now
        // Continue presenting Metal frames, but do not advance the
        // original cinematic or either game simulation under an overlay.
        // Keeping lastTime current avoids a 250-ms catch-up on resume.
        let elapsed = input.gameplayPaused ? 0.0 : frameElapsed
        if input.introPreview41 != wasIntroPreview41 {
            // Different source clocks: always refresh the first GLB
            // morph frame when switching cinematic <-> Boreas combat.
            lastPlanetMorphUpload = -1
            if input.introPreview41 {introTime41=0}
        }
        wasIntroPreview41=input.introPreview41
        if input.introPreview41 {
            if input.missionIntroSector == 1 {
                // Game.StepIntro (Intro41.cs) is NOT a looping preview.
                // Exactly one 16-second pass; the owning mission view
                // observes 16.0 and transfers into real CARBONIS combat.
                introTime41=min(IntroOrbit41.duration,
                                introTime41+Float(elapsed))
            } else {
                // The explicitly selected old debug preview may loop.
                introTime41=(introTime41+Float(elapsed))
                    .truncatingRemainder(dividingBy:IntroOrbit41.duration)
            }
        }
        if input.sectorTraining != previousSectorTraining {
            previousSectorTraining = input.sectorTraining
            let balance = input.sectorTraining ? CombatBalance556(level: 1, difficulty: .normal, spherical: false) : nil
            game.setSectorTraining(balance)
        }
        if input.verifiedDamageLab != previousDamageLabEnabled {
            previousDamageLabEnabled=input.verifiedDamageLab
            damageLab=PlanetDamageLab556()
        }
        // The native playable Boreas diagnostic was previously hardwired
        // to level 1. Switch only among source-audited test sectors:
        // Boreas sector 05 is visual-only test; Gameplay65 waves 9/17
        // and AmigaOnly266 level 25 remain test-only as before.
        // Do not claim campaign progress or reset unrelated flat GameCore.
        let selected=input.planetTestLevel
        if combatSession05 == nil && selected != activePlanetTestLevel &&
           [1,AnimatedPlanetTestSlot556.sector,9,17,25].contains(selected),
           let balance=CombatBalance556(level:selected,difficulty:.normal,
                                         spherical:true) {
            sphereSector=SphereSector556(balance:balance)
            var freshFlight=SphereFlight67()
            freshFlight.position=Vec2(x:320,y:360)
            freshFlight.camera=SphereCamera67(at:freshFlight.position)
            sphereFlight=freshFlight
            damageLab=PlanetDamageLab556()
            activePlanetTestLevel=selected
        }
        let command = FlightCommand(turn:input.steer,throttle:input.thrust,fire:input.shooting)
        if let combatSession05, input.planetPreview {
            // One combat owner: advance the same CarbonisSession568
            // stepped by the original HUD, weapons, damage and victory.
            // The independent sphere sandbox is never stepped here.
            combatSession05.frame(at:now)
            sphereFlight=combatSession05.game.flight
            planetAnimationTime += elapsed
        } else {
        fixedClock.advance(elapsed:elapsed) {
            if input.introPreview41 {
                // Source cinematic must not run either test simulation.
                return
            }
            if input.planetPreview {
                planetAnimationTime += fixedClockStep
                let canControl = !input.verifiedDamageLab || !damageLab.gameOver
                if canControl {
                    sphereFlight.tick(move: Vec2(x:input.steer,y:-input.thrust),
                                      aim: Vec2(x:input.steer,y:-input.thrust),dt:Float(fixedClockStep))
                    if input.shooting {
                        let heading = Vec2(x:cos(sphereFlight.heading),y:sin(sphereFlight.heading))
                        sphereSector.fire(from:sphereFlight.position,direction:heading)
                    }
                }
                let contact=sphereSector.tick(
                    dt:Float(fixedClockStep),playerPosition:sphereFlight.position,
                    playerRadius:11.2,detectContacts:canControl,
                    playerVelocity:canControl ? sphereFlight.velocity : nil,
                    shipMass:2.4,useLegacyHull:!input.verifiedDamageLab)
                if let shipContact=contact {
                    sphereFlight.position=shipContact.position
                    sphereFlight.velocity=shipContact.velocity
                    if shipContact.contacts>0 {
                        sphereFlight.camera.update(target:shipContact.position,
                                                   dt:Float(fixedClockStep))
                    }
                }
                if input.verifiedDamageLab {
                    _ = damageLab.advance(dt:Float(fixedClockStep),
                        contacts:contact?.contacts ?? 0,
                        sector:&sphereSector,flight:&sphereFlight,
                        tarczaHeld:input.tarczaHeld)
                }
            } else {
                game.tick(command,dt:Float(fixedClockStep))
            }
        }
        }
        if now-lastHUDTime > 0.14 {
            lastHUDTime = now
            let introElapsed41=introTime41
            let score = combatSession05?.game.score ??
                (input.planetPreview ? sphereSector.score : game.score)
            let hull = combatSession05?.game.lives ??
                (input.planetPreview
                 ? (input.verifiedDamageLab ? damageLab.lives : sphereSector.hull)
                 : game.hull)
            let gameOver = input.planetPreview && input.verifiedDamageLab && damageLab.gameOver
            let deaths = damageLab.deathCount
            let armor = damageLab.armor
            let health = damageLab.hull
            let domeEnergy = damageLab.tarczaEnergy
            let domeActive = damageLab.tarczaActive
            let rockCount = combatSession05?.game.rocks.count ??
                (input.planetPreview ? sphereSector.asteroids.count : game.rocks.count)
            let sectorCleared = combatSession05?.game.phase == .victory ||
                (combatSession05 == nil && sphereSector.sectorCleared)
            let objectiveWave = sphereSector.objectiveWave
            let incomingNotice = sphereSector.arrivalNoticeRemaining > 0
            let amigaDemo=sphereSector.isAmigaDemo
            let amigaHits=sphereSector.amigaHits
            DispatchQueue.main.async { [weak input] in
                input?.introProgress41 = introElapsed41
                input?.score = score
                input?.hull = hull
                input?.verifiedGameOver = gameOver
                input?.verifiedDeaths = deaths
                input?.verifiedArmor = armor
                input?.verifiedHull = health
                input?.verifiedTarczaEnergy = domeEnergy
                input?.verifiedTarczaActive = domeActive
                input?.trainingRockCount = rockCount
                input?.planetSectorCleared = sectorCleared
                input?.planetWave = objectiveWave
                input?.planetIncomingNotice = incomingNotice
                input?.planetAmigaDemo = amigaDemo
                input?.planetAmigaHits = amigaHits
            }
        }
        // Original Windows/src/GpuSphere67.cs:420 sets this exact
        // clearColor before drawing IntroSky and the combat planet.
        // Keep the pre-existing flat arena background unchanged.
        if input.planetPreview || input.introPreview41 {
            view.clearColor=MTLClearColor(red:0.012,green:0.021,
                                         blue:0.04,alpha:1)
        } else {
            view.clearColor=MTLClearColor(red:0.01,green:0.025,
                                         blue:0.07,alpha:1)
        }
        guard let pass = view.currentRenderPassDescriptor, let drawable = view.currentDrawable,
              let command = queue.makeCommandBuffer(), let encoder = command.makeRenderCommandEncoder(descriptor:pass) else { return }
        let aspect = Float(view.drawableSize.width / max(view.drawableSize.height,1))
        // SphereCombat67/GpuSphere67 camera must follow SphereFlight67's
        // verified focus/up; the flat arena still uses the original view.
        let cameraFrame: (view: simd_float4x4, eye: SIMD3<Float>)
        if input.introPreview41 {
            cameraFrame=Self.introView41(introTime41)
        } else if input.planetPreview {
            cameraFrame=Self.sphereView(sphereFlight.camera)
        } else {
            cameraFrame=(view:Self.translation(0,0,-4),
                         eye:SIMD3<Float>(0,0,4))
        }
        let vp=Self.perspective(
            aspect,spherical:input.planetPreview || input.introPreview41) *
            cameraFrame.view
        encoder.setRenderPipelineState(pipeline)
        encoder.setDepthStencilState(depthState)
        encoder.setCullMode(.none)
        func drawMesh(_ mesh: GPUModel, _ model: simd_float4x4, unlit: Float = 0) {
            // The model transform carries the normal direction. All current scene
            // transforms are uniform scales plus rigid motions (no shear).
            // Pass the physical camera eye in spare uniform components.
            // PBR's view vector must rotate with the camera rather than
            // always pretending the camera is at flat-mode (0,0,4).
            var uniform = SceneUniforms(
                mvp: vp * model, model: model,
                lighting: SIMD4<Float>(unlit,
                    cameraFrame.eye.x,cameraFrame.eye.y,cameraFrame.eye.z))
            encoder.setVertexBuffer(mesh.vertices,offset:0,index:0)
            encoder.setVertexBytes(&uniform,length:MemoryLayout<SceneUniforms>.stride,index:1)
            encoder.drawIndexedPrimitives(type:.triangle,indexCount:mesh.count,indexType:.uint32,indexBuffer:mesh.indices,indexBufferOffset:0)
        }
        if input.introPreview41 {
            // The source Windows GpuIntro41.CinematicIntro41 16-second
            // scene, NOT the independent flat or Boreas training arena.
            let frame=IntroOrbit41.frame(introTime41)
            let inv=IntroOrbit41.radiusNormalization

            // CinematicIntro41 IntroSky painter order, using the exact
            // cinematic camera axes (not the sphere-combat camera):
            // 24 FAR clouds, 3 planets, black hole, 12 NEAR clouds,
            // 1500 stars and 5 solar rays, all original source layers.
            // clouds are layered BEFORE stars and the five solar rays.
            // One immutable 216-vertex buffer, one 2-slice 256x256
            // NebulaTexture; camera orientation changes in a uniform.
            let c=IntroOrbit41.skyCamera(time:introTime41)
            var nebulaUniform=(
                SIMD4<Float>(c.right.x,c.right.y,c.right.z,0),
                SIMD4<Float>(c.up.x,c.up.y,c.up.z,0),
                SIMD4<Float>(c.focus.x,c.focus.y,c.focus.z,0),
                SIMD4<Float>(2/(720*aspect),-2/720,0,0)
            )
            encoder.setDepthStencilState(skyDepthState)
            let sourceCloudTexture=ensureCloudTextures55(camera:c)
            if let clouds=sourceCloudTexture {
                encoder.setRenderPipelineState(nebulaOverlayPipeline)
                encoder.setVertexBuffer(
                    nebulaOverlayMesh.vertices,offset:0,index:0)
                encoder.setVertexBytes(
                    &nebulaUniform,length:MemoryLayout.size(ofValue:nebulaUniform),
                    index:1)
                encoder.setFragmentTexture(clouds,index:0)
                // C# DrawDeepSpace55: 24 FAR cloud layers first.
                encoder.drawPrimitives(
                    type:.triangle,vertexStart:0,
                    vertexCount:24*6)
            }

            // C# DrawDeepSpace55 and DrawSkyPlanet55:
            // three source planets in style order 0→1→2, each:
            // optional source glow IntroHalo then a 320x220 texture.
            // Reuse the existing premultiplied 2D quad shader from
            // BlackHole55; no new MSL entrypoints or pipeline, no
            // dynamic GPU textures. One draw PER visible source planet
            // preserves draw order with the following black hole.
            for style in 0..<DeepSkyPlanets55.count {
                guard let projected=DeepSkyPlanets55.project(
                    style:style,time:introTime41,
                    camera:c) else { continue }
                // Source GpuIntro41: only build any planet Bitmap
                // AFTER SkyProject55 confirms visibility.
                guard let planets=ensureDeepPlanetTextures55(style:style)
                else { break }
                encoder.setRenderPipelineState(blackHolePipeline)
                encoder.setFragmentTexture(planets,index:0)
                encoder.setFragmentTexture(sphereHaloTexture,index:1)
                let x=(projected.screen.x-640)*2/(720*aspect)
                let y=(360-projected.screen.y)*2/720
                let frame=SIMD4<Float>(x,y,2/(720*aspect),-2/720)
                let layers=DeepSkyPlanets55.overlays(
                    style:style,scale:projected.scale,glow:true)
                let uniforms=SourceSkyUniformPacking.planet(frame:frame,layers:layers)
                uniforms.withUnsafeBytes { raw in
                    if let ptr=raw.baseAddress {
                        encoder.setVertexBytes(
                            ptr,length:raw.count,index:0)
                    }
                }
                encoder.drawPrimitives(type:.triangle,
                    vertexStart:0,vertexCount:layers.count*6)
            }

            // C# DrawDeepSpace55: the black hole is behind the NEAR
            // cloud layers and in front of FAR clouds. 3 source
            // StarTexture halos, 4 moving rays, then rear disk/core/
            // front disk in the exact original 2D painter order.
            if let blackProjection=BlackHoleSky55.project(
                camera:c,time:introTime41),
                let blackTextures=ensureBlackHoleTextures55() {
                let bx=(blackProjection.screen.x-640)*2/(720*aspect)
                let by=(360-blackProjection.screen.y)*2/720
                let screen=SIMD4<Float>(bx,by,2/(720*aspect),-2/720)
                let layers=BlackHoleSky55.overlays(
                    time:introTime41,
                    scale:blackProjection.scale,glow:true)
                let properties=SourceSkyUniformPacking.blackHole(screen:screen,layers:layers)
                encoder.setRenderPipelineState(blackHolePipeline)
                properties.withUnsafeBytes { raw in
                    if let ptr=raw.baseAddress {
                        encoder.setVertexBytes(
                            ptr,length:raw.count,index:0)
                    }
                }
                encoder.setFragmentTexture(blackTextures,index:0)
                encoder.setFragmentTexture(sphereHaloTexture,index:1)
                encoder.drawPrimitives(type:.triangle,vertexStart:0,
                    vertexCount:layers.count*6)
            }
            // C# IntroSky: 12 NEAR clouds come AFTER all background
            // space objects. Reuse the SAME immutable buffer and
            // two-texture-array; no new geometry or texture uploads.
            if let clouds=sourceCloudTexture {
                encoder.setRenderPipelineState(nebulaOverlayPipeline)
                encoder.setVertexBuffer(
                    nebulaOverlayMesh.vertices,offset:0,index:0)
                encoder.setVertexBytes(
                    &nebulaUniform,length:MemoryLayout.size(ofValue:nebulaUniform),
                    index:1)
                encoder.setFragmentTexture(clouds,index:0)
                encoder.drawPrimitives(type:.triangle,
                    vertexStart:24*6,vertexCount:12*6)
            }
            // Source GpuIntro41.IntroSky uses a sky centred on the eye.
            // Render 1500 alpha-blended screen-size points in one GPU call;
            // none writes depth or changes the scene PBR pipeline.
            let skyEye=cameraFrame.eye
            let skyMVP=vp*Self.translation(skyEye.x,skyEye.y,skyEye.z)
            var skyUniform=SceneUniforms(
                mvp:skyMVP,model:matrix_identity_float4x4,
                lighting:SIMD4<Float>(SphereSky207.drawableScale(
                    height:Float(view.drawableSize.height)),0,0,0))
            encoder.setRenderPipelineState(skyPointPipeline)
            encoder.setDepthStencilState(skyDepthState)
            encoder.setFragmentTexture(sphereHaloTexture,index:0)
            encoder.setVertexBuffer(sphereSkyMesh.vertices,offset:0,index:0)
            encoder.setVertexBytes(
                &skyUniform,length:MemoryLayout<SceneUniforms>.stride,index:1)
            encoder.drawPrimitives(
                type:.point,vertexStart:0,vertexCount:sphereSkyMesh.count)
            // GpuIntro41.cs:454: only draw solar effects when the source
            // 900-unit sky direction is in the original extended screen
            // bounds. SkyProject55 uses the camera rotation, NOT its eye.
            if let sun=SphereSolarOverlay556.project(
                camera:c) {
                let ndcX=(sun.x-640)*2/(720*aspect)
                let ndcY=(360-sun.y)*2/720
                var solarUniform=SIMD4<Float>(
                    ndcX,ndcY,2/(720*aspect),-2/720)
                encoder.setRenderPipelineState(solarOverlayPipeline)
                encoder.setVertexBuffer(
                    solarOverlayMesh.vertices,offset:0,index:0)
                encoder.setVertexBytes(
                    &solarUniform,
                    length:MemoryLayout<SIMD4<Float>>.stride,index:1)
                encoder.setFragmentTexture(sphereHaloTexture,index:0)
                encoder.drawPrimitives(
                    type:.triangle,vertexStart:0,
                    vertexCount:solarOverlayMesh.count)
            }
            encoder.setDepthStencilState(depthState)
            encoder.setRenderPipelineState(pipeline)

            // Original source painter order: Belt51 rocks, 24-unit
            // intro planet, orbiting Vanguard. Exact IntroStone +
            // StoneNormal56 per-seed geometry is built ONLY on first
            // visibility, at most one stone per frame (mobile budget).
            // Meshes live in a bounded cache; only not-yet-created
            // stones temporarily use the legacy octahedral placeholder.
            let beltCenter=IntroOrbit41.planetCenter*inv
            let beltTransform = Self.translation(
                beltCenter.x,beltCenter.y,beltCenter.z) *
                Self.rotateYDegrees(
                    IntroOrbit41.beltRotationDegrees(time:introTime41))
            var builtThisFrame=0
            for (index,rock) in IntroOrbit41.belt.enumerated()
                where IntroOrbit41.visible(rock,time:introTime41,in:frame) {
                let local=rock.center*inv
                let translation=beltTransform *
                    Self.translation(local.x,local.y,local.z)
                if let original=introRockMeshes41[index] {
                    drawMesh(original,translation)
                    continue
                }
                if builtThisFrame==0 && !introRockFailed41.contains(index) {
                    builtThisFrame=1
                    do {
                        let source=IntroRockGeometry41.geometry(rock)
                        let model=try Self.makeMesh(device,source.vertices,source.indices)
                        if introRockMeshes41.count >= introRockMaxCached41,
                           !introRockLoadOrder41.isEmpty {
                            let oldest=introRockLoadOrder41.removeFirst()
                            introRockMeshes41.removeValue(forKey:oldest)
                        }
                        introRockMeshes41[index]=model
                        introRockLoadOrder41.append(index)
                        drawMesh(model,translation)
                        continue
                    } catch {
                        introRockFailed41.insert(index)
                        NSLog("ASTEROIDY iOS IntroStone source rock %ld: %@",
                              index,String(describing:error))
                    }
                }
                drawMesh(asteroidMesh,
                    translation*Self.scale(rock.size*inv))
            }
            let center=IntroOrbit41.planetCenter*inv
            let missionCarbonis=input.missionIntroSector == 1
            // GpuIntro41.CinematicIntro41 draws the selected sector's
            // REAL planet. The historical debug preview was fixed to
            // level 5 Boreas, so it cannot stand in for CARBONIS 01.
            if missionCarbonis {
                if !carbonisIntroLoadAttempted568 {
                    carbonisIntroLoadAttempted568=true
                    do {
                        carbonisIntroPlanet568=try CarbonisIntroPlanet568(
                            device:device,queue:queue)
                    } catch {
                        NSLog("Intro41 source CARBONIS C279 cannot load: %@",
                              String(describing:error))
                        DispatchQueue.main.async { [weak input] in
                            input?.rendererError =
                                "Brak oryginalnej planety CARBONIS w Intro41"
                        }
                    }
                }
                if let carbonis=carbonisIntroPlanet568 {
                    let model=Self.translation(center.x,center.y,center.z) *
                        Self.scale(carbonis.introNormalizedScale) *
                        Self.rotateXDegrees(-18) *
                        Self.rotateYDegrees(IntroOrbit41.planetRotationDegrees(
                            level:1,time:introTime41))
                    carbonis.draw(encoder:encoder,mvp:vp,
                                  model:model,time:introTime41)
                }
            } else {
                let planetModel=Self.translation(center.x,center.y,center.z) *
                    Self.scale(IntroOrbit41.introPlanetScale) *
                    Self.rotateXDegrees(-18) *
                    Self.rotateYDegrees(IntroOrbit41.planetRotationDegrees(
                        level:IntroOrbit41.boreasSourceLevel,
                        time:introTime41))
                // Unmodified level-5 Boreas diagnostic with its real
                // glTF animation and triple-buffered source geometry.
                uploadBoreasMorphIfNeeded(seconds:Double(introTime41))
                let slot=planetBufferSlots.retainCurrent()
                command.addCompletedHandler { [planetBufferSlots] _ in
                    planetBufferSlots.release(slot)
                }
                let mesh=GPUModel(vertices:planetVertexBuffers[slot],
                                  indices:planetIndices,count:planetIndexCount)
                drawMesh(mesh,planetModel)
            }

            // Original IntroScene41.CraftOrientation local axes.
            let a=IntroOrbit41.craftOrientationColumns(introTime41)
            let orientation=simd_float4x4(columns:(
                SIMD4(a[0],a[1],a[2],a[3]),
                SIMD4(a[4],a[5],a[6],a[7]),
                SIMD4(a[8],a[9],a[10],a[11]),
                SIMD4(a[12],a[13],a[14],a[15])
            ))
            let ship=IntroOrbit41.ship(introTime41)*inv
            // Original v568 Vanguard431 model size and Y-up GLB
            // origin were read from actual embedded v4311 mesh +
            // BakeInfo.json. The pre-existing iOS AS3D baked a smaller
            // factor of 0.32 and a different Y centre. Restore the
            // source gameplay model coordinates in LOCAL axes, then
            // apply the exact IntroScene41 fighter orientation.
            // Combat collision scale is independent and NOT changed.
            let craft=Self.translation(ship.x,ship.y,ship.z) *
                orientation * Self.rotateYDegrees(sin(introTime41*0.8)*7) *
                Self.translation(0,0,
                    IntroVanguard431.normalizedDorsalCorrection) *
                Self.scale(IntroVanguard431.normalizedShipModelScale)
            // When source PC vertex packets and the original JPEG
            // are both present, draw true 4311 mesh/UV/skin. Otherwise
            // preserve the VERIFIED v556 approximate-AS3D pipeline.
            if let native=sourceVanguard431 {
                // PC GPU vertex positions already include the original
                // v4311 bake scale and centre, so do NOT apply AS3D
                // scale/translation correction a second time.
                let originalCraft=Self.translation(
                    ship.x,ship.y,ship.z) *
                    orientation * Self.rotateYDegrees(
                        sin(introTime41*0.8)*7) * Self.scale(inv)
                var originalUniform=FighterSourceUniform431(
                    mvp:vp * originalCraft,
                    model:originalCraft,eyeView:cameraFrame.view)
                encoder.setRenderPipelineState(
                    sourceFighterTexturedPipeline431)
                encoder.setVertexBuffer(native.buffer,offset:0,index:0)
                encoder.setVertexBytes(&originalUniform,
                    length:MemoryLayout<FighterSourceUniform431>.stride,
                    index:1)
                encoder.setFragmentTexture(native.skin,index:0)
                encoder.drawPrimitives(
                    type:.triangle,vertexStart:0,vertexCount:native.count)
            } else {
                // The real PC default binds GpuToon60 for this
                // Vanguard material 0. Its directional FighterLight
                // coordinates are EYE-SPACE and remain fixed to the
                // actual IntroScene41 camera, not a made-up world sun.
                encoder.setRenderPipelineState(sourceFighterToonPipeline60)
                var fighterEyeView=cameraFrame.view
                encoder.setFragmentBytes(&fighterEyeView,
                    length:MemoryLayout<simd_float4x4>.stride,index:0)
                drawMesh(shipMesh,craft)
            }
            encoder.setRenderPipelineState(pipeline)

            // GpuIntro41.cs:493 calls DrawFighterMesh(time,1,0,false).
            // GpuShip.cs:19–63: after opaque Vanguard, the original
            // draws additive, unlit three-layer exhaust from the two
            // actual v4311 binary nozzle positions. The procedural
            // shader uses 1728 vertex_id calls, no per-frame CPU mesh.
            // Plasma positions are ALREADY in original PC local units,
            // so unlike the AS3D fighter we only apply world /144.19674.
            let plasmaModel=Self.translation(ship.x,ship.y,ship.z) *
                orientation * Self.rotateYDegrees(sin(introTime41*0.8)*7) *
                Self.scale(inv)
            let engineCenters=IntroEnginePlasma491.engineCenters
            var plasmaUniform=FighterPlasmaUniforms491(
                mvp:vp * plasmaModel,
                engine0:SIMD4<Float>(engineCenters[0].x,
                    engineCenters[0].y,engineCenters[0].z,0),
                engine1:SIMD4<Float>(engineCenters[1].x,
                    engineCenters[1].y,engineCenters[1].z,0),
                frame:SIMD4<Float>(introTime41,1,
                    IntroEnginePlasma491.visualSize,0))
            encoder.setRenderPipelineState(fighterPlasmaPipeline491)
            encoder.setDepthStencilState(atmosphereDepthState)
            encoder.setVertexBytes(&plasmaUniform,
                length:MemoryLayout<FighterPlasmaUniforms491>.stride,index:0)
            encoder.drawPrimitives(type:.triangle,vertexStart:0,
                vertexCount:IntroEnginePlasma491.vertexCount)

            // Original GpuIntro41.cs:494 draws DrawAtmosphere47 AFTER
            // the planet AND fighter. It is a 3D dome facing the true
            // source camera, depth-tested with depth writes disabled.
            // PlanetBiome.ForLevel decides the authentic atmosphere:
            // CARBONIS #EC4E19, diagnostic BOREAS #95DBFF.
            let atmoAxes=IntroAtmosphere47.basis(
                center:IntroOrbit41.planetCenter,
                eye:IntroOrbit41.frame(introTime41).eye)
            let atmoScale=IntroOrbit41.introPlanetScale
            let atmoModel=simd_float4x4(columns:(
                SIMD4<Float>(atmoAxes.x.x*atmoScale,
                             atmoAxes.x.y*atmoScale,
                             atmoAxes.x.z*atmoScale,0),
                SIMD4<Float>(atmoAxes.y.x*atmoScale,
                             atmoAxes.y.y*atmoScale,
                             atmoAxes.y.z*atmoScale,0),
                SIMD4<Float>(atmoAxes.z.x*atmoScale,
                             atmoAxes.z.y*atmoScale,
                             atmoAxes.z.z*atmoScale,0),
                SIMD4<Float>(center.x,center.y,center.z,1)
            ))
            encoder.setRenderPipelineState(atmospherePipeline)
            encoder.setDepthStencilState(atmosphereDepthState)
            drawMesh(missionCarbonis
                     ? carbonisAtmosphereMesh568 : atmosphereMesh,
                     atmoModel,unlit:1)
            encoder.endEncoding()

            // GitHub iOS SIMULATOR ONLY: prove the original textured
            // Vanguard draw was actually submitted and the entire
            // Metal command buffer COMPLETED, not just that JPEG/mesh
            // happened to exist in a compiled .app. No external
            // logging permission or unreliable macOS log database.
            // Normal iPhone/iPad builds leave no diagnostic file.
            if sourceDrawProofRequested && !sourceDrawProofScheduled,
               let original=sourceVanguard431 {
                sourceDrawProofScheduled=true
                let vertexCount=original.count
                let textureWidth=original.skin.width
                let textureHeight=original.skin.height
                command.addCompletedHandler { finished in
                    let passed=finished.status == .completed
                    let payload:[String:Any]=[
                        "evidence":"actual-source-vanguard-metal-command-buffer",
                        "gpuCommandBufferCompleted":passed,
                        "pipeline":"sourceFighterTexturedPipeline431",
                        "vertexCount":vertexCount,
                        "textureWidth":textureWidth,
                        "textureHeight":textureHeight,
                        "meshSHA256":SourceVanguardMesh431.exactMeshSHA256,
                        "skinSHA256":SourceVanguardMesh431.exactBaseJPEG_SHA256,
                        "bundleID":Bundle.main.bundleIdentifier ?? "",
                        "simulatorTestOnly":true
                    ]
                    OriginalRenderProofWriter568.save(
                        payload,
                        filename:"ASTEROIDY_Vanguard431_RenderProof.json")
                }
            }
            command.present(drawable)
            SourcePerformance568.shared.watch(command)
            command.commit()
            return
        }
        if input.planetPreview {
            // Original GpuIntro41.DrawDeepSpace55: 24 distant + 12 near
            // clouds are layered BEFORE stars and the five solar rays.
            // One immutable 216-vertex buffer, one 2-slice 256x256
            // NebulaTexture; camera orientation changes in a uniform.
            let c=sphereFlight.camera
            var nebulaUniform=(
                SIMD4<Float>(c.right.x,c.right.y,c.right.z,0),
                SIMD4<Float>(c.up.x,c.up.y,c.up.z,0),
                SIMD4<Float>(c.focus.x,c.focus.y,c.focus.z,0),
                SIMD4<Float>(2/(720*aspect),-2/720,0,0)
            )
            encoder.setDepthStencilState(skyDepthState)
            let sourceCloudTexture=ensureCloudTextures55(camera:c)
            if let clouds=sourceCloudTexture {
                encoder.setRenderPipelineState(nebulaOverlayPipeline)
                encoder.setVertexBuffer(
                    nebulaOverlayMesh.vertices,offset:0,index:0)
                encoder.setVertexBytes(
                    &nebulaUniform,length:MemoryLayout.size(ofValue:nebulaUniform),
                    index:1)
                encoder.setFragmentTexture(clouds,index:0)
                // C# DrawDeepSpace55: 24 FAR cloud layers first.
                encoder.drawPrimitives(
                    type:.triangle,vertexStart:0,
                    vertexCount:24*6)
            }

            // C# DrawDeepSpace55 and DrawSkyPlanet55:
            // three source planets in style order 0→1→2, each:
            // optional source glow IntroHalo then a 320x220 texture.
            // Reuse the existing premultiplied 2D quad shader from
            // BlackHole55; no new MSL entrypoints or pipeline, no
            // dynamic GPU textures. One draw PER visible source planet
            // preserves draw order with the following black hole.
            for style in 0..<DeepSkyPlanets55.count {
                guard let projected=DeepSkyPlanets55.project(
                    style:style,time:Float(planetAnimationTime),
                    camera:sphereFlight.camera) else { continue }
                // Source GpuIntro41: only build any planet Bitmap
                // AFTER SkyProject55 confirms visibility.
                guard let planets=ensureDeepPlanetTextures55(style:style)
                else { break }
                encoder.setRenderPipelineState(blackHolePipeline)
                encoder.setFragmentTexture(planets,index:0)
                encoder.setFragmentTexture(sphereHaloTexture,index:1)
                let x=(projected.screen.x-640)*2/(720*aspect)
                let y=(360-projected.screen.y)*2/720
                let frame=SIMD4<Float>(x,y,2/(720*aspect),-2/720)
                let layers=DeepSkyPlanets55.overlays(
                    style:style,scale:projected.scale,glow:true)
                let uniforms=SourceSkyUniformPacking.planet(frame:frame,layers:layers)
                uniforms.withUnsafeBytes { raw in
                    if let ptr=raw.baseAddress {
                        encoder.setVertexBytes(
                            ptr,length:raw.count,index:0)
                    }
                }
                encoder.drawPrimitives(type:.triangle,
                    vertexStart:0,vertexCount:layers.count*6)
            }

            // C# DrawDeepSpace55: the black hole is behind the NEAR
            // cloud layers and in front of FAR clouds. 3 source
            // StarTexture halos, 4 moving rays, then rear disk/core/
            // front disk in the exact original 2D painter order.
            if let blackProjection=BlackHoleSky55.project(
                camera:sphereFlight.camera,time:Float(planetAnimationTime)),
                let blackTextures=ensureBlackHoleTextures55() {
                let bx=(blackProjection.screen.x-640)*2/(720*aspect)
                let by=(360-blackProjection.screen.y)*2/720
                let screen=SIMD4<Float>(bx,by,2/(720*aspect),-2/720)
                let layers=BlackHoleSky55.overlays(
                    time:Float(planetAnimationTime),
                    scale:blackProjection.scale,glow:true)
                let properties=SourceSkyUniformPacking.blackHole(screen:screen,layers:layers)
                encoder.setRenderPipelineState(blackHolePipeline)
                properties.withUnsafeBytes { raw in
                    if let ptr=raw.baseAddress {
                        encoder.setVertexBytes(
                            ptr,length:raw.count,index:0)
                    }
                }
                encoder.setFragmentTexture(blackTextures,index:0)
                encoder.setFragmentTexture(sphereHaloTexture,index:1)
                encoder.drawPrimitives(type:.triangle,vertexStart:0,
                    vertexCount:layers.count*6)
            }
            // C# IntroSky: 12 NEAR clouds come AFTER all background
            // space objects. Reuse the SAME immutable buffer and
            // two-texture-array; no new geometry or texture uploads.
            if let clouds=sourceCloudTexture {
                encoder.setRenderPipelineState(nebulaOverlayPipeline)
                encoder.setVertexBuffer(
                    nebulaOverlayMesh.vertices,offset:0,index:0)
                encoder.setVertexBytes(
                    &nebulaUniform,length:MemoryLayout.size(ofValue:nebulaUniform),
                    index:1)
                encoder.setFragmentTexture(clouds,index:0)
                encoder.drawPrimitives(type:.triangle,
                    vertexStart:24*6,vertexCount:12*6)
            }
            // Source GpuIntro41.IntroSky uses a sky centred on the eye.
            // Render 1500 alpha-blended screen-size points in one GPU call;
            // none writes depth or changes the scene PBR pipeline.
            let skyEye=cameraFrame.eye
            let skyMVP=vp*Self.translation(skyEye.x,skyEye.y,skyEye.z)
            var skyUniform=SceneUniforms(
                mvp:skyMVP,model:matrix_identity_float4x4,
                lighting:SIMD4<Float>(SphereSky207.drawableScale(
                    height:Float(view.drawableSize.height)),0,0,0))
            encoder.setRenderPipelineState(skyPointPipeline)
            encoder.setDepthStencilState(skyDepthState)
            encoder.setFragmentTexture(sphereHaloTexture,index:0)
            encoder.setVertexBuffer(sphereSkyMesh.vertices,offset:0,index:0)
            encoder.setVertexBytes(
                &skyUniform,length:MemoryLayout<SceneUniforms>.stride,index:1)
            encoder.drawPrimitives(
                type:.point,vertexStart:0,vertexCount:sphereSkyMesh.count)
            // GpuIntro41.cs:454: only draw solar effects when the source
            // 900-unit sky direction is in the original extended screen
            // bounds. SkyProject55 uses the camera rotation, NOT its eye.
            if let sun=SphereSolarOverlay556.project(
                camera:sphereFlight.camera) {
                let ndcX=(sun.x-640)*2/(720*aspect)
                let ndcY=(360-sun.y)*2/720
                var solarUniform=SIMD4<Float>(
                    ndcX,ndcY,2/(720*aspect),-2/720)
                encoder.setRenderPipelineState(solarOverlayPipeline)
                encoder.setVertexBuffer(
                    solarOverlayMesh.vertices,offset:0,index:0)
                encoder.setVertexBytes(
                    &solarUniform,
                    length:MemoryLayout<SIMD4<Float>>.stride,index:1)
                encoder.setFragmentTexture(sphereHaloTexture,index:0)
                encoder.drawPrimitives(
                    type:.triangle,vertexStart:0,
                    vertexCount:solarOverlayMesh.count)
            }
            encoder.setDepthStencilState(depthState)
            encoder.setRenderPipelineState(pipeline)
            // Triple-buffered morph uploads. Never write into a buffer referenced by
            // an outstanding GPU command, and never allocate a new MTLBuffer per morph.
            // Same source-mesh morph update and ring buffering as before,
            // now also shared with the original cinematic clock.
            uploadBoreasMorphIfNeeded(seconds:planetAnimationTime)
            let slot = planetBufferSlots.retainCurrent()
            command.addCompletedHandler { [planetBufferSlots, telemetry] finished in
                planetBufferSlots.release(slot)
                let begin = finished.gpuStartTime
                let end = finished.gpuEndTime
                if begin > 0 && end >= begin {
                    telemetry.record(.gpuExecution, seconds: end - begin)
                }
            }
            let activeMesh = GPUModel(vertices: planetVertexBuffers[slot], indices:planetIndices, count:planetIndexCount)
            // Boreas GLB from v556, converted with all node transforms.
            // Spherical flight collision is still a diagnostic approximation.
            drawMesh(activeMesh, Self.scale(1.0))
            // Geodesic asteroid positions on the visible Boreas mesh.
            // Radius is translated from the original H/pi spherical atlas.
            for asteroid in (combatSession05?.game.rocks ?? sphereSector.asteroids) {
                // Windows GpuSphere67.RockSphere67: StampSphere67
                // followed by rock.Angle*41 X and rock.Angle*23 Y.
                // Level 25 uses Amiga263's unrotated stamp + radial hop.
                let demo=sphereSector.isAmigaDemo
                let stamp=Self.sphereStamp(
                    asteroid.position,angle:asteroid.angle,
                    size:asteroid.radius,
                    lift:demo ? asteroid.bounceHeight : 0)
                let model=demo ? stamp :
                    stamp * Self.rotateXDegrees(asteroid.angle*41) *
                            Self.rotateYDegrees(asteroid.angle*23)
                drawMesh(asteroidMesh,model)
            }
            if let live=combatSession05 {
                // Original source enemy meshes + identical contact positions
                // and orientations from the actual active shooter AI.
                for enemy in live.game.shooters {
                    guard let mesh=sourceShooterModels05[enemy.core.type]
                    else { continue }
                    let pose=Self.sphereStamp(enemy.core.position,
                        angle:enemy.aim,
                        size:9*sourceMissionScale05.enemyFactor)
                    drawMesh(mesh,pose)
                }
                for shot in live.game.bullets {
                    let p=PlanetPreview556.shipSurfacePosition(
                        shot.point,altitude:0.12)
                    drawMesh(bulletMesh,Self.translation(p.x,p.y,p.z)*
                             Self.scale(0.014),unlit:1)
                }
                for shot in live.game.hostileShots {
                    let p=PlanetPreview556.shipSurfacePosition(
                        shot.point,altitude:0.12)
                    drawMesh(bulletMesh,Self.translation(p.x,p.y,p.z)*
                             Self.scale(0.014),unlit:1)
                }
            } else {
                for bolt in sphereSector.bolts {
                    let position=PlanetPreview556.shipSurfacePosition(
                        bolt.position,altitude:0.12)
                    drawMesh(bulletMesh,
                        Self.translation(position.x,position.y,position.z)*
                        Self.scale(0.014),unlit:1)
                }
            }
            // GpuSphere67.CraftSphere67: real sphere tangent basis,
            // source world ShipContactRadius*Scale67*.65 and visual
            // bank/pitch in DEGREES. The source Vanguard GLB exporter
            // already projects the GLB onto local XY with Z up.
            let craft=Self.sphereStamp(
                sphereFlight.position,
                angle:sphereFlight.flight.visualHeading,
                size:SphereSurfaceStamp556.sourceCraftRadius)
            let shipScaleRevision=UserDefaults.standard.integer(
                forKey:SourceShipScale472.revisionKey)
            if shipScaleRevision != shipScaleRevision472 {
                shipScale472=SourceShipScale472.load()
                shipScaleRevision472=shipScaleRevision
            }
            let shipModel=craft *
                Self.rotateYDegrees(sphereFlight.flight.visualBank) *
                Self.rotateXDegrees(sphereFlight.flight.visualPitch) *
                Self.scale(shipScale472.missionFactor)
            if let original=combatCraft05 {
                var uniforms=FighterSourceUniform431(
                    mvp:vp*shipModel,model:shipModel,eyeView:cameraFrame.view)
                encoder.setRenderPipelineState(sourceFighterTexturedPipeline431)
                encoder.setVertexBuffer(original.buffer,offset:0,index:0)
                encoder.setVertexBytes(&uniforms,
                    length:MemoryLayout<FighterSourceUniform431>.stride,
                    index:1)
                encoder.setFragmentTexture(original.skin,index:0)
                encoder.drawPrimitives(type:.triangle,vertexStart:0,
                                       vertexCount:original.count)
                encoder.setRenderPipelineState(pipeline)
            } else if input.sourceShip367Preview {
                // Original Windows/src/GpuSphere67.cs CraftSphere67 uses the
                // same tangent basis and ShipContactRadius * Scale67 * .65.
                // PlayerShip363 has already applied StandardSize369=.714
                // to XYZ; never scale vertices a second time.
                if let native=verifiedPlayerShip367() {
                    var uniforms=FighterSourceUniform431(
                        mvp:vp*shipModel,model:shipModel,
                        eyeView:cameraFrame.view)
                    encoder.setRenderPipelineState(
                        sourceFighterTexturedPipeline431)
                    encoder.setVertexBuffer(native.buffer,offset:0,index:0)
                    encoder.setVertexBytes(&uniforms,
                        length:MemoryLayout<FighterSourceUniform431>.stride,
                        index:1)
                    encoder.setFragmentTexture(native.skin,index:0)
                    encoder.drawPrimitives(type:.triangle,vertexStart:0,
                        vertexCount:native.count)
                    // Simulator-only evidence from the same command buffer
                    // as the *actual* original v568 PlayerShip367 draw.
                    // This does not claim pixel parity or visible model size.
                    if sourceShip367DrawProofRequested &&
                       !sourceShip367DrawProofScheduled {
                        sourceShip367DrawProofScheduled=true
                        let count=native.count
                        let width=native.skin.width
                        let height=native.skin.height
                        command.addCompletedHandler { finished in
                            let payload:[String:Any]=[
                                "evidence":"actual-source-playership367-metal-command-buffer",
                                "gpuCommandBufferCompleted":finished.status == .completed,
                                "pipeline":"sourceFighterTexturedPipeline431",
                                "vertexCount":count,
                                "textureWidth":width,
                                "textureHeight":height,
                                "sourceGPU_SHA256":SourcePlayerShip367.expectedGPU_SHA256,
                                "skinSHA256":SourcePlayerShip367.expectedTexture_SHA256,
                                "bundleID":Bundle.main.bundleIdentifier ?? "",
                                "simulatorTestOnly":true
                            ]
                            OriginalRenderProofWriter568.save(
                                payload,
                                filename:"ASTEROIDY_PlayerShip367_RenderProof.json")
                        }
                    }
                    encoder.setRenderPipelineState(pipeline)
                }
            } else {
                drawMesh(shipMesh,shipModel)
            }
            encoder.endEncoding()
            command.present(drawable)
            SourcePerformance568.shared.watch(command)
            command.commit()
            if ProcessInfo.processInfo.environment["ASTEROIDY_IOS_PROFILE"] == "1",
               now - lastTelemetryLog > 5.0 {
                lastTelemetryLog = now
                NSLog("ASTEROIDY iOS diagnostic: %@", telemetry.report())
            }
            return
        }
        drawMesh(starMesh, matrix_identity_float4x4, unlit: 1)
        for rock in game.rocks {
            drawMesh(asteroidMesh,Self.translation(rock.at.x,rock.at.y,-0.1) * Self.rotated(rock.phase + game.time*0.2) * Self.scale(rock.radius))
        }
        for bolt in game.bolts {
            drawMesh(bulletMesh,Self.translation(bolt.at.x,bolt.at.y,0.08) * Self.scale(0.013), unlit: 1)
        }
        drawMesh(shipMesh,Self.translation(game.ship.x,game.ship.y,0.18) * Self.rotated(-game.flight.visualHeading))
        encoder.endEncoding()
        command.present(drawable)
        command.commit()
    }
}
