import SwiftUI

/// Source Windows/src/MusicLoading.cs DrawMusicLoading:
/// (1) real sound bank, (2) Astral Gate, (3) Orbital Pulse.
/// Menu can open only after those source assets are inspected. Other
/// 13 tracks are prepared afterward and do not block the main screen.
struct OriginalAudioLoadingView568: View {
    @ObservedObject var audio: OriginalAudioAV568
    private let cyan = Color(red:0.40,green:0.77,blue:0.83)
    private let gold = Color(red:0.84,green:0.66,blue:0.37)
    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height<550
            VStack(alignment:.leading,spacing:compact ? 8:21) {
                HStack {
                    Text("ASTEROIDY")
                        .font(.system(size:compact ? 24:40,weight:.black,design:.monospaced))
                    Spacer()
                    Text("SYSTEM STARTOWY / AUDIO")
                        .font(.system(size:compact ? 10:15,weight:.bold,design:.monospaced))
                        .foregroundStyle(cyan)
                }
                Rectangle().fill(gold).frame(height:1)
                Text("FAZA INICJALIZACJI")
                    .font(.system(size:compact ? 11:17,weight:.bold,design:.monospaced))
                    .foregroundStyle(cyan)
                Text("PRZYGOTOWYWANIE MUZYKI")
                    .font(.system(size:compact ? 18:29,weight:.bold,design:.monospaced))
                Text(audio.sourceStatus)
                    .font(.system(size:compact ? 10:15,design:.monospaced))
                    .foregroundStyle(.gray)
                ForEach(0..<3,id:\.self) { index in
                    HStack(spacing:12) {
                        Text(String(format:"%02d",index+1))
                            .foregroundStyle(index==audio.stage ? gold : cyan)
                        Text(["EFEKTY DŹWIĘKOWE", "ASTRAL GATE", "ORBITAL PULSE"][index])
                        Spacer(minLength:0)
                        Text(audio.stage>index ? "ZAKOŃCZONO" :
                             audio.stage==index ? "W TRAKCIE" : "OCZEKUJE")
                            .foregroundStyle(audio.stage>index ? cyan : .gray)
                    }
                    .font(.system(size:compact ? 10:13,weight:.semibold,design:.monospaced))
                    .padding(compact ? 7:12)
                    .background(.white.opacity(index==audio.stage ? 0.09:0.04))
                }
                HStack {
                    Text("GOTOWE UTWORY MENU")
                    Spacer()
                    Text("\(audio.readyMenuTracks) / 2")
                }
                .font(.system(size:compact ? 10:14,design:.monospaced))
                .foregroundStyle(cyan)
                ProgressView(value:Double(audio.readyMenuTracks),total:2)
                    .tint(cyan)
                Text("Dalsze 13 utworów zostanie przygotowanych w tle po otwarciu menu.")
                    .font(.system(size:compact ? 10:13,design:.monospaced))
                    .foregroundStyle(.gray)
                Spacer(minLength:0)
            }
            .padding(compact ? 18:42)
            .foregroundStyle(.white)
            .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading)
            .background(Color(red:0.01,green:0.03,blue:0.05))
        }
        .accessibilityIdentifier("w3-original-audio-loading-283")
    }
}
