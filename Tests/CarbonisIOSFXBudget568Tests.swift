import Foundation

@main struct CarbonisIOSFXBudget568Tests {
    static func main() {
        func check(_ ok:Bool,_ message:String){precondition(ok,message)}
        let suite="ASTEROIDY-IOS-FX-TEST-\(ProcessInfo.processInfo.processIdentifier)"
        let defaults=UserDefaults(suiteName:suite)!
        defaults.removeObject(forKey:CarbonisIOSFXBudget568.key)
        let low=CarbonisIOSFXBudget568.load(defaults)
        check(low.reduced,"default ON even for older installs")
        check(low.volumeCount(3)==1,"one 3D explosion")
        check(low.raySamples(22)==10,"10 volume steps")
        check(low.gasLobes(13)==7,"7 gas lobes")
        check(low.explosionDuration(4.2)==1.9,"shorter blast lifetime")
        check(low.groundLightLayers==[2],"only one of four lights")
        check(low.groundSlices(22)==12,"12-slice light circle")
        check(!low.drawBulletGlow,"no outer bullet halo")
        check(low.particleLimit(512)==96,"visual-only particle cap")
        check(low.pieceLimit(160)==48,"visual-only debris cap")
        check(low.shardLimit(35)==12,"visual-only shard cap")
        check(low.volumeCount(0)==0,"never synthesize blast")
        let original=CarbonisIOSFXBudget568.original
        check(!original.reduced &&
              original.volumeCount(3)==3 &&
              original.raySamples(22)==22 &&
              original.gasLobes(13)==13 &&
              original.explosionDuration(4.2)==4.2 &&
              original.groundLightLayers==[0,1,2,3] &&
              original.groundSlices(22)==22 &&
              original.drawBulletGlow &&
              original.particleLimit(512)==512 &&
              original.pieceLimit(160)==160 &&
              original.shardLimit(35)==35,
              "full original quality must be restorable 1:1")
        original.save(defaults)
        check(!CarbonisIOSFXBudget568.load(defaults).reduced,
              "persist original full visual mode")
        low.save(defaults)
        check(CarbonisIOSFXBudget568.load(defaults).reduced,
              "persist iOS reduced FX mode")
        defaults.removePersistentDomain(forName:suite)
        print("PASS iOS default-on cosmetic reduction, exact original quality restore, persistent toggle")
        print("Analytical max per overlapping volumes: 3*22*13=858 vs 1*10*7=70 (~91.8% fewer ray-lobe evaluations), NOT measured FPS")
    }
}
