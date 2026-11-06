import Foundation

/// Source Orbit50.CompleteMission50 (first level only) and iOS CampaignStore556.
/// Commit is idempotent: repeated UI events never grant a second clear bonus.
/// This is not called on defeat, pause, scene inspection or a mere HUD update.
enum Sector01MissionSettlement568 {
    static func wallet(defaults:UserDefaults = .standard)->Int {
        Sector01Shop568.load(defaults:defaults).tokens
    }

    @discardableResult
    static func commit(_ summary:Sector01MissionSummary568,
                       campaign:inout CampaignProgress556,
                       defaults:UserDefaults = .standard)->Bool {
        guard summary.sector==1, campaign.unlocked(1) else {return false}
        let newlyCompleted=campaign.finishMission(1)
        if newlyCompleted && !summary.isReplay {
            // CompleteMission50 runs before SaveShopProfile56; duplicate
            // finish notifications NEVER grant tokens twice.
            var profile=Sector01Shop568.load(defaults:defaults)
            profile.award(summary.earnedTokens)
            Sector01Shop568.save(profile,defaults:defaults)
        }
        CampaignStore556.save(campaign,defaults:defaults)
        return newlyCompleted
    }
}
