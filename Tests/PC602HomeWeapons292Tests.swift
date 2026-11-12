import Foundation

guard CommandLine.arguments.count==2 else {
    fatalError("Use the SHA-verified original H290 height map")
}
let source=try Data(contentsOf:
    URL(fileURLWithPath:CommandLine.arguments[1]))
let home=try PC602NewHome290(heightMapBytes:source)
let equipment=PC602HomeFlight291.Equipment(craft:.vanguard)!
let flight=try PC602HomeFlight291(home:home,equipment:equipment)
let ship=flight.flight

func expect(_ actual:Float,_ expected:Float,
            tolerance:Float=0.0002,_ why:String) {
    assert(actual.isFinite && abs(actual-expected)<=tolerance,
           "\(why): expected \(expected), found \(actual)")
}
for weapon in PC602HomeWeaponTest292.Weapon.allCases {
    guard let setting=PC602HomeWeaponTest292.Settings(weapon:weapon)
    else {fatalError("All original five guns must be constructible")}
    var test=PC602HomeWeaponTest292(settings:setting)
    test.step(ship:ship,dt:1/60,fire:true)
    let expected=weapon == .twin ? 2:
        weapon == .scatter || weapon == .swarm ? 3:1
    assert(test.projectiles.count==expected)
    assert(test.emissions==1)
    expect(test.cooldown,setting.interval,tolerance:0.000001,
           "Original source first Fire cooldown")
    for bullet in test.projectiles {
        assert(bullet.kind == weapon)
        expect(bullet.life,weapon == .swarm ? 1.8-1/60:1.05-1/60,
               tolerance:0.000001,"Original per-gun lifetime")
        assert(bullet.position.x.isFinite && bullet.position.y.isFinite)
        assert(bullet.velocity.x.isFinite && bullet.velocity.y.isFinite)
        let n=Sphere67.normal(bullet.position)
        assert(n.length>0.999)
        let speed=sqrt(bullet.velocity.lengthSquared)
        let wanted:Float=weapon == .rail ? 1050:610
        expect(speed,wanted,tolerance:0.5,
               "Sphere67 transported source shot speed")
    }
    for _ in 0..<8 {test.step(ship:ship,dt:1/60,fire:false)}
    assert(test.emissions==1)
    assert(test.projectiles.count==expected)
    for _ in 0..<120 {test.step(ship:ship,dt:1/60,fire:false)}
    assert(test.projectiles.isEmpty,"No phantom persistent shots after expiry")
}
let scatter=PC602HomeWeaponTest292.Settings(weapon:.scatter,upgrade:3)!
var five=PC602HomeWeaponTest292(settings:scatter)
five.step(ship:ship,dt:1/60,fire:true)
assert(five.projectiles.count==5)
assert(five.projectiles.filter {$0.pierce==2}.count==1)
let twin=PC602HomeWeaponTest292.Settings(weapon:.twin)!
var two=PC602HomeWeaponTest292(settings:twin)
two.step(ship:ship,dt:1/60,fire:true)
assert(two.projectiles.count==2)
assert(Sphere67.delta(target:two.projectiles[0].position,
                      origin:two.projectiles[1].position).lengthSquared>100)
let heavy=PC602HomeWeaponTest292.Settings(weapon:.rail,upgrade:3)!
var rail=PC602HomeWeaponTest292(settings:heavy)
rail.step(ship:ship,dt:1/60,fire:true)
assert(rail.projectiles[0].damage==4 && rail.projectiles[0].pierce==4)
expect(rail.settings.interval,0.28,tolerance:0.00001,
       "Original upgraded Gauss cooldown")
let rapid=PC602HomeWeaponTest292.Settings(
    weapon:.pulse,upgrade:1,rapid:2,cooling:2)!
expect(rapid.interval,0.16/1.30*0.88,tolerance:0.0001,
       "Original Modules97 CoolingRank + rapid purchased profile")
assert(PC602HomeWeaponTest292.Settings(
    weapon:.pulse,upgrade:5)==nil)
assert(PC602HomeWeaponTest292.Settings(
    weapon:.pulse,cooling:3)==nil)
assert(PC602HomeWeaponTest292.Settings(
    weapon:.pulse,cooling:2) != nil)

