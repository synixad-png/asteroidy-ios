import Foundation

/// GpuIntro41.DrawSkyPlanet55 and DrawSkyBlackHole55 only allocate
/// Bitmap after the source SkyProject55 visibility guard; original
/// GpuCosmos39.CloudLayer also caches its first generated texture.
/// This tests the resource gate, NOT Apple Metal itself.
@main struct SkyTextureGate55Tests {
    static func main() {
        let three=SkyTextureGate55.threePlanetsBytes
        let black=SkyTextureGate55.blackHoleBytes
        let nebula=SkyTextureGate55.nebulaBytes
        precondition(three == 844800)
        precondition(black == 4915200)
        precondition(nebula == 524288)
        precondition(SkyTextureGate55.deferredTotalBytes == 6284288)

        for n in 0..<64 {
            var source=SkyTextureGate55()
            for _ in 0..<(n+1) {
                precondition(!source.shouldAllocate(visible:false))
                precondition(!source.attempted)
            }
            precondition(source.shouldAllocate(visible:true))
            precondition(source.attempted)
            for _ in 0..<128 {
                precondition(!source.shouldAllocate(visible:true))
                precondition(!source.shouldAllocate(visible:false))
            }
        }

        var clouds=SkyTextureGate55()
        var worlds=SkyTextureGate55()
        var hole=SkyTextureGate55()
        // Flat training arena: nothing in the heavy source sky is
        // visible; no 3x640 black hole or 3x320 planet allocation.
        for _ in 0..<240 {
            precondition(!clouds.shouldAllocate(visible:false))
            precondition(!worlds.shouldAllocate(visible:false))
            precondition(!hole.shouldAllocate(visible:false))
        }
        precondition(!clouds.attempted && !worlds.attempted && !hole.attempted)
        // Camera sees the first nebula but not any planetary object.
        precondition(clouds.shouldAllocate(visible:true))
        precondition(!worlds.shouldAllocate(visible:false))
        precondition(!hole.shouldAllocate(visible:false))
        // First sphere planet enters camera; load the one common
        // source-planet array once and preserve it across camera turns.
        precondition(worlds.shouldAllocate(visible:true))
        for _ in 0..<240 {
            precondition(!worlds.shouldAllocate(visible:true))
            precondition(!worlds.shouldAllocate(visible:false))
        }
        // Black hole only when it actually enters the source camera.
        precondition(hole.shouldAllocate(visible:true))
        precondition(!hole.shouldAllocate(visible:true))
        // For an allocation failure, the gate has nevertheless
        // recorded its single attempt: no retry every 60 Hz frame.
        var failed=SkyTextureGate55()
        precondition(failed.shouldAllocate(visible:true))
        for _ in 0..<500 {
            precondition(!failed.shouldAllocate(visible:true))
        }

        // The original GpuIntro41.BuildDeepPlanet55 produces a 320x220
        // Bitmap separately for every visible planet style. A shared
        // three-slice MTLTexture must not imply generating all three CPU
        // images at the first visible planet. Test every visible order.
        let orders: [[Int]] = [
            [0,1,2], [0,2,1], [1,0,2],
            [1,2,0], [2,0,1], [2,1,0]
        ]
        for order in orders {
            var slices=SkyTextureSliceCache55(count:3)
            precondition(slices.uploadedCount == 0)
            precondition(!slices.needsUpload(style:-1))
            precondition(!slices.needsUpload(style:3))
            for (n,style) in order.enumerated() {
                // A newly encountered source planet can generate pixels.
                precondition(slices.needsUpload(style:style))
                // Other hidden styles remain deferred.
                for hidden in order.dropFirst(n+1) {
                    precondition(slices.needsUpload(style:hidden))
                }
                slices.markUploaded(style:style)
                precondition(slices.uploadedCount == n+1)
                // Future rendered frames reuse the source bitmap.
                for _ in 0..<240 {
                    precondition(!slices.needsUpload(style:style))
                }
            }
            precondition(slices.uploadedCount == 3)
        }
        // A texture allocation and pixel generation are different
        // gates: even with an array allocated, two hidden styles remain
        // ungenerated until individually visible in SkyProject55.
        var onlyOne=SkyTextureSliceCache55(count:3)
        onlyOne.markUploaded(style:1)
        for _ in 0..<600 {
            precondition(onlyOne.uploadedCount == 1)
            precondition(onlyOne.needsUpload(style:0))
            precondition(onlyOne.needsUpload(style:2))
            precondition(!onlyOne.needsUpload(style:1))
        }

        // GpuCosmos39.CloudLayer keeps NebulaTexture(theme) in a
        // separate lazy cache. The shared Metal texture2DArray is not
        // a reason to generate the other, invisible 256px theme.
        for first in 0..<2 {
            let later=1-first
            var themes=SkyTextureSliceCache55(count:2)
            precondition(themes.uploadedCount == 0)
            precondition(themes.needsUpload(style:first))
            precondition(themes.needsUpload(style:later))
            themes.markUploaded(style:first)
            for _ in 0..<720 {
                precondition(themes.uploadedCount == 1)
                precondition(!themes.needsUpload(style:first))
                precondition(themes.needsUpload(style:later))
            }
            themes.markUploaded(style:later)
            precondition(themes.uploadedCount == 2)
            for _ in 0..<720 {
                precondition(!themes.needsUpload(style:first))
                precondition(!themes.needsUpload(style:later))
            }
        }

        print("PASS: source v556 lazy GPU texture gate: flat mode zero loads,")
        print("      source SkyProject55 visibility first, no per-frame retries,")
        print("      deferred 6,284,288 bytes of uncompressed GPU textures")
        print("LIMITATION: pure Swift resource lifetime test; Apple Metal not compiled")
    }
}
