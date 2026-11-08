import Foundation

@main struct H55Walk580Tests {
    static func main() {
        func check(_ value:Bool,_ reason:String) {precondition(value,reason)}
        let clear:(Float,Float,Float)->Bool={_,_,_ in true}
        let flat:(Float,Float,Float)->Float?={_,_,_ in 0}
        var walk=H55Walk580()
        check(walk.x==2 && walk.z==14 && walk.y==0,"surveyed H55 starting lane")
        check(abs(H55Walk580.walkSpeed-4.3)<0.001,"v580 HubWalk speed400 default50")
        check(H55Walk580.bodyRadius==0.34 && H55Walk580.bodyHeight==2,
              "H55FullCollision379 capsule dimensions")
        walk.step(dt:1/60,forward:1,right:0,sprint:false,
                  bodyClear:clear,support:flat)
        check(walk.z<14 && walk.x==2,
              "yaw 0 walks toward -Z as source HubWalk375")
        let early=walk.z
        for _ in 0..<30 {
            walk.step(dt:1/60,forward:1,right:0,sprint:false,
                      bodyClear:clear,support:flat)
        }
        check(walk.z<early-1,"source walking accelerates over 30 frames")
        let oldZ=walk.z
        for _ in 0..<60 {
            walk.step(dt:1/60,forward:0,right:0,sprint:false,
                      bodyClear:clear,support:flat)
        }
        check(walk.z<oldZ && abs(walk.vz)<0.03,"source exponential stop")
        walk.look(deltaX:100,deltaY:100)
        check(abs(walk.yaw-0.28)<0.0001 &&
              abs(walk.pitch+0.25)<0.0001,
              "source delta look uses 0.0028 and 0.0025")
        var wall=H55Walk580()
        let noWall:(Float,Float,Float)->Bool={x,_,_ in x<=2.10}
        for _ in 0..<200 {
            wall.step(dt:1/60,forward:0,right:1,sprint:true,
                      bodyClear:noWall,support:flat)
        }
        check(wall.x<=2.10001,"5cm bounded steps do not pass thin wall")
        var ledge=H55Walk580()
        let unsupported:(Float,Float,Float)->Float?={_,z,_ in
            z<13.8 ? nil : 0
        }
        for _ in 0..<200 {
            ledge.step(dt:1/60,forward:1,right:0,sprint:true,
                       bodyClear:clear,support:unsupported)
        }
        check(ledge.z>=13.8,"missing floor blocks movement fail-closed")
        var step=H55Walk580()
        let halfMetre:(Float,Float,Float)->Float?={_,z,_ in
            z<13.7 ? Float(0.5) : Float(0)
        }
        for _ in 0..<30 {
            step.step(dt:1/60,forward:1,right:0,sprint:false,
                      bodyClear:clear,support:halfMetre)
        }
        check(abs(step.y-0.5)<0.0001,"source max step up 50cm")
        var tooHigh=H55Walk580()
        let more:(Float,Float,Float)->Float?={_,z,_ in
            z<13.8 ? Float(0.501) : Float(0)
        }
        for _ in 0..<80 {
            tooHigh.step(dt:1/60,forward:1,right:0,sprint:true,
                         bodyClear:clear,support:more)
        }
        check(tooHigh.z>=13.8,"source rejects steps above .50 metres")
        var jump=H55Walk580()
        check(jump.jump(),"source first jump enabled")
        check(jump.jumps==1 && !jump.grounded,"jump makes airborne")
        var firstTop:Float=0
        for _ in 0..<150 {
            jump.step(dt:1/60,forward:0,right:0,sprint:false,
                      bodyClear:clear,support:flat)
            firstTop=max(firstTop,jump.y)
        }
        check(firstTop>1.10 && firstTop<1.20,
              "source first jump apex 1.15m")
        check(jump.y==0 && jump.grounded && jump.jumps==0,
              "source jump resets on floor contact")
        check(jump.jump(),"first jump for double-jump sequence")
        for _ in 0..<10 {
            jump.step(dt:1/60,forward:0,right:0,sprint:false,
                      bodyClear:clear,support:flat)
        }
        check(jump.jump(),"source midair second jump")
        check(jump.jumps==2 && !jump.jump(),"third jump forbidden")
        var secondApex:Float=jump.y
        for _ in 0..<180 {
            jump.step(dt:1/60,forward:0,right:0,sprint:false,
                      bodyClear:clear,support:flat)
            secondApex=max(secondApex,jump.y)
        }
        check(secondApex>3.45 && secondApex<5,
              "source second jump adds 3.45 metres of vertical travel")
        check(jump.grounded && jump.jumps==0,
              "double jump re-arms only after physical landing")
        print("PASS v580 H55 walking source speed/look/damping, GLB collision gates, max-step, no-floor and walls")
    }
}
