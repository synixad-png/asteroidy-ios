import MetalKit
import simd

/// Original PC602 HomeFlight291.DrawHomeProjectileLights296.
/// Two additive, height-map-following GL_TRIANGLE_FAN equivalents per live
/// non-hostile projectile. Uses the mission's *same* original 8 shot colors,
/// mixing and brightness and the actual H290 terrain surface.
/// Geometry matches 24 radial segments, radius*2/.34 at +1.8 m,
/// radius/.78 at +2.0 m. No additional physics or light objects.
final class PC602HomeProjectileLights296 {
    enum SourceError:Error {case metal}
    private static let maxBullets=145
    private static let verticesPerBullet=2*24*3
    private let pipeline:MTLRenderPipelineState
    private let depth:MTLDepthStencilState
    private let buffers:[MTLBuffer]
    private let slots=DispatchSemaphore(value:3)
    private let settings=CarbonisVisualSettings568.load()
    private var ringIndex=0
    private var staging=[PC602HomeBeacons291.Vertex]()
    private static let circle:[SIMD2<Float>]=(0...24).map { i in
        let a=Float(i)*Float.pi*2/24
        return SIMD2<Float>(cos(a),sin(a))
    }

    init(device:MTLDevice)throws {
        let library=try device.makeDefaultLibrary(bundle:.main)
        guard let v=library.makeFunction(name:"home291BeaconVertex"),
              let f=library.makeFunction(name:"home291BeaconFragment")
        else{throw SourceError.metal}
        let p=MTLRenderPipelineDescriptor()
        p.vertexFunction=v
        p.fragmentFunction=f
        p.colorAttachments[0].pixelFormat = .bgra8Unorm
        p.depthAttachmentPixelFormat = .depth32Float
        p.colorAttachments[0].isBlendingEnabled=true
        p.colorAttachments[0].sourceRGBBlendFactor = .one
        p.colorAttachments[0].destinationRGBBlendFactor = .one
        p.colorAttachments[0].sourceAlphaBlendFactor = .one
        p.colorAttachments[0].destinationAlphaBlendFactor = .one
        pipeline=try device.makeRenderPipelineState(descriptor:p)
        let d=MTLDepthStencilDescriptor()
        d.depthCompareFunction = .lessEqual
        d.isDepthWriteEnabled=false
        guard let stencil=device.makeDepthStencilState(descriptor:d)
        else{throw SourceError.metal}
        depth=stencil
        let capacity=Self.maxBullets*Self.verticesPerBullet*
                     MemoryLayout<PC602HomeBeacons291.Vertex>.stride
        var storage=[MTLBuffer]()
        for _ in 0..<3 {
            guard let buffer=device.makeBuffer(length:capacity,
                                               options:.storageModeShared)
            else{throw SourceError.metal}
            storage.append(buffer)
        }
        buffers=storage
        staging.reserveCapacity(Self.maxBullets*Self.verticesPerBullet)
    }

    private static func basis(_ point:Vec2)
        ->(n:SIMD3<Float>,east:SIMD3<Float>,up:SIMD3<Float>) {
        let n=Sphere67.normal(point)
        let vectors=Sphere67.basis(point)
        return (SIMD3(n.x,n.y,n.z),
                SIMD3(vectors.east.x,vectors.east.y,vectors.east.z),
                SIMD3(vectors.south.x,vectors.south.y,vectors.south.z))
    }

    private func fan(_ point:Vec2,home:PC602NewHome290,
                     radius:Float,tint:SIMD3<Float>,
                     power:Float,heightBias:Float) {
        guard radius>0,power>0 else{return}
        let frame=Self.basis(point)
        guard let h=home.surface(frame.n) else{return}
        let core=frame.n*(h+heightBias)
        let bright=SIMD4<Float>(min(1,tint.x*power),
                                min(1,tint.y*power),
                                min(1,tint.z*power),1)
        let black=SIMD4<Float>(repeating:0)
        func append(_ p:SIMD3<Float>,_ color:SIMD4<Float>) {
            staging.append(.init(position:SIMD4<Float>(p,1),tint:color))
        }
        let unit=radius/130
        var previous:SIMD3<Float>?=nil
        for uv in Self.circle {
            let tangent=frame.n +
                frame.east*(uv.x*unit)+frame.up*(uv.y*unit)
            let n=simd_normalize(tangent)
            guard let relief=home.surface(n) else{continue}
            let current=n*(relief+heightBias)
            if let previous {
                append(core,bright)
                append(previous,black)
                append(current,black)
            }
            previous=current
        }
    }

    func draw(encoder:MTLRenderCommandEncoder,
              command:MTLCommandBuffer,
              home:PC602NewHome290,
              bullets:[PC602HomeWeaponTest292.Bullet],
              projection:simd_float4x4,view:simd_float4x4) {
        guard !bullets.isEmpty,settings.projectileBrightness>0 else{return}
        let power=min(2.8,max(0,settings.projectileBrightnessFactor))
        staging.removeAll(keepingCapacity:true)
        for bullet in bullets.prefix(Self.maxBullets) {
            let source=CarbonisProjectileFX69.playerTint(bullet.kind.rawValue)
            let chosen=CarbonisProjectileFX69.groundTint(source,settings:settings)
            let tint=SIMD3<Float>(chosen.r,chosen.g,chosen.b)
            let radius:Float=bullet.kind == .rail ? 34 :
                              bullet.kind == .swarm ? 28 : 26
            fan(bullet.position,home:home,radius:radius*2,
                tint:tint,power:0.34*power,heightBias:1.8)
            fan(bullet.position,home:home,radius:radius,
                tint:tint,power:0.78*power,heightBias:2.0)
        }
        guard !staging.isEmpty,
              slots.wait(timeout:.now()) == .success else{return}
        let buffer=buffers[ringIndex]
        ringIndex=(ringIndex+1)%buffers.count
        staging.withUnsafeBytes { raw in
            if let origin=raw.baseAddress {
                buffer.contents().copyMemory(from:origin,
                                               byteCount:raw.count)
            }
        }
        command.addCompletedHandler{ [slots=self.slots] _ in slots.signal() }
        var vp=projection*view
        encoder.setRenderPipelineState(pipeline)
        encoder.setDepthStencilState(depth)
        encoder.setCullMode(.none)
        encoder.setVertexBuffer(buffer,offset:0,index:0)
        encoder.setVertexBytes(&vp,
            length:MemoryLayout<simd_float4x4>.stride,index:1)
        encoder.drawPrimitives(type:.triangle,
            vertexStart:0,vertexCount:staging.count)
    }
}
