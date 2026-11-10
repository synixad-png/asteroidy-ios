import SwiftUI
import UniformTypeIdentifiers

/// Exact 46-widget PC v600 layout exchange for iOS Files.
/// Neither side writes the running mission or arbitrary GLB asset paths.
struct HudLayoutDocument600:FileDocument {
    static var readableContentTypes:[UTType] { [.json] }
    static var writableContentTypes:[UTType] { [.json] }

    var layout:HudLayout600

    init(layout:HudLayout600) {self.layout=layout}

    init(configuration:ReadConfiguration) throws {
        guard let bytes=configuration.file.regularFileContents else {
            throw HudLayout600.LayoutError.invalidLayout
        }
        layout=try HudLayout600.decodeJSON(bytes)
    }

    func fileWrapper(configuration:WriteConfiguration) throws->FileWrapper {
        FileWrapper(regularFileWithContents:try layout.encodeJSON())
    }
}
