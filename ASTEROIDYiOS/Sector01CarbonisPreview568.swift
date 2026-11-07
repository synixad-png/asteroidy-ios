import Foundation
import CryptoKit
import MetalKit
import simd
import SwiftUI

/// Real indexed C279 source globe in the iOS mission-01 selection panel.
/// Uses all source vertices, source UVs, indexed triangles, two material groups
/// and THREE exact PC v568 images. Preview ≠ playable mission (stage C pending).
struct Sector01CarbonisPreview568: UIViewRepresentable {
    // User-controlled orientation affects only the real source C279
    // inspection camera; never alters PC mesh geometry or UV data.
    var yawOffset: Float = 0
    var pitchOffset: Float = 0
    // Initial authentic Game.Wave actors; renderer advances positions in Metal draw loop.
    var initialRocks: [SphereAsteroid556] = []
    var gameSession: CarbonisSession568? = nil
    static let isAvailable: Bool = {
        let files:[(String,String)] = [
            ("Sector01CarbonisVertices","bin"),
            ("Sector01CarbonisIndices","bin"),
            ("Sector01CarbonisHeightMap","dat"),
            ("Sector01CarbonisBase","dat"),
            ("Sector01CarbonisEmissive","dat"),
            ("Sector01CarbonisIrradiance","dat")
        ]
        // The entry gate must reject damaged/substituted source files,
        // not merely confirm that a filename exists. The renderer also
        // validates these hashes before allocating GPU buffers.
        return files.allSatisfy { name,ext in
            guard let url=Bundle.main.url(forResource:name,withExtension:ext)
                    ?? Bundle.main.url(forResource:name,withExtension:ext,
                                       subdirectory:"Assets"),
                  let bytes=try? Data(contentsOf:url),
                  let expected=Coordinator.Renderer.expected[name+"."+ext]
            else { return false }
            let actual=SHA256.hash(data:bytes).map {
                String(format:"%02x",$0)
            }.joined()
            return actual==expected
        }
    }()

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context:Context) -> MTKView {
        let view=MTKView(frame:.zero,device:MTLCreateSystemDefaultDevice())
        // Real source GpuSphere67.cs clears gameplay to an opaque scene.
        // The diagnostic planet preview still needs its transparent layer.
        // Do not blend the full-screen game drawable with the SwiftUI
        // background: that forces unnecessary framebuffer composition.
        let gameplay=gameSession != nil
        view.isOpaque=gameplay
        view.backgroundColor = gameplay
            ? UIColor(red:0.008,green:0.014,blue:0.032,alpha:1)
            : .clear
        view.clearColor=gameplay
            ? MTLClearColor(red:0.008,green:0.014,blue:0.032,alpha:1)
            : MTLClearColor(red:0,green:0,blue:0,alpha:0)
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.framebufferOnly=true
        view.preferredFramesPerSecond=gameSession == nil ? 30 : 60
        if let device=view.device {
            do {
                let renderer=try Coordinator.Renderer(device:device,initialRocks:initialRocks,
                    gameSession:gameSession)
                renderer.yawOffset=yawOffset
                renderer.pitchOffset=pitchOffset
                view.delegate=renderer
                context.coordinator.renderer=renderer
            } catch {
                NSLog("ASTEROIDY sector01 real Carbonis source rejected: %@",
                      String(describing:error))
            }
        }
        return view
    }
    func updateUIView(_ view:MTKView,context:Context) {
        context.coordinator.renderer?.yawOffset=yawOffset
        context.coordinator.renderer?.pitchOffset=pitchOffset
    }

    final class Coordinator {
        var renderer: Renderer?
        final class Renderer: NSObject,MTKViewDelegate {
            enum SourceError: Error {case missing,invalid,metal}
            private let gpu:MTLDevice
            private let queue:MTLCommandQueue
            private let pipeline:MTLRenderPipelineState
            private let rockPipeline:MTLRenderPipelineState
            // GpuSphere67.SphereScene67 calls IntroSky FIRST, before
            // DrawPlanetSolid. Same original source renderer on iOS.
            private let sourceSky568:SourceCombatSky568?
            private let rockFallbackPipeline:MTLRenderPipelineState
            private var rockBuffers: [Int:MTLBuffer] = [:]
            private var activeRocks: [SphereAsteroid556]
            private var previousRockFrame: TimeInterval?
            private let depth:MTLDepthStencilState
            private let noDepthWrite:MTLDepthStencilState
            // Source v568: 3D cap drawn after planet; additive halo only
            // for 2D menu preview, exactly as GpuSphere67/PlanetScreen.
            private let planetAtmospherePipeline:MTLRenderPipelineState
            private let planetGlowPipeline:MTLRenderPipelineState
            private let planetAtmosphereBuffer:MTLBuffer
            private let planetGlowBuffer:MTLBuffer
            private let planetAtmosphereCount:Int
            private let planetGlowCount:Int
            private var visualSettings=CarbonisVisualSettings568.load()
            private var fxBudget=CarbonisIOSFXBudget568.load()
            private var nextVisualReload:TimeInterval=0
            private var lava287=SourceLavaLightSettings287.load()
            private let planetFx568=SourcePlanetGraphicsSettings568.load()
            private let shipScale472=SourceShipScale472.load()
            private let missionTerrainScale523:Float
            private let vertexBuffer:MTLBuffer
            private let indexBuffer:MTLBuffer
            // Windows GpuPlanet.cs:CarbonisCombined469 caches one combined
            // map until source brightness changes. Retain original textures
            // solely for a rare brightness-triggered re-bake. The ordinary
            // planet fragment continues sampling ONE combined map.
            private let carbonisBase469:MTLTexture
            private let carbonisEmissive469:MTLTexture
            private let carbonisIrradiance469:MTLTexture
            private let carbonisBakePipeline469:MTLComputePipelineState
            private var carbonisCombined469:MTLTexture
            private let started=ProcessInfo.processInfo.systemUptime
            private let gameSession:CarbonisSession568?
            private var craftBuffer:MTLBuffer?
            private var craftTexture:MTLTexture?
            private var craftVertexCount=0
            private var craftPipeline:MTLRenderPipelineState?
            private var craftEnginePipeline491:MTLRenderPipelineState?
            private var tracerPipeline:MTLRenderPipelineState?
            private var projectilePipeline:MTLRenderPipelineState?
            private var projectileGroundPipeline:MTLRenderPipelineState?
            private lazy var fxStream568=CarbonisFXStreamingBuffers568(device:gpu)
            // Explosion524 v568: one 3D noise texture and one Metal
            // pipeline for all actual rock/enemy death events.
            private var destructionRenderer:CarbonisExplosion524Renderer?
            private var shooterPipeline:MTLRenderPipelineState?
            private var sourceShooters:[Int:(buffer:MTLBuffer,ranges:[Range<Int>])] = [:]
            private var proofScheduled=false
            var yawOffset: Float = 0
            var pitchOffset: Float = 0
            static let expected:[String:String] = [
                "Sector01CarbonisVertices.bin":"b35318d059b9c4f180d03f36e52a6c4eea1225a484e339d3f117e5df9d7634bd",
                "Sector01CarbonisIndices.bin":"e542a65a0ddf0767d982b573da037becea7872cc8a6e0d5d1e1851cd90730bef",
                "Sector01CarbonisHeightMap.dat":"3ce9a0456d23a5b88de718e7fd8fe6560cb53cd112a31ecc876e6200a762cb39",
                "Sector01CarbonisBase.dat":"8a9d5d2ad53d1c5bc8681f9ff17b83a3375fb7e16f58a3ed083a9157bcc58424",
                "Sector01CarbonisEmissive.dat":"cc32669e8e31dbf0942fa0db54fd04582af9bfbd02e7248932a04e7eb78646b3",
                "Sector01CarbonisIrradiance.dat":"b1cc566768c655e643c450b1eba73cf718765b918e54d7f7a1ac30ac6045d685",
                "Vanguard431Source.mesh":SourceVanguardMesh431.exactMeshSHA256,
                "Vanguard431Base.jpg":SourceVanguardMesh431.exactBaseJPEG_SHA256
            ]
            private struct Uniforms {
                var mvp:simd_float4x4
                var model:simd_float4x4
                var material:UInt32=0
                var glow:Float=1.0
                // Windows GpuToon60.cs:202 original solar terminator 436.
                var planetSunNight:SIMD4<Float>=SIMD4<Float>(0,0,1,1)
                // Original CarbonisCombined469 with Menu139 #45.
                var lavaBoost287:Float=1.8
            }
            // Exact ABI of Ship.metal FighterPlasmaUniform491.
            private struct EngineUniforms491 {
                var mvp:simd_float4x4
                var engine0:SIMD4<Float>
                var engine1:SIMD4<Float>
                var frame:SIMD4<Float>
            }
            private static func verified(_ full:String) throws -> Data {
                let name=(full as NSString).deletingPathExtension
                let ext=(full as NSString).pathExtension
                guard let path=Bundle.main.url(forResource:name,withExtension:ext)
                      ?? Bundle.main.url(forResource:name,withExtension:ext,
                                         subdirectory:"Assets"),
                      let bytes=try? Data(contentsOf:path)
                else {throw SourceError.missing}
                let digest=SHA256.hash(data:bytes).map {
                    String(format:"%02x",$0)
                }.joined()
                guard digest==expected[full] else {throw SourceError.invalid}
                return bytes
            }
            private static func makeBuffer(_ data:Data,device:MTLDevice)
                throws -> MTLBuffer {
                guard let buffer=data.withUnsafeBytes({ raw in
                    raw.baseAddress.flatMap {
                        device.makeBuffer(bytes:$0,length:data.count,options:[])
                    }
                }) else {throw SourceError.metal}
                return buffer
            }
            init(device:MTLDevice,initialRocks:[SphereAsteroid556],
                 gameSession:CarbonisSession568?) throws {
                activeRocks=initialRocks
                gpu=device
                self.gameSession=gameSession
                // The W3 planet-only menu preview stays transparent and
                // has NO sky. Only real playable CARBONIS combat gets it.
                sourceSky568=try gameSession != nil
                    ? SourceCombatSky568(device:device) : nil
                guard let q=device.makeCommandQueue() else {throw SourceError.metal}
                queue=q
                let vertices=try Self.verified("Sector01CarbonisVertices.bin")
                let indices=try Self.verified("Sector01CarbonisIndices.bin")
                guard vertices.count==137067*48 && indices.count==810747*4
                else {throw SourceError.invalid}
                // Windows GpuPlanetGltf463: terrain radius from actual
                // C279 triangles, not the conservative MaxRadius.
                guard let sourceScale=CarbonisMissionPlanet523
                    .missionScale523(vertexBytes:vertices)
                else {throw SourceError.invalid}
                missionTerrainScale523=sourceScale
                vertexBuffer=try Self.makeBuffer(vertices,device:device)
                indexBuffer=try Self.makeBuffer(indices,device:device)
                let texLoader=MTKTextureLoader(device:device)
                let opts:[MTKTextureLoader.Option:Any] = [
                    .SRGB:false,
                    .generateMipmaps:false,
                    .origin:MTKTextureLoader.Origin.topLeft
                ]
                let baseTex=try texLoader.newTexture(
                    data:Self.verified("Sector01CarbonisBase.dat"),
                    options:opts)
                let emissionTex=try texLoader.newTexture(
                    data:Self.verified("Sector01CarbonisEmissive.dat"),
                    options:opts)
                let irradianceTex=try texLoader.newTexture(
                    data:Self.verified("Sector01CarbonisIrradiance.dat"),
                    options:opts)
                let library=try device.makeDefaultLibrary(bundle:.main)
                // The original GpuPlanet.cs:175-225 builds this color+lava
                // texture once and only changes it when the lava slider
                // changes. Previous iOS evaluated all three source maps
                // and complex smoothsteps for each *planet fragment*.
                guard baseTex.width==emissionTex.width,
                      baseTex.height==emissionTex.height,
                      let baker=library.makeFunction(
                          name:"sector01SourceCarbonisBake469")
                else {throw SourceError.metal}
                let bakedDesc=MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat:.rgba8Unorm,width:baseTex.width,
                    height:baseTex.height,mipmapped:false)
                bakedDesc.usage=[.shaderRead,.shaderWrite]
                bakedDesc.storageMode = .private
                guard let baked=device.makeTexture(descriptor:bakedDesc),
                      let bakeCommand=q.makeCommandBuffer(),
                      let bakeEncoder=bakeCommand.makeComputeCommandEncoder()
                else {throw SourceError.metal}
                let bakeState=try device.makeComputePipelineState(
                    function:baker)
                bakeEncoder.setComputePipelineState(bakeState)
                bakeEncoder.setTexture(baseTex,index:0)
                bakeEncoder.setTexture(emissionTex,index:1)
                bakeEncoder.setTexture(irradianceTex,index:2)
                bakeEncoder.setTexture(baked,index:3)
                var boost287=SourceLavaLightSettings287.load().intensity
                bakeEncoder.setBytes(&boost287,length:MemoryLayout<Float>.stride,
                                     index:0)
                bakeEncoder.dispatchThreads(
                    MTLSize(width:baseTex.width,height:baseTex.height,depth:1),
                    threadsPerThreadgroup:MTLSize(width:8,height:8,depth:1))
                bakeEncoder.endEncoding()
                bakeCommand.commit()
                bakeCommand.waitUntilCompleted()
                guard bakeCommand.status == .completed else {
                    throw SourceError.metal
                }
                carbonisCombined469=baked
                carbonisBase469=baseTex
                carbonisEmissive469=emissionTex
                carbonisIrradiance469=irradianceTex
                carbonisBakePipeline469=bakeState
                guard let v=library.makeFunction(name:"sector01CarbonisVertex568"),
                      let f=library.makeFunction(name:"sector01CarbonisFragment568"),
                      let rockFragment=library.makeFunction(name:"sector01SourceRockFragment568"),
                      let rockVertexInstanced=library.makeFunction(name:"sector01RockInstancedVertex568"),
                      let rockFragmentInstanced=library.makeFunction(name:"sector01RockInstancedFragment568")
                else {throw SourceError.metal}
                let spec=MTLRenderPipelineDescriptor()
                spec.vertexFunction=v
                spec.fragmentFunction=f
                spec.colorAttachments[0].pixelFormat = .bgra8Unorm
                spec.depthAttachmentPixelFormat = .depth32Float
                // Original C279 vertex alpha is 1 for all 137067 points,
                // base is JPEG (opaque), and original GpuSphere67.cs:420
                // disables blending for the planet surface. Fragment shader
                // produces alpha=1. This planet pass never needs blending.
                spec.colorAttachments[0].isBlendingEnabled=false
                pipeline=try device.makeRenderPipelineState(descriptor:spec)
                // Exact GpuPlanet.cs Atmosphere47: source-alpha RGB,
                // depth tested with writes disabled after the terrain pass.
                guard let atmosphereVertex=library.makeFunction(
                        name:"sourcePlanetAtmosphereVertex568"),
                      let atmosphereFragment=library.makeFunction(
                        name:"sourcePlanetAtmosphereFragment568"),
                      let glowVertex=library.makeFunction(
                        name:"sourcePlanetGlowVertex568"),
                      let glowFragment=library.makeFunction(
                        name:"sourcePlanetGlowFragment568")
                else {throw SourceError.metal}
                let atmosphereSpec=MTLRenderPipelineDescriptor()
                atmosphereSpec.vertexFunction=atmosphereVertex
                atmosphereSpec.fragmentFunction=atmosphereFragment
                atmosphereSpec.colorAttachments[0].pixelFormat = .bgra8Unorm
                atmosphereSpec.depthAttachmentPixelFormat = .depth32Float
                let atmBlend=atmosphereSpec.colorAttachments[0]!
                atmBlend.isBlendingEnabled=true
                atmBlend.sourceRGBBlendFactor = .sourceAlpha
                atmBlend.destinationRGBBlendFactor = .oneMinusSourceAlpha
                atmBlend.sourceAlphaBlendFactor = .sourceAlpha
                atmBlend.destinationAlphaBlendFactor = .oneMinusSourceAlpha
                planetAtmospherePipeline=try device.makeRenderPipelineState(
                    descriptor:atmosphereSpec)
                let glowSpec=MTLRenderPipelineDescriptor()
                glowSpec.vertexFunction=glowVertex
                glowSpec.fragmentFunction=glowFragment
                glowSpec.colorAttachments[0].pixelFormat = .bgra8Unorm
                glowSpec.depthAttachmentPixelFormat = .depth32Float
                let glowBlend=glowSpec.colorAttachments[0]!
                glowBlend.isBlendingEnabled=true
                glowBlend.sourceRGBBlendFactor = .one
                glowBlend.destinationRGBBlendFactor = .one
                glowBlend.sourceAlphaBlendFactor = .one
                glowBlend.destinationAlphaBlendFactor = .one
                planetGlowPipeline=try device.makeRenderPipelineState(
                    descriptor:glowSpec)
                let cap=SourcePlanetAtmosphere568.atmosphere(
                    tint:SourcePlanetAtmosphere568.carbonisTint)
                let halo=SourcePlanetAtmosphere568.glow(
                    tint:SourcePlanetAtmosphere568.carbonisTint)
                planetAtmosphereCount = cap.count /
                    SourcePlanetAtmosphere568.atmosphereVertexStride
                planetGlowCount = halo.count /
                    SourcePlanetAtmosphere568.glowVertexStride
                guard let capGPU=cap.withUnsafeBytes({ data in
                    data.baseAddress.flatMap {
                        device.makeBuffer(bytes:$0,length:data.count,options:[])
                    }
                }),let haloGPU=halo.withUnsafeBytes({ data in
                    data.baseAddress.flatMap {
                        device.makeBuffer(bytes:$0,length:data.count,options:[])
                    }
                }) else {throw SourceError.metal}
                planetAtmosphereBuffer=capGPU
                planetGlowBuffer=haloGPU
                let rockSpec=MTLRenderPipelineDescriptor()
                rockSpec.vertexFunction=rockVertexInstanced
                rockSpec.fragmentFunction=rockFragmentInstanced
                rockSpec.colorAttachments[0].pixelFormat = .bgra8Unorm
                rockSpec.depthAttachmentPixelFormat = .depth32Float
                rockPipeline=try device.makeRenderPipelineState(descriptor:rockSpec)
                // Preserve the exact old per-rock draw path if instance
                // buffer allocation fails; game objects never disappear.
                let rockFallbackSpec=MTLRenderPipelineDescriptor()
                rockFallbackSpec.vertexFunction=v
                rockFallbackSpec.fragmentFunction=rockFragment
                rockFallbackSpec.colorAttachments[0].pixelFormat = .bgra8Unorm
                rockFallbackSpec.depthAttachmentPixelFormat = .depth32Float
                rockFallbackPipeline=try device.makeRenderPipelineState(
                    descriptor:rockFallbackSpec)
                // Cache original procedural geometry per shape, never each frame.
                for shape in Set(initialRocks.map { CarbonisRockGeometry568.shape(for:$0) }) {
                    let values=CarbonisRockGeometry568.vertices(shape:shape)
                    let newBuffer=values.withUnsafeBytes { bytes in
                        bytes.baseAddress.flatMap {
                            device.makeBuffer(bytes:$0,length:bytes.count,options:[])
                        }
                    }
                    guard let buffer=newBuffer else {throw SourceError.metal}
                    rockBuffers[shape]=buffer
                }
                // Original playable Vanguard, not W3 lookalike geometry.
                // W3 and combat use the same SHA-locked source mesh and JPEG.
                if gameSession != nil {
                    let parsed=try SourceVanguardMesh431(
                        data:Self.verified("Vanguard431Source.mesh"))
                    craftBuffer=try Self.makeBuffer(parsed.vertices,device:device)
                    craftVertexCount=parsed.vertexCount
                    craftTexture=try texLoader.newTexture(
                        data:Self.verified("Vanguard431Base.jpg"),options:opts)
                    guard let fighterFragment=library.makeFunction(
                        name:"sector01SourceCraftFragment568") else {
                        throw SourceError.metal
                    }
                    let fighterSpec=MTLRenderPipelineDescriptor()
                    fighterSpec.vertexFunction=v
                    fighterSpec.fragmentFunction=fighterFragment
                    fighterSpec.colorAttachments[0].pixelFormat = .bgra8Unorm
                    fighterSpec.depthAttachmentPixelFormat = .depth32Float
                    craftPipeline=try device.makeRenderPipelineState(descriptor:fighterSpec)
                    // Source GpuShip.cs v491 uses the same 2 source sockets,
                    // 3 layers, 3 planes, 16 segments as Ship.metal.
                    guard let exhaustVertex=library.makeFunction(
                        name:"fighterPlasmaVertex491"),
                          let exhaustFragment=library.makeFunction(
                        name:"fighterPlasmaFragment491")
                    else {throw SourceError.metal}
                    let exhaustSpec=MTLRenderPipelineDescriptor()
                    exhaustSpec.vertexFunction=exhaustVertex
                    exhaustSpec.fragmentFunction=exhaustFragment
                    exhaustSpec.colorAttachments[0].pixelFormat = .bgra8Unorm
                    exhaustSpec.depthAttachmentPixelFormat = .depth32Float
                    exhaustSpec.colorAttachments[0].isBlendingEnabled=true
                    exhaustSpec.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                    exhaustSpec.colorAttachments[0].destinationRGBBlendFactor = .one
                    exhaustSpec.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
                    exhaustSpec.colorAttachments[0].destinationAlphaBlendFactor = .one
                    craftEnginePipeline491=try device.makeRenderPipelineState(
                        descriptor:exhaustSpec)
                    // Original GpuRobot70: two unique source drone hulls.
                    // Level1 has four kind0 fighters; later missions use
                    // kind1. Each shape is uploaded once, never per actor.
                    for kind in 0...1 {
                        let mesh=kind==0 ? CarbonisShooterMesh71.typeZero()
                                         : CarbonisShooterMesh71.typeOne()
                        let buffer=mesh.vertices.withUnsafeBytes { raw in
                            raw.baseAddress.flatMap {
                                device.makeBuffer(bytes:$0,length:raw.count,options:[])
                            }
                        }
                        guard let buffer else {throw SourceError.metal}
                        sourceShooters[kind]=(buffer,mesh.ranges)
                    }
                    guard let shooterFragment=library.makeFunction(
                        name:"sector01ShooterFragment71") else {throw SourceError.metal}
                    let shooterSpec=MTLRenderPipelineDescriptor()
                    shooterSpec.vertexFunction=v
                    shooterSpec.fragmentFunction=shooterFragment
                    shooterSpec.colorAttachments[0].pixelFormat = .bgra8Unorm
                    shooterSpec.depthAttachmentPixelFormat = .depth32Float
                    shooterPipeline=try device.makeRenderPipelineState(
                        descriptor:shooterSpec)
                    // Original Explosion524.InitExplosion524 catches an
                    // unavailable GPU volume path without hiding the
                    // playable planet. Keep impact sparks/3D metal debris.
                    do {
                        destructionRenderer=try CarbonisExplosion524Renderer(
                            device:device,library:library)
                    } catch {
                        destructionRenderer=nil
                        NSLog("CARBONIS Explosion524 volumetric Metal unavailable: %@",
                              String(describing:error))
                    }
                    if let tracer=library.makeFunction(name:"sector01CombatTracer568") {
                        let tracerSpec=MTLRenderPipelineDescriptor()
                        tracerSpec.vertexFunction=v
                        tracerSpec.fragmentFunction=tracer
                        tracerSpec.colorAttachments[0].pixelFormat = .bgra8Unorm
                        tracerSpec.depthAttachmentPixelFormat = .depth32Float
                        tracerSpec.colorAttachments[0].isBlendingEnabled=true
                        tracerSpec.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                        tracerSpec.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                        tracerPipeline=try device.makeRenderPipelineState(
                            descriptor:tracerSpec)
                        let fx=MTLRenderPipelineDescriptor()
                        fx.vertexFunction=v
                        fx.fragmentFunction=tracer
                        fx.colorAttachments[0].pixelFormat = .bgra8Unorm
                        fx.depthAttachmentPixelFormat = .depth32Float
                        fx.colorAttachments[0].isBlendingEnabled=true
                        fx.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                        fx.colorAttachments[0].destinationRGBBlendFactor = .one
                        // Combat69 + GpuSphere67 use additive depth-tested
                        // blending for both projectiles and ground light.
                        projectilePipeline=try device.makeRenderPipelineState(
                            descriptor:fx)
                        projectileGroundPipeline=projectilePipeline
                    }
                }
                let ds=MTLDepthStencilDescriptor()
                ds.depthCompareFunction = .lessEqual
                ds.isDepthWriteEnabled=true
                guard let d=device.makeDepthStencilState(descriptor:ds)
                else {throw SourceError.metal}
                depth=d
                let effectsDepth=MTLDepthStencilDescriptor()
                effectsDepth.depthCompareFunction = .lessEqual
                effectsDepth.isDepthWriteEnabled=false
                guard let noWrite=device.makeDepthStencilState(
                    descriptor:effectsDepth) else {throw SourceError.metal}
                noDepthWrite=noWrite
                super.init()
            }
            /// Rebuild only when PLANETY → JASNOŚĆ EMISJI LAWY changes.
            /// A fresh texture avoids overwriting texels still being sampled
            /// by an in-flight frame; Metal command buffers retain textures
            /// until GPU completion. This command commits before this
            /// frame's render command on the same serial Metal queue.
            private func rebakeCarbonis469(_ newBrightness:Float) {
                let desc=MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat:.rgba8Unorm,width:carbonisBase469.width,
                    height:carbonisBase469.height,mipmapped:false)
                desc.storageMode = .private
                desc.usage=[.shaderRead,.shaderWrite]
                guard let next=gpu.makeTexture(descriptor:desc),
                      let command=queue.makeCommandBuffer(),
                      let encoder=command.makeComputeCommandEncoder() else {
                    NSLog("CARBONIS 469 live lava rebake unavailable; original texture retained")
                    return
                }
                encoder.setComputePipelineState(carbonisBakePipeline469)
                encoder.setTexture(carbonisBase469,index:0)
                encoder.setTexture(carbonisEmissive469,index:1)
                encoder.setTexture(carbonisIrradiance469,index:2)
                encoder.setTexture(next,index:3)
                var intensity=newBrightness
                encoder.setBytes(&intensity,length:MemoryLayout<Float>.stride,
                                 index:0)
                encoder.dispatchThreads(
                    MTLSize(width:next.width,height:next.height,depth:1),
                    threadsPerThreadgroup:MTLSize(width:8,height:8,depth:1))
                encoder.endEncoding()
                command.commit()
                carbonisCombined469=next
            }

            static func rotateY(_ angle:Float) -> simd_float4x4 {
                let c=cos(angle),s=sin(angle)
                return simd_float4x4(columns:(
                    SIMD4<Float>(c,0,-s,0),SIMD4<Float>(0,1,0,0),
                    SIMD4<Float>(s,0,c,0),SIMD4<Float>(0,0,0,1)))
            }
            static func rotateX(_ angle:Float) -> simd_float4x4 {
                let c=cos(angle),s=sin(angle)
                return simd_float4x4(columns:(
                    SIMD4<Float>(1,0,0,0),SIMD4<Float>(0,c,s,0),
                    SIMD4<Float>(0,-s,c,0),SIMD4<Float>(0,0,0,1)))
            }
            static func previewMVP(_ aspect:Float,_ model:simd_float4x4)
                -> simd_float4x4 {
                let h:Float=1.42,near:Float=0.5,far:Float=30
                let projection=simd_float4x4(columns:(
                    SIMD4<Float>(1/(h*max(aspect,0.35)),0,0,0),
                    SIMD4<Float>(0,1/h,0,0),
                    SIMD4<Float>(0,0,-1/(far-near),0),
                    SIMD4<Float>(0,0,-near/(far-near),1)))
                return projection*model
            }
            /// GpuSphere67.cs:8,63,133: source StampSphere67 placement
            /// and 41/23 degree rock spin rotations. CARBONIS C279 is
            /// already normalized to source outer radius in this renderer.
            static func sourceRockModel(_ rock:SphereAsteroid556)
                -> simd_float4x4 {
                let n=Sphere67.normal(rock.position)
                let forward=Sphere67.vector(
                    rock.position,MissionWave568.direction(rock.angle)).normalized
                let right=SphereVector3.cross(forward,n).normalized
                let outer:Float=100*1.4419674
                let shell=outer+15
                let radius=rock.radius*(shell/Sphere67.radius)/outer
                let place=shell/outer
                let placement=simd_float4x4(columns:(
                    SIMD4<Float>(right.x*radius,right.y*radius,right.z*radius,0),
                    SIMD4<Float>(forward.x*radius,forward.y*radius,forward.z*radius,0),
                    SIMD4<Float>(n.x*radius,n.y*radius,n.z*radius,0),
                    SIMD4<Float>(n.x*place,n.y*place,n.z*place,1)))
                let degrees=Float.pi/180
                let spin=rotateX(rock.angle*41*degrees) *
                    rotateY(rock.angle*23*degrees)
                return placement*spin
            }

            /// Original SphereCamera67 / GpuSphere67:420 camera center follows
            /// the player's geodesic position, not an arbitrary spun globe.
            static func viewProjection(_ camera:SphereCamera67,
                                       aspect:Float)->simd_float4x4 {
                let v=SphereCameraView556(camera:camera).viewColumnMajor
                let view=simd_float4x4(columns:(
                    SIMD4<Float>(v[0],v[1],v[2],v[3]),
                    SIMD4<Float>(v[4],v[5],v[6],v[7]),
                    SIMD4<Float>(v[8],v[9],v[10],v[11]),
                    SIMD4<Float>(v[12],v[13],v[14],v[15])))
                let near=SphereProjection556.normalizedNear
                let far=SphereProjection556.normalizedFar
                let focal=SphereProjection556.sourceVerticalFocal
                // GpuIntro41.cs:455 uses 1280×720 (16:9). Keep exactly
                // its horizontal framing on narrower iPad landscape
                // viewports, so C279 terrain AND Atmosphere47 fit together.
                // iPhone viewports >= 16:9 retain the unchanged source
                // vertical focal length. All mission actors share this VP.
                let fitted=MissionViewportFraming568.focals(
                    aspect:aspect,sourceVerticalFocal:focal)
                let projection=simd_float4x4(columns:(
                    SIMD4<Float>(fitted.horizontal,0,0,0),
                    SIMD4<Float>(0,fitted.vertical,0,0),
                    SIMD4<Float>(0,0,far/(near-far),-1),
                    SIMD4<Float>(0,0,near*far/(near-far),0)))
                return projection*view
            }
            static func craftModel(_ flight:SphereFlight67)->simd_float4x4 {
                let stamp=SphereSurfaceStamp556(
                    point:flight.position,angle:flight.flight.visualHeading)
                let v=stamp.columnMajor(size:SphereSurfaceStamp556.sourceCraftRadius)
                let base=simd_float4x4(columns:(
                    SIMD4<Float>(v[0],v[1],v[2],v[3]),
                    SIMD4<Float>(v[4],v[5],v[6],v[7]),
                    SIMD4<Float>(v[8],v[9],v[10],v[11]),
                    SIMD4<Float>(v[12],v[13],v[14],v[15])))
                let attitude=rotateY(flight.flight.visualBank*Float.pi/180) *
                    rotateX(flight.flight.visualPitch*Float.pi/180)
                return base*attitude
            }
            /// EnemyTactics71.cs:84-85 DrawThreatWarnings71:
            /// RingSphere67(b.P,22,OrangeRed) and SphereLine67(b.P,
            /// Offset(b.P,Direction(Aim71)*100),rgba(160,255,100,70)).
            /// Actual surface points, depth tested against C279.
            static func warningVertices(
                _ fighters:[CarbonisCombat568.Shooter])->[Float] {
                let shell=SphereSurfaceStamp556.normalizedShellRadius+0.012
                let ringColor:[Float]=[1.0,0.28,0.12,0.9]
                let lineColor:[Float]=[1.0,0.39,0.27,160.0/255.0]
                var result:[Float]=[]
                func emit(_ at:Vec2,_ rgba:[Float]) {
                    let n=Sphere67.normal(at)
                    result.append(contentsOf:[
                        n.x*shell,n.y*shell,n.z*shell,
                        n.x,n.y,n.z,rgba[0],rgba[1],rgba[2],rgba[3],0,0])
                }
                func quad(_ a:Vec2,_ b:Vec2,_ c:Vec2,_ d:Vec2,
                          _ color:[Float]) {
                    emit(a,color);emit(b,color);emit(c,color)
                    emit(a,color);emit(c,color);emit(d,color)
                }
                for f in fighters where f.telegraph>0 {
                    let origin=f.core.position
                    // Original spherical radius 22. Thin ring with 32
                    // geodesic sections; on-screen source warning distance.
                    for i in 0..<32 {
                        let a=Float(i)*2*Float.pi/32
                        let b=Float(i+1)*2*Float.pi/32
                        let av=Vec2(x:cos(a),y:sin(a))
                        let bv=Vec2(x:cos(b),y:sin(b))
                        quad(Sphere67.offset(origin,by:av*21.3),
                             Sphere67.offset(origin,by:bv*21.3),
                             Sphere67.offset(origin,by:bv*22.7),
                             Sphere67.offset(origin,by:av*22.7),
                             ringColor)
                    }
                    let gun=Vec2(x:cos(f.aim),y:sin(f.aim))
                    let side=Vec2(x:-gun.y,y:gun.x)
                    for j in 0..<20 {
                        let start=Float(j)*5
                        let end=Float(j+1)*5
                        quad(Sphere67.offset(origin,by:gun*start+side*0.7),
                             Sphere67.offset(origin,by:gun*end+side*0.7),
                             Sphere67.offset(origin,by:gun*end-side*0.7),
                             Sphere67.offset(origin,by:gun*start-side*0.7),
                             lineColor)
                    }
                }
                return result
            }

            /// GpuSphere67.cs:438 first-level Supply.Token:
            /// RingSphere67(p.P,4.5f, Color.FromArgb(255,222,118)).
            /// Genuine collectible token locations, not decoration.
            static func tokenVertices(
                _ tokens:[CarbonisCombat568.TokenPickup])->[Float] {
                let shell=SphereSurfaceStamp556.normalizedShellRadius+0.014
                let color:[Float]=[1,222.0/255.0,118.0/255.0,0.95]
                var result:[Float]=[]
                result.reserveCapacity(tokens.count*24*6*12)
                func emit(_ point:Vec2) {
                    let n=Sphere67.normal(point)
                    result.append(contentsOf:[
                        n.x*shell,n.y*shell,n.z*shell,
                        n.x,n.y,n.z,color[0],color[1],color[2],color[3],0,0])
                }
                for token in tokens {
                    for i in 0..<24 {
                        let a=Float(i)*2*Float.pi/24
                        let b=Float(i+1)*2*Float.pi/24
                        let da=Vec2(x:cos(a),y:sin(a))
                        let db=Vec2(x:cos(b),y:sin(b))
                        let a1=Sphere67.offset(token.position,by:da*4.2)
                        let b1=Sphere67.offset(token.position,by:db*4.2)
                        let a2=Sphere67.offset(token.position,by:da*4.8)
                        let b2=Sphere67.offset(token.position,by:db*4.8)
                        emit(a1);emit(b1);emit(b2)
                        emit(a1);emit(b2);emit(a2)
                    }
                }
                return result
            }

            func mtkView(_ view:MTKView,drawableSizeWillChange size:CGSize) {}
            func draw(in view:MTKView) {
                let entered=ProcessInfo.processInfo.systemUptime
                guard let drawable=view.currentDrawable,
                      let pass=view.currentRenderPassDescriptor,
                      let command=queue.makeCommandBuffer(),
                      let encoder=command.makeRenderCommandEncoder(descriptor:pass)
                else {return}
                fxStream568.beginFrame()
                let acquired=ProcessInfo.processInfo.systemUptime
                let waitMs=(acquired-entered)*1000
                let now=acquired
                if gameSession != nil && now>=nextVisualReload {
                    // One-shot snapshots previously made all effects
                    // sliders inert until a UIViewRepresentable rebuild.
                    // Reading UserDefaults 4x/s applies changes to the
                    // same live renderer without reloading 3D assets.
                    visualSettings=CarbonisVisualSettings568.load()
                    fxBudget=CarbonisIOSFXBudget568.load()
                    let newLava=SourceLavaLightSettings287.load()
                    if newLava != lava287 {
                        rebakeCarbonis469(newLava.intensity)
                        lava287=newLava
                    }
                    nextVisualReload=now+0.25
                }
                let physicsStart=ProcessInfo.processInfo.systemUptime
                if let session=gameSession {
                    session.frame(at:now)
                    activeRocks=session.game.rocks
                } else if let previous=previousRockFrame {
                    let dt=Float(min(0.05,max(0,now-previous)))
                    for index in activeRocks.indices {activeRocks[index].advance(dt:dt)}
                }
                previousRockFrame=now
                let simulationMs=(ProcessInfo.processInfo.systemUptime-physicsStart)*1000
                let t=Float(now-started)
                var model=matrix_identity_float4x4
                if gameSession == nil {
                    model.columns.3.z = -5
                    let orbit=Self.rotateX(-0.24+pitchOffset) *
                        Self.rotateY(t*0.22+yawOffset)
                    model=model*orbit
                }
                let size=view.drawableSize
                let aspect=Float(max(1,size.width)/max(1,size.height))
                let visibilityFrame=gameSession.map {
                    SphereCameraView556(camera:$0.game.flight.camera)
                }
                let vp:simd_float4x4?=gameSession.map {
                    Self.viewProjection($0.game.flight.camera,aspect:aspect)
                }
                // Original GpuSphere67.cs:420:
                // clear -> IntroSky(24 far clouds, three real distant
                // planets, black hole, 12 near clouds, 1500 stars and
                // 5 rays) -> DrawPlanetSolid -> DrawCombatResearchWreck214.
                // Sky has depth ALWAYS/no writes; source terrain has
                // normal depth test and occludes the distant objects.
                if let session=gameSession,let sourceVP=vp {
                    sourceSky568?.draw(
                        encoder:encoder,camera:session.game.flight.camera,
                        vp:sourceVP,time:session.game.elapsed,
                        aspect:aspect,drawableHeight:Float(size.height),
                        glow:planetFx568.glowEnabled,nebula:true,rays:true)
                }
                // Only the combat planet takes the v523 radius transform;
                // NewHome290 and the PlanetScreen preview are separate.
                let terrainModel=gameSession == nil ? model :
                    simd_float4x4(diagonal:SIMD4<Float>(
                        missionTerrainScale523,missionTerrainScale523,
                        missionTerrainScale523,1))
                var uniforms=Uniforms(mvp:vp.map{$0*terrainModel} ??
                                       Self.previewMVP(aspect,terrainModel),
                                       model:terrainModel)
                // PlanetScreen draws the additive ring BEFORE terrain,
                // while sphere combat draws only its 3D atmosphere cap.
                if gameSession == nil && planetFx568.glowEnabled {
                    let sourceRadius:Float = 1 / missionTerrainScale523
                    var haloCenterScale=SIMD4<Float>(
                        0,0,sourceRadius/(1.42*max(0.35,aspect)),
                        sourceRadius/1.42)
                    encoder.setRenderPipelineState(planetGlowPipeline)
                    encoder.setDepthStencilState(noDepthWrite)
                    encoder.setVertexBuffer(planetGlowBuffer,offset:0,index:0)
                    encoder.setVertexBytes(&haloCenterScale,
                        length:MemoryLayout<SIMD4<Float>>.stride,index:1)
                    encoder.drawPrimitives(type:.triangle,vertexStart:0,
                        vertexCount:planetGlowCount)
                }
                let sourceSun=planetFx568.sourceSun(
                    gameSession?.game.elapsed ?? t)
                uniforms.planetSunNight=SIMD4<Float>(
                    sourceSun.0,sourceSun.1,sourceSun.2,sourceSun.3)
                uniforms.lavaBoost287=lava287.intensity
                encoder.setRenderPipelineState(pipeline)
                encoder.setDepthStencilState(depth)
                // iOS-only optimization, NOT a Windows raster-state copy:
                // original Windows GpuPlanet.cs DrawCarbonis277:251 calls
                // disable(GL_CULL_FACE), preserving double-sided rendering.
                // Source C279: all 270249 triangles have outward winding.
                // We cull rear-facing surfaces on iOS to reduce the heavy
                // planet cost; visual parity on actual devices is NOT proven.
                // Restore .none for all other geometry.
                encoder.setFrontFacing(.counterClockwise)
                encoder.setCullMode(.back)
                encoder.setVertexBuffer(vertexBuffer,offset:0,index:0)
                // One sampled RGBA texture, as in source PC v469.
                // No recurring emission/irradiance fetches in gameplay.
                encoder.setFragmentTexture(carbonisCombined469,index:0)
                encoder.setVertexBytes(&uniforms,
                    length:MemoryLayout<Uniforms>.stride,index:1)
                encoder.setFragmentBytes(&uniforms,
                    length:MemoryLayout<Uniforms>.stride,index:1)
                encoder.drawIndexedPrimitives(type:.triangle,indexCount:803712,
                    indexType:.uint32,indexBuffer:indexBuffer,indexBufferOffset:0)
                uniforms.material=1
                encoder.setVertexBytes(&uniforms,
                    length:MemoryLayout<Uniforms>.stride,index:1)
                encoder.setFragmentBytes(&uniforms,
                    length:MemoryLayout<Uniforms>.stride,index:1)
                encoder.drawIndexedPrimitives(type:.triangle,indexCount:7035,
                    indexType:.uint32,indexBuffer:indexBuffer,
                    indexBufferOffset:803712*MemoryLayout<UInt32>.stride)
                // Remaining original mixed-winding procedural meshes and
                // camera-facing quads are independent of planet winding.
                encoder.setCullMode(.none)
                if planetFx568.glowEnabled {
                    let atmosphereModel:simd_float4x4
                    if let session=gameSession {
                        // Windows GpuPlanet.cs Atmosphere47 faces the eye.
                        // The source SphereCameraView556 already defines
                        // the normalized orbit camera's real local axes.
                        let f=SphereCameraView556(
                            camera:session.game.flight.camera)
                        atmosphereModel=simd_float4x4(columns:(
                            SIMD4<Float>(f.right.x,f.right.y,f.right.z,0),
                            SIMD4<Float>(f.up.x,f.up.y,f.up.z,0),
                            SIMD4<Float>(f.back.x,f.back.y,f.back.z,0),
                            SIMD4<Float>(0,0,0,1)))
                    } else {
                        var origin=matrix_identity_float4x4
                        origin.columns.3.z = -5
                        let sourceRadius:Float = 1 / missionTerrainScale523
                        atmosphereModel=origin*simd_float4x4(
                            diagonal:SIMD4<Float>(
                                sourceRadius,sourceRadius,sourceRadius,1))
                    }
                    var capMVP=vp.map{$0*atmosphereModel} ??
                        Self.previewMVP(aspect,atmosphereModel)
                    encoder.setRenderPipelineState(planetAtmospherePipeline)
                    encoder.setDepthStencilState(noDepthWrite)
                    encoder.setVertexBuffer(
                        planetAtmosphereBuffer,offset:0,index:0)
                    encoder.setVertexBytes(&capMVP,
                        length:MemoryLayout<simd_float4x4>.stride,index:1)
                    encoder.drawPrimitives(type:.triangle,vertexStart:0,
                        vertexCount:planetAtmosphereCount)
                    encoder.setDepthStencilState(depth)
                }

                // Original GpuSphere67.DrawProjectileGroundLights170:
                // source four colored radial lights on the planet surface,
                // brightness/color/mixing follow the saved settings.
                if let session=gameSession,let cameraMatrix=vp,
                   let groundPipeline=projectileGroundPipeline {
                    let lightMesh=CarbonisProjectileFX69.indexedGroundLights(
                        session.game.bullets+session.game.hostileShots,
                        settings:visualSettings,budget:fxBudget)
                    if lightMesh.indexCount>0,
                       let verts=fxStream568.upload(
                           lightMesh.vertices,as:.groundVertices),
                       let index=fxStream568.upload(
                           lightMesh.indices,as:.groundIndices) {
                        uniforms=Uniforms(mvp:cameraMatrix,
                            model:matrix_identity_float4x4,
                            material:2,glow:1)
                        encoder.setDepthStencilState(noDepthWrite)
                        encoder.setRenderPipelineState(groundPipeline)
                        encoder.setVertexBuffer(verts,offset:0,index:0)
                        encoder.setVertexBytes(&uniforms,
                            length:MemoryLayout<Uniforms>.stride,index:1)
                        encoder.setFragmentBytes(&uniforms,
                            length:MemoryLayout<Uniforms>.stride,index:1)
                        encoder.drawIndexedPrimitives(type:.triangle,
                            indexCount:lightMesh.indexCount,indexType:.uint32,
                            indexBuffer:index,indexBufferOffset:0)
                        encoder.setDepthStencilState(depth)
                    }
                }

                // GpuRockInstancing75: one Metal draw per visible *shape*.
                // Individual source model/MVP and 960-vertex procedural
                // geometry are preserved; Physics68 and combat are untouched.
                if !activeRocks.isEmpty {
                    var groups:[Int:[Uniforms]]=[:]
                    for rock in activeRocks {
                        if let visibilityFrame,
                           !SourceVisibleSurface73.possiblyVisible(
                               rock.position,
                               worldRadius:SourceVisibleSurface73.rockWorldRadius(rock),
                               camera:visibilityFrame,aspect:aspect) {
                            continue
                        }
                        let shape=CarbonisRockGeometry568.shape(for:rock)
                        if rockBuffers[shape] == nil {
                            // Physics68 splits create new source shapes; cache once.
                            let mesh=CarbonisRockGeometry568.vertices(shape:shape)
                            rockBuffers[shape]=mesh.withUnsafeBytes { bytes in
                                bytes.baseAddress.flatMap {
                                    gpu.makeBuffer(bytes:$0,length:bytes.count,options:[])
                                }
                            }
                        }
                        guard rockBuffers[shape] != nil else {continue}
                        let rockMatrix=model*Self.sourceRockModel(rock)
                        let rockUniforms=Uniforms(
                            mvp:vp.map{$0*rockMatrix} ??
                                Self.previewMVP(aspect,rockMatrix),
                            model:rockMatrix,material:2,glow:0)
                        groups[shape,default:[]].append(rockUniforms)
                    }
                    if !groups.isEmpty {
                        var instances:[Uniforms]=[]
                        instances.reserveCapacity(activeRocks.count)
                        var batches:[(shape:Int,start:Int,count:Int)]=[]
                        for shape in groups.keys.sorted() {
                            guard let records=groups[shape] else {continue}
                            batches.append((shape,instances.count,records.count))
                            instances.append(contentsOf:records)
                        }
                        if let gpuInstances=fxStream568.upload(
                            instances,as:.rockInstances) {
                            encoder.setRenderPipelineState(rockPipeline)
                            for batch in batches {
                                guard let vertex=rockBuffers[batch.shape] else {continue}
                                let offset=batch.start*MemoryLayout<Uniforms>.stride
                                encoder.setVertexBuffer(vertex,offset:0,index:0)
                                encoder.setVertexBuffer(gpuInstances,offset:offset,index:1)
                                encoder.setFragmentBuffer(gpuInstances,offset:offset,index:1)
                                encoder.drawPrimitives(type:.triangle,vertexStart:0,
                                    vertexCount:CarbonisRockGeometry568.sourceVertexCount,
                                    instanceCount:batch.count)
                            }
                        } else {
                            // The original render path remains available on
                            // allocation failure rather than dropping rocks.
                            encoder.setRenderPipelineState(rockFallbackPipeline)
                            for batch in batches {
                                guard let vertex=rockBuffers[batch.shape] else {continue}
                                encoder.setVertexBuffer(vertex,offset:0,index:0)
                                for i in batch.start..<(batch.start+batch.count) {
                                    var original=instances[i]
                                    encoder.setVertexBytes(&original,
                                        length:MemoryLayout<Uniforms>.stride,index:1)
                                    encoder.setFragmentBytes(&original,
                                        length:MemoryLayout<Uniforms>.stride,index:1)
                                    encoder.drawPrimitives(type:.triangle,
                                        vertexStart:0,
                                        vertexCount:CarbonisRockGeometry568.sourceVertexCount)
                                }
                            }
                        }
                    }
                }
                // GpuRobot70.DrawShooter71: kind0/1 independently authored
                // original source meshes. Unported kinds2–5 are not faked.
                if let session=gameSession,let worldView=vp,
                   let shooterPipeline=shooterPipeline {
                    encoder.setRenderPipelineState(shooterPipeline)
                    for enemy in session.game.shooters {
                        if let visibilityFrame,
                           !SourceVisibleSurface73.possiblyVisible(
                               enemy.core.position,
                               worldRadius:SourceVisibleSurface73.shooterWorldRadius(),
                               camera:visibilityFrame,aspect:aspect) {
                            continue
                        }
                        guard let shooter=sourceShooters[enemy.core.type] else {
                            continue
                        }
                        encoder.setVertexBuffer(shooter.buffer,offset:0,index:0)
                        let stamp=SphereSurfaceStamp556(
                            point:enemy.core.position,angle:enemy.aim)
                        let pose=stamp.columnMajor(size:9)
                        let matrix=simd_float4x4(columns:(
                            SIMD4<Float>(pose[0],pose[1],pose[2],pose[3]),
                            SIMD4<Float>(pose[4],pose[5],pose[6],pose[7]),
                            SIMD4<Float>(pose[8],pose[9],pose[10],pose[11]),
                            SIMD4<Float>(pose[12],pose[13],pose[14],pose[15])))
                        // GpuRobot70.ShooterMesh71: a telegraphed shot
                        // enlarges ONLY emissive cores material 5/6 by 15%.
                        // The rest of the original hull remains unchanged.
                        let brightCore=matrix * simd_float4x4(
                            diagonal:SIMD4<Float>(1.15,1.15,1.15,1))
                        for (material,range) in shooter.ranges.enumerated()
                            where !range.isEmpty {
                            let showWarning=enemy.telegraph>0 &&
                                (material==5 || material==6)
                            let partMatrix=showWarning ? brightCore : matrix
                            uniforms=Uniforms(
                                mvp:worldView*partMatrix,model:partMatrix,
                                material:UInt32(material),glow:0)
                            encoder.setVertexBytes(&uniforms,
                                length:MemoryLayout<Uniforms>.stride,index:1)
                            encoder.setFragmentBytes(&uniforms,
                                length:MemoryLayout<Uniforms>.stride,index:1)
                            encoder.drawPrimitives(
                                type:.triangle,vertexStart:range.lowerBound,
                                vertexCount:range.count)
                        }
                    }
                }
                // Render the exact default VANGUARD v568 craft alongside
                // its moving CARBONIS sphere; use real source mesh and UV.
                if let session=gameSession,
                   let buffer=craftBuffer,
                   let texture=craftTexture,
                   let fighterPipeline=craftPipeline,
                   let worldView=vp {
                    // Windows/src/GpuSphere67.cs CraftSphere67 applies the
                    // visual MissionShipScale472 AFTER source StampSphere67.
                    // Reuse this very same model for exhaust sockets 491,
                    // without touching collision size or geodesic movement.
                    let pct=shipScale472.missionFactor
                    let shipMatrix=Self.craftModel(session.game.flight) *
                        simd_float4x4(diagonal:SIMD4<Float>(pct,pct,pct,1))
                    uniforms=Uniforms(mvp:worldView*shipMatrix,
                                      model:shipMatrix,material:2,glow:0)
                    encoder.setRenderPipelineState(fighterPipeline)
                    encoder.setVertexBuffer(buffer,offset:0,index:0)
                    encoder.setVertexBytes(&uniforms,
                        length:MemoryLayout<Uniforms>.stride,index:1)
                    encoder.setFragmentBytes(&uniforms,
                        length:MemoryLayout<Uniforms>.stride,index:1)
                    encoder.setFragmentTexture(texture,index:0)
                    encoder.drawPrimitives(type:.triangle,vertexStart:0,
                                           vertexCount:craftVertexCount)
                    // GpuSphere67.CraftSphere67 draws v491 exhaust at the
                    // exact craft transform, with max(.12, VisualPower298).
                    if let enginePipeline=craftEnginePipeline491 {
                        let engines=IntroEnginePlasma491.engineCenters
                        var exhaust=EngineUniforms491(
                            mvp:worldView*shipMatrix,
                            engine0:SIMD4<Float>(engines[0].x,
                                engines[0].y,engines[0].z,0),
                            engine1:SIMD4<Float>(engines[1].x,
                                engines[1].y,engines[1].z,0),
                            frame:SIMD4<Float>(session.game.elapsed,
                                max(0.12,session.game.flight.flight.visualPower),
                                IntroEnginePlasma491.visualSize,0))
                        encoder.setRenderPipelineState(enginePipeline)
                        encoder.setDepthStencilState(noDepthWrite)
                        encoder.setVertexBytes(&exhaust,
                            length:MemoryLayout<EngineUniforms491>.stride,index:0)
                        encoder.drawPrimitives(type:.triangle,vertexStart:0,
                            vertexCount:IntroEnginePlasma491.vertexCount)
                        encoder.setDepthStencilState(depth)
                    }
                }
                // Windows GpuSphere67.cs:433 calls volume explosion
                // immediately before projectile/debris visual effects.
                if let session=gameSession,let worldView=vp,
                   let explosion=destructionRenderer {
                    explosion.render(session.game.destruction,
                        time:session.game.elapsed,
                        camera:session.game.flight.camera,
                        vp:worldView,settings:visualSettings,
                        budget:fxBudget,into:encoder)
                }
                if let session=gameSession,let tracer=tracerPipeline,
                   let cameraMatrix=vp {
                    let shots=session.game.bullets+session.game.hostileShots
                    // Combat69: source player/hostile projectiles are six
                    // segment, three-layer geodesic luminous ribbons
                    // with true constant-pixel round 3D projectile cores.
                    if let fxPipeline=projectilePipeline {
                        var fx=CarbonisProjectileFX69.indexedVertices(
                            shots,camera:session.game.flight.camera,
                            drawableHeight:Float(view.drawableSize.height),
                            glow:fxBudget.drawBulletGlow)
                        // Source enemy muzzle flashes retain all 24 slices.
                        let muzzles=CarbonisProjectileFX69.muzzleFlashes(
                            session.game.shooters,
                            camera:session.game.flight.camera,
                            drawableHeight:Float(view.drawableSize.height))
                        if !muzzles.isEmpty {
                            let first=fx.vertexCount
                            fx.vertices.append(contentsOf:muzzles)
                            for i in first..<fx.vertexCount {
                                fx.indices.append(UInt32(i))
                            }
                        }
                        if fx.indexCount>0,
                           let verts=fxStream568.upload(
                               fx.vertices,as:.projectileVertices),
                           let indices=fxStream568.upload(
                               fx.indices,as:.projectileIndices) {
                            uniforms=Uniforms(mvp:cameraMatrix,
                                model:matrix_identity_float4x4,
                                material:2,glow:1)
                            encoder.setRenderPipelineState(fxPipeline)
                            encoder.setDepthStencilState(noDepthWrite)
                            encoder.setVertexBuffer(verts,offset:0,index:0)
                            encoder.setVertexBytes(&uniforms,
                                length:MemoryLayout<Uniforms>.stride,index:1)
                            encoder.setFragmentBytes(&uniforms,
                                length:MemoryLayout<Uniforms>.stride,index:1)
                            encoder.drawIndexedPrimitives(type:.triangle,
                                indexCount:fx.indexCount,indexType:.uint32,
                                indexBuffer:indices,indexBufferOffset:0)
                            encoder.setDepthStencilState(depth)
                        }
                    }
                    var values=Self.warningVertices(session.game.shooters)
                    values.append(contentsOf:Self.tokenVertices(
                        session.game.tokenPickups))
                    // Source particle bursts, radius-animated lights,
                    // metal CombatPieces125 and Explosion524 3D shards.
                    values.append(contentsOf:
                        CarbonisExplosion524Meshes.vertices(
                            session.game.destruction,
                            time:session.game.elapsed,
                            camera:session.game.flight.camera,
                            settings:visualSettings,budget:fxBudget))
                    if !values.isEmpty,
                       let buffer=fxStream568.upload(
                           values,as:.debrisVertices) {
                        uniforms=Uniforms(mvp:cameraMatrix,
                                          model:matrix_identity_float4x4,
                                          material:2,glow:1)
                        encoder.setRenderPipelineState(tracer)
                        encoder.setVertexBuffer(buffer,offset:0,index:0)
                        encoder.setVertexBytes(&uniforms,
                            length:MemoryLayout<Uniforms>.stride,index:1)
                        encoder.setFragmentBytes(&uniforms,
                            length:MemoryLayout<Uniforms>.stride,index:1)
                        encoder.drawPrimitives(type:.triangle,vertexStart:0,
                                               vertexCount:values.count/12)
                    }
                }
                encoder.endEncoding()
                command.present(drawable)
                if !proofScheduled &&
                    ProcessInfo.processInfo.environment["ASTEROIDY_W3_MENU_VERIFY"]=="1" {
                    proofScheduled=true
                    command.addCompletedHandler { completed in
                        let proof:[String:Any] = [
                            "source":"v568-C279-CARBONIS-L1-original-indexed",
                            "gpuCommandBufferCompleted":completed.status == .completed,
                            "triangles":270249,"sourceUniqueVertices":137067,
                            "sourceIndices":810747,
                            "sourceMaterialGroups":2,
                            "sourceRockMeshes":self.activeRocks.count,
                            "sourceRockMeshVerticesPerObject":CarbonisRockGeometry568.sourceVertexCount,
                            "sourceRockUpdateRoutine":"SphereAsteroid556.advance",
                            "enemyAIIntegrated":true,
                            "sourceShooterType0Geometry":"ShipMesh0-BossMesh65-drone",
                            "nativeMissionPlayable":false
                        ]
                        if let dir=FileManager.default.urls(
                            for:.cachesDirectory,in:.userDomainMask).first,
                            let bytes=try? JSONSerialization.data(
                                withJSONObject:proof,options:[.sortedKeys]) {
                            try? bytes.write(to:dir.appendingPathComponent(
                                "ASTEROIDY_CARBONIS_L1_GPUProof.json"),
                                options:.atomic)
                        }
                    }
                }
                if gameSession != nil {
                    SourcePerformance568.shared.recordCPU(
                        workMs:(ProcessInfo.processInfo.systemUptime-acquired)*1000,
                        simulationMs:simulationMs,waitMs:waitMs)
                    SourcePerformance568.shared.watch(command)
                }
                fxStream568.completeFrame(command)
                command.commit()
            }
        }
    }
}
