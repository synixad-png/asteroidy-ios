import Foundation
import MetalKit
import CryptoKit
import simd

/// Intro41/GpuIntro41 mission-level C279 globe, NOT the level-5 Boreas
/// diagnostic. Shares the exact indexed Metal C279 shader and the same
/// pre-baked v469 source texture recipe as the playable sector renderer.
/// No reconstructed sphere, substituted textures or invented planet meshes.
final class CarbonisIntroPlanet568 {
    enum SourceError: Error { case missing, invalid, metal }
    private static let hashes:[String:String] = [
        "Sector01CarbonisVertices.bin":
            "b35318d059b9c4f180d03f36e52a6c4eea1225a484e339d3f117e5df9d7634bd",
        "Sector01CarbonisIndices.bin":
            "e542a65a0ddf0767d982b573da037becea7872cc8a6e0d5d1e1851cd90730bef",
        "Sector01CarbonisBase.dat":
            "8a9d5d2ad53d1c5bc8681f9ff17b83a3375fb7e16f58a3ed083a9157bcc58424",
        "Sector01CarbonisEmissive.dat":
            "cc32669e8e31dbf0942fa0db54fd04582af9bfbd02e7248932a04e7eb78646b3",
        "Sector01CarbonisIrradiance.dat":
            "b1cc566768c655e643c450b1eba73cf718765b918e54d7f7a1ac30ac6045d685"
    ]
    private static func verified(_ file:String) throws -> Data {
        let base=(file as NSString).deletingPathExtension
        let ext=(file as NSString).pathExtension
        guard let url=Bundle.main.url(forResource:base,withExtension:ext)
                ?? Bundle.main.url(forResource:base,withExtension:ext,
                                   subdirectory:"Assets"),
              let bytes=try? Data(contentsOf:url) else {
            throw SourceError.missing
        }
        let hash=SHA256.hash(data:bytes).map {
            String(format:"%02x",$0)
        }.joined()
        guard hash==hashes[file] else {throw SourceError.invalid}
        return bytes
    }
    private struct Uniforms {
        var mvp:simd_float4x4
        var model:simd_float4x4
        var material:UInt32=0
        var glow:Float=1
        var planetSunNight:SIMD4<Float>=SIMD4<Float>(0,0,1,1)
        var lavaBoost287:Float=1.8
    }
    let sourceOuterRadius:Float
    private let vertexBuffer:MTLBuffer
    private let indexBuffer:MTLBuffer
    private let combined:MTLTexture
    private let pipeline:MTLRenderPipelineState
    private let lava287=SourceLavaLightSettings287.load()
    private let planetSettings=SourcePlanetGraphicsSettings568.load()

