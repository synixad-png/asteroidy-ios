import Foundation

@main enum HudMissionGate600Tests {
    static func require(_ condition:Bool,_ explanation:String) {
        precondition(condition,explanation)
    }
    static func main() {
        require(HudMissionGate600.nextMessage(
            playing:true,remainingRocks:0,remainingFighters:0) ==
            "OCZYSZCZONA ORBITA","exact original PC clear text")
        require(HudMissionGate600.nextMessage(
            playing:true,remainingRocks:1,remainingFighters:0)==nil,
            "remaining asteroid must suppress completion notice")
        require(HudMissionGate600.nextMessage(
            playing:true,remainingRocks:0,remainingFighters:1)==nil,
            "remaining enemy must suppress completion notice")
        require(HudMissionGate600.nextMessage(
            playing:false,remainingRocks:0,remainingFighters:0)==nil,
            "victory/defeat summary owns the screen; no duplicate notice")
        require(HudMissionGate600.nextMessage(
            playing:false,remainingRocks:4,remainingFighters:3)==nil,
            "inactive missions have no invented notices")
        print("PASS source PC v600 mission.next: true clear, active-only, no fake late objectives")
    }
}
