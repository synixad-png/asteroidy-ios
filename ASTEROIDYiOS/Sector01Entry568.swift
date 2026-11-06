import Foundation

/// Stage C entry contract, deliberately distinct from PC Game.StartHubMission261.
///
/// Windows/src/Orbit50.cs starts a complete combat mission only after
/// MissionUnlocked50 and a valid orbit entry. The iOS port currently has the
/// exact CARBONIS (C279) GLB-derived globe but not the complete mission mode,
/// source mission Wave(), boss rules, or full terrain collision. Do not use
/// the unrelated Boreas/9-asteroid diagnostic in its place.
///
/// This gate allows a real transition from the 26-sector source atlas to the
/// original sector-01 planet rendering only. It NEVER changes completion bits.
struct Sector01Entry568: Equatable {
    enum Stage: Equatable {
        case sourcePlanetInspection
    }
    let sector: Int
    let name: String
    let stage: Stage

    static func open(selectedSector: Int,
                     campaign: CampaignProgress556,
                     hasOriginalC279Assets: Bool) -> Self? {
        guard selectedSector == 1,
              campaign.selectedSector == selectedSector,
              campaign.unlocked(selectedSector),
              hasOriginalC279Assets,
              let name = MissionCatalog568.title(for: selectedSector)
        else { return nil }
        return Self(sector: selectedSector,
                    name: name,
                    stage: .sourcePlanetInspection)
    }

    /// Must remain false until source StartHubMission261/Wave(), full scene,
    /// controls, HUD, terrain collisions and completion logic are integrated.
    var sourceCombatMissionIsPlayable: Bool { false }
}
