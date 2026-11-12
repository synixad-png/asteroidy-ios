import Foundation
import CryptoKit
import MetalKit
import simd
import SwiftUI

/// Source Vanguard431 (default Game.ShipType=1) in the small original W3
/// HOME "STATEK / PODGLĄD" panel (GpuW3HomeReal333.cs).
/// This is not a second mesh or a generated lookalike. It uses the very same
/// .mesh and JPEG already used for native Vanguard431 gameplay/intro.
struct W3HomeShipPreview568: UIViewRepresentable {
    static var isAvailable: Bool {
        func file(_ name: String,_ ext: String) -> URL? {
            Bundle.main.url(forResource:name,withExtension:ext)
                ?? Bundle.main.url(forResource:name,withExtension:ext,
                                   subdirectory:"Assets")
        }
        if H55SourceMechanics580.load().selectedShip==2 {
            return SourceBastion606.load() != nil
        }
        return file("Vanguard431Source","mesh") != nil
            && file("Vanguard431Base","jpg") != nil
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context:Context) -> MTKView {
        let view=MTKView(frame:.zero,device:MTLCreateSystemDefaultDevice())
        view.isOpaque=false
        view.backgroundColor = .clear
        view.clearColor=MTLClearColor(red:0,green:0,blue:0,alpha:0)
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.preferredFramesPerSecond = 30
        if let device=view.device {
            do {
                let renderer=try Coordinator.Renderer(device:device)
                view.delegate=renderer
                context.coordinator.renderer=renderer
            } catch {
                NSLog("ASTEROIDY v568 W3 source Vanguard431 unavailable: %@",
                      String(describing:error))
            }
        }
        return view
    }
    func updateUIView(_ view:MTKView,context:Context) {}

    final class Coordinator {
        var renderer: Renderer?
        final class Renderer: NSObject,MTKViewDelegate {
            enum SourceError: Error { case missing,badSHA,metal }
            private let gpu: MTLDevice
            private let commandQueue: MTLCommandQueue
            private let pipeline: MTLRenderPipelineState
            private let depthState: MTLDepthStencilState
            private let buffer: MTLBuffer
            private let count: Int
            private let base: MTLTexture
            private let selectedShip:Int
            private let started = ProcessInfo.processInfo.systemUptime
            private var proofScheduled=false

