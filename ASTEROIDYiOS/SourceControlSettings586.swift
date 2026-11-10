import SwiftUI
import UniformTypeIdentifiers

/// W3 / STEROWANIE: one 65-row scrollable list, original action indices.
/// Only actions backed by the current iOS engine are marked as playable;
/// future PC co-op, drill, planetarium and debug commands remain described,
/// not wired to false buttons. Rebinding has immediate persistent effect.
struct SourceControlSettings586:View {
    let compact:Bool
    @State private var profile=SourceControls586.Profile.load()
    @State private var importingPC=false
    @State private var notice=""
    @State private var confirmReset=false

    private let gold=Color(red:0.89,green:0.67,blue:0.31)
    private let cyan=Color(red:0.39,green:0.75,blue:0.79)
    private let muted=Color(red:0.63,green:0.73,blue:0.77)

    private static let availableKeys:[Int] = {
        var values=[0,9,13,27,32,33,34,37,38,39,40]
        values.append(contentsOf:Array(48...57))
        values.append(contentsOf:Array(65...90))
        values.append(contentsOf:Array(96...105))
        values.append(contentsOf:Array(112...123))
        values.append(contentsOf:[160,161,162,163,164,165,187,188,189,190])
        return values
    }()
    private static let availablePad:[String] = {
        var values=[""]
        values.append(contentsOf:(0...14).map{"B\($0)"})
        values.append(contentsOf:(0...5).flatMap{["A\($0)-","A\($0)+"]})
        values.append("B9+B3")
        return values
    }()

    private func mutate(_ change:(inout SourceControls586.Profile)->Void) {
        change(&profile)
        profile.normalize()
        profile.save()
    }

    private func status(_ action:Int)->String {
        switch SourceControls586.context(for:action) {
        case .combat:
            return (action==33 || action==34)
                ? "DZIAŁA / MISJA 01 + H55" : "DZIAŁA / MISJA 01"
        case .hangar:return "DZIAŁA / H55"
        case .other:return "NIEPRZENIESIONE / PC"
        }
    }

    @ViewBuilder private func actionRow(_ action:Int)->some View {
        let conflicts=SourceControls586.conflictingActions(action,profile:profile)
        VStack(alignment:.leading,spacing:compact ? 3:5) {
            HStack(alignment:.firstTextBaseline,spacing:6) {
                Text(String(format:"%02d",action))
                    .foregroundStyle(gold)
                    .frame(width:27,alignment:.leading)
                Text(SourceControls586.label(action))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Spacer(minLength:6)
                Text(status(action))
                    .font(.system(size:compact ? 8:10,design:.monospaced))
                    .foregroundStyle(SourceControls586.context(for:action)==(.other)
                        ? muted : cyan)
                    .lineLimit(1)
            }
            HStack(spacing:compact ? 8:18) {
                Text("KLAWIATURA")
                    .foregroundStyle(muted)
                    .frame(width:compact ? 72:100,alignment:.leading)
                Menu {
                    ForEach(Self.availableKeys,id:\.self) {key in
                        Button(SourceControls586.keyName(key)) {
                            mutate{$0.keys[action]=key}
                        }
                    }
                } label:{
                    Text(SourceControls586.keyName(profile.keys[action]))
                        .foregroundStyle(gold)
                        .frame(minWidth:60,alignment:.leading)
                }
                .accessibilityIdentifier("pc586-key-\(action)")
                Spacer(minLength:4)
                Text("PAD").foregroundStyle(muted)
                Menu {
                    ForEach(Self.availablePad,id:\.self) {token in
                        Button(token.isEmpty ? "BRAK":token) {
                            mutate{$0.pad[action]=token}
                        }
                    }
                } label:{
                    Text(profile.pad[action].isEmpty
                        ? "BRAK":profile.pad[action])
                        .foregroundStyle(gold)
                        .lineLimit(1)
                }
                .accessibilityIdentifier("pc586-pad-\(action)")
            }
            if !conflicts.isEmpty {
                Text("UWAGA: KONFLIKT PRZYPISANIA Z AKCJĄ " +
                     conflicts.map{String($0)}.joined(separator:", "))
                    .foregroundStyle(.orange)
                    .font(.system(size:compact ? 8:10,design:.monospaced))
                    .fixedSize(horizontal:false,vertical:true)
            }
        }
        .font(.system(size:compact ? 9:11,design:.monospaced))
        .padding(.horizontal,compact ? 7:11)
        .padding(.vertical,compact ? 6:9)
        .frame(maxWidth:.infinity,alignment:.leading)
        .background(Color(red:0.014,green:0.057,blue:0.078))
        .overlay(alignment:.leading) {
            Rectangle().fill(SourceControls586.context(for:action)==(.other)
                ? muted.opacity(0.33):gold.opacity(0.85))
                .frame(width:3)
        }
        .accessibilityIdentifier("pc586-action-\(action)")
    }

