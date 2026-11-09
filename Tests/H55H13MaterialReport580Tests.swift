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
                ["name": "Transmission", "extensions": [
                    "KHR_materials_transmission": ["transmissionFactor": 0.7],
                    "KHR_materials_volume": ["thicknessFactor": 0.1]
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
        assert(result.issues.isEmpty)
        assert(result.text.contains("3: Transmission"))
        assert(result.text.contains("nie potwierdza wyglądu szkła"))
        assert(try Data(contentsOf: path) == original, "Reading must not change the GLB")
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
        let valid = try Data(contentsOf: path)
        try Data(valid.dropLast(4)).write(to: path)
        do {
            _ = try H55H13MaterialReport580.inspect(path)
            preconditionFailure("Truncated GLB accepted")
        } catch H55H13MaterialReport580.Failure.invalidHeader {}
        print("PASS H13 native: JSON-only material report, real BIN header, alpha, double-sided, extensions, read-only and fail closed")
    }
}
