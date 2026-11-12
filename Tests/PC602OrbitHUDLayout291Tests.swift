import Foundation
@main struct PC602OrbitHUDLayout291Tests {
    static func main() {
        let original=PC602OrbitHUDLayout291.defaults()
        precondition(original.valid && original.elements.count==11)
        precondition(original.elements.allSatisfy{$0.x==0 && $0.y==0 && $0.scale==1})
        let domain="pc602-orbit-hud-test-"+UUID().uuidString
        guard let prefs=UserDefaults(suiteName:domain) else {fatalError("defaults suite")}
        defer{prefs.removePersistentDomain(forName:domain)}
        precondition(PC602OrbitHUDLayout291.load(defaults:prefs)==original)
        // Backward-compatible old JSON has no visibility key.
        let records=PC602OrbitHUDLayout291.ids.map { id in
            "{\"id\":\"\(id)\",\"x\":0,\"y\":0,\"scale\":1}"
        }
        let json="{\"schema\":1,\"elements\":[" + records.joined(separator:",") + "]}"
        let oldJSON=Data(json.utf8)
        let migrated=try! PC602OrbitHUDLayout291.decodeJSON(oldJSON)
        precondition(migrated.valid && migrated.elements.allSatisfy{$0.visible})
        var hidden=migrated
        hidden.change("hud.mission"){$0.visible=false}
        precondition(hidden.valid && !hidden.item("hud.mission").visible)
        let encoded=try! JSONEncoder().encode(hidden)
        precondition(try! PC602OrbitHUDLayout291.decodeJSON(encoded)==hidden)
        var edited=original
        edited.change("control.enter"){$0.x = -135;$0.y = 90;$0.scale = 1.65}
        edited.change("hud.atlas-grid"){$0.x = 115;$0.y = -60;$0.scale = 0.8}
        precondition(edited.valid && edited.item("control.enter").scale==1.65)
        precondition(edited.save(defaults:prefs))
        precondition(PC602OrbitHUDLayout291.load(defaults:prefs)==edited)
        let unchanged=edited
        edited.change("control.pause"){$0.scale=999}
        edited.change("hud.mission"){$0.x = .infinity}
        edited.change("invalid-element"){$0.x=13}
        precondition(edited==unchanged,"invalid edit must not corrupt layout")
        prefs.set(Data("corrupt json".utf8),forKey:"asteroidy.ios.pc602.orbit-hud-layout291.v1")
        precondition(PC602OrbitHUDLayout291.load(defaults:prefs)==original)
        print("PASS PC602 orbit HUD 11 identifiers, persistence, reset and invalid rollback")
    }
}