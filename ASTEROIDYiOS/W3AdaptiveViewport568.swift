import Foundation

/// Actual UIWindow safe-area insets (not hard-coded per iPhone model).
/// Only the overlay UI is inset. The source W3 background, horizontal
/// chrome and Metal viewport continue to fill the entire physical screen.
struct W3ScreenInsets568:Equatable {
    let top:Double
    let left:Double
    let bottom:Double
    let right:Double

    init(top:Double=0,left:Double=0,bottom:Double=0,right:Double=0) {
        self.top=top.isFinite ? max(0,top) : 0
        self.left=left.isFinite ? max(0,left) : 0
        self.bottom=bottom.isFinite ? max(0,bottom) : 0
        self.right=right.isFinite ? max(0,right) : 0
    }
}

/// One viewport policy shared by W3 splash, HOME, submenus and Intro41.
/// Original Windows v568 chrome (74px header, 68px footer at 1280x720)
/// retains its top/bottom anchors on iPad 4:3. On an iPhone 15 Pro Max
/// landscape screen (932x430 logical points), the content moves clear
/// of the Dynamic Island, the rounded corners and the home indicator.
/// Never shrink/stretch the original planet model or change its shader.
struct W3AdaptiveViewport568 {
    let width:Double
    let height:Double
    let insets:W3ScreenInsets568

    init(width:Double,height:Double,
         insets:W3ScreenInsets568 = W3ScreenInsets568()) {
        self.width=max(1,width.isFinite ? width : 1)
        self.height=max(1,height.isFinite ? height : 1)
        self.insets=insets
    }
    var compact:Bool {height<540}
    // Keep a positive content region even for future split-screen sizes.
    var safeLeft:Double {min(insets.left,width*0.45)}
    var safeRight:Double {min(insets.right,width*0.45)}
    var safeTop:Double {min(insets.top,height*0.45)}
    var safeBottom:Double {min(insets.bottom,height*0.45)}
    var usableWidth:Double {max(1,width-safeLeft-safeRight)}
    var horizontalPadding:Double {compact ? 12 : 26}
    var leadingPadding:Double {safeLeft+horizontalPadding}
    var trailingPadding:Double {safeRight+horizontalPadding}
    // The source bars touch y=0 and the physical bottom respectively;
    // only their text moves into the unobstructed portion of each bar.
    var headerHeight:Double {
        compact ? max(52,safeTop+38) : max(74,safeTop+48)
    }
    var footerHeight:Double {
        compact ? max(37,safeBottom+27) : max(68,safeBottom+44)
    }
    var contentHeight:Double {max(1,height-headerHeight-footerHeight)}
    var contentTop:Double {headerHeight}
    var footerTop:Double {height-footerHeight}
    var sourceScale:Double {
        compact ? max(0.64,min(0.94,min(usableWidth/1024,height/600))) : 1
    }
    var centerLogoWidth:Double {
        min(350,usableWidth*(compact ? 0.37 : 0.42))
    }
    var headerLogoWidth:Double {
        min(186,usableWidth*(compact ? 0.15 : 0.16))
    }
}
