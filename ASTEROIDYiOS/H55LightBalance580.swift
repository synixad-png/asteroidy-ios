import Foundation

/// PC v580 Windows/src/H55Renderer.cs Lights() fallback for the actual
/// hangar_h55.glb, which has 24 H46 proxy nodes but NO KHR_lights_punctual.
/// The 8-light budget and proximity score are source rules (not new lights).
enum H55LightBalance580 {
    static let budget=8

    static func isRed(_ name:String)->Bool {
        name.hasPrefix("H46_DOCK_") || name.hasPrefix("H46_UPPER_RED_")
    }
    static func isScanner(_ name:String)->Bool {
        name.contains("SCAN_SPOT")
    }
    static func sourceFallbackColor(_ name:String)->(r:Float,g:Float,b:Float) {
        if isRed(name) {return (2.5,0.14,0.05)}
        if isScanner(name) {return (0.45,2.4,2.9)}
        return (1.6,2.0,2.4)
    }
    static func score(_ name:String, distanceSquared:Float)->Float {
        guard distanceSquared.isFinite && distanceSquared>=0 else{return 0}
        let c=sourceFallbackColor(name)
        // Exactly PC Lights(): (R+G+B)/(40+distance squared).
        return (c.r+c.g+c.b)/(40+distanceSquared)
    }

    /// Conversion to SceneKit lighting units is NOT a physically exact
    /// OpenGL shader equivalence. 0.22 is PC's source punctual gain;
    /// reduced red-only gain is an iOS visual correction requested after
    /// device capture, isolated here without editing authored GLB materials.
    static func sceneIntensity(_ name:String,raw:Float)->Float {
        guard raw.isFinite && raw>0 else{return 0}
        let redVisualGain:Float=0.30
        return raw*0.22*(isRed(name) ? redVisualGain : 1)
    }
}
