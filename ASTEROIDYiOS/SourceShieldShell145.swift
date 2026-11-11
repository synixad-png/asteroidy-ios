import Foundation
import Metal
import simd

/// Native translucent plasma shell around the exact source Vanguard431 craft.
///
/// Tarcza145's existing simulation owns energy, held state and impact flash.
/// This class only renders that already-authoritative state. Geometry bounds
/// are measured once from the actual validated source GPU mesh; the effect
/// shares the original ship model transform and never changes its collision.
final class SourceShieldShell145 {
    enum Failure:Error {case invalidMesh,missingShader}
    struct Bounds {
        let center:SIMD3<Float>
        let radius:Float
    }
    private struct Uniforms {
        var mvp:simd_float4x4
        var model:simd_float4x4
        var centerRadius:SIMD4<Float>
        var cameraTime:SIMD4<Float>
        var state:SIMD4<Float>
    }
    private let pipeline:MTLRenderPipelineState
    let bounds:Bounds
    static let vertexCount=48*24*6

    /// SourceVanguardMesh431: original CPU/GPU float stream has 12 floats
    /// per vertex (48 bytes) and xyz are first. Two bounded scans only at
    /// scene initialization, never during the 60 FPS rendering loop.
    static func measure(_ source:Data)->Bounds? {
        let stride=SourceVanguardMesh431.bytesPerVertex
        guard source.count>=stride*3,source.count%stride==0 else{return nil}
        return source.withUnsafeBytes {raw -> Bounds? in
            func point(_ idx:Int)->SIMD3<Float> {
                let offset=idx*stride
                return SIMD3(
                    raw.loadUnaligned(fromByteOffset:offset,as:Float.self),
                    raw.loadUnaligned(fromByteOffset:offset+4,as:Float.self),
                    raw.loadUnaligned(fromByteOffset:offset+8,as:Float.self))
            }
            var low=SIMD3<Float>(repeating:Float.greatestFiniteMagnitude)
            var high=SIMD3<Float>(repeating:-Float.greatestFiniteMagnitude)
            for i in 0..<(source.count/stride) {
                let p=point(i)
                guard p.x.isFinite,p.y.isFinite,p.z.isFinite else{return nil}
                low=simd_min(low,p)
                high=simd_max(high,p)
            }
            let center=(low+high)*0.5
            var squared:Float=0
            for i in 0..<(source.count/stride) {
                let delta=point(i)-center
                squared=max(squared,simd_length_squared(delta))
            }
            let radius=sqrt(squared)
            guard radius.isFinite,radius>0.001 else{return nil}
            return Bounds(center:center,radius:radius*1.18)
        }
    }

    init(device:MTLDevice,library:MTLLibrary,sourceMesh:Data) throws {
        guard let b=Self.measure(sourceMesh) else {throw Failure.invalidMesh}
        guard let vertex=library.makeFunction(name:"shieldShellVertex145"),
              let fragment=library.makeFunction(name:"shieldShellFragment145")
        else {throw Failure.missingShader}
        let spec=MTLRenderPipelineDescriptor()
        spec.label="Tarcza145 source Vanguard translucent plasma dome"
        spec.vertexFunction=vertex
        spec.fragmentFunction=fragment
        spec.colorAttachments[0].pixelFormat = .bgra8Unorm
        spec.depthAttachmentPixelFormat = .depth32Float
        spec.colorAttachments[0].isBlendingEnabled=true
        spec.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        spec.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        spec.colorAttachments[0].sourceAlphaBlendFactor = .one
        spec.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipeline=try device.makeRenderPipelineState(descriptor:spec)
        bounds=b
    }

    func draw(encoder:MTLRenderCommandEncoder,
              viewProjection:simd_float4x4,
              shipMatrix:simd_float4x4,
              cameraEye:SphereVector3,
              time:Float,energy:Float,flash:Float) {
        guard energy>0,energy.isFinite,time.isFinite else{return}
        var uniform=Uniforms(
            mvp:viewProjection*shipMatrix,
            model:shipMatrix,
            centerRadius:SIMD4(bounds.center,bounds.radius),
            cameraTime:SIMD4(cameraEye.x,cameraEye.y,cameraEye.z,time),
            state:SIMD4(min(1,max(0,energy/SourceTarcza145.maximum)),
                        min(0.37,max(0,flash)),0,0))
        encoder.setRenderPipelineState(pipeline)
        encoder.setCullMode(.none)
        encoder.setVertexBytes(&uniform,
            length:MemoryLayout<Uniforms>.stride,index:0)
        encoder.drawPrimitives(type:.triangle,vertexStart:0,
                               vertexCount:Self.vertexCount)
    }
}
