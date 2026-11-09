import Foundation

@main enum H55FPSPose580Tests {
    static func main() {
        func check(_ yes:Bool,_ why:String) {precondition(yes,why)}
        func close(_ a:Float,_ b:Float,_ tol:Float=0.00001)->Bool{abs(a-b)<tol}
        let p=Float.pi/2
        let walking=H55FPSPose580.gloveWalk(phase:p,movement:1,visualIntensity:0.5,hand:0)
        check(close(walking.x,0.0095) && close(walking.y,0) &&
              close(walking.yawDegrees,0.675),"PC glove source sway")
        let other=H55FPSPose580.gloveWalk(phase:p,movement:1,visualIntensity:0.5,hand:1)
        check(close(other.x,-walking.x) && close(other.y,walking.y) &&
              close(other.yawDegrees,-walking.yawDegrees),"opposing hands")
        let gun=H55FPSPose580.weaponWalk(phase:p,movement:1,visualIntensity:0.5)
        check(close(gun.x,0.0115) && close(gun.y,0) &&
              close(gun.yawDegrees,0.95),"PC weapon source sway")
        let still=H55FPSPose580.gloveWalk(phase:p,movement:0,visualIntensity:1,hand:0)
        check(still.x==0 && still.y==0 && still.yawDegrees==0,
              "Blocked player never sways")
        check(H55FPSPose580.idle(time:p,hand:0,enabled:false)==0,"PC idle gate")
        let a=H55FPSPose580.fingers(time:2,hand:0)
        let b=H55FPSPose580.fingers(time:2,hand:1)
        check(a.count==5 && a.allSatisfy{(0...1).contains($0)},"finger pose bounds")
        check(a != b,"five fingers offset independently by hand")
        check(H55FPSSettings580.tripoLeft == [-36,-35,-92,-75,-10,-15,130] &&
              H55FPSSettings580.tripoRight == [36,-35,-92,-75,10,15,130],
              "PC GlovesSettings417 default TRIPO poses")
        check(H55FPSSettings580.weaponDefault == [26,-31,-92,-10,18,3,100],
              "PC WeaponViewSettings470 original poses")
        print("PASS PC580 hands/weapon sway, idle, independent finger wave and source poses")
    }
}
