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
        print("PASS original v568 W3 16:9 and iPad 4:3 full-screen header/footer without letterboxing")
    }
}
