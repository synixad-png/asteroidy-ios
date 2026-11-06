import SwiftUI

/// Faithful defaults and 5-point steps from Windows Renderer.cs options 8/9.
/// Fifteen source titles / playback preview from MusicLibrary.cs.
struct OriginalAudioSettingsPanel568: View {
    let compact: Bool
    @State private var profile = OriginalAudioSettings568.load()
    @State private var playingSelection:Int?=1
    private let cyan = Color(red:0.39,green:0.75,blue:0.79)
    private let gold = Color(red:0.89,green:0.67,blue:0.31)

    private func binding(_ music:Bool)->Binding<Double> {
        Binding(get:{Double(music ? profile.musicPercent : profile.effectsPercent)},
                set:{value in
            if music {profile.setMusic(Int(value.rounded()))}
            else {profile.setEffects(Int(value.rounded()))}
            profile.save()
        })
    }
    private func volume(_ title:String,music:Bool)->some View {
        VStack(alignment:.leading,spacing:5) {
            HStack {
                Text(title)
                Spacer()
                Text("\(music ? profile.musicPercent : profile.effectsPercent)%")
            }
            .font(.system(size:compact ? 10:13,weight:.bold,design:.monospaced))
            .foregroundStyle(cyan)
            Slider(value:binding(music),in:0...100,step:5)
                .tint(gold)
                .accessibilityIdentifier(music ? "w3-music-volume-8" : "w3-effects-volume-9")
        }
    }
    var body:some View {
        VStack(alignment:.leading,spacing:compact ? 9:14) {
            Text("ORYGINALNA MUZYKA I DŹWIĘKI / v568")
                .font(.system(size:compact ? 11:14,weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
            volume("GŁOŚNOŚĆ MUZYKI",music:true)
            volume("GŁOŚNOŚĆ EFEKTÓW",music:false)
            Text("BIBLIOTEKA 15 ORYGINALNYCH UTWORÓW")
                .font(.system(size:compact ? 10:13,weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
            ForEach(0..<OriginalAudioCatalog568.names.count,id:\.self) { index in
                HStack(spacing:8) {
                    Text(String(format:"%02d",index+1))
                        .foregroundStyle(gold)
                    Text(OriginalAudioCatalog568.names[index])
                    Spacer(minLength:5)
                    Text("\(OriginalAudioCatalog568.bpm[index]) BPM")
                        .foregroundStyle(.gray)
                    Button("ODSŁUCH") {
                        playingSelection=index
                        NotificationCenter.default.post(
                            name:.originalMusicPreview568,object:index)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(cyan)
                    .accessibilityIdentifier("w3-audio-preview-\(index)")
                }
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .padding(.vertical,4)
                .padding(.horizontal,6)
                .background(.white.opacity(0.035))
            }
            // Windows RendererW3Music355: STOP (15), REPLAY (16).
            // Odsłuch nigdy nie zmienia poziomu misji ani postępu.
            HStack(spacing:12) {
                Button("ZATRZYMAJ ODSŁUCH") {
                    playingSelection=nil
                    NotificationCenter.default.post(name:.originalMusicStop568,
                                                    object:nil)
                }
                .accessibilityIdentifier("w3-audio-stop-355")
                Button("ODTWÓRZ PONOWNIE") {
                    playingSelection = playingSelection ?? 1
                    NotificationCenter.default.post(name:.originalMusicReplay568,
                                                    object:nil)
                }
                .accessibilityIdentifier("w3-audio-replay-355")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(cyan)
            .font(.system(size:compact ? 10:12,design:.monospaced))
        }
        .onAppear {
            // MusicLibrary.OpenMusic chooses and starts source track 1.
            playingSelection=1
            NotificationCenter.default.post(name:.originalMusicPreview568,
                                            object:1)
        }
        .onDisappear {
            NotificationCenter.default.post(name:.originalMusicRestore568,
                                            object:nil)
        }
        .frame(maxWidth:.infinity,alignment:.leading)
        .accessibilityIdentifier("w3-original-audio-options-568")
    }
}
