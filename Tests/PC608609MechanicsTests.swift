import Foundation

/// Direct behavioral parity to Tests/TarczaReserve608Tests.cs (PC v608)
/// and Tests/ArmorRegeneration609Tests.cs (PC v609). Portable Swift,
/// no Metal, UIKit, artificial pause clock or additional HUD state.
@main struct PC608609MechanicsTests {
    static var checks=0
    static func check(_ condition:@autoclosure ()->Bool,_ message:String) {
        checks+=1
        precondition(condition(),"PC608_609_PARITY_FAIL: "+message)
    }
    static func near(_ value:Float,_ expected:Float,_ message:String) {
        check(abs(value-expected)<0.002,message)
    }

    static func shields() {
        check(SourceTarcza145.maximum==100 &&
              SourceTarcza145.reserveMaximum==3,
              "one active 100-point bar plus three reserve bars")
        var shield=SourceTarcza145()
        var reserve=3
        shield.energy=40
        shield.step(dt:0.25,held:true,playing:true,reserve:&reserve)
        near(shield.energy,37,"12 energy per second while held")
        check(shield.active && reserve==3,"no passive drain of reserves")
        for expected in [2,1,0] {
            shield.energy=0.3
            shield.step(dt:0.1,held:true,playing:true,reserve:&reserve)
            near(shield.energy,100,"auto replacement always supplies 100")
            check(reserve==expected && shield.active,
                  "reserve consumption 3/3 -> 2/3 -> 1/3 -> 0/3")
        }
        shield.energy=0.3
        shield.step(dt:0.1,held:true,playing:true,reserve:&reserve)
        near(shield.energy,0,"no extra replacement with empty reserve")
        check(!shield.active && reserve==0,"no fourth reserve")
        shield.step(dt:0.1,held:true,playing:true,reserve:&reserve)
        near(shield.energy,0,"no spontaneous regeneration")

        shield.energy=80;reserve=3;shield.active=true
        var immunity:Float=0
        check(shield.absorb(invincible:&immunity,reserve:&reserve),
              "active shield intercepts damage")
        near(shield.energy,45,"hit costs 35 energy")
        check(reserve==3 && immunity>=0.28,"non-depleting hit costs no reserve")
        shield.energy=10;shield.active=true
        check(shield.absorb(invincible:&immunity,reserve:&reserve),
              "depleting impact is blocked")
        near(shield.energy,100,"impact restores full bar")
        check(reserve==2 && shield.active,"exactly one reserve on impact")
        shield.energy=5;shield.active=true;reserve=0
        check(shield.absorb(invincible:&immunity,reserve:&reserve),
              "last five energy still absorb one impact")
        near(shield.energy,0,"depleted with no reserve")
        check(!shield.active && !shield.absorb(
            invincible:&immunity,reserve:&reserve),"no free impact block at zero")

        shield.energy=100;shield.active=false;reserve=3
        check(!shield.absorb(invincible:&immunity,reserve:&reserve),
              "inactive shield never intercepts and cannot consume reserve")
        check(reserve==3,"unshielded hit leaves reserve unchanged")
        shield.energy=25;reserve=1
        check(shield.collectCell(reserve:&reserve) &&
              shield.energy==25 && reserve==2,"pickup adds one full reserve")
        check(shield.collectCell(reserve:&reserve) && reserve==3,
              "second pickup reaches reserve maximum")
        check(shield.collectCell(reserve:&reserve) &&
              shield.energy==100 && reserve==3,
              "full reserve pickup may refill current bar")
        check(!shield.collectCell(reserve:&reserve),
              "no overflow when active+reserve are full")
        shield.energy=0;reserve=0
        check(shield.collectCell(reserve:&reserve) &&
              shield.energy==100 && reserve==0,
              "pickup at zero energy restores active bar through reserve")
        shield.energy=0;reserve=2
        shield.step(dt:0.01,held:false,playing:true,reserve:&reserve)
        check(shield.energy==100 && reserve==1 && !shield.active,
              "legacy save with empty energy consumes one reserve")
        shield.step(dt:0.01,held:false,playing:true,reserve:&reserve)
        check(shield.energy==100 && reserve==1,"save migration is idempotent")
        shield.energy=80;shield.active=false;reserve=2
        shield.step(dt:100,held:true,playing:false,reserve:&reserve)
        check(shield.energy==80 && reserve==2 && !shield.active,
              "pause/menu cannot drain shield")
        shield.step(dt:100,held:true,playing:true,
                    shipDown:true,reserve:&reserve)
        check(shield.energy==80 && reserve==2 && !shield.active,
              "downed cannot drain shield")
        shield.refill()
        check(shield.energy==100 && reserve==2 && !shield.active,
              "free hangar refill never spends reserves")

        // The verified Physics68 adapter MUST delegate to the identical
        // reducer instead of implementing different reserve semantics.
        var adapter=CombatTarcza145();reserve=3
        adapter.tick(dt:1,held:true,playing:true,shipDown:false,reserve:&reserve)
        near(adapter.energy,48,"adapter same held drain")
        check(adapter.absorb(invincible:&immunity,reserve:&reserve),
              "adapter active hit")
        near(adapter.energy,13,"adapter same 35-point impact")
        adapter.tick(dt:2,held:true,playing:true,shipDown:false,reserve:&reserve)
        check(adapter.energy==100 && reserve==2,
              "adapter same full-bar replenishment")
    }

