import Foundation
import Metal
import simd

/// Native 3D Explosion524 (Windows V8.2 preset0) GPU renderer.
/// Builds one shared 64³ Xorshift texture and one Metal pipeline per scene,
/// NOT one resource per explosion. Source has max 3 concurrent volumes at
/// gameplay quality (22 depth samples, 13 irregular lobes).
final class CarbonisExplosion524Renderer {
    private struct Parameters {
        var mvp:simd_float4x4
        var age:Float
        var scale:Float
        var fire:Float
        var smoke:Float
        var chaos:Float
        var spread:Float
        var seed:Float
        var lobes:UInt32
        var steps:UInt32
        var kind:UInt32
    }
    // All three SIMD4<Float> fields match three Metal float4 fields.
    // This precomputation keeps source Explosion524 formulas and removes
    // repeated lobe trigonometry/exponentials from GPU depth samples.
    private struct Lobe {
        var directionFire:SIMD4<Float>
        var centerRadius:SIMD4<Float>
        var smokePhase:SIMD4<Float>
    }

    private static func hash524(_ n:Float)->Float {
        let value=sin(n*97.23+12.4)*43758.5453
        return value-floor(value)
    }

    private static func lobes(age:Float,
                              settings:CarbonisVisualSettings568)->[Lobe] {
        let a=max(0,age)
        let scale=settings.factor(0)
        let spread=settings.factor(5)
        let lAge:Float=0.96*(1-exp(-a*1.62))
        var result:[Lobe]=[]
        result.reserveCapacity(17)
        for i in 0..<17 {
            let fi=Float(i)
            let k=fi+0.5
            let y:Float=1-2*k/17
            let azimuth=k*2.399963
            let r=sqrt(max(0,1-y*y))
            var direction=SIMD3<Float>(cos(azimuth)*r,y,sin(azimuth)*r)
            direction.y=direction.y*0.75+0.18
            direction=simd_normalize(direction+SIMD3<Float>(
                0.20*sin(fi*2.73),0.14*cos(fi*3.17),
                0.16*sin(fi*1.32)))
            let speed=(0.96+0.82*hash524(fi*4.37+2))*spread
            let center=direction*(speed*lAge*1.48)+SIMD3<Float>(
                0.13*sin(a*1.6+fi),
                a*a*0.06*(0.4+direction.y),
                0.07*cos(a*2+fi))
            let radius=(0.30+0.31*hash524(fi*2.71+9))*(0.59+1.35*sqrt(a+0.025))*scale
            let pulse=0.60+0.4*sin(fi*1.9+a*(1.1+hash524(fi)*2))
            let fireAmplitude=pulse*exp(-a*(0.55+hash524(fi+13)*0.6))*(1.2+0.4*hash524(fi+4))
            let smokeAmplitude=(0.38+0.45*hash524(fi+17))*(0.22+a*0.78)
            result.append(Lobe(
                directionFire:SIMD4<Float>(
                    direction.x,direction.y,direction.z,fireAmplitude),
                centerRadius:SIMD4<Float>(
                    center.x,center.y,center.z,radius),
                smokePhase:SIMD4<Float>(
                    smokeAmplitude,fi*2.31+a*1.35,0,0)))
        }
        return result
    }

    // Original quad covers a unit square. The volume's actually
    // contributing region is exactly the disc radius 0.49 in UV:
    // original smoothstep forces zero opacity at 0.98*bound and
    // out-of-circle flash falls below the source alpha-discard gate.
    // A circumscribed 24-gon covers the *entire* nonzero source domain,
    // while avoiding fragment invocations in ~24% empty quad pixels.
    // Precompute unit directions once; 3D raymarch, 13 lobes, noise,
    // glow, alpha, sampling quality and event life remain identical.
    static let sourceDiscSides=24
    private static let sourceDiscCorners:[SIMD2<Float>] = {
        let radius:Float=0.49/cos(Float.pi/Float(sourceDiscSides))
            + 0.00001
        return (0...sourceDiscSides).map { i in
            let a=2*Float.pi*Float(i)/Float(sourceDiscSides)
            return SIMD2<Float>(radius*cos(a),radius*sin(a))
        }
    }()
    private let pipeline:MTLRenderPipelineState
    private let noise:MTLTexture
    private let noDepthWrite:MTLDepthStencilState

