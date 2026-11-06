import Foundation
import CryptoKit
import MetalKit
import simd
import SwiftUI

/// Actual NewHome290 GLB-derived source globe rendered in Metal for W3 HOME.
/// Exact 172208 original triangles and source texture/glow are SHA-pinned.
/// Source W3 uses an orthographic preview (GpuW3HomeReal333.cs: halfH=1.72,
/// z=-6, X=-18deg + pitch, Y=yaw). Menu layout and world state are independent.
struct W3HomePlanetMetal568: UIViewRepresentable {
    var yaw: Float
    var pitch: Float

    static let isAvailable: Bool = {
        ["W3HomePlanet290OriginalGPU.bin","W3HomePlanet290Base.dat",
         "W3HomePlanet293Glow.dat"].allSatisfy { name in
            let url=Bundle.main.url(forResource:
                    String(name.split(separator: ".")[0]),
                    withExtension:String(name.split(separator: ".").last ?? ""))
                ?? Bundle.main.url(
                    forResource:String(name.split(separator: ".")[0]),
                    withExtension:String(name.split(separator: ".").last ?? ""),
                    subdirectory:"Assets")
            return url != nil
        }
    }()

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> MTKView {
        let view=MTKView(frame:.zero,device:MTLCreateSystemDefaultDevice())
        view.isOpaque=false
        view.backgroundColor = .clear
        view.clearColor=MTLClearColor(red:0,green:0,blue:0,alpha:0)
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.preferredFramesPerSecond=30
        view.framebufferOnly=true
        if let device=view.device {
            do {
                let renderer=try Coordinator.Renderer(device:device)
                renderer.yaw=yaw
                renderer.pitch=pitch
                context.coordinator.renderer=renderer
                view.delegate=renderer
            } catch {
                NSLog("ASTEROIDY W3 original NewHome290 rejected: %@",
                      String(describing:error))
            }
        }
        return view
    }

    func updateUIView(_ view: MTKView,context:Context) {
        context.coordinator.renderer?.yaw=yaw
        context.coordinator.renderer?.pitch=pitch
    }

    final class Coordinator {
        var renderer: Renderer?

        final class Renderer: NSObject,MTKViewDelegate {
            enum SourceError: Error {case missing,invalid,metal}
            private let device: MTLDevice
            private let queue: MTLCommandQueue
            private let pipeline: MTLRenderPipelineState
            private let depth: MTLDepthStencilState
            private let vertices: MTLBuffer
            private let baseTexture: MTLTexture
            private let glowTexture: MTLTexture
            private let started = ProcessInfo.processInfo.systemUptime
            private var proofScheduled=false
            var yaw:Float=0
            var pitch:Float=0

            static let sourceGPU_SHA256 =
                "e93a0bbafc9bb50a25726a828ada81f36675bf88d802c5a8f985b89b6dc96c1b"
            static let baseSHA256 =
                "4987f35cd6f021fd98794f406c641f4853c538a82b10625e6b79e860c8a787c0"
            static let glowSHA256 =
                "6f1debd175f52b7ce1fbc687e9977597335ee432858d7d6d6e47cf66b5f9aa39"
            static func digest(_ data:Data) -> String {
                SHA256.hash(data:data).map {String(format:"%02x",$0)}.joined()
            }
            static func resource(_ name:String,_ ext:String,_ sha:String)
                throws -> Data {
                let url=Bundle.main.url(forResource:name,withExtension:ext)
                    ?? Bundle.main.url(forResource:name,withExtension:ext,
                                       subdirectory:"Assets")
                guard let file=url,let data=try? Data(contentsOf:file)
                else {throw SourceError.missing}
                guard digest(data)==sha else {throw SourceError.invalid}
                return data
            }

            init(device:MTLDevice) throws {
                self.device=device
                guard let q=device.makeCommandQueue() else {throw SourceError.metal}
                queue=q
                let bytes=try Self.resource(
                    "W3HomePlanet290OriginalGPU","bin",Self.sourceGPU_SHA256)
                guard bytes.count==516_624*48 else {throw SourceError.invalid}
                guard let mesh=bytes.withUnsafeBytes({ raw in
                    raw.baseAddress.flatMap {
                        device.makeBuffer(bytes:$0,length:bytes.count,options:[])
                    }
                }) else {throw SourceError.metal}
                vertices=mesh
                let baseData=try Self.resource(
                    "W3HomePlanet290Base","dat",Self.baseSHA256)
                let glowData=try Self.resource(
                    "W3HomePlanet293Glow","dat",Self.glowSHA256)
                let loader=MTKTextureLoader(device:device)
                baseTexture=try loader.newTexture(
                    data:baseData,options:[.SRGB:false,.generateMipmaps:false,
                                          .origin:MTKTextureLoader.Origin.topLeft])
                glowTexture=try loader.newTexture(
                    data:glowData,options:[.SRGB:false,.generateMipmaps:false,
                                          .origin:MTKTextureLoader.Origin.topLeft])
                let library=try device.makeDefaultLibrary(bundle:.main)
                guard let vertex=library.makeFunction(name:"w3Home290Vertex"),
                      let fragment=library.makeFunction(name:"w3Home290Fragment")
                else {throw SourceError.metal}
                let desc=MTLRenderPipelineDescriptor()
                desc.vertexFunction=vertex
                desc.fragmentFunction=fragment
                desc.colorAttachments[0].pixelFormat = .bgra8Unorm
                desc.depthAttachmentPixelFormat = .depth32Float
                desc.colorAttachments[0].isBlendingEnabled=true
                desc.colorAttachments[0].rgbBlendOperation = .add
                desc.colorAttachments[0].alphaBlendOperation = .add
                desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                desc.colorAttachments[0].sourceAlphaBlendFactor = .one
                desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
                pipeline=try device.makeRenderPipelineState(descriptor:desc)
                let ds=MTLDepthStencilDescriptor()
                ds.depthCompareFunction = .lessEqual
                ds.isDepthWriteEnabled=true
                guard let depthState=device.makeDepthStencilState(descriptor:ds)
                else {throw SourceError.metal}
                depth=depthState
                super.init()
            }

