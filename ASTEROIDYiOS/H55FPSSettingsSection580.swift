import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Original PC580 first-person models live in W3 RĘKAWICE/BROŃ settings.
/// Bundled original GLBs load without any user action. Files import is optional.
struct H55FPSSettingsSection580: View {
    let category:H55FPSSettings580.Mode
    let loader:H55SceneModel580?

    @State private var stored=H55FPSSettings580()
    @State private var available:Set<H55FPSAssets580.Kind>=[]
    @State private var choosingFile=false
    @State private var importKind:H55FPSAssets580.Kind = .tripo
    @State private var importMessage=""
    @State private var rightHand=false

    private let gold=Color(red:0.89,green:0.67,blue:0.31)
    private let cyan=Color(red:0.39,green:0.75,blue:0.79)
    private let axes=["POZYCJA X","POZYCJA Y","POZYCJA Z",
                      "OBRÓT X","OBRÓT Y","OBRÓT Z","SKALA"]

    private var current:H55FPSSettings580 { loader?.fpsCalibration ?? stored }
    private var target:H55FPSSettings580.Target {
        category == .weapon ? .weapon : (rightHand ? .right : .left)
    }
    private func refreshAvailable() {
        available=Set(H55FPSAssets580.Kind.allCases.filter {
            H55FPSAssets580.installed($0) != nil
        })
    }
    private func select(_ kind:H55FPSAssets580.Kind) {
        if let loader {
            switch kind {
            case .tripo:loader.setFPSGloves(.tripo)
            case .monolith:loader.setFPSGloves(.monolith)
            case .weapon:loader.setFPSMode(.weapon)
            }
            stored=loader.fpsCalibration
        } else {
            switch kind {
            case .tripo:
                stored.changeModel(.tripo)
                stored.mode = .gloves
            case .monolith:
                stored.changeModel(.monolith)
                stored.mode = .gloves
            case .weapon:stored.mode = .weapon
            }
            stored.save()
        }
        importMessage=available.contains(kind)
            ? "WYBRANO ZWERYFIKOWANY MODEL — BĘDZIE WIDOCZNY PODCZAS CHODZENIA"
            : "BRAK GLB — WYBIERZ IMPORTUJ ORYGINALNY PLIK"
    }
    private func calibrate(_ axis:Int,_ value:Int) {
        let kind:H55FPSAssets580.Kind = category == .weapon ? .weapon :
            (current.model == .tripo ? .tripo : .monolith)
        select(kind)
        if let loader {
            loader.setFPSCalibration(target,component:axis,value:value)
            stored=loader.fpsCalibration
        } else {
            stored.calibrate(target,component:axis,value:value)
        }
    }
    private func resetPose() {
        let kind:H55FPSAssets580.Kind = category == .weapon ? .weapon :
            (current.model == .tripo ? .tripo : .monolith)
        select(kind)
        if let loader {
            loader.resetFPSCalibration(target)
            stored=loader.fpsCalibration
        } else {
            stored.reset(target)
        }
    }
    private func importOriginal(_ result:Result<[URL],Error>) {
        do {
            guard let url=try result.get().first else{return}
            if let loader {
                try loader.importFPS(url,kind:importKind)
                stored=loader.fpsCalibration
            } else {
                _=try H55FPSAssets580.install(url,as:importKind)
                select(importKind)
            }
            refreshAvailable()
            importMessage="ORYGINALNY MODEL ZWERYFIKOWANO I ZAPISANO"
        } catch {
            importMessage="BŁĄD IMPORTU: "+error.localizedDescription
        }
    }
    private func modelRow(_ title:String,kind:H55FPSAssets580.Kind,
                          selector:String,importer:String)->some View {
        VStack(alignment:.leading,spacing:5) {
            HStack(spacing:9) {
                Button(title) {select(kind)}
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier(selector)
                Text(available.contains(kind) ? "GOTOWY GLB" : "BRAK GLB")
                    .font(.system(size:10,weight:.semibold,design:.monospaced))
                    .foregroundStyle(available.contains(kind) ? cyan : Color.orange)
            }
            Button("IMPORTUJ ORYGINALNY GLB (OPCJONALNIE)") {
                importKind=kind
                choosingFile=true
            }
            .font(.system(size:10,design:.monospaced))
            .accessibilityIdentifier(importer)
        }
    }
    private func axisRow(_ axis:Int)->some View {
        let r=H55FPSSettings580.limits(axis)
        return VStack(alignment:.leading,spacing:3) {
            HStack {
                Text(axes[axis])
                Spacer()
                Text(String(current.pose(target)[axis])+(axis==6 ? "%" : axis>=3 ? "°" : " cm"))
                    .monospacedDigit()
            }
            .font(.system(size:10,weight:.medium,design:.monospaced))
            Slider(value:Binding(get:{Double(current.pose(target)[axis])},
                        set:{calibrate(axis,Int($0.rounded()))}),
                   in:Double(r.lowerBound)...Double(r.upperBound),step:1)
                .tint(gold)
                .accessibilityIdentifier("h55-fps-calibration-axis-\(axis)")
        }
    }
    var body:some View {
        VStack(alignment:.leading,spacing:11) {
            Text(category == .gloves ? "ORYGINALNE RĘKAWICE PC580"
                                     : "ORYGINALNA BROŃ EXP-01 PC580")
                .font(.system(size:13,weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
            Text("Oryginalne GLB ładowane są z aplikacji automatycznie. Import z Plików jest tylko opcją awaryjną.")
                .font(.system(size:10,design:.monospaced))
                .foregroundStyle(.secondary)
            if category == .gloves {
                modelRow("RĘCE TRIPO",kind:.tripo,
                    selector:"h55-fps-show-hands",importer:"h55-fps-import-hands")
                modelRow("RĘCE MONOLIT",kind:.monolith,
                    selector:"h55-fps-show-monolith",importer:"h55-fps-import-monolith")
                Picker("DŁOŃ",selection:$rightHand) {
                    Text("LEWA").tag(false)
                    Text("PRAWA").tag(true)
                }.pickerStyle(.segmented)
                Text(current.model == .tripo ? "KALIBRACJA TRIPO" : "KALIBRACJA MONOLIT")
                    .font(.system(size:11,design:.monospaced))
            } else {
                modelRow("BROŃ EXP-01",kind:.weapon,
                    selector:"h55-fps-show-weapon",importer:"h55-fps-import-weapon")
            }
            ForEach(0..<7,id:\.self) {axis in axisRow(axis)}
            Button("PRZYWRÓĆ POZYCJĘ DOMYŚLNĄ") {resetPose()}
                .buttonStyle(.bordered)
                .accessibilityIdentifier("h55-fps-reset-calibration")
            if let loader {
                Text(loader.fpsStatus)
                    .font(.system(size:10,design:.monospaced))
                    .foregroundStyle(cyan)
            }
            if !importMessage.isEmpty {
                Text(importMessage)
                    .font(.system(size:10,design:.monospaced))
                    .foregroundStyle(importMessage.hasPrefix("BŁĄD") ? Color.orange : cyan)
            }
        }
        .onAppear {
            stored=loader?.fpsCalibration ?? H55FPSSettings580()
            refreshAvailable()
        }
        .fileImporter(isPresented:$choosingFile,
            allowedContentTypes:[UTType(filenameExtension:"glb") ?? .data],
            allowsMultipleSelection:false,onCompletion:importOriginal)
        .accessibilityIdentifier(category == .gloves
            ? "h55-fps-gloves-settings" : "h55-fps-weapon-settings")
    }
}
