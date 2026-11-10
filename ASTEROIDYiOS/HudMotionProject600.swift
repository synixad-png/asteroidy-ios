import Foundation

/// Pixel-perfect port of Windows HudMotion.cs:
/// HudMotionPose.Project(x,y,widgetId,out px,out py).
/// All user-edited F6 coordinates stay untouched. Per-widget visual rotation
/// happens around 1280x720 screen center BEFORE the safe-area anchor maps
/// the result to iPhone/iPad screen points.
enum HudMotionProject600 {
    struct Point:Equatable {let x:Double,y:Double}
    static func project(x:Double,y:Double,
                        pose:HudMotion600.Pose,widget:String)->Point {
        let weight=Double(pose.weight(widget))
        let radians=Double(pose.roll)*weight*Double.pi/180
        let cs=cos(radians),sn=sin(radians)
        let dx=x-640,dy=y-360
        return Point(
            x:640+dx*cs-dy*sn+Double(pose.x)*weight,
            y:360+dx*sn+dy*cs+Double(pose.y)*weight)
    }
}
