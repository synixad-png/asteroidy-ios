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

        private func length(_ a:[Float])->Float {
            sqrt(a.reduce(Float.zero){$0+$1*$1})
        }
        private func dot(_ a:[Float],_ b:[Float])->Float {
            zip(a,b).reduce(Float.zero){$0+$1.0*$1.1}
        }
        var valid:Bool {
            guard schema==PC602OrbitSave61.schema,
                  savedAt.isFinite,savedAt>0,
                  UUID(uuidString:runID) != nil,
                  shipType==1, // Other craft explicitly out of scope.
                  (1...26).contains(target),
                  completedMask>=0,completedMask & ~PC602OrbitSave61.validMask == 0,
                  PC602HomeFlight291.unlocked(target,mask:completedMask),
                  position.count==3,forward.count==3,right.count==3,
                  (position+forward+right).allSatisfy({$0.isFinite && abs($0)<=1000}),
                  (100...1000).contains(length(position)),
                  (0.9...1.1).contains(length(forward)),
                  (0.9...1.1).contains(length(right)),
                  abs(dot(forward,right))<=0.2,
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
                  verify.completedMask==snapshot.completedMask
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
    static func clearResume() {
        guard let file=file(nil) else{return}
        try? FileManager.default.removeItem(at:file)
    }
}
