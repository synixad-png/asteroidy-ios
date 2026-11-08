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


    // Verified identical in both renderers before extraction; unchanged
    // source texture formats, BGRA uploads, lazy caller behavior and errors.
    static func makeNebulaTextures556(_ device:MTLDevice)
            throws -> MTLTexture {
            let n=SphereNebula556.imageSize
            let d=MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat:.bgra8Unorm,width:n,height:n,mipmapped:false)
            d.textureType = .type2DArray
            d.arrayLength = SphereNebula556.orbitThemeCount
            d.storageMode = .shared
            d.usage=[.shaderRead]
            guard let texture=device.makeTexture(descriptor:d) else {
                throw NSError(domain:"ASTEROIDY iOS Metal",code:13,
                     userInfo:[NSLocalizedDescriptionKey:
                        "Nie można utworzyć źródłowych NebulaTexture 256x256"])
            }
            return texture
        }
    
        static func uploadNebulaSlice556(_ texture:MTLTexture,
                                                 theme:Int) -> Bool {
            let n=SphereNebula556.imageSize
            let texels=SphereNebula556.textureBGRA(theme:theme)
            guard texels.count == n*n*4 else {
                NSLog("ASTEROIDY iOS: nieprawidłowa tekstura mgławicy %ld", theme)
                return false
            }
            texels.withUnsafeBytes { raw in
                if let p=raw.baseAddress {
                    texture.replace(region:MTLRegionMake2D(0,0,n,n),
                                    mipmapLevel:0,slice:theme,withBytes:p,
                                    bytesPerRow:n*4,bytesPerImage:n*n*4)
                }
            }
            return true
        }
    
        static func nebulaSource556()
            -> ([AssetMesh.Vertex],[UInt32]) {
            let uv:[SIMD2<Float>]=[
                SIMD2(0,0),SIMD2(1,0),SIMD2(1,1),
                SIMD2(0,0),SIMD2(1,1),SIMD2(0,1)
            ]
            var vertices:[AssetMesh.Vertex]=[]
            vertices.reserveCapacity(SphereNebula556.orbitLayerCount*6)
            var indices:[UInt32]=[]
            indices.reserveCapacity(SphereNebula556.orbitLayerCount*6)
            for i in 0..<SphereNebula556.orbitLayerCount {
                let layer=SphereNebula556.layer(i)
                for u in uv {
                    vertices.append(AssetMesh.Vertex(
                        position:SIMD4(layer.direction.x,layer.direction.y,
                                       layer.direction.z,1),
                        color:SIMD4(1,1,1,layer.alpha),
                        normal:SIMD4(u.x,u.y,0,0),
                        material:SIMD4<Float>(
                            layer.near ? 1:0,Float(layer.theme),0,0)))
                    indices.append(UInt32(indices.count))
                }
            }
            return (vertices,indices)
        }
    
        static func makeBlackHoleTextures55(_ device:MTLDevice)
            throws -> MTLTexture {
            let n=BlackHoleSky55.imageSize
            let desc=MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat:.bgra8Unorm,width:n,height:n,mipmapped:false)
            desc.textureType = .type2DArray
            desc.arrayLength = 3
            desc.storageMode = .shared
            desc.usage=[.shaderRead]
            guard let tex=device.makeTexture(descriptor:desc) else {
                throw NSError(domain:"ASTEROIDY iOS Metal",code:14,
                              userInfo:[NSLocalizedDescriptionKey:
                               "Nie można utworzyć trzech źródłowych warstw czarnej dziury 640px"])
            }
            for slice in 0..<3 {
                let image=BlackHoleSky55.textureBGRA(slice:slice)
                image.withUnsafeBytes { bytes in
                    if let p=bytes.baseAddress {
                        tex.replace(region:MTLRegionMake2D(0,0,n,n),
                                    mipmapLevel:0,slice:slice,
                                    withBytes:p,bytesPerRow:n*4,
                                    bytesPerImage:n*n*4)
                    }
                }
            }
            return tex
        }
    
        static func makeDeepPlanetTextures55(_ device:MTLDevice)
            throws -> MTLTexture {
            let w=DeepSkyPlanets55.textureWidth
            let h=DeepSkyPlanets55.textureHeight
            let d=MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat:.bgra8Unorm,width:w,height:h,mipmapped:false)
            d.textureType = .type2DArray
            d.arrayLength = DeepSkyPlanets55.count
            d.storageMode = .shared
            d.usage=[.shaderRead]
            guard let tex=device.makeTexture(descriptor:d) else {
                throw NSError(domain:"ASTEROIDY iOS Metal",code:15,
                    userInfo:[NSLocalizedDescriptionKey:
                        "Nie można utworzyć trzech źródłowych planet 320x220"])
            }
            // Deliberately leave unseen slices uninitialized; the renderer
            // never samples a planet until uploadDeepPlanetSlice55 succeeds.
            return tex
        }
    
        static func uploadDeepPlanetSlice55(_ tex:MTLTexture,
                                                    style:Int) -> Bool {
            let w=DeepSkyPlanets55.textureWidth
            let h=DeepSkyPlanets55.textureHeight
            let img=DeepSkyPlanets55.textureBGRA(style:style)
            guard img.count == w*h*4 else {
                NSLog("ASTEROIDY iOS: nieprawidłowy rozmiar tekstury planety %ld", style)
                return false
            }
            img.withUnsafeBytes { raw in
                if let ptr=raw.baseAddress {
                    tex.replace(region:MTLRegionMake2D(0,0,w,h),
                                mipmapLevel:0,slice:style,
                                withBytes:ptr,bytesPerRow:w*4,
                                bytesPerImage:w*h*4)
                }
            }
            return true
        }
}