            private struct Uniforms {
                var mvp:simd_float4x4
                var model:simd_float4x4
                var eyeView:simd_float4x4
            }
            private static func verified(_ name:String,_ ext:String,
                                         _ sha:String) throws -> (Data,URL) {
                guard let url=Bundle.main.url(forResource:name,withExtension:ext)
                    ?? Bundle.main.url(forResource:name,withExtension:ext,
                                       subdirectory:"Assets"),
                      let bytes=try? Data(contentsOf:url)
                else {throw SourceError.missing}
                let hash=SHA256.hash(data:bytes)
                    .map{String(format:"%02x",$0)}.joined()
                guard hash==sha else {throw SourceError.badSHA}
                return (bytes,url)
            }
            init(device:MTLDevice) throws {
                gpu=device
                guard let queue=device.makeCommandQueue()
                else {throw SourceError.metal}
                commandQueue=queue
                selectedShip=H55SourceMechanics580.load().selectedShip
                let original:SourceBakedShipMesh
                let textureBytes:Data
                let textureURL:URL?
                if selectedShip==2 {
                    guard let bastion=SourceBastion606.load() else {
                        throw SourceError.missing
                    }
                    original=bastion.mesh
                    textureBytes=bastion.jpeg
                    textureURL=nil
                } else {
                    guard selectedShip==1 else{throw SourceError.missing}
                    let (source,_)=try Self.verified(
                        "Vanguard431Source","mesh",
                        SourceVanguardMesh431.exactMeshSHA256)
                    let (sourceJPEG,sourceURL)=try Self.verified(
                        "Vanguard431Base","jpg",
                        SourceVanguardMesh431.exactBaseJPEG_SHA256)
                    original=try SourceBakedShipMesh(data:source)
                    textureBytes=sourceJPEG
                    textureURL=sourceURL
                }
                guard let vb=original.vertices.withUnsafeBytes({
                    $0.baseAddress.flatMap {
                        device.makeBuffer(bytes:$0,
                                          length:original.vertices.count,
                                          options:[])
                    }
                }) else {throw SourceError.metal}
                buffer=vb
                count=original.vertexCount
                let textureLoader=MTKTextureLoader(device:device)
                let options:[MTKTextureLoader.Option:Any]=[
                    .SRGB:false,.generateMipmaps:false,
                    .origin:MTKTextureLoader.Origin.topLeft
                ]
                if let textureURL {
                    base=try textureLoader.newTexture(
                        URL:textureURL,options:options)
                } else {
                    base=try textureLoader.newTexture(
                        data:textureBytes,options:options)
                }
                guard !textureBytes.isEmpty else {throw SourceError.missing}
                let library=try device.makeDefaultLibrary(bundle:.main)
                guard let vertex=library.makeFunction(name:"sourceVanguardVertex431"),
                      let fragment=library.makeFunction(
                        name:"w3HomeVanguardFragment431")
                else {throw SourceError.metal}
                let desc=MTLRenderPipelineDescriptor()
                desc.vertexFunction=vertex
                desc.fragmentFunction=fragment
                desc.colorAttachments[0].pixelFormat = .bgra8Unorm
                desc.depthAttachmentPixelFormat = .depth32Float
                pipeline=try device.makeRenderPipelineState(descriptor:desc)
                let ds=MTLDepthStencilDescriptor()
                ds.depthCompareFunction = .lessEqual
                ds.isDepthWriteEnabled = true
                guard let depth=device.makeDepthStencilState(descriptor:ds)
                else {throw SourceError.metal}
                depthState=depth
                super.init()
            }
            private static func translation(_ x:Float,_ y:Float,_ z:Float)
                ->simd_float4x4 {
                var m=matrix_identity_float4x4
                m.columns.3=SIMD4<Float>(x,y,z,1)
                return m
            }
            private static func scale(_ value:Float)->simd_float4x4 {
                return simd_float4x4(diagonal:
                    SIMD4<Float>(value,value,value,1))
            }
            private static func rx(_ a:Float)->simd_float4x4 {
                let c=cos(a),s=sin(a)
                return simd_float4x4(columns:(
                    SIMD4<Float>(1,0,0,0),SIMD4<Float>(0,c,s,0),
                    SIMD4<Float>(0,-s,c,0),SIMD4<Float>(0,0,0,1)))
            }
            private static func ry(_ a:Float)->simd_float4x4 {
                let c=cos(a),s=sin(a)
                return simd_float4x4(columns:(
                    SIMD4<Float>(c,0,-s,0),SIMD4<Float>(0,1,0,0),
                    SIMD4<Float>(s,0,c,0),SIMD4<Float>(0,0,0,1)))
            }
            private static func rz(_ a:Float)->simd_float4x4 {
                let c=cos(a),s=sin(a)
                return simd_float4x4(columns:(
                    SIMD4<Float>(c,s,0,0),SIMD4<Float>(-s,c,0,0),
                    SIMD4<Float>(0,0,1,0),SIMD4<Float>(0,0,0,1)))
            }
            private static func perspective(_ aspect:Float)->simd_float4x4 {
                // GpuW3HomeReal333: near=1,far=28, zoom=.88, halfH=.33*.88.
                let near:Float=1,far:Float=28
                let halfH:Float=0.33*0.88
                let halfW=halfH*max(0.35,aspect)
                return simd_float4x4(columns:(
                    SIMD4<Float>(near/halfW,0,0,0),
                    SIMD4<Float>(0,near/halfH,0,0),
                    SIMD4<Float>(0,0,far/(near-far),-1),
                    SIMD4<Float>(0,0,far*near/(near-far),0)))
            }
            func mtkView(_ view:MTKView,
                         drawableSizeWillChange size:CGSize) {}
            func draw(in view:MTKView) {
                guard let drawable=view.currentDrawable,
                      let pass=view.currentRenderPassDescriptor,
                      let command=commandQueue.makeCommandBuffer(),
                      let encoder=command.makeRenderCommandEncoder(descriptor:pass)
                else {return}
                let elapsed=Float(ProcessInfo.processInfo.systemUptime-started)
                // EXACT original W3 preview pose for source ShipType=1.
                let model=Self.translation(0,-0.15,-5.5)
                    * Self.rx(18 * .pi/180)
                    * Self.ry(elapsed * 42 * .pi/180)
                    * Self.rz(sin(elapsed * 0.71) * 8 * .pi/180)
                    * Self.scale(0.34)
                let aspect = Float(max(1.0, view.drawableSize.width) / max(1.0, view.drawableSize.height))
                var uniforms=Uniforms(
                    mvp:Self.perspective(aspect)*model,model:model,
                    eyeView:matrix_identity_float4x4)
                encoder.setRenderPipelineState(pipeline)
                encoder.setDepthStencilState(depthState)
                encoder.setCullMode(.none)
                encoder.setVertexBuffer(buffer,offset:0,index:0)
                encoder.setVertexBytes(&uniforms,
                    length:MemoryLayout<Uniforms>.stride,index:1)
                encoder.setFragmentTexture(base,index:0)
                encoder.drawPrimitives(type:.triangle,
                    vertexStart:0,vertexCount:count)
                encoder.endEncoding()
                command.present(drawable)
                if !proofScheduled &&
                    ProcessInfo.processInfo.environment[
                        "ASTEROIDY_W3_MENU_VERIFY"]=="1" {
                    proofScheduled=true
                    let originalCount=count
                    let id=selectedShip
                    command.addCompletedHandler { result in
                        let obj:[String:Any]=[
                            "source":id==2 ? "Bastion-PC609-ShipType2" :
                                "Vanguard431-default-ShipType1-v568",
                            "gpuCommandBufferCompleted":result.status == .completed,
                            "vertexCount":originalCount,
                            "meshSHA256":id==2 ? SourceBastion606.meshSHA256 :
                                SourceVanguardMesh431.exactMeshSHA256,
                            "skinSHA256":id==2 ? SourceBastion606.jpegSHA256 :
                                SourceVanguardMesh431.exactBaseJPEG_SHA256,
                            "originalW3PreviewScale":0.34,
                            "simulatorOnly":true
                        ]
                        OriginalRenderProofWriter568.save(
                            obj,filename:id==2 ? "ASTEROIDY_W3_Bastion606_GPUProof.json" :
                                        "ASTEROIDY_W3_Vanguard431_GPUProof.json")
                    }
                }
                command.commit()
            }
        }
    }
}
