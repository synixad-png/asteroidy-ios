import Foundation
import MetalKit
import simd
import QuartzCore

private struct GPUModel {
    let vertices: MTLBuffer
    let indices: MTLBuffer
    let count: Int
}

// Perspective renderer. This intentionally reuses the independent v2 gameplay
// while the real C# v556 simulation and PBR shaders remain to be ported.
final class MetalRenderer: NSObject, MTKViewDelegate {
    let input: FlightInput
    let device: MTLDevice
    let queue: MTLCommandQueue
    let pipeline: MTLRenderPipelineState
    let depthState: MTLDepthStencilState
    let skyPointPipeline: MTLRenderPipelineState
    let solarOverlayPipeline: MTLRenderPipelineState
    let nebulaOverlayPipeline: MTLRenderPipelineState
    let blackHolePipeline: MTLRenderPipelineState
    let skyDepthState: MTLDepthStencilState
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
    private var planetMorphScratch: [AssetMesh.Vertex]
    private var planetAnimationTime: Double = 0
    private var lastPlanetMorphUpload: Double = -1
    private let telemetry = RenderTelemetry()
    private var lastTelemetryLog: Double = 0
    // Original IntroScene41 cinematic; not a mission or campaign unlock.
    private var introTime41: Float = 0
    private var wasIntroPreview41 = false
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

