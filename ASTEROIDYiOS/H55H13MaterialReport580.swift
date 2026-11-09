import Foundation

/// H13 diagnostic for the authenticated GLB already imported by H55Asset580.
/// Reads only the JSON chunk once, off the display thread. The scanner itself
/// never changes scene nodes, geometry, shaders or the original user file.
enum H55H13MaterialReport580 {
    enum Failure: Error { case invalidHeader, invalidDocument, invalidMaterials }

    struct EmissionSource {
        let index: Int
        let name: String
        let factor: [Float]
        let strength: Float
        let hasTexture: Bool
        let uniqueName: Bool
        var label: String {
            "\(index): \(name) | strength=\(strength) | factor=\(factor) | texture=\(hasTexture) | unique=\(uniqueName)"
        }
    }

    struct Snapshot {
        let materialCount: Int
        let meshCount: Int
        let imageCount: Int
        let opaque: Int
        let masked: Int
        let blended: [String]
        let doubleSided: Int
        let baseColorTextured: Int
        let extensions: [String: Int]
        let transmissionOrVolume: [String]
        let issues: [String]
        let emissive: [EmissionSource]
        let clearcoat: [String]

        var text: String {
            var lines = [
                "ASTEROIDY H55 / PC v580 — RAPORT H13",
                "Źródło: zaimportowany i zweryfikowany plik hangar_h55.glb",
                "Materiały: \(materialCount) | Siatki: \(meshCount) | Obrazy: \(imageCount)",
                "OPAQUE: \(opaque) | MASK: \(masked) | BLEND: \(blended.count)",
                "Dwustronne: \(doubleSided) | Z teksturą baseColor: \(baseColorTextured)"
            ]
            if !extensions.isEmpty {
                lines.append("Rozszerzenia glTF:")
                for key in extensions.keys.sorted() {
                    lines.append("  \(key): \(extensions[key] ?? 0)")
                }
            }
            if !blended.isEmpty {
                lines.append("Materiały BLEND (indeks: nazwa):")
                lines.append(contentsOf: blended)
            }
            if !clearcoat.isEmpty {
                lines.append("Materiały clearcoat (obsługa bazowa GLTFKit2):")
                lines.append(contentsOf: clearcoat)
            }
            if !emissive.isEmpty {
                lines.append("Materiały emissive_strength (wartości źródłowe GLB):")
                lines.append(contentsOf: emissive.map { $0.label })
            }
            if !transmissionOrVolume.isEmpty {
                lines.append("Materiały transmission/volume (do porównania wizualnego):")
                lines.append(contentsOf: transmissionOrVolume)
            }
            if !issues.isEmpty {
                lines.append("Nieprawidłowe lub nieznane metadane:")
                lines.append(contentsOf: issues)
            }
            lines.append("Tylko dane glTF; nie potwierdza wyglądu szkła, FPS, dźwięków ani zgodności GPU z PC.")
            return lines.joined(separator: "\n")
        }
    }

    private static func word(_ bytes: Data, _ offset: Int) -> UInt32 {
        UInt32(bytes[offset]) | (UInt32(bytes[offset + 1]) << 8) |
            (UInt32(bytes[offset + 2]) << 16) | (UInt32(bytes[offset + 3]) << 24)
    }

