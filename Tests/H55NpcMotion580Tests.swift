import Foundation
/// PC v580 v527/v528/v538 gait, blend, 110 kg skeleton and landing springs.
@main struct H55NpcMotion580Tests {
    static func check(_ p:Bool,_ s:String){precondition(p,"H09: "+s)}
    static func main() throws {
        check(CommandLine.arguments.count==2,"original 126 MB GLB required")
        let rig=try H55NpcTracks580.load(URL(fileURLWithPath:CommandLine.arguments[1]))
        let motion=try H55NpcMotion580(rig:rig)
        check(motion.links.count==15,"15 actual joints")
        check(abs(motion.links.reduce(Float(0)){$0+$1.mass}-110)<0.0001,"exact 110kg mass")
        _=motion.step(dt:1/60,moving:false,distance:0,speed:0,yawRate:0)
        for _ in 0..<25 {_=motion.step(dt:1/60,moving:false,distance:0,speed:0,yawRate:0)}
        let old=motion.poses
        _=motion.step(dt:1/60,moving:true,distance:1,speed:1.0,yawRate:0)
        check(motion.playingWalk && motion.clipTime>0 && motion.blendElapsed<0.25,
              "walk follows real distance, source blend 0.25")
        check(old != motion.poses,"transition poses change from real mocap")
        let exact:Float=1.5 / H55NpcMotion580.walkCycleMeters * rig.walk.duration
        _=motion.step(dt:1/60,moving:true,distance:1.5,speed:1,yawRate:0)
        check(abs(motion.gaitTime-exact)<0.00001,"phase from accumulated distance")
        for _ in 0..<20 {_=motion.step(dt:1/60,moving:false,distance:1.5,speed:0,yawRate:0)}
        check(!motion.playingWalk,"standing state during collision/stop")
        for _ in 0..<120 {_=motion.step(dt:1/60,moving:false,distance:1.5,speed:0,yawRate:0)}
        let recovered=motion.step(dt:1/60,moving:true,distance:2,speed:1,yawRate:0)
        check(motion.playingWalk && abs(motion.gaitTime-(2 / 4.01 * 2.375))<0.00001,
              "walk does not restart from frame zero after stop")
        for i in motion.links.indices {
            check(abs(recovered[motion.links[i].bone].rotation.norm-1)<0.002,
                  "15 source springs normalized")
        }
        let before=motion.land(dt:1/60,newContacts:1,speed:1)
        check(before>=0 && before<=0.017,"landing compression within source 17mm cap")
        for _ in 0..<500 {_=motion.land(dt:1/60,newContacts:0,speed:0)}
        check(motion.landingDrop<0.001,"damped 110kg landing settles")
        print("PASS H09 original GLB: 15-joint 110kg springs, 0.25s blend, distance gait and 17mm landing")
    }
}
