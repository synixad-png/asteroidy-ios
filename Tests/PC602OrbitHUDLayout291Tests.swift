import Foundation

@main struct PC602OrbitHUDLayout291Tests {
    private static func check(_ condition:@autoclosure ()->Bool,_ message:String) {
        precondition(condition(),message)
    }
    static func main() {
        let original=PC602OrbitHUDLayout291.defaults()
        check(original.valid,"complete default H290 HUD")
        check(original.elements.count==PC602OrbitHUDLayout291.ids.count,
              "all source and atomic HUD entries are registered")
        check(original.elements.count>PC602OrbitHUDLayout291.legacyIDs.count,
              "atomic HUD labels must be editable individually")
        check(original.elements.allSatisfy{$0.x==0 && $0.y==0 && $0.scale==1},
              "no geometry regression in the original default H290 HUD")
        let domain="pc602-orbit-hud-test-"+UUID().uuidString
        guard let prefs=UserDefaults(suiteName:domain) else{fatalError("defaults suite")}
        defer{prefs.removePersistentDomain(forName:domain)}
        check(PC602OrbitHUDLayout291.load(defaults:prefs)==original,"default HUD")

        // Migration: REAL prior H290 JSON contained only the original 11 IDs.
        let oldRecords=PC602OrbitHUDLayout291.legacyIDs.map { id in
            "{\"id\":\"\(id)\",\"x\":0,\"y\":0,\"scale\":1}"
        }
        let oldJSON=Data(("{\"schema\":1,\"elements\":["+
                          oldRecords.joined(separator:",")+"]}").utf8)
        let migrated=try! PC602OrbitHUDLayout291.decodeJSON(oldJSON)
        check(migrated==original,"legacy 11-element JSON must expand losslessly")
        prefs.set(oldJSON,forKey:"asteroidy.ios.pc602.orbit-hud-layout291.v1")
        check(PC602OrbitHUDLayout291.load(defaults:prefs)==original,
              "old layout must also be upgraded when loaded from disk")

        var hidden=migrated
        hidden.change("hud.mission.heading"){$0.visible=false}
        check(hidden.valid && !hidden.item("hud.mission.heading").visible,
              "independent visibility for editable HUD text")
        let encoded=try! JSONEncoder().encode(hidden)
        check(try! PC602OrbitHUDLayout291.decodeJSON(encoded)==hidden,
              "atomic HUD JSON roundtrip")
        var edited=original
        edited.change("control.enter"){$0.x = -135;$0.y = 90;$0.scale = 1.65}
        edited.change("hud.telemetry.speed"){$0.x = 115;$0.y = -60;$0.scale = 0.8}
        check(edited.valid && edited.item("control.enter").scale==1.65,
              "individual button + telemetry editing")
        check(edited.save(defaults:prefs),"save")
        check(PC602OrbitHUDLayout291.load(defaults:prefs)==edited,"load")
        let before=edited
        edited.change("control.pause"){$0.scale=999}
        edited.change("control.enter"){$0.visible=false}
        edited.change("hud.mission"){$0.x = .infinity}
        edited.change("unknown"){$0.x=13}
        check(edited==before,"invalid edits cannot corrupt saved HUD")

        // Like HudEditorGeometry.hit: controls first, smallest visible
        // text rectangle first, minimum 44-pt touch region for tiny text.
        let group=CGRect(x:0,y:0,width:320,height:200)
        let heading=CGRect(x:30,y:20,width:180,height:18)
        let target=CGRect(x:30,y:110,width:145,height:18)
        let control=CGRect(x:30,y:20,width:20,height:18)
        var frames:[String:CGRect]=[
            "hud.mission":group,
            "hud.mission.heading":heading,
            "hud.mission.target":target,
            "control.atlas":control
        ]
        func hit(_ x:Double,_ y:Double,_ data:PC602OrbitHUDLayout291=original)->String? {
            PC602OrbitHUDLayout291.hit(point:CGPoint(x:x,y:y),
                                       frames:frames,layout:data)
        }
        check(hit(40,30)=="control.atlas","button wins overlap with HUD labels")
        frames.removeValue(forKey:"control.atlas")
        check(hit(40,30)=="hud.mission.heading",
              "individual text wins over the legacy enclosing group")
        check(hit(40,120)=="hud.mission.target","second atomic text selected directly")
        check(hit(270,160)=="hud.mission","empty group space still selects group")
        var hideHeading=original
        hideHeading.change("hud.mission.heading"){$0.visible=false}
        check(hit(40,30,hideHeading)=="hud.mission",
              "invisible text cannot intercept touches")
        frames["hud.mission.heading"]=CGRect(x:70,y:20,width:180,height:18)
        check(hit(40,30)=="hud.mission",
              "moving text changes physical hit location")
        check(hit(95,30)=="hud.mission.heading",
              "new physical location becomes selectable")
        frames=["hud.dock.hint":CGRect(x:100,y:100,width:8,height:8)]
        check(hit(119,119)=="hud.dock.hint","44-pt minimum touch size")
        check(hit(143,143)==nil,"don't silently treat the full viewport as HUD")
        check(PC602OrbitHUDLayout291.touchFrame(
            CGRect(x:0,y:0,width:0,height:100))==nil,"discard empty frames")
        check(PC602OrbitHUDLayout291.touchFrame(
            CGRect(x:Double.nan,y:0,width:100,height:100))==nil,
              "discard invalid source geometry")
        prefs.set(Data("corrupt json".utf8),
                  forKey:"asteroidy.ios.pc602.orbit-hud-layout291.v1")
        check(PC602OrbitHUDLayout291.load(defaults:prefs)==original,
              "corrupted document must safely fall back to approved layout")
        print("PASS PC602 orbit HUD: atomic labels, migration, 44pt hit areas, control priority, visibility, drag geometry, persistence and corruption")
    }
}