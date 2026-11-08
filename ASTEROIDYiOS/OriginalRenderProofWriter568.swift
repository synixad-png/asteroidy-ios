import Foundation

/// Shared persistence for the two source-verified GPU completion proofs.
/// Called only by explicitly requested diagnostic command-buffer callbacks;
/// it is never used by the regular Metal draw path.
enum OriginalRenderProofWriter568 {
    static func save(_ payload: [String: Any], filename: String) {
        guard let folder = FileManager.default.urls(
            for: .cachesDirectory, in: .userDomainMask).first else {
            NSLog("ASTEROIDY GPU proof directory unavailable: %@", filename)
            return
        }
        do {
            let bytes = try JSONSerialization.data(
                withJSONObject: payload, options: [.sortedKeys])
            try bytes.write(
                to: folder.appendingPathComponent(filename),
                options: .atomic)
        } catch {
            NSLog("ASTEROIDY GPU proof write failed (%@): %@",
                  filename, String(describing: error))
        }
    }
}
