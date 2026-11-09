import Foundation

/// H13 verifies the same JSON-only material statistics exported by the iOS
/// hangar after importing a real authenticated GLB. The fixture is synthetic:
/// this test must never claim that the 126 MB hangar was rendered on a device.
@main struct H55H13MaterialReport580Tests {
    static func little(_ number: UInt32) -> Data {
        var value = number.littleEndian
        return withUnsafeBytes(of: &value) { Data($0) }
    }

    static func writeGLB(_ url: URL, _ doc: [String: Any],
                         includeBIN: Bool = false) throws {
        var json = try JSONSerialization.data(withJSONObject: doc, options: [.sortedKeys])
        json.append(contentsOf: repeatElement(UInt8(32),
                                              count: (4 - json.count % 4) % 4))
        let binaryLength = includeBIN ? 4 : 0
        let total = 20 + json.count + (includeBIN ? 8 + binaryLength : 0)
        var glb = little(0x46546C67) + little(2) + little(UInt32(total))
        glb += little(UInt32(json.count)) + little(0x4E4F534A) + json
        if includeBIN {
            glb += little(UInt32(binaryLength)) + little(0x004E4942)
            glb += Data([1,2,3,4])
        }
        try glb.write(to: url)
    }

    static func main() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("h13-material-report-\(UUID())", isDirectory: true)
        try FileManager.default.createDirectory(at: directory,
                                                 withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("synthetic.glb")
        let fixture: [String: Any] = [
            "asset": ["version": "2.0"],
            "meshes": [["primitives": []]],
            "images": [["mimeType": "image/png"]],
            "materials": [
                ["name": "Opaque floor"],
                ["name": "Mask fence", "alphaMode": "MASK", "doubleSided": true],
                ["name": "Window", "alphaMode": "BLEND",
                 "pbrMetallicRoughness": ["baseColorTexture": ["index": 0]]],
                ["name": "Transmission",
                 "emissiveFactor": [0.2, 0.4, 0.5],
                 "emissiveTexture": ["index": 0],
                 "extensions": [
                    "KHR_materials_transmission": ["transmissionFactor": 0.7],
                    "KHR_materials_volume": ["thicknessFactor": 0.1],
                    "KHR_materials_clearcoat": ["clearcoatFactor": 0.4],
                    "KHR_materials_emissive_strength": ["emissiveStrength": 2.5]
                ]]
            ]
        ]
        try writeGLB(path, fixture, includeBIN: true)
        let original = try Data(contentsOf: path)
        let result = try H55H13MaterialReport580.inspect(path)
        assert(result.materialCount == 4 && result.meshCount == 1 && result.imageCount == 1)
        assert(result.opaque == 2 && result.masked == 1 && result.blended == ["2: Window"])
        assert(result.doubleSided == 1 && result.baseColorTextured == 1)
        assert(result.transmissionOrVolume == ["3: Transmission"])
        assert(result.extensions["KHR_materials_transmission"] == 1)
        assert(result.extensions["KHR_materials_volume"] == 1)
        assert(result.extensions["KHR_materials_clearcoat"] == 1)
        assert(result.extensions["KHR_materials_emissive_strength"] == 1)
        assert(result.clearcoat == ["3: Transmission"])
        assert(result.emissive.count == 1)
        assert(result.emissive[0].name == "Transmission")
        assert(result.emissive[0].strength == 2.5 && result.emissive[0].hasTexture)
        assert(result.emissive[0].factor == [0.2, 0.4, 0.5])
        assert(result.emissive[0].uniqueName)
        let gains = H55H13EmissionRules580.gains(result.emissive[0])!
        assert(abs(gains[0] - 0.5) < 0.0001 && abs(gains[1] - 1) < 0.0001 &&
               abs(gains[2] - 1.25) < 0.0001)
        let retained = "#pragma body\\n_surface.diffuse *= float4(1.0);"
        let modifier = H55H13EmissionRules580.modifier(existing: retained, gains: gains)!
        assert(modifier.hasPrefix(retained))
        assert(modifier.contains("_surface.emission.rgb *= float3(0.5, 1.0, 1.25)"))
        assert(H55H13EmissionRules580.modifier(existing: retained, gains: [1,1,1]) == retained)
        assert(result.issues.isEmpty)
        assert(result.text.contains("3: Transmission"))
        assert(result.text.contains("nie potwierdza wyglądu szkła"))
        let afterInspection = try Data(contentsOf: path)
        assert(afterInspection == original, "Reading must not change the GLB")
        try writeGLB(path, ["asset": ["version": "2.0"], "materials": [
            ["name": "Bad alpha", "alphaMode": "CUSTOM", "doubleSided": "true"],
            "not a material"
        ]])
        do {
            _ = try H55H13MaterialReport580.inspect(path)
            preconditionFailure("Non-object material accepted")
        } catch H55H13MaterialReport580.Failure.invalidMaterials {}
        try writeGLB(path, ["asset": ["version": "2.0"], "materials": [
            ["name": "Bad alpha", "alphaMode": "CUSTOM", "doubleSided": "true"]
        ]])
        let warnings = try H55H13MaterialReport580.inspect(path)
        assert(warnings.issues.count == 2)
        // Duplicate glTF material names cannot safely map to SceneKit
        // material instances: the renderer must not apply corrections.
        try writeGLB(path, ["asset": ["version": "2.0"], "materials": [
            ["name": "Same", "extensions": ["KHR_materials_emissive_strength":
                ["emissiveStrength": 4.0]]],
            ["name": "Same", "extensions": ["KHR_materials_emissive_strength":
                ["emissiveStrength": 2.0]]]
        ]])
        let duplicate = try H55H13MaterialReport580.inspect(path)
        assert(duplicate.emissive.count == 2)
        assert(duplicate.emissive.allSatisfy { !$0.uniqueName })
        assert(duplicate.emissive.allSatisfy { H55H13EmissionRules580.gains($0) == nil })
        try writeGLB(path, ["asset": ["version": "2.0"], "materials": [
            ["name": "Untextured", "emissiveFactor": [0.2, 0.1, 0.4],
             "extensions": ["KHR_materials_emissive_strength": ["emissiveStrength": 4.0]]]
        ]])
        let solid = try H55H13MaterialReport580.inspect(path)
        assert(H55H13EmissionRules580.gains(solid.emissive[0]) == [4,4,4])
        try writeGLB(path, ["asset": ["version": "2.0"], "materials": [
            ["name": "No strength", "extensions": ["KHR_materials_emissive_strength": [:]]]
        ]])
        let unit = try H55H13MaterialReport580.inspect(path)
        assert(unit.emissive[0].strength == 1)
        assert(H55H13EmissionRules580.gains(unit.emissive[0]) == [1,1,1])
        try writeGLB(path, ["asset": ["version": "2.0"], "materials": [
            ["name": "Bad emission", "extensions": [
                "KHR_materials_emissive_strength": ["emissiveStrength": -2.0]]]
        ]])
        let rejected = try H55H13MaterialReport580.inspect(path)
        assert(rejected.emissive.isEmpty && rejected.issues.count == 1)
        let valid = try Data(contentsOf: path)
        try Data(valid.dropLast(4)).write(to: path)
        do {
            _ = try H55H13MaterialReport580.inspect(path)
            preconditionFailure("Truncated GLB accepted")
        } catch H55H13MaterialReport580.Failure.invalidHeader {}
        print("PASS H13 native: GLB metadata, emissive strength/factors, texture/no texture, clearcoat, duplicates, shader composition, read-only")
    }
}
