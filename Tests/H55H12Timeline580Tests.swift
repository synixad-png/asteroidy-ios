import Foundation

/// Verified H12 time map from Windows GpuHub90.cs:177–184 and
/// H55Renderer.cs:1108–1127. No scene, artwork or fabricated H51 keys.
@main struct H55H12Timeline580Tests {
    static func expect(_ b:Bool,_ m:String){precondition(b,"H12 PC580 "+m)}
    static func close(_ a:Float,_ b:Float,_ m:String) {
        expect(abs(a-b)<0.0005,m+" \(a) vs \(b)")
    }
    static func main() {
        let names=H55H12Timeline580.obligatory
        expect(names.count==6 && Set(names).count==6,
               "original six independent/composite clips")
        var d:[String:Float]=[:]
        let actual:[Float]=[32,96,2.4,96,20,16]
        for (i,n) in names.enumerated() {d[n]=actual[i]}
        d["H39_AmbientImported_LOOP"]=10
        d["H39_SingleAction"]=11
        d["NPC525_Walk"]=2.375
        d["H70_HANGAR_AIRLOCK_SLIDING_DOORS_8S"]=8
        d["H51_03_SHOULD_NEVER_AUTO"]=64
        d["H39_Idle_Natural_24s_NO_ARMS"]=24
        let meta=[
            H55H12Timeline580.Loop("H39_AmbientImported_LOOP",1.5),
            H55H12Timeline580.Loop("H70_HANGAR_AIRLOCK_SLIDING_DOORS_8S",1),
            H55H12Timeline580.Loop("NPC525_Walk",1),
            H55H12Timeline580.Loop("H51_03_SHOULD_NEVER_AUTO",1),
            H55H12Timeline580.Loop("H39_AmbientImported_LOOP",1.5)
        ]
        func frame(_ t:Float)->[H55H12Timeline580.Sample] {
            H55H12Timeline580.sample(time:t,durations:d,
                idleMorph:"H39_Idle_Natural_24s_NO_ARMS",metadata:meta)
        }
        let zero=frame(0)
        expect(zero.count==7 && zero[0].clip==H55H12Timeline580.docking,
               "one H51 docking composite plus four original loops, idle and imported")
        expect(!zero.map(\.clip).contains(H55H12Timeline580.service),
               "service composite never plays concurrently during docking")
        expect(!zero.map(\.clip).contains("NPC525_Walk") &&
               !zero.map(\.clip).contains("H70_HANGAR_AIRLOCK_SLIDING_DOORS_8S") &&
               !zero.map(\.clip).contains("H51_03_SHOULD_NEVER_AUTO"),
               "H09 NPC/H07 doors/unauthorized H51 protected")
        let before=frame(31.9)
        expect(before[0].clip==H55H12Timeline580.docking,
               "strict source <32 second docking gate")
        close(before[0].at,31.9,"H51 frame at 31.9")
        let after=frame(32)
        expect(after[0].clip==H55H12Timeline580.service,
               "at exactly 32 seconds H51 service replaces H51 docking")
        close(after[0].at,0,"service resets local timer at 32")
        let t=frame(48)
        close(t[0].at,16,"service at t=48")
        // IEEE754 float modulo at an exact mathematical boundary may
        // return duration-epsilon rather than zero, as in PC C# float.
        expect(min(abs(t[1].at),abs(t[1].at-2.4))<0.001,
               "turbine source 2x, duration2.4 wraps (float modulo)")
        close(t[2].at,48,"repair arms 3x, duration96 => 32-second cycle")
        close(t[3].at,8,"light 20-second loop")
        close(t[4].at,0,"crane 16-second loop")
        close(t[5].at,0,"morph idle 24-second loop")
        close(t[6].at,2,"metadata 1.5x10-second loop")
        close(frame(129)[0].at,1,"service 96-second repeat")
        expect(frame(-1).isEmpty && frame(Float.nan).isEmpty,
               "reject invalid negative/nonfinite source clocks")
        var missing=d
        missing.removeValue(forKey:H55H12Timeline580.service)
        expect(H55H12Timeline580.sample(time:33,durations:missing).isEmpty,
               "missing actual source composite must fail closed")
        print("PASS H12 GpuHub90/H55Renderer source timeline: 32-second docking, 96-second service, 2x turbine, 3x arms, light/crane/morph, imported metadata and H07/H09 channel protection")
    }
}
