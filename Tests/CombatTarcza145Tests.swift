import Foundation

@main struct CombatTarcza145Tests {
    static func near(_ a:Float,_ b:Float) {
        precondition(abs(a-b)<0.0005,"Expected \\(b), got \\(a)")
    }
    static func main() {
        var t=CombatTarcza145()
        near(t.energy,60)
        precondition(!t.active)
        t.tick(dt:1,held:true,playing:true,shipDown:false)
        near(t.energy,48)
        precondition(t.active)
        var immunity:Float=0.12
        precondition(t.absorb(invincible:&immunity))
        near(t.energy,13)
        near(immunity,0.28)
        near(t.flash,0.37)
        t.tick(dt:0.5,held:true,playing:true,shipDown:false)
        near(t.energy,7)
        precondition(t.absorb(invincible:&immunity))
        near(t.energy,0)
        precondition(!t.active && !t.absorb(invincible:&immunity))
        near(immunity,0.28)
        precondition(t.collectCell())
        near(t.energy,20)
        t.tick(dt:1,held:false,playing:true,shipDown:false)
        near(t.energy,20)
        precondition(!t.active)
        t.tick(dt:0.1,held:true,playing:true,shipDown:true)
        near(t.energy,20)
        precondition(!t.active)
        t.tick(dt:0.1,held:true,playing:false,shipDown:false)
        near(t.energy,20)
        precondition(!t.active)
        t.refill()
        near(t.energy,100)
        precondition(!t.collectCell())
        t.tick(dt:0.5,held:true,playing:true,shipDown:false)
        near(t.energy,94)
        immunity=0.95
        precondition(t.absorb(invincible:&immunity))
        near(immunity,0.95)
        near(t.energy,59)
        t.reset()
        near(t.energy,60)
        precondition(!t.active && t.flash==0)
        print("PASS: source Tarcza145 energy 60/100, 12/s drain, 35/hit, .28 immunity, 20-cell, scene/down guards")
    }
}
