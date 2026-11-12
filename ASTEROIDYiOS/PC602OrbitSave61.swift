import Foundation
import CryptoKit

/// Native, isolated iOS representation of PC602 SaveManager61.Snapshot61.
/// PC slots are NOT claimed byte-compatible with Windows .txt saves.
/// Source fields: position[3], forward[3], right[3], target, completion mask,
/// canonical wallet/modules/vitals/difficulty and originating run ID.
/// As in LoadSlot61 + InitializeHomeFlight291, speed/projectiles are reset
/// when resuming. A valid save never fabricates earned campaign progress.
enum PC602OrbitSave61 {
    enum Failure:Error {case unavailable,invalid,unsupported,io}
    static let schema=1
    static let validMask=(1<<26)-1

    struct Snapshot:Codable {
        let schema:Int
        let savedAt:Double
        let runID:String
        let shipType:Int
        let position:[Float]
        let forward:[Float]
        let right:[Float]
        let target:Int
        let completedMask:Int
        let shop:Sector01Shop568.State
        let vitals:H55Workshop580.Vitals
        let mechanics:H55SourceMechanics580.State
        let difficultyRaw:Int
        // PC602 Snapshot61 meta[0]/meta[3]. A legacy JSON record without
        // these fields is an orbital snapshot, never a guessed mission save.
        var sourceMode61:String? = nil
        var missionLevel61:Int? = nil
        var returnHome61:Bool? = nil

        var isMissionIntro61:Bool {
            sourceMode61 == "intro" && missionLevel61 == 1
        }
        var isOrbit61:Bool {sourceMode61 == nil || sourceMode61 == "orbit"}

        private func length(_ a:[Float])->Float {
            sqrt(a.reduce(Float.zero){$0+$1*$1})
        }
        private func dot(_ a:[Float],_ b:[Float])->Float {
            zip(a,b).reduce(Float.zero){$0+$1.0*$1.1}
        }
        var valid:Bool {
            guard schema==PC602OrbitSave61.schema,
                  (isOrbit61 || isMissionIntro61),
                  (isOrbit61 || missionLevel61==1),
                  (isOrbit61 || returnHome61 != nil),
                  savedAt.isFinite,savedAt>0,
                  UUID(uuidString:runID) != nil,
                  shipType==1, // Other craft explicitly out of scope.
                  (1...26).contains(target),
                  completedMask>=0,completedMask & ~PC602OrbitSave61.validMask == 0,
                  PC602HomeFlight291.unlocked(target,mask:completedMask),
                  position.count==3,forward.count==3,right.count==3,
                  (position+forward+right).allSatisfy({$0.isFinite && abs($0)<=1000}),
                  // ReadSlot61 only imposes the orbit-length/orthogonality
                  // constraints on Mode.Orbit. Intro stores unused vectors
                  // as finite values, exactly as the Windows source does.
                  (!isOrbit61 || (100...1000).contains(length(position))),
                  (!isOrbit61 || (0.9...1.1).contains(length(forward))),
                  (!isOrbit61 || (0.9...1.1).contains(length(right))),
                  (!isOrbit61 || abs(dot(forward,right))<=0.2),
                  mechanics.valid && mechanics.selectedShip==1,
                  vitals.valid,
                  Sector01Shop568.validate(shop),
                  CombatBalance556.Difficulty(rawValue:difficultyRaw) != nil
            else{return false}
            return true
        }
    }

    private struct Envelope:Codable {
        let schema:Int
        let checksum:String
        let payload:Data
    }

    static func capture(_ flight:PC602HomeFlight291,
                        defaults:UserDefaults = .standard)->Snapshot? {
        guard let id=SourceNewGame568.currentRunID(defaults:defaults) else{return nil}
        let position=flight.orbitPosition
        let forward=flight.orbitForward
        let right=flight.orbitRight
        let snapshot=Snapshot(schema:schema,savedAt:Date().timeIntervalSince1970,
            runID:id,shipType:flight.equipment.craft.rawValue,
            position:[position.x,position.y,position.z],
            forward:[forward.x,forward.y,forward.z],
            right:[right.x,right.y,right.z],
            target:flight.target,completedMask:flight.completedMask,
            shop:Sector01Shop568.load(defaults:defaults),
            vitals:H55Workshop580.loadVitals(defaults:defaults),
            mechanics:H55SourceMechanics580.load(defaults:defaults),
            difficultyRaw:SourceNewGame568.selection(defaults:defaults).difficulty.rawValue)
        return snapshot.valid ? snapshot : nil
    }

