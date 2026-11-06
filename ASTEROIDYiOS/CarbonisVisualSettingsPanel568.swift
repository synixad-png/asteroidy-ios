import SwiftUI

/// Two real W3 settings tabs from Windows/src/Menu139.cs:
/// 11 "WYBUCHY 3D" (12 controls), 16 "POCISKI" (3 controls).
/// Unlike the old placeholder, every slider/dropdown writes to the
/// same persisted rendering profile consumed by CARBONIS 01 GPU.
struct CarbonisVisualSettingsPanel568: View {
    let compact:Bool

    @State private var profile=CarbonisVisualSettings568.load()
    @State private var tab:Int=0
    @State private var previewRevision=0

    private let gold=Color(red:0.89,green:0.67,blue:0.31)
    private let cyan=Color(red:0.39,green:0.75,blue:0.79)
    private let muted=Color(red:0.63,green:0.73,blue:0.77)

    private func save(_ change:(inout CarbonisVisualSettings568)->Void) {
        change(&profile)
        profile.clampAll()
        profile.save()
    }
    private func doubleValue(_ idx:Int)->Binding<Double> {
        Binding(get:{Double(profile.value(idx))},
                set:{n in
            save{$0.setValue(idx,Int(n.rounded()))}
        })
    }
    private func sliderRange(_ idx:Int)->ClosedRange<Double> {
        Double(CarbonisVisualSettings568.minimum[idx])...
        Double(CarbonisVisualSettings568.maximum[idx])
    }
    private var brightness:Binding<Double> {
        Binding(get:{Double(profile.projectileBrightness)},
                set:{n in
            save{$0.projectileBrightness=Int(n.rounded())}
        })
    }
    private var colorChoice:Binding<Int> {
        Binding(get:{profile.projectileColor},
                set:{n in save{$0.projectileColor=n}})
    }
    private var mixed:Binding<Bool> {
        Binding(get:{profile.projectileMixed},
                set:{n in save{$0.projectileMixed=n}})
    }

