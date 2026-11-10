import Foundation

@main enum SourcePickupVisual586Tests {
    static func main() {
        let suiteName="pc586-original-item-visual-\(UUID().uuidString)"
        guard let defaults=UserDefaults(suiteName:suiteName) else {
            fatalError("Could not isolate test UserDefaults suite")
        }
        defer{defaults.removePersistentDomain(forName:suiteName)}
        var config=SourcePickupVisual586.load(defaults)
        precondition(config.brightnessPercent==180)
        precondition(config.shieldPercent==60)
        precondition(config.boostPercent==78)
        precondition(config.energyPercent==78)
        precondition(config.bombPercent==78)
        precondition(config.moneyPercent==78)
        precondition(abs(config.addedFill-1.17)<0.0001)
        precondition(abs(config.visualFactor(.shield)-0.60)<0.0001)
        precondition(abs(config.visualFactor(.energy)-0.78)<0.0001)
        precondition(abs(config.moneyFactor-0.78)<0.0001)
        config.brightnessPercent=500
        config.shieldPercent=5
        config.boostPercent=175
        config.energyPercent=71
        config.bombPercent=41
        config.moneyPercent = -2
        config.save(defaults)
        let restored=SourcePickupVisual586.load(defaults)
        precondition(restored.brightnessPercent==400)
        precondition(restored.shieldPercent==30)
        precondition(restored.boostPercent==150)
        precondition(restored.energyPercent==71)
        precondition(restored.bombPercent==41)
        precondition(restored.moneyPercent==40)
        precondition(abs(restored.addedFill-2.6)<0.0001)
        // Values outside bounds or corrupted settings must fall back
        // deterministically; no silent change to existing collision sizes.
        defaults.set(Data("bad-json".utf8),forKey:SourcePickupVisual586.key)
        precondition(SourcePickupVisual586.load(defaults).brightnessPercent==180)
        print("PASS: original PC586 brightness and independent pickup scale defaults, clamps and persistence")
    }
}
