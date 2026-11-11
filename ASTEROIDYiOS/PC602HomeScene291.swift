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
    // An actual gameplay host supplies exactly one physics step from
    // this MTKView render clock. Nil preserves source-only test previews.
    var onFrame:((TimeInterval)->PC602HomeFlight291?)? = nil
    var onRendererError:((String)->Void)? = nil

    func makeCoordinator()->Coordinator {Coordinator()}

    func makeUIView(context:Context)->MTKView {
        let view=MTKView(frame:.zero,device:SourceNewHome290MetalAssets.defaultDevice)
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
                renderer.onFrame=onFrame
                context.coordinator.renderer=renderer
                view.delegate=renderer
            } catch {
                let failure="PC602 HomeScene291: "+String(describing:error)
                NSLog("%@",failure)
                DispatchQueue.main.async {
                    onRendererError?(failure)
                }
            }
        }
        return view
    }

    func updateUIView(_ view:MTKView,context:Context) {
        context.coordinator.renderer?.flight=flight
        context.coordinator.renderer?.onFrame=onFrame
    }

    final class Coordinator {
        var renderer:Renderer?

        final class Renderer:NSObject,MTKViewDelegate {
            enum SourceError:Error {case metal,invalidCamera}
            let device:MTLDevice
            let queue:MTLCommandQueue
            let pipeline:MTLRenderPipelineState
            let beaconPipeline:MTLRenderPipelineState
            let beltPipeline:MTLRenderPipelineState
            let belt:PC602OrbitBelt51
            let beltBuffer:MTLBuffer
            let originalWreck:SourceHomeWreck209
            let originalShip:SourceHomeVanguard431
            let orbitVisualScale:Float
            let depth:MTLDepthStencilState
            let beaconDepth:MTLDepthStencilState
            let source:SourceNewHome290MetalAssets
            private var beaconBuffer:MTLBuffer?
            private var beaconCacheKey:(Int,Int)?
            let lava287=SourceLavaLightSettings287.load()
            var flight:PC602HomeFlight291?
            var onFrame:((TimeInterval)->PC602HomeFlight291?)?
            private var lastFrameTime:TimeInterval?

            init(device:MTLDevice) throws {
                guard let queue=device.makeCommandQueue() else {
                    throw SourceError.metal
                }
                self.device=device
                self.queue=queue
                source=try SourceNewHome290MetalAssets.shared(device:device)
                // Shares the existing source-verified full hull generator;
                // never invent a second partial GLB or duplicate debris.
                originalWreck=try SourceHomeWreck209(device:device)
                originalShip=try SourceHomeVanguard431(device:device)
                orbitVisualScale=SourceShipScale472.load().orbitFactor
                let originalBelt=try PC602OrbitBelt51.load()
                belt=originalBelt
                let geometryLength = originalBelt.vertexCount * PC602OrbitBelt51.vertexStride
                guard let beltGPU=originalBelt.sourceBytes.withUnsafeBytes({
                    raw in raw.baseAddress.flatMap { base in
                        device.makeBuffer(
                            bytes:base.advanced(by:originalBelt.vertexOffset),
                            length:geometryLength,options:[])
                    }
                }) else {throw SourceError.metal}
                beltBuffer=beltGPU
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
                guard let beaconVertex=library.makeFunction(name:"home291BeaconVertex"),
                      let beaconFragment=library.makeFunction(name:"home291BeaconFragment")
                else {throw SourceError.metal}
                let markers=MTLRenderPipelineDescriptor()
                markers.vertexFunction=beaconVertex
                markers.fragmentFunction=beaconFragment
                markers.colorAttachments[0].pixelFormat = .bgra8Unorm
                markers.depthAttachmentPixelFormat = .depth32Float
                markers.colorAttachments[0].isBlendingEnabled=true
                markers.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                markers.colorAttachments[0].destinationRGBBlendFactor = .one
                markers.colorAttachments[0].sourceAlphaBlendFactor = .one
                markers.colorAttachments[0].destinationAlphaBlendFactor = .one
                beaconPipeline=try device.makeRenderPipelineState(descriptor:markers)
                guard let rockVertex=library.makeFunction(name:"pc602Belt51Vertex"),
                      let rockFragment=library.makeFunction(name:"pc602Belt51Fragment")
                else {throw SourceError.metal}
                let rockDesc=MTLRenderPipelineDescriptor()
                rockDesc.vertexFunction=rockVertex
                rockDesc.fragmentFunction=rockFragment
                rockDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
                rockDesc.depthAttachmentPixelFormat = .depth32Float
                rockDesc.colorAttachments[0].isBlendingEnabled=false
                beltPipeline=try device.makeRenderPipelineState(
                    descriptor:rockDesc)
                let depthDescriptor=MTLDepthStencilDescriptor()
                depthDescriptor.depthCompareFunction = .lessEqual
                depthDescriptor.isDepthWriteEnabled=true
                guard let depth=device.makeDepthStencilState(
                    descriptor:depthDescriptor) else {throw SourceError.metal}
                self.depth=depth
                let beaconDescriptor=MTLDepthStencilDescriptor()
                beaconDescriptor.depthCompareFunction = .lessEqual
                // PC HomeScene291 disables depth writes for 26 additive lines.
                beaconDescriptor.isDepthWriteEnabled=false
                guard let markerDepth=device.makeDepthStencilState(
                    descriptor:beaconDescriptor) else {throw SourceError.metal}
                beaconDepth=markerDepth
                super.init()
            }

            private struct Uniforms {
                var mvp:simd_float4x4
                var model:simd_float4x4
                var material:UInt32=0
                var glowPower:Float=1.8
            }
            private struct BeltUniforms {
                var mvp:simd_float4x4
                var modelView:simd_float4x4
                var sourceLightEye:SIMD4<Float>
            }

            private struct Lighting {
                var sourceKeyEye:SIMD4<Float>
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
                let now=ProcessInfo.processInfo.systemUptime
                let elapsed=lastFrameTime.map { max(0,now-$0) } ?? 0
                lastFrameTime=now
                // Resume after background sleep must NOT teleport the ship.
                let step=elapsed<=0.15 ? min(elapsed,0.05) : 0
                let activeFlight=onFrame?(step) ?? flight
                guard let flight=activeFlight,
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
                // OpenGL gl_NormalMatrix and the specular view vector use
                // MODEL-VIEW coordinates (not untransformed world space).
                let modelView=viewMatrix*model
                var uniforms=Uniforms(
                    mvp:projection*modelView,model:modelView,
                    glowPower:lava287.intensity)
                // GpuShip.FighterLight(false) runs with OrbitWorld50.View
                // active; GL_LIGHT0 is therefore EYE-space, as in PC602.
                var light=Lighting(sourceKeyEye:SIMD4(-0.6,0.8,1.4,0))
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

                // Exact PC602 GpuIntro41.DrawIntroBelt(orbital135:true):
                // one immutable buffer, original 820 source-defined meshes,
                // original conservative camera-frustum culling, true 3.2x
                // world model. No asteroid can be replaced by an impostor.
                let rockModel=simd_float4x4(
                    diagonal:SIMD4(3.2,3.2,3.2,1))
                let rockMV=viewMatrix*rockModel
                var rockUniform=BeltUniforms(
                    mvp:projection*rockMV,modelView:rockMV,
                    sourceLightEye:SIMD4(-0.6,0.8,1.4,0))
                encoder.setRenderPipelineState(beltPipeline)
                encoder.setDepthStencilState(depth)
                encoder.setVertexBuffer(beltBuffer,offset:0,index:0)
                encoder.setVertexBytes(&rockUniform,
                    length:MemoryLayout<BeltUniforms>.stride,index:1)
                encoder.setFragmentBytes(&rockUniform,
                    length:MemoryLayout<BeltUniforms>.stride,index:1)
                // Source DrawIntroBelt(true) uses glMultiDrawArrays.
                // In Metal, consecutive visible source ranges are merged
                // without copying a single vertex or allocating a list per
                // frame. All-visible (820 stones) uses ONE GPU draw call;
                // a partly occluded belt retains the exact original set.
                var runStart=0
                var runCount=0
                for stone in belt.stones {
                    if belt.visible(stone,view:frame.view,aspect:aspect) {
                        if runCount==0 {
                            runStart=stone.firstVertex
                            runCount=stone.vertexCount
                        } else if runStart+runCount==stone.firstVertex {
                            runCount+=stone.vertexCount
                        } else {
                            encoder.drawPrimitives(type:.triangle,
                                vertexStart:runStart,vertexCount:runCount)
                            runStart=stone.firstVertex
                            runCount=stone.vertexCount
                        }
                    } else if runCount>0 {
                        encoder.drawPrimitives(type:.triangle,
                            vertexStart:runStart,vertexCount:runCount)
                        runCount=0
                    }
                }
                if runCount>0 {
                    encoder.drawPrimitives(type:.triangle,
                        vertexStart:runStart,vertexCount:runCount)
                }

                // Exact PC602 HomeScene291 draws the whole authored research
                // wreck AFTER the original 820-rock belt, BEFORE the 26
                // mission beacons. The same H290 source WreckPosition is
                // also used by Hub90.CanDock90; never relocate either.
                originalWreck.draw(encoder:encoder,projection:projection,
                    view:viewMatrix,dock:flight.dockPosition,
                    time:flight.orbitTime)

                // CPU marker geometry changes ONLY when campaign progress or
                // the chosen destination changes; never rebuild 26 rings
                // every render frame. All positions use original H290 heights.
                let key=(flight.target,flight.completedMask)
                if beaconCacheKey?.0 != key.0 || beaconCacheKey?.1 != key.1 {
                    beaconCacheKey=key
                    if let lines=PC602HomeBeacons291.vertices(
                        home:flight.home,selected:key.0,completedMask:key.1) {
                        beaconBuffer=lines.withUnsafeBytes { raw in
                            raw.baseAddress.flatMap {
                                device.makeBuffer(bytes:$0,length:raw.count,options:[])
                            }
                        }
                    } else {beaconBuffer=nil}
                }
                if let beaconBuffer {
                    var vp=projection*viewMatrix
                    encoder.setRenderPipelineState(beaconPipeline)
                    encoder.setDepthStencilState(beaconDepth)
                    encoder.setVertexBuffer(beaconBuffer,offset:0,index:0)
                    encoder.setVertexBytes(&vp,
                        length:MemoryLayout<simd_float4x4>.stride,index:1)
                    encoder.drawPrimitives(type:.line,vertexStart:0,
                        vertexCount:PC602HomeBeacons291.levels * PC602HomeBeacons291.verticesPerLevel)
                }
                // Original HomeScene291 draws the source 4311 fighter AFTER
                // beacons, with depth write and actual live DirectFlight298
                // visual heading/roll/pitch (no ship-shaped impostor).
                originalShip.draw(encoder:encoder,flight:flight,
                    projection:projection,view:viewMatrix,
                    orbitScale:orbitVisualScale)
                encoder.endEncoding()
                command.present(drawable)
                command.commit()
            }
        }
    }
}
