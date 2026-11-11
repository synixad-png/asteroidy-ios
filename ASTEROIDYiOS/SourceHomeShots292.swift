import Foundation
import MetalKit
import simd

/// One real original PC602 geodesic shot pass after source
/// HomeFlight291.StepHomeWeaponTest292. Three fixed, reusable triple-ring
/// GPU buffers; NO malloc/dynamic texture or drawable-buffer overwrite
/// on the graphics queue. 6 source segments × 3 source glow/beam layers.
/// Up to 145 original bullets after a last eligible 5-shot scatter salvo.
final class SourceHomeShots292 {
    enum SourceError:Error {case pipeline,buffer}
    private static let maxBullets=145
    private static let maxVertices = Self.maxBullets * PC602HomeShotGeometry292.verticesPerShot
    private static let byteCount = Self.maxVertices * PC602HomeShotGeometry292.floatsPerVertex * MemoryLayout<Float>.size
    private let pipeline:MTLRenderPipelineState
    private let depth:MTLDepthStencilState
    private let vertices:[MTLBuffer]
    private let slots=DispatchSemaphore(value:3)
    private var ringIndex=0
    private var scratch=[Float]()

    init(device:MTLDevice) throws {
        let library=try device.makeDefaultLibrary(bundle:.main)
        guard let vertex=library.makeFunction(name:"pc602HomeShotVertex292"),
              let fragment=library.makeFunction(
                name:"pc602HomeShotFragment292")
        else {throw SourceError.pipeline}
        let descriptor=MTLRenderPipelineDescriptor()
        descriptor.vertexFunction=vertex
        descriptor.fragmentFunction=fragment
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.colorAttachments[0].isBlendingEnabled=true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .one
        pipeline=try device.makeRenderPipelineState(descriptor:descriptor)
        let ds=MTLDepthStencilDescriptor()
        ds.depthCompareFunction = .lessEqual
        ds.isDepthWriteEnabled=false
        guard let stencil=device.makeDepthStencilState(descriptor:ds)
        else {throw SourceError.pipeline}
        depth=stencil
        var allocated=[MTLBuffer]()
        for _ in 0..<3 {
            guard let buffer=device.makeBuffer(
                length:Self.byteCount,options:.storageModeShared)
            else {throw SourceError.buffer}
            allocated.append(buffer)
        }
        vertices=allocated
        scratch.reserveCapacity(Self.maxVertices * PC602HomeShotGeometry292.floatsPerVertex)
    }

    /// Renders exactly the source-owned projectiles, never claims a
    /// combat hit. Source ShotOrb151 billboards and terrain light fans
    /// still have their own (unimplemented) stages; no fake replacement.
    func draw(encoder:MTLRenderCommandEncoder,
              command:MTLCommandBuffer,
              home:PC602NewHome290,
              bullets:[PC602HomeWeaponTest292.Bullet],
              camera:SIMD3<Float>,
              view:[Float],
              mvp:simd_float4x4) {
        guard !bullets.isEmpty else{return}
        PC602HomeShotGeometry292.build(home:home,bullets:bullets,
            camera:camera,view:view,into:&scratch)
        guard !scratch.isEmpty,
              scratch.count%PC602HomeShotGeometry292.floatsPerVertex==0
        else{return}
        let bytes=scratch.count*MemoryLayout<Float>.size
        guard bytes<=Self.byteCount else{return}
        // Do not write into a previously submitted frame still owned
        // by the Metal GPU. If back-pressured, skip this *visual* tick,
        // NEVER skip/duplicate physical projectile integration.
        guard slots.wait(timeout:.now()) == .success else{return}
        let buffer=vertices[ringIndex]
        ringIndex=(ringIndex+1)%vertices.count
        scratch.withUnsafeBytes { raw in
            if let source=raw.baseAddress {
                buffer.contents().copyMemory(from:source,byteCount:bytes)
            }
        }
        command.addCompletedHandler { [slots] _ in slots.signal() }
        var matrix=mvp
        encoder.setRenderPipelineState(pipeline)
        encoder.setDepthStencilState(depth)
        encoder.setCullMode(.none)
        encoder.setVertexBuffer(buffer,offset:0,index:0)
        encoder.setVertexBytes(&matrix,
            length:MemoryLayout<simd_float4x4>.stride,index:1)
        encoder.drawPrimitives(type:.triangle,vertexStart:0,
            vertexCount:scratch.count / PC602HomeShotGeometry292.floatsPerVertex)
    }
}
