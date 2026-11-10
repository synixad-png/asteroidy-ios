import Foundation

/// One stateful input edge router shared by hardware keyboard, gamepad,
/// and existing touch semantics. Action IDs are exactly PC Controls.cs.
/// No gameplay actions for unported PC contexts/co-op. 120Hz-safe:
/// no file IO, parsing, allocations proportional to actions, or timers.
struct SourceControlRouter586 {
    struct Frame {
        let continuous:SourceControls586.Combat
        let bombPressed:Bool
        let boostPressed:Bool
        let pausePressed:Bool
    }
    private var previousBomb=false
    private var previousBoost=false
    private var previousPause=false

    mutating func read(_ input:SourceControls586.Snapshot,
                       profile:SourceControls586.Profile)->Frame {
        let c=input.combat(profile:profile)
        let next=Frame(
            continuous:c,
            bombPressed:c.bomb && !previousBomb,
            boostPressed:c.boost && !previousBoost,
            pausePressed:c.pause && !previousPause)
        previousBomb=c.bomb
        previousBoost=c.boost
        previousPause=c.pause
        return next
    }

    /// Clear stale buttons after an actual disconnected input device or
    /// scene teardown, never on each pause (a held P must not unpause).
    mutating func reset() {
        previousBomb=false
        previousBoost=false
        previousPause=false
    }

    struct Hangar {
        let moveForward:Float
        let moveRight:Float
        let jumpPressed:Bool
        let interactPressed:Bool
    }
    private var previousJump=false
    private var previousInteract=false

    mutating func readHangar(
        _ input:SourceControls586.Snapshot,
        profile:SourceControls586.Profile)->Hangar {
        let a:(Int)->Bool={input.held($0,profile:profile)}
        let forward:Float=(a(2) ? 1 : 0) - (a(3) ? 1 : 0)
        let right:Float=(a(1) ? 1 : 0) + (a(5) ? 1 : 0)
            - (a(0) ? 1 : 0) - (a(4) ? 1 : 0)
        let jump=a(11)
        let interact=a(12)
        defer {previousJump=jump;previousInteract=interact}
        return Hangar(
            moveForward:max(-1,min(1,forward)),
            moveRight:max(-1,min(1,right)),
            jumpPressed:jump && !previousJump,
            interactPressed:interact && !previousInteract)
    }
}
