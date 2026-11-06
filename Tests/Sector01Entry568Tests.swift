import Foundation

/// Source-backed stage-C state test: selecting the original CARBONIS globe
/// is an actual navigation transition, NOT Game.StartHubMission261.
@main struct Sector01Entry568Tests {
    static func main() {
        precondition(MissionCatalog568.planetNames.count == 26)
        let name=MissionCatalog568.title(for:1)
        precondition(name == "CARBONIS / PBR")
        var campaign=CampaignProgress556()
        let completedBefore=campaign.completedMask
        let selectedBefore=campaign.selectedSector

        precondition(Sector01Entry568.open(
            selectedSector:1,campaign:campaign,
            hasOriginalC279Assets:false) == nil)
        let inspection=Sector01Entry568.open(
            selectedSector:1,campaign:campaign,
            hasOriginalC279Assets:true)
        precondition(inspection?.sector == 1)
        precondition(inspection?.name == name)
        precondition(inspection?.stage == .sourcePlanetInspection)
        precondition(inspection?.sourceCombatMissionIsPlayable == false)
        precondition(campaign.completedMask == completedBefore)
        precondition(campaign.selectedSector == selectedBefore)

        // Do not allow opening a locked sector or accidentally routing
        // any other mission through the original C279 (Carbonis) renderer.
        for level in 2...26 {
            precondition(Sector01Entry568.open(
                selectedSector:level,campaign:campaign,
                hasOriginalC279Assets:true) == nil)
        }
        precondition(campaign.finishMission(1))
        precondition(campaign.unlocked(2))
        precondition(campaign.selectUnlocked(2))
        precondition(Sector01Entry568.open(
            selectedSector:1,campaign:campaign,
            hasOriginalC279Assets:true) == nil)
        precondition(Sector01Entry568.open(
            selectedSector:2,campaign:campaign,
            hasOriginalC279Assets:true) == nil)

        print("PASS: original CARBONIS 01 gate, source asset requirement, no locked/mismatched sectors")
        print("PASS: original campaign selected state and completedMask remain unchanged by inspection")
        print("LIMIT: original Windows v568 StartHubMission261, Wave and live combat are not yet ported")
    }
}
