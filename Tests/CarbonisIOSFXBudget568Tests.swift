import Foundation

@main struct CarbonisIOSFXBudget568Tests {
    static func main() {
        func check(_ ok:Bool,_ message:String){precondition(ok,message)}
        let suite="ASTEROIDY-IOS-FX-AUDIT-\(ProcessInfo.processInfo.processIdentifier)"
        let prefs=UserDefaults(suiteName:suite)!
        defer {prefs.removePersistentDomain(forName:suite)}
        let type=CarbonisIOSFXBudget568.self
        for key in [type.key,type.explosionKey,type.projectileKey] {
            prefs.removeObject(forKey:key)
        }
        let low=type.load(prefs)
        check(low.explosionsReduced && low.projectilesReduced,
              "both visual modes are reduced on a new install")
        check(low.volumeCount(3)==1 && low.volumeCount(4)==2 &&
              low.volumeCount(6)==2,"source quality choice matters in light mode")
        check(low.raySamples(22)==10 && low.raySamples(32)==15 &&
              low.raySamples(48)==22,"22/32/48 source step presets retain an effect")
        check(low.gasLobes(5)==3 && low.gasLobes(13)==7 &&
              low.gasLobes(17)==9,"original lobe slider is not stuck at seven")
        check(abs(low.explosionDuration(4.2)-1.89)<0.001 &&
              abs(low.explosionDuration(4.8)-2.16)<0.001,
              "original blast lifetime slider is never ignored")
        check(low.shardLimit(0)==0 && low.shardLimit(35)==12 &&
              low.shardLimit(70)==25,"original 3D shard slider stays functional")
        check(low.groundLightLayers==[2] && low.groundSlices(22)==12 &&
              !low.drawBulletGlow,"only one reduced projectile light")
        check(low.particleLimit(512)==96 && low.pieceLimit(160)==48,
              "render-only caps do not mutate simulation")
        let original=type.original
        check(!original.reduced && original.volumeCount(3)==3 &&
              original.raySamples(48)==48 && original.gasLobes(17)==17 &&
              original.explosionDuration(4.2)==4.2 &&
              original.shardLimit(35)==35 &&
              original.groundLightLayers==[0,1,2,3] &&
              original.groundSlices(28)==28 &&
              original.drawBulletGlow &&
              original.particleLimit(512)==512 &&
              original.pieceLimit(160)==160,
              "full original PC visuals restored when each mode is off")
        prefs.set(false,forKey:type.key)
        check(!type.load(prefs).explosionsReduced &&
              !type.load(prefs).projectilesReduced,
              "migrate old combined OFF preference")
        prefs.set(true,forKey:type.key)
        var independent=type.load(prefs)
        independent.explosionsReduced=false
        independent.projectilesReduced=true
        independent.save(prefs)
        let restored=type.load(prefs)
        check(!restored.explosionsReduced && restored.projectilesReduced,
              "independent explosion / projectile settings survive relaunch")
        check(restored.volumeCount(3)==3 && restored.raySamples(22)==22 &&
              restored.groundLightLayers==[2],
              "disable explosion budget WITHOUT changing projectile budget")
        independent.explosionsReduced=true
        independent.projectilesReduced=false
        independent.save(prefs)
        let reverse=type.load(prefs)
        check(reverse.volumeCount(3)==1 &&
              reverse.groundLightLayers==[0,1,2,3] &&
              reverse.drawBulletGlow,
              "disable projectile budget WITHOUT changing explosions")
        print("PASS iOS FX budgets separated, legacy UserDefaults migrated, source sliders effective, source original mode intact")
    }
}
