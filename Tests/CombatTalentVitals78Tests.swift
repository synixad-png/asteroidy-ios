import Foundation

@main struct CombatTalentVitals78Tests {
    static func main() {
        let vitals=CombatTalentVitals78()
        var immunity:Float=0
        precondition(vitals.hull==60 && vitals.armor==25)
        precondition(vitals.maxHull==60 && vitals.maxArmor==25)
        precondition(vitals.absorb(damage:18,cause:"ASTEROIDA",
            difficulty:.normal,invincible:&immunity))
        precondition(vitals.hull==60 && vitals.armor==7 && immunity==0.85)
        immunity=0
        precondition(vitals.absorb(damage:18,cause:"ASTEROIDA",
            difficulty:.normal,invincible:&immunity))
        precondition(vitals.hull==49 && vitals.armor==0)
        immunity=0
        precondition(!vitals.absorb(damage:60,cause:"ASTEROIDA",
            difficulty:.normal,invincible:&immunity))
        precondition(vitals.hull==0 && immunity==0.85)
        vitals.reset()
        precondition(vitals.hull==60 && vitals.armor==25)

        let upgraded=CombatTalentVitals78(hullRank:2,armorRank:1,dampenerRank:3)
        precondition(upgraded.maxHull==90 && upgraded.maxArmor==40)
        immunity=0
        precondition(upgraded.absorb(damage:11,cause:"POCISK WROGA",
            difficulty:.hard,invincible:&immunity))
        precondition(upgraded.lastDamage==5 && upgraded.armor==35)
        immunity=0
        precondition(upgraded.absorb(damage:11,cause:"KOLIZJA ZE STATKIEM",
            difficulty:.hard,invincible:&immunity))
        precondition(upgraded.lastDamage==11 && upgraded.armor==24)
        immunity=0
        precondition(upgraded.absorb(damage:0,cause:"POCISK WROGA",
            difficulty:.hard,invincible:&immunity))
        precondition(upgraded.lastDamage==38 && upgraded.armor==0 &&
                     upgraded.hull==76)
        upgraded.advance(dt:0.1)
        precondition(upgraded.flash==0)
        upgraded.reset()
        precondition(upgraded.hull==90 && upgraded.armor==40)

        // End-to-end source flow: purchased shield -> vitals armor ->
        // vitals hull -> Game.Damage life and full vitals reset.
        var survival=CombatSurvival96(),dome=CombatTarcza145()
        var rescue=CombatRescue65()
        var player=CombatBody68(position:Vec2(x:640,y:360),
            velocity:Vec2(x:0,y:0),mass:2.4,radius:11.2)
        let gauge=CombatTalentVitals78()
        survival.shieldCharges=1
        func collide() -> CombatVerifiedHit556.Outcome {
            CombatVerifiedHit556.hit(cause:"ASTEROIDA",
                level:1,difficulty:.normal,player:.first,
                survival:&survival,body:&player,dome:&dome,rescue:&rescue,
                cooperative:false,developerInfinite:false,
                guardian:.clear,talent:.unverified,vitals:gauge)
        }
        precondition(collide()==.applied(.shieldAbsorbed(
            remaining:0,cause:"ASTEROIDA")))
        precondition(gauge.armor==25 && gauge.hull==60)
        survival.advance(dt:1)
        precondition(collide()==.talentAbsorbed)
        precondition(gauge.armor==7 && gauge.hull==60)
        // This hit starts after the .85s of protection expires.
        for hit in 2...5 {
            survival.advance(dt:1)
            let outcome=collide()
            if hit<5 {precondition(outcome == .talentAbsorbed)}
            else {precondition(outcome == .applied(
                .lifeLost(remaining:2,respawnProtection:4.5,
                           cause:"ASTEROIDA")))}
        }
        precondition(gauge.hull==60 && gauge.armor==25)
        precondition(survival.lives==2)
        print("PASS: source Talents78 armor 25, hull 60, upgraded maxima, dampener, fatal-hit continuation and verified shield/vitals/life chain")
    }
}
