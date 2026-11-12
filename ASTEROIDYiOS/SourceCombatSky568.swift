import Foundation
import MetalKit
import simd

/// Windows v568 GpuSphere67.SphereScene67 -> GpuIntro41.IntroSky.
/// Real sector-01 combat renderer was missing this entire FIRST painter
/// layer. Keep source 24 FAR clouds -> 3 animated distant planets ->
/// black hole -> 12 NEAR clouds -> 1500 stars -> five solar rays.
/// All positions/textures/projections are reused from the already ported
/// original GpuIntro41 Swift helpers, never fabricated scene decoration.
final class SourceCombatSky568 {
    private let device:MTLDevice
    private let skyPointPipeline:MTLRenderPipelineState
    private let solarOverlayPipeline:MTLRenderPipelineState
    private let nebulaOverlayPipeline:MTLRenderPipelineState
    private let blackHolePipeline:MTLRenderPipelineState
    private let skyDepthState:MTLDepthStencilState
    private let starBuffer:MTLBuffer
    private let starCount:Int
    private let cloudBuffer:MTLBuffer
    private let solarBuffer:MTLBuffer
    private let solarCount:Int
    private let sphereHaloTexture:MTLTexture
    private var nebulaTexture:MTLTexture?
    private var deepPlanetTextures:MTLTexture?
    private var blackHoleTextures:MTLTexture?
    private var nebulaLoadGate=SkyTextureGate55()
    private var nebulaSliceCache55=SkyTextureSliceCache55(
        count:SphereNebula556.orbitThemeCount)
    private var deepPlanetLoadGate=SkyTextureGate55()
    private var deepPlanetSliceCache55=SkyTextureSliceCache55(
        count:DeepSkyPlanets55.count)
    private var blackHoleLoadGate=SkyTextureGate55()
    private struct SceneUniforms {
        var mvp:simd_float4x4
        var model:simd_float4x4
        var lighting:SIMD4<Float>
    }
    private static let sourceCloudLayers55:[SphereNebula556.Layer] =
        (0..<SphereNebula556.orbitLayerCount).map { SphereNebula556.layer($0) }

    private static func translation(_ x:Float,_ y:Float,_ z:Float)
        -> simd_float4x4 {
        var result=matrix_identity_float4x4
        result.columns.3=SIMD4<Float>(x,y,z,1)
        return result
    }
    private static func buffer(_ device:MTLDevice,
                               _ verts:[AssetMesh.Vertex]) throws -> MTLBuffer {
        guard !verts.isEmpty,let result=device.makeBuffer(
            bytes:verts,length:verts.count*MemoryLayout<AssetMesh.Vertex>.stride,
            options:[]) else {
            throw NSError(domain:"ASTEROIDY SourceCombatSky568",code:8)
        }
        return result
    }
    init(device:MTLDevice) throws {
        self.device=device
        let library=try device.makeDefaultLibrary(bundle:.main)
        func shader(_ n:String) throws -> MTLFunction {
            guard let f=library.makeFunction(name:n) else {
                throw NSError(domain:"SourceCombatSky568",code:9,
                    userInfo:[NSLocalizedDescriptionKey:"Missing source shader "+n])
            }
            return f
        }
        func pipeline(_ vertex:String,_ fragment:String)
            throws -> MTLRenderPipelineState {
            let d=MTLRenderPipelineDescriptor()
            d.vertexFunction=try shader(vertex)
            d.fragmentFunction=try shader(fragment)
            d.depthAttachmentPixelFormat = .depth32Float
            // GpuIntro41/IntroSky: unchanged source PArgb blend mode.
            try SourceSkyPremultipliedBlend.configure(d)
            return try device.makeRenderPipelineState(descriptor:d)
        }
        skyPointPipeline=try pipeline("skyPointVertex","skyPointFragment")
        solarOverlayPipeline=try pipeline("solarOverlayVertex","solarOverlayFragment")
        nebulaOverlayPipeline=try pipeline("nebulaOverlayVertex","nebulaOverlayFragment")
        blackHolePipeline=try pipeline("blackHoleVertex55","blackHoleFragment55")
        let ds=MTLDepthStencilDescriptor()
        ds.depthCompareFunction = .always
        ds.isDepthWriteEnabled=false
        guard let sky=device.makeDepthStencilState(descriptor:ds)
        else {throw NSError(domain:"SourceCombatSky568",code:10)}
        skyDepthState=sky
        let stars=SourceSkyAssetFactory568.sphereSky207()
        starBuffer=try Self.buffer(device,stars.0)
        starCount=stars.1.count
        let clouds=SourceSkyAssetFactory568.nebulaSource556()
        cloudBuffer=try Self.buffer(device,clouds.0)
        let rays=SourceSkyAssetFactory568.solarOverlaySource556()
        solarBuffer=try Self.buffer(device,rays.0)
        solarCount=rays.1.count
        sphereHaloTexture=try SourceSkyAssetFactory568.makeSphereHaloTexture(device)
    }

