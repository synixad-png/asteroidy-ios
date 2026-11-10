import Foundation

@main enum HudV600CoreTests {
    static func check(_ condition:@autoclosure ()->Bool,_ label:String) {
        precondition(condition(),"HUD v600: "+label)
    }
    static func main() {
        var motion=HudMotion600()
        check(motion.settings.leftSway==400 && motion.settings.rightSway==400,
              "independent default directions 400 percent")
        check(motion.settings.profile==2 && motion.settings.strength==45,
              "PC source profile and strength")
        var s=HudMotion600.Sample()
        _=motion.update(s,at:1,active:true)
        s.turnRate=2.2
        for i in 1...60 {_=motion.update(s,at:1+Double(i)/60,active:true)}
        let left=motion.pose.x
        check(left<0,"left sway tracks genuine turning")
        motion.reset()
        s.turnRate = -2.2
        _=motion.update(s,at:2,active:true)
        for i in 1...60 {_=motion.update(s,at:2+Double(i)/60,active:true)}
        check(motion.pose.x>0,"right sway uses separate limit")
        motion.reset()
        motion.settings.leftSway=0
        s.turnRate=2.2
        _=motion.update(s,at:3,active:true)
        for i in 1...60 {_=motion.update(s,at:3+Double(i)/60,active:true)}
        check(abs(motion.pose.x)<0.001,"left zero disables only left sway")
        motion.settings.profile=0
        check(motion.update(s,at:4,active:true).x==0,"static profile zeroes motion")
        motion.settings.profile=2
        s.shots=10
        _=motion.update(s,at:5,active:true)
        s.shots=11
        check(motion.update(s,at:5+1.0/60,active:true).shotPulse>0,
              "actual shot counter produces one impulse")
        s.hits=1
        check(motion.update(s,at:5+2.0/60,active:true).hitPulse>0,
              "source projectile hit counter drives a real collision reaction")
        s.pickups=1
        let pickupPose=motion.update(s,at:5+3.0/60,active:true)
        check(pickupPose.pickupPulse>0,
              "successful pickup counter drives independent collection impulse")
        check(pickupPose.widgetPulse("ion.icon")>0,
              "source HUD icon consumes shot/collection pulse")
        check(pickupPose.widgetPulse("boost.value")>0,
              "source HUD boost inventory consumes collection pulse")
        check(pickupPose.widgetPulse("status.mode")==0,
              "top UI text never inherits resource micro-pulses")
        check(motion.update(s,at:6,active:false).shotPulse==0,
              "inactive mission resets impulses")
        check(HudEnergy600.fraction(30,maximum:60)==0.5,
              "50 percent health trims exactly half stream")
        check(HudEnergy600.fraction(0,maximum:60)==0,
              "empty health has no glowing ribbon")
        check(HudEnergy600.fraction(300,maximum:60)==1,
              "overmaximum health is clamped")
        let ribbon=HudEnergy600.ribbon(x:1,y:2,width:150,length:75,
                                      time:1.2,style:0,layer:2)
        check(ribbon.count>=10 && ribbon.count<=70,
              "bounded geometry and no unbounded GPU workload")
        check(ribbon.allSatisfy{$0.x>=1 && $0.x<=76},
              "vertices fit current health length")
        let other=HudEnergy600.ribbon(x:1,y:2,width:150,length:75,
                                     time:1.9,style:0,layer:2)
        check(ribbon[3].y != other[3].y,
              "plasma envelope is time-varying")
        print("PASS HUD v600 Swift core: directions, reset, shot pulse, plasma clipping and turbulence")
    }
}