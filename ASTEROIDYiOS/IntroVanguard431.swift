import Foundation

/// Restores the original CPU/GPU-size Vanguard type=1 in the original
/// IntroScene41 cinematic, WITHOUT modifying its v556 AS3D file or
/// the independent spherical combat ship.
/// 
/// Actual PC v568 runtime resource:
///   Shared/assets/vanguard431/vanguard431.mesh.gz
///   (4311 header, 194427 vertices, first vertex below)
/// with Shared/assets/vanguard431/BakeInfo.json:
///   scale = 3.265866381849069,
///   center_glb.y = 0.18199390172958374.
///
/// The **current** Tools/bake_vanguard431.py says scale=2.88 and
/// center=0.12, but that stale script does NOT reproduce the embedded
/// v568 runtime resource. The actual binary + BakeInfo are authoritative.
///
/// The original game uses local axes (x=right,y=nose,z=dorsal),
/// as does iOS Tools/export_vanguard.py. Their exports differ by:
///    PC xyz = (glb.x, glb.z, glb.y - pcCenter) * pcScale
///    iOS xyz = (glb.x, glb.z, glb.y - iosCenter) * iosScale
/// Therefore the exact mapping from existing AS3D *local* positions
/// to original PC gameplay model space is uniform scale + Z shift.
/// When rendered, normalize by original sphere world radius 144.19674.
enum IntroVanguard431 {
    typealias V = SphereVector3

    static let pcBakedScale: Float = 3.265866381849069
    static let pcBakedYCenter: Float = 0.18199390172958374
    static let iosExportScale: Float = 0.32
    static let iosExportYCenter: Float = 0.18

    static var sourceUnitsPerPackedUnit: Float {
        pcBakedScale / iosExportScale
    }
    static var sourceLocalDorsalCorrection: Float {
        (iosExportYCenter-pcBakedYCenter)*pcBakedScale
    }

    static var normalizedShipModelScale: Float {
        sourceUnitsPerPackedUnit*IntroOrbit41.radiusNormalization
    }
    static var normalizedDorsalCorrection: Float {
        sourceLocalDorsalCorrection*IntroOrbit41.radiusNormalization
    }

    // Exact point mapping used for test fixtures from actual 4311
    // binary and glTF source POSITION, not an OBB or approximate radius.
    static func sourceLocalPosition(_ packed:V)->V {
        V(x:packed.x*sourceUnitsPerPackedUnit,
          y:packed.y*sourceUnitsPerPackedUnit,
          z:packed.z*sourceUnitsPerPackedUnit +
            sourceLocalDorsalCorrection)
    }

    static func sourceLocalFromGLB(_ glb:V)->V {
        V(x:glb.x*pcBakedScale,
          y:glb.z*pcBakedScale,
          z:(glb.y-pcBakedYCenter)*pcBakedScale)
    }
}
