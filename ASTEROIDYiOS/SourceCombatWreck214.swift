import Foundation
import MetalKit
import simd

/// Exact position and camera anchoring of Windows v568
/// GpuSphere67.DrawCombatResearchWreck214; uses generated original
/// DrawDetailedResearchWreck211 instead of an unrelated ship model.
/// Not a new gameplay actor, does not alter collision/mission state.
final class SourceCombatWreck214 {
    enum SourceError:Error { case resources, geometry }
    private let triangles:MTLBuffer
    private let lines:MTLBuffer
    private let triangleCount:Int
    private let lineCount:Int
    private let trianglePipeline:MTLRenderPipelineState
    private let linePipeline:MTLRenderPipelineState
    private let depth:MTLDepthStencilState

    private struct Uniforms {
        var mvp:simd_float4x4
        var model:simd_float4x4
        var sunAndTime:SIMD4<Float>
    }

    init(device:MTLDevice,sector:Int) throws {
        let geometry=ResearchWreckGeometry214.make(sector:sector)
        // Original GpuIntro41 WreckTriangles222 has 131072 vertices,
        // WreckLines222 32768 vertices at most per batch.
        guard geometry.triangleCount>0,geometry.lineCount>0,
              geometry.triangleCount<131072,
              geometry.lineCount<32768,
              geometry.triangleCount%3==0,
              geometry.lineCount%2==0 else {throw SourceError.geometry}
        triangleCount=geometry.triangleCount
        lineCount=geometry.lineCount
        guard let t=geometry.triangles.withUnsafeBytes({ raw in
                    raw.baseAddress.flatMap {
                        device.makeBuffer(bytes:$0,length:raw.count,options:[])
                    }
                }),
              let l=geometry.lines.withUnsafeBytes({ raw in
                    raw.baseAddress.flatMap {
                        device.makeBuffer(bytes:$0,length:raw.count,options:[])
                    }
                }) else {throw SourceError.resources}
        triangles=t
        lines=l
        let lib=try device.makeDefaultLibrary(bundle:.main)
        func make(_ vertex:String,_ fragment:String)
            throws -> MTLRenderPipelineState {
            guard let v=lib.makeFunction(name:vertex),
                  let f=lib.makeFunction(name:fragment)
            else {throw SourceError.resources}
            let d=MTLRenderPipelineDescriptor()
            d.vertexFunction=v
            d.fragmentFunction=f
            d.colorAttachments[0].pixelFormat = .bgra8Unorm
            d.depthAttachmentPixelFormat = .depth32Float
            // Original DrawCombatResearchWreck214 disables blending.
            d.colorAttachments[0].isBlendingEnabled=false
            return try device.makeRenderPipelineState(descriptor:d)
        }
        trianglePipeline=try make("combatWreckTriangleVertex214",
                                  "combatWreckTriangleFragment214")
        linePipeline=try make("combatWreckLineVertex214",
                              "combatWreckLineFragment214")
        let ds=MTLDepthStencilDescriptor()
        ds.depthCompareFunction = .lessEqual
        ds.isDepthWriteEnabled=true
        guard let state=device.makeDepthStencilState(descriptor:ds)
        else {throw SourceError.resources}
        depth=state
    }

    private static func translate(_ p:SIMD3<Float>)->simd_float4x4 {
        var m=matrix_identity_float4x4
        m.columns.3=SIMD4(p.x,p.y,p.z,1)
        return m
    }
    private static func rotateZ(_ degrees:Float)->simd_float4x4 {
        let a=degrees*Float.pi/180,c=cos(a),s=sin(a)
        return simd_float4x4(columns:(
            SIMD4(c,s,0,0),SIMD4(-s,c,0,0),
            SIMD4(0,0,1,0),SIMD4(0,0,0,1)))
    }
    private static func rotateY(_ degrees:Float)->simd_float4x4 {
        let a=degrees*Float.pi/180,c=cos(a),s=sin(a)
        return simd_float4x4(columns:(
            SIMD4(c,0,-s,0),SIMD4(0,1,0,0),
            SIMD4(s,0,c,0),SIMD4(0,0,0,1)))
    }
    private static func rotateX(_ degrees:Float)->simd_float4x4 {
        let a=degrees*Float.pi/180,c=cos(a),s=sin(a)
        return simd_float4x4(columns:(
            SIMD4(1,0,0,0),SIMD4(0,c,s,0),
            SIMD4(0,-s,c,0),SIMD4(0,0,0,1)))
    }

