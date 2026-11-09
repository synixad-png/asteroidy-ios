import SceneKit

/// H13: one-time, opt-in-by-source correction for the three glTF materials
/// carrying KHR_materials_emissive_strength. No new lights, no fake meshes,
/// no changes to BLEND/clearcoat or any per-frame work.
@MainActor enum H55H13SceneMaterials580 {
    struct Outcome {
        let materialInstancesChanged: Int
        let sourceMaterialsMatched: Int
        let sourceMaterialsEligible: Int
        let ambiguousOrInvalid: Int
        var text: String {
            "H13 SceneKit emissive_strength: źródłowe \(sourceMaterialsEligible), " +
            "dopasowane \(sourceMaterialsMatched), skorygowane instancje \(materialInstancesChanged), " +
            "pominięte niejednoznaczne \(ambiguousOrInvalid). " +
            "Wynik nie jest testem poprawności HDR/GPU na urządzeniu."
        }
    }

    static func apply(_ snapshot: H55H13MaterialReport580.Snapshot,
                      nodes: [SCNNode]) -> Outcome {
        // The upstream GLTFKit2 0.5.15 importer sets SCNMaterial.name to
        // original GLTFMaterial.name. A duplicated name is not a safe index
        // mapping: leave it alone rather than patching the wrong material.
        let eligible = snapshot.emissive.filter { $0.uniqueName }
        let byName = Dictionary(eligible.map { ($0.name, $0) },
                                uniquingKeysWith: { first, _ in first })
        var seen = Set<ObjectIdentifier>()
        var matched = Set<String>()
        var changed = 0
        for node in nodes {
            guard let geometry = node.geometry else { continue }
            for material in geometry.materials {
                let identity = ObjectIdentifier(material)
                guard seen.insert(identity).inserted,
                      let name = material.name,
                      let source = byName[name],
                      let gains = H55H13EmissionRules580.gains(source) else { continue }
                matched.insert(name)
                var modifiers = material.shaderModifiers ?? [:]
                let previous = modifiers[.surface]
                guard let replacement = H55H13EmissionRules580.modifier(
                    existing: previous, gains: gains), replacement != previous else { continue }
                modifiers[.surface] = replacement
                material.shaderModifiers = modifiers
                changed += 1
            }
        }
        return Outcome(materialInstancesChanged: changed,
                       sourceMaterialsMatched: matched.count,
                       sourceMaterialsEligible: snapshot.emissive.count,
                       ambiguousOrInvalid: snapshot.emissive.count - eligible.count)
    }
}
