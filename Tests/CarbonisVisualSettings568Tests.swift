import Foundation

@main struct CarbonisVisualSettings568Tests {
    static func main() {
        var count=0
        func check(_ condition:Bool,_ message:String) {
            precondition(condition,message)
            count+=1
        }
        let namespace="C279.VisualSettings568.Tests.\(UUID().uuidString)"
        let prefs=UserDefaults(suiteName:namespace)!
        defer { prefs.removePersistentDomain(forName:namespace) }
        let initial=CarbonisVisualSettings568()
        check(initial.type==0 && initial.quality==0 &&
              initial.values==[100,13,135,100,130,125,50,260] &&
              initial.autoRotate,
              "original Explosion524 default fuel GAMEPLAY values and auto rotate")
        check(initial.projectileBrightness==220 &&
              initial.projectileColor==0 &&
              initial.projectileMixed,
              "original Renderer.cs projectile settings default 220%, automatic and mixed")
        check(initial.raySamples==22 &&
              initial.simultaneousVolumes==3 &&
              initial.shardCount==35 &&
              abs(initial.explosionDuration-4.2)<0.0001,
              "original GAMEPLAY 22 depth samples, budget3, 35 metal shards, 4.2 seconds")
        var config=initial
        config.selectPreset(1)
        check(config.type==1 &&
              config.values==[92,11,80,165,145,155,90,270],
              "original ASTEROIDA preset sets eight source values")
        config.selectPreset(2)
        check(config.type==2 &&
              config.values==[130,15,160,110,175,150,75,350],
              "original REAKTOR preset sets eight source values")
        config.selectPreset(0)
        check(config.type==0 && config.values==initial.values,
              "switch back to PALIWO restores source lab preset")
        config.quality=1
        check(config.raySamples==32 && config.simultaneousVolumes==4,
              "original BALANCED 32 steps / four volumes")
        config.quality=2
        check(config.raySamples==48 && config.simultaneousVolumes==6,
              "original SHOWCASE 48 steps / six volumes")
        config.setValue(1,17)
        check(config.value(1)==17,"original 5-17 gas lobe source range")
        config.setValue(7,450)
        check(config.value(7)==450 &&
              abs(config.explosionDuration-4.8)<0.0001,
              "original 1.50-4.50 seconds with V8.2 global 4.8s cap")
        config.setValue(6,100)
        check(config.shardCount==70,"original shards slider 100 produces 70 3D pieces")
        config.setValue(4,14)
        check(config.value(4)==15,"source irregularity quantum 5 and min10")
        config.setValue(0,999)
        check(config.value(0)==170,"source max 3D scale 170%")
        config.setValue(3,-1)
        check(config.value(3)==0,"source soot minimum 0%")
        config.projectileBrightness=385
        config.projectileColor=6
        config.projectileMixed=false
        config.autoRotate=false
        config.save(prefs)
        let restored=CarbonisVisualSettings568.load(prefs)
        check(restored==config,"original explosion/shot options persist across relaunch")
        check(restored.projectileBrightness==385 &&
              restored.projectileColor==6 &&
              !restored.projectileMixed,
              "projectile light brightness, color and mixing all saved")
        var invalid=restored
        invalid.type=12
        invalid.quality=99
        invalid.values=[-123,10000]
        invalid.projectileBrightness=8999
        invalid.projectileColor=98
        invalid.save(prefs)
        let safe=CarbonisVisualSettings568.load(prefs)
        check(safe.type==2 && safe.quality==2 &&
              safe.values==CarbonisVisualSettings568.presets[2] &&
              safe.projectileBrightness==400 &&
              safe.projectileColor==7,
              "malformed persisted values clamp to exact source ranges")
        check(CarbonisVisualSettings568.minimum.count==8 &&
              CarbonisVisualSettings568.maximum.count==8 &&
              CarbonisVisualSettings568.increments.count==8,
              "all eight source explosion controls have bounds and steps")
        check(CarbonisVisualSettings568.shotColorNames.count==8 &&
              CarbonisVisualSettings568.typeNames.count==3 &&
              CarbonisVisualSettings568.qualityNames.count==3,
              "original shot tint choices and V8.2 presets have exact cardinality")
        print("PASS \(count) original Explosion524 + ProjectileLight285 v568 persistent W3 settings source fidelity assertions")
    }
}