    private func optionTitle(_ id:Int)->some View {
        HStack {
            Text(String(format:"%02d",id))
                .foregroundStyle(gold)
                .frame(width:27,alignment:.leading)
            Text(SourceControls586.label(id))
                .foregroundStyle(.white)
            Spacer(minLength:4)
            Text(id==60 ? "DZIAŁA / PAD" : "ZAPIS / PC")
                .font(.system(size:compact ? 7:9,design:.monospaced))
                .foregroundStyle(id==60 ? cyan:muted)
                .lineLimit(1)
        }
        .font(.system(size:compact ? 9:11,design:.monospaced))
    }

    @ViewBuilder private var extraRows:some View {
        VStack(alignment:.leading,spacing:10) {
            optionTitle(60)
            HStack {
                Text("\(profile.deadZone)%")
                    .foregroundStyle(gold)
                Slider(value:Binding(
                    get:{Double(profile.deadZone)},
                    set:{v in mutate{$0.deadZone=Int(v.rounded())}}
                ),in:10...60,step:5)
                    .tint(cyan)
                    .accessibilityIdentifier("pc586-deadzone")
            }
        }
        .accessibilityIdentifier("pc586-extra-60")
        VStack(alignment:.leading) {
            optionTitle(61)
            Toggle("ODWRÓĆ OŚ PIONOWĄ ATLASU",
                   isOn:Binding(get:{profile.invertOrbitPitch},
                                set:{v in mutate{$0.invertOrbitPitch=v}}))
                .tint(cyan)
        }.accessibilityIdentifier("pc586-extra-61")
        VStack(alignment:.leading) {
            optionTitle(62)
            Toggle("OBSŁUGA MYSZY W ATLASIE",
                   isOn:Binding(get:{profile.orbitMouse},
                                set:{v in mutate{$0.orbitMouse=v}}))
                .tint(cyan)
        }.accessibilityIdentifier("pc586-extra-62")
        VStack(alignment:.leading,spacing:8) {
            optionTitle(63)
            HStack {
                Text("\(profile.mouseSensitivity)%")
                    .foregroundStyle(gold)
                Slider(value:Binding(
                    get:{Double(profile.mouseSensitivity)},
                    set:{v in mutate{$0.mouseSensitivity=Int(v.rounded())}}
                ),in:25...200,step:5)
                    .tint(cyan)
            }
        }.accessibilityIdentifier("pc586-extra-63")
        VStack(alignment:.leading) {
            optionTitle(64)
            Toggle("ODWRÓĆ PION MYSZY",
                   isOn:Binding(get:{profile.invertMouse},
                                set:{v in mutate{$0.invertMouse=v}}))
                .tint(cyan)
        }.accessibilityIdentifier("pc586-extra-64")
    }

