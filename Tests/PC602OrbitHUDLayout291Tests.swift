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
        let legacyJSON="{\"schema\":1,\"elements\":[" + oldRecords.joined(separator:",") + "]}"
        let oldJSON=Data(legacyJSON.utf8)
        let migrated=try! PC602OrbitHUDLayout291.decodeJSON(oldJSON)
        check(migrated==original,"legacy 11-element JSON must expand losslessly")
        prefs.set(oldJSON,forKey:"asteroidy.ios.pc602.orbit-hud-layout291.v1")
        check(PC602OrbitHUDLayout291.load(defaults:prefs)==original,
              "old layout must also be upgraded when loaded from disk")

        // Regression: a previously saved H290 file may include a subset of
        // newly added labels. It must not silently reset earlier WEJDŹ/PAUZA
        // coordinates when another leaf ID is introduced.
        var intermediate=original
        intermediate.change("control.enter"){$0.x = -510;$0.y = 180}
        intermediate.change("control.pause"){$0.x = 230;$0.y = -125}
        let partialIDs=Set(PC602OrbitHUDLayout291.legacyIDs+[
            "hud.mission.heading","hud.mission.distance"])
        let subset=PC602OrbitHUDLayout291(
            elements:intermediate.elements.filter{partialIDs.contains($0.id)})
        let earlierBytes=try! JSONEncoder().encode(subset)
        let migratedPartial=try! PC602OrbitHUDLayout291.decodeJSON(earlierBytes)
        check(migratedPartial.valid,"intermediate partial HUD migrates")
        check(migratedPartial.item("control.enter")==intermediate.item("control.enter"),
              "previously relocated WEJDŹ is not reset")
        check(migratedPartial.item("control.pause")==intermediate.item("control.pause"),
              "previously relocated PAUZA is not reset")
        prefs.set(earlierBytes,
                  forKey:"asteroidy.ios.pc602.orbit-hud-layout291.v1")
        check(PC602OrbitHUDLayout291.load(defaults:prefs)==migratedPartial,
              "partial saved H290 profile auto-upgrades on load")

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

        // Every real H290 touch control must remain separately selectable,
        // movable and persisted. Mission v600 editor remains untouched.
        let buttons=["control.options","control.atlas","control.next",
                     "control.pause","control.enter"]
        check(buttons.allSatisfy{PC602OrbitHUDLayout291.ids.contains($0)},
              "all five original H290 touch buttons represented")
        var allButtons=original
        for (index,id) in buttons.enumerated() {
            let signed=Double(index)*130-260
            allButtons.change(id) {element in
                element.x=signed
                element.y=Double(index)*95-190
                element.scale=1.0+Double(index)*0.1
            }
        }
        check(allButtons.valid,"all button edits must validate")
        check(allButtons.save(defaults:prefs),"persist all buttons at once")
        check(PC602OrbitHUDLayout291.load(defaults:prefs)==allButtons,
              "all five button positions must round-trip without snapping")
        for id in buttons {
            let saved=PC602OrbitHUDLayout291.load(defaults:prefs).item(id)
            check(saved==allButtons.item(id),"persisted transform: "+id)
        }
        var farMove=original
        farMove.change("control.enter"){$0.x = -1100;$0.y = -610}
        farMove.change("control.pause"){$0.x = 1050;$0.y = 510}
        check(farMove.valid,"full 1280x720 landscape movement cannot truncate")
        check(farMove.save(defaults:prefs),"save full-range moves")
        check(PC602OrbitHUDLayout291.load(defaults:prefs)==farMove,
              "far-moved WEJDŹ and PAUZA must remain where the user saved them")
        let before=edited
        edited.change("control.pause"){$0.scale=999}
        edited.change("control.enter"){$0.visible=false}
        edited.change("hud.mission"){$0.x = .infinity}
        edited.change("unknown"){$0.x=13}
        check(edited==before,"invalid edits cannot corrupt saved HUD")

        // Like HudEditorGeometry.hit: controls first, smallest visible
        // text rectangle first, minimum 44-pt touch region for tiny text.
        let group=PC602OrbitHUDLayout291.Rect(x:0,y:0,width:320,height:200)
        let heading=PC602OrbitHUDLayout291.Rect(x:30,y:20,width:180,height:18)
        let target=PC602OrbitHUDLayout291.Rect(x:30,y:110,width:145,height:18)
        let control=PC602OrbitHUDLayout291.Rect(x:30,y:20,width:20,height:18)
        var frames:[String:PC602OrbitHUDLayout291.Rect]=[
            "hud.mission":group,
            "hud.mission.heading":heading,
            "hud.mission.target":target,
            "control.atlas":control
        ]
        func hit(_ x:Double,_ y:Double,_ data:PC602OrbitHUDLayout291=original)->String? {
            PC602OrbitHUDLayout291.hit(x:x,y:y,
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
        frames["hud.mission.heading"]=PC602OrbitHUDLayout291.Rect(x:70,y:20,width:180,height:18)
        check(hit(40,30)=="hud.mission",
              "moving text changes physical hit location")
        check(hit(95,30)=="hud.mission.heading",
              "new physical location becomes selectable")
        // Each button has a real, independent hit region even when all
        // controls are visible simultaneously on an iPhone or iPad.
        frames=[:]
        for (index,id) in buttons.enumerated() {
            frames[id]=PC602OrbitHUDLayout291.Rect(
                x:Double(30+index*110),y:210,width:85,height:52)
        }
        for (index,id) in buttons.enumerated() {
            check(hit(Double(60+index*110),230)==id,
                  "touch target must select exact control: "+id)
        }
        frames["control.enter"]=PC602OrbitHUDLayout291.Rect(
            x:220,y:375,width:85,height:52)
        check(hit(250,400)=="control.enter",
              "moving WEJDŹ must change its hit rectangle")
        check(hit(500,235)==nil,
              "old WEJDŹ hit rectangle must not remain active after move")
        frames=["hud.dock.hint":PC602OrbitHUDLayout291.Rect(x:100,y:100,width:8,height:8)]
        check(hit(119,119)=="hud.dock.hint","44-pt minimum touch size")
        check(hit(143,143)==nil,"don't silently treat the full viewport as HUD")
        check(PC602OrbitHUDLayout291.touchFrame(
            PC602OrbitHUDLayout291.Rect(x:0,y:0,width:0,height:100))==nil,"discard empty frames")
        check(PC602OrbitHUDLayout291.touchFrame(
            PC602OrbitHUDLayout291.Rect(x:Double.nan,y:0,width:100,height:100))==nil,
              "discard invalid source geometry")
        // Source mission editor keeps function buttons within the real
        // viewport and leaves at least 12pt of passive HUD selectable.
        let safeControl=PC602OrbitHUDLayout291.constrainedDrag(
            "control.enter",deltaX:100,deltaY:1000,
            frame:PC602OrbitHUDLayout291.Rect(x:310,y:30,width:60,height:48),
            viewportWidth:400,viewportHeight:300,
            safeInsets:(left:20,right:20,top:20,bottom:20))
        check(safeControl.x==10 && safeControl.y==202,
              "control stays fully reachable inside the safe area")
        let passive=PC602OrbitHUDLayout291.constrainedDrag(
            "hud.mission",deltaX:-500,deltaY:-500,
            frame:PC602OrbitHUDLayout291.Rect(x:0,y:0,width:300,height:150),
            viewportWidth:400,viewportHeight:300)
        check(passive.x == -288 && passive.y == -138,
              "text preserves the source 12pt visible drag margin")
        prefs.set(Data("corrupt json".utf8),
                  forKey:"asteroidy.ios.pc602.orbit-hud-layout291.v1")
        check(PC602OrbitHUDLayout291.load(defaults:prefs)==original,
              "corrupted document must safely fall back to approved layout")
        print("PASS PC602 orbit HUD: atomic labels, migration, 44pt hit areas, control priority, visibility, drag geometry, persistence and corruption")
    }
}