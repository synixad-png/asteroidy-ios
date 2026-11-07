import Foundation

@main struct SourceNewGame568Tests {
    static func main() throws {
        var checks=0
        func check(_ condition:Bool,_ label:String) {
            precondition(condition,label);checks+=1
        }
        let id="asteroidy-newgame568-\(UUID().uuidString)"
        let defaults=UserDefaults(suiteName:id)!
        defer {defaults.removePersistentDomain(forName:id)}
        let backup=FileManager.default.temporaryDirectory
            .appendingPathComponent("w3-profile358-\(UUID().uuidString)")
        defer {try? FileManager.default.removeItem(at:backup)}
        let normal=SourceNewGame568.selection(defaults:defaults)
        check(normal.players==1 && normal.difficulty == .normal,
              "source normal difficulty and 1 player defaults")
        check(!SourceNewGame568.hasActiveProfile(defaults:defaults),
              "initial profile absent")
        check(SourceNewGame568.startingLives(difficulty:.easy)==5 &&
              SourceNewGame568.startingLives(difficulty:.normal)==3 &&
              SourceNewGame568.startingLives(difficulty:.hard)==3,
              "original Vanguard starting lives")
        check(SourceNewGame568.startingLives(difficulty:.easy,shipType:0)==4 &&
              SourceNewGame568.startingLives(difficulty:.normal,shipType:2)==4,
              "source Kestrel and Bastion modifiers")
        let blocked=SourceNewGameSelection568(players:2,difficulty:.hard)
        check(!SourceNewGame568.create(blocked,defaults:defaults,
                  backupDirectory:backup),
              "2 player launch impossible until second ship implemented")
        check(!SourceNewGame568.hasActiveProfile(defaults:defaults),
              "disabled co-op cannot write fake profile")
        defaults.set(173,forKey:"asteroidy.ios.graphics.test.persistent")
        check(SourceNewGame568.create(.init(players:1,difficulty:.easy),
              defaults:defaults,backupDirectory:backup),
              "first easy Vanguard campaign persists")
        check(SourceNewGame568.hasActiveProfile(defaults:defaults),
              "first active auto profile now exists")
        check(SourceNewGame568.selection(defaults:defaults).difficulty == .easy,
              "easy persists across app restart")
        check(Sector01Shop568.load(defaults:defaults).lives==5,
              "easy Vanguard has 5 lives")
        var old=CampaignStore556.load(defaults:defaults)
        check(old.finishMission(1),"old first-sector clear")
        CampaignStore556.save(old,defaults:defaults)
        var oldShop=Sector01Shop568.load(defaults:defaults)
        oldShop.award(379)
        Sector01Shop568.save(oldShop,defaults:defaults)
        let originalShop=defaults.data(forKey:
            "asteroidy.ios.v568.shop-profile-first-sector")!
        let oldMask=defaults.integer(forKey:
            "asteroidy.ios.v556.campaign.completedMask")
        check(oldMask==1 && oldShop.tokens==379,
              "old campaign and wallet ready for backup")
        check(SourceNewGame568.create(.init(players:1,difficulty:.hard),
              defaults:defaults,backupDirectory:backup),
              "explicit fresh hard game archives old profile")
        check(CampaignStore556.load(defaults:defaults).completedCount==0 &&
              !CampaignStore556.load(defaults:defaults).unlocked(2),
              "new game resets actual progress and relocks sector 2")
        check(Sector01Shop568.load(defaults:defaults).tokens==0 &&
              Sector01Shop568.load(defaults:defaults).lives==3,
              "new game resets wallet, items, lives")
        check(SourceNewGame568.selection(defaults:defaults).difficulty == .hard,
              "hard difficulty persisted")
        check(defaults.integer(forKey:"asteroidy.ios.graphics.test.persistent")==173,
              "graphics settings preserved")
        let names=try FileManager.default.contentsOfDirectory(at:backup,
            includingPropertiesForKeys:nil)
        check(names.count==1,"one existing profile archived")
        let bytes=try Data(contentsOf:names[0])
        let payload=try PropertyListSerialization.propertyList(from:bytes,
            format:nil) as! [String:Any]
        let archived=payload["profile"] as! [String:Any]
        check(archived["asteroidy.ios.v556.campaign.completedMask"] as? Int == 1,
              "campaign bit mask exactly backed up")
        check(archived["asteroidy.ios.v568.shop-profile-first-sector"] as? Data ==
              originalShop,"wallet/inventory backed up byte-for-byte")
        let failingURL=FileManager.default.temporaryDirectory
            .appendingPathComponent("backup-blocker-\(UUID().uuidString)")
        try Data("blocker".utf8).write(to:failingURL)
        defer {try? FileManager.default.removeItem(at:failingURL)}
        check(!SourceNewGame568.create(.init(players:1,difficulty:.easy),
              defaults:defaults,backupDirectory:failingURL),
              "failed backup rejects destructive new game")
        check(SourceNewGame568.selection(defaults:defaults).difficulty == .hard &&
              CampaignStore556.load(defaults:defaults).completedCount==0,
              "failed backup leaves active state unchanged")
        print("PASS \(checks) source W3 new game / difficulty / profile358 assertions")
    }
}
