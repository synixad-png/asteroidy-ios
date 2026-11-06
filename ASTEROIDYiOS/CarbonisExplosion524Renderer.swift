import Foundation
import Metal
import simd

/// Native 3D Explosion524 (Windows V8.2 preset0) GPU renderer.
/// Builds one shared 64³ Xorshift texture and one Metal pipeline per scene,
/// NOT one resource per explosion. Source has max 3 concurrent volumes at
/// gameplay quality (22 depth samples, 13 irregular lobes).
final class CarbonisExplosion524Renderer {
    private struct Parameters {
        var mvp:simd_float4x4
        var age:Float
        var scale:Float
        var fire:Float
        var smoke:Float
        var chaos:Float
        var spread:Float
        var seed:Float
        var lobes:UInt32
        var steps:UInt32
        var kind:UInt32
    }
    private let pipeline:MTLRenderPipelineState
    private let noise:MTLTexture
    private let noDepthWrite:MTLDepthStencilState

    init(device:MTLDevice,library:MTLLibrary) throws {
        enum Setup:Error {case failed}
        guard let vertex=library.makeFunction(
                name:"sector01ExplosionVertex524"),
              let fragment=library.makeFunction(
                name:"sector01ExplosionFragment524")
        else {throw Setup.failed}
        let desc=MTLRenderPipelineDescriptor()
        desc.vertexFunction=vertex
        desc.fragmentFunction=fragment
        desc.colorAttachments[0].pixelFormat = .bgra8Unorm
        desc.colorAttachments[0].isBlendingEnabled=true
        desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        desc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        desc.depthAttachmentPixelFormat = .depth32Float
        pipeline=try device.makeRenderPipelineState(descriptor:desc)

        // Xcode 16.4: MTLTextureDescriptor provides texture2DDescriptor,
        // but no texture3DDescriptor convenience factory. Configure true
        // 3D texture explicitly; R8 bytes and dimensions are unchanged.
        let tex=MTLTextureDescriptor()
        tex.textureType = .type3D
        tex.pixelFormat = .r8Unorm
        tex.width=64
        tex.height=64
        tex.depth=64
        tex.mipmapLevelCount=1
        tex.usage = .shaderRead
        tex.storageMode = .shared
        guard let result=device.makeTexture(descriptor:tex)
        else {throw Setup.failed}
        noise=result
        let bytes=CarbonisExplosionNoise524.originalBytes()
        bytes.withUnsafeBytes { raw in
            if let address=raw.baseAddress {
                result.replace(
                    region:MTLRegionMake3D(0,0,0,64,64,64),
                    mipmapLevel:0,
                    withBytes:address,
                    bytesPerRow:64,bytesPerImage:4096)
            }
        }
        let ds=MTLDepthStencilDescriptor()
        ds.depthCompareFunction = .lessEqual
        ds.isDepthWriteEnabled=false
        guard let depth=device.makeDepthStencilState(descriptor:ds)
        else {throw Setup.failed}
        noDepthWrite=depth
    }

    /// Camera-facing 3D *bound* as in Explosion524.cs:185-220; the
    /// fragment program samples actual 3D density through the bound.
    func render(_ state:CarbonisDestruction524,time:Float,
                camera:SphereCamera67,vp:simd_float4x4,
                settings:CarbonisVisualSettings568,
                into encoder:MTLRenderCommandEncoder) {
        let events=state.visibleExplosions(
            at:time,maxCount:settings.simultaneousVolumes,
            duration:settings.explosionDuration)
        if events.isEmpty {return}
        let outer=SphereCameraView556.originalPlanetOuterRadius
        let shell=(outer+15)/outer
        let eye=SphereCameraView556(camera:camera).eye
        encoder.setRenderPipelineState(pipeline)
        encoder.setDepthStencilState(noDepthWrite)
        encoder.setCullMode(.none)
        encoder.setFragmentTexture(noise,index:0)
        for event in events {
            let age=time-event.spawned
            let normal=Sphere67.normal(event.point)
            let center=normal*(shell+1.1/outer)
            let front=(eye-center).normalized
            var right=SphereVector3.cross(
                SphereVector3(x:0,y:1,z:0),front).normalized
            if right.length<0.01 {
                right=SphereVector3(x:1,y:0,z:0)
            }
            let up=SphereVector3.cross(front,right).normalized
            // Explosion524.cs:197,203 — both the projected radius
            // and the shader uScale obey the original "ROZMIAR 3D" slider.
            let scale=settings.factor(0)
            let radius=event.scale*scale*0.55/outer
            let extent=radius*5.1*scale
            let bottomLeft=center-right*extent-up*extent
            let bottomRight=center+right*extent-up*extent
            let topRight=center+right*extent+up*extent
            let topLeft=center-right*extent+up*extent
            var vertices:[Float]=[]
            vertices.reserveCapacity(30)
            func put(_ point:SphereVector3,_ x:Float,_ y:Float) {
                vertices.append(contentsOf:[
                    point.x,point.y,point.z,x,y])
            }
            put(bottomLeft,0,0);put(bottomRight,1,0)
            put(topRight,1,1);put(bottomLeft,0,0)
            put(topRight,1,1);put(topLeft,0,1)
            var params=Parameters(
                mvp:vp,age:age,
                scale:scale,
                fire:settings.factor(2),smoke:settings.factor(3),
                chaos:settings.factor(4),spread:settings.factor(5),
                seed:event.spawned*0.13,
                lobes:UInt32(settings.value(1)),
                steps:UInt32(settings.raySamples),
                kind:UInt32(event.kind))
            vertices.withUnsafeBytes { raw in
                if let address=raw.baseAddress {
                    encoder.setVertexBytes(address,length:raw.count,index:0)
                }
            }
            encoder.setVertexBytes(&params,length:MemoryLayout<Parameters>.stride,
                                   index:1)
            encoder.setFragmentBytes(&params,length:MemoryLayout<Parameters>.stride,
                                     index:1)
            encoder.drawPrimitives(type:.triangle,vertexStart:0,vertexCount:6)
        }
    }
}
