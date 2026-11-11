import Foundation

/// The ONLY native control-profile adapter for the PC602 orbital flight.
/// Uses existing PC586 60-action key/pad remapping instead of inventing a
/// second hardcoded input system. This is a read-only mapping: no campaign
/// mutation and no changes to working CARBONIS or H55 controls.
enum PC602HomeFlightInput291 {
    /// Physical hardware is already translated to SourceControls586.Snapshot
    /// by the existing SourceHardwareInput586 shared input bridge. It handles
    /// HID keyboard events, gamepad axes, reassigned buttons and deadzone.
    static func read(snapshot:SourceControls586.Snapshot,
                     profile:SourceControls586.Profile,
                     touchMove:Vec2=Vec2(x:0,y:0),
                     touchAim:Vec2=Vec2(x:0,y:0)) -> PC602HomeFlight291.Input {
        let mapped=snapshot.combat(profile:profile)
        let touchMotion=touchMove.lengthSquared>0.0001
        let touchTarget=touchAim.lengthSquared>0.0001
        let move=touchMotion
            ? touchMove
            : Vec2(x:mapped.move.x,y:mapped.move.y)
        let aim=touchTarget
            ? touchAim
            : Vec2(x:mapped.aim.x,y:mapped.aim.y)

        // Source 33/34: ONE persisted remapping owns the right stick. Do
        // not inspect hardcoded axes[2]/[3] if the user rebound them.
        let ax=snapshot.boundAnalog(33,profile:profile)
        let ay=snapshot.boundAnalog(34,profile:profile)
        let padActive=sqrt(ax*ax+ay*ay)>Float(profile.deadZone)/100

        // Distinguish hardware keyboard from physical pad so the original
        // HomeFlight291 right-stick heading latch is released ONLY on
        // actual keyboard control (or an explicitly provided touch aim).
        let keyboardMotion=(0...5).contains { index in
            let key=profile.keys[index]
            return key>0 && snapshot.keys.contains(key)
        } || (
            snapshot.keys.contains(37) ||
            snapshot.keys.contains(38) ||
            snapshot.keys.contains(39) ||
            snapshot.keys.contains(40)
        )
        let keyboardAim=(44...47).contains { index in
            let key=profile.keys[index]
            return key>0 && snapshot.keys.contains(key)
        }
        return PC602HomeFlight291.Input(
            move:move,aim:aim,
            padAimActive:padActive && !keyboardAim && !touchTarget,
            keyboardMovement:keyboardMotion)
    }
}