            private struct Uniforms {
                var mvp:simd_float4x4
                var model:simd_float4x4
                var material:UInt32=0
                var glowPower:Float=1.8
            }
            static func rotationX(_ a:Float)->simd_float4x4 {
                let c=cos(a),s=sin(a)
                return simd_float4x4(columns:(
                    SIMD4<Float>(1,0,0,0),SIMD4<Float>(0,c,s,0),
                    SIMD4<Float>(0,-s,c,0),SIMD4<Float>(0,0,0,1)))
            }
            static func rotationY(_ a:Float)->simd_float4x4 {
                let c=cos(a),s=sin(a)
                return simd_float4x4(columns:(
                    SIMD4<Float>(c,0,-s,0),SIMD4<Float>(0,1,0,0),
                    SIMD4<Float>(s,0,c,0),SIMD4<Float>(0,0,0,1)))
            }
            static func translationZ(_ z:Float)->simd_float4x4 {
                var m=matrix_identity_float4x4
                m.columns.3.z=z
                return m
            }
            static func orthographic(aspect:Float)->simd_float4x4 {
                let h:Float=1.72,near:Float=0.5,far:Float=32
                return simd_float4x4(columns:(
                    SIMD4<Float>(1/(h*max(0.35,aspect)),0,0,0),
                    SIMD4<Float>(0,1/h,0,0),
                    SIMD4<Float>(0,0,-1/(far-near),0),
                    SIMD4<Float>(0,0,-near/(far-near),1)))
            }
            func mtkView(_ view:MTKView,drawableSizeWillChange size:CGSize) {}
            func draw(in view:MTKView) {
                guard let drawable=view.currentDrawable,
                      let pass=view.currentRenderPassDescriptor,
                      let command=queue.makeCommandBuffer(),
                      let encoder=command.makeRenderCommandEncoder(descriptor:pass)
                else {return}
                let size=view.drawableSize
                let aspect=Float(max(1,size.width)/max(1,size.height))
                let elapsed=Float(ProcessInfo.processInfo.systemUptime-started)
                let model=Self.translationZ(-6)
                    * Self.rotationX(-18 * .pi/180)
                    * Self.rotationX(pitch)
                    * Self.rotationY(yaw + elapsed*0.19)
                let projection=Self.orthographic(aspect:aspect)
                var uniform=Uniforms(mvp:projection*model,model:model)
                encoder.setRenderPipelineState(pipeline)
                encoder.setDepthStencilState(depth)
                encoder.setCullMode(.none) // Do not drop unknown original front-face order.
                encoder.setVertexBuffer(vertices,offset:0,index:0)
                encoder.setFragmentTexture(baseTexture,index:0)
                encoder.setFragmentTexture(glowTexture,index:1)
                encoder.setVertexBytes(&uniform,length:MemoryLayout<Uniforms>.stride,index:1)
                encoder.setFragmentBytes(&uniform,length:MemoryLayout<Uniforms>.stride,index:1)
                encoder.drawPrimitives(type:.triangle,vertexStart:0,vertexCount:514_176)
                uniform.material=1
                encoder.setVertexBytes(&uniform,length:MemoryLayout<Uniforms>.stride,index:1)
                encoder.setFragmentBytes(&uniform,length:MemoryLayout<Uniforms>.stride,index:1)
                encoder.drawPrimitives(type:.triangle,vertexStart:514_176,vertexCount:2_448)
                encoder.endEncoding()
                command.present(drawable)
                if !proofScheduled &&
                    ProcessInfo.processInfo.environment["ASTEROIDY_W3_MENU_VERIFY"]=="1" {
                    proofScheduled=true
                    let w=baseTexture.width,h=baseTexture.height
                    command.addCompletedHandler { finished in
                        let proof:[String:Any]=[
                            "render":"NewHome290-source-v568-original-3D",
                            "gpuCommandBufferCompleted":finished.status == .completed,
                            "vertexCount":516624,"triangleCount":172208,
                            "materialGroups":2,
                            "baseTextureWidth":w,"baseTextureHeight":h,
                            "geometrySHA256":Self.sourceGPU_SHA256,
                            "baseSHA256":Self.baseSHA256,"glowSHA256":Self.glowSHA256,
                            "simulatorOnly":true
                        ]
                        if let dir=FileManager.default.urls(
                            for:.cachesDirectory,in:.userDomainMask).first,
                           let data=try? JSONSerialization.data(
                            withJSONObject:proof,options:[.sortedKeys]) {
                            try? data.write(to:dir.appendingPathComponent(
                                "ASTEROIDY_W3_NewHome290_GPUProof.json"),options:.atomic)
                        }
                    }
                }
                command.commit()
            }
        }
    }
}
