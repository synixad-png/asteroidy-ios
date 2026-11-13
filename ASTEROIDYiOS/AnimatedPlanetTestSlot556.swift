import Foundation
import CryptoKit

/// The source-authenticated temporary visual planet in the sector-05
/// test slot. This is NOT a new campaign mission or unlock. Future GLB
/// replacements change this binding and its exported data, never the
/// existing Metal/physics path or the 26-sector campaign.
enum AnimatedPlanetTestSlot556 {
    static let sector=5
    static let name="BOREAS"
    static let sourceGLB="Shared/assets/planets/boreas_ferrofluid.glb"
    static let meshName="Boreas556"
    static let animationName="Boreas556"
    static let bindingName="BoreasMorphBinding556"
    static let nodeTracksName="Boreas556"
    static let duration:Double=5

    private static let assetHashes:[String:String]=[
        "Boreas556.as3d":
            "0a18d88a734906811fc6421d79d68a56a2ae4bd7dd7a622fc89c46a4cd5fbf9b",
        "Boreas556.asmo":
            "33c7bec0a53fe8a63e0c351658155ee74fc364cddef8ec261af15d6675a103a6",
        "BoreasMorphBinding556.json":
            "f5f099707a1e63582934dc2bd26155e739225db26f3d358fd4a100fff9e50593",
        "Boreas556.asnt":
            "bdf22733cfe6a1314517537e2400019a97c3a83507b8f654fd1307dbf9809edc"
    ]

    static func resourceURL(_ name:String,_ ext:String)->URL? {
        Bundle.main.url(forResource:name,withExtension:ext) ??
        Bundle.main.url(forResource:name,withExtension:ext,subdirectory:"Assets")
    }

    // Keep validation out of per-frame drawing; verify once when entering
    // the atlas/test. A missing or substituted model is never displayed.
    static let sourceAssetsVerified:Bool = {
        for (filename,expected) in assetHashes {
            let parts=(filename as NSString)
            guard let url=resourceURL(parts.deletingPathExtension,parts.pathExtension),
                  let bytes=try? Data(contentsOf:url,options:.mappedIfSafe),
                  SHA256.hash(data:bytes).map({
                      String(format:"%02x",$0)
                  }).joined()==expected else { return false }
        }
        return true
    }()
}
