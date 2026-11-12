import Foundation

/// Direct PC Tests/TarczaReserve608Tests.cs parity. Works without
/// UIKit/Metal and exercises the SAME reducer as live C279 and Physics68.
@main struct CombatTarcza145Tests {
    static func near(_ a:Float,_ b:Float,_ message:String) {
        precondition(abs(a-b)<0.002,"\(message): expected \(b), got \(a)")
    }
    static func main() {
        precondition(CombatTarcza145.maximum==100 &&
                     CombatTarcza145.reserveMaximum==3)
        var t=CombatTarcza145()
        var reserve=3
        var immunity:Float=0
        near(t.energy,60,"PC initial 60")
        t.tick(dt:1,held:true,playing:true,shipDown:false,reserve:&reserve)
        near(t.energy,48,"12 energy drain/s")
        precondition(t.active && reserve==3)
        precondition(t.absorb(invincible:&immunity,reserve:&reserve))
        near(t.energy,13,"35 energy impact")
        near(immunity,0.28,"impact immunity")
        near(t.flash,0.37,"impact flash")

        // PC608 exact chain: 3/3 -> 2/3 -> 1/3 -> 0/3.
        for expected in [2,1,0] {
            t.tick(dt:2,held:true,playing:true,shipDown:false,reserve:&reserve)
            near(t.energy,100,"automatic active bar replacement")
            precondition(reserve==expected && t.active)
        }
        t.tick(dt:9,held:true,playing:true,shipDown:false,reserve:&reserve)
        near(t.energy,0,"no fourth reserve at 0/3")
        precondition(!t.active && reserve==0)
        t.tick(dt:1,held:true,playing:true,shipDown:false,reserve:&reserve)
        near(t.energy,0,"empty reserve never recharges")
        precondition(!t.absorb(invincible:&immunity,reserve:&reserve))

        // Full-bar pickup semantics: not legacy +20.
        precondition(t.collectCell(reserve:&reserve))
        near(t.energy,100,"one pickup at zero energy immediately supplies 100")
        precondition(reserve==0)
        t.tick(dt:1,held:false,playing:true,shipDown:false,reserve:&reserve)
        precondition(!t.active)
        precondition(t.collectCell(reserve:&reserve) && reserve==1)
        precondition(t.collectCell(reserve:&reserve) && reserve==2)
        precondition(t.collectCell(reserve:&reserve) && reserve==3)
        precondition(!t.collectCell(reserve:&reserve))
        t.tick(dt:0.5,held:true,playing:true,shipDown:false,reserve:&reserve)
        near(t.energy,94,"held 0.5 s costs 6 energy")
        precondition(t.collectCell(reserve:&reserve))
        near(t.energy,100,"at 3/3 extra pickup refills current bar")
        precondition(reserve==3)

        // Impact that depletes the active bar consumes exactly one spare.
        t.tick(dt:0.1,held:true,playing:true,shipDown:false,reserve:&reserve)
        for _ in 0..<3 {
            precondition(t.absorb(invincible:&immunity,reserve:&reserve))
        }
        precondition(reserve==2 && t.active)
        near(t.energy,100,"depleting impact replenishes 100")
        t.refill()
        precondition(reserve==2 && !t.active)
        near(t.energy,100,"free hangar refill does not spend reserve")

        var other=CombatTarcza145(), otherReserve=2
        other.tick(dt:0.2,held:false,playing:true,
                   shipDown:false,reserve:&otherReserve)
        precondition(!other.absorb(invincible:&immunity,reserve:&otherReserve))
        precondition(otherReserve==2)
        other.tick(dt:4,held:true,playing:true,shipDown:true,
                   reserve:&otherReserve)
        near(other.energy,60,"downed freezes drain")
        other.tick(dt:4,held:true,playing:false,shipDown:false,
                   reserve:&otherReserve)
        near(other.energy,60,"paused freezes drain")
        other.reset()
        near(other.energy,60,"reset to PC initial")
        precondition(otherReserve==2 && !other.active && other.flash==0)
        print("PASS PC608 Tarcza145: full-bar reserves, impact/drain, 3/3->0/3, pickups, down/pause, no passive hit")
    }
}
