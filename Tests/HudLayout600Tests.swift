import Foundation

@main enum HudLayout600Tests {
    static func check(_ condition:@autoclosure ()->Bool,_ description:String) {
        precondition(condition(),description)
    }
    static func main() {
        let baseline=HudLayout600.defaults()
        check(baseline.schema==1 && baseline.widgets.count==46,
              "all approved PC v600 widgets available")
        check(Set(baseline.widgets.map(\.id)).count==46,
              "stable unique widget identities")
        for widget in baseline.widgets {
            guard let dims=HudWidgetGeometry600.size(widget.id),
                  let xRange=HudWidgetGeometry600.xRange(for:widget),
                  let yRange=HudWidgetGeometry600.yRange(for:widget) else {
                preconditionFailure("missing original PC widget geometry: "+widget.id)
            }
            check(dims.width>0 && dims.height>0,
                  "source widget hitboxes must be positive")
            check(xRange.contains(widget.x) && yRange.contains(widget.y),
                  "approved PC position must obey original F6 drag bounds")
        }
        check(HudWidgetGeometry600.size("radar")==HudWidgetGeometry600.Size(width:178,height:192),
              "original radar geometry")
        check(HudWidgetGeometry600.size("boss.health_bar")==HudWidgetGeometry600.Size(width:515,height:5),
              "original boss HUD geometry")
        check(HudWidgetGeometry600.size("unknown.widget")==nil,
              "no guessed geometry for unknown widget")
        let exported=try! baseline.encodeJSON()
        check((try? HudLayout600.decodeJSON(exported))==baseline,
              "PC v600 full 46-widget JSON exchange is lossless")
        check((try? HudLayout600.decodeJSON(Data(repeating:65,count:65_537)))==nil,
              "oversized Files JSON is rejected before decoding")
        var wrongModel=baseline
        let iconIndex=wrongModel.widgets.firstIndex(where:{$0.id=="ion.icon"})!
        wrongModel.widgets[iconIndex].glb="unknown"
        check(!wrongModel.isValid,
              "foreign GLB identity cannot enter validated native HUD")
        check((try? wrongModel.encodeJSON())==nil,
              "invalid GLB mappings cannot be exported")
        let badModelBytes=try! JSONEncoder().encode(wrongModel)
        check((try? HudLayout600.decodeJSON(badModelBytes))==nil,
              "foreign GLB mappings cannot be imported")
        var wrongID=baseline
        wrongID.widgets[0].id="status.invented"
        let badIDBytes=try! JSONEncoder().encode(wrongID)
        check((try? HudLayout600.decodeJSON(badIDBytes))==nil,
              "unknown 47th/renamed widget IDs are rejected")
        let planet=baseline.widget("hud.planetarium")!
        check(planet.x==64.7882 && planet.y==553.0863 &&
              planet.scale==1.4702 && planet.pitch == -20,
              "exact approved original planetarium pose")
        check(baseline.widget("hull.bar")?.x==201.7023,
              "approved plasma status bar coordinate")
        check(baseline.widget("shield.bar")?.y==577.9584,
              "approved shield plasma coordinate")
        var updated=baseline
        updated.change("hud.planetarium") {
            $0.x=90
            $0.pitch = -12
            $0.scale=1.70
            $0.visible=false
        }
        updated.change("ion.icon") { $0.yaw=17;$0.roll = -5 }
        check(updated.isValid,"user edits remain valid")
        check(updated.widget("hud.planetarium")?.visible==false,
              "3D visibility persisted in document")
        updated.change("hud.planetarium") { $0.scale = 55 }
        check(updated.widget("hud.planetarium")?.scale==1.70,
              "out of range updates revert atomically")
        updated.change("fake.widget") { $0.visible=false }
        check(updated.widgets.count==46,"no invented widget")
        let key="asteroidy.ios.hud.v600.layout"
        let original=UserDefaults.standard.data(forKey:key)
        defer {
            if let original {UserDefaults.standard.set(original,forKey:key)}
            else{UserDefaults.standard.removeObject(forKey:key)}
        }
        check(updated.save(),"save valid layout")
        let loaded=HudLayout600.load()
        check(loaded==updated,"save/load preserves all widgets")
        check(HudLayout600.restoreDefaults()==baseline,
              "restore defaults always restores PC v600, not v568")
        print("PASS HUD v600 native layout: 46 approved values, constrained edits, save, restore")
    }
}