// O03: the original PC602 Game.Fire() uses ConsumeIon() ONCE PER
// volley and adds +1 to the damage of EACH created Bullet.  However,
// HomeFlight291.StepHomeWeaponTest292 saves/restores IonAmmo around
// Game.Fire(), so testing on H290 does NOT spend ion ammo.
// Check 0 vs 1 vs 300 charges, ALL FIVE guns, including scatter 5-shot.
for kind in PC602HomeWeaponTest292.Weapon.allCases {
    for upgrade in 1...3 {
        let without=PC602HomeWeaponTest292.Settings(
            weapon:kind,upgrade:upgrade,ionAmmo:0)!
        let one=PC602HomeWeaponTest292.Settings(
            weapon:kind,upgrade:upgrade,ionAmmo:1)!
        let full=PC602HomeWeaponTest292.Settings(
            weapon:kind,upgrade:upgrade,ionAmmo:300)!
        var normal=PC602HomeWeaponTest292(settings:without)
        var ion=PC602HomeWeaponTest292(settings:one)
        var charged=PC602HomeWeaponTest292(settings:full)
        for _ in 0..<3 {
            // 2 seconds guarantees the original cooldown has expired
            // and any prior bullet lifetime on the empty test range.
            normal.step(ship:ship,dt:0.05,fire:true)
            ion.step(ship:ship,dt:0.05,fire:true)
            charged.step(ship:ship,dt:0.05,fire:true)
            assert(normal.projectiles.count==ion.projectiles.count)
            assert(normal.projectiles.count==charged.projectiles.count)
            for i in normal.projectiles.indices {
                assert(ion.projectiles[i].damage == normal.projectiles[i].damage+1)
                assert(charged.projectiles[i].damage == normal.projectiles[i].damage+1)
                assert(ion.projectiles[i].pierce == normal.projectiles[i].pierce)
                assert(charged.projectiles[i].pierce == normal.projectiles[i].pierce)
            }
            // Practice salvos preserve exactly their original charge count.
            assert(ion.settings.ionAmmo==1)
            assert(charged.settings.ionAmmo==300)
            for _ in 0..<45 {
                normal.step(ship:ship,dt:0.05,fire:false)
                ion.step(ship:ship,dt:0.05,fire:false)
                charged.step(ship:ship,dt:0.05,fire:false)
            }
        }
        assert(normal.emissions==3 && ion.emissions==3 && charged.emissions==3)
    }
}
assert(PC602HomeWeaponTest292.Settings(weapon:.pulse,ionAmmo:-1)==nil)
assert(PC602HomeWeaponTest292.Settings(weapon:.pulse,ionAmmo:301)==nil)

