import Foundation

/// Screen-space placement of the original v568 RendererW3Combat331 HUD.
/// Original x/y coordinates and art sizes remain unchanged (1280x720).
/// Crucially the four groups have FOUR separate physical-screen anchors:
/// upper-left, upper-right, lower-left, lower-right. No centered 16:9 box.
/// Safe insets come from the actual UIWindow, never device-name heuristics.
struct CombatHUDViewport568 {
    enum Anchor {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    static let sourceWidth:Double=1280
    static let sourceHeight:Double=720

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

    // Preserve the PC's original HUD aspect ratio, but NOT the old
    // centered source viewport. Its physical anchor is set per group.
    var scale:Double {
        max(0.001,min(usableWidth/Self.sourceWidth,
                      usableHeight/Self.sourceHeight))
    }

    // Small optical padding from the safe SCREEN edges, not from the
    // letterboxed 16:9 gaming area. Scales on phone without device guesses.
    var horizontalMargin:Double {min(10,max(3,scale*10))}
    var verticalMargin:Double {min(8,max(3,scale*9))}

    // The full-bleed 19.5:9 iPhone has wide horizontal safe insets.
    // They are appropriate for touch targets, but made the read-only HUD
    // float too far toward the middle. Keep the original safe-area scale
    // and use less horizontal inset ONLY for this long, short viewport.
    // 4:3 iPad and conventional 16:9 geometry remain byte-for-byte in
    // effect identical to the previously approved four-corner HUD.
    var widePhoneHUD:Bool {width/height >= 2.0 && height <= 500}

    // Move the left group toward (not fully behind) Dynamic Island.
    // Reduce ~59pt safe inset to ~29.5pt on a 15 Pro Max.
    var leftHUDInset:Double {widePhoneHUD ? left*0.5 : left}

    // On a long iPhone the passive right HUD reaches the physical right
    // edge (only the original scaled source optical margin remains).
    var rightHUDInset:Double {widePhoneHUD ? 0 : right}

    func originX(for anchor:Anchor)->Double {
        switch anchor {
        case .topLeft,.bottomLeft:
            return leftHUDInset+horizontalMargin
        case .topRight,.bottomRight:
            return width-rightHUDInset-horizontalMargin-Self.sourceWidth*scale
        }
    }

    func originY(for anchor:Anchor)->Double {
        switch anchor {
        case .topLeft,.topRight:
            return top+verticalMargin
        case .bottomLeft,.bottomRight:
            return height-bottom-verticalMargin-Self.sourceHeight*scale
        }
    }

    func x(_ sourceX:Double,at anchor:Anchor)->Double {
        originX(for:anchor)+sourceX*scale
    }
    func y(_ sourceY:Double,at anchor:Anchor)->Double {
        originY(for:anchor)+sourceY*scale
    }

    // Pause is a touch-only iOS control, horizontally centered in the
    // real safe screen (independent of the PC HUD's individual groups).
    var pauseCenterX:Double {left+usableWidth/2}
    var pauseCenterY:Double {y(33,at:.topLeft)}
}
