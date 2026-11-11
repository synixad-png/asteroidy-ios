import Foundation
import MetalKit
import simd

/// The ACTUAL orbital PC602 research wreck, not a fabricated GLB.
/// Geometry is reused verbatim from the already verified combat
/// ResearchWreckGeometry214 source transcription. Orbit-specific changes:
/// seed=211, debris=146, trail=178; the entire authored hull is unchanged.
///
/// PC602 GpuIntro41.DrawOrbitResearchWreck209 transform order:
/// T(NewHome290.WreckPosition) * Ry(31deg) * Rz(-9deg) * Scale(.6048).
/// The source's GL state disables culling/blending, enables depth test and
/// writes depth. Reuse the existing battle-wreck Metal functions and vertex
/// ABI (11-float triangles, 7-float scratch lines, time-based 7 lamps).
final class SourceHomeWreck209 {
    enum SourceError:Error { case missingMetal, invalidGeometry }

    private let triangles:MTLBuffer
    private let scratches:MTLBuffer
    private let triangleCount:Int
    private let lineCount:Int
    private let trianglePipeline:MTLRenderPipelineState
    private let linePipeline:MTLRenderPipelineState
    private let sourceDepth:MTLDepthStencilState

    private struct Uniforms {
        var mvp:simd_float4x4
        var model:simd_float4x4
        var sunAndTime:SIMD4<Float>
    }

    init(device:MTLDevice) throws {
        let original=ResearchWreckGeometry214.makeOrbitHome602()
        guard original.triangleCount>0,
              original.lineCount>0,
              original.triangleCount%3==0,
              original.lineCount%2==0,
              original.triangleCount<131072,
              original.lineCount<32768,
              original.triangles.count==original.triangleCount*11,
              original.lines.count==original.lineCount*7
        else {throw SourceError.invalidGeometry}
        triangleCount=original.triangleCount
        lineCount=original.lineCount
        guard let tv=original.triangles.withUnsafeBytes({ raw in
                  raw.baseAddress.flatMap{
                      device.makeBuffer(bytes:$0,length:raw.count,options:[])
                  }
              }),
              let lv=original.lines.withUnsafeBytes({ raw in
                  raw.baseAddress.flatMap{
                      device.makeBuffer(bytes:$0,length:raw.count,options:[])
                  }
              }) else {throw SourceError.missingMetal}
        triangles=tv
        scratches=lv

        let library=try device.makeDefaultLibrary(bundle:.main)
        func makePipeline(_ vertex:String,_ fragment:String)
            throws -> MTLRenderPipelineState {
            guard let v=library.makeFunction(name:vertex),
                  let f=library.makeFunction(name:fragment)
            else {throw SourceError.missingMetal}
            let d=MTLRenderPipelineDescriptor()
            d.vertexFunction=v
            d.fragmentFunction=f
            d.colorAttachments[0].pixelFormat = .bgra8Unorm
            d.depthAttachmentPixelFormat = .depth32Float
            // Exact original orbit wreck: opaque, depth writes enabled.
            d.colorAttachments[0].isBlendingEnabled=false
            return try device.makeRenderPipelineState(descriptor:d)
        }
        // Existing source-transcribed shaders preserve RGB, scratch lines,
        // authored face normals and warning-lamp phase in the vertex stream.
        trianglePipeline=try makePipeline(
            "combatWreckTriangleVertex214","combatWreckTriangleFragment214")
        linePipeline=try makePipeline(
            "combatWreckLineVertex214","combatWreckLineFragment214")

        let depth=MTLDepthStencilDescriptor()
        depth.depthCompareFunction = .lessEqual
        depth.isDepthWriteEnabled=true
        guard let state=device.makeDepthStencilState(descriptor:depth)
        else {throw SourceError.missingMetal}
        sourceDepth=state
    }

    private static func translate(_ p:SIMD3<Float>)->simd_float4x4 {
        var m=matrix_identity_float4x4
        m.columns.3=SIMD4(p.x,p.y,p.z,1)
        return m
    }
    private static func rotateY(_ degrees:Float)->simd_float4x4 {
        let a=degrees*Float.pi/180
        let c=cos(a),s=sin(a)
        return simd_float4x4(columns:(
            SIMD4(c,0,-s,0),SIMD4(0,1,0,0),
            SIMD4(s,0,c,0),SIMD4(0,0,0,1)))
    }
    private static func rotateZ(_ degrees:Float)->simd_float4x4 {
        let a=degrees*Float.pi/180
        let c=cos(a),s=sin(a)
        return simd_float4x4(columns:(
            SIMD4(c,s,0,0),SIMD4(-s,c,0,0),
            SIMD4(0,0,1,0),SIMD4(0,0,0,1)))
    }

    /// OrbitWorld50.SunDirection111 + PlanetLife52.LifeLighting52 from
    /// PC602: one real moving solar direction, 134sec/revolution.
    private static func sunDirection111(_ time:Float)->SIMD3<Float> {
        let angle:Float=0.62+max(0,time)*0.047
        let value=SIMD3<Float>(cos(angle),
            0.25+sin(angle*0.33)*0.13,sin(angle))
        return simd_normalize(value)
    }

    /// Wreck model is allocated once, its original vertices never rebuilt
    /// during animation. Only 64-byte uniforms change each render tick.
    func draw(encoder:MTLRenderCommandEncoder,
              projection:simd_float4x4,
              view:simd_float4x4,
              dock:SIMD3<Float>,
              time:Float) {
        guard dock.x.isFinite && dock.y.isFinite && dock.z.isFinite,
              time.isFinite else{return}
        let sourceScale=PC602NewHome290.wreckScale295
        let scale=simd_float4x4(
            diagonal:SIMD4(sourceScale,sourceScale,sourceScale,1))
        let orientation=Self.rotateY(31) * Self.rotateZ(-9)
        let transform=Self.translate(dock) * orientation * scale
        let sun=Self.sunDirection111(time)
        var uniform=Uniforms(mvp:projection*view*transform,model:transform,
                             sunAndTime:SIMD4(sun.x,sun.y,sun.z,time))
        encoder.setCullMode(.none)
        encoder.setDepthStencilState(sourceDepth)
        encoder.setRenderPipelineState(trianglePipeline)
        encoder.setVertexBuffer(triangles,offset:0,index:0)
        encoder.setVertexBytes(&uniform,
            length:MemoryLayout<Uniforms>.stride,index:1)
        encoder.setFragmentBytes(&uniform,
            length:MemoryLayout<Uniforms>.stride,index:1)
        encoder.drawPrimitives(type:.triangle,vertexStart:0,
                               vertexCount:triangleCount)
        // Source WreckSketchLine215 is a distinct GL_LINES pass; preserve it
        // over the actual hull rather than substituting a texture decal.
        encoder.setRenderPipelineState(linePipeline)
        encoder.setVertexBuffer(scratches,offset:0,index:0)
        encoder.setVertexBytes(&uniform,
            length:MemoryLayout<Uniforms>.stride,index:1)
        encoder.drawPrimitives(type:.line,vertexStart:0,
                               vertexCount:lineCount)
    }
}
