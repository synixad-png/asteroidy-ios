import Foundation
@main struct OriginalMusicSynth568Tests {
    static func main() throws {
        precondition(OriginalMusicSynth568.names.count == 15)
        precondition(OriginalMusicSynth568.bpm.count == 15)
        let dir=FileManager.default.temporaryDirectory.appendingPathComponent("Asteroidy-v568-native-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        defer {try? FileManager.default.removeItem(at:dir)}
        for track in [0,1,4,7,14] {
            let file=dir.appendingPathComponent("Music\(track).wav")
            _=try OriginalMusicSynth568.generate(track:track,destination:file,testBars:8)
            let bytes=try Data(contentsOf:file)
            precondition(bytes.count==44+OriginalMusicSynth568.frames(track,8)*4)
            precondition(bytes.prefix(4)==Data("RIFF".utf8))
            precondition(bytes[8..<16]==Data("WAVEfmt ".utf8))
            precondition(bytes[36..<40]==Data("data".utf8))
            precondition(bytes.dropFirst(44).contains(where:{$0 != 0}))
            precondition(bytes[44..<48]==Data([0,0,0,0]))
            precondition(bytes.suffix(4)==Data([0,0,0,0]))
            print("PASS source music track \(track), 44.1kHz original stereo WAV")
        }
        let a=dir.appendingPathComponent("repeatA.wav")
        let b=dir.appendingPathComponent("repeatB.wav")
        _=try OriginalMusicSynth568.generate(track:0,destination:a,testBars:1)
        _=try OriginalMusicSynth568.generate(track:0,destination:b,testBars:1)
        let ba=try Data(contentsOf:a),bb=try Data(contentsOf:b)
        precondition(ba==bb,"Source synth must be deterministic")
        // Future mission tracks must be pausable while combat runs.
        // Pause checkpoints may NEVER change source PCM even by 1 byte.
        let old=dir.appendingPathComponent("BackgroundOriginal.wav")
        let gated=dir.appendingPathComponent("BackgroundGated.wav")
        _=try OriginalMusicSynth568.generate(
            track:2,destination:old,testBars:1)
        var checkpoints=0
        _=try OriginalMusicSynth568.generate(
            track:2,destination:gated,testBars:1,
            checkpoint:{checkpoints+=1})
        precondition(checkpoints>20,
            "full-song synthesis must cooperate frequently with combat")
        let oldPCM=try Data(contentsOf:old)
        let gatedPCM=try Data(contentsOf:gated)
        precondition(oldPCM==gatedPCM,
            "combat checkpoints must not change any byte of source music")
        print("PASS source music combat checkpoints: \(checkpoints) waits, WAV byte parity")
        print("PASS source synthesis, five arrangements, deterministic repeat")
    }
}
