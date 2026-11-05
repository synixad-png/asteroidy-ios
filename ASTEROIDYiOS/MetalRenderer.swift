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
    private let nebulaTexture: MTLTexture
    private let blackHoleTextures: MTLTexture
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
        nebulaTexture=try Self.makeNebulaTextures556(device)
        blackHoleTextures=try Self.makeBlackHoleTextures55(device)
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

    /// Two immutable original GpuCosmos39 PArgb NebulaTexture themes
    /// used by GpuIntro41.IntroSky. Share one 2-slice texture array across
    /// all 36 distant/near cloud layers, allocated exactly once.
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
        for theme in 0..<SphereNebula556.orbitThemeCount {
            let texels=SphereNebula556.textureBGRA(theme:theme)
            texels.withUnsafeBytes { raw in
                if let p=raw.baseAddress {
                    texture.replace(
                        region:MTLRegionMake2D(0,0,n,n),mipmapLevel:0,
                        slice:theme,withBytes:p,
                        bytesPerRow:n*4,bytesPerImage:n*n*4)
                }
            }
        }
        return texture
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
        // Original GpuIntro41.IntroProjection uses a .2/.4 half-height
        // frustum (vertical FOV 53.1301°) in GpuSphere67.SphereScene67.
        // The previous port wrongly used 36° in the planet view. The
        // independent flat training arena retains its prior projection.
        let near: Float = 0.1, far: Float = 20
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
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        // 120 Hz fixed-step simulation decoupled from 60/120 Hz display refresh.
        // A bounded catch-up prevents an unbounded simulation spiral after resume.
        let elapsed = min(0.25, max(0, now - lastTime))
        lastTime = now
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
        if input.planetPreview {
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
        let cameraFrame = input.planetPreview
            ? Self.sphereView(sphereFlight.camera)
            : (view: Self.translation(0,0,-4),
               eye: SIMD3<Float>(0,0,4))
        let vp = Self.perspective(aspect,spherical:input.planetPreview) * cameraFrame.view
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
            encoder.setRenderPipelineState(nebulaOverlayPipeline)
            encoder.setVertexBuffer(
                nebulaOverlayMesh.vertices,offset:0,index:0)
            encoder.setVertexBytes(
                &nebulaUniform,length:MemoryLayout.size(ofValue:nebulaUniform),
                index:1)
            encoder.setFragmentTexture(nebulaTexture,index:0)
            encoder.drawPrimitives(
                type:.triangle,vertexStart:0,
                vertexCount:nebulaOverlayMesh.count)
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
