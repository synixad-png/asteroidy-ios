import Foundation

/// Source dimensions from Windows/src/HudLayout.cs RegisterDefaults.
/// The approved v600 JSON stores mutable positions, not hitbox geometry.
/// One immutable source supplies touch editor bounds and per-widget pulses.
enum HudWidgetGeometry600 {
    struct Size:Equatable {
        let width:Double
        let height:Double
    }

    static func size(_ id:String)->Size? {
        switch id {
        case "status.mode":return Size(width:280,height:24)
        case "status.weapon":return Size(width:550,height:24)
        case "status.sector":return Size(width:151,height:25)
        case "status.score":return Size(width:106,height:25)
        case "status.money":return Size(width:148,height:25)
        case "status.lives":return Size(width:83,height:25)
        case "status.frame":return Size(width:1242,height:65)
        case "radar":return Size(width:178,height:192)

        case "hull.label","armor.label","shield.label":
            return Size(width:96,height:23)
        case "hull.bar","armor.bar","shield.bar":
            return Size(width:148,height:10)
        case "hull.value","armor.value","shield.value":
            return Size(width:36,height:23)

        case "ion.icon","bomb.icon","shield_charge.icon","boost.icon":
            return Size(width:50,height:50)
        case "ion.label","bomb.label","shield_charge.label","boost.label":
            return Size(width:90,height:22)
        case "ion.value","bomb.value","shield_charge.value","boost.value":
            return Size(width:88,height:22)

        case "mission.notice":return Size(width:570,height:40)
        case "mission.clear_title":return Size(width:450,height:55)
        case "mission.clear_body":return Size(width:450,height:35)
        case "mission.next":return Size(width:460,height:46)
        case "objective.title":return Size(width:350,height:23)
        case "objective.info":return Size(width:570,height:23)
        case "flame.title":return Size(width:300,height:24)
        case "flame.bar":return Size(width:180,height:5)
        case "coop.status":return Size(width:286,height:26)

        case "boss.panel":return Size(width:545,height:105)
        case "boss.title":return Size(width:330,height:27)
        case "boss.health_text":return Size(width:160,height:27)
        case "boss.health_bar":return Size(width:515,height:5)
        case "boss.modules":return Size(width:515,height:30)
        case "boss.warning":return Size(width:515,height:26)
        case "boss.warning_bar":return Size(width:515,height:3)

        case "hud.planetarium":return Size(width:250,height:135)
        default:return nil
        }
    }

    /// Exact PC F6 drag region: keep at least 12 logical pixels on-screen.
    static func xRange(for widget:HudLayout600.Widget)->ClosedRange<Double>? {
        guard let dims=size(widget.id) else{return nil}
        return (-dims.width*widget.scale+12)...1268
    }
    static func yRange(for widget:HudLayout600.Widget)->ClosedRange<Double>? {
        guard let dims=size(widget.id) else{return nil}
        return (-dims.height*widget.scale+12)...708
    }
    static func scaleRange(for widget:HudLayout600.Widget)->ClosedRange<Double> {
        widget.is3D ? 0.1...6 : 0.25...3
    }
}