    init(device:MTLDevice,library:MTLLibrary) throws {
        enum Setup:Error {case failed}
        guard let vertex=library.makeFunction(
                name:"sector01ExplosionVertex524"),
              let fragment=library.makeFunction(
                name:"sector01ExplosionFragment524")
        else {throw Setup.failed}
        let desc=MTLRenderPipelineDescriptor()
        desc.vertexFunction=vertex
        desc.fragmentFunction=fragment
        desc.colorAttachments[0].pixelFormat = .bgra8Unorm
        desc.colorAttachments[0].isBlendingEnabled=true
        desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        desc.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        desc.depthAttachmentPixelFormat = .depth32Float
        pipeline=try device.makeRenderPipelineState(descriptor:desc)

        // Xcode 16.4: MTLTextureDescriptor provides texture2DDescriptor,
        // but no texture3DDescriptor convenience factory. Configure true
        // 3D texture explicitly; R8 bytes and dimensions are unchanged.
        let tex=MTLTextureDescriptor()
        tex.textureType = .type3D
        tex.pixelFormat = .r8Unorm
        tex.width=64
        tex.height=64
        tex.depth=64
        tex.mipmapLevelCount=1
        tex.usage = .shaderRead
        tex.storageMode = .shared
        guard let result=device.makeTexture(descriptor:tex)
        else {throw Setup.failed}
        noise=result
        let bytes=CarbonisExplosionNoise524.originalBytes()
        bytes.withUnsafeBytes { raw in
            if let address=raw.baseAddress {
                result.replace(
                    region:MTLRegionMake3D(0,0,0,64,64,64),
                    mipmapLevel:0,
                    slice:0,
                    withBytes:address,
                    bytesPerRow:64,bytesPerImage:4096)
            }
        }
        let ds=MTLDepthStencilDescriptor()
        ds.depthCompareFunction = .lessEqual
        ds.isDepthWriteEnabled=false
        guard let depth=device.makeDepthStencilState(descriptor:ds)
        else {throw Setup.failed}
        noDepthWrite=depth
    }

    /// Camera-facing 3D *bound* as in Explosion524.cs:185-220; the
    /// fragment program samples actual 3D density through the bound.
    func render(_ state:CarbonisDestruction524,time:Float,
                camera:SphereCamera67,vp:simd_float4x4,
                settings:CarbonisVisualSettings568,
                budget:CarbonisIOSFXBudget568 = .original,
                into encoder:MTLRenderCommandEncoder) {
        let events=state.visibleExplosions(
            at:time,maxCount:budget.volumeCount(settings.simultaneousVolumes),
            duration:budget.explosionDuration(settings.explosionDuration))
        if events.isEmpty {return}
        let outer=SphereCameraView556.originalPlanetOuterRadius
        let shell=(outer+15)/outer
        let eye=SphereCameraView556(camera:camera).eye
        encoder.setRenderPipelineState(pipeline)
        encoder.setDepthStencilState(noDepthWrite)
        encoder.setCullMode(.none)
        encoder.setFragmentTexture(noise,index:0)
        for event in events {
            let age=time-event.spawned
            let normal=Sphere67.normal(event.point)
            let center=normal*(shell+1.1/outer)
            let front=(eye-center).normalized
            var right=SphereVector3.cross(
                SphereVector3(x:0,y:1,z:0),front).normalized
            if right.length<0.01 {
                right=SphereVector3(x:1,y:0,z:0)
            }
            let up=SphereVector3.cross(front,right).normalized
            // Explosion524.cs:197,203 — both the projected radius
            // and the shader uScale obey the original "ROZMIAR 3D" slider.
            let scale=settings.factor(0)
            let radius=event.scale*scale*0.55/outer
            let extent=radius*5.1*scale
            // UV and world positions are related by the same affine
            // mapping as the original four quad corners. Every surviving
            // fragment receives the unchanged source (x,y,z) ray sample.
            var vertices:[Float]=[]
            vertices.reserveCapacity(Self.sourceDiscSides*3*5)
            func put(_ point:SphereVector3,_ x:Float,_ y:Float) {
                vertices.append(contentsOf:[point.x,point.y,point.z,x,y])
            }
            for i in 0..<Self.sourceDiscSides {
                let a=Self.sourceDiscCorners[i]
                let b=Self.sourceDiscCorners[i+1]
                let pointA=center+right*(a.x*2*extent)+up*(a.y*2*extent)
                let pointB=center+right*(b.x*2*extent)+up*(b.y*2*extent)
                put(center,0.5,0.5)
                put(pointA,0.5+a.x,0.5+a.y)
                put(pointB,0.5+b.x,0.5+b.y)
            }
            var params=Parameters(
                mvp:vp,age:age,
                scale:scale,
                fire:settings.factor(2),smoke:settings.factor(3),
                chaos:settings.factor(4),spread:settings.factor(5),
                seed:event.spawned*0.13,
                lobes:UInt32(budget.gasLobes(settings.value(1))),
                steps:UInt32(budget.raySamples(settings.raySamples)),
                kind:UInt32(event.kind))
            vertices.withUnsafeBytes { raw in
                if let address=raw.baseAddress {
                    encoder.setVertexBytes(address,length:raw.count,index:0)
                }
            }
            encoder.setVertexBytes(&params,length:MemoryLayout<Parameters>.stride,
                                   index:1)
            encoder.setFragmentBytes(&params,length:MemoryLayout<Parameters>.stride,
                                     index:1)
            let prepared=Array(Self.lobes(age:age,settings:settings)
                .prefix(budget.gasLobes(settings.value(1))))
            prepared.withUnsafeBytes { raw in
                if let address=raw.baseAddress {
                    encoder.setFragmentBytes(address,length:raw.count,index:2)
                }
            }
            encoder.drawPrimitives(type:.triangle,vertexStart:0,
                                   vertexCount:Self.sourceDiscSides*3)
        }
    }
}