    init(device:MTLDevice,queue:MTLCommandQueue) throws {
        let positions=try Self.verified("Sector01CarbonisVertices.bin")
        let indices=try Self.verified("Sector01CarbonisIndices.bin")
        guard positions.count==137067*48,
              indices.count==810747*MemoryLayout<UInt32>.stride,
              let radius=CarbonisMissionPlanet523
                .sourceOuterRadius523(vertexBytes:positions),
              radius>0.01 else {throw SourceError.invalid}
        sourceOuterRadius=radius
        guard let vb=positions.withUnsafeBytes({ raw in
                    raw.baseAddress.flatMap {
                        device.makeBuffer(bytes:$0,length:positions.count,options:[])
                    }
                }),
              let ib=indices.withUnsafeBytes({ raw in
                    raw.baseAddress.flatMap {
                        device.makeBuffer(bytes:$0,length:indices.count,options:[])
                    }
                }) else {throw SourceError.metal}
        vertexBuffer=vb
        indexBuffer=ib
        let loader=MTKTextureLoader(device:device)
        let options:[MTKTextureLoader.Option:Any]=[
            .SRGB:false,.generateMipmaps:false,
            .origin:MTKTextureLoader.Origin.topLeft
        ]
        let base=try loader.newTexture(
            data:Self.verified("Sector01CarbonisBase.dat"),options:options)
        let emission=try loader.newTexture(
            data:Self.verified("Sector01CarbonisEmissive.dat"),options:options)
        let irradiation=try loader.newTexture(
            data:Self.verified("Sector01CarbonisIrradiance.dat"),options:options)
        let library=try device.makeDefaultLibrary(bundle:.main)
        guard base.width==emission.width,base.height==emission.height,
              let v=library.makeFunction(name:"sector01CarbonisVertex568"),
              let f=library.makeFunction(name:"sector01CarbonisFragment568"),
              let bake=library.makeFunction(name:"sector01SourceCarbonisBake469")
        else {throw SourceError.metal}
        let desc=MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat:.rgba8Unorm,width:base.width,
            height:base.height,mipmapped:false)
        desc.usage=[.shaderRead,.shaderWrite]
        desc.storageMode = .private
        guard let baked=device.makeTexture(descriptor:desc),
              let command=queue.makeCommandBuffer(),
              let encoder=command.makeComputeCommandEncoder()
        else {throw SourceError.metal}
        let compute=try device.makeComputePipelineState(function:bake)
        encoder.setComputePipelineState(compute)
        encoder.setTexture(base,index:0)
        encoder.setTexture(emission,index:1)
        encoder.setTexture(irradiation,index:2)
        encoder.setTexture(baked,index:3)
        var brightness=SourceLavaLightSettings287.load().intensity
        encoder.setBytes(&brightness,length:MemoryLayout<Float>.stride,index:0)
        encoder.dispatchThreads(
            MTLSize(width:base.width,height:base.height,depth:1),
            threadsPerThreadgroup:MTLSize(width:8,height:8,depth:1))
        encoder.endEncoding()
        command.commit()
        command.waitUntilCompleted()
        guard command.status == .completed else {throw SourceError.metal}
        combined=baked
        let spec=MTLRenderPipelineDescriptor()
        spec.vertexFunction=v
        spec.fragmentFunction=f
        spec.colorAttachments[0].pixelFormat = .bgra8Unorm
        spec.colorAttachments[0].isBlendingEnabled=false
        spec.depthAttachmentPixelFormat = .depth32Float
        pipeline=try device.makeRenderPipelineState(descriptor:spec)
    }

    /// Source GpuIntro41.CinematicIntro41: the intro uses
    /// MissionPlanetScale523(24f), not the combat scale of 100f.
    /// All other scene objects use IntroOrbit41.radiusNormalization.
    var introNormalizedScale:Float {
        IntroOrbit41.introPlanetScale/sourceOuterRadius
    }

    func draw(encoder:MTLRenderCommandEncoder,mvp:simd_float4x4,
              model:simd_float4x4,time:Float) {
        let sun=planetSettings.sourceSun(time)
        var u=Uniforms(mvp:mvp*model,model:model)
        u.planetSunNight=SIMD4<Float>(sun.0,sun.1,sun.2,sun.3)
        u.lavaBoost287=lava287.intensity
        encoder.setRenderPipelineState(pipeline)
        encoder.setCullMode(.none) // PC GpuIntro41 disables GL_CULL_FACE.
        encoder.setVertexBuffer(vertexBuffer,offset:0,index:0)
        encoder.setFragmentTexture(combined,index:0)
        encoder.setVertexBytes(&u,length:MemoryLayout<Uniforms>.stride,index:1)
        encoder.setFragmentBytes(&u,length:MemoryLayout<Uniforms>.stride,index:1)
        encoder.drawIndexedPrimitives(
            type:.triangle,indexCount:803712,indexType:.uint32,
            indexBuffer:indexBuffer,indexBufferOffset:0)
        u.material=1
        encoder.setVertexBytes(&u,length:MemoryLayout<Uniforms>.stride,index:1)
        encoder.setFragmentBytes(&u,length:MemoryLayout<Uniforms>.stride,index:1)
        encoder.drawIndexedPrimitives(
            type:.triangle,indexCount:7035,indexType:.uint32,
            indexBuffer:indexBuffer,
            indexBufferOffset:803712*MemoryLayout<UInt32>.stride)
    }
}