    static func armor() {
        check(ArmorRegeneration609.interval==3 &&
              ArmorRegeneration609.fraction==0.25,
              "3 seconds and 25 percent of CURRENT maximum")
        for rank in 0...4 {
            let maximum=25+15*rank
            var armor=0
            var regen=ArmorRegeneration609()
            for cycle in 1...4 {
                regen.advance(dt:2.9,armor:&armor,maximum:maximum,
                              playing:true,shipDown:false)
                check(armor==maximum*(cycle-1)/4,
                      "rank \(rank) cannot heal before threshold \(cycle)")
                regen.advance(dt:0.1,armor:&armor,maximum:maximum,
                              playing:true,shipDown:false)
                check(armor==maximum*cycle/4,
                      "rank \(rank) exact fractional quarter \(cycle)")
            }
            check(armor==maximum,"full at 12 seconds every rank")
            regen.advance(dt:60,armor:&armor,maximum:maximum,
                          playing:true,shipDown:false)
            check(armor==maximum && regen.elapsed==0 && regen.carry==0,
                  "no overheal; timer and fraction reset at max")
        }
        var healing=ArmorRegeneration609(),amount=0
        healing.advance(dt:3,armor:&amount,maximum:25,
                        playing:true,shipDown:false)
        check(amount==6,"3s zero->6")
        healing.advance(dt:3,armor:&amount,maximum:25,
                        playing:true,shipDown:false)
        check(amount==12,"6s zero->12")
        healing.advance(dt:3,armor:&amount,maximum:25,
                        playing:true,shipDown:false)
        check(amount==18,"9s zero->18")
        healing.advance(dt:3,armor:&amount,maximum:25,
                        playing:true,shipDown:false)
        check(amount==25,"12s zero->25")

        var clock=ArmorRegeneration609()
        var remaining=25
        remaining-=5
        clock.tookDamage(wasFull:true,now:remaining,maximum:25)
        clock.advance(dt:2.5,armor:&remaining,maximum:25,
                      playing:true,shipDown:false)
        check(remaining==20,"damage starts interval")
        remaining-=3
        clock.tookDamage(wasFull:false,now:remaining,maximum:25)
        clock.advance(dt:0.5,armor:&remaining,maximum:25,
                      playing:true,shipDown:false)
        check(remaining==23,"subsequent hit does not reset interval")
        clock.advance(dt:3,armor:&remaining,maximum:25,
                      playing:true,shipDown:false)
        check(remaining==25 && clock.elapsed==0 && clock.carry==0,
              "healing clamps and resets on full")
        remaining-=5
        clock.tookDamage(wasFull:true,now:remaining,maximum:25)
        clock.advance(dt:0.5,armor:&remaining,maximum:25,
                      playing:true,shipDown:false)
        check(remaining==20,"new hit after full starts fresh 3s")
        clock.advance(dt:2.5,armor:&remaining,maximum:25,
                      playing:true,shipDown:false)
        check(remaining==25,"first new full interval restores one quarter")

        remaining=0;clock.reset()
        clock.advance(dt:1,armor:&remaining,maximum:25,
                      playing:true,shipDown:false)
        clock.advance(dt:25,armor:&remaining,maximum:25,
                      playing:false,shipDown:false)
        clock.advance(dt:25,armor:&remaining,maximum:25,
                      playing:true,shipDown:true)
        check(remaining==0 && clock.elapsed<3,
              "menu, pause, hangar and downed freeze simulation clock")
        clock.advance(dt:2,armor:&remaining,maximum:25,
                      playing:true,shipDown:false)
        check(remaining==6,"resume preserves partial active 3s interval")

        remaining=0;clock.reset()
        for _ in 0..<359 {
            clock.advance(dt:1.0/120.0,armor:&remaining,maximum:25,
                          playing:true,shipDown:false)
        }
        check(remaining==0,"359 frames at 120 Hz do not heal early")
        clock.advance(dt:1.0/120.0,armor:&remaining,maximum:25,
                      playing:true,shipDown:false)
        check(remaining==6,"360th frame completes first interval")

        var vitals=CombatTalentVitals78(armorRank:1)
        var immunity:Float=0
        check(vitals.armor==40,"talent maximum=40")
        check(vitals.absorb(damage:5,cause:"ASTEROIDA",
            difficulty:.normal,invincible:&immunity),"hit accepted")
        vitals.advance(dt:3,playing:true,shipDown:false)
        check(vitals.armor==40 && vitals.hull==60,
              "real vitals' one quarter heals 10 and clamps at 40; hull stays")
        vitals.reset()
        check(vitals.armor==40,"respawn restores armor and resets clock")
    }

    static func main() {
        shields()
        armor()
        print("PASS IOS_PC608_PC609_SHIELD_ARMOR checks=\(checks)")
    }
}