    /// PC602 Intro41.BeginLevelIntro -> SaveManager61.RefreshCheckpoint61:
    /// the source checkpoint is PRE-combat, never current combat projectiles,
    /// lives spent after intro, temporary scores or random battle frames.
    /// A direct W3 intro has no active orbit vectors (which PC ReadSlot61
    /// expressly does not require for Mode.Intro). Do not fabricate an orbit.
    static func captureMissionStart61(level:Int,returnHome:Bool,
        baseOrbit:Snapshot?=nil,
        defaults:UserDefaults = .standard)->Snapshot? {
        guard level==1,
              let runID=SourceNewGame568.currentRunID(defaults:defaults),
              UUID(uuidString:runID) != nil else{return nil}
        let progress=CampaignStore556.load(defaults:defaults)
        guard progress.unlocked(level) else{return nil}
        let verifiedOrbit=baseOrbit?.isOrbit61 == true &&
            baseOrbit?.runID==runID && baseOrbit?.valid == true ? baseOrbit : nil
        var result=Snapshot(schema:schema,savedAt:Date().timeIntervalSince1970,
            runID:runID,shipType:1,
            position:verifiedOrbit?.position ?? [0,0,0],
            forward:verifiedOrbit?.forward ?? [0,0,0],
            right:verifiedOrbit?.right ?? [0,0,0],
            target:level,completedMask:progress.completedMask,
            shop:Sector01Shop568.load(defaults:defaults),
            vitals:H55Workshop580.loadVitals(defaults:defaults),
            mechanics:H55SourceMechanics580.load(defaults:defaults),
            difficultyRaw:SourceNewGame568.selection(defaults:defaults).difficulty.rawValue)
        result.sourceMode61="intro"
        result.missionLevel61=level
        result.returnHome61=returnHome
        return result.valid ? result : nil
    }

    private static func file(_ slot:Int?)->URL? {
        if let slot, !(0...2).contains(slot) {return nil}
        guard let support=FileManager.default.urls(
            for:.applicationSupportDirectory,in:.userDomainMask).first else{return nil}
        return support.appendingPathComponent("ASTEROIDY/saves61",isDirectory:true)
            .appendingPathComponent(slot.map{"slot\($0).json"} ?? "resume.json")
    }
    private static func digest(_ data:Data)->String {
        SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined()
    }
    static func store(_ snapshot:Snapshot,slot:Int?=nil) throws {
        guard snapshot.valid,let url=file(slot) else{throw Failure.invalid}
        let payload=try JSONEncoder().encode(snapshot)
        let wrapper=Envelope(schema:schema,checksum:digest(payload),payload:payload)
        let bytes=try JSONEncoder().encode(wrapper)
        do {
            try FileManager.default.createDirectory(
                at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
            try bytes.write(to:url,options:.atomic)
            let verify=try read(slot:slot)
            guard verify.runID==snapshot.runID,
                  verify.target==snapshot.target,
                  verify.position==snapshot.position,
                  verify.completedMask==snapshot.completedMask,
                  verify.sourceMode61==snapshot.sourceMode61,
                  verify.missionLevel61==snapshot.missionLevel61
            else{throw Failure.invalid}
        } catch {throw Failure.io}
    }
    static func read(slot:Int?=nil)throws->Snapshot {
        guard let url=file(slot),let data=try? Data(contentsOf:url),
              let env=try? JSONDecoder().decode(Envelope.self,from:data),
              env.schema==schema,
              env.checksum==digest(env.payload),
              let state=try? JSONDecoder().decode(Snapshot.self,from:env.payload),
              state.valid else{throw Failure.invalid}
        return state
    }
    static func exists(slot:Int?=nil)->Bool {(try? read(slot:slot)) != nil}
    // Source ReadSlot61 and DeleteSlot61: corrupt slots are not empty.
    static func slotFileExists(_ slot:Int)->Bool {
        guard let url=file(slot) else{return false}
        return FileManager.default.fileExists(atPath:url.path)
    }
    @discardableResult static func deleteSlot(_ slot:Int)->Bool {
        guard let url=file(slot),
              FileManager.default.fileExists(atPath:url.path)
        else{return false}
        do {try FileManager.default.removeItem(at:url);return true}
        catch{return false}
    }
    static var hasManualSave:Bool {(0..<3).contains {exists(slot:$0)}}
    static func clearResume() {
        guard let file=file(nil) else{return}
        try? FileManager.default.removeItem(at:file)
    }
}