// O03: independent numerical expectations transcribed directly from the
// SHA-verified ORIGINAL PC602 Game.cs:123–133, Modules97.cs:15,
// Talents78.cs:23 and HomeFlight291.cs:55–62.
// 5 guns × 3 power × 3 rapid × 3 cooling × 3 talent × 2 ion = 810 cases.
// All reference values below are calculated without invoking the tested
// Swift ShotIntervalBase97 / emit implementations.
var validatedOriginalFireCases=0
for kind in PC602HomeWeaponTest292.Weapon.allCases {
    for power in 1...3 {
        for rapidRank in 0...2 {
            for coolingRank in 0...2 {
                for talentRank in 0...2 {
                    let originalTalent:Float=1 / (1 + Float(talentRank) * 0.06)
                    // Original C# Vanguard FireRateScale is 1.0.
                    let originalBase:Float
                    switch kind {
                    case .rail:
                        originalBase=originalTalent *
                            (0.32 - 0.02 * Float(power-1)) /
                            (1 + Float(rapidRank) * 0.15)
                    case .swarm:
                        originalBase=originalTalent *
                            (0.29 - 0.015 * Float(power-1)) /
                            (1 + Float(rapidRank) * 0.15)
                    case .pulse,.twin,.scatter:
                        let initial:Float=kind == .scatter ? 0.31 :
                                          kind == .twin ? 0.20 : 0.16
                        let step:Float=kind == .scatter ? 0.03 : 0.02
                        originalBase=max(0.075,
                            (initial-step*Float(power-1)) /
                            (1 + Float(rapidRank) * 0.15) *
                            originalTalent)
                    }
                    let originalInterval=max(Float(0.065),
                        originalBase * (1 - Float(coolingRank) * 0.06))
                    let originalCount=kind == .swarm ? 3 :
                        kind == .twin ? 2 :
                        kind == .scatter ? (power == 3 ? 5 : 3) : 1
                    let originalLaunchSpeed:Float=kind == .rail
                        ? 1050 : 610 + Float(power-1) * 95
                    let originalLife:Float=kind == .swarm ? 1.8 : 1.05
                    for ionCharge in 0...1 {
                        guard let setting=PC602HomeWeaponTest292.Settings(
                            weapon:kind,upgrade:power,
                            rapid:rapidRank,cooling:coolingRank,
                            fireRateTalent:originalTalent,
                            ionAmmo:ionCharge) else {
                            fatalError("Original PC602 legal gun state rejected")
                        }
                        expect(setting.interval,originalInterval,
                               tolerance:0.00015,
                               "O03 original C# independent ShotInterval")
                        var simulation=PC602HomeWeaponTest292(settings:setting)
                        simulation.step(ship:ship,dt:1/60,fire:true)
                        assert(simulation.emissions==1)
                        assert(simulation.projectiles.count==originalCount)
                        for index in 0..<originalCount {
                            let shot=simulation.projectiles[index]
                            let baseDamage=kind == .rail ? 4 :
                                (kind == .pulse && power == 3 ? 2 : 1)
                            let expectedPierce=kind == .rail ? 4 :
                                (power == 3 &&
                                  (kind != .scatter || index == originalCount/2)
                                    ? 2 : 1)
                            assert(shot.damage == baseDamage+ionCharge,
                                   "O03 source ion +1 per bullet")
                            assert(shot.pierce == expectedPierce,
                                   "O03 original C# pierce pattern")
                            expect(shot.life,originalLife-1/60,
                                   tolerance:0.00015,
                                   "O03 source WorldAdvance67 shot life")
                            expect(sqrt(shot.velocity.lengthSquared),
                                   originalLaunchSpeed,tolerance:0.5,
                                   "O03 source bullet geodesic speed")
                        }
                        assert(simulation.settings.ionAmmo==ionCharge)
                        validatedOriginalFireCases+=1
                    }
                }
            }
        }
    }
}
assert(validatedOriginalFireCases==810)

guard let camera=PC602HomeWorldView291(
    camera:ship.camera,aspect:16.0/9.0) else {
    fatalError("Original PC602 400m sphere camera must project shots")
}
var visual=[Float]()
let cameraEye=SIMD3<Float>(ship.camera.focus.x,
                          ship.camera.focus.y,
                          ship.camera.focus.z)*400
let ribbonVertices=PC602HomeShotGeometry292.build(
    home:home,bullets:five.projectiles,
    camera:cameraEye,view:camera.view,into:&visual)
assert(ribbonVertices==5*PC602HomeShotGeometry292.ribbonVerticesPerShot)
assert(visual.count==5*PC602HomeShotGeometry292.verticesPerShot*7)
assert(visual.allSatisfy{$0.isFinite})
// First outer OrbDisc150 ring has original premultiplied alpha zero.
// Its next source inner ring has original weapon RGB * 48/255.
let orbStart=ribbonVertices*7
expect(visual[orbStart+6],0,tolerance:0.000001,
       "Source ring outer alpha zero")
expect(visual[orbStart+7+6],48/255,tolerance:0.000001,
       "Source ring inner 48-alpha halo")
expect(visual[orbStart+7+3],48/255,tolerance:0.000001,
       "Premultiplied source scatter-red halo")
expect(visual[3],255/255,tolerance:0.0001,
       "Original scatter RGB source shot tint red")
expect(visual[4],92/255,tolerance:0.0001,
       "Original scatter RGB source shot tint green")
expect(visual[6],27/255,tolerance:0.0001,
       "Original source 27-alpha halo")
let capacity=visual.capacity
let emptyVertices=PC602HomeShotGeometry292.build(
    home:home,bullets:[],camera:cameraEye,
    view:camera.view,into:&visual)
assert(emptyVertices==0)
assert(visual.isEmpty && visual.capacity>=capacity)
print("PASS source PC602 HomeShotPass292: five genuine weapon patterns, " +
      "1/3/5 shot spreads, source cooldowns, 67 geodesic speed, " +
      "timed expiry, no fake score or hit; RGB/alpha/3-layer " +
      "terrain-following original Combat69 ribbon vertices")
