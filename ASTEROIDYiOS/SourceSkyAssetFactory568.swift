import Foundation
import Metal

/// One immutable source-exact construction path shared by the W3/Intro
/// renderer and CARBONIS combat sky. Previously copied verbatim into
/// MetalRenderer.swift and SourceCombatSky568.swift.
/// No new GPU format, colors, vertices, allocations per frame or fallbacks.
enum SourceSkyAssetFactory568 {
    /// Original GpuAmbient37 StarTexture 64×64, premultiplied BGRA.
    static func makeSphereHaloTexture(_ device: MTLDevice)
        throws -> MTLTexture {
        let n=SphereSky207.haloTextureSize
        let descriptor=MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat:.bgra8Unorm,width:n,height:n,mipmapped:false)
        descriptor.usage=[.shaderRead]
        descriptor.storageMode = .shared
        guard let texture=device.makeTexture(descriptor:descriptor) else {
            throw NSError(domain:"ASTEROIDY iOS Metal",code:12,
                          userInfo:[NSLocalizedDescriptionKey:
                            "Nie można utworzyć oryginalnej StarTexture 64x64"])
        }
        let texels=SphereSky207.haloTexelsBGRA()
        texels.withUnsafeBytes { raw in
            if let p=raw.baseAddress {
                texture.replace(region:MTLRegionMake2D(0,0,n,n),
                                mipmapLevel:0,withBytes:p,bytesPerRow:n*4)
            }
        }
        return texture
    }

    /// Original SphereSky207 source-visible star and halo vertices.
    static func sphereSky207() -> ([AssetMesh.Vertex],[UInt32]) {
        var vertices:[AssetMesh.Vertex]=[]
        var indices:[UInt32]=[]
        vertices.reserveCapacity(SphereSky207.count*2)
        indices.reserveCapacity(SphereSky207.count*2)
        let radius=SphereSky207.normalizedSkyRadius
        for i in 0..<SphereSky207.count {
            let star=SphereSky207.star(i)
            let point=SIMD3<Float>(
                star.direction.x,star.direction.y,star.direction.z)*radius
            func appendHalo(_ diameter:Float,_ alpha:Float) {
                let base=UInt32(vertices.count)
                vertices.append(AssetMesh.Vertex(
                    position:SIMD4(point.x,point.y,point.z,1),
                    color:SIMD4(star.red,star.green,star.blue,alpha),
                    normal:SIMD4(0,0,1,0),
                    material:SIMD4<Float>(diameter,0,0,0)))
                indices.append(base)
            }
            // Renderer.GlowEnabled defaults to true in original
            // Windows/src/Renderer.cs:25. Glow UI option is not ported.
            if SphereSky207.hasBrightHalo(star) {
                appendHalo(SphereSky207.brightHaloDiameterPixels(star),
                           125/255)
            }
            appendHalo(SphereSky207.baseDiameterPixels(star),
                       star.alpha)
        }
        return (vertices,indices)
    }

    /// Original GpuCosmos39 solar ray overlay vertices.
    static func solarOverlaySource556()
        -> ([AssetMesh.Vertex],[UInt32]) {
        let source=SphereSolarOverlay556.vertices()
        var vertices:[AssetMesh.Vertex]=[]
        vertices.reserveCapacity(source.count)
        for v in source {
            let (r,g,b,a)=v.rgba
            vertices.append(AssetMesh.Vertex(
                position:SIMD4(v.offset.x,v.offset.y,0,1),
                color:SIMD4(r,g,b,a),
                normal:SIMD4(v.uv.x,v.uv.y,0,0),
                material:SIMD4<Float>(v.textured ? 1:0,1,0,0)))
        }
        return (vertices,(0..<source.count).map {UInt32($0)})
    }
}
