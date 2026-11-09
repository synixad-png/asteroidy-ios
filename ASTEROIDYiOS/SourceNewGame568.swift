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
    // PC v580 SaveManager61.ArchiveActiveProfile358 saves the complete
    // active profile, including talents/modules. The iOS port stores
    // those independent records in separate UserDefaults entries.
    private static let shopKey="asteroidy.ios.v568.shop-profile-first-sector"
    private static let vitalsKey="asteroidy.ios.h11.pc580.c279.vitals"
    private static let mechanicsKey="asteroidy.ios.pc580.h11.source-mechanics"
    private static let profileKeys=[
        "asteroidy.ios.v556.campaign.completedMask",
        "asteroidy.ios.v568.campaign.selectedSector",
        shopKey,vitalsKey,mechanicsKey,
        difficultyKey,playersKey,activeIDKey
    ]
    private static let archiveFormat="Windows-v568-profile358"

    private static func archiveDirectory(_ override:URL?)->URL? {
        override ?? FileManager.default.urls(
            for:.applicationSupportDirectory,
            in:.userDomainMask).first?
                .appendingPathComponent("ASTEROIDY/backups61",isDirectory:true)
    }

    /// Return false without resetting anything if the archive cannot be
    /// safely written and read back. PC SaveManager61 uses the same barrier.
    private static func archiveActive(defaults:UserDefaults,
                                      directory:URL)->Bool {
        guard hasActiveProfile(defaults:defaults) else {return true}
        var snapshot:[String:Any]=[:]
        for key in profileKeys {
            if let value=defaults.object(forKey:key) {snapshot[key]=value}
        }
        do {
            let archive:[String:Any]=[
                "source":archiveFormat,
                "schema":2,
                "savedAt":Date().timeIntervalSince1970,
                "profile":snapshot
            ]
            let bytes=try PropertyListSerialization.data(
                fromPropertyList:archive,format:.binary,options:0)
            try FileManager.default.createDirectory(
                at:directory,withIntermediateDirectories:true)
            let target=directory.appendingPathComponent(
                "active-\(UUID().uuidString).plist")
            try bytes.write(to:target,options:.atomic)
            guard (try? Data(contentsOf:target))==bytes else{return false}
            return true
        } catch{return false}
    }

    /// Explicit restoration of an archived profile. Validate the entire
    /// envelope and every known record BEFORE touching the active profile;
    /// archive the current state first, preserving rollback on failure.
    /// Older v568 archives without H11 records correctly restore H11 defaults.
    @discardableResult static func restoreArchive(
        at url:URL,defaults:UserDefaults = .standard,
        backupDirectory:URL? = nil
    )->Bool {
        guard let bytes=try? Data(contentsOf:url),
              let plist=try? PropertyListSerialization.propertyList(
                from:bytes,format:nil) as? [String:Any],
              plist["source"] as? String == archiveFormat,
              let snapshot=plist["profile"] as? [String:Any],
              !snapshot.isEmpty,
              Set(snapshot.keys).isSubset(of:Set(profileKeys))
        else{return false}
        for (key,value) in snapshot {
            switch key {
            case shopKey:
                guard let data=value as? Data,
                      let state=try? JSONDecoder().decode(
                        Sector01Shop568.State.self,from:data),
                      Sector01Shop568.validate(state) else{return false}
            case vitalsKey:
                guard let data=value as? Data,
                      let state=try? JSONDecoder().decode(
                        H55Workshop580.Vitals.self,from:data),
                      state.valid else{return false}
            case mechanicsKey:
                guard let data=value as? Data,
                      let state=try? JSONDecoder().decode(
                        H55SourceMechanics580.State.self,from:data),
                      state.valid else{return false}
            case "asteroidy.ios.v556.campaign.completedMask",
                 "asteroidy.ios.v568.campaign.selectedSector",
                 difficultyKey,playersKey:
                guard value is Int else{return false}
            case activeIDKey:
                guard value is String else{return false}
            default:return false
            }
        }
        guard let directory=archiveDirectory(backupDirectory),
              archiveActive(defaults:defaults,directory:directory)
        else{return false}
        for key in profileKeys {defaults.removeObject(forKey:key)}
        for (key,value) in snapshot {defaults.set(value,forKey:key)}
        return true
    }

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
        guard let directory=archiveDirectory(backupDirectory),
              archiveActive(defaults:defaults,directory:directory)
        else{return false}
        let fresh=CampaignProgress556()
        CampaignStore556.save(fresh,defaults:defaults)
        Sector01Shop568.save(Sector01Shop568.State(
            lives:startingLives(difficulty:request.difficulty)),defaults:defaults)
        // One transaction boundary for BOTH direct create() and the W3
        // menu: do not leave prior-game H11 ships, trophies or hull behind.
        H55Workshop580.resetVitals(defaults:defaults)
        H55SourceMechanics580.reset(defaults:defaults)
        defaults.set(request.difficulty.rawValue,forKey:difficultyKey)
        defaults.set(1,forKey:playersKey)
        defaults.set(UUID().uuidString,forKey:activeIDKey)
        return true
    }
}
