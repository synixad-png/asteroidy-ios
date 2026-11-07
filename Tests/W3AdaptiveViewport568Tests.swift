import Foundation

@main struct W3AdaptiveViewport568Tests {
    static func main() {
        func eq(_ a:Double,_ b:Double,_ name:String) {
            precondition(abs(a-b)<1e-8,name)
        }
        for (w,h) in [(1280.0,720.0),(1024.0,768.0),
                      (1194.0,834.0),(844.0,390.0),(932.0,430.0)] {
            let v=W3AdaptiveViewport568(width:w,height:h)
            eq(v.contentTop, v.headerHeight,"header not top")
            eq(v.footerTop+v.footerHeight, h,"footer not bottom")
            eq(v.headerHeight+v.contentHeight+v.footerHeight,h,
               "no internal bars allowed on full viewport")
            precondition(v.centerLogoWidth <= min(350,w))
            precondition(v.sourceScale>0 && v.sourceScale<=1)
        }
        let win=W3AdaptiveViewport568(width:1280,height:720)
        eq(win.headerHeight,74,"original W3 header")
        eq(win.footerHeight,68,"original W3 footer")
        eq(win.footerTop,652,"original W3 footer y")
        let ipad=W3AdaptiveViewport568(width:1024,height:768)
        eq(ipad.contentTop,74,"iPad top header pinned to y0")
        eq(ipad.footerTop,700,"iPad footer at bottom; no 16:9 letterbox")
        precondition(!ipad.compact)
        let phone=W3AdaptiveViewport568(width:844,height:390)
        eq(phone.headerHeight,52,"landscape phone header")
        eq(phone.footerHeight,37,"landscape phone footer")
        precondition(phone.compact && phone.centerLogoWidth>0)

        // iPhone 15 Pro Max landscape is 932 x 430pt. The test injects
        // representative CURRENT window insets; production obtains
        // actual left/right/bottom dynamically from UIWindow, never
        // model-detects or hardcodes these representative values.
        let iphone15=W3AdaptiveViewport568(
            width:932,height:430,
            insets:W3ScreenInsets568(top:0,left:59,bottom:21,right:59))
        precondition(iphone15.compact)
        eq(iphone15.usableWidth,814,
           "iPhone Dynamic Island margins leave actual content width")
        eq(iphone15.leadingPadding,71,
           "iPhone buttons clear the camera cutout on left")
        eq(iphone15.trailingPadding,71,
           "iPhone buttons clear rounded right edge")
        eq(iphone15.headerHeight,52,
           "19.5:9 original W3 bar anchored at physical y=0")
        eq(iphone15.footerHeight,48,
           "19.5:9 W3 footer contains the home-indicator inset")
        eq(iphone15.footerTop,382,
           "iPhone footer aligned to actual bottom")
        eq(iphone15.contentHeight,330,
           "iPhone content has no 16:9 letterbox")
        precondition(iphone15.centerLogoWidth<win.centerLogoWidth,
                     "wide iPhone text/logo must fit safe content width")

        // Rotating the handset changes the exposed left/right insets.
        // This MUST be decided by actual window geometry, not .phone.
        let leftCutout=W3AdaptiveViewport568(width:932,height:430,
            insets:W3ScreenInsets568(left:59,bottom:21,right:0))
        let rightCutout=W3AdaptiveViewport568(width:932,height:430,
            insets:W3ScreenInsets568(left:0,bottom:21,right:59))
        eq(leftCutout.leadingPadding,71,"camera on left orientation")
        eq(rightCutout.trailingPadding,71,"camera on right orientation")
        eq(leftCutout.usableWidth,rightCutout.usableWidth,
           "rotation symmetry without double-cropping")

        // Previous iPad 4:3 MUST retain 74/68 source bars even if the
        // system reports status/home safe-area insets.
        let ipadWithInsets=W3AdaptiveViewport568(width:1024,height:768,
            insets:W3ScreenInsets568(top:24,bottom:20))
        eq(ipadWithInsets.headerHeight,74,
           "iPad W3 original header may not be lowered")
        eq(ipadWithInsets.footerHeight,68,
           "iPad W3 original footer may not be raised")
        eq(ipadWithInsets.footerTop,700,
           "iPad full-bleed chrome remains original")
        eq(ipadWithInsets.usableWidth,1024,"iPad keeps full width")

        let badInsets=W3ScreenInsets568(top:.nan,left:-59,
            bottom:.infinity,right:-4)
        eq(badInsets.top,0,"reject NaN insets")
        eq(badInsets.left,0,"reject negative insets")
        eq(badInsets.bottom,0,"reject infinite insets")
        eq(badInsets.right,0,"reject negative right inset")
        print("PASS native v568 16:9, iPad 4:3 and iPhone 15 Pro Max 19.5:9")
        print("PASS anchored W3 chrome, screen-safe navigation and rotated Dynamic Island")
    }
}
