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
        var spring=HudIconMotion600()
        let active=HudMotion600.Pose(iconStrength:1,parallax:true)
        for i in 0..<4 {
            let still=HudPickupTransform600.sample(index:i,time:0,
                pose:zero,drawableWidth:1280,drawableHeight:720)!
            let frame0=spring.evaluate(index:i,seconds:0,motion:active)!
            let frame4=spring.evaluate(index:i,seconds:4,motion:active)!
            let a=HudPickupTransform600.sample(index:i,time:0,
                pose:active,drawableWidth:1280,drawableHeight:720,
                animation:frame0)!
            let b=HudPickupTransform600.sample(index:i,time:4,
                pose:active,drawableWidth:1280,drawableHeight:720,
                animation:frame4)!
            verify(a.x>20 && a.x<1260 && a.y>20 && a.y<700,
                   "HUD icons remain on-screen")
            verify(still.yaw==0 && still.pitch==0 && still.roll==0,
                   "disabled HUD does not fabricate 3D icon motion")
            verify(abs(a.yaw)<0.2 && abs(a.pitch)<0.2 && abs(a.roll)<0.2,
                   "original icons never spin through 360 degrees")
            verify(abs(a.yaw-b.yaw)+abs(a.pitch-b.pitch)>0.01,
                   "actual PC icon spring animates all four independently")
            let m=HudPickupTransform600.mvp(a,width:1280,height:720)
            verify(m.columns.3.x.isFinite && m.columns.3.y.isFinite,
                   "GPU transform is finite")
        }
        var shotPose=HudMotion600.Pose()
        shotPose.shotPulse=0.8
        shotPose.pickupPulse=0.5
        let plain=HudPickupTransform600.sample(index:0,time:0,
            pose:zero,drawableWidth:1280,drawableHeight:720)!
        let pulsed=HudPickupTransform600.sample(index:0,time:0,
            pose:shotPose,drawableWidth:1280,drawableHeight:720)!
        verify(pulsed.size>plain.size,
               "real shot/pickup events produce local PC v600 GLB icon pulse")
        let p=HudPickupTransform600.sample(index:3,time:7,
            pose:zero,drawableWidth:1179,drawableHeight:255)!
        verify(p.x>0 && p.x<1179 && p.y>0 && p.y<255,
               "iPhone wide HUD remains on-screen")
        let q=HudPickupTransform600.sample(index:0,time:7,
            pose:zero,drawableWidth:1024,drawableHeight:768)!
        verify(q.x>0 && q.x<1024 && q.y>0 && q.y<768,
               "iPad 4:3 HUD remains on-screen")
        var layout=HudLayout600.defaults()
        let defaultIcon=layout.widget("ion.icon")!
        let start=HudPickupTransform600.sample(index:0,time:2,
            pose:zero,drawableWidth:1280,drawableHeight:720,
            widget:defaultIcon)!
        layout.change("ion.icon") {
            $0.x += 80
            $0.y -= 35
            $0.scale=1.75
            $0.yaw=23
            $0.pitch = -11
            $0.roll=7
        }
        let edited=HudPickupTransform600.sample(index:0,time:2,
            pose:zero,drawableWidth:1280,drawableHeight:720,
            widget:layout.widget("ion.icon"))!
        verify(edited.x>start.x && edited.y<start.y,
               "edited HUD GLB coordinates affect real Metal placement")
        verify(edited.size>start.size*1.7,
               "HUD editor scale affects existing Metal model")
        verify(edited.yaw>start.yaw && edited.pitch<start.pitch &&
               edited.roll>start.roll,
               "independent yaw pitch roll reach shared Metal geometry")
        let notchViewport=CombatHUDViewport568(width:1179,height:255,
            safeLeft:59,safeRight:59,safeTop:0,safeBottom:0)
        let item=layout.widget("boost.icon")!
        let screen=HudWidgetPlacement600.frame(item,sourceWidth:50,
            sourceHeight:50,anchor:.bottomRight,viewport:notchViewport)!
        let expected=HudWidgetPlacement600.pixels(screen,
            viewport:notchViewport,drawableWidth:1768.5,
            drawableHeight:382.5)!
        let metal=HudPickupTransform600.sample(index:3,time:0,pose:zero,
            drawableWidth:1768.5,drawableHeight:382.5,
            widget:item,viewport:notchViewport)!
        verify(abs(Double(metal.x)-expected.centerX)<0.02 &&
               abs(Double(metal.y)-expected.centerY)<0.02,
               "Metal model center matches SwiftUI on iPhone with Dynamic Island")
        verify(abs(Double(metal.size)-min(expected.width,expected.height)*0.9)<0.02,
               "adaptive iPhone drawable uses approved GLB icon size")
        verify(HudPickupTransform600.sample(index:4,time:0,pose:zero,
            drawableWidth:1024,drawableHeight:768)==nil,
            "unexpected fifth model is rejected")
        print("PASS HUD v600 Metal pickup icons: four identities, bounded angles, iPhone/iPad, finite matrices")
    }
}
