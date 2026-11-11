import Foundation
import MetalKit
import simd
import SwiftUI

/// Dedicated GPU scene for the REAL PC v602 orbital NewHome290 terrain.
/// Not W3's miniature: full source 100x H290, OrbitWorld50.View camera and
/// GpuIntro41's .4/1600 frustum, with the original 2 GLB material groups.
/// The flight snapshot is supplied by PC602HomeFlight291, not a fake orbit
/// animation. No app/menu route is changed until the entire game mode exists.
struct PC602HomeScene291: UIViewRepresentable {
    var flight:PC602HomeFlight291

    func makeCoordinator()->Coordinator {Coordinator()}

    func makeUIView(context:Context)->MTKView {
        let view=MTKView(frame:.zero,device:MTLCreateSystemDefaultDevice())
        view.isOpaque=true
        view.clearColor=MTLClearColor(red:0.012,green:0.021,blue:0.04,alpha:1)
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.preferredFramesPerSecond=60
        view.framebufferOnly=true
        if let device=view.device {
            do {
                let renderer=try Coordinator.Renderer(device:device)
                renderer.flight=flight
                context.coordinator.renderer=renderer
                view.delegate=renderer
            } catch {
                NSLog("PC602 HomeScene291 rejected original GPU source: %@",
                      String(describing:error))
            }
        }
        return view
    }

    func updateUIView(_ view:MTKView,context:Context) {
        context.coordinator.renderer?.flight=flight
    }

    final class Coordinator {
        var renderer:Renderer?

        final class Renderer:NSObject,MTKViewDelegate {
            enum SourceError:Error {case metal,invalidCamera}
            let queue:MTLCommandQueue
            let pipeline:MTLRenderPipelineState
            let depth:MTLDepthStencilState
            let source:SourceNewHome290MetalAssets
            let lava287=SourceLavaLightSettings287.load()
            var flight:PC602HomeFlight291?

            init(device:MTLDevice) throws {
                guard let queue=device.makeCommandQueue() else {
                    throw SourceError.metal
                }
                self.queue=queue
                source=try SourceNewHome290MetalAssets.shared(device:device)
                let library=try device.makeDefaultLibrary(bundle:.main)
                guard let vertex=library.makeFunction(name:"home291Vertex"),
                      let fragment=library.makeFunction(name:"home291Fragment")
                else {throw SourceError.metal}
                let descriptor=MTLRenderPipelineDescriptor()
                descriptor.vertexFunction=vertex
                descriptor.fragmentFunction=fragment
                descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
                descriptor.depthAttachmentPixelFormat = .depth32Float
                // The source terrain GLB is opaque and depth-tested.
                descriptor.colorAttachments[0].isBlendingEnabled=false
                pipeline=try device.makeRenderPipelineState(descriptor:descriptor)
                let depthDescriptor=MTLDepthStencilDescriptor()
                depthDescriptor.depthCompareFunction = .lessEqual
                depthDescriptor.isDepthWriteEnabled=true
                guard let depth=device.makeDepthStencilState(
                    descriptor:depthDescriptor) else {throw SourceError.metal}
                self.depth=depth
                super.init()
            }

            private struct Uniforms {
                var mvp:simd_float4x4
                var model:simd_float4x4
                var material:UInt32=0
                var glowPower:Float=1.8
            }
            private struct Lighting {
                var eyeWorld:SIMD4<Float>
                var sourceKeyWorld:SIMD4<Float>
                var smooth65:UInt32=0
                var padding0:Float=0
                var padding1:Float=0
                var padding2:Float=0
            }

            private static func matrix(_ values:[Float])->simd_float4x4? {
                guard values.count==16 && values.allSatisfy({$0.isFinite})
                else {return nil}
                return simd_float4x4(columns:(
                    SIMD4(values[0],values[1],values[2],values[3]),
                    SIMD4(values[4],values[5],values[6],values[7]),
                    SIMD4(values[8],values[9],values[10],values[11]),
                    SIMD4(values[12],values[13],values[14],values[15])
                ))
            }

            func mtkView(_ view:MTKView,drawableSizeWillChange size:CGSize) {}

            func draw(in view:MTKView) {
                guard let flight,
                      let drawable=view.currentDrawable,
                      let renderPass=view.currentRenderPassDescriptor,
                      let command=queue.makeCommandBuffer()
                else{return}
                let size=view.drawableSize
                let aspect=Float(max(1,size.width)/max(1,size.height))
                guard let frame=PC602HomeWorldView291(
                    camera:flight.flight.camera,aspect:aspect),
                      let viewMatrix=Self.matrix(frame.view),
                      let projection=Self.matrix(frame.projection)
                else {
                    NSLog("PC602 HomeScene291 invalid source view projection")
                    return
                }

                // Windows GpuNewHome290: planetPush();shipScale(100,100,100).
                // The 24.8 MB original triangle stream is NEVER rebuilt.
                let model=simd_float4x4(diagonal:SIMD4(100,100,100,1))
                var uniforms=Uniforms(
                    mvp:projection*viewMatrix*model,model:model,
                    glowPower:lava287.intensity)
                // GpuShip.FighterLight(false) keyPosition=(-.6,.8,1.4,0);
                // light was specified in world units before GL model draw.
                var light=Lighting(
                    eyeWorld:SIMD4(frame.eye.x,frame.eye.y,frame.eye.z,1),
                    sourceKeyWorld:SIMD4(-0.6,0.8,1.4,0))
                renderPass.colorAttachments[0].loadAction = .clear
                renderPass.colorAttachments[0].clearColor =
                    MTLClearColor(red:0.012,green:0.021,blue:0.04,alpha:1)
                guard let encoder=command.makeRenderCommandEncoder(
                    descriptor:renderPass) else{return}
                encoder.setRenderPipelineState(pipeline)
                encoder.setDepthStencilState(depth)
                // HomeScene291 disables GL_CULL_FACE; preserve every
                // source triangle, regardless of original front-face order.
                encoder.setCullMode(.none)
                encoder.setVertexBuffer(source.vertices,offset:0,index:0)
                encoder.setFragmentTexture(source.base,index:0)
                encoder.setFragmentTexture(source.glow,index:1)
                encoder.setFragmentBytes(&light,
                    length:MemoryLayout<Lighting>.stride,index:2)
                encoder.setVertexBytes(&uniforms,
                    length:MemoryLayout<Uniforms>.stride,index:1)
                encoder.setFragmentBytes(&uniforms,
                    length:MemoryLayout<Uniforms>.stride,index:1)
                encoder.drawPrimitives(type:.triangle,vertexStart:0,
                    vertexCount:SourceNewHome290MetalAssets.terrainVertices)
                uniforms.material=1
                encoder.setVertexBytes(&uniforms,
                    length:MemoryLayout<Uniforms>.stride,index:1)
                encoder.setFragmentBytes(&uniforms,
                    length:MemoryLayout<Uniforms>.stride,index:1)
                encoder.drawPrimitives(type:.triangle,
                    vertexStart:SourceNewHome290MetalAssets.terrainVertices,
                    vertexCount:SourceNewHome290MetalAssets.armorVertices)
                encoder.endEncoding()
                command.present(drawable)
                command.commit()
            }
        }
    }
}
