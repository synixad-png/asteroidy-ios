import MetalKit
import simd

/// The actual PC v602 GpuPlanet.DrawAtmosphere47 after HomeScene291:
/// 24 radial rings x 96 triangles pairs, warm #FF7441, world radius 130.
/// Reuses the existing vetted SourcePlanetAtmosphere568 source geometry
/// and shader; no alternative shader, guessed billboard or CPU rebuild.
final class PC602HomeAtmosphere47 {
    enum SourceError:Error {case metal}
    private let buffer:MTLBuffer
    private let count:Int
    private let pipeline:MTLRenderPipelineState
    private let depth:MTLDepthStencilState

    init(device:MTLDevice)throws {
        let source=SourcePlanetAtmosphere568.atmosphere(
            tint:(1,116/255,65/255))
        count=source.count/SourcePlanetAtmosphere568.atmosphereVertexStride
        guard let vertexBuffer=source.withUnsafeBytes({ raw in
            raw.baseAddress.flatMap {
                device.makeBuffer(bytes:$0,length:raw.count,options:[])
            }
        }) else{throw SourceError.metal}
        buffer=vertexBuffer
        let library=try device.makeDefaultLibrary(bundle:.main)
        guard let v=library.makeFunction(name:"sourcePlanetAtmosphereVertex568"),
              let f=library.makeFunction(name:"sourcePlanetAtmosphereFragment568")
        else{throw SourceError.metal}
        let d=MTLRenderPipelineDescriptor()
        d.vertexFunction=v
        d.fragmentFunction=f
        d.colorAttachments[0].pixelFormat = .bgra8Unorm
        d.depthAttachmentPixelFormat = .depth32Float
        d.colorAttachments[0].isBlendingEnabled=true
        d.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        d.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        d.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        d.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipeline=try device.makeRenderPipelineState(descriptor:d)
        let stencil=MTLDepthStencilDescriptor()
        stencil.depthCompareFunction = .lessEqual
        stencil.isDepthWriteEnabled=false
        guard let s=device.makeDepthStencilState(descriptor:stencil)
        else{throw SourceError.metal}
        depth=s
    }

    func draw(encoder:MTLRenderCommandEncoder,
              projection:simd_float4x4,view:simd_float4x4,
              camera:SIMD3<Float>) {
        let distance=simd_length(camera)
        guard distance>0.001,camera.x.isFinite,
              camera.y.isFinite,camera.z.isFinite else{return}
        let z=camera/distance
        let axis=abs(z.y)<0.95
            ? SIMD3<Float>(0,1,0):SIMD3<Float>(1,0,0)
        let x=simd_normalize(simd_cross(axis,z))
        let y=simd_normalize(simd_cross(z,x))
        let radius:Float=130
        let matrix=simd_float4x4(columns:(
            SIMD4<Float>(x*radius,0),
            SIMD4<Float>(y*radius,0),
            SIMD4<Float>(z*radius,0),
            SIMD4<Float>(0,0,0,1)
        ))
        var mvp=projection*view*matrix
        encoder.setRenderPipelineState(pipeline)
        encoder.setDepthStencilState(depth)
        encoder.setCullMode(.none)
        encoder.setVertexBuffer(buffer,offset:0,index:0)
        encoder.setVertexBytes(&mvp,
            length:MemoryLayout<simd_float4x4>.stride,index:1)
        encoder.drawPrimitives(type:.triangle,vertexStart:0,vertexCount:count)
    }
}