    func draw(encoder:MTLRenderCommandEncoder,camera:SphereCamera67,
              vp:simd_float4x4,time:Float,aspect:Float,
              drawableHeight:Float,glow:Bool=true,
              nebula:Bool=true,rays:Bool=true,
              worldEye:SIMD3<Float>?=nil,
              worldScale:Float=1) {
        let basis=SphereCameraView556(camera:camera)
        encoder.setCullMode(.none)
        encoder.setDepthStencilState(skyDepthState)
        // CinematicIntro41 IntroSky painter order, using the exact
        // cinematic camera axes (not the sphere-combat camera):
        // 24 FAR clouds, 3 planets, black hole, 12 NEAR clouds,
        // 1500 stars and 5 solar rays, all original source layers.
        // clouds are layered BEFORE stars and the five solar rays.
        // One immutable 216-vertex buffer, one 2-slice 256x256
        // NebulaTexture; camera orientation changes in a uniform.
        let c=camera
        var nebulaUniform=(
            SIMD4<Float>(c.right.x,c.right.y,c.right.z,0),
            SIMD4<Float>(c.up.x,c.up.y,c.up.z,0),
            SIMD4<Float>(c.focus.x,c.focus.y,c.focus.z,0),
            SIMD4<Float>(2/(720*aspect),-2/720,0,0)
        )
        encoder.setDepthStencilState(skyDepthState)
        let sourceCloudTexture=nebula ? ensureCloudTextures55(camera:c) : nil
        if let clouds=sourceCloudTexture {
            encoder.setRenderPipelineState(nebulaOverlayPipeline)
            encoder.setVertexBuffer(
                cloudBuffer,offset:0,index:0)
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
                style:style,time:time,
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
                style:style,scale:projected.scale,glow:glow)
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
            camera:c,time:time),
            let blackTextures=ensureBlackHoleTextures55() {
            let bx=(blackProjection.screen.x-640)*2/(720*aspect)
            let by=(360-blackProjection.screen.y)*2/720
            let screen=SIMD4<Float>(bx,by,2/(720*aspect),-2/720)
            let layers=BlackHoleSky55.overlays(
                time:time,
                scale:blackProjection.scale,glow:glow)
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
                cloudBuffer,offset:0,index:0)
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
        // PC602 H290: camera radius 400, original star sphere radius 900.
        // Combat's normalized camera and star scale remain unchanged.
        let skyEye=worldEye ?? SIMD3<Float>(basis.eye.x,basis.eye.y,basis.eye.z)
        let skyScale=simd_float4x4(diagonal:SIMD4<Float>(
            worldScale,worldScale,worldScale,1))
        let skyMVP=vp*Self.translation(skyEye.x,skyEye.y,skyEye.z)*skyScale
        var skyUniform=SceneUniforms(
            mvp:skyMVP,model:matrix_identity_float4x4,
            lighting:SIMD4<Float>(SphereSky207.drawableScale(
                height:drawableHeight),0,0,0))
        encoder.setRenderPipelineState(skyPointPipeline)
        encoder.setDepthStencilState(skyDepthState)
        encoder.setFragmentTexture(sphereHaloTexture,index:0)
        encoder.setVertexBuffer(starBuffer,offset:0,index:0)
        encoder.setVertexBytes(
            &skyUniform,length:MemoryLayout<SceneUniforms>.stride,index:1)
        encoder.drawPrimitives(
            type:.point,vertexStart:0,vertexCount:starCount)
        // GpuIntro41.cs:454: only draw solar effects when the source
        // 900-unit sky direction is in the original extended screen
        // bounds. SkyProject55 uses the camera rotation, NOT its eye.
        if rays,let sun=SphereSolarOverlay556.project(
            camera:c) {
            let ndcX=(sun.x-640)*2/(720*aspect)
            let ndcY=(360-sun.y)*2/720
            var solarUniform=SIMD4<Float>(
                ndcX,ndcY,2/(720*aspect),-2/720)
            encoder.setRenderPipelineState(solarOverlayPipeline)
            encoder.setVertexBuffer(
                solarBuffer,offset:0,index:0)
            encoder.setVertexBytes(
                &solarUniform,
                length:MemoryLayout<SIMD4<Float>>.stride,index:1)
            encoder.setFragmentTexture(sphereHaloTexture,index:0)
            encoder.drawPrimitives(
                type:.triangle,vertexStart:0,
                vertexCount:solarCount)
        }

    }







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

    

    

    

    

    

    
}