    func draw(encoder:MTLRenderCommandEncoder,
              camera:SphereCamera67,vp:simd_float4x4,
              time:Float,sourceSun:SIMD4<Float>) {
        let basis=SphereCameraView556(camera:camera)
        typealias V=SphereVector3
        // GpuSphere67.cs:387: exact celestial orientation of ringed
        // gas giant, independent of camera focus.
        let ringSky221=V(x:-0.7,y:0.22,z:-0.68).normalized
        let ringDepth = -V.dot(basis.back,ringSky221*900)
        // Source SkyProject55 returns false for depth <= 0.4.
        if ringDepth<=0.4 {return}
        let inv=1/SphereCameraView556.originalPlanetOuterRadius
        // GpuSphere67.cs:392: Eye+SkyDirection*900+Right*80+Up*52
        let origin=basis.eye+ringSky221*(900*inv)+
                   basis.right*(80*inv)+basis.up*(52*inv)
        let delta=(origin-basis.eye) / inv
        let eyeDepth = -V.dot(basis.back,delta)
        if eyeDepth<=0.4 {return}
        let sx:Float=640+V.dot(basis.right,delta)*720/max(0.01,eyeDepth)
        let sy:Float=360-V.dot(basis.up,delta)*720/max(0.01,eyeDepth)
        // DrawCombatResearchWreck214: original screen-space gate.
        if sx < -150 || sx > 1430 || sy < -110 || sy > 830 {return}
        let toCamera=V.cross(basis.right,basis.up).normalized
        let frame=simd_float4x4(columns:(
            SIMD4(basis.right.x,basis.right.y,basis.right.z,0),
            SIMD4(basis.up.x,basis.up.y,basis.up.z,0),
            SIMD4(toCamera.x,toCamera.y,toCamera.z,0),
            SIMD4(0,0,0,1)))
        // Same matrix product as OpenGL column-vector stack:
        // T(pos) * basis * Rz(-11) * Ry(24) * Rx(26) * Scale(2.20)
        let size=2.20*inv
        let scale=simd_float4x4(diagonal:SIMD4<Float>(size,size,size,1))
        let transform=Self.translate(SIMD3(origin.x,origin.y,origin.z))
            * frame * Self.rotateZ(-11) * Self.rotateY(24)
            * Self.rotateX(26) * scale
        var u=Uniforms(mvp:vp*transform,model:transform,
                       sunAndTime:SIMD4(sourceSun.x,sourceSun.y,
                                       sourceSun.z,time))
        encoder.setCullMode(.none)
        encoder.setDepthStencilState(depth)
        encoder.setRenderPipelineState(trianglePipeline)
        encoder.setVertexBuffer(triangles,offset:0,index:0)
        encoder.setVertexBytes(&u,length:MemoryLayout<Uniforms>.stride,index:1)
        encoder.setFragmentBytes(&u,length:MemoryLayout<Uniforms>.stride,index:1)
        encoder.drawPrimitives(type:.triangle,vertexStart:0,
                               vertexCount:triangleCount)
        encoder.setRenderPipelineState(linePipeline)
        encoder.setVertexBuffer(lines,offset:0,index:0)
        encoder.setVertexBytes(&u,length:MemoryLayout<Uniforms>.stride,index:1)
        encoder.drawPrimitives(type:.line,vertexStart:0,
                               vertexCount:lineCount)
    }
}
