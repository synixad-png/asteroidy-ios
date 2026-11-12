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
    private struct PlasmaUniforms491 {
        var mvp:simd_float4x4
        var engine0:SIMD4<Float>
        var engine1:SIMD4<Float>
        var timePowerSideSize:SIMD4<Float>
    }
    let shipType:Int
    private let pipeline:MTLRenderPipelineState
    private let plasmaPipeline:MTLRenderPipelineState
    private let depth:MTLDepthStencilState
    private let plasmaDepth:MTLDepthStencilState
    private let engine0:SIMD4<Float>
    private let engine1:SIMD4<Float>
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

    init(device:MTLDevice,shipType:Int=1) throws {
        guard shipType==1 || shipType==2 else{throw SourceError.missing}
        self.shipType=shipType
        let baked:SourceBakedShipMesh
        let skinURL:URL?
        let skinData:Data
        if shipType==2 {
            guard let bastion=SourceBastion606.load() else {
                throw SourceError.missing
            }
            baked=bastion.mesh
            skinData=bastion.jpeg
            skinURL=nil
        } else {
            let (originalMesh,_)=try Self.verified(
                "Vanguard431Source","mesh",
                SourceVanguardMesh431.exactMeshSHA256)
            let (originalSkin,originalSkinURL)=try Self.verified(
                "Vanguard431Base","jpg",
                SourceVanguardMesh431.exactBaseJPEG_SHA256)
            baked=try SourceBakedShipMesh(data:originalMesh)
            skinData=originalSkin
            skinURL=originalSkinURL
        }
        guard !skinData.isEmpty else{throw SourceError.missing}
        guard baked.engines.count==2 else {throw SourceError.missing}
        engine0=SIMD4(baked.engines[0].x,baked.engines[0].y,
                      baked.engines[0].z,0)
        engine1=SIMD4(baked.engines[1].x,baked.engines[1].y,
                      baked.engines[1].z,0)
        count=baked.vertexCount
        guard let vertex=baked.vertices.withUnsafeBytes({ raw in
            raw.baseAddress.flatMap {
                device.makeBuffer(bytes:$0,length:raw.count,options:[])
            }
        }) else {throw SourceError.metal}
        buffer=vertex
        let loader=MTKTextureLoader(device:device)
        let opts:[MTKTextureLoader.Option:Any]=[
            .SRGB:false,.generateMipmaps:false,
            .origin:MTKTextureLoader.Origin.topLeft
        ]
        if let skinURL {
            texture=try loader.newTexture(URL:skinURL,options:opts)
        } else {
            texture=try loader.newTexture(data:skinData,options:opts)
        }
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
        guard let plasmaVertex=library.makeFunction(
                name:"pc602HomePlasmaVertex491"),
              let plasmaFragment=library.makeFunction(
                name:"pc602HomePlasmaFragment491")
        else {throw SourceError.metal}
        let exhaust=MTLRenderPipelineDescriptor()
        exhaust.vertexFunction=plasmaVertex
        exhaust.fragmentFunction=plasmaFragment
        exhaust.colorAttachments[0].pixelFormat = .bgra8Unorm
        exhaust.depthAttachmentPixelFormat = .depth32Float
        exhaust.colorAttachments[0].isBlendingEnabled=true
        exhaust.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        exhaust.colorAttachments[0].destinationRGBBlendFactor = .one
        exhaust.colorAttachments[0].sourceAlphaBlendFactor = .one
        exhaust.colorAttachments[0].destinationAlphaBlendFactor = .one
        plasmaPipeline=try device.makeRenderPipelineState(descriptor:exhaust)
        let noWrite=MTLDepthStencilDescriptor()
        noWrite.depthCompareFunction = .lessEqual
        noWrite.isDepthWriteEnabled=false
        guard let shallow=device.makeDepthStencilState(descriptor:noWrite)
        else {throw SourceError.metal}
        plasmaDepth=shallow
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
        guard flight.equipment.craft.rawValue==shipType,
              let pose=PC602HomeShipPose291.active(
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

        // Original GpuShip.cs:19-63, not a billboard approximation:
        // two source-authenticated engine sockets, three independently
        // travelling layers and three crossing planes in each plume.
        // Vertex positions are generated by the Metal vertex program
        // from the current source time/power, NEVER on the Swift CPU.
        let sourcePower=max(0.12,flight.flight.flight.visualPower)
        var plasma=PlasmaUniforms491(
            mvp:projection*view*model,
            engine0:engine0,engine1:engine1,
            timePowerSideSize:SIMD4(flight.orbitTime,sourcePower,
                                    flight.sideThrust,1.06))
        encoder.setRenderPipelineState(plasmaPipeline)
        encoder.setDepthStencilState(plasmaDepth)
        encoder.setVertexBytes(&plasma,
            length:MemoryLayout<PlasmaUniforms491>.stride,index:0)
        encoder.drawPrimitives(type:.triangle,vertexStart:0,
                               vertexCount:1728)
        if abs(flight.sideThrust)>0.0001 {
            encoder.drawPrimitives(type:.triangle,vertexStart:1728,
                                   vertexCount:24)
        }
    }
}
