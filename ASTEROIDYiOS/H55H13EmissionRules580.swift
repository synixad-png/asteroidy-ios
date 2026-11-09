import Foundation

/// Source-only glTF H13 emission correction. SceneKit's GLTFKit2 v0.5.15
/// imports emissive textures/factors but does not apply
/// KHR_materials_emissive_strength. These rules are testable without GPU.
enum H55H13EmissionRules580 {
    static func gains(_ source: H55H13MaterialReport580.EmissionSource) -> [Float]? {
        guard source.factor.count == 3,
              source.strength.isFinite, source.strength >= 0,
              source.factor.allSatisfy({ $0.isFinite && $0 >= 0 && $0 <= 1 }),
              source.uniqueName else { return nil }
        let values = source.hasTexture
            ? source.factor.map { $0 * source.strength }
            : [source.strength, source.strength, source.strength]
        guard values.allSatisfy({ $0.isFinite && $0 >= 0 }) else { return nil }
        return values
    }

    /// Do not use SCNMaterialProperty.intensity here: SceneKit specifies 0...1,
    /// which cannot express HDR glTF emission strengths greater than one.
    /// Instead retain GLTFKit2's existing modifiers and multiply its surface
    /// emissive vector, before SceneKit's lighting step.
    static func modifier(existing: String?,
                         gains: [Float]) -> String? {
        guard gains.count == 3,
              gains.allSatisfy({ $0.isFinite && $0 >= 0 }) else { return nil }
        if gains.allSatisfy({ $0 == 1 }) { return existing }
        func literal(_ value: Float) -> String {
            let result = String(format: "%.9g", locale: Locale(identifier: "en_US_POSIX"),
                                Double(value))
            return result.contains(".") || result.contains("e") || result.contains("E")
                ? result : result + ".0"
        }
        let body = "_surface.emission.rgb *= float3(\(literal(gains[0])), \(literal(gains[1])), \(literal(gains[2])));"
        let prefix = existing.flatMap { $0.isEmpty ? nil : $0 } ?? "#pragma body"
        return prefix + "\n" + body + "\n"
    }
}
