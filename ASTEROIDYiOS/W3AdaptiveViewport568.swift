import Foundation

/// Adaptive implementation of the genuine Windows v568 W3 header (74),
/// footer (68), and movable central content. The original 1280x720 text
/// dimensions remain reference values, not a centered 16:9 letterbox.
/// On 4:3 iPad the header must start at pixel zero and footer at the
/// actual bottom edge, without stretching logos, text or the planet.
struct W3AdaptiveViewport568 {
    let width:Double
    let height:Double
    init(width:Double,height:Double) {
        self.width=max(1,width.isFinite ? width : 1)
        self.height=max(1,height.isFinite ? height : 1)
    }
    var compact:Bool {height<540}
    var headerHeight:Double {compact ? 52 : 74}
    var footerHeight:Double {compact ? 37 : 68}
    var contentHeight:Double {max(1,height-headerHeight-footerHeight)}
    var contentTop:Double {headerHeight}
    var footerTop:Double {height-footerHeight}
    var sourceScale:Double {
        compact ? max(0.64,min(0.94,min(width/1024,height/600))) : 1
    }
    var centerLogoWidth:Double {min(350,width*(compact ? 0.37 : 0.42))}
    var headerLogoWidth:Double {min(186,width*(compact ? 0.15 : 0.16))}
}
