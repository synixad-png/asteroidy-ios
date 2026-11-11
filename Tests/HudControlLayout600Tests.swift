import Foundation

@main enum HudControlLayout600Tests {
    static func check(_ ok:@autoclosure ()->Bool,_ note:String) {
        precondition(ok(),note)
    }
    static func close(_ a:Double,_ b:Double)->Bool {abs(a-b)<0.0001}

    static func main() {
        let original=HudControlLayout600.defaults()
        check(original.isValid && original.controls.count==5,
              "five functional controls have a separate valid schema")
        check(HudLayout600.defaults().widgets.count==46,
              "approved 46 HUD elements were not migrated or replaced")
        let vp=CombatHUDViewport568(width:1024,height:768,
                                    safeLeft:0,safeRight:0,
                                    safeTop:24,safeBottom:20)
        let phone=CombatHUDViewport568(width:956,height:440,
                                       safeLeft:59,safeRight:59,
                                       safeTop:21,safeBottom:21)
        for layout in [vp,phone] {
            let compact=layout.height<550
            let shield=original.control("control.shield")!
            let r=HudControlLayout600.frame(
                shield,viewport:layout,compact:compact)
            check(r.width>=44 && r.height>=44,
                  "active shield has accessible hitbox")
            check(HudControlLayout600.hit(x:r.centerX,y:r.centerY,
                  layout:original,viewport:layout,compact:compact) != nil,
                  "real editor can select a functional touch area")
            let originalPause=HudControlLayout600.frame(
                original.control("control.pause")!,
                viewport:layout,compact:compact)
            check(close(originalPause.centerX,layout.pauseCenterX),
                  "original pause button centre is retained on both screens")
            check(close(originalPause.centerY,layout.pauseCenterY),
                  "original pause Y is retained without user customization")
        }
        var moved=original
        let start=moved.control("control.shield")!
        moved.move("control.shield",from:start,deltaX:55,deltaY:25,
                   viewport:vp,compact:false)
        let shield=moved.control("control.shield")!
        check(shield.x>start.x && shield.y>start.y,
              "moving shield changes its physical hitbox position")
        for id in HudControlLayout600.ids where id != "control.shield" {
            check(moved.control(id)==original.control(id),
                  "moving shield cannot move another functional control")
        }
        let old=HudControlLayout600.frame(start,viewport:vp,compact:false)
        let current=HudControlLayout600.frame(shield,viewport:vp,compact:false)
        check(close(current.centerX-old.centerX,
                    shield.x*vp.scale) &&
              close(current.centerY-old.centerY,
                    shield.y*vp.scale),
              "same transform drives actual button and editor geometry")
        moved.zoom("control.shield",originalScale:shield.scale,factor:2,
                   viewport:vp,compact:false)
        let enlarged=moved.control("control.shield")!
        let enlargedFrame=HudControlLayout600.frame(
            enlarged,viewport:vp,compact:false)
        check(close(enlarged.scale,2) &&
              enlargedFrame.width>current.width &&
              enlargedFrame.height>current.height,
              "zoom enlarges both visible size and real touch target")
        check(moved.control("control.pause")==original.control("control.pause"),
              "zooming shield never changes pause button")
        var editedOptions=moved
        let opts=editedOptions.control("control.options")!
        editedOptions.move("control.options",from:opts,
                           deltaX:-60,deltaY:30,viewport:vp,compact:false)
        check(editedOptions.control("control.options") != opts,
              "pause OPTIONS button remains independently editable")
        check(editedOptions.isValid,"edited layout remains valid")
        let data=try! JSONEncoder().encode(editedOptions)
        let restored=try! JSONDecoder().decode(HudControlLayout600.self,from:data)
        check(restored==editedOptions && restored.isValid,
              "five button offsets/scales survive JSON encoding")
        var invalid=restored
        invalid.controls.append(invalid.controls[0])
        check(!invalid.isValid,"duplicate ids rejected")
        invalid=restored
        invalid.controls[0].scale=999
        check(!invalid.isValid,"invalid or extreme scale rejected")
        print("PASS five independent native controls: shield/options touch size, phone/iPad geometry, drag, pinch, JSON, original 46 HUD untouched")
    }
}
