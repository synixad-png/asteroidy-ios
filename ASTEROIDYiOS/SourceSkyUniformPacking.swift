import Foundation

/// Encodes the original GpuIntro41 sky overlays for the common Metal
/// BlackHoleRaster55 shader. Exact fields and order are source-verified.
/// Only pure per-draw packing is shared; the renderers keep separate states,
/// source textures, scene ordering, visibility gates and GPU ownership.
enum SourceSkyUniformPacking {
    static func planet(frame:SIMD4<Float>,
                       layers:[DeepSkyPlanets55.Overlay]) -> [SIMD4<Float>] {
        var uniforms:[SIMD4<Float>]=[frame]
        uniforms.reserveCapacity(1+layers.count*3)
        for layer in layers {
            uniforms.append(SIMD4(
                layer.radiusX,layer.radiusY,1,0))
            let (r,g,b,a)=layer.rgba
            uniforms.append(SIMD4(r*a,g*a,b*a,a))
            uniforms.append(SIMD4(
                Float(layer.textureSlice),0,0,0))
        }
        return uniforms
    }

    static func blackHole(screen:SIMD4<Float>,
                          layers:[BlackHoleSky55.Overlay]) -> [SIMD4<Float>] {
        var properties:[SIMD4<Float>]=[screen]
        properties.reserveCapacity(1+layers.count*3)
        for layer in layers {
            properties.append(SIMD4(
                layer.radiusX,layer.radiusY,
                cos(layer.angle),sin(layer.angle)))
            let (r,g,b,a)=layer.rgba
            properties.append(SIMD4(r*a,g*a,b*a,a))
            properties.append(SIMD4(
                layer.isTexture ? Float(layer.layer) : -1,
                0,0,0))
        }
        return properties
    }
}
