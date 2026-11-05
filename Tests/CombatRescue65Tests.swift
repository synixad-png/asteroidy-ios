import Foundation

@main struct CombatRescue65Tests {
    static func body(_ x:Float,_ vx:Float=0)->CombatBody68 {
        CombatBody68(position:Vec2(x:x,y:360),
            velocity:Vec2(x:vx,y:0),mass:2.4,radius:11)
    }
    static func close(_ x:Float,_ y:Float) {
        precondition(abs(x-y)<0.002,"Expected \\(y), got \\(x)")
    }
    static func main() {
        var rescue=CombatRescue65()
        var s1=CombatSurvival96(),s2=CombatSurvival96()
        var a=body(640,33), b=body(695,30)
        precondition(!rescue.beginDown(.first,cooperative:false,playing:true,
                    developerInfinite:false,rescueDamage:false,
                    survival:&s1,body:&a))
        precondition(!rescue.down(.first))
        precondition(rescue.beginDown(.first,cooperative:true,playing:true,
                    developerInfinite:false,rescueDamage:false,
                    survival:&s1,body:&a))
        precondition(rescue.down(.first) && s1.currentDown)
        close(rescue.downFirst,12)
        close(s1.invincible,9999)
        close(a.velocity.lengthSquared,0)
        // Two seconds of successful helper fire. The running rescue does not
        // consume a life; it resets 3-second protection and velocity.
        var ev=CombatRescue65.Event.none
        for _ in 0..<120 {
            ev=rescue.tick(dt:1.0/60,playing:true,sceneBusy:false,
                devOpen:false,bossArrival:false,cooperative:true,
                first:&a,second:&b,firstSurvival:&s1,secondSurvival:&s2,
                firstFiring:false,secondFiring:true)
        }
        precondition(ev == .rescued(.first))
        precondition(rescue.rescues == 1 && !rescue.down(.first))
        close(s1.invincible,3)
        close(rescue.progress,0)
        close(Float(s1.lives),3)

        // A slow helper cannot rescue; progress decays at twice the speed
        // until the 12-second down timer triggers an explicit failure action.
        b.velocity=Vec2(x:180,y:0)
        precondition(rescue.beginDown(.second,cooperative:true,playing:true,
                    developerInfinite:false,rescueDamage:false,
                    survival:&s2,body:&b))
        // Failure is a requested Damage() action, not an automatic life loss
        // because guardian and talents may still absorb the failure damage.
        for _ in 0..<13 {
            ev=rescue.tick(dt:1,playing:true,sceneBusy:false,
                devOpen:false,bossArrival:false,cooperative:true,
                first:&a,second:&b,firstSurvival:&s1,secondSurvival:&s2,
                firstFiring:false,secondFiring:false)
            if case .failed = ev { break }
        }
        precondition(ev == .failed(first:false,second:true))
        precondition(s2.lives == 3 && !s2.currentDown)

        // Simultaneous wrecks fail immediately; only the verified Damage()
        // layer is authorized to resolve the resulting real loss.
        precondition(rescue.beginDown(.first,cooperative:true,playing:true,
                    developerInfinite:false,rescueDamage:false,
                    survival:&s1,body:&a))
        precondition(rescue.beginDown(.second,cooperative:true,playing:true,
                    developerInfinite:false,rescueDamage:false,
                    survival:&s2,body:&b))
        ev=rescue.tick(dt:1/60,playing:true,sceneBusy:false,
                       devOpen:false,bossArrival:false,cooperative:true,
                       first:&a,second:&b,firstSurvival:&s1,
                       secondSurvival:&s2,firstFiring:true,secondFiring:true)
        precondition(ev == .failed(first:true,second:true))
        precondition(s1.lives==3 && s2.lives==3)

        // Blockers never advance the progress or timers.
        precondition(rescue.beginDown(.first,cooperative:true,playing:true,
                    developerInfinite:false,rescueDamage:false,
                    survival:&s1,body:&a))
        let before=rescue.downFirst
        ev=rescue.tick(dt:3,playing:true,sceneBusy:true,
                       devOpen:false,bossArrival:false,cooperative:true,
                       first:&a,second:&b,firstSurvival:&s1,
                       secondSurvival:&s2,firstFiring:true,secondFiring:true)
        precondition(ev == .none)
        close(rescue.downFirst,before)
        print("PASS: Gameplay65 12s down, 105-unit rescue, 2s progress, 2x decay, co-op helper input, failure guards")
    }
}
