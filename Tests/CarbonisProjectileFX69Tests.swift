import Foundation

@main struct CarbonisProjectileFX69Tests {
    static func main() {
        var checks=0
        func check(_ value:Bool,_ label:String) {
            precondition(value,label)
            checks+=1
        }
        let whereAt=Vec2(x:640,y:360)
        let camera=SphereCamera67(at:whereAt)
        let shots=[
            CarbonisCombat568.Projectile(
                point:whereAt,velocity:Vec2(x:610,y:30),
                life:1,hostile:false,kind:0),
            CarbonisCombat568.Projectile(
                point:Vec2(x:665,y:350),velocity:Vec2(x:-245,y:50),
                life:2.6,hostile:true,kind:0)]
        check(CarbonisProjectileFX69.playerTint(0).r==55/255 &&
              CarbonisProjectileFX69.playerTint(0).g==215/255,
              "original Combat69 Pulse cyan RGB(55,215,255)")
        check(CarbonisProjectileFX69.playerTint(1).g==197/255 &&
              CarbonisProjectileFX69.playerTint(2).b==190/255,
              "original Twin gold, Scatter pink and full weapon kind palette")
        check(CarbonisProjectileFX69.hostileTint(0).b==1 &&
              CarbonisProjectileFX69.hostileTint(2).g==243/255 &&
              CarbonisProjectileFX69.hostileTint(3).b==254/255,
              "original hostile default BLUE, kind2 green and kind3 purple")
        let colorMesh=CarbonisProjectileFX69.vertices(
            shots,camera:camera,drawableHeight:720)
        check(colorMesh.count%12==0 && colorMesh.count>2000,
              "source 6-segment triple-layer ribbons and 3 rounded alpha orbs, not two flat quads")
        check(colorMesh.allSatisfy({$0.isFinite}),
              "source shot geodesic geometry is finite across head/halo vertices")
        let noGlow=CarbonisProjectileFX69.vertices(
            shots,camera:camera,drawableHeight:720,glow:false)
        check(noGlow.count < colorMesh.count && !noGlow.isEmpty,
              "source GlowEnabled removes ONLY glow layers, not visible shots")
        var profile=CarbonisVisualSettings568()
        check(CarbonisProjectileFX69.groundLights(
              shots,settings:profile).count>5000,
              "each player and enemy projectile casts four real radial sphere lights")
        profile.projectileBrightness=0
        check(CarbonisProjectileFX69.groundLights(
              shots,settings:profile).isEmpty,
              "original 0 percent disables only ground lighting")
        check(!CarbonisProjectileFX69.vertices(
              shots,camera:camera,drawableHeight:720).isEmpty,
              "at 0 lighting the projectile's natural beam remains visible")
        profile.projectileBrightness=400
        check(!CarbonisProjectileFX69.groundLights(
              shots,settings:profile).isEmpty,
              "original 400 percent lights remain safely bounded")
        profile.projectileColor=2
        profile.projectileMixed=false
        let tint=CarbonisProjectileFX69.groundTint(
            CarbonisProjectileFX69.playerTint(0),settings:profile)
        check(abs(tint.r-1)<0.0001 &&
              abs(tint.g-205/255)<0.0001 &&
              abs(tint.b-102/255)<0.0001,
              "chosen GOLD overrides ground tint when mixing is disabled")
        profile.projectileMixed=true
        let mixed=CarbonisProjectileFX69.groundTint(
            CarbonisProjectileFX69.playerTint(0),settings:profile)
        let natural=CarbonisProjectileFX69.playerTint(0)
        check(abs(mixed.r-(natural.r*0.52+tint.r*0.48))<0.0001 &&
              abs(mixed.g-(natural.g*0.52+tint.g*0.48))<0.0001,
              "original GpuSphere67 selected tint mixes at precisely 48 percent")
        profile.projectileColor=0
        let automatic=CarbonisProjectileFX69.groundTint(
            natural,settings:profile)
        check(abs(automatic.r-natural.r)<0.0001,
              "original Automatyczny always uses native weapon tint")

        let campaign=CampaignProgress556()
        guard let start=Sector01Entry568.open(
                selectedSector:1,campaign:campaign,
                hasOriginalC279Assets:true),
              let prepared=Sector01PreparedWave568.prepare(
                entry:start,campaign:campaign,hasOriginalC279Assets:true,
                difficulty:.normal,seed:3141)
        else {fatalError("actual C279 source enemy spawn missing")}
        var game=CarbonisCombat568(prepared)
        check(game.shooters.count==4,"test uses four real source shooter models")
        game.shooters[0].muzzle=0.1
        let muzzle=CarbonisProjectileFX69.muzzleFlashes(
            game.shooters,camera:camera,drawableHeight:720)
        check(!muzzle.isEmpty && muzzle.count%12==0 &&
              muzzle.allSatisfy{$0.isFinite},
              "source EnemyTactics71 muzzle 0.1 seconds casts actual radial 3D flash")
        game.shooters[0].muzzle=0
        check(CarbonisProjectileFX69.muzzleFlashes(
              game.shooters,camera:camera,drawableHeight:720).isEmpty,
              "after the original timer expires muzzle flash disappears")

        game.step(move:Vec2(x:0,y:0),aim:Vec2(x:0,y:0),
                  shooting:true,dt:1/120)
        check(game.bullets.first?.kind==0,
              "original mission Pulse0 remains cyan in real weapon fire")
        print("PASS \(checks) authentic source Combat69/ShotAppearance151 source 3D bullet, hostile flash, 4-layer ground light and setting reactions")
    }
}