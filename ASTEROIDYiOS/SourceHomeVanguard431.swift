import Foundation
import CryptoKit
import MetalKit
import simd

/// REAL original PC v602 Vanguard431 ShipType=1 in HomeScene291.
/// Source proof: original v602 Vanguard431.Mesh gzip decompresses to
/// SHA256 f5d6d0107437fa54c3e8505f9adfbf6143cc877cb970eef687603609e26f9f4a;
/// its BaseColor JPEG SHA256 is 2945f711a6b559bfb5fdfb79750a2f2f77e2071aa5f3f4173eb450bce81b8b95.
/// The same two authentic assets were already staged for native W3 preview;
/// no replacement/GLB copy or second vertex decoder is added.
///
/// PC Vanguard431.TryApply puts *all* GPU vertices in material group 0.
/// Therefore the exact existing sourceVanguardVertex431 and
/// sourceVanguardTexturedToonFragment431 cover the full original hull.
///
/// Current scope: actual geometry/UV/baseColor/toon and game-driven pose.
/// The original GpuShip.DrawFighterMesh plasma jets and
/// DrawCraftModules95 remain separate, explicitly unported passes.
final class SourceHomeVanguard431 {
    enum SourceError:Error {case missing,checksum,metal}
    private struct Uniforms {
        var mvp:simd_float4x4
        var model:simd_float4x4
        var eyeView:simd_float4x4
    }
    private let pipeline:MTLRenderPipelineState
    private let depth:MTLDepthStencilState
    private let buffer:MTLBuffer
    private let texture:MTLTexture
    private let count:Int

    private static func verified(_ name:String,_ ext:String,
                                 _ expected:String) throws->(Data,URL) {
        guard let url=Bundle.main.url(forResource:name,withExtension:ext)
            ?? Bundle.main.url(forResource:name,withExtension:ext,
                               subdirectory:"Assets"),
              let bytes=try? Data(contentsOf:url)
        else {throw SourceError.missing}
        let hash=SHA256.hash(data:bytes).map {
            String(format:"%02x",$0)
        }.joined()
        guard hash==expected else {throw SourceError.checksum}
        return (bytes,url)
    }

    init(device:MTLDevice) throws {
        let (originalMesh,_)=try Self.verified(
            "Vanguard431Source","mesh",
            SourceVanguardMesh431.exactMeshSHA256)
        let (originalSkin,skinURL)=try Self.verified(
            "Vanguard431Base","jpg",
            SourceVanguardMesh431.exactBaseJPEG_SHA256)
        guard !originalSkin.isEmpty else {throw SourceError.missing}
        let baked=try SourceVanguardMesh431(data:originalMesh)
        count=baked.vertexCount
        guard let vertex=baked.vertices.withUnsafeBytes({ raw in
            raw.baseAddress.flatMap {
                device.makeBuffer(bytes:$0,length:raw.count,options:[])
            }
        }) else {throw SourceError.metal}
        buffer=vertex
        texture=try MTKTextureLoader(device:device).newTexture(
            URL:skinURL,options:[
                .SRGB:false,.generateMipmaps:false,
                .origin:MTKTextureLoader.Origin.topLeft
            ])
        let library=try device.makeDefaultLibrary(bundle:.main)
        guard let vert=library.makeFunction(name:"sourceVanguardVertex431"),
              let frag=library.makeFunction(
                name:"sourceVanguardTexturedToonFragment431")
        else {throw SourceError.metal}
        let descriptor=MTLRenderPipelineDescriptor()
        descriptor.vertexFunction=vert
        descriptor.fragmentFunction=frag
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.colorAttachments[0].isBlendingEnabled=false
        pipeline=try device.makeRenderPipelineState(descriptor:descriptor)
        let stencil=MTLDepthStencilDescriptor()
        stencil.depthCompareFunction = .lessEqual
        stencil.isDepthWriteEnabled=true
        guard let state=device.makeDepthStencilState(descriptor:stencil)
        else {throw SourceError.metal}
        depth=state
    }

    private static func matrix(_ m:[Float])->simd_float4x4? {
        guard m.count==16 && m.allSatisfy({$0.isFinite}) else{return nil}
        return simd_float4x4(columns:(
            SIMD4(m[0],m[1],m[2],m[3]),
            SIMD4(m[4],m[5],m[6],m[7]),
            SIMD4(m[8],m[9],m[10],m[11]),
            SIMD4(m[12],m[13],m[14],m[15])))
    }
    private static func rotateX(_ a:Float)->simd_float4x4 {
        let c=cos(a),s=sin(a)
        return simd_float4x4(columns:(
            SIMD4(1,0,0,0),SIMD4(0,c,s,0),
            SIMD4(0,-s,c,0),SIMD4(0,0,0,1)))
    }
    private static func rotateY(_ a:Float)->simd_float4x4 {
        let c=cos(a),s=sin(a)
        return simd_float4x4(columns:(
            SIMD4(c,0,-s,0),SIMD4(0,1,0,0),
            SIMD4(s,0,c,0),SIMD4(0,0,0,1)))
    }

    /// Source: sphereMatrix67 * RY(VisualBank) * RX(VisualPitch81).
    /// All actual physical controls continue to live in HomeFlight291.
    /// If the equipped craft is not the SHA-proven type 1, the source
    /// requires its OWN model; never show a Vanguard as Kestrel/Titan.
    func draw(encoder:MTLRenderCommandEncoder,
              flight:PC602HomeFlight291,
              projection:simd_float4x4,
              view:simd_float4x4,
              orbitScale:Float) {
        guard let pose=PC602HomeShipPose291.vanguard(
                  flight,orbitScale:orbitScale),
              let basis=Self.matrix(pose.basis) else{return}
        let bank=pose.bankDegrees*Float.pi/180
        let pitch=pose.pitchDegrees*Float.pi/180
        let model=basis*Self.rotateY(bank)*Self.rotateX(pitch)
        var data=Uniforms(mvp:projection*view*model,model:model,
                          eyeView:view)
        encoder.setRenderPipelineState(pipeline)
        encoder.setDepthStencilState(depth)
        encoder.setCullMode(.none)
        encoder.setVertexBuffer(buffer,offset:0,index:0)
        encoder.setVertexBytes(&data,length:MemoryLayout<Uniforms>.stride,
                               index:1)
        encoder.setFragmentTexture(texture,index:0)
        encoder.drawPrimitives(type:.triangle,vertexStart:0,
                               vertexCount:count)
    }
}
