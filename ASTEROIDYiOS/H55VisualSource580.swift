import Foundation

/// PC v580 Glass548.cs / GlassPrefab549.cs and original hangar_h55.glb.
/// Pure source rules: do not mutate glTF assets or construct geometry.
enum H55VisualSource580 {
    private static let separators=" _-./\\:()[]"
    private static func words(_ value:String)->Set<String> {
        Set(value.uppercased().split(whereSeparator:{separators.contains($0)}).map(String.init))
    }
    private static let paneWords:Set<String>=["GLASS","GLAZING","SZYBA"]
    private static let prefabPaneWords:Set<String>=["GLASS","GLAZING","SZYBA","SZKLO","PANE","VITRE"]
    private static let excluded:Set<String>=["FRAME","RAMA","RAMKA","BEZEL","GASKET","USZCZELKA","SEAL","SILL","PROFIL","SLUPEK","NIT","BOLT","FUTRYNA","HANDLE","HINGE","ZAWIAS","ALLOY","TITANIUM","SCREW","SRUBA","METAL"]

    /// PC renders even OPAQUE material glass in the transparent glass pass.
    /// Never convert frame, gasket or screw geometry to transparent panes.
    static func isGlassPane(node:String,material:String)->Bool {
        let n=words(node),m=words(material)
        guard n.isDisjoint(with:excluded) && m.isDisjoint(with:excluded) else{return false}
        if !n.isDisjoint(with:paneWords) || !m.isDisjoint(with:paneWords) {return true}
        let knownPrefab=node.uppercased().contains("GLASSWALL") || node.uppercased().contains("WINDOW")
        return knownPrefab && (!n.isDisjoint(with:prefabPaneWords) || !m.isDisjoint(with:prefabPaneWords))
    }

    /// Only original textured H34 ceiling; do not touch animated crane arms.
    static func isTexturedCeiling(node:String,material:String)->Bool {
        material.hasPrefix("H34_CEILING__") && node.lowercased().hasPrefix("05_ceiling / ")
    }

    /// Existing source emissive surface; no new shader or lights on the mesh.
    static func lampEmission(_ material:String)->(r:Double,g:Double,b:Double)? {
        switch material {
        case "H46_MAT_WHITE_HIGH_OUTPUT_EMISSIVE": return (1,1,1)
        case "H46_MAT_COLD_CYAN_EMISSIVE": return (0.11,0.72,0.90)
        case "H46_MAT_RED_DOCK_WARNING_EMISSIVE": return (1,0.035,0.02)
        case "H46_MAT_AMBER_SERVICE_EMISSIVE": return (0.8,0.27,0.025)
        default:return nil
        }
    }

    struct LightProxy {
        let kind:String
        let red:Double,green:Double,blue:Double
        let power:Float,range:Double,inner:Double,outer:Double
    }

    /// The exact 24 runtime-only fallback proxies embedded in source GLB.
    /// PC v580 H55Renderer.cs activates these by name if KHR lights are absent.
    static func lightProxy(_ name:String)->LightProxy? {
        if name.hasPrefix("H46_GENERAL_SPOT_") && name.hasSuffix("_KHR_SPOT") {
            return .init(kind:"spot",red:1,green:0.952,blue:0.89,
                         power:2300,range:30,inner:0.23,outer:0.49)
        }
        if name.hasPrefix("H46_WORK_SPOT_") && name.hasSuffix("_KHR_SPOT") {
            return .init(kind:"spot",red:0.86,green:0.94,blue:1,
                         power:6100,range:24,inner:0.23,outer:0.4)
        }
        if name.hasPrefix("H46_SCAN_SPOT_") && name.hasSuffix("_KHR_SPOT") {
            return .init(kind:"spot",red:0.1,green:0.78,blue:1,
                         power:420,range:24,inner:0.18,outer:0.33)
        }
        if name.hasPrefix("H46_DOCK_") && name.hasSuffix("_RED_POINT_LIGHT") {
            return .init(kind:"point",red:1,green:0.045,blue:0.026,
                         power:180,range:4.5,inner:0,outer:0)
        }
        if name.hasPrefix("H46_UPPER_RED_") && name.hasSuffix("_POINT") {
            return .init(kind:"point",red:1,green:0.065,blue:0.025,
                         power:90,range:6,inner:0,outer:0)
        }
        return nil
    }
}
