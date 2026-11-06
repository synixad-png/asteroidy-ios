import Foundation

@main struct Sector01PreparedWave568Tests {
    static func main() {
        var checks=0
        func verify(_ value:Bool,_ message:String) {
            precondition(value,message);checks += 1
        }
        var campaign=CampaignProgress556()
        let before=campaign.completedMask
        guard let entry=Sector01Entry568.open(
            selectedSector:1,campaign:campaign,hasOriginalC279Assets:true)
        else {fatalError("source entry rejected")}
        guard let prepared=Sector01PreparedWave568.prepare(
            entry:entry,campaign:campaign,hasOriginalC279Assets:true,
            difficulty:.normal,seed:1) else {fatalError("source bridge rejected")}
        verify(prepared.reset.level==1 && prepared.reset.hubMission,"start state")
        verify(prepared.encounter.sector==1 && prepared.encounter.rocks.count==13,"real rocks")
        verify(prepared.encounter.fighters.count==4,"real shooter count")
        verify(prepared.encounter.robots.count==0,"real robot count")
        verify(prepared.encounter.initialReinforcements==0,"source quota")
        verify(!prepared.isPlayable && !prepared.encounter.playable,"no fake combat")
        verify(campaign.completedMask==before,"never complete mission")
        verify(Sector01PreparedWave568.prepare(entry:entry,campaign:campaign,
            hasOriginalC279Assets:false,difficulty:.normal,seed:1)==nil,
            "reject missing C279 source")
        verify(campaign.selectUnlocked(2)==false,"locked second sector")
        verify(campaign.finishMission(1),"test unlock only")
        verify(campaign.selectUnlocked(2),"second sector selection")
        verify(Sector01PreparedWave568.prepare(entry:entry,campaign:campaign,
            hasOriginalC279Assets:true,difficulty:.normal,seed:1)==nil,
            "selection mismatch does not start Carbonis")
        print("PASS \(checks) CARBONIS mission-entry bridge tests")
    }
}