    init(device: MTLDevice, input: FlightInput) throws {
        self.device = device
        self.input = input
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
        // Source GpuIntro41 stars use RGBA and pixel dimensions. Keep a
        // dedicated blended POINT pipeline, independent of the existing
        // opaque PBR and flat training arena pipelines.
        let skyDescriptor=MTLRenderPipelineDescriptor()
        skyDescriptor.vertexFunction=skyVertex
        skyDescriptor.fragmentFunction=skyFragment
        skyDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        skyDescriptor.depthAttachmentPixelFormat = .depth32Float
        let blend=skyDescriptor.colorAttachments[0]!
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
        solarDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        solarDescriptor.depthAttachmentPixelFormat = .depth32Float
        let solarBlend=solarDescriptor.colorAttachments[0]!
        solarBlend.isBlendingEnabled=true
        solarBlend.sourceRGBBlendFactor = .one
        solarBlend.destinationRGBBlendFactor = .oneMinusSourceAlpha
        solarBlend.sourceAlphaBlendFactor = .one
        solarBlend.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        solarOverlayPipeline=try device.makeRenderPipelineState(
            descriptor:solarDescriptor)
        let nebulaDescriptor=MTLRenderPipelineDescriptor()
        nebulaDescriptor.vertexFunction=nebulaVertex
        nebulaDescriptor.fragmentFunction=nebulaFragment
        nebulaDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        nebulaDescriptor.depthAttachmentPixelFormat = .depth32Float
        let nebulaBlend=nebulaDescriptor.colorAttachments[0]!
        nebulaBlend.isBlendingEnabled=true
        nebulaBlend.sourceRGBBlendFactor = .one
        nebulaBlend.destinationRGBBlendFactor = .oneMinusSourceAlpha
        nebulaBlend.sourceAlphaBlendFactor = .one
        nebulaBlend.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        nebulaOverlayPipeline=try device.makeRenderPipelineState(
            descriptor:nebulaDescriptor)
        // Source GpuIntro41 DrawSkyBlackHole55 uses the same
        // premultiplied Blend(ONE,ONE_MINUS_SRC_ALPHA) as IntroSky.
        let blackDesc=MTLRenderPipelineDescriptor()
        blackDesc.vertexFunction=blackHoleVertex
        blackDesc.fragmentFunction=blackHoleFragment
        blackDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        blackDesc.depthAttachmentPixelFormat = .depth32Float
        let blackBlend=blackDesc.colorAttachments[0]!
        blackBlend.isBlendingEnabled = true
        blackBlend.sourceRGBBlendFactor = .one
        blackBlend.destinationRGBBlendFactor = .oneMinusSourceAlpha
        blackBlend.sourceAlphaBlendFactor = .one
        blackBlend.destinationAlphaBlendFactor = .oneMinusSourceAlpha
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
        guard let url = Bundle.main.url(forResource:"Vanguard556",withExtension:"as3d")
            ?? Bundle.main.url(forResource:"Vanguard556",withExtension:"as3d",subdirectory:"Assets") else {
            throw NSError(domain:"ASTEROIDY iOS",code:3,userInfo:[NSLocalizedDescriptionKey:"Brak autentycznego modelu Vanguard556.as3d w aplikacji"])
        }
        let asset = try AssetMesh(data: Data(contentsOf:url))
        shipMesh = try Self.makeMesh(device, asset.vertices, asset.indices)
        asteroidMesh = try Self.makeMesh(device, Self.asteroidVertices(), Self.octahedronIndices())
        bulletMesh = try Self.makeMesh(device, Self.bulletVertices(), Self.octahedronIndices())
        let starData = Self.stars()
        starMesh = try Self.makeMesh(device, starData.0, starData.1)
        let sphereSkyData=Self.sphereSky207()
        sphereSkyMesh=try Self.makeMesh(device,sphereSkyData.0,sphereSkyData.1)
        sphereHaloTexture=try Self.makeSphereHaloTexture(device)
        let overlayData=Self.solarOverlaySource556()
        solarOverlayMesh=try Self.makeMesh(device,overlayData.0,overlayData.1)
        let cloudData=Self.nebulaSource556()
        nebulaOverlayMesh=try Self.makeMesh(device,cloudData.0,cloudData.1)
        // Source GpuIntro41.cs generates large sky Bitmaps only after
        // their first visible SkyProject55. Do not eagerly allocate
        // 5.76MB of mostly unseen textures in the flat training arena.
        // MTLTexture resources are loaded on their first visible use.
        // Only use the verified v556 Boreas GLB conversion when bundled.
        // Never silently claim that the diagnostic UV sphere is an imported asset.
        guard let planetURL = Bundle.main.url(forResource:"Boreas556",withExtension:"as3d")
             ?? Bundle.main.url(forResource:"Boreas556",withExtension:"as3d",subdirectory:"Assets") else {
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
        guard let animURL = Bundle.main.url(forResource:"Boreas556",withExtension:"asmo")
             ?? Bundle.main.url(forResource:"Boreas556",withExtension:"asmo",subdirectory:"Assets"),
              let bindingURL = Bundle.main.url(forResource:"BoreasMorphBinding556",withExtension:"json")
             ?? Bundle.main.url(forResource:"BoreasMorphBinding556",withExtension:"json",subdirectory:"Assets") else {
            throw NSError(domain:"ASTEROIDY iOS",code:6,userInfo:[NSLocalizedDescriptionKey:"Brak danych animacji lub wiązania Boreas"])
        }
        planetAnimator = try BoreasMorphRenderer556(source:BoreasMorph556(data:Data(contentsOf:animURL)),
                                                    bindingData:Data(contentsOf:bindingURL), mesh:planet)
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
    private static func makeSphereHaloTexture(_ device: MTLDevice)
        throws -> MTLTexture {
        let n=SphereSky207.haloTextureSize
        let descriptor=MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat:.bgra8Unorm,width:n,height:n,mipmapped:false)
        descriptor.usage=[.shaderRead]
        descriptor.storageMode = .shared
        guard let texture=device.makeTexture(descriptor:descriptor) else {
            throw NSError(domain:"ASTEROIDY iOS Metal",code:12,
                          userInfo:[NSLocalizedDescriptionKey:
                            "Nie można utworzyć oryginalnej StarTexture 64x64"])
        }
        let texels=SphereSky207.haloTexelsBGRA()
        texels.withUnsafeBytes { raw in
            if let p=raw.baseAddress {
                texture.replace(region:MTLRegionMake2D(0,0,n,n),
                                mipmapLevel:0,withBytes:p,bytesPerRow:n*4)
            }
        }
        return texture
    }

    /// Original GpuIntro41.IntroSky draws the *bright* halo FIRST, then
    /// IntroHalo(p,size*2) for every visible source star. Each sprite
    /// uses the exact 64x64 mask and premultiplied source alpha.
    /// A single static point buffer avoids 1500 separate draws.
    private static func sphereSky207() -> ([AssetMesh.Vertex],[UInt32]) {
        var vertices:[AssetMesh.Vertex]=[]
        var indices:[UInt32]=[]
        vertices.reserveCapacity(SphereSky207.count*2)
        indices.reserveCapacity(SphereSky207.count*2)
        let radius=SphereSky207.normalizedSkyRadius
        for i in 0..<SphereSky207.count {
            let star=SphereSky207.star(i)
            let point=SIMD3<Float>(
                star.direction.x,star.direction.y,star.direction.z)*radius
            func appendHalo(_ diameter:Float,_ alpha:Float) {
                let base=UInt32(vertices.count)
                vertices.append(AssetMesh.Vertex(
                    position:SIMD4(point.x,point.y,point.z,1),
                    color:SIMD4(star.red,star.green,star.blue,alpha),
                    normal:SIMD4(0,0,1,0),
                    material:SIMD4<Float>(diameter,0,0,0)))
                indices.append(base)
            }
            // Renderer.GlowEnabled defaults to true in original
            // Windows/src/Renderer.cs:25. Glow UI option is not ported.
            if SphereSky207.hasBrightHalo(star) {
                appendHalo(SphereSky207.brightHaloDiameterPixels(star),
                           125/255)
            }
            appendHalo(SphereSky207.baseDiameterPixels(star),
                       star.alpha)
        }
        return (vertices,indices)
    }

    /// GpuCosmos39.SoftRay: 720 static ray-triangle vertices. GpuIntro41
    /// solar 3 textured halos: 18 vertices. All share ONE immutable 64x64
    /// original StarTexture and ONE GPU draw; projection changes via a
    /// 16-byte centerScale uniform, never by rewriting this buffer.
    private static func solarOverlaySource556()
        -> ([AssetMesh.Vertex],[UInt32]) {
        let source=SphereSolarOverlay556.vertices()
        var vertices:[AssetMesh.Vertex]=[]
        vertices.reserveCapacity(source.count)
        for v in source {
            let (r,g,b,a)=v.rgba
            vertices.append(AssetMesh.Vertex(
                position:SIMD4(v.offset.x,v.offset.y,0,1),
                color:SIMD4(r,g,b,a),
                normal:SIMD4(v.uv.x,v.uv.y,0,0),
                material:SIMD4<Float>(v.textured ? 1:0,1,0,0)))
        }
        return (vertices,(0..<source.count).map {UInt32($0)})
    }

    /// The original GpuCosmos39.CloudLayer and GpuIntro41.DrawSkyPlanet55/
    /// DrawSkyBlackHole55 allocate their images only on first visible use.
    /// All three texture arrays remain cached within this renderer for
    /// the rest of the session, regardless of flat/sphere toggling.
    /// Errors log once, and gameplay continues without that sky layer.
    private static let sourceCloudLayers55: [SphereNebula556.Layer] =
        (0..<SphereNebula556.orbitLayerCount).map {SphereNebula556.layer($0)}

    private func ensureCloudTextures55(camera: SphereCamera67) -> MTLTexture? {
        // Both original GpuCosmos39.NebulaTexture themes are cached now:
        // preserve the current GPU texture array, and let its existing
        // vertex shader project all 36 layers per current camera frame.
        // Recomputing 36 Swift projections + a Set here every frame
        // cannot change which texture is sampled once both exist.
        if let cached=nebulaTexture, nebulaSliceCache55.allUploaded {
            return cached
        }
        // GpuCosmos39.CloudLayer caches each NebulaTexture(theme) on its
        // own first visible use. The original sphere preview only uses
        // themes 0 and 1 across the fixed 24+12 source cloud layers.
        // A 36-direction cache avoids recomputing source sin/cos offsets.
        let visibleThemes=Set(Self.sourceCloudLayers55.compactMap { layer -> Int? in
            layer.projected(camera:camera) != nil ? layer.theme : nil
        })
        let texture: MTLTexture
        if let current=nebulaTexture {
            texture=current
        } else {
            guard nebulaLoadGate.shouldAllocate(visible:!visibleThemes.isEmpty)
            else { return nil }
            do {
                let created=try Self.makeNebulaTextures556(device)
                nebulaTexture=created
                texture=created
            } catch {
                NSLog("ASTEROIDY iOS: źródłowe NebulaTexture: %@", String(describing:error))
                return nil
            }
        }
        // Only the texture themes that actually project into this
        // camera are generated/uploaded. The second theme may appear
        // later; unseen slices are never sampled by the shader.
        for theme in 0..<SphereNebula556.orbitThemeCount
            where visibleThemes.contains(theme) &&
                  nebulaSliceCache55.needsUpload(style:theme) {
            guard Self.uploadNebulaSlice556(texture,theme:theme) else {
                return nil
            }
            nebulaSliceCache55.markUploaded(style:theme)
        }
        return texture
    }

    private func ensureDeepPlanetTextures55(style: Int) -> MTLTexture? {
        guard (0..<DeepSkyPlanets55.count).contains(style) else { return nil }
        // The original GpuIntro41.DrawSkyPlanet55 builds each style's
        // Bitmap only AFTER its own SkyProject55 visibility check.
        // Share one GPU array but generate/upload CPU pixels one slice
        // at a time, never for off-screen planet styles.
        let texture: MTLTexture
        if let current=deepPlanetTextures {
            texture=current
        } else {
            guard deepPlanetLoadGate.shouldAllocate(visible: true)
            else { return nil }
            do {
                let created=try Self.makeDeepPlanetTextures55(device)
                deepPlanetTextures=created
                texture=created
            } catch {
                NSLog("ASTEROIDY iOS: źródłowe planety 320px: %@", String(describing:error))
                return nil
            }
        }
        if deepPlanetSliceCache55.needsUpload(style:style) {
            guard Self.uploadDeepPlanetSlice55(texture,style:style) else {
                return nil
            }
            deepPlanetSliceCache55.markUploaded(style:style)
        }
        return texture
    }

    private func ensureBlackHoleTextures55() -> MTLTexture? {
        if let current=blackHoleTextures { return current }
        guard blackHoleLoadGate.shouldAllocate(visible: true) else { return nil }
        do {
            let created=try Self.makeBlackHoleTextures55(device)
            blackHoleTextures=created
            return created
        } catch {
            NSLog("ASTEROIDY iOS: źródłowa czarna dziura 640px: %@", String(describing:error))
            return nil
        }
    }

    /// Two immutable original GpuCosmos39 PArgb NebulaTexture themes
    /// used by GpuIntro41.IntroSky. Share one 2-slice texture array across
    /// all 36 distant/near cloud layers, allocated exactly once. Each
    /// 256px CPU bitmap is generated only when its theme is visible.
    private static func makeNebulaTextures556(_ device:MTLDevice)
        throws -> MTLTexture {
        let n=SphereNebula556.imageSize
        let d=MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat:.bgra8Unorm,width:n,height:n,mipmapped:false)
        d.textureType = .type2DArray
        d.arrayLength = SphereNebula556.orbitThemeCount
        d.storageMode = .shared
        d.usage=[.shaderRead]
        guard let texture=device.makeTexture(descriptor:d) else {
            throw NSError(domain:"ASTEROIDY iOS Metal",code:13,
                 userInfo:[NSLocalizedDescriptionKey:
                    "Nie można utworzyć źródłowych NebulaTexture 256x256"])
        }
        return texture
    }

