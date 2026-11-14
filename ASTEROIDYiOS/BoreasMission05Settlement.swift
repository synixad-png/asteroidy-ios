import Foundation

/// Mission-05 settlement occurs only after a real source Game.FinishLevel
/// report; neither atlas inspection nor the isolated W3 model test calls it.
enum BoreasMission05Settlement {
    @discardableResult
    static func commit(_ report:Sector01MissionSummary568,
                       campaign:inout CampaignProgress556,
                       defaults:UserDefaults = .standard)->Bool {
        guard report.sector==BoreasMission05Source.sector,
              report.elapsedSeconds>=50,
              campaign.selectedSector==report.sector,
              campaign.unlocked(report.sector) else{return false}
        let firstClear=campaign.finishMission(report.sector)
        if firstClear && !report.isReplay {
            var profile=Sector01Shop568.load(defaults:defaults)
            profile.award(report.earnedTokens)
            Sector01Shop568.save(profile,defaults:defaults)
        }
        CampaignStore556.save(campaign,defaults:defaults)
        return firstClear
    }
}
