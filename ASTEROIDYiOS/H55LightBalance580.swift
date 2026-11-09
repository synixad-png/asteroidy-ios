import Foundation

/// PC v580 Windows/src/H55Renderer.cs Lights() fallback for the actual
/// hangar_h55.glb, which has 24 H46 proxy nodes but NO KHR_lights_punctual.
/// The 8-light budget and proximity score are source rules (not new lights).
enum H55LightBalance580 {
    static let budget=8
    /// H46 iOS correction: source rank remains intact *within* each family,
    /// but at most two red lamps may consume the eight local slots.
    /// The OpenGL renderer is not changed.
    static let maxRedActive=2

    struct Candidate {
        let name:String
        let distanceSquared:Float
    }

    static func selectedNames(_ candidates:[Candidate])->[String] {
        let ranked=candidates.map { ($0.name,score($0.name,distanceSquared:$0.distanceSquared)) }
            .filter { $0.1 > 0 }
            .sorted { a,b in a.1 == b.1 ? a.0 < b.0 : a.1 > b.1 }
        var selected=[String]()
        var seen=Set<String>()
        var red=0
        for (name,_) in ranked {
            if selected.count==budget { break }
            if seen.contains(name) { continue }
            if isRed(name) {
                if red==maxRedActive { continue }
                red+=1
            }
            selected.append(name)
            seen.insert(name)
        }
        return selected
    }

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

    /// Source H46 intensity -> SceneKit approximation, not photometric parity.
    /// Non-red local sources retain their gain; red is user-adjustable in iOS.
    static func sceneIntensity(_ name:String,raw:Float,
                               redGain:Float=H55LightingProfile580.defaultRed)->Float {
        guard raw.isFinite && raw>0 else{return 0}
        let safe=redGain.isFinite ? max(0,min(H55LightingProfile580.maximumRed,redGain))
                                  : H55LightingProfile580.defaultRed
        return raw*0.22*(isRed(name) ? safe : 1)
    }
}
