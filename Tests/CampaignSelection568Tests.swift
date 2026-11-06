import Foundation

/// Stage B regression — actual 26-sector UI state, unlocked selection,
/// persistence and original PC Orbit50 campaign locks. No fake mission starts.
@main
struct CampaignSelection568Tests {
    static func main() {
        precondition(MissionCatalog568.planetNames.count == 26)
        precondition(MissionCatalog568.title(for:1) == "CARBONIS / PBR")
        precondition(MissionCatalog568.title(for:5) == "BOREAS / LODOWCE")
        precondition(MissionCatalog568.title(for:25) == "AMIGA / BOING BALL")
        precondition(MissionCatalog568.title(for:26) == "VULKARIS / OBCY ŚWIAT")
        precondition(MissionCatalog568.title(for:0) == nil)
        precondition(MissionCatalog568.title(for:27) == nil)

        let identifier="AsteroidySelection568-\(UUID().uuidString)"
        guard let defaults=UserDefaults(suiteName:identifier) else {
            fatalError("Missing isolated UserDefaults suite")
        }
        defer { defaults.removePersistentDomain(forName:identifier) }

        var campaign=CampaignStore556.load(defaults:defaults)
        precondition(campaign.selectedSector == 1)
        precondition(campaign.completedMask == 0)
        precondition(campaign.unlocked(1) && !campaign.unlocked(2))
        precondition(!campaign.selectUnlocked(0))
        precondition(!campaign.selectUnlocked(2))
        precondition(!campaign.selectUnlocked(26))
        precondition(campaign.selectedSector == 1)
        precondition(campaign.selectUnlocked(1))
        CampaignStore556.save(campaign,defaults:defaults)
        precondition(CampaignStore556.load(defaults:defaults).selectedSector == 1)
        precondition(CampaignStore556.load(defaults:defaults).completedMask == 0)

        // Only the already-existing verified mission-complete mechanism can
        // unlock the next original PC target. Tap cannot award completion.
        precondition(campaign.finishMission(1))
        precondition(campaign.unlocked(2))
        let savedBefore = campaign.completedMask
        precondition(campaign.selectUnlocked(2))
        precondition(campaign.selectedSector == 2)
        precondition(campaign.completedMask == savedBefore)
        CampaignStore556.save(campaign,defaults:defaults)
        let restored=CampaignStore556.load(defaults:defaults)
        precondition(restored.selectedSector == 2)
        precondition(restored.completedMask == savedBefore)
        precondition(!restored.completed(2))
        precondition(!restored.unlocked(3))

        // Stale UI selection must never bypass current source unlocks.
        defaults.set(0,forKey:"asteroidy.ios.v556.campaign.completedMask")
        let reset=CampaignStore556.load(defaults:defaults)
        precondition(reset.selectedSector == 1)
        precondition(reset.completedMask == 0)

        // Source Orbit50 special case: mission 26 becomes unlocked after 24.
        var original26=CampaignProgress556()
        for sector in 1...24 { precondition(original26.finishMission(sector)) }
        precondition(original26.selectUnlocked(26))
        precondition(original26.completedCount == 24)
        precondition(!original26.completed(26))
        CampaignStore556.save(original26,defaults:defaults)
        precondition(CampaignStore556.load(defaults:defaults).selectedSector == 26)
        print("PASS: real 26-sector names, source-only unlock selection, UserDefaults restore, no completion mutation, special 26-from-24")
    }
}
