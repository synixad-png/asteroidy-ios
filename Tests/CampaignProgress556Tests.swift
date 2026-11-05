import Foundation

@main struct CampaignProgress556Tests {
    static func main() {
        var p = CampaignProgress556()
        precondition(p.completedCount == 0 && p.unlocked(1) && !p.unlocked(2))
        precondition(!p.unlocked(26) && !p.finishMission(26))
        precondition(p.finishMission(1) && !p.finishMission(1))
        precondition(p.unlocked(2) && !p.unlocked(3))
        precondition(p.nextAvailableSector == 2)
        precondition(p.select(26) && !p.unlocked(26) && p.selectedSector == 26)
        precondition(!p.select(0) && !p.select(27) && p.selectedSector == 26)
        precondition(!p.completed(0) && !p.unlocked(27))
        var progressTo24 = CampaignProgress556()
        for i in 1...24 { precondition(progressTo24.finishMission(i)) }
        precondition(progressTo24.unlocked(25) && progressTo24.unlocked(26))
        precondition(progressTo24.finishMission(26))
        precondition(progressTo24.completedCount == 25)
        precondition(progressTo24.nextAvailableSector == 25)
        precondition(CampaignProgress556.readLegacyProgress("67108864\n")?.completed(1) == true)
        precondition(CampaignProgress556.readLegacyProgress("-1") == nil)
        precondition(CampaignProgress556.readLegacyProgress("abc") == nil)
        precondition(CampaignProgress556(mask:-1).completedCount == 26)
        let suite = "AsteroidyCampaignV19-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName:suite) else { fatalError("Missing test defaults") }
        defer { defaults.removePersistentDomain(forName:suite) }
        CampaignStore556.save(progressTo24, defaults:defaults)
        let restored = CampaignStore556.load(defaults:defaults)
        precondition(restored.completedMask == progressTo24.completedMask)
        precondition(restored.completedCount == 25)
        print("PASS: 26 sectors, unlock rules incl sector 26 from 24, progress bitmask, legacy migration, isolated persistence")
    }
}