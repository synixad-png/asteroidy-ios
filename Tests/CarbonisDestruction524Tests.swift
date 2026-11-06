import Foundation

@main struct CarbonisDestruction524Tests {
    static func main() {
        var checks=0
        func check(_ value:Bool,_ message:String) {
            precondition(value,message)
            checks+=1
        }
        let center=Vec2(x:640,y:350)
        func rock(_ size:Int)->SphereAsteroid556 {
            SphereAsteroid556(
                position:center,velocity:Vec2(x:12,y:4),
                radius:size==3 ? 34.72 : size==2 ? 20.16:11.2,
                size:size,tier:0,health:1)
        }
        for (size,count,scale) in [(3,27,Float(23)),
                                   (2,18,Float(15)),(1,18,Float(9))] {
            var state=CarbonisDestruction524()
            var rng=MissionWave568.SourceRandom(seed:42)
            state.rockDestroyed(rock(size),time:0.2,rng:&rng)
            check(state.particles.count==count,
                  "Game.Split source rock burst count size \(size)")
            check(state.particles.allSatisfy({
                $0.kind==0 && $0.life>=0.25 && $0.life<=0.8 &&
                sqrt($0.velocity.lengthSquared)>=34.999 &&
                sqrt($0.velocity.lengthSquared)<=200.01
            }),"original cyan rocks particle life and speed")
            check(state.lights.count==1 &&
                  state.lights[0].maxLife==0.9 &&
                  state.lights[0].kind==0,
                  "source cyan rock flash kind0 / .9 seconds")
            check(state.explosions.count==1 &&
                  state.explosions[0].scale==scale &&
                  state.explosions[0].kind==1,
                  "original asteroid V8.2 kind1 and scale 9/15/23")
            check(state.visibleExplosions(at:0.3).count==1,
                  "source event 3D raymarch lifetime begins at death")
            check(state.nearDestruction(center,time:0.3),
                  "original volume suppresses duplicate old light ring")
            check(!state.nearDestruction(
                Vec2(x:900,y:360),time:0.3),
                "unrelated distant original light ring remains")
            let mesh=CarbonisExplosion524Meshes.vertices(
                state,time:0.3,
                camera:SphereCamera67(at:center))
            check(!mesh.isEmpty && mesh.count%12==0 &&
                  mesh.allSatisfy{$0.isFinite},
                  "source particles and 35 explosion shards have valid 3D mesh")
            state.tick(dt:0.95)
            check(state.particles.isEmpty &&
                  state.lights.allSatisfy({$0.life==0}),
                  "source burst/lights expire independently of visual volume")
            check(state.visibleExplosions(at:4.6).isEmpty,
                  "source 4.2 second gameplay volume bounded")
        }
        do {
            var fx=CarbonisDestruction524()
            var rng=MissionWave568.SourceRandom(seed:19)
            fx.rockHit(rock(2),rng:&rng)
            check(fx.particles.count==3 &&
                  fx.lights.count==1 &&
                  fx.lights[0].maxLife==0.13 &&
                  fx.explosions.isEmpty,
                  "nonfatal rock pulse adds 3 cyan particles + .13s light, no blast")
        }
        do {
            var fx=CarbonisDestruction524()
            var rng=MissionWave568.SourceRandom(seed:17)
            fx.shooterHit(at:center,
                          impactPoint:Vec2(x:638,y:349),
                          velocity:Vec2(x:600,y:0),
                          momentum:Vec2(x:30,y:-4),
                          defeated:true,time:2.0,rng:&rng)
            check(fx.particles.count==22 &&
                  fx.particles.allSatisfy{$0.kind==1},
                  "source HitBug fatal blast emits 22 orange particles")
            check(fx.pieces.count==17 &&
                  fx.pieces.filter({$0.kind==0}).count==6 &&
                  fx.pieces.filter({$0.kind==2}).count==11,
                  "source HitBug impact 6 sparks plus 11 true metallic fragments")
            check(fx.lights.count==3 &&
                  fx.lights.map{$0.maxLife}==[0.13,0.72,0.3],
                  "source impact, BreakApart125 and explosion light timings")
            check(fx.explosions.count==1 &&
                  fx.explosions[0].kind==0 &&
                  fx.explosions[0].scale==14 &&
                  fx.explosions[0].spawned==2,
                  "source HitBug V8.2 fuel explosion kind0 scale14")
            check(fx.pieces.allSatisfy({
                  $0.life>0 && $0.maxLife>0 && $0.size>0 }),
                  "all original metal debris has finite physical size/lifetime")
            let image=CarbonisExplosion524Meshes.vertices(
                fx,time:2.4,camera:SphereCamera67(at:center))
            check(!image.isEmpty && image.count%12==0,
                  "render all 22 flame particles and twelve-facet metal fragments")
            check(image.allSatisfy{$0.isFinite},
                  "3D sphere renderer has no NaN or infinite effect vertices")
            fx.tick(dt:2.11)
            check(fx.particles.isEmpty && fx.pieces.isEmpty,
                  "source sparks and free-flying metal debris expire")
        }
        do {
            var fx=CarbonisDestruction524()
            var rng=MissionWave568.SourceRandom(seed:17)
            fx.shooterHit(at:center,impactPoint:center,
                          velocity:Vec2(x:100,y:0),
                          momentum:Vec2(x:0,y:0),
                          defeated:false,time:1,rng:&rng)
            check(fx.particles.count==3 && fx.pieces.count==6 &&
                  fx.lights.count==1 && fx.explosions.isEmpty,
                  "original nonfatal fighter hit never generates death cloud")
        }
        do {
            var fx=CarbonisDestruction524()
            for i in 0..<40 {
                fx.explosion(at:center,kind:1,scale:23,
                             time:Float(i)*0.01)
            }
            check(fx.explosions.count==32 &&
                  fx.visibleExplosions(at:0.4).count==3 &&
                  fx.visibleExplosions(at:0.4).map{$0.spawned}
                    == [0.39,0.38,0.37],
                  "exact fixed 32-event ring and newest-first gameplay cap3")
            var rng=MissionWave568.SourceRandom(seed:2)
            fx.burst(at:center,count:600,kind:1,rng:&rng)
            check(fx.particles.count==512,
                  "source Game.MaxParticles=512 hard cap")
        }
        do {
            let noise=CarbonisExplosionNoise524.originalBytes()
            check(noise.count==262144 &&
                  Array(noise.prefix(16))==
                  [132,115,213,242,193,41,90,88,20,228,61,160,71,45,110,76],
                  "literal source Explosion524 C# Xorshift seed and 16 byte prefix")
            check(noise.reduce(0) {$0+Int($1)}==33412184,
                  "source 64^3 8-bit GPU volume content full checksum")
            check(CarbonisExplosion524Meshes.hash524(1)>0 &&
                  CarbonisExplosion524Meshes.hash524(1)<1,
                  "source deterministic 3D shrapnel angle hash")
        }
        print("PASS \(checks) source v568 asteroid/fighter destruction, 3D metal fragments, GPU-volume events, xorshift noise, caps and lifetime assertions")
    }
}