    var body:some View {
        VStack(alignment:.leading,spacing:9) {
            Text("STEROWANIE / PC v586")
                .font(.system(size:compact ? 12:15,
                              weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
            Text("60 oryginalnych akcji + 5 ustawień urządzeń. Jedna przewijana lista. Kody i domyślne przypisania pochodzą z Windows/src/Controls.cs.")
                .foregroundStyle(muted)
                .font(.system(size:compact ? 9:11,design:.monospaced))
                .fixedSize(horizontal:false,vertical:true)
            HStack(spacing:6) {
                Text("OSŁONA [\(SourceControls586.keyName(profile.keys[21]))]")
                Text("BOMBA [\(SourceControls586.keyName(profile.keys[7]))]")
                Text("DOPALACZ [\(SourceControls586.keyName(profile.keys[35]))]")
            }
            .font(.system(size:compact ? 8:11,design:.monospaced))
            .foregroundStyle(gold)
            .lineLimit(1)
            Rectangle().fill(cyan.opacity(0.3)).frame(height:1)

            // The parent W3 right pane already owns the ONLY ScrollView.
            // LazyVStack saves memory and does not nest a second scroller.
            LazyVStack(alignment:.leading,spacing:4) {
                ForEach(0..<SourceControls586.actionCount,id:\.self) {i in
                    actionRow(i)
                }
                Rectangle().fill(cyan.opacity(0.45)).frame(height:1)
                    .padding(.vertical,5)
                extraRows
            }
            .accessibilityIdentifier("pc586-60-actions-five-options")
            HStack(spacing:compact ? 6:14) {
                Button("IMPORT PC") {importingPC=true}
                    .accessibilityIdentifier("pc586-import-original-controls")
                Button("PRZYWRÓĆ DOMYŚLNE") {confirmReset=true}
                    .accessibilityIdentifier("pc586-reset-original-controls")
            }
            .font(.system(size:compact ? 9:11,design:.monospaced))
            .foregroundStyle(gold)
            .buttonStyle(.plain)
            .padding(.vertical,10)
            if !notice.isEmpty {
                Text(notice)
                    .foregroundStyle(cyan)
                    .font(.system(size:compact ? 9:11,design:.monospaced))
                    .fixedSize(horizontal:false,vertical:true)
            }
            Text("Martwa strefa (60) działa w misji i H55. Opcje atlasu/myszy (61–64) są przechowywane dla dalszego portu PC, lecz nie sterują dziś tymi scenami.")
                .foregroundStyle(muted)
                .font(.system(size:compact ? 8:10,design:.monospaced))
                .fixedSize(horizontal:false,vertical:true)
            Text("Przypisania dla funkcji nieprzeniesionych są zapisywane na przyszłość; nie uruchamiają nieistniejących mechanik. Import z PC: wybierz controls-v29.txt i opcjonalny controls-v29.txt.flight67 (dla myszy).")
                .foregroundStyle(muted)
                .font(.system(size:compact ? 8:10,design:.monospaced))
                .fixedSize(horizontal:false,vertical:true)
        }
        .fileImporter(isPresented:$importingPC,
                      allowedContentTypes:[.plainText,.data],
                      allowsMultipleSelection:true) {outcome in
            do {
                let urls=try outcome.get()
                guard (1...2).contains(urls.count) else {
                    notice="WYBIERZ JEDEN LUB DWA ORYGINALNE PLIKI PC"
                    return
                }
                var importedControls:SourceControls586.Profile?
                var flightFile:String?
                for url in urls {
                    let granted=url.startAccessingSecurityScopedResource()
                    defer {if granted {url.stopAccessingSecurityScopedResource()}}
                    let raw=try String(contentsOf:url,encoding:.utf8)
                    let first=raw.replacingOccurrences(of:"\u{FEFF}",with:"")
                    if first.hasPrefix("ASTEROIDY_CONTROLS_") {
                        guard importedControls==nil,
                              let decoded=SourceControls586.Profile.importPCText(raw)
                        else {
                            notice="ODRZUCONO: nieprawidłowe lub powtórzone przypisania"
                            return
                        }
                        importedControls=decoded
                    } else if first.hasPrefix("ASTEROIDY_FLIGHT_67") {
                        guard flightFile==nil else {
                            notice="ODRZUCONO: zduplikowany plik myszy"
                            return
                        }
                        flightFile=raw
                    } else {
                        notice="ODRZUCONO: nieznany format PC"
                        return
                    }
                }
                var merged=importedControls ?? profile
                if let flight=flightFile {
                    guard let updated=SourceControls586.Profile.importFlight67Text(
                        flight,into:merged) else {
                        notice="ODRZUCONO: nieprawidłowy plik .flight67"
                        return
                    }
                    merged=updated
                }
                // No partial writes: both files are validated before save.
                profile=merged
                profile.save()
                notice="ZAIMPORTOWANO: sterowanie PC (v1/v2) i ustawienia myszy, jeśli wybrano."
            } catch {
                notice="BŁĄD IMPORTU: \(error.localizedDescription)"
            }
        }
        .confirmationDialog("Przywrócić oryginalne 60 przypisań PC v586?",
                            isPresented:$confirmReset) {
            Button("PRZYWRÓĆ",role:.destructive) {
                profile=SourceControls586.Profile()
                profile.save()
                notice="Przywrócono oryginalne przypisania PC v586."
            }
            Button("ANULUJ",role:.cancel) {}
        }
        .accessibilityIdentifier("pc586-native-scrollable-controls")
    }
}
