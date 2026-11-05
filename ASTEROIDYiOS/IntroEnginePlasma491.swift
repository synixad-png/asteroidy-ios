import Foundation

/// Windows/src/GpuShip.cs:19–63, source v491 sustained exhaust
/// from the *actual* type-1 Vanguard431 model (not the obsolete
/// blue-wedge v490 effect). The engine sockets below were decoded
/// directly from Shared/assets/vanguard431/vanguard431.mesh.gz,
/// 4311 header -> n=2 -> six little-endian IEEE754 float32 values.
///
/// The Metal shader runs this exact algebra per vertex. This pure
/// Swift oracle is used ONLY for deterministic GPU/source parity
/// regression tests; no 576-vertex CPU rebuild runs each frame.
enum IntroEnginePlasma491 {
    typealias V=SphereVector3
    struct Vertex {
        let position:V
        let color:SIMD4<Float>
    }

    static let engineCenters:[V] = [
        V(x:-0.44299396872520447,y:-1.5887130498886108,
          z:-0.1674797236919403),
        V(x: 0.44578471779823303,y:-1.5894304513931274,
          z:-0.18300314247608185)
    ]
    static let visualSize:Float=1.06 // ShipMesh.VisualSize172
    static let layers=3
    static let planes=3
    static let segments=16
    static let verticesPerSlice=6
    static var vertexCount:Int {
        engineCenters.count*layers*planes*segments*verticesPerSlice
    }

    static func vertex(id:Int,time:Float,power:Float=1)->Vertex {
        precondition(id>=0 && id<vertexCount)
        let engineIndex=id/(layers*planes*segments*verticesPerSlice)
        let layer=(id/(planes*segments*verticesPerSlice))%layers
        let plane=(id/(segments*verticesPerSlice))%planes
        let step=(id/verticesPerSlice)%segments
        let corner=id%verticesPerSlice
        let first=corner==0 || corner==1 || corner==4
        let left=corner==0 || corner==2 || corner==3
        let u=Float(first ? step : step+1)/Float(segments)
        let src=engineCenters[engineIndex]
        let thrust=max(0,min(1,power))
        let plume:Float=0.17+thrust*1.47
        let angle=Float(plane)*Float.pi/3
        let dx=cos(angle),dz=sin(angle)
        let radial:Float=layer==0 ? 0.12 : layer==1 ? 0.072 : 0.030
        let alpha:Float=layer==0 ? 0.21 : layer==1 ? 0.48 : 0.82
        let off=sin(u*11-time*11+Float(plane)*1.9+src.x*2) *
            u*u*0.075*thrust
        let spread=pow(max(Float(0.035),1-u),0.58) *
            (1+0.11*sin(u*28-time*21+Float(plane)))
        let width=visualSize*radial*spread
        let fade=alpha*(1-u*u) *
            (0.83+0.17*sin(time*19-u*37+Float(plane)))
        let sign:Float=left ? 1 : -1
        let r:Float=1
        let g:Float=layer==2 ? 0.96-0.19*u :
            layer==1 ? 0.65-0.27*u : 0.27-0.14*u
        let b:Float=layer==2 ? 0.49*(1-u) : 0.035
        return Vertex(
            position:V(x:src.x+off+sign*dx*width,
                       y:src.y-plume*u,
                       z:src.z+sign*dz*width),
            color:SIMD4<Float>(r,g,b,fade))
    }
}
