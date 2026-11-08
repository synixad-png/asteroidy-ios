import Foundation

@main struct CombatHUDViewport568Tests {
    static func check(_ condition:Bool,_ message:String) {
        precondition(condition,message)
    }
    static func main() {
        // 4:3 iPad landscape: old 16:9 HUD centering left 96pt top gutter.
        // Lift the entire HUD by 48pt without moving individual ornaments.
        let ipad=CombatHUDViewport568(width:1024,height:768)
        check(abs(ipad.scale-0.8)<0.00001,"iPad proportional HUD")
        check(abs(ipad.originY-48)<0.00001,"iPad HUD higher than centered")
        check(ipad.hudY(612)<96+612*0.8,"iPad radar lifted")
        check(ipad.leftX(91)>0,"iPad radar visible")
        check(ipad.topRightX(1220)<1024,"iPad last ability visible")

        // 15 Pro Max landscape, logical points; safe-area insets supplied
        // by UIWindow, never hard-coded in rendering code.
        let phone=CombatHUDViewport568(width:932,height:430,
            safeLeft:59,safeRight:59,safeTop:0,safeBottom:0)
        check(abs(phone.scale-430.0/720)<0.00001,"iPhone height fit")
        check(phone.spareWidth>0,"wide phone spare width")
        check(phone.leftX(20)>=phone.left,"left HUD out of notch")
        check(phone.topRightX(1262)<=932-phone.right,"right HUD within safe area")
        check(phone.hudY(701)<=430,"lower HUD fits")
        check(phone.topRightX(1220)>phone.leftX(1220),"right group reaches wide screen")
        check(abs(phone.originY)<0.00001,"wide iPhone top anchored")

        let original=CombatHUDViewport568(width:1280,height:720)
        check(abs(original.scale-1)<0.00001,"16:9 source scale")
        check(abs(original.originY)<0.00001,"16:9 source vertical positions")
        check(abs(original.spareWidth)<0.00001,"16:9 source horizontal positions")

        let safe=CombatHUDViewport568(width:932,height:430,
            safeLeft:40,safeRight:35,safeTop:8,safeBottom:12)
        check(safe.leftX(20)>40,"notch safe area")
        check(safe.topRightX(1262)<932-35,"trailing corner safe area")
        check(safe.hudY(701)<430-12,"bottom inset")
        print("PASS HUD viewport: iPad 4:3 raised, 15 Pro Max wide, 16:9 unchanged, safe areas")
    }
}
