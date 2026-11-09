import Foundation

/// H12 PC v580: GpuHub90.cs:177–184 selects precisely one H51
/// composite. H55Renderer.cs:1114–1127 applies independently authored
/// mechanisms AFTER that composite, in the original priority order.
/// All clocks use HubTime90; do not mix CAAnimation wall-clock timelines.
enum H55H12Timeline580 {
    static let docking="H51_01_DOCKING_CINEMATIC_32S"
    static let service="H51_02_REPAIR_CINEMATIC_96S"
    static let turbines="04_TURBINE_ROTATION_LOOP"
    static let arms="05_GIANT_REPAIR_ARMS_SERVICE_LOOP"
    static let lighting="H46_LIGHT_IDLE_20S"
    static let crane="H70_WORKSHOP_CRANE_TRAVEL_16S"
    static let idleMorphSuffix="Idle_Natural_24s_NO_ARMS"
    static let obligatory=[docking,service,turbines,arms,lighting,crane]
    static let protectedPrefixes=["NPC525_","H51_","H70_"]
    struct Loop:Equatable {
        let name:String
        let speed:Float
        init(_ name:String,_ speed:Float=1) {
            self.name=name;self.speed=speed
        }
    }
    struct Sample:Equatable {
        let clip:String
        let at:Float
    }
    static func eligibleMetadata(_ clip:String)->Bool {
        guard !clip.isEmpty else{return false}
        let upper=clip.uppercased()
        return !protectedPrefixes.contains(where:{upper.hasPrefix($0)}) &&
            !upper.contains("AIRLOCK") && !upper.contains("DOOR_") &&
            !upper.contains("DOCK_CLAMPS") && !upper.contains("DEPART")
    }
    /// Never skip a genuine H51 composite in favour of an H39 idle clip.
    /// Tests or user-visible GLB inspector are separate explicit playback.
    static func sample(time:Float,durations:[String:Float],
                       idleMorph:String?=nil,
                       metadata:[Loop]=[])->[Sample] {
        guard time.isFinite && time>=0 else{return []}
        let composite=time<32 ? docking : service
        let mainTime=time<32 ? time : (time-32).truncatingRemainder(dividingBy:96)
        guard let d=durations[composite],d>0,d.isFinite else{return []}
        var output=[Sample(clip:composite,at:min(mainTime,d))]
        var present=Set([composite])
        func append(_ name:String,_ speed:Float) {
            guard let duration=durations[name],duration>0,duration.isFinite,
                  speed>0,speed.isFinite,present.insert(name).inserted else{return}
            let source=time*speed
            guard source.isFinite else{return}
            output.append(Sample(clip:name,
                          at:source.truncatingRemainder(dividingBy:duration)))
        }
        append(turbines,2)   // 2 original rotor revolutions per 1.2 s
        append(arms,3)       // 96s authored motion -> 32s source cycle
        append(lighting,1)
        append(crane,1)
        if let idleMorph,idleMorph.hasSuffix(idleMorphSuffix) {
            append(idleMorph,1)
        }
        // Renderer v443 metadata-driven independent loops follow fixed
        // mechanisms, but H70 doors and H51 cinematics are never autoplay.
        for loop in metadata where eligibleMetadata(loop.name) {
            append(loop.name,loop.speed)
        }
        return output
    }
}
