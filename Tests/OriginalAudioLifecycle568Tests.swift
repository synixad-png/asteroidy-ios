import Foundation

/// Test-only silent frames; these test cache/order, not the game music.
final class Audio568Fixture:OriginalAudioGenerator568 {
    var menuCalls=0
    var missionCalls:[Int:Int]=[:]
    func generateOriginalMenuMusic() throws -> OriginalPCM568 {
        menuCalls+=1
        return OriginalPCM568(sourceId:"fixture-only",sampleRate:22050,
                              channels:1,interleavedFloat32:[0,0],loops:true)
    }
    func generateOriginalMissionAudio(sector:Int) throws -> OriginalMissionAudio568 {
        missionCalls[sector,default:0]+=1
        return OriginalMissionAudio568(music:nil,effectsBySourceId:[:])
    }
}
@main struct OriginalAudioLifecycle568Tests {
    static func main() {
        let fixture=Audio568Fixture()
        let life=OriginalAudioLifecycle568(generator:fixture)
        var menuEvents=0
        var missionEvents=0
        life.onEvent={ event in
            switch event {
            case .menuReady:menuEvents+=1
            case .missionReady:missionEvents+=1
            case .unavailable:preconditionFailure("unexpected missing fixture")
            }
        }
        life.prepareAtStartup()
        life.openMission(sector:1)
        life.openMenu()
        life.openMission(sector:1)
        life.openMission(sector:2)
        life.openMenu()
        let finished=Date().addingTimeInterval(5)
        while menuEvents<1 && Date()<finished {
            RunLoop.main.run(until:Date().addingTimeInterval(0.01))
        }
        precondition(menuEvents==1,"latest menu event must be delivered")
        precondition(fixture.menuCalls==1)
        precondition(fixture.missionCalls[1]==1 && fixture.missionCalls[2]==1)
        precondition(menuEvents==1 && missionEvents==0)
        let missing=OriginalAudioLifecycle568()
        var refused=false
        missing.onEvent={event in if case .unavailable=event {refused=true}}
        missing.openMenu()
        let stop=Date().addingTimeInterval(2)
        while !refused && Date()<stop {
            RunLoop.main.run(until:Date().addingTimeInterval(0.01))
        }
        precondition(refused,"missing real source must not synthesize replacement sound")
        let invalid=OriginalPCM568(sourceId:"bad",sampleRate:0,channels:1,
                                   interleavedFloat32:[.nan],loops:false)
        precondition(!invalid.isValid)
        print("PASS v568 two-stage menu->mission, cache, latest scene, no fabricated audio")
    }
}
