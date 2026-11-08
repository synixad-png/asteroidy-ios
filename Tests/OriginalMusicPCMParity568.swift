import Foundation

/// Generates deterministic WAV fixtures from the unchanged v568 source
/// arranger. GitHub CI compares each byte against the approved release
/// synthesizer at commit 8af0f3f1, not just against this same implementation.
@main struct OriginalMusicPCMParity568 {
    static func main() throws {
        guard CommandLine.arguments.count==2 else {
            throw SynthError568.invalidPCM
        }
        let output=URL(fileURLWithPath:CommandLine.arguments[1],
                       isDirectory:true)
        try FileManager.default.createDirectory(at:output,
                                                withIntermediateDirectories:true)
        for (track,bars) in [(0,1),(7,24),(14,1)] {
            let filename=String(format:"source_track_%02d_bars_%02d.wav",track,bars)
            let file=output.appendingPathComponent(filename)
            _=try OriginalMusicSynth568.generate(
                track:track,destination:file,testBars:bars)
            let bytes=try Data(contentsOf:file)
            precondition(bytes.count==44+OriginalMusicSynth568.frames(track,bars)*4)
            print("PCM: \(filename) \(bytes.count) bytes")
        }
    }
}
