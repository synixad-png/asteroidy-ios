import Foundation

/// Camera-only iOS accessibility calibration for the original H55 walk.
///
/// PC v580 / HubWalk375: 1.80 metres above the authoritative feet support.
/// The collision capsule, stair/slope support, jump, hand viewmodels and
/// original cameraFeet smoothing are deliberately unchanged.
enum H55EyeHeight580 {
    static let original:Float = H55Walk580.eyes
    static let minimum:Float = 1.55
    static let maximum:Float = 2.15
    private static let key="ASTEROIDY_H55_EYE_HEIGHT_580"

    static func valid(_ value:Float)->Float {
        value.isFinite ? min(maximum,max(minimum,value)) : original
    }
    static func load()->Float {
        guard let stored=UserDefaults.standard.object(forKey:key) as? NSNumber
        else{return original}
        return valid(stored.floatValue)
    }
    static func save(_ height:Float) {
        UserDefaults.standard.set(Double(valid(height)),forKey:key)
    }
    static func reset() {
        UserDefaults.standard.removeObject(forKey:key)
    }

    /// Check the actual camera's 9.5 cm safety sphere against H04 scene
    /// geometry. A higher visual viewpoint is never allowed through a
    /// ceiling; the player's physical capsule is not modified.
    static func safeY(feet:Float,desired:Float,
                      clear:(Float)->Bool)->Float {
        let target=valid(desired)
        let base=original
        if clear(feet+target) {return feet+target}
        // Search downward from the user's requested height in 5 cm steps.
        // If the scene itself has no safe camera point, fall back to the
        // original H55 height, never change the physics solver's feet.
        let steps=Int(ceil(max(0,target-minimum)/0.05))
        for i in 1...max(1,steps) {
            let test=target-Float(i)*0.05
            if test<minimum {break}
            if clear(feet+test) {return feet+test}
        }
        return feet+base
    }
}
