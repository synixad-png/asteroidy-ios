import Foundation

/// iOS rendering policy only, for the native *iPhone* CARBONIS gameplay
/// MTKView. It never changes Game.Step, weapon fire cadence, mission projection,
/// shader quality controls, sample counts or source explosion/shot geometry.
/// The iPad path never constructs or calls this policy.
struct PhoneCombatResolution568 {
    enum Tier:Int,Equatable {
        case native=0,balanced=1,performance=2
    }
    private(set) var tier:Tier = .native
    private var previousFrame:TimeInterval?
    private var slowSeconds:Double=0
    private var recoveredSeconds:Double=0

    /// Reduce framebuffer pixels only if iPhone actually misses multiple
    /// vsyncs while bullets are active. Keep original 100% otherwise.
    var drawableScale:Double {
        switch tier {
        case .native:return 1.0
        case .balanced:return 0.84
        case .performance:return 0.74
        }
    }

    /// An observed callback cadence is not a claim about GPU timings.
    /// Misses must persist for >0.65 seconds while shots are present;
    /// once restored, do not oscillate back to full resolution mid-volley.
    /// Revert one tier after >4 seconds of stable 60 Hz without projectiles.
    @discardableResult
    mutating func observe(at now:TimeInterval,
                          projectilesActive:Bool)->Bool {
        guard now.isFinite,now>=0 else {return false}
        defer {previousFrame=now}
        guard let previousFrame else{return false}
        let dt=now-previousFrame
        guard dt>0 && dt<0.20 else {
            slowSeconds=0
            recoveredSeconds=0
            return false
        }
        if projectilesActive && dt>=0.025 {
            slowSeconds+=dt
            recoveredSeconds=0
            if slowSeconds>=0.65,tier != .performance,
               let next=Tier(rawValue:tier.rawValue+1) {
                tier=next
                slowSeconds=0
                return true
            }
        } else if !projectilesActive && dt<=0.019 {
            recoveredSeconds+=dt
            slowSeconds=0
            if recoveredSeconds>=4.0,tier != .native,
               let next=Tier(rawValue:tier.rawValue-1) {
                tier=next
                recoveredSeconds=0
                return true
            }
        } else {
            slowSeconds=max(0,slowSeconds-dt)
            recoveredSeconds=0
        }
        return false
    }

    /// UIKit provides bounds in points and its own contentScaleFactor.
    /// These two values preserve the exact layout aspect on both 19.5:9
    /// iPhone screens and orientation changes. SwiftUI/HUD is never scaled.
    func drawablePixels(widthPoints:Double,heightPoints:Double,
                        contentScale:Double)->(width:Int,height:Int) {
        guard widthPoints.isFinite,heightPoints.isFinite,
              contentScale.isFinite,widthPoints>0,heightPoints>0,
              contentScale>0 else {return (0,0)}
        return (
            max(1,Int((widthPoints*contentScale*drawableScale).rounded())),
            max(1,Int((heightPoints*contentScale*drawableScale).rounded()))
        )
    }
}
