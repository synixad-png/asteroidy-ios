import Foundation
import simd

@main enum HudPickupTransform600Tests {
    static func verify(_ value:@autoclosure ()->Bool,_ why:String) {
        precondition(value(),why)
    }
    static func main() {
        verify(HudPickupTransform600.order == [.energy,.bomb,.shield,.boost],
               "PC v600 four exact GLB icon identities")
        let zero=HudMotion600.Pose()
        for i in 0..<4 {
            let a=HudPickupTransform600.sample(index:i,time:0,
                pose:zero,drawableWidth:1280,drawableHeight:720)!
            let b=HudPickupTransform600.sample(index:i,time:4.0,
                pose:zero,drawableWidth:1280,drawableHeight:720)!
            verify(a.x>20 && a.x<1260 && a.y>20 && a.y<700,
                   "HUD icons remain on-screen")
            verify(abs(a.yaw)<0.2 && abs(a.pitch)<0.2 && abs(a.roll)<0.2,
                   "original icons never spin through 360 degrees")
            verify(abs(a.yaw-b.yaw)+abs(a.pitch-b.pitch)>0.01,
                   "original GLB icon is independently animated")
            let m=HudPickupTransform600.mvp(a,width:1280,height:720)
            verify(m.columns.3.x.isFinite && m.columns.3.y.isFinite,
                   "GPU transform is finite")
        }
        let p=HudPickupTransform600.sample(index:3,time:7,
            pose:zero,drawableWidth:1179,drawableHeight:255)!
        verify(p.x>0 && p.x<1179 && p.y>0 && p.y<255,
               "iPhone wide HUD remains on-screen")
        let q=HudPickupTransform600.sample(index:0,time:7,
            pose:zero,drawableWidth:1024,drawableHeight:768)!
        verify(q.x>0 && q.x<1024 && q.y>0 && q.y<768,
               "iPad 4:3 HUD remains on-screen")
        verify(HudPickupTransform600.sample(index:4,time:0,pose:zero,
            drawableWidth:1024,drawableHeight:768)==nil,
            "unexpected fifth model is rejected")
        print("PASS HUD v600 Metal pickup icons: four identities, bounded angles, iPhone/iPad, finite matrices")
    }
}
