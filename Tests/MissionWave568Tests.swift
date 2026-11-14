import Foundation

@main struct MissionWave568Tests {
 static func main() {
   var checks=0
   func ok(_ condition:Bool,_ label:String){precondition(condition,label);checks += 1}
   var rng=MissionWave568.SourceRandom(seed:1)
   ok(rng.next()==534011718,"C# Random(1).Next first golden")
   ok(rng.next()==237820880,"C# Random(1).Next second golden")
   ok(rng.next()==1002897798,"C# Random(1).Next third golden")
   for lvl in 1...25 {
     for d in CombatBalance556.Difficulty.allCases {
       guard let snap=MissionWave568.generate(level:lvl,difficulty:d,seed:12345) else{fatalError("wave missing")}
       let b=CombatBalance556(level:lvl,difficulty:d,spherical:true)!
       ok(snap.rocks.count == b.sectorRockCount,"C# rock count")
       ok(snap.rocks.allSatisfy({$0.health == b.sphericalRockHealth(size:3,tier:$0.tier)}),"C# rock HP")
       ok(snap.rocks.allSatisfy({sqrt(Sphere67.delta(target:$0.position,origin:Vec2(x:640,y:360)).lengthSquared)>=259.99}),"rock safe spawn")
       ok(snap.rocks.enumerated().allSatisfy({ b.tier(at:$0.offset)==$0.element.tier }),"rock tier")
       ok(snap.fighters.count == (lvl==25 ? 0:MissionWave568.shooterCount(lvl,d)),"source shooter count")
       ok(snap.robots.count == (lvl==25 ? 0:MissionWave568.robotCount(lvl,d)),"source robot count")
       ok(snap.robots.allSatisfy({$0.rings.count==6+min(6,max(0,(lvl-3)/3))}),"snake rings")
       ok(snap.robots.allSatisfy({$0.rings.allSatisfy({$0.hp==2+d.rawValue+(lvl>=13 ? 1:0)+(lvl>=21 ? 1:0)})}),"snake armor")
       ok(snap.initialReinforcements == (lvl==25 ? 0 : MissionWave568.initialQuota(level:lvl,difficulty:d,objective:MissionWave568.objective(lvl))),"wave reinforcements")
       ok(snap.nextIncomingSeconds == (MissionWave568.objective(lvl)==(.waves) ? 16 : 12),"reinforcement time")
       ok(!snap.playable,"no invented playable flag")
       guard let again=MissionWave568.generate(level:lvl,difficulty:d,seed:12345) else{fatalError("not deterministic")}
       ok(again.rocks.map(\.shapeSeed) == snap.rocks.map(\.shapeSeed),"deterministic C# wave")
     }
   }
   let first=MissionWave568.generate(level:1,difficulty:.normal,seed:1)!
   ok(first.rocks.count==13,"CARBONIS 13 asteroids")
   ok(first.fighters.count==4,"CARBONIS 4 armed fighters")
   ok(first.robots.isEmpty,"CARBONIS no robot")
   ok(first.initialReinforcements==0,"CARBONIS 0 reinforcement")
   // Source BOREAS 05 must include every generated actor and the defense
   // objective. A native port may not silently discard the RobotSnake.
   let boreas=MissionWave568.generate(level:5,difficulty:.normal,seed:1)!
   ok(boreas.sector==5,"BOREAS authentic sector")
   ok(boreas.objective == .defend,"BOREAS defense objective")
   ok(boreas.fighters.count == MissionWave568.shooterCount(5,.normal),
      "BOREAS all shooter actors")
   ok(boreas.robots.count == MissionWave568.robotCount(5,.normal),
      "BOREAS original RobotSnake cannot be omitted")
   ok(!boreas.robots.isEmpty,"BOREAS requires real RobotSnake runtime")
   ok(MissionWave568.generate(level:26,difficulty:.normal,seed:1)==nil,"PC campaign excludes atlas entry 26")
   ok(MissionWave568.generate(level:0,difficulty:.normal,seed:1)==nil,"invalid level")
   print("PASS \(checks) source Wave568 spawn, fighters, snakes, quotas, C# seed checks")
 }
}
