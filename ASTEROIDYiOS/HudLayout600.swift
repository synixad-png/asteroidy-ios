import Foundation

/// Exact approved PC v600 layout, embedded in the executable so a missing
/// resource-copy phase cannot silently restore outdated positions.
struct HudLayout600:Codable,Equatable {
    struct Widget:Codable,Equatable,Identifiable {
        var id:String
        var x:Double
        var y:Double
        var scale:Double
        var visible:Bool
        var glb:String?
        var yaw:Double?
        var pitch:Double?
        var roll:Double?
        var is3D:Bool {glb != nil}
    }
    var schema:Int
    var widgets:[Widget]
    private static let key="asteroidy.ios.hud.v600.layout"

    private static let approvedJSON = #"""
{"schema":1,"widgets":[{"id":"status.mode","x":34,"y":17,"scale":1,"visible":true},{"id":"status.weapon","x":34,"y":42,"scale":1,"visible":true},{"id":"status.sector","x":777,"y":17,"scale":1,"visible":true},{"id":"status.score","x":936,"y":17,"scale":1,"visible":true},{"id":"status.money","x":1050,"y":17,"scale":1,"visible":true},{"id":"status.lives","x":1195,"y":17,"scale":1,"visible":true},{"id":"status.frame","x":20,"y":17,"scale":1,"visible":true},{"id":"radar","x":14.1293,"y":526.7036,"scale":1,"visible":true},{"id":"hull.label","x":212.4047,"y":546.447,"scale":0.7738,"visible":true},{"id":"hull.bar","x":201.7023,"y":654.6442,"scale":0.9453,"visible":true},{"id":"hull.value","x":341,"y":565,"scale":1,"visible":true},{"id":"armor.label","x":210.9776,"y":597.3012,"scale":0.8552,"visible":true},{"id":"armor.bar","x":204.5563,"y":614.8741,"scale":0.9002,"visible":true},{"id":"armor.value","x":341,"y":613,"scale":1,"visible":true},{"id":"shield.label","x":208.8371,"y":631.7433,"scale":0.8574,"visible":true},{"id":"shield.bar","x":205.2698,"y":577.9584,"scale":0.9476,"visible":true},{"id":"shield.value","x":341,"y":661,"scale":1,"visible":true},{"id":"ion.icon","x":895,"y":603,"scale":1,"visible":true,"glb":"energy","yaw":0,"pitch":0,"roll":0},{"id":"ion.label","x":875,"y":658,"scale":1,"visible":true},{"id":"ion.value","x":876,"y":680,"scale":1,"visible":true},{"id":"bomb.icon","x":995,"y":603,"scale":1,"visible":true,"glb":"bomb","yaw":0,"pitch":0,"roll":0},{"id":"bomb.label","x":975,"y":658,"scale":1,"visible":true},{"id":"bomb.value","x":976,"y":680,"scale":1,"visible":true},{"id":"shield_charge.icon","x":1095,"y":603,"scale":1,"visible":true,"glb":"shield","yaw":0,"pitch":0,"roll":0},{"id":"shield_charge.label","x":1075,"y":658,"scale":1,"visible":true},{"id":"shield_charge.value","x":1076,"y":680,"scale":1,"visible":true},{"id":"boost.icon","x":1195,"y":603,"scale":1,"visible":true,"glb":"boost","yaw":0,"pitch":0,"roll":0},{"id":"boost.label","x":1175,"y":658,"scale":1,"visible":true},{"id":"boost.value","x":1176,"y":680,"scale":1,"visible":true},{"id":"mission.notice","x":385,"y":188,"scale":1,"visible":true},{"id":"mission.clear_title","x":415,"y":304,"scale":1,"visible":true},{"id":"mission.clear_body","x":415,"y":365,"scale":1,"visible":true},{"id":"mission.next","x":410,"y":310,"scale":1,"visible":true},{"id":"objective.title","x":20,"y":96,"scale":1,"visible":true},{"id":"objective.info","x":20,"y":119,"scale":1,"visible":true},{"id":"flame.title","x":20,"y":147,"scale":1,"visible":true},{"id":"flame.bar","x":20,"y":168,"scale":1,"visible":true},{"id":"coop.status","x":968,"y":93,"scale":1,"visible":true},{"id":"boss.panel","x":422,"y":79,"scale":1,"visible":true},{"id":"boss.title","x":432,"y":92,"scale":1,"visible":true},{"id":"boss.health_text","x":795,"y":92,"scale":1,"visible":true},{"id":"boss.health_bar","x":432,"y":116,"scale":1,"visible":true},{"id":"boss.modules","x":432,"y":125,"scale":1,"visible":true},{"id":"boss.warning","x":432,"y":150,"scale":1,"visible":true},{"id":"boss.warning_bar","x":432,"y":171,"scale":1,"visible":true},{"id":"hud.planetarium","x":64.7882,"y":553.0863,"scale":1.4702,"visible":true,"glb":"planetarium","yaw":0,"pitch":-20,"roll":0}]}
"""#

    static func defaults()->HudLayout600 {
        // This JSON is the byte-exact approved 46-widget source, not
        // the previous v568 hard-coded default positions.
        let data=Data(approvedJSON.utf8)
        guard let value=try? JSONDecoder().decode(HudLayout600.self,from:data),
              value.isValid else {
            // Fail visibly without terminating combat or substituting old v568 data.
            NSLog("ASTEROIDY HUD v600: approved layout invalid — no fallback layout")
            return HudLayout600(schema:1,widgets:[])
        }
        return value
    }
    // Bind original PC v600 model identities, never arbitrary user-supplied
    // asset paths from an imported layout.
    private static let expectedModels:[String:String]=[
        "ion.icon":"energy","bomb.icon":"bomb",
        "shield_charge.icon":"shield","boost.icon":"boost",
        "hud.planetarium":"planetarium"
    ]
    enum LayoutError:Error,LocalizedError {
        case invalidLayout
        var errorDescription:String? {
            "Układ HUD musi zawierać dokładnie 46 zgodnych elementów PC v600."
        }
    }
    static func decodeJSON(_ data:Data) throws->HudLayout600 {
        guard data.count<=65_536 else{throw LayoutError.invalidLayout}
        let value=try JSONDecoder().decode(HudLayout600.self,from:data)
        guard value.isValid else{throw LayoutError.invalidLayout}
        return value
    }
    func encodeJSON() throws->Data {
        guard isValid else{throw LayoutError.invalidLayout}
        let bytes=try JSONEncoder().encode(self)
        guard bytes.count<=65_536 else{throw LayoutError.invalidLayout}
        return bytes
    }
    var isValid:Bool {
        guard schema==1,widgets.count==46 else{return false}
        let originals=Self.approvedWidgetIDs
        guard Set(widgets.map(\.id)) == originals else{return false}
        return widgets.allSatisfy { item in
            guard item.glb==Self.expectedModels[item.id],
                  item.x.isFinite,item.y.isFinite,item.scale.isFinite,
                  HudWidgetGeometry600.scaleRange(for:item).contains(item.scale),
                  let xRange=HudWidgetGeometry600.xRange(for:item),
                  let yRange=HudWidgetGeometry600.yRange(for:item),
                  xRange.contains(item.x),yRange.contains(item.y) else{return false}
            return [item.yaw,item.pitch,item.roll].allSatisfy { value in
                guard let value else{return true}
                return value.isFinite && abs(value)<=180
            }
        }
    }
    private static var approvedWidgetIDs:Set<String> {
        // The defaults literal is validated against these stable keys.
        Set(["status.mode","status.weapon","status.sector","status.score",
             "status.money","status.lives","status.frame","radar",
             "hull.label","hull.bar","hull.value","armor.label","armor.bar",
             "armor.value","shield.label","shield.bar","shield.value",
             "ion.icon","ion.label","ion.value","bomb.icon","bomb.label",
             "bomb.value","shield_charge.icon","shield_charge.label",
             "shield_charge.value","boost.icon","boost.label","boost.value",
             "mission.notice","mission.clear_title","mission.clear_body",
             "mission.next","objective.title","objective.info","flame.title",
             "flame.bar","coop.status","boss.panel","boss.title",
             "boss.health_text","boss.health_bar","boss.modules",
             "boss.warning","boss.warning_bar","hud.planetarium"])
    }
    static func load()->HudLayout600 {
        guard let saved=UserDefaults.standard.data(forKey:key),
              let value=try? JSONDecoder().decode(HudLayout600.self,from:saved),
              value.isValid else{return defaults()}
        return value
    }
    @discardableResult func save()->Bool {
        guard let data=try? encodeJSON() else{return false}
        UserDefaults.standard.set(data,forKey:Self.key)
        return true
    }
    static func restoreDefaults()->HudLayout600 {
        UserDefaults.standard.removeObject(forKey:key)
        return defaults()
    }
    func widget(_ id:String)->Widget? {widgets.first{$0.id==id}}
    mutating func change(_ id:String,_ edit:(inout Widget)->Void) {
        guard let index=widgets.firstIndex(where:{$0.id==id}) else{return}
        let backup=widgets[index]
        edit(&widgets[index])
        if !isValid {widgets[index]=backup}
    }
}