    var body:some View {
        VStack(alignment:.leading,spacing:compact ? 6:10) {
            HStack(spacing:8) {
                tabButton("WYBUCHY 3D",index:0)
                tabButton("POCISKI",index:1)
            }
            .accessibilityIdentifier("w3-effects-tabs-524-285")
            ScrollView {
                VStack(alignment:.leading,spacing:compact ? 8:13) {
                    if tab==0 {
                        explosionPage
                    } else {
                        projectilePage
                    }
                }
                .padding(.bottom,14)
                .frame(maxWidth:.infinity,alignment:.leading)
            }
        }
        .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading)
        .accessibilityIdentifier("w3-original-explosion-projectile-settings")
    }

    private func tabButton(_ title:String,index:Int)->some View {
        Button {
            tab=index
        } label:{
            Text(title)
                .font(.system(size:compact ? 10:12,
                              weight:.bold,design:.monospaced))
                .foregroundStyle(tab==index ? .black:cyan)
                .padding(.horizontal,compact ? 11:15)
                .padding(.vertical,compact ? 7:10)
                .frame(maxWidth:.infinity)
                .background(tab==index ? gold:Color.white.opacity(0.07))
                .overlay(Rectangle().stroke(
                    tab==index ? gold:cyan.opacity(0.35),lineWidth:1))
        }
        .buttonStyle(.plain)
    }
    private func header(_ title:String)->some View {
        Text(title)
            .font(.system(size:compact ? 11:13,
                          weight:.bold,design:.monospaced))
            .foregroundStyle(gold)
    }
    private var explosionPage:some View {
        VStack(alignment:.leading,spacing:compact ? 8:12) {
            header("ORYGINALNE USTAWIENIA V8.2 / EXPLOSION524")
            HStack(spacing:6) {
                ForEach(0..<CarbonisVisualSettings568.typeNames.count,
                        id:\.self) { index in
                    Button(CarbonisVisualSettings568.typeNames[index]) {
                        save{$0.selectPreset(index)}
                        previewRevision+=1
                    }
                    .font(.system(size:compact ? 10:12,
                                  weight:.bold,design:.monospaced))
                    .foregroundStyle(profile.type==index ? .black:cyan)
                    .padding(.horizontal,compact ? 5:9)
                    .padding(.vertical,compact ? 5:8)
                    .background(profile.type==index ? gold:
                                Color.white.opacity(0.08))
                    .overlay(Rectangle().stroke(
                        gold.opacity(profile.type==index ? 1:0.25)))
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("w3-explosion-type-\(index)")
                }
            }
            header("JAKOŚĆ RENDEROWANIA")
            HStack(spacing:6) {
                ForEach(0..<CarbonisVisualSettings568.qualityNames.count,
                        id:\.self) { index in
                    Button(CarbonisVisualSettings568.qualityNames[index]) {
                        save{$0.quality=index}
                    }
                    .font(.system(size:compact ? 9:11,design:.monospaced))
                    .foregroundStyle(profile.quality==index ? .black:cyan)
                    .padding(.horizontal,compact ? 5:10)
                    .padding(.vertical,compact ? 6:9)
                    .background(profile.quality==index ? gold:
                                Color.white.opacity(0.08))
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("w3-explosion-quality-\(index)")
                }
            }
            ForEach(0..<8,id:\.self) { i in
                VStack(alignment:.leading,spacing:2) {
                    HStack {
                        Text(CarbonisVisualSettings568.explosionLabels[i])
                        Spacer(minLength:8)
                        Text(explosionValue(i))
                            .foregroundStyle(gold)
                    }
                    .font(.system(size:compact ? 10:12,
                                  weight:.medium,design:.monospaced))
                    .foregroundStyle(.white)
                    Slider(value:doubleValue(i),in:sliderRange(i),
                           step:Double(CarbonisVisualSettings568.increments[i]))
                        .tint(cyan)
                        .accessibilityIdentifier("w3-explosion-slider-\(i)")
                }
            }
            HStack {
                Toggle("OBRÓT PODGLĄDU",isOn:Binding(
                    get:{profile.autoRotate},
                    set:{n in save{$0.autoRotate=n}}))
                    .toggleStyle(.switch)
                    .tint(cyan)
                    .font(.system(size:compact ? 10:12,
                                  weight:.medium,design:.monospaced))
                Spacer(minLength:5)
                Button("NOWY WYBUCH (PODGLĄD)") {
                    previewRevision+=1
                }
                .font(.system(size:compact ? 9:11,
                              weight:.bold,design:.monospaced))
                .foregroundStyle(gold)
                .padding(8)
                .background(cyan.opacity(0.13))
                .accessibilityIdentifier("w3-explosion-detonate-preview")
            }
            // Actual native Explosion524 volume shader in a dedicated
            // Metal viewport. No simulated SwiftUI fire sprites.
            CarbonisExplosion524Preview568(
                settings:profile,revision:previewRevision)
                .frame(height:compact ? 124:194)
                .background(Color.black.opacity(0.6))
                .accessibilityIdentifier("w3-explosion-metal-preview")
            Text("ŹRÓDŁO: WINDOWS v568 / WYBUCHY 3D · ZMIANY ZAPISYWANE AUTOMATYCZNIE")
                .font(.system(size:9,design:.monospaced))
                .foregroundStyle(muted)
        }
    }
    private func explosionValue(_ index:Int)->String {
        if index==1 {return "\(profile.value(index))"}
        if index==7 {
            return String(format:"%.2f s",
                          Double(profile.value(index))/100)
        }
        return "\(profile.value(index))%"
    }
    private var projectilePage:some View {
        VStack(alignment:.leading,spacing:compact ? 12:18) {
            header("ORYGINALNE USTAWIENIA POCISKÓW / GPU 285")
            VStack(alignment:.leading,spacing:4) {
                HStack {
                    Text("JASNOŚĆ OŚWIETLENIA POCISKÓW")
                    Spacer()
                    Text("\(profile.projectileBrightness)%")
                        .foregroundStyle(gold)
                }
                .foregroundStyle(.white)
                .font(.system(size:compact ? 10:12,
                              weight:.medium,design:.monospaced))
                Slider(value:brightness,in:0...400,step:5)
                    .tint(cyan)
                    .accessibilityIdentifier("w3-projectile-light-brightness")
            }
            HStack(spacing:8) {
                Text("KOLOR OŚWIETLENIA POCISKÓW")
                    .font(.system(size:compact ? 10:12,design:.monospaced))
                Spacer()
                Picker("BARWA",selection:colorChoice) {
                    ForEach(0..<CarbonisVisualSettings568.shotColorNames.count,
                            id:\.self) {index in
                        Text(CarbonisVisualSettings568.shotColorNames[index])
                            .tag(index)
                    }
                }
                .pickerStyle(.menu)
                .tint(gold)
                .accessibilityIdentifier("w3-projectile-light-color")
            }
            .foregroundStyle(.white)
            Toggle("MIESZANE KOLORY OŚWIETLENIA",isOn:mixed)
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                .tint(cyan)
                .accessibilityIdentifier("w3-projectile-light-mixed")
            Text("WYBRANA BARWA DOTYCZY ŚWIATŁA PADAJĄCEGO NA PLANETĘ. NATURALNY KOLOR POCISKU ZALEŻY OD BRONI LUB WROGA, JAK W ORYGINALE.")
                .font(.system(size:10,design:.monospaced))
                .foregroundStyle(muted)
            Text("ŹRÓDŁO: COMBAT69 / SHOTAPPEARANCE151 / GPUSPHERE67")
                .font(.system(size:10,design:.monospaced))
                .foregroundStyle(gold)
            Spacer(minLength:0)
        }
        .accessibilityIdentifier("w3-projectile-settings")
    }
}