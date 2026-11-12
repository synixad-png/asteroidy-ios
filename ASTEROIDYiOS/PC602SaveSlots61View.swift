import Foundation
import SwiftUI

/// One native presentation of SaveManager61.SaveKey61 and PerformSave61.
/// Shared by H290 and W3: original three slots, selection, operations,
/// overwrite/load/delete confirmation. The iOS snapshot is JSON, not PC .sav.
struct PC602SaveSlots61View:View {
    let allowSave:Bool
    // Source SaveKey61: only replacing an ACTIVE session requires confirmation.
    let confirmActiveLoad:Bool
    let initialAction:Int
    let onSave:(Int)->Bool
    let onLoad:(Int)->Bool
    let onClose:()->Void

    @State private var selected=0
    @State private var pending:Int?
    @State private var status=""

    private func caption(_ slot:Int)->String {
        if let value=try? PC602OrbitSave61.read(slot:slot) {
            let stamp=Date(timeIntervalSince1970:value.savedAt)
                .formatted(date:.numeric,time:.shortened)
            let label=value.isMissionIntro61
                ? "POCZĄTEK MISJI \(String(format:"%02d",value.missionLevel61 ?? 1))"
                : "ORBITA / MISJA \(String(format:"%02d",value.target))"
            return "VANGUARD / \(label) / \(stamp)"
        }
        return PC602OrbitSave61.slotFileExists(slot)
            ? "USZKODZONY ZAPIS" : "PUSTY SLOT"
    }

    private func request(_ action:Int) {
        switch action {
        case 0:
            guard allowSave else{return}
            // PC602 SaveKey61 confirms overwrite if a file exists,
            // including invalid or corrupt files.
            if PC602OrbitSave61.slotFileExists(selected) {pending=action}
            else {perform(action)}
        case 1:
            guard PC602OrbitSave61.exists(slot:selected) else {
                status="Zapis pusty lub uszkodzony.";return
            }
            // In the original source, replacing an active session prompts.
            if confirmActiveLoad {pending=action}
            else {perform(action)}
        case 2:pending=action
        default:break
        }
    }

    private func perform(_ action:Int) {
        pending=nil
        switch action {
        case 0:
            status=onSave(selected)
                ? "ZAPISANO SLOT \(selected+1)"
                : "NIE UDAŁO SIĘ ZAPISAĆ PLIKU"
        case 1:
            if onLoad(selected) {onClose()}
            else {status="WCZYTANIE NIEUDANE"}
        case 2:
            status=PC602OrbitSave61.deleteSlot(selected)
                ? "USUNIĘTO ZAPIS"
                : "NIE UDAŁO SIĘ USUNĄĆ / SLOT JEST PUSTY"
        default:break
        }
    }

    private func confirmText(_ action:Int)->String {
        switch action {
        case 0:return "Nadpisać zapis? Enter / A: TAK · Esc / B: NIE"
        case 1:return "Wczytać i zastąpić bieżącą grę? Enter / A: TAK · Esc / B: NIE"
        default:return "Usunąć ten zapis? Enter / A: TAK · Esc / B: NIE"
        }
    }

    var body:some View {
        GeometryReader { geo in
            let compact=geo.size.height<450
            ZStack {
                Color.black.opacity(0.84).ignoresSafeArea()
                VStack(alignment:.leading,spacing:compact ? 6:12) {
                    HStack {
                        Text(initialAction==1
                             ? "KONTYNUACJA / ZAPISY" : "ZAPISY / 3 SLOTY")
                            .fontWeight(.bold)
                        Spacer(minLength:8)
                        Button("WSTECZ") {onClose()}
                            .frame(minWidth:100,minHeight:52)
                            .background(Color(red:0.05,green:0.15,blue:0.22),
                                        in:RoundedRectangle(cornerRadius:5))
                            .accessibilityIdentifier("pc602-save61-back")
                    }
                    Text("TRZY SLOTY / DANE Z PRAWIDŁOWYCH ZAPISÓW")
                        .font(.system(size:compact ? 14:16,design:.monospaced))
                    ForEach(0..<3,id:\.self) { slot in
                        Button {
                            selected=slot
                            status=""
                        } label: {
                            HStack(spacing:8) {
                                Text("SLOT \(String(format:"%02d",slot+1))")
                                    .fontWeight(.bold)
                                Text(caption(slot))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.90)
                                Spacer(minLength:0)
                            }
                            .frame(maxWidth:.infinity,
                                   minHeight:compact ? 52:64,alignment:.leading)
                            .padding(.horizontal,12)
                            .background(selected==slot
                                ? Color(red:34/255,green:35/255,blue:36/255)
                                : Color(red:4/255,green:18/255,blue:29/255),
                                in:RoundedRectangle(cornerRadius:5))
                            .overlay(Rectangle().stroke(
                                selected==slot ? .yellow : .gray.opacity(0.35),
                                lineWidth:selected==slot ? 2:1))
                            .contentShape(Rectangle())
                        }
                        .accessibilityIdentifier("pc602-orbit-save61-slot-\(slot)")
                    }
                    HStack(spacing:8) {
                        ForEach(0..<3,id:\.self) { action in
                            Button(["ZAPISZ","WCZYTAJ","USUŃ"][action]) {
                                request(action)
                            }
                            .disabled(action==0 && !allowSave)
                            .frame(maxWidth:.infinity,
                                   minHeight:compact ? 52:60)
                            .background(Color(red:5/255,green:19/255,blue:30/255),
                                        in:RoundedRectangle(cornerRadius:5))
                            .overlay(RoundedRectangle(cornerRadius:5)
                                .stroke(.yellow.opacity(0.6),lineWidth:1))
                            .accessibilityIdentifier("pc602-save61-action-\(action)")
                        }
                    }
                    Text(status.isEmpty ? "WYBIERZ SLOT I OPERACJĘ" : status)
                        .font(.system(size:compact ? 14:16,design:.monospaced))
                        .foregroundStyle(.yellow).lineLimit(2)
                }
                .font(.system(size:compact ? 15:18,
                              weight:.semibold,design:.monospaced))
                .foregroundStyle(.white)
                .buttonStyle(.plain)
                .padding(compact ? 14:22)
                .frame(maxWidth:790)
                .background(Color(red:5/255,green:17/255,blue:28/255))
                .overlay(Rectangle().stroke(.yellow.opacity(0.6)))
                .padding(12)
                if let action=pending {
                    Color.black.opacity(0.90).ignoresSafeArea()
                    VStack(spacing:14) {
                        Text(confirmText(action)).multilineTextAlignment(.center)
                        HStack(spacing:16) {
                            Button("ANULUJ / B") {pending=nil}
                                .accessibilityIdentifier("pc602-save61-cancel")
                            Button("POTWIERDŹ / A") {perform(action)}
                                .accessibilityIdentifier("pc602-save61-confirm")
                        }
                    }
                    .font(.system(size:compact ? 15:18,design:.monospaced))
                    .foregroundStyle(.white)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(18)
                    .frame(maxWidth:600)
                    .background(Color(red:5/255,green:17/255,blue:28/255))
                    .overlay(Rectangle().stroke(.yellow,lineWidth:1))
                    .accessibilityIdentifier("pc602-save61-confirmation")
                }
            }
            .frame(width:geo.size.width,height:geo.size.height)
        }
        .accessibilityIdentifier("pc602-source-three-slot-save61")
    }
}
