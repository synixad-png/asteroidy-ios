import Foundation

/// Original v556 source GpuIntro41.cs:62/115 creates each deep-space
/// Bitmap only after SkyProject55 has proved it is on screen.
/// GpuCosmos39.cs:7 lazily creates the two cloud textures on first
/// CloudLayer use. This simple gate prevents eagerly allocating large
/// 640x640/320x220 textures in the flat arena or on hidden sectors.
///
/// One attempt per renderer lifetime: if Metal resource creation fails,
/// the renderer logs the failure once and keeps running, rather than
/// trying to allocate a multi-megabyte texture every 60 Hz frame.
/// No timers, global caches, network or simulated Apple GPU results.
struct SkyTextureGate55 {
    private(set) var attempted = false

    mutating func shouldAllocate(visible: Bool) -> Bool {
        guard visible && !attempted else { return false }
        attempted = true
        return true
    }

    static let blackHoleBytes = 3 * 640 * 640 * 4
    static let threePlanetsBytes = 3 * 320 * 220 * 4
    static let nebulaBytes = 2 * 256 * 256 * 4
    static let deferredTotalBytes =
        blackHoleBytes + threePlanetsBytes + nebulaBytes
}
