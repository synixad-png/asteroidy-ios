import MetalKit
import simd

/// Windows/src/VisualStyle58.cs MissionSignal58:
/// two crossed 109..135 world-radius strips and two 64-section halo rings.
/// Only the selected, genuinely unlocked source beacon is signalled.
/// GL_QUADS have been converted 1-to-1 into two Metal triangles.
final class PC602HomeMissionSignal58 {
    enum SourceError:Error {case metal}
    private let device:MTLDevice
    private let pipeline:MTLRenderPipelineState
    private let depth:MTLDepthStencilState
    private var cache:(Int,Int)?
    private var buffer:MTLBuffer?
    private var vertexCount=0

    init(device:MTLDevice)throws {
        self.device=device
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
        p.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        p.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        p.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        p.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipeline=try device.makeRenderPipelineState(descriptor:p)
        let d=MTLDepthStencilDescriptor()
        d.depthCompareFunction = .lessEqual
        d.isDepthWriteEnabled=false
        guard let depth=device.makeDepthStencilState(descriptor:d)
        else{throw SourceError.metal}
        self.depth=depth
    }

    private static func geometry(home:PC602NewHome290,
                                 selected:Int,completedMask:Int)
        ->[PC602HomeBeacons291.Vertex] {
        guard PC602HomeFlight291.unlocked(selected,mask:completedMask),
              let beacon=home.beacon(selected) else{return []}
        let n=simd_normalize(beacon)
        var side=simd_cross(n,SIMD3<Float>(0,1,0))
        guard simd_length(side)>0.001 else{return []}
        side=simd_normalize(side)
        let front=simd_normalize(simd_cross(n,side))
        let completed=PC602HomeFlight291.completed(
            selected,mask:completedMask)
        let tint:SIMD3<Float>=completed
            ? SIMD3<Float>(112,220,164)/255
            : SIMD3<Float>(113,205,235)/255
        var result=[PC602HomeBeacons291.Vertex]()
        result.reserveCapacity(864)
        func add(_ point:SIMD3<Float>,_ alpha:Float) {
            result.append(.init(position:SIMD4<Float>(point,1),
                tint:SIMD4<Float>(tint,alpha)))
        }
        func quad(_ a:SIMD3<Float>,_ b:SIMD3<Float>,
                  _ c:SIMD3<Float>,_ d:SIMD3<Float>,
                  _ aa:Float,_ ba:Float,_ ca:Float,_ da:Float) {
            add(a,aa);add(b,ba);add(c,ca)
            add(a,aa);add(c,ca);add(d,da)
        }
        for axis in 0..<2 {
            let right=axis==0 ? side:front
            for strip in 0..<4 {
                let x=(Float(strip)-2)*0.55
                let xx=x+0.55
                let a:Float=(strip==0 || strip==3) ? 0.015:0.12
                quad(n*109+right*x,n*109+right*xx,
                     n*126+right*xx,n*126+right*x,
                     0,0,a,a)
                quad(n*126+right*x,n*126+right*xx,
                     n*135+right*xx,n*135+right*x,
                     a,a,0,0)
            }
        }
        for ring in 0..<2 {
            let radius:Float=4+Float(ring)*1.6
            for j in 0..<64 {
                let a=Float(j)*Float.pi/32
                let b=a+Float.pi/32
                let u=side*cos(a)+front*sin(a)
                let v=side*cos(b)+front*sin(b)
                quad(beacon+u*radius,beacon+v*radius,
                     beacon+v*(radius+0.3),beacon+u*(radius+0.3),
                     0.22,0.22,0,0)
            }
        }
        return result
    }

    func draw(encoder:MTLRenderCommandEncoder,
              projection:simd_float4x4,view:simd_float4x4,
              flight:PC602HomeFlight291) {
        let key=(flight.target,flight.completedMask)
        if cache?.0 != key.0 || cache?.1 != key.1 {
            cache=key
            let points=Self.geometry(home:flight.home,selected:key.0,
                                     completedMask:key.1)
            vertexCount=points.count
            buffer=points.withUnsafeBytes { raw in
                raw.baseAddress.flatMap {
                    device.makeBuffer(bytes:$0,length:raw.count,options:[])
                }
            }
        }
        guard let buffer,vertexCount>0 else{return}
        var vp=projection*view
        encoder.setRenderPipelineState(pipeline)
        encoder.setDepthStencilState(depth)
        encoder.setCullMode(.none)
        encoder.setVertexBuffer(buffer,offset:0,index:0)
        encoder.setVertexBytes(&vp,
            length:MemoryLayout<simd_float4x4>.stride,index:1)
        encoder.drawPrimitives(type:.triangle,
            vertexStart:0,vertexCount:vertexCount)
    }
}
