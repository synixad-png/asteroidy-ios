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
        view.isOpaque=false
        view.backgroundColor = .clear
        view.clearColor=MTLClearColor(red:0,green:0,blue:0,alpha:0)
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
            private var rockBuffers: [Int:MTLBuffer] = [:]
            private var activeRocks: [SphereAsteroid556]
            private var previousRockFrame: TimeInterval?
            private let depth:MTLDepthStencilState
            private let vertexBuffer:MTLBuffer
            private let indexBuffer:MTLBuffer
            private let base:MTLTexture
            private let emissive:MTLTexture
            private let irradiance:MTLTexture
            private let started=ProcessInfo.processInfo.systemUptime
            private let gameSession:CarbonisSession568?
            private var craftBuffer:MTLBuffer?
            private var craftTexture:MTLTexture?
            private var craftVertexCount=0
            private var craftPipeline:MTLRenderPipelineState?
            private var tracerPipeline:MTLRenderPipelineState?
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
                      let f=library.makeFunction(name:"sector01CarbonisFragment568"),
                      let rockFragment=library.makeFunction(name:"sector01SourceRockFragment568")
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
                let rockSpec=MTLRenderPipelineDescriptor()
                rockSpec.vertexFunction=v
                rockSpec.fragmentFunction=rockFragment
                rockSpec.colorAttachments[0].pixelFormat = .bgra8Unorm
                rockSpec.depthAttachmentPixelFormat = .depth32Float
                rockPipeline=try device.makeRenderPipelineState(descriptor:rockSpec)
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
                    if let tracer=library.makeFunction(name:"sector01CombatTracer568") {
                        let tracerSpec=MTLRenderPipelineDescriptor()
                        tracerSpec.vertexFunction=v
                        tracerSpec.fragmentFunction=tracer
                        tracerSpec.colorAttachments[0].pixelFormat = .bgra8Unorm
                        tracerSpec.depthAttachmentPixelFormat = .depth32Float
                        tracerPipeline=try device.makeRenderPipelineState(
                            descriptor:tracerSpec)
                    }
                }
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
                return placement*rotateX(rock.angle*41*degrees)
                    * rotateY(rock.angle*23*degrees)
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
                let projection=simd_float4x4(columns:(
                    SIMD4<Float>(focal/max(0.35,aspect),0,0,0),
                    SIMD4<Float>(0,focal,0,0),
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
                return base*rotateY(flight.flight.visualBank*Float.pi/180)
                    * rotateX(flight.flight.visualPitch*Float.pi/180)
            }
            func mtkView(_ view:MTKView,drawableSizeWillChange size:CGSize) {}
            func draw(in view:MTKView) {
                guard let drawable=view.currentDrawable,
                      let pass=view.currentRenderPassDescriptor,
                      let command=queue.makeCommandBuffer(),
                      let encoder=command.makeRenderCommandEncoder(descriptor:pass)
                else {return}
                let now=ProcessInfo.processInfo.systemUptime
                if let session=gameSession {
                    session.frame(at:now)
                    activeRocks=session.game.rocks
                } else if let previous=previousRockFrame {
                    let dt=Float(min(0.05,max(0,now-previous)))
                    for index in activeRocks.indices {activeRocks[index].advance(dt:dt)}
                }
                previousRockFrame=now
                let t=Float(now-started)
                var model=matrix_identity_float4x4
                if gameSession == nil {
                    model.columns.3.z = -5
                    model=model*Self.rotateX(-0.24+pitchOffset)
                        * Self.rotateY(t*0.22+yawOffset)
                }
                let size=view.drawableSize
                let aspect=Float(max(1,size.width)/max(1,size.height))
                let vp:simd_float4x4?=gameSession.map {
                    Self.viewProjection($0.game.flight.camera,aspect:aspect)
                }
                var uniforms=Uniforms(mvp:vp.map{$0*model} ??
                                      Self.previewMVP(aspect,model),
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

                // Original Game.Wave asteroid shapes, not billboard/GLB stand-ins.
                // C279 stays unchanged; rock meshes share one cached VBO per shape.
                if !activeRocks.isEmpty {
                    encoder.setRenderPipelineState(rockPipeline)
                    for rock in activeRocks {
                        let shape=CarbonisRockGeometry568.shape(for:rock)
                        guard let buffer=rockBuffers[shape] else {continue}
                        let rockMatrix=model*Self.sourceRockModel(rock)
                        uniforms=Uniforms(mvp:vp.map{$0*rockMatrix} ??
                                          Self.previewMVP(aspect,rockMatrix),
                                          model:rockMatrix,material:2,glow:0)
                        encoder.setVertexBuffer(buffer,offset:0,index:0)
                        encoder.setVertexBytes(&uniforms,
                            length:MemoryLayout<Uniforms>.stride,index:1)
                        encoder.setFragmentBytes(&uniforms,
                            length:MemoryLayout<Uniforms>.stride,index:1)
                        encoder.drawPrimitives(type:.triangle,vertexStart:0,
                            vertexCount:CarbonisRockGeometry568.sourceVertexCount)
                    }
                }
                // Render the exact default VANGUARD v568 craft alongside
                // its moving CARBONIS sphere; use real source mesh and UV.
                if let session=gameSession,
                   let buffer=craftBuffer,
                   let texture=craftTexture,
                   let fighterPipeline=craftPipeline,
                   let worldView=vp {
                    let shipMatrix=Self.craftModel(session.game.flight)
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
                            "sourceRockMeshes":activeRocks.count,
                            "sourceRockMeshVerticesPerObject":CarbonisRockGeometry568.sourceVertexCount,
                            "sourceRockUpdateRoutine":"SphereAsteroid556.advance",
                            "enemyAIIntegrated":false,
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
                command.commit()
            }
        }
    }
}