    static func inspect(_ url: URL) throws -> Snapshot {
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        let header = try file.read(upToCount: 20) ?? Data()
        guard header.count == 20, word(header, 0) == 0x46546C67,
              word(header, 4) == 2, word(header, 16) == 0x4E4F534A
        else { throw Failure.invalidHeader }
        let size = Int(word(header, 12))
        let declared = UInt64(word(header, 8))
        guard size > 0, size <= 32 * 1024 * 1024, size % 4 == 0,
              let actual = (try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.uint64Value,
              actual == declared, UInt64(size) + 20 <= declared
        else { throw Failure.invalidHeader }
        let json = try file.read(upToCount: size) ?? Data()
        guard json.count == size else { throw Failure.invalidDocument }
        if declared > UInt64(size) + 20 {
            let bin = try file.read(upToCount: 8) ?? Data()
            guard bin.count == 8, word(bin, 4) == 0x004E4942,
                  UInt64(size) + 28 + UInt64(word(bin, 0)) == declared
            else { throw Failure.invalidDocument }
        }
        guard let doc = try JSONSerialization.jsonObject(with: json) as? [String: Any],
              let asset = doc["asset"] as? [String: Any],
              asset["version"] as? String == "2.0"
        else { throw Failure.invalidDocument }
        let rawMaterials = doc["materials"] as? [Any] ?? []
        guard doc["materials"] == nil || doc["materials"] is [Any],
              rawMaterials.allSatisfy({ $0 is [String: Any] })
        else { throw Failure.invalidMaterials }
        let materials = rawMaterials.compactMap { $0 as? [String: Any] }
        var opaque = 0, masked = 0, doubleSided = 0, baseColorTextured = 0
        var blended = [String](), transmissionOrVolume = [String](), issues = [String]()
        var extensions = [String: Int]()
        var emissive = [EmissionSource]()
        var clearcoat = [String]()
        let names = materials.compactMap { $0["name"] as? String }
        let namesCount = Dictionary(names.map { ($0, 1) },
                                    uniquingKeysWith: +)
        for (index, material) in materials.enumerated() {
            let name = (material["name"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                ?? "material[\(index)]"
            let label = "\(index): \(name)"
            let alpha = material["alphaMode"] as? String ?? "OPAQUE"
            switch alpha {
            case "OPAQUE": opaque += 1
            case "MASK": masked += 1
            case "BLEND": blended.append(label)
            default: issues.append("\(label): nieznany alphaMode=\(alpha)")
            }
            if let sided = material["doubleSided"] {
                if let value = sided as? Bool {
                    if value { doubleSided += 1 }
                } else { issues.append("\(label): doubleSided nie jest bool") }
            }
            if let pbr = material["pbrMetallicRoughness"] {
                if let data = pbr as? [String: Any] {
                    if data["baseColorTexture"] is [String: Any] {
                        baseColorTextured += 1
                    }
                } else { issues.append("\(label): błędne pbrMetallicRoughness") }
            }
            if let value = material["extensions"] {
                guard let entry = value as? [String: Any] else {
                    issues.append("\(label): rozszerzenia nie są obiektem")
                    continue
                }
                for key in entry.keys { extensions[key, default: 0] += 1 }
                if entry["KHR_materials_clearcoat"] != nil {
                    clearcoat.append(label)
                }
                if let raw = entry["KHR_materials_emissive_strength"] {
                    guard let value = raw as? [String: Any],
                          let number = value["emissiveStrength"] == nil ? NSNumber(value: 1) : (value["emissiveStrength"] as? NSNumber),
                          number.doubleValue.isFinite, number.doubleValue >= 0,
                          number.doubleValue <= Double(Float.greatestFiniteMagnitude),
                          let sourceName = material["name"] as? String,
                          !sourceName.isEmpty else {
                        issues.append("\(label): nieprawidłowe emissiveStrength lub brak nazwy")
                        continue
                    }
                    let factorValues = (material["emissiveFactor"] as? [NSNumber]) ??
                        [NSNumber(value: 0), NSNumber(value: 0), NSNumber(value: 0)]
                    guard factorValues.count == 3,
                          factorValues.allSatisfy({ $0.doubleValue.isFinite && $0.doubleValue >= 0 && $0.doubleValue <= 1 }) else {
                        issues.append("\(label): nieprawidłowy emissiveFactor")
                        continue
                    }
                    emissive.append(.init(index: index, name: sourceName,
                        factor: factorValues.map { $0.floatValue },
                        strength: number.floatValue,
                        hasTexture: material["emissiveTexture"] is [String: Any],
                        uniqueName: namesCount[sourceName] == 1))
                }
                if entry["KHR_materials_transmission"] != nil ||
                    entry["KHR_materials_volume"] != nil {
                    transmissionOrVolume.append(label)
                }
            }
        }
        let meshes = (doc["meshes"] as? [Any])?.count ?? 0
        let images = (doc["images"] as? [Any])?.count ?? 0
        return Snapshot(materialCount: materials.count, meshCount: meshes,
                        imageCount: images, opaque: opaque, masked: masked,
                        blended: blended, doubleSided: doubleSided,
                        baseColorTextured: baseColorTextured, extensions: extensions,
                        transmissionOrVolume: transmissionOrVolume, issues: issues,
                        emissive: emissive, clearcoat: clearcoat)
    }
}
