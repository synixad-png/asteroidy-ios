import Foundation

/// Keep HUD graphics at the original 1280x720 proportions, but lay out
/// top/left and right HUD regions independently when aspect ratio differs.
/// No device model checks: supports both iPad 4:3 and long iPhone landscape.
struct CombatHUDViewport568 {
    let width:Double
    let height:Double
    let safeLeft:Double
    let safeRight:Double
    let safeTop:Double
    let safeBottom:Double

    init(width:Double,height:Double,safeLeft:Double=0,safeRight:Double=0,
         safeTop:Double=0,safeBottom:Double=0) {
        self.width=max(1,width.isFinite ? width : 1)
        self.height=max(1,height.isFinite ? height : 1)
        self.safeLeft=max(0,safeLeft.isFinite ? safeLeft : 0)
        self.safeRight=max(0,safeRight.isFinite ? safeRight : 0)
        self.safeTop=max(0,safeTop.isFinite ? safeTop : 0)
        self.safeBottom=max(0,safeBottom.isFinite ? safeBottom : 0)
    }

    var left:Double {min(safeLeft,width*0.35)}
    var right:Double {min(safeRight,width*0.35)}
    var top:Double {min(safeTop,height*0.25)}
    var bottom:Double {min(safeBottom,height*0.25)}
    var usableWidth:Double {max(1,width-left-right)}
    var usableHeight:Double {max(1,height-top-bottom)}
    var scale:Double {max(0.001,min(usableWidth/1280,usableHeight/720))}
    var spareWidth:Double {max(0,usableWidth-1280*scale)}
    var spareHeight:Double {max(0,usableHeight-720*scale)}

    // iPad portrait-ratio landscape leaves extra height: shift HUD upwards
    // relative to the previously centered letterbox (50% of spare height).
    // A quarter gutter preserves vertical breathing room at the top.
    var originY:Double {top+spareHeight*0.25}
    var originLeftX:Double {left}
    var originRightX:Double {left+spareWidth}

    func topRightX(_ x:Double)->Double {originRightX+x*scale}
    func leftX(_ x:Double)->Double {originLeftX+x*scale}
    func hudY(_ y:Double)->Double {originY+y*scale}

    // Independent x anchoring moves the rightmost equipment to the edge on
    // wide iPhones. The center is left free for the actual gameplay scene.
    func rightGroupOffsetInSource()->Double {spareWidth/scale}
}
