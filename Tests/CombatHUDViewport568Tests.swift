import Foundation

/// Four-corner geometry regression. Validate physical viewport positions,
/// not just a 1280x720 aspect-fit factor (the old iPad bug).
@main struct CombatHUDViewport568Tests {
    static func check(_ ok:Bool,_ reason:String) {
        precondition(ok,reason)
    }
    static func near(_ a:Double,_ b:Double,_ tolerance:Double=0.0001)->Bool {
        abs(a-b) < tolerance
    }
    static func main() {
        typealias A=CombatHUDViewport568.Anchor

        // Fullscreen iPad 4:3 with a status bar and home indicator.
        // The source radar is at (91,612), gauges y=565/613/661,
        // bottom ability counts y=680; all must hug the REAL bottom.
        let ipad=CombatHUDViewport568(width:1024,height:768,
            safeTop:24,safeBottom:20)
        check(near(ipad.scale,0.8),"4:3 iPad retains source HUD geometry")
        check(!ipad.widePhoneHUD,"4:3 iPad must not use iPhone extension")
        check(near(ipad.leftHUDInset,ipad.left) &&
              near(ipad.rightHUDInset,ipad.right),
              "approved iPad left and right anchors stay unchanged")
        check(ipad.y(17,at:.topLeft) < 52,
              "4:3 header must start just under status bar")
        check(ipad.y(17,at:.topRight) < 52,
              "4:3 right header must also reach the top")
        check(ipad.y(612,at:.bottomLeft) > 640,
              "4:3 radar must be near bottom, not screen middle")
        check(ipad.y(661,at:.bottomLeft) > 685,
              "4:3 armor and shield group must be low")
        check(ipad.y(680,at:.bottomRight) > 700,
              "4:3 equipment must be near bottom")
        check(ipad.y(680,at:.bottomRight) < 768-ipad.bottom,
              "4:3 bottom text must not cross safe edge")
        check(near(ipad.originY(for:.topLeft),
                   ipad.originY(for:.topRight)),
              "upper corners have same top baseline")
        check(near(ipad.originY(for:.bottomLeft),
                   ipad.originY(for:.bottomRight)),
              "lower corners have same bottom baseline")
        check(ipad.originY(for:.bottomLeft) - ipad.originY(for:.topLeft) > 120,
              "top and bottom MUST NOT share one origin")
        check(ipad.x(91,at:.bottomLeft) > 0 &&
              ipad.x(1220,at:.bottomRight) < 1024,
              "iPad left radar and right icon both visible")

        // User's iPad screenshot is 1408x1056 pixels; the same 4:3 policy
        // must remain correct without checking hardware model names.
        let screenshot=CombatHUDViewport568(width:1408,height:1056,
            safeTop:30,safeBottom:24)
        check(screenshot.y(612,at:.bottomLeft) > screenshot.height*0.82,"screenshot radar lower than before")
        check(screenshot.y(17,at:.topLeft) < screenshot.height*0.07,"screenshot top HUD near top")

        // iPhone 15 Pro Max landscape 932x430pt (19.5:9),
        // safe-area cutouts on BOTH sides; no invisible 16:9 side bands.
        let phone=CombatHUDViewport568(width:932,height:430,
            safeLeft:59,safeRight:59)
        check(near(phone.scale,430.0/720),
              "iPhone retains source aspect and readable height")
        check(phone.widePhoneHUD,"long iPhone landscape must enable wide HUD")
        check(near(phone.leftHUDInset,29.5),
              "long iPhone reduces left HUD inset by half")
        check(near(phone.rightHUDInset,0),
              "long iPhone reaches physical right edge")
        check(phone.x(34,at:.topLeft) > 50 &&
              phone.x(34,at:.topLeft) < 64,
              "left title moves about 30pt closer to Dynamic Island")
        check(phone.x(91,at:.bottomLeft) > 80 &&
              phone.x(91,at:.bottomLeft) < 100,
              "radar also moves outward on long iPhone")
        check(phone.x(1262,at:.topRight) > 910 &&
              phone.x(1262,at:.topRight) < 932,
              "right header fills outer 22pt of physical iPhone screen")
        check(phone.x(1220,at:.bottomRight) > 885,
              "rightmost ability moves to outer edge")
        check(phone.x(1220,at:.bottomRight) > phone.x(1220,at:.bottomLeft) + 90,
              "right equipment independently anchored")
        check(phone.y(17,at:.topRight) < 25,
              "wide iPhone top bar genuinely at top")
        check(phone.y(680,at:.bottomRight) > 395,
              "wide iPhone equipment genuinely at bottom")
        check(phone.y(680,at:.bottomRight) < 430,
              "wide iPhone equipment not cut off")
        check(near(phone.pauseCenterX,466),
              "pause centered in the actual safe viewport")
        check(phone.pauseCenterY<33,
              "pause button near screen top")

        // Unchanged PC reference geometry: components still have the same
        // x,y, shape, sizes and relative distances, only anchors change.
        let source=CombatHUDViewport568(width:1280,height:720)
        check(near(source.scale,1),"original PC source scale")
        check(!source.widePhoneHUD,"16:9 must not use long-iPhone extension")
        check(near(source.originX(for:.topLeft),source.left+source.horizontalMargin),
              "16:9 left anchor unchanged")
        check(near(source.originX(for:.topRight),
                   source.width-source.right-source.horizontalMargin-1280*source.scale),
              "16:9 right anchor unchanged")
        check(near(source.y(661,at:.bottomLeft) - source.y(565,at:.bottomLeft),96),
              "original 3 gauge vertical spacing stays exact")
        check(near(source.x(1220,at:.bottomRight) - source.x(920,at:.bottomRight),300),
              "original 4 equipment horizontal spacing stays exact")

        let safe=CombatHUDViewport568(width:932,height:430,
            safeLeft:40,safeRight:35,safeTop:8,safeBottom:12)
        check(safe.leftHUDInset == 20 && safe.rightHUDInset == 0,
              "long iPhone adjusts only passive HUD side insets")
        check(safe.x(20,at:.topLeft) < 40 && safe.x(20,at:.topLeft) > 0,
              "left HUD uses more of the physical screen")
        check(safe.x(1262,at:.topRight) > 932-35 &&
              safe.x(1262,at:.topRight) < 932,
              "right HUD uses physical trailing edge")
        check(safe.y(17,at:.topLeft) > 8,"independent top safe area")
        check(safe.y(680,at:.bottomRight) < 430-12,
              "independent bottom safe area")

        print("PASS wider iPhone HUD: left toward Dynamic Island, right to physical edge, iPad 4:3 and 16:9 unchanged, pause")
    }
}
