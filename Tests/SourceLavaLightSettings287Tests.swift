import Foundation

@main struct SourceLavaLightSettings287Tests {
    static func main() {
        var checks=0
        func check(_ v:Bool,_ what:String){precondition(v,what);checks+=1}
        let original=SourceLavaLightSettings287()
        check(original.brightnessPercent==180,"Original Renderer.cs default LavaLightBrightness287=180")
        check(abs(original.intensity-1.8)<0.000001,"C# engine factor 180%=1.8f")
        check(SourceLavaLightSettings287.normalized(-100)==0,"0% minimum")
        check(SourceLavaLightSettings287.normalized(10000)==400,"400% maximum")
        check(SourceLavaLightSettings287.normalized(177)==175,"5% quantization low")
        check(SourceLavaLightSettings287.normalized(178)==180,"5% quantization high")
        let ns="ast.io.lava287.tests.\(UUID().uuidString)"
        let d=UserDefaults(suiteName:ns)!
        defer {d.removePersistentDomain(forName:ns)}
        var modified=original;modified.setBrightness(325);modified.save(d)
        check(SourceLavaLightSettings287.load(d)==modified,"independent stored setting")
        check(abs(SourceLavaLightSettings287.load(d).intensity-3.25)<1e-6,
              "GPU receives original 325/100")
        modified.setBrightness(-10);modified.save(d)
        check(SourceLavaLightSettings287.load(d).intensity==0,"complete disable works")
        print("PASS \(checks) source v568 lava emission / settings 287")
    }
}
