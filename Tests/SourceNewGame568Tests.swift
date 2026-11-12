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
        check(!SourceNewGame568.canContinueActive358(defaults:defaults),
              "missing active campaign cannot be resumed")
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
        // PC602 ContinueActive358: a freshly started campaign is resumable,
        // even though original H55 default records are stored implicitly.
        let vitalsRecord="asteroidy.ios.h11.pc580.c279.vitals"
        let mechanicsRecord="asteroidy.ios.pc580.h11.source-mechanics"
        check(defaults.object(forKey:vitalsRecord)==nil &&
              defaults.object(forKey:mechanicsRecord)==nil &&
              SourceNewGame568.canContinueActive358(defaults:defaults),
              "fresh source campaign resumes with implicit H55 defaults")
        defaults.set(Data([0xFF,0x00]),forKey:vitalsRecord)
        check(!SourceNewGame568.canContinueActive358(defaults:defaults),
              "corrupt explicit H55 vitals must not be silently defaulted")
        defaults.removeObject(forKey:vitalsRecord)
        defaults.set("INVALID",forKey:mechanicsRecord)
        check(!SourceNewGame568.canContinueActive358(defaults:defaults),
              "wrong type for explicit H55 mechanics must block continuation")
        defaults.removeObject(forKey:mechanicsRecord)
        check(SourceNewGame568.canContinueActive358(defaults:defaults),
              "valid fresh campaign continues after invalid records removed")
        var old=CampaignStore556.load(defaults:defaults)
        check(old.finishMission(1),"old first-sector clear")
        CampaignStore556.save(old,defaults:defaults)
        var oldShop=Sector01Shop568.load(defaults:defaults)
        oldShop.award(379)
        // The H11 state MUST be included before deleting a previous
        // campaign. Source PC580 ArchiveActiveProfile358 copies the entire
        // active profile, not only the shop wallet.
        oldShop.ionAmmo=137
        oldShop.bombs=2
        Sector01Shop568.save(oldShop,defaults:defaults)
        var oldVitals=H55Workshop580.Vitals()
        oldVitals.hullRank=1
        oldVitals.hull=68
        oldVitals.armor=16
        check(H55Workshop580.saveVitals(oldVitals,defaults:defaults),
              "source H11 real hull/armor recorded before new campaign")
        var oldH11=H55SourceMechanics580.State()
        oldH11.vanguardXOwned=true
        oldH11.selectedShip=3
        oldH11.guardianOwned=true
        oldH11.guardianStrike=1
        oldH11.cooling=2
        oldH11.collector=1
        oldH11.bossTrophies=1 << 3
        oldH11.timeTrophies=1
        check(H55SourceMechanics580.save(oldH11,defaults:defaults),
              "source H11 owned ships/modules/talents/trophies valid")
        check(!SourceNewGame568.canContinueActive358(defaults:defaults),
              "unsupported ship in genuine H55 profile is not an iOS Vanguard")
        let originalVitals=defaults.data(forKey:
            "asteroidy.ios.h11.pc580.c279.vitals")!
        let originalH11=defaults.data(forKey:
            "asteroidy.ios.pc580.h11.source-mechanics")!
        let originalShop=defaults.data(forKey:
            "asteroidy.ios.v568.shop-profile-first-sector")!
        // The original PC v608 on-disk reserve lives in the OLD shop
        // fields; active-bar energy is a separate optional iOS checkpoint.
        // Archive/restore must preserve both with no HUD/profile rewrite.
        check(SourceTarcza145.savePersistentEnergy(37.5,defaults:defaults),
              "v608 active shield bar stored before campaign archive")
        let previousShieldEnergy=SourceTarcza145.loadPersistentEnergy(defaults:defaults)
        check(previousShieldEnergy==37.5,"active bar checkpoint 37.5")
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
              Sector01Shop568.load(defaults:defaults).lives==3 &&
              Sector01Shop568.load(defaults:defaults).ionAmmo==0 &&
              Sector01Shop568.load(defaults:defaults).bombs==0,
              "new game resets wallet, items, consumables, lives")
        check(H55Workshop580.loadVitals(defaults:defaults)==H55Workshop580.Vitals() &&
              H55SourceMechanics580.load(defaults:defaults)==H55SourceMechanics580.State(),
              "direct create atomically resets both H11 records after backup")
        check(SourceTarcza145.loadPersistentEnergy(defaults:defaults)==60 &&
              defaults.object(forKey:SourceTarcza145.persistentKey)==nil,
              "fresh campaign clears shield energy checkpoint to PC default 60")
        check(SourceNewGame568.selection(defaults:defaults).difficulty == .hard,
              "hard difficulty persisted")
        check(defaults.integer(forKey:"asteroidy.ios.graphics.test.persistent")==173,
              "graphics settings preserved")
        let names=try FileManager.default.contentsOfDirectory(at:backup,
            includingPropertiesForKeys:nil)
        check(names.count==1,"one existing profile archived")
        let available=SourceNewGame568.archives(backupDirectory:backup)
        check(available.count==1 && available[0].url==names[0],
              "native W3 lists the actual validated backup, not an invented file")
        let bytes=try Data(contentsOf:names[0])
        let payload=try PropertyListSerialization.propertyList(from:bytes,
            format:nil) as! [String:Any]
        let archived=payload["profile"] as! [String:Any]
        check(archived["asteroidy.ios.v556.campaign.completedMask"] as? Int == 1,
              "campaign bit mask exactly backed up")
        check(archived["asteroidy.ios.v568.shop-profile-first-sector"] as? Data ==
              originalShop,"wallet/inventory backed up byte-for-byte")
        check(archived["asteroidy.ios.h11.pc580.c279.vitals"] as? Data ==
              originalVitals,"H11 hull and armor archived byte-for-byte")
        check(archived["asteroidy.ios.pc580.h11.source-mechanics"] as? Data ==
              originalH11,"H11 ships, modules, talents and trophy bits archived byte-for-byte")
        check((archived[SourceTarcza145.persistentKey] as? NSNumber)?
              .floatValue == previousShieldEnergy,
              "existing seven-field talent state unchanged; current shield energy archived")
        let failingURL=FileManager.default.temporaryDirectory
            .appendingPathComponent("backup-blocker-\(UUID().uuidString)")
        try Data("blocker".utf8).write(to:failingURL)
        defer {try? FileManager.default.removeItem(at:failingURL)}
        check(!SourceNewGame568.create(.init(players:1,difficulty:.easy),
              defaults:defaults,backupDirectory:failingURL),
              "failed backup rejects destructive new game")
        check(SourceNewGame568.selection(defaults:defaults).difficulty == .hard &&
              CampaignStore556.load(defaults:defaults).completedCount==0 &&
              H55SourceMechanics580.load(defaults:defaults)==H55SourceMechanics580.State(),
              "failed backup leaves active source state unchanged")

        // Explicit rollback of the complete previous profile; current hard
        // campaign is independently archived before restore overwrites it.
        check(SourceNewGame568.restoreArchive(
            at:names[0],defaults:defaults,backupDirectory:backup),
            "restore verified original PC580 full profile")
        check(Sector01Shop568.load(defaults:defaults)==oldShop &&
              CampaignStore556.load(defaults:defaults).completed(1),
              "restored wallet, Ion/Bombs and campaign completion")
        check(H55Workshop580.loadVitals(defaults:defaults)==oldVitals &&
              H55SourceMechanics580.load(defaults:defaults)==oldH11,
              "restored real ship, guardian, collector, trophies, hull and armor")
        check(SourceNewGame568.selection(defaults:defaults).difficulty == .easy &&
              defaults.integer(forKey:"asteroidy.ios.graphics.test.persistent")==173,
              "restored difficulty without touching graphics/settings")
        check(SourceTarcza145.loadPersistentEnergy(defaults:defaults)==37.5,
              "archive restores source active bar without extra spare charge")
        let backupAfterRestore=try FileManager.default.contentsOfDirectory(
            at:backup,includingPropertiesForKeys:nil)
        check(backupAfterRestore.count==2 &&
              SourceNewGame568.archives(backupDirectory:backup).count==2,
              "restore made a second selectable recovery archive of overwritten profile")

        // Reject tampered and foreign archives BEFORE backing up / changing
        // any live profile record; old save must be recoverable on failure.
        let invalidURL=FileManager.default.temporaryDirectory
            .appendingPathComponent("h11-invalid-\(UUID().uuidString).plist")
        defer {try? FileManager.default.removeItem(at:invalidURL)}
        var invalidPayload=payload
        var invalidState=archived
        invalidState["asteroidy.ios.pc580.h11.source-mechanics"]=Data([1,2,3])
        invalidPayload["profile"]=invalidState
        let invalidBytes=try PropertyListSerialization.data(
            fromPropertyList:invalidPayload,format:.binary,options:0)
        try invalidBytes.write(to:invalidURL,options:.atomic)
        check(!SourceNewGame568.restoreArchive(
            at:invalidURL,defaults:defaults,backupDirectory:backup),
            "malformed H11 source state cannot corrupt an active profile")
        check(H55SourceMechanics580.load(defaults:defaults)==oldH11 &&
              Sector01Shop568.load(defaults:defaults)==oldShop,
              "failed restore leaves wallet and H11 gameplay untouched")
        check(try FileManager.default.contentsOfDirectory(
            at:backup,includingPropertiesForKeys:nil).count==2,
            "bad archive validation cannot create misleading recovery backup")

        // Older v568 archives legitimately lack the new H11 entries.
        let legacyURL=FileManager.default.temporaryDirectory
            .appendingPathComponent("h11-legacy-\(UUID().uuidString).plist")
        defer {try? FileManager.default.removeItem(at:legacyURL)}
        var legacyPayload=payload
        var legacyState=archived
        legacyState.removeValue(forKey:"asteroidy.ios.pc580.h11.source-mechanics")
        legacyState.removeValue(forKey:"asteroidy.ios.h11.pc580.c279.vitals")
        legacyState.removeValue(forKey:SourceTarcza145.persistentKey)
        legacyPayload["profile"]=legacyState
        let legacyBytes=try PropertyListSerialization.data(
            fromPropertyList:legacyPayload,format:.binary,options:0)
        try legacyBytes.write(to:legacyURL,options:.atomic)
        check(SourceNewGame568.restoreArchive(
            at:legacyURL,defaults:defaults,backupDirectory:backup),
            "valid older v568 archive remains restorable")
        check(H55SourceMechanics580.load(defaults:defaults)==H55SourceMechanics580.State() &&
              H55Workshop580.loadVitals(defaults:defaults)==H55Workshop580.Vitals(),
              "legacy restore clears stale modern H11 records")
        check(Sector01Shop568.load(defaults:defaults)==oldShop,
              "legacy restore retains source wallet and ion/bomb purchases")
        check(SourceTarcza145.loadPersistentEnergy(defaults:defaults)==60,
              "legacy archive without current shield energy defaults to 60")
        print("PASS \(checks) PC580 full active-profile archive, legacy migration, rollback and no-data-loss assertions")
    }
}
