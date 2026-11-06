import Foundation

/// Source Orbit50.CompleteMission50 (first level only) and iOS CampaignStore556.
/// Commit is idempotent: repeated UI events never grant a second clear bonus.
/// This is not called on defeat, pause, scene inspection or a mere HUD update.
enum Sector01MissionSettlement568 {
    private static let tokenKey="asteroidy.ios.v568.shop.tokens"
    private static let earnedKey="asteroidy.ios.v568.shop.totalEarned"

    static func wallet(defaults:UserDefaults = .standard)->Int {
        max(0,defaults.integer(forKey:tokenKey))
    }

    @discardableResult
    static func commit(_ summary:Sector01MissionSummary568,
                       campaign:inout CampaignProgress556,
                       defaults:UserDefaults = .standard)->Bool {
        guard summary.sector==1, campaign.unlocked(1) else {return false}
        let newlyCompleted=campaign.finishMission(1)
        if newlyCompleted && !summary.isReplay {
            // Windows Game.FinishLevel: after collecting remaining tokens
            // and ClearBonus, persist the shop wallet.
            let existing=wallet(defaults:defaults)
            let reward=max(0,summary.earnedTokens)
            defaults.set(existing>Int.max-reward ? Int.max : existing+reward,
                         forKey:tokenKey)
            let earned=max(0,defaults.integer(forKey:earnedKey))
            defaults.set(earned>Int.max-reward ? Int.max : earned+reward,
                         forKey:earnedKey)
        }
        CampaignStore556.save(campaign,defaults:defaults)
        return newlyCompleted
    }
}
