import Foundation
import Metal

/// Source GpuIntro41/GpuCosmos39 visibility-driven texture lifecycle.
/// These are the verified identical implementations formerly duplicated
/// in MetalRenderer and SourceCombatSky. All textures, gates and slice
/// caches are passed by inout from each INDIVIDUAL renderer instance;
/// there is deliberately no global GPU cache or shared ownership.
enum SourceSkyTextureLifecycle55 {
    static func ensureCloudTextures55(device:MTLDevice,camera:SphereCamera67,sourceCloudLayers55:[SphereNebula556.Layer],nebulaTexture:inout MTLTexture?,nebulaLoadGate:inout SkyTextureGate55,nebulaSliceCache55:inout SkyTextureSliceCache55)->MTLTexture? {
            // Both original GpuCosmos39.NebulaTexture themes are cached now:
            // preserve the current GPU texture array, and let its existing
            // vertex shader project all 36 layers per current camera frame.
            // Recomputing 36 Swift projections + a Set here every frame
            // cannot change which texture is sampled once both exist.
            if let cached=nebulaTexture, nebulaSliceCache55.allUploaded {
                return cached
            }
            // GpuCosmos39.CloudLayer caches each NebulaTexture(theme) on its
            // own first visible use. The original sphere preview only uses
            // themes 0 and 1 across the fixed 24+12 source cloud layers.
            // A 36-direction cache avoids recomputing source sin/cos offsets.
            let visibleThemes=Set(sourceCloudLayers55.compactMap { layer -> Int? in
                layer.projected(camera:camera) != nil ? layer.theme : nil
            })
            let texture: MTLTexture
            if let current=nebulaTexture {
                texture=current
            } else {
                guard nebulaLoadGate.shouldAllocate(visible:!visibleThemes.isEmpty)
                else { return nil }
                do {
                    let created=try SourceSkyAssetFactory568.makeNebulaTextures556(device)
                    nebulaTexture=created
                    texture=created
                } catch {
                    NSLog("ASTEROIDY iOS: źródłowe NebulaTexture: %@", String(describing:error))
                    return nil
                }
            }
            // Only the texture themes that actually project into this
            // camera are generated/uploaded. The second theme may appear
            // later; unseen slices are never sampled by the shader.
            for theme in 0..<SphereNebula556.orbitThemeCount
                where visibleThemes.contains(theme) &&
                      nebulaSliceCache55.needsUpload(style:theme) {
                guard SourceSkyAssetFactory568.uploadNebulaSlice556(texture,theme:theme) else {
                    return nil
                }
                nebulaSliceCache55.markUploaded(style:theme)
            }
            return texture
        }

    static func ensureDeepPlanetTextures55(device:MTLDevice,style:Int,deepPlanetTextures:inout MTLTexture?,deepPlanetLoadGate:inout SkyTextureGate55,deepPlanetSliceCache55:inout SkyTextureSliceCache55)->MTLTexture? {
            guard (0..<DeepSkyPlanets55.count).contains(style) else { return nil }
            // The original GpuIntro41.DrawSkyPlanet55 builds each style's
            // Bitmap only AFTER its own SkyProject55 visibility check.
            // Share one GPU array but generate/upload CPU pixels one slice
            // at a time, never for off-screen planet styles.
            let texture: MTLTexture
            if let current=deepPlanetTextures {
                texture=current
            } else {
                guard deepPlanetLoadGate.shouldAllocate(visible: true)
                else { return nil }
                do {
                    let created=try SourceSkyAssetFactory568.makeDeepPlanetTextures55(device)
                    deepPlanetTextures=created
                    texture=created
                } catch {
                    NSLog("ASTEROIDY iOS: źródłowe planety 320px: %@", String(describing:error))
                    return nil
                }
            }
            if deepPlanetSliceCache55.needsUpload(style:style) {
                guard SourceSkyAssetFactory568.uploadDeepPlanetSlice55(texture,style:style) else {
                    return nil
                }
                deepPlanetSliceCache55.markUploaded(style:style)
            }
            return texture
        }

    static func ensureBlackHoleTextures55(device:MTLDevice,blackHoleTextures:inout MTLTexture?,blackHoleLoadGate:inout SkyTextureGate55)->MTLTexture? {
            if let current=blackHoleTextures { return current }
            guard blackHoleLoadGate.shouldAllocate(visible: true) else { return nil }
            do {
                let created=try SourceSkyAssetFactory568.makeBlackHoleTextures55(device)
                blackHoleTextures=created
                return created
            } catch {
                NSLog("ASTEROIDY iOS: źródłowa czarna dziura 640px: %@", String(describing:error))
                return nil
            }
        }
}
