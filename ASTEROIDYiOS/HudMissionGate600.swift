import Foundation

/// Original Windows RendererW3Combat331 mission.next gate for the
/// only currently playable native iOS objective: clear all live actors.
/// Does not synthesize unavailable boss/escort/defend campaign telemetry.
enum HudMissionGate600 {
    static func nextMessage(playing:Bool,
                            remainingRocks:Int,
                            remainingFighters:Int)->String? {
        guard playing,remainingRocks==0,remainingFighters==0 else{return nil}
        return "OCZYSZCZONA ORBITA"
    }
}
