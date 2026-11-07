import SwiftUI

/// Two real W3 settings tabs from Windows/src/Menu139.cs:
/// 11 "WYBUCHY 3D" (12 controls), 16 "POCISKI" (3 controls).
/// Unlike the old placeholder, every slider/dropdown writes to the
/// same persisted rendering profile consumed by CARBONIS 01 GPU.
struct CarbonisVisualSettingsPanel568: View {
    let compact:Bool

    @State private var profile=CarbonisVisualSettings568.load()
    @State private var planetProfile=SourcePlanetGraphicsSettings568.load()
    @State private var lava287=SourceLavaLightSettings287.load()
    @State private var shipScale472=SourceShipScale472.load()
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
    private func saveLava(_ value:Int) {
        lava287.setBrightness(value)
        lava287.save()
    }
    private func savePlanet(_ change:(inout SourcePlanetGraphicsSettings568)->Void) {
        change(&planetProfile)
        planetProfile.clampAll()
        planetProfile.save()
    }
    private func saveShipScale(_ update:(inout SourceShipScale472)->Void) {
        update(&shipScale472)
        shipScale472.clampAll()
        shipScale472.save()
    }
    private func doubleValue(_ idx:Int)->Binding<Double> {
        Binding(get:{Double(profile.value(idx))},
                set:{n in
            save{$0.setValue(idx,Int(n.rounded()))}
        })
    }
    private func sliderRange(_ idx:Int)->ClosedRange<Double> {
        let low=Double(CarbonisVisualSettings568.minimum[idx])
        let high=Double(CarbonisVisualSettings568.maximum[idx])
        return low...high
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
            ScrollView(.horizontal,showsIndicators:false) {
                HStack(spacing:8) {
                    tabButton("WYBUCHY 3D",index:0)
                    tabButton("POCISKI",index:1)
                    tabButton("AUDIO",index:2)
                    tabButton("PLANETY",index:3)
                    tabButton("POSTPROCES",index:4)
                    tabButton("STATEK",index:5)
                }
            }
            .accessibilityIdentifier("w3-effects-tabs-524-285")
            ScrollView {
                VStack(alignment:.leading,spacing:compact ? 8:13) {
                    if tab==0 {
                        explosionPage
                    } else if tab==1 {
                        projectilePage
                    } else if tab==2 {
                        OriginalAudioSettingsPanel568(compact:compact)
                    } else if tab==3 {
                        planetPage
                    } else if tab==4 {
                        postprocessPage
                    } else {
                        shipSizePage
                    }
                }
                .padding(.bottom,14)
                .frame(maxWidth:.infinity,alignment:.leading)
            }
            .accessibilityIdentifier("w3-effects-scroll")
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
        .accessibilityIdentifier("w3-effects-tab-\(index)")
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
                    .accessibilityValue(profile.type==index ? "wybrany":"niewybrany")
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
                    .accessibilityValue(profile.quality==index ? "wybrany":"niewybrany")
                }
            }
            ForEach(0..<8,id:\.self) { i in
                VStack(alignment:.leading,spacing:2) {
                    HStack {
                        Text(CarbonisVisualSettings568.explosionLabels[i])
                        Spacer(minLength:8)
                        Text(explosionValue(i))
                            .foregroundStyle(gold)
                            .accessibilityIdentifier("w3-explosion-value-\(i)")
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
                        .accessibilityIdentifier("w3-projectile-brightness-value")
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
    // Menu139.cs: source PLANETY tab, original IDs #55 / #56 / #57.
    // This is the same profile that the actual C279 Metal renderer reads.
    private var planetPage:some View {
        VStack(alignment:.leading,spacing:compact ? 10:18) {
            header("ORYGINALNE USTAWIENIA PLANET / v436–437")
            Toggle("ŚWIATŁO PLANETY",isOn:Binding(
                get:{planetProfile.planetLightEnabled},
                set:{v in savePlanet{$0.planetLightEnabled=v}}))
                .tint(cyan)
                .foregroundStyle(.white)
                .accessibilityIdentifier("w3-planet-light-436")
            VStack(alignment:.leading,spacing:4) {
                HStack {
                    Text("ŚWIATŁO PLANETY / PRĘDKOŚĆ")
                    Spacer()
                    Text("\(planetProfile.planetLightSpeed)%")
                        .foregroundStyle(gold)
                }
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                Slider(value:Binding(
                    get:{Double(planetProfile.planetLightSpeed)},
                    set:{v in savePlanet{$0.planetLightSpeed=Int(v)}}),
                    in:0...400,step:5)
                    .tint(cyan)
                    .accessibilityIdentifier("w3-planet-light-speed-436")
            }
            VStack(alignment:.leading,spacing:4) {
                HStack {
                    Text("ŚWIATŁO PLANETY / JASNOŚĆ NOCY")
                    Spacer()
                    Text("\(planetProfile.planetNightBrightness)%")
                        .foregroundStyle(gold)
                }
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                Slider(value:Binding(
                    get:{Double(planetProfile.planetNightBrightness)},
                    set:{v in savePlanet{$0.planetNightBrightness=Int(v)}}),
                    in:0...400,step:5)
                    .tint(cyan)
                    .accessibilityIdentifier("w3-planet-night-brightness-437")
            }
            VStack(alignment:.leading,spacing:4) {
                HStack {
                    Text("JASNOŚĆ EMISJI LAWY")
                    Spacer()
                    Text("\(lava287.brightnessPercent)%")
                        .foregroundStyle(gold)
                        .accessibilityIdentifier("w3-planet-lava-brightness-value-287")
                }
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                Slider(value:Binding(
                    get:{Double(lava287.brightnessPercent)},
                    set:{v in saveLava(Int(v.rounded()))}),
                    in:0...400,step:5)
                    .tint(cyan)
                    .accessibilityIdentifier("w3-planet-lava-brightness-287")
            }
            Text("ORYGINALNE MENU: PLANETY / #45 — EMISJA LAWY CARBONIS, POŚWIATA LAWY NEWHOME ORAZ MATERIAŁY LAWOWE INNYCH PLANET, GDY ICH RENDERERY ZOSTANĄ PRZENIESIONE.")
                .font(.system(size:compact ? 9:11,design:.monospaced))
                .foregroundStyle(muted)
            Text("ORIGINAL: WINDOWS/src/Menu139.cs #45, #55–57. LAWĘ REGULUJE SKALA 0–400%, KROK 5%, DOMYŚLNIE 180%.")
                .font(.system(size:9,design:.monospaced))
                .foregroundStyle(muted)
                .font(.system(size:9,design:.monospaced))
                .foregroundStyle(muted)
            Spacer(minLength:0)
        }
        .accessibilityIdentifier("w3-original-planet-settings-436")
    }
    private var postprocessPage:some View {
        VStack(alignment:.leading,spacing:compact ? 10:18) {
            header("ORYGINALNE USTAWIENIA POSTPROCES / #2")
            Toggle("GLOW — POŚWIATA",isOn:Binding(
                get:{planetProfile.glowEnabled},
                set:{v in savePlanet{$0.glowEnabled=v}}))
                .tint(cyan)
                .foregroundStyle(.white)
                .accessibilityIdentifier("w3-source-planet-glow-256")
            Text("PRZEŁĄCZNIK ORYGINAŁU: WŁĄCZA / WYŁĄCZA POŚWIATĘ I ATMOSFERĘ PLANETY. SAM MODEL 3D, EMISJA TEKSTURY ORAZ ŚWIATŁO POCISKÓW POZOSTAJĄ NIENARUSZONE.")
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(muted)
            Text("ŹRÓDŁO: WINDOWS/src/Renderer.cs OPTION #2; GpuPlanet.cs Atmosphere47; GpuPlanetAnimation.cs GlowVertex.")
                .font(.system(size:9,design:.monospaced))
                .foregroundStyle(gold)
            Spacer(minLength:0)
        }
        .accessibilityIdentifier("w3-original-postprocess-glow-256")
    }

    // Source Windows/src/Menu139.cs OptionGroups139 STATEK, IDs 100 and 101.
    // 17 choices from 70% through 150%, increments 5%, default 100%.
    private var shipSizePage:some View {
        VStack(alignment:.leading,spacing:compact ? 10:18) {
            header("ORYGINALNA SKALA WIZUALNA STATKU / v472")
            VStack(alignment:.leading,spacing:5) {
                HStack {
                    Text("STATEK / SKALA W MISJACH")
                    Spacer()
                    Text("\(shipScale472.missionPercent)%")
                        .foregroundStyle(gold)
                        .accessibilityIdentifier("w3-ship-mission-scale-value-472")
                }
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                Slider(value:Binding(
                    get:{Double(shipScale472.missionPercent)},
                    set:{value in saveShipScale{$0.setMission(Int(value.rounded()))}}),
                    in:70...150,step:5)
                    .tint(cyan)
                    .accessibilityIdentifier("w3-ship-mission-scale-slider-472")
            }
            VStack(alignment:.leading,spacing:5) {
                HStack {
                    Text("STATEK / SKALA W ŚWIECIE ORBITALNYM")
                    Spacer()
                    Text("\(shipScale472.orbitPercent)%")
                        .foregroundStyle(gold)
                        .accessibilityIdentifier("w3-ship-orbit-scale-value-472")
                }
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(.white)
                Slider(value:Binding(
                    get:{Double(shipScale472.orbitPercent)},
                    set:{value in saveShipScale{$0.setOrbit(Int(value.rounded()))}}),
                    in:70...150,step:5)
                    .tint(cyan)
                    .accessibilityIdentifier("w3-ship-orbit-scale-slider-472")
            }
            Text("ZAKRES ORYGINAŁU: 70–150%, KROK 5%, DOMYŚLNIE 100%. ZMIANA DOTYCZY WYŁĄCZNIE WIDOCZNEJ GEOMETRII I DYSZ; NIE ZMIENIA KOLIZJI, PRĘDKOŚCI ANI OBRAŻEŃ.")
                .font(.system(size:compact ? 10:12,design:.monospaced))
                .foregroundStyle(muted)
            Text("ŹRÓDŁO: Menu139.cs #100/#101; Renderer.cs; GpuSphere67.CraftSphere67; Orbit50.cs:318.")
                .font(.system(size:9,design:.monospaced))
                .foregroundStyle(gold)
            Spacer(minLength:0)
        }
        .accessibilityIdentifier("w3-source-ship-scale-settings-472")
    }

}