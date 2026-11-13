import Foundation
@main struct CombatGuardian37Tests {
    static func main() {
        let none=CombatGuardian37(owned:false)
        var invincible:Float=0
        precondition(!none.absorb(invincible:&invincible))
        precondition(none.charges==0 && invincible==0)
        none.resetForSector()
        precondition(none.charges==0)

        let guardian=CombatGuardian37(owned:true)
        precondition(guardian.charges==1)
        precondition(guardian.absorb(invincible:&invincible))
        precondition(guardian.charges==0 && invincible==1.2)
        invincible=0
        precondition(!guardian.absorb(invincible:&invincible))
        guardian.resetForSector()
        precondition(guardian.charges==1)

        var survival=CombatSurvival96(),dome=CombatTarcza145()
        let vitals=CombatTalentVitals78()
        var rescue=CombatRescue65()
        var body=CombatBody68(position:Vec2(x:640,y:360),
            velocity:Vec2(x:0,y:0),mass:2.4,radius:11.2)
        survival.shieldCharges=1
        func collide() -> CombatVerifiedHit556.Outcome {
            CombatVerifiedHit556.hit(cause:"ASTEROIDA",
                level:7,difficulty:.normal,player:.first,
                survival:&survival,body:&body,dome:&dome,rescue:&rescue,
                cooperative:false,developerInfinite:false,
                guardian:.unverified,talent:.unverified,
                vitals:vitals,guardianState:guardian)
        }
        // PC608-609: reserve shield charges are not passive per-hit guards.
        // HitByBoss invokes Campaign37 Guardian BEFORE active Tarcza145.
        precondition(collide() == .guardianAbsorbed)
        precondition(guardian.charges==0 && survival.invincible==1.2)
        precondition(survival.shieldCharges==1 &&
                     vitals.armor==25 && survival.lives==3)
        survival.advance(dt:1)
        precondition(collide() == .ignored)
        survival.advance(dt:0.21) // Allow for Float32 rounding after 1.2 s
        precondition(collide() == .talentAbsorbed)
        precondition(vitals.armor==0 && vitals.hull==59)
        precondition(survival.shieldCharges==1 && survival.lives==3)
        print("PASS PC608-609: Guardian37 charge, respawn immunity, no passive reserve hit, then real armor/hull")
    }
}
