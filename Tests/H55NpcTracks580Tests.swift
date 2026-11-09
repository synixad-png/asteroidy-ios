import Foundation
/// Execute only with the SHA-authenticated original 126419336-byte H55 GLB.
@main struct H55NpcTracks580Tests {
    static func check(_ p:Bool,_ s:String){precondition(p,"H09 GLB: "+s)}
    static func main() throws {
        check(CommandLine.arguments.count==2,"source original hangar GLB path")
        let rig=try H55NpcTracks580.load(URL(fileURLWithPath:CommandLine.arguments[1]))
        check(rig.bones.count==80 && rig.idle.tracks.count==240 && rig.walk.tracks.count==240,
              "80 exact bones/480 channels")
        check(abs(rig.walk.duration-2.375)<0.001 && abs(rig.idle.duration-17.625)<0.001,
              "source clip durations")
        let p=rig.sample(walk:true,time:0),q=rig.sample(walk:true,time:rig.walk.duration*0.5)
        check(p.count==80 && q.count==80 && p != q,"actual authored moving poses")
        for i in 0..<80 {check(abs(p[i].rotation.norm-1)<0.001,"unit glTF quat")}
        for suffix in ["_pelvis","_thigh_l","_calf_l","_foot_l","_ball_l",
                       "_thigh_r","_calf_r","_foot_r","_ball_r"] {
            check(rig.named(suffix) != nil,"missing "+suffix)
        }
        let a=H55NpcTracks580.Quaternion.identity
        let b=H55NpcTracks580.Quaternion.axisAngle(SIMD3(0,1,0),.pi)
        check(abs(H55NpcTracks580.Quaternion.slerp(a,b,0.5).norm-1)<0.0001,
              "proper quaternion slerp")
        print("PASS H09 original GLB: 80 exact bone nodes/480 channels and 2.375s/17.625s mocap")
    }
}
