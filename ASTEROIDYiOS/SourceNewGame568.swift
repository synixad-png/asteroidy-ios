import Foundation

/// Native v568 NEW GAME active profile. Source reference:
/// Windows/src/ProgramW3Native315.cs NativeStartFresh342/NativeCommitFresh342,
/// Windows/src/Campaign37.cs StartingLives,
/// Windows/src/SaveManager61.cs ArchiveActiveProfile358.
/// Existing iOS manual-save/settings keys are intentionally NOT reset.
struct SourceNewGameSelection568: Equatable {
    var players:Int=1
    var difficulty:CombatBalance556.Difficulty = .normal
}

enum SourceNewGame568 {
    private static let difficultyKey="asteroidy.ios.v568.newgame.difficulty"
    private static let playersKey="asteroidy.ios.v568.newgame.players"
    private static let activeIDKey="asteroidy.ios.v568.newgame.activeID"
    private static let profileKeys=[
        "asteroidy.ios.v556.campaign.completedMask",
        "asteroidy.ios.v568.campaign.selectedSector",
        "asteroidy.ios.v568.shop-profile-first-sector",
        difficultyKey,playersKey,activeIDKey
    ]

    static func selection(defaults:UserDefaults = .standard)->SourceNewGameSelection568 {
        let difficulty=CombatBalance556.Difficulty(rawValue:
            defaults.object(forKey:difficultyKey) as? Int ?? 1) ?? .normal
        // Co-op is not yet a supported executable iOS mission; never
        // load a stale two-player choice as if the port had two ships.
        return SourceNewGameSelection568(players:1,difficulty:difficulty)
    }
    static func hasActiveProfile(defaults:UserDefaults = .standard)->Bool {
        profileKeys.contains { defaults.object(forKey:$0) != nil }
    }
    // Campaign37.cs:16 (Kestrel=0, Vanguard=1, Bastion=2).
    static func startingLives(difficulty:CombatBalance556.Difficulty,
                              shipType:Int=1)->Int {
        let base=difficulty == .easy ? 5 : 3
        let shipDelta=shipType == 0 ? -1 : shipType == 2 ? 1 : 0
        return min(5,base+shipDelta)
    }
    /// Explicit new campaign only. A preexisting profile must be backed up
    /// before ANY data is reset; failure leaves it unchanged. Manual slots,
    /// music, graphics and touch settings are never mutated here.
    @discardableResult static func create(
        _ request:SourceNewGameSelection568,
        defaults:UserDefaults = .standard,
        backupDirectory:URL? = nil
    )->Bool {
        guard request.players==1 else {return false}
        if hasActiveProfile(defaults:defaults) {
            let root=backupDirectory ??
                FileManager.default.urls(for:.applicationSupportDirectory,
                                         in:.userDomainMask).first?
                    .appendingPathComponent("ASTEROIDY/backups61",isDirectory:true)
            guard let directory=root else {return false}
            var snapshot:[String:Any]=[:]
            for key in profileKeys {
                if let value=defaults.object(forKey:key) {
                    snapshot[key]=value
                }
            }
            do {
                let plist:[String:Any]=[
                    "source":"Windows-v568-profile358",
                    "savedAt":Date().timeIntervalSince1970,
                    "profile":snapshot
                ]
                let bytes=try PropertyListSerialization.data(
                    fromPropertyList:plist,format:.binary,options:0)
                try FileManager.default.createDirectory(at:directory,
                    withIntermediateDirectories:true)
                let target=directory.appendingPathComponent(
                    "active-\(UUID().uuidString).plist")
                try bytes.write(to:target,options:.atomic)
                guard (try? Data(contentsOf:target)) == bytes else {return false}
            } catch {return false}
        }
        let fresh=CampaignProgress556()
        CampaignStore556.save(fresh,defaults:defaults)
        Sector01Shop568.save(Sector01Shop568.State(
            lives:startingLives(difficulty:request.difficulty)),defaults:defaults)
        defaults.set(request.difficulty.rawValue,forKey:difficultyKey)
        defaults.set(1,forKey:playersKey)
        defaults.set(UUID().uuidString,forKey:activeIDKey)
        return true
    }
}
