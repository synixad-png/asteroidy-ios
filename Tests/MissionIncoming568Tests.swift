import Foundation
@main struct MissionIncoming568Tests {
 static func main() {
  var checks=0
  func check(_ good:Bool,_ message:String){precondition(good,message);checks+=1}
  let ship=Vec2(x:640,y:360),target=Vec2(x:640,y:420)
  for level in 1...25 {
   for diff in CombatBalance556.Difficulty.allCases {
    guard let wave=MissionWave568.generate(level:level,difficulty:diff,seed:33) else{fatalError("wave")}
    var step=MissionIncoming568(from:wave,difficulty:diff)
    let want=wave.initialReinforcements
    check(step.incomingLeft==want,"initial wave quota")
    let before=step.step(dt:0.1,isPlaying:false,ship:ship,activeRocks:10,activeEnemies:5,objectivePosition:target)
    check(before.isEmpty && step.sectorTime==0,"pause not stepping")
    if want>0 {
     let delay=wave.nextIncomingSeconds
     let early=step.step(dt:delay-0.1,isPlaying:true,ship:ship,activeRocks:10,activeEnemies:5,objectivePosition:target)
     check(early.isEmpty && step.incomingLeft==want,"wait for original spawn timer")
     let fired=step.step(dt:0.1,isPlaying:true,ship:ship,activeRocks:10,activeEnemies:5,objectivePosition:target)
     check(fired.count==min(2,want),"source max two reinforcements")
     check(step.incomingLeft==want-min(2,want),"remaining quota")
     check(fired.allSatisfy({sqrt(Sphere67.delta(target:$0.position,origin:ship).lengthSquared)>=259.9}),"safe spawn")
     check(fired.allSatisfy({$0.health>0 && $0.size==3}),"proper rock size and health")
     check(step.noticeTime==1.6,"source 1.6s notice")
     check(step.nextIncoming == step.sectorTime+(wave.objective == .waves ? 16:11),"time to next spawn")
    } else {
     check(step.step(dt:100,isPlaying:true,ship:ship,activeRocks:10,activeEnemies:5,objectivePosition:target).isEmpty,"empty quota")
    }
   }
  }
  let wave9=MissionWave568.generate(level:9,difficulty:.normal,seed:123)!
  check(wave9.objective == .waves,"survival objective")
  var survival=MissionIncoming568(from:wave9,difficulty:.normal)
  check(survival.step(dt:15.9,isPlaying:true,ship:ship,activeRocks:1,activeEnemies:1,objectivePosition:target).isEmpty,"survival ignores low-rock trigger")
  check(survival.step(dt:0.1,isPlaying:true,ship:ship,activeRocks:1,activeEnemies:1,objectivePosition:target).count==2,"survival spawns at 16")
  let wave5=MissionWave568.generate(level:5,difficulty:.normal,seed:45)!
  var defend=MissionIncoming568(from:wave5,difficulty:.normal)
  let arrivals=defend.step(dt:1,isPlaying:true,ship:ship,activeRocks:4,activeEnemies:1,objectivePosition:target)
  check(arrivals.count==2,"defend low rock trigger")
  let wave3=MissionWave568.generate(level:3,difficulty:.normal,seed:8)!
  var clear=MissionIncoming568(from:wave3,difficulty:.normal)
  check(clear.step(dt:100,isPlaying:true,ship:ship,activeRocks:0,activeEnemies:0,objectivePosition:target).isEmpty,"no spawns after clear")
  check(clear.incomingLeft==0,"clear zeroes quota")
  print("PASS \(checks) original Action38 SpawnIncoming/SectorTime regression checks")
 }
}
