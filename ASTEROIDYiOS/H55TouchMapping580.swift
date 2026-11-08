import Foundation

/// Touch-to-PC v580 H55 movement coordinates.
/// Up on the left pad = PC forward (+input F -> world -Z at yaw 0).
/// Right on the left pad = PC strafe right (+input R -> world +X).
/// For diagonal input, preserve length <= 1 to avoid sprint-by-diagonal.
enum H55TouchMapping580 {
    static let travelForFullSpeed:Float = 78
    static func walk(dx:Float,dy:Float)->(forward:Float,right:Float) {
        guard dx.isFinite && dy.isFinite else {return (0,0)}
        var right=dx/travelForFullSpeed
        var forward = -dy/travelForFullSpeed
        let length=hypot(right,forward)
        if length>1 {right/=length;forward/=length}
        return (forward,right)
    }

    /// GLB/PC physics uses yaw positive toward +X. SceneKit's camera
    /// local -Z turns toward -X at *positive* euler Y, so negate yaw.
    static func sceneYaw(for physicsYaw:Float)->Float { -physicsYaw }

    /// Source H55Walk580.pitch decreases when dragging DOWN. SCN camera
    /// positive X looks UP, so pass the source pitch through unchanged.
    static func scenePitch(for physicsPitch:Float)->Float { physicsPitch }
}