    private static func uploadNebulaSlice556(_ texture:MTLTexture,
                                             theme:Int) -> Bool {
        let n=SphereNebula556.imageSize
        let texels=SphereNebula556.textureBGRA(theme:theme)
        guard texels.count == n*n*4 else {
            NSLog("ASTEROIDY iOS: nieprawidłowa tekstura mgławicy %ld", theme)
            return false
        }
        texels.withUnsafeBytes { raw in
            if let p=raw.baseAddress {
                texture.replace(region:MTLRegionMake2D(0,0,n,n),
                                mipmapLevel:0,slice:theme,withBytes:p,
                                bytesPerRow:n*4,bytesPerImage:n*n*4)
            }
        }
        return true
    }

    /// Original DrawDeepSpace55 emits 24 distant clouds, IntroSky adds
    /// 12 near layers. A static 216-vertex stream stores the exact
    /// source 3D sky directions, UV, alpha, theme and layer type; the
    /// original SkyProject55 is evaluated in the GPU vertex stage with
    /// the LIVE camera, without rebuilding the geometry every frame.
    private static func nebulaSource556()
        -> ([AssetMesh.Vertex],[UInt32]) {
        let uv:[SIMD2<Float>]=[
            SIMD2(0,0),SIMD2(1,0),SIMD2(1,1),
            SIMD2(0,0),SIMD2(1,1),SIMD2(0,1)
        ]
        var vertices:[AssetMesh.Vertex]=[]
        vertices.reserveCapacity(SphereNebula556.orbitLayerCount*6)
        var indices:[UInt32]=[]
        indices.reserveCapacity(SphereNebula556.orbitLayerCount*6)
        for i in 0..<SphereNebula556.orbitLayerCount {
            let layer=SphereNebula556.layer(i)
            for u in uv {
                vertices.append(AssetMesh.Vertex(
                    position:SIMD4(layer.direction.x,layer.direction.y,
                                   layer.direction.z,1),
                    color:SIMD4(1,1,1,layer.alpha),
                    normal:SIMD4(u.x,u.y,0,0),
                    material:SIMD4<Float>(
                        layer.near ? 1:0,Float(layer.theme),0,0)))
                indices.append(UInt32(indices.count))
            }
        }
        return (vertices,indices)
    }

