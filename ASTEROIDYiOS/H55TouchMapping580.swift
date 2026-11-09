import Foundation

/// PC HubWalk375: digital W/A/S/D movement, never a virtual thumbstick.
/// The entire left half responds at full speed after only a 3pt gesture.
/// The right half remains independently assigned to camera look.
enum H55TouchMapping580 {
    static let movementThreshold:Float=3
    static func walk(dx:Float,dy:Float)->(forward:Float,right:Float) {
        guard dx.isFinite && dy.isFinite else{return (0,0)}
        if max(abs(dx),abs(dy))<movementThreshold{return (0,0)}
        let horizontal=abs(dx)>=max(movementThreshold,abs(dy)*0.40)
        let vertical=abs(dy)>=max(movementThreshold,abs(dx)*0.40)
        let right:Float=horizontal ? (dx>0 ? 1 : -1) : 0
        let forward:Float=vertical ? (dy<0 ? 1 : -1) : 0
        let speed:Float=(right != 0 && forward != 0) ? 0.7071067811865476 : 1
        return (forward*speed,right*speed)
    }

    /// Preserve PC H06 movement signs without modifying game physics.
    static func sceneYaw(for physicsYaw:Float)->Float{-physicsYaw}
    static func scenePitch(for physicsPitch:Float)->Float{physicsPitch}
}
