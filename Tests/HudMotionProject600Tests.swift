import Foundation

@main enum HudMotionProject600Tests {
    static func check(_ x:@autoclosure ()->Bool,_ reason:String) {
        precondition(x(),"PC Project parity: "+reason)
    }
    static func near(_ x:Double,_ y:Double,_ reason:String) {
        check(abs(x-y)<0.00001,reason)
    }
    static func main() {
        var pose=HudMotion600.Pose()
        for id in ["status.score","radar","ion.icon","hud.planetarium"] {
            let a=HudMotionProject600.project(
                x:924.2,y:630.1,pose:pose,widget:id)
            near(a.x,924.2,"identity x "+id)
            near(a.y,630.1,"identity y "+id)
        }
        pose.x=8
        pose.y = -5
        pose.roll=0
        pose.parallax=true
        let weights:[(String,Double)]=[
            ("status.score",0.42),("radar",1),
            ("ion.icon",0.78),("hud.planetarium",1.18)]
        for (id,weight) in weights {
            let p=HudMotionProject600.project(
                x:895,y:603,pose:pose,widget:id)
            near(p.x,895+8*weight,"source signed x weight "+id)
            near(p.y,603-5*weight,"source signed y weight "+id)
        }
        pose.x=0
        pose.y=0
        pose.roll=7
        for (id,w) in weights {
            let p=HudMotionProject600.project(
                x:895,y:603,pose:pose,widget:id)
            let radians=7*w*Double.pi/180
            let dx=895.0-640
            let dy=603.0-360
            near(p.x,640+dx*cos(radians)-dy*sin(radians),
                 "PC roll rotates whole icon screen center "+id)
            near(p.y,360+dx*sin(radians)+dy*cos(radians),
                 "PC roll projects y into bottom anchored view "+id)
        }
        pose.x=9
        pose.y=2
        let center=HudMotionProject600.project(
            x:640,y:360,pose:pose,widget:"radar")
        near(center.x,649,"rotation center ignores roll")
        near(center.y,362,"rotation center uses signed y")
        pose.parallax=false
        let inactive=HudMotionProject600.project(
            x:895,y:603,pose:pose,widget:"status.score")
        let expected=HudMotionProject600.project(
            x:895,y:603,pose:pose,widget:"radar")
        near(inactive.x,expected.x,"no parallax gives equal weight")
        near(inactive.y,expected.y,"no parallax projects all categories equally")
        print("PASS PC HUD v600: four widget weights, world-center roll, signed translation, no-parallax identity")
    }
}