    /// Original BuildBlackHoleDisk55(false), BuildBlackHoleCore55(),
    /// BuildBlackHoleDisk55(true) from actual v556 GpuIntro41.cs. One
    /// three-slice GPU texture shared by all 3 black-hole image passes.
    /// Source GpuRenderer.Texture(Bitmap) uploads Format32bppPArgb.
    /// Never flatten the original rear/core/front ordering.
    private static func makeBlackHoleTextures55(_ device:MTLDevice)
        throws -> MTLTexture {
        let n=BlackHoleSky55.imageSize
        let desc=MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat:.bgra8Unorm,width:n,height:n,mipmapped:false)
        desc.textureType = .type2DArray
        desc.arrayLength = 3
        desc.storageMode = .shared
        desc.usage=[.shaderRead]
        guard let tex=device.makeTexture(descriptor:desc) else {
            throw NSError(domain:"ASTEROIDY iOS Metal",code:14,
                          userInfo:[NSLocalizedDescriptionKey:
                           "Nie można utworzyć trzech źródłowych warstw czarnej dziury 640px"])
        }
        for slice in 0..<3 {
            let image=BlackHoleSky55.textureBGRA(slice:slice)
            image.withUnsafeBytes { bytes in
                if let p=bytes.baseAddress {
                    tex.replace(region:MTLRegionMake2D(0,0,n,n),
                                mipmapLevel:0,slice:slice,
                                withBytes:p,bytesPerRow:n*4,
                                bytesPerImage:n*n*4)
                }
            }
        }
        return tex
    }

    /// Real GpuIntro41.BuildDeepPlanet55(0/1/2): all images are
    /// 320x220 Format32bppPArgb. Allocate only ONCE in a single GPU
    /// array. The array is allocated once at first visible planet; each
    /// actual CPU image/slice is uploaded only when THAT style is visible.
    /// Reuse BlackHole55's generic premultiplied 2D shader: texture slice
    /// -1 uses the original shared StarTexture halo.
    private static func makeDeepPlanetTextures55(_ device:MTLDevice)
        throws -> MTLTexture {
        let w=DeepSkyPlanets55.textureWidth
        let h=DeepSkyPlanets55.textureHeight
        let d=MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat:.bgra8Unorm,width:w,height:h,mipmapped:false)
        d.textureType = .type2DArray
        d.arrayLength = DeepSkyPlanets55.count
        d.storageMode = .shared
        d.usage=[.shaderRead]
        guard let tex=device.makeTexture(descriptor:d) else {
            throw NSError(domain:"ASTEROIDY iOS Metal",code:15,
                userInfo:[NSLocalizedDescriptionKey:
                    "Nie można utworzyć trzech źródłowych planet 320x220"])
        }
        // Deliberately leave unseen slices uninitialized; the renderer
        // never samples a planet until uploadDeepPlanetSlice55 succeeds.
        return tex
    }

    private static func uploadDeepPlanetSlice55(_ tex:MTLTexture,
                                                style:Int) -> Bool {
        let w=DeepSkyPlanets55.textureWidth
        let h=DeepSkyPlanets55.textureHeight
        let img=DeepSkyPlanets55.textureBGRA(style:style)
        guard img.count == w*h*4 else {
            NSLog("ASTEROIDY iOS: nieprawidłowy rozmiar tekstury planety %ld", style)
            return false
        }
        img.withUnsafeBytes { raw in
            if let ptr=raw.baseAddress {
                tex.replace(region:MTLRegionMake2D(0,0,w,h),
                            mipmapLevel:0,slice:style,
                            withBytes:ptr,bytesPerRow:w*4,
                            bytesPerImage:w*h*4)
            }
        }
        return true
    }

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
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        // 120 Hz fixed-step simulation decoupled from 60/120 Hz display refresh.
        // A bounded catch-up prevents an unbounded simulation spiral after resume.
        let elapsed = min(0.25, max(0, now - lastTime))
        lastTime = now
        if input.introPreview41 && !wasIntroPreview41 {introTime41=0}
        wasIntroPreview41=input.introPreview41
        if input.introPreview41 {
            // The unfinished port replays, rather than invents an
            // unsupported transition into a supposedly complete mission.
            introTime41=(introTime41+Float(elapsed))
                .truncatingRemainder(dividingBy:IntroOrbit41.duration)
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
        // Gameplay65 waves 9/17 and AmigaOnly266 level 25.
        // Do not claim campaign progress or reset unrelated flat GameCore.
        let selected=input.planetTestLevel
        if selected != activePlanetTestLevel &&
           [1,9,17,25].contains(selected),
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
        if now-lastHUDTime > 0.14 {
            lastHUDTime = now
            let score = input.planetPreview ? sphereSector.score : game.score
            let hull = input.planetPreview
                ? (input.verifiedDamageLab ? damageLab.lives : sphereSector.hull)
                : game.hull
            let gameOver = input.planetPreview && input.verifiedDamageLab && damageLab.gameOver
            let deaths = damageLab.deathCount
            let armor = damageLab.armor
            let health = damageLab.hull
            let domeEnergy = damageLab.tarczaEnergy
            let domeActive = damageLab.tarczaActive
            let rockCount = input.planetPreview ? sphereSector.asteroids.count : game.rocks.count
            let sectorCleared = sphereSector.sectorCleared
            let objectiveWave = sphereSector.objectiveWave
            let incomingNotice = sphereSector.arrivalNoticeRemaining > 0
            let amigaDemo=sphereSector.isAmigaDemo
            let amigaHits=sphereSector.amigaHits
            DispatchQueue.main.async { [weak input] in
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
                var uniforms:[SIMD4<Float>]=[frame]
                uniforms.reserveCapacity(1+layers.count*3)
                for layer in layers {
                    uniforms.append(SIMD4(
                        layer.radiusX,layer.radiusY,1,0))
                    let (r,g,b,a)=layer.rgba
                    uniforms.append(SIMD4(r*a,g*a,b*a,a))
                    uniforms.append(SIMD4(
                        Float(layer.textureSlice),0,0,0))
                }
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
                var properties:[SIMD4<Float>]=[screen]
                properties.reserveCapacity(1+layers.count*3)
                for layer in layers {
                    properties.append(SIMD4(
                        layer.radiusX,layer.radiusY,
                        cos(layer.angle),sin(layer.angle)))
                    let (r,g,b,a)=layer.rgba
                    properties.append(SIMD4(r*a,g*a,b*a,a))
                    properties.append(SIMD4(
                        layer.isTexture ? Float(layer.layer) : -1,
                        0,0,0))
                }
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
            if lastPlanetMorphUpload < 0 || planetAnimationTime - lastPlanetMorphUpload >= 1.0/30.0 {
                if let slot = planetBufferSlots.reserveWrite() {
                    let morphStarted = ProcessInfo.processInfo.systemUptime
                    planetAnimator.updateVertices(seconds: planetAnimationTime, into: &planetMorphScratch)
                    telemetry.record(.morphCPU, seconds: ProcessInfo.processInfo.systemUptime - morphStarted)
                    let range = planetAnimator.dynamicVertexRange
                    let strideBytes = MemoryLayout<AssetMesh.Vertex>.stride
                    let startByte = range.lowerBound * strideBytes
                    let dynamicBytes = range.count * strideBytes
                    let target = planetVertexBuffers[slot]
                    if startByte <= target.length && dynamicBytes <= target.length - startByte {
                        // Every ring buffer already contains identical immutable vertices.
                        // Upload only the morphed tail; do not copy the 4,320 static vertices.
                        let copyStarted = ProcessInfo.processInfo.systemUptime
                        planetMorphScratch.withUnsafeBytes { bytes in
                            if let p = bytes.baseAddress {
                                memcpy(target.contents().advanced(by:startByte), p.advanced(by:startByte), dynamicBytes)
                            }
                        }
                        telemetry.record(.uploadCPU, seconds: ProcessInfo.processInfo.systemUptime - copyStarted)
                        telemetry.noteUpload(success: true)
                        planetBufferSlots.publish(slot)
                        lastPlanetMorphUpload = planetAnimationTime
                    } else {
                        telemetry.noteUpload(success: false)
                        planetBufferSlots.cancelWrite(slot)
                    }
                } else {
                    telemetry.noteUpload(success: false)
                }
            }
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
            for asteroid in sphereSector.asteroids {
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
            for bolt in sphereSector.bolts {
                let position = PlanetPreview556.shipSurfacePosition(bolt.position,altitude:0.12)
                drawMesh(bulletMesh,Self.translation(position.x,position.y,position.z) * Self.scale(0.014),unlit:1)
            }
            // GpuSphere67.CraftSphere67: real sphere tangent basis,
            // source world ShipContactRadius*Scale67*.65 and visual
            // bank/pitch in DEGREES. The source Vanguard GLB exporter
            // already projects the GLB onto local XY with Z up.
            let craft=Self.sphereStamp(
                sphereFlight.position,
                angle:sphereFlight.flight.visualHeading,
                size:SphereSurfaceStamp556.sourceCraftRadius)
            let shipModel=craft *
                Self.rotateYDegrees(sphereFlight.flight.visualBank) *
                Self.rotateXDegrees(sphereFlight.flight.visualPitch)
            drawMesh(shipMesh,shipModel)
            encoder.endEncoding()
            command.present(drawable)
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
