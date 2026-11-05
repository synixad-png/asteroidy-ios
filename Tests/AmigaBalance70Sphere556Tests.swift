import Foundation

/// Source audit: Windows/src/Balance70.cs RockHealth70/PrepareRock70;
/// Windows/src/AmigaBounce265.cs StepAmigaBounce265/ImpulseAmiga266;
/// Windows/src/Game.cs Wave/Split/Step and Action38.ConfigureActionSector.
@main struct AmigaBalance70Sphere556Tests {
    static func near(_ a:Float,_ b:Float,_ e:Float=0.001) {
        precondition(abs(a-b)<=e,"Expected \(b), got \(a)")
    }
    static func main() {
        var checked=0
        for level in 1...26 {
            for d in CombatBalance556.Difficulty.allCases {
                let c=CombatBalance556(level:level,difficulty:d,spherical:true)!
                let sample=SphereSector556(balance:c)
                precondition(sample.asteroids.count==c.sectorRockCount)
                for r in sample.asteroids {
                    let hp=c.sphericalRockHealth(size:3,tier:r.tier)
                    precondition(r.health==hp && r.maxHealth==hp)
                    precondition(r.originalHealth==
                                 Rock.healthFor(size:3,tier:r.tier))
                    near(r.radius,c.sphericalRockRadius(size:3))
                    near(r.mass,8)
                    if level==25 {
                        precondition(r.bounceHeight>=4 && r.bounceHeight<=21)
                        precondition(r.bounceVertical>=119 && r.bounceVertical<=190)
                    } else {
                        precondition(r.bounceHeight==0 && r.bounceVertical==0)
                    }
                }
                if level==25 {
                    precondition(sample.isAmigaDemo)
                    precondition(sample.incomingRocksLeft==0)
                    precondition(!sample.objectiveTimerComplete)
                    precondition(!sample.sectorFinished)
                } else {
                    precondition(!sample.isAmigaDemo)
                }
                checked+=1
            }
        }
        precondition(checked==78)

        // Balance70 exact original Pulse durability and co-op increment.
        let normal=CombatBalance556(level:1,difficulty:.normal,spherical:true)!
        precondition(normal.sphericalRockHealth(size:3,tier:0)==6)
        precondition(normal.sphericalRockHealth(size:2,tier:0)==4)
        precondition(normal.sphericalRockHealth(size:1,tier:0)==2)
        precondition(normal.sphericalRockHealth(size:3,tier:0,cooperative:true)==7)
        precondition(normal.sphericalRockHealth(size:2,tier:0,cooperative:true)==5)
        precondition(normal.sphericalRockHealth(size:1,tier:0,cooperative:true)==2)
        near(normal.sphericalRockRadius(size:3),31*1.12*0.52)
        near(normal.sphericalRockRadius(size:2,parentSize:3),18*1.12*0.49)
        near(normal.sphericalRockRadius(size:1,parentSize:2),10*1.12*0.39)
        let amigaBalance=CombatBalance556(level:25,difficulty:.normal,spherical:true)!
        near(amigaBalance.sphericalRockRadius(size:3),31*1.12*0.41)
        near(amigaBalance.sphericalRockRadius(size:2),18*1.12*0.57)
        near(amigaBalance.sphericalRockRadius(size:1),10*1.12*0.76)

        let coop=SphereSector556(balance:normal,cooperative:true)
        precondition(coop.asteroids.allSatisfy {
            $0.health==normal.sphericalRockHealth(size:3,tier:$0.tier,
                                                   cooperative:true)
        })

        // Native Dev265Tests.cs: per-ball rhythm and bounded vertical hop
        // over 850 steps, never touching any non-Amiga level's physics.
        var balls=[
            SphereAsteroid556(position:Vec2(x:200,y:280),
                velocity:Vec2(x:80,y:0),radius:18,shapeSeed:101),
            SphereAsteroid556(position:Vec2(x:630,y:290),
                velocity:Vec2(x:0,y:90),radius:18,
                size:2,shapeSeed:739),
            SphereAsteroid556(position:Vec2(x:310,y:340),
                velocity:Vec2(x:-75,y:32),radius:10,
                size:1,shapeSeed:981)
        ]
        var maxHeight=[Float](repeating:0,count:balls.count)
        var turns=[Int](repeating:0,count:balls.count)
        for i in balls.indices {AmigaBounce265.prepare(&balls[i])}
        for _ in 0..<850 {
            for i in balls.indices {
                let old=balls[i].velocity
                let oldCount=balls[i].bounceCount
                AmigaBounce265.step(&balls[i],dt:0.016)
                if balls[i].bounceCount>oldCount {
                    let denom=max(0.0001,sqrt(old.lengthSquared*
                                             balls[i].velocity.lengthSquared))
                    let dot=(old.x*balls[i].velocity.x+
                             old.y*balls[i].velocity.y)/denom
                    if dot<0.99 {turns[i]+=1}
                }
                balls[i].advance(dt:0.016)
                maxHeight[i]=max(maxHeight[i],balls[i].bounceHeight)
                precondition(balls[i].bounceHeight>=0 &&
                             balls[i].bounceHeight<=55.001)
            }
        }
        for i in balls.indices {
            precondition(balls[i].bounceCount>=5)
            precondition(turns[i]>=3)
            precondition(maxHeight[i]>20)
            precondition(balls[i].velocity.lengthSquared>=40*40)
        }

        // Amiga266Tests.cs: a shot does not destroy the ball, it restores
        // the real maxHealth and launches a hop, scoring exactly +10.
        var ball=SphereAsteroid556(position:Vec2(x:640,y:360),
            velocity:Vec2(x:0,y:0),radius:25,size:3,tier:0,
            health:amigaBalance.sphericalRockHealth(size:3,tier:0),
            originalHealth:1,shapeSeed:101)
        AmigaBounce265.prepare(&ball)
        let oldHealth=ball.maxHealth
        var demo=SphereSector556(balance:amigaBalance,
            diagnosticAsteroids:[ball],diagnosticIncomingQuota:9)
        precondition(demo.incomingRocksLeft==0 && !demo.sectorFinished)
        demo.fire(from:Vec2(x:605,y:360),direction:Vec2(x:1,y:0))
        _=demo.tick(dt:1/120,playerPosition:Vec2(x:640,y:360),
                     playerRadius:0,detectContacts:false)
        precondition(demo.amigaHits==1 && demo.score==10)
        precondition(demo.destroyedRocks==0 && demo.asteroids.count==1)
        precondition(demo.asteroids[0].health==oldHealth)
        precondition(demo.asteroids[0].bounceHeight>0)
        precondition(demo.asteroids[0].bounceVertical>0)
        precondition(demo.asteroids[0].velocity.lengthSquared>90*90)
        precondition(!demo.sectorFinished && !demo.sectorCleared)
        for _ in 0..<850 {
            _=demo.tick(dt:0.016,playerPosition:Vec2(x:640,y:360),
                         playerRadius:0,detectContacts:false)
        }
        precondition(demo.asteroids.count==1)
        precondition(!demo.sectorFinished && !demo.sectorCleared)
        precondition(demo.amigaHits==1 && demo.score==10)

        print("PASS: Balance70 spherical rock health/scale in 78 profiles, co-op durability, 850 Amiga bounce frames, immortal level 25 balls and source score")
    }
}
