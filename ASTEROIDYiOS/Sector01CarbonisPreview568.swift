import Foundation
import CryptoKit
import MetalKit
import simd
import SwiftUI

/// Real indexed C279 source globe in the iOS mission-01 selection panel.
/// Uses all source vertices, source UVs, indexed triangles, two material groups
/// and THREE exact PC v568 images. Preview ≠ playable mission (stage C pending).
struct Sector01CarbonisPreview568: UIViewRepresentable {
    static let isAvailable: Bool = {
        let files:[(String,String)] = [
            ("Sector01CarbonisVertices","bin"),
            ("Sector01CarbonisIndices","bin"),
            ("Sector01CarbonisBase","dat"),
            ("Sector01CarbonisEmissive","dat"),
            ("Sector01CarbonisIrradiance","dat")
        ]
        return files.allSatisfy { name,ext in
            Bundle.main.url(forResource:name,withExtension:ext) != nil
            || Bundle.main.url(forResource:name,withExtension:ext,
                               subdirectory:"Assets") != nil
        }
    }()

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context:Context) -> MTKView {
        let view=MTKView(frame:.zero,device:MTLCreateSystemDefaultDevice())
        view.isOpaque=false
        view.backgroundColor = .clear
        view.clearColor=MTLClearColor(red:0,green:0,blue:0,alpha:0)
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.framebufferOnly=true
        view.preferredFramesPerSecond=30
        if let device=view.device {
            do {
                let renderer=try Coordinator.Renderer(device:device)
                view.delegate=renderer
                context.coordinator.renderer=renderer
            } catch {
                NSLog("ASTEROIDY sector01 real Carbonis source rejected: %@",
                      String(describing:error))
            }
        }
        return view
    }
    func updateUIView(_ view:MTKView,context:Context) {}

    final class Coordinator {
        var renderer: Renderer?
        final class Renderer: NSObject,MTKViewDelegate {
            enum SourceError: Error {case missing,invalid,metal}
            private let queue:MTLCommandQueue
            private let pipeline:MTLRenderPipelineState
            private let depth:MTLDepthStencilState
            private let vertexBuffer:MTLBuffer
            private let indexBuffer:MTLBuffer
            private let base:MTLTexture
            private let emissive:MTLTexture
            private let irradiance:MTLTexture
            private let started=ProcessInfo.processInfo.systemUptime
            private var proofScheduled=false
            private static let expected:[String:String] = [
                "Sector01CarbonisVertices.bin":"b35318d059b9c4f180d03f36e52a6c4eea1225a484e339d3f117e5df9d7634bd",
                "Sector01CarbonisIndices.bin":"e542a65a0ddf0767d982b573da037becea7872cc8a6e0d5d1e1851cd90730bef",
                "Sector01CarbonisBase.dat":"8a9d5d2ad53d1c5bc8681f9ff17b83a3375fb7e16f58a3ed083a9157bcc58424",
                "Sector01CarbonisEmissive.dat":"cc32669e8e31dbf0942fa0db54fd04582af9bfbd02e7248932a04e7eb78646b3",
                "Sector01CarbonisIrradiance.dat":"b1cc566768c655e643c450b1eba73cf718765b918e54d7f7a1ac30ac6045d685"
            ]
            private struct Uniforms {
                var mvp:simd_float4x4
                var model:simd_float4x4
                var material:UInt32=0
                var glow:Float=1.0
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
            init(device:MTLDevice) throws {
                guard let q=device.makeCommandQueue() else {throw SourceError.metal}
                queue=q
                let vertices=try Self.verified("Sector01CarbonisVertices.bin")
                let indices=try Self.verified("Sector01CarbonisIndices.bin")
                guard vertices.count==137067*48 && indices.count==810747*4
                else {throw SourceError.invalid}
                vertexBuffer=try Self.makeBuffer(vertices,device:device)
                indexBuffer=try Self.makeBuffer(indices,device:device)
                let texLoader=MTKTextureLoader(device:device)
                let opts:[MTKTextureLoader.Option:Any] = [
                    .SRGB:false,
                    .generateMipmaps:false,
                    .origin:MTKTextureLoader.Origin.topLeft
                ]
                base=try texLoader.newTexture(
                    data:Self.verified("Sector01CarbonisBase.dat"),
                    options:opts)
                emissive=try texLoader.newTexture(
                    data:Self.verified("Sector01CarbonisEmissive.dat"),
                    options:opts)
                irradiance=try texLoader.newTexture(
                    data:Self.verified("Sector01CarbonisIrradiance.dat"),
                    options:opts)
                let library=try device.makeDefaultLibrary(bundle:.main)
                guard let v=library.makeFunction(name:"sector01CarbonisVertex568"),
                      let f=library.makeFunction(name:"sector01CarbonisFragment568")
                else {throw SourceError.metal}
                let spec=MTLRenderPipelineDescriptor()
                spec.vertexFunction=v
                spec.fragmentFunction=f
                spec.colorAttachments[0].pixelFormat = .bgra8Unorm
                spec.depthAttachmentPixelFormat = .depth32Float
                spec.colorAttachments[0].isBlendingEnabled=true
                spec.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                spec.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                pipeline=try device.makeRenderPipelineState(descriptor:spec)
                let ds=MTLDepthStencilDescriptor()
                ds.depthCompareFunction = .lessEqual
                ds.isDepthWriteEnabled=true
                guard let d=device.makeDepthStencilState(descriptor:ds)
                else {throw SourceError.metal}
                depth=d
                super.init()
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
            func mtkView(_ view:MTKView,drawableSizeWillChange size:CGSize) {}
            func draw(in view:MTKView) {
                guard let drawable=view.currentDrawable,
                      let pass=view.currentRenderPassDescriptor,
                      let command=queue.makeCommandBuffer(),
                      let encoder=command.makeRenderCommandEncoder(descriptor:pass)
                else {return}
                let t=Float(ProcessInfo.processInfo.systemUptime-started)
                var model=matrix_identity_float4x4
                model.columns.3.z = -5
                model=model*Self.rotateX(-0.24)*Self.rotateY(t*0.22)
                let size=view.drawableSize
                let aspect=Float(max(1,size.width)/max(1,size.height))
                var uniforms=Uniforms(mvp:Self.previewMVP(aspect,model),
                                      model:model)
                encoder.setRenderPipelineState(pipeline)
                encoder.setDepthStencilState(depth)
                encoder.setCullMode(.none)
                encoder.setVertexBuffer(vertexBuffer,offset:0,index:0)
                encoder.setFragmentTexture(base,index:0)
                encoder.setFragmentTexture(emissive,index:1)
                encoder.setFragmentTexture(irradiance,index:2)
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
                            "sourceMaterialGroups":2,"nativeMissionPlayable":false
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
                command.commit()
            }
        }
    }
}
