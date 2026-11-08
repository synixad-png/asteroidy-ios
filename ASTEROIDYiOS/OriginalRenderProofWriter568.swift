import Foundation

/// Shared persistence for source-verified rendering diagnostics:
/// GPU completion proofs and the opt-in native W3 menu state marker.
/// Never called by the ordinary per-frame Metal draw path; all callers
/// guard the original diagnostic conditions before invoking this writer.
enum OriginalRenderProofWriter568 {
    static func save(_ payload: [String: Any], filename: String) {
        guard let folder = FileManager.default.urls(
            for: .cachesDirectory, in: .userDomainMask).first else {
            NSLog("ASTEROIDY render proof directory unavailable: %@", filename)
            return
        }
        do {
            let bytes = try JSONSerialization.data(
                withJSONObject: payload, options: [.sortedKeys])
            try bytes.write(
                to: folder.appendingPathComponent(filename),
                options: .atomic)
        } catch {
            NSLog("ASTEROIDY render proof write failed (%@): %@",
                  filename, String(describing: error))
        }
    }
}
