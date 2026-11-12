import Foundation

// Source references:
// PC v602 Windows/src/Campaign37.cs, Physics68.cs, FlightDynamics298.cs,
// SphereCombat67.cs, HomeFlight291.cs, Orbit50.cs and OrbitWorld51.cs.
// All geometry is loaded from the exact GitHub-staged PC602 H290 binary.
func close(_ actual:Float,_ expected:Float,_ tolerance:Float,_ label:String) {
    guard actual.isFinite,abs(actual-expected)<=tolerance else {
        fatalError("\(label): received \(actual), PC602 expected \(expected)")
    }
}
func length(_ v:SIMD3<Float>)->Float {sqrt(v.x*v.x+v.y*v.y+v.z*v.z)}
func normal(_ v:SIMD3<Float>)->SIMD3<Float> {v/length(v)}
func dot(_ a:SIMD3<Float>,_ b:SIMD3<Float>)->Float {
    a.x*b.x+a.y*b.y+a.z*b.z
}
func equipment(_ craft:PC602HomeFlight291.Craft,
               detached:Bool=false)->PC602HomeFlight291.Equipment {
    guard let result=PC602HomeFlight291.Equipment(
        craft:craft,miningDetached:detached) else {
        fatalError("Valid original PC602 craft configuration rejected")
    }
    return result
}

guard CommandLine.arguments.count==2 else {
    fatalError("Usage: home-flight-test PC602Home290HeightMap.bin")
}
let home=try PC602NewHome290(
    heightMapBytes:Data(contentsOf:URL(
        fileURLWithPath:CommandLine.arguments[1])))

// PC v602 Campaign37.TopSpeed * Physics68.SurfaceSpeed68:
let expected:[(PC602HomeFlight291.Craft,Float,Float)]=[
    (.kestrel,174.72,2.4),(.vanguard,156,3.4),
    (.bastion,134.16,5),(.vanguardX,145.08,6.2),
    (.titan,118.56,10),(.mammoth,109.2,12.5),
]
for (craft,speed,mass) in expected {
    let eq=equipment(craft)
    close(eq.surfaceSpeed,speed,0.005,"\(craft) source speed")
    close(eq.mass,mass,0.0001,"\(craft) source mass")
    let start=try PC602HomeFlight291(home:home,equipment:eq)
    assert(start.target==1)
    assert(start.orbitTime==0)
    assert(start.orbitSpeed==0)
    close(length(start.orbitCamera),400,0.04,"original 400m camera")
    guard let radius=home.surface(start.orbitPosition) else {
        fatalError("NewHome original surface not loaded")
    }
    close(length(start.orbitPosition),radius+12,0.04,"source 12m altitude")
    close(dot(normal(start.orbitPosition),start.orbitForward),
          0,0.03,"source tangent ship heading")
    close(dot(normal(start.orbitPosition),start.orbitRight),
          0,0.03,"source tangent ship right")
}
// O02: all purchased levels 0..2 are those of PC602 Campaign37.cs
// (Acceleration / TopSpeed / TurnSpeed), Physics68.SurfaceSpeed68 and
// FlightDynamics298.DirectMotion298. Do not create additional craft.
for engine in 0...2 {
    for thruster in 0...2 {
        for stabilizer in 0...2 {
            guard let eq=PC602HomeFlight291.Equipment(
                craft:.vanguard,engineLevel:engine,
                thrusterRank:thruster,stabilizerLevel:stabilizer)
            else {fatalError("Valid PC602 Vanguard upgrades rejected")}
            let acceleration:Float=245 * (1 + Float(engine) * 0.06) *
                (1 + Float(thruster) * 0.045)
            let topSpeed:Float=390 * (1 + Float(engine) * 0.035) *
                (1 + Float(thruster) * 0.025)
            let turnSpeed:Float=3.8 * (1 + Float(stabilizer) * 0.04)
            let massFactor:Float=sqrt(3.4/3.4)
            let control=(1 + Float(stabilizer) * 0.12) *
                max(0.55,min(1.6,acceleration/245)) * massFactor
            close(eq.acceleration,acceleration,0.0002,"O02 original PC acceleration")
            close(eq.topSpeed,topSpeed,0.0002,"O02 original PC top speed")
            close(eq.surfaceSpeed,topSpeed*0.40,0.0002,"O02 source 40% speed")
            close(eq.turnSpeed,turnSpeed,0.00002,"O02 PC stabilizer turn")
            close(eq.flightConfiguration.control,control,0.0002,
                  "O02 DirectMotion298 live control")
            var tick=try PC602HomeFlight291(home:home,equipment:eq)
            try tick.step(.init(move:Vec2(x:0,y:-1)),dt:1/60)
            let expectedSpeed=eq.surfaceSpeed *
                (1 - exp(-Float(3) * control/60))
            close(tick.orbitSpeed,expectedSpeed,0.08,
                  "O02 source first tick with purchased upgrades")
        }
    }
}
// PC engine reads upgraded source properties immediately after H55,
// without restarting the orbit or resetting momentum/camera/time.
var baseline=try PC602HomeFlight291(home:home,equipment:equipment(.vanguard))
var live=baseline
try baseline.step(.init(move:Vec2(x:0,y:-1)),dt:1/60)
try live.step(.init(move:Vec2(x:0,y:-1)),dt:1/60)
let preservedPosition=live.orbitPosition
let preservedSpeed=live.orbitSpeed
let preservedHeading=live.flight.heading
let preservedTime=live.orbitTime
let high=PC602HomeFlight291.Equipment(
    craft:.vanguard,engineLevel:2,thrusterRank:2,stabilizerLevel:2)!
assert(live.adoptVanguardEquipment(high))
assert(live.equipment.engineLevel==2)
assert(live.orbitPosition==preservedPosition)
assert(live.orbitSpeed==preservedSpeed)
assert(live.flight.heading==preservedHeading)
assert(live.orbitTime==preservedTime)
assert(!live.adoptVanguardEquipment(equipment(.kestrel)))
try baseline.step(.init(move:Vec2(x:0,y:-1)),dt:1/60)
try live.step(.init(move:Vec2(x:0,y:-1)),dt:1/60)
assert(live.orbitSpeed>baseline.orbitSpeed,
       "O02 upgrades must affect the immediately following live orbit tick")

let detached=equipment(.mammoth,detached:true)
close(detached.surfaceSpeed,180.96,0.005,"MAMMOTH shuttle speed")
close(detached.mass,1.5,0.0001,"MAMMOTH shuttle mass")
close(detached.flightConfiguration.coastRateMultiplier,1.25,0.0001,
      "source shuttle drag")
close(equipment(.vanguardX).flightConfiguration.coastRateMultiplier,
      0.75,0.0001,"source Vanguard X drift")
close(equipment(.titan).flightConfiguration.bankBuildRate,
      6.3*0.5,0.0001,"source Titan bank inertia")

// Original DirectMotion298 at 1/60s: 156 * (1-exp(-3/60)).
var flight=try PC602HomeFlight291(
    home:home,equipment:equipment(.vanguard))
guard let dock=home.wreckPosition() else {
    fatalError("NewHome source docking wreck is absent")
}
close(length(flight.dockPosition-dock),0,0.001,
      "physical dock point must always come from original NewHome290")
close(flight.dockDistance,length(flight.orbitPosition-dock),0.02,
      "dock distance must be initialized before the first flight tick")
let eligible=PC602HomeFlight291.DockContext(
    planetHub:true,orbitMode:true)
assert(PC602HomeFlight291.canDock90(
    distance:43.1,miningDetached:false,context:eligible))
assert(PC602HomeFlight291.canDock90(
    distance:43.2,miningDetached:false,context:eligible))
assert(!PC602HomeFlight291.canDock90(
    distance:43.3,miningDetached:false,context:eligible))
assert(!PC602HomeFlight291.canDock90(
    distance:0,miningDetached:true,context:eligible))
assert(!PC602HomeFlight291.canDock90(
    distance:0,miningDetached:false,
    context:.init(planetHub:false,orbitMode:true)))
assert(!PC602HomeFlight291.canDock90(
    distance:0,miningDetached:false,
    context:.init(planetHub:true,orbitMode:false)))
assert(!PC602HomeFlight291.canDock90(
    distance:0,miningDetached:false,
    context:.init(planetHub:true,orbitMode:true,sceneBusy:true)))
assert(!PC602HomeFlight291.canDock90(
    distance:0,miningDetached:false,
    context:.init(planetHub:true,orbitMode:true,talentOpen:true)))
assert(!PC602HomeFlight291.canDock90(
    distance:Float.nan,miningDetached:false,context:eligible))
assert(!PC602HomeFlight291.canDock90(
    distance:-1,miningDetached:false,context:eligible))
assert(flight.canDock90(context:eligible) ==
    PC602HomeFlight291.canDock90(
        distance:flight.dockDistance,miningDetached:false,context:eligible))
try flight.step(.init(move:Vec2(x:0,y:-1),
                      aim:Vec2(x:0,y:0)),
                dt:1.0/60.0)
close(flight.orbitSpeed,156*(1-exp(-3.0/60)),0.06,
      "source 298 first-step velocity")
assert(flight.thrusting)
close(flight.sideThrust,0,0.0001,"first-step left/right thrust")
assert(flight.orbitTime>0)
close(length(flight.orbitCamera),400,0.04,"camera after geodesic step")
close(length(flight.orbitPosition),
      (home.surface(flight.orbitPosition) ?? 0)+12,0.04,
      "home radial terrain clearance after geodesic movement")
close(dot(normal(flight.orbitPosition),flight.orbitForward),
      0,0.04,"flight forward remains tangent")
close(dot(normal(flight.orbitPosition),flight.orbitVelocity),
      0,0.04,"transported flight velocity remains tangent")
close(flight.dockDistance,length(flight.orbitPosition-dock),0.02,
      "dock distance uses live source point")

let prior=flight.orbitSpeed
try flight.step(.init(),dt:1.0/60.0)
assert(flight.orbitSpeed<prior,
       "original unpowered DirectMotion298 must coast rather than accelerate")
assert(!flight.thrusting)
assert(flight.entryMission>=0 && flight.entryMission<=26)
assert(PC602HomeFlight291.unlocked(1,mask:0))
assert(!PC602HomeFlight291.unlocked(2,mask:0))
assert(!PC602HomeFlight291.unlocked(27,mask:0))
assert(!PC602HomeFlight291.unlocked(26,mask:1<<22))
assert(PC602HomeFlight291.unlocked(26,mask:1<<23),
       "source mission 26 is unlocked by finished sector 24")
assert(!flight.select(2),"locked mission must not be selectable")
flight.applyCompletedMask(1)
assert(flight.target==2,"PC602 return from mission auto-advances to first unfinished sector")
assert(flight.select(2),"completed mission 1 unlocks sector 2")
assert(flight.target==2)
flight.cycleTarget()
assert(flight.target==1,"source target cycle goes to replayable mission 1")
assert(PC602HomeFlight291.Equipment(craft:.vanguard,engineLevel:-1)==nil)

// The PC C# code normalizes the vector (1,1) to unit length for
// translation, but explicitly preserves sqrt(2) for exhaust-power output.
var diagonal=try PC602HomeFlight291(
    home:home,equipment:equipment(.vanguard))
try diagonal.step(.init(move:Vec2(x:1,y:1)),dt:1/60)
let diagonalPower=(0.48+0.52*sqrt(Float(2))) * (1-exp(-Float(7)/60))
close(diagonal.flight.flight.visualPower,diagonalPower,0.0001,
      "source diagonal thrust magnitude")
close(diagonal.orbitSpeed,156*(1-exp(-3.0/60)),0.06,
      "source diagonal vector remains normalized for movement")

// PAD AIM latching; source AimX/Y priority cannot be overwritten by motion
// while the right stick is released. Real C# retains the chosen heading.
var aimed=try PC602HomeFlight291(home:home,equipment:equipment(.vanguard))
try aimed.step(.init(move:Vec2(x:0,y:0),
                     aim:Vec2(x:1,y:0),padAimActive:true),
               dt:1/60)
let lockedHeading=aimed.flight.heading
try aimed.step(.init(move:Vec2(x:0,y:-1)),dt:1/60)
close(FlightDynamics556.wrapAngle(aimed.flight.heading-lockedHeading),
      0,0.005,"released right stick holds heading")
try aimed.step(.init(move:Vec2(x:0,y:-1),
                     keyboardMovement:true),
               dt:1/60)
assert(abs(FlightDynamics556.wrapAngle(
    aimed.flight.heading-lockedHeading))>0.1,
    "actual keyboard movement cancels pad heading lock")

// Original OrbitWorld50.View + GpuIntro41 frustum on native Metal.
// Verified for both 16:9 (PC/iPhone) and 4:3 iPad aspect.
guard let sourceView=PC602HomeWorldView291(
    camera:flight.flight.camera,aspect:16.0/9.0),
    let ipadView=PC602HomeWorldView291(
    camera:flight.flight.camera,aspect:4.0/3.0)
else {fatalError("Source orbital camera must have a valid frustum")}
close(sourceView.projection[0],1.125,0.00001,"PC 16:9 horizontal focal")
close(sourceView.projection[5],2,0.00001,"PC original 53-degree vertical focal")
close(ipadView.projection[0],1.5,0.00001,"iPad 4:3 horizontal focal")
close(ipadView.projection[5],2,0.00001,"iPad retains source vertical FOV")
close(sourceView.projection[10],-1600/1599.6,0.00001,
      "Metal hardware depth conversion")
close(sourceView.projection[14],-640/1599.6,0.00001,
      "PC source near/far clipping")
close(sourceView.view[14],-400,0.2,"OrbitWorld50 camera origin translation")
let frontNormal=normal(sourceView.eye)
guard let frontHeight=home.surface(frontNormal) else {
    fatalError("Actual front terrain unavailable")
}
let front=frontNormal*(frontHeight+4)
assert(PC602HomeWorldView291.visible(
    from:sourceView.eye,to:front,on:home),
    "source-beacon on near side must be geometrically visible")
let behindNormal=frontNormal * (-1.0)
guard let behindHeight=home.surface(behindNormal) else {
    fatalError("Actual back terrain unavailable")
}
let behind=behindNormal*(behindHeight+4)
assert(!PC602HomeWorldView291.visible(
    from:sourceView.eye,to:behind,on:home),
    "back-side beacons cannot bleed through original planet")
assert(PC602HomeWorldView291(camera:flight.flight.camera,aspect:0)==nil)

// PC602 HomeScene291: 26 source world markers, each with one vertical
// segment and exactly 40 separate ring segments, all in source H290 space.
guard let markers=PC602HomeBeacons291.vertices(
    home:home,selected:1,completedMask:0) else {
    fatalError("Original PC602 world beacons missing")
}
assert(markers.count==26*82)
guard let firstBeacon=home.beacon(1),let secondBeacon=home.beacon(2)
else {fatalError("Source PC602 atlas missing levels 1 and 2")}
let first=SIMD3(markers[0].position.x,markers[0].position.y,
                markers[0].position.z)
let firstEnd=SIMD3(markers[1].position.x,markers[1].position.y,
                   markers[1].position.z)
let firstRing=SIMD3(markers[2].position.x,markers[2].position.y,
                    markers[2].position.z)
close(length(firstEnd-firstBeacon),0,0.001,
      "source H290 first beacon vertical line reaches actual marker")
close(length(firstRing-firstBeacon),8,0.002,
      "selected PC602 sector ring radius is 8m")
close(length(firstEnd-first),3.5,0.03,
      "PC602 source ring base H290 +0.5 to beacon H290+4")
close(markers[0].tint.x,82.0/255,0.00001,
      "unlocked source cyan R")
close(markers[0].tint.y,217.0/255,0.00001,
      "unlocked source cyan G")
close(markers[0].tint.w,1,0.00001,"selected beacon alpha")
let secondOffset=PC602HomeBeacons291.verticesPerLevel
let secondRing=SIMD3(markers[secondOffset+2].position.x,
                     markers[secondOffset+2].position.y,
                     markers[secondOffset+2].position.z)
close(length(secondRing-secondBeacon),3.4,0.002,
      "inactive PC602 sector ring radius is 3.4m")
close(markers[secondOffset].tint.x,110.0/255,0.00001,
      "locked source dim gray R")
close(markers[secondOffset].tint.w,0.66,0.00001,
      "nonselected beacon alpha")
guard let progressed=PC602HomeBeacons291.vertices(
    home:home,selected:2,completedMask:1)
else {fatalError("Original completed beacon colors not generated")}
close(progressed[0].tint.x,95.0/255,0.00001,
      "completed source green R")
close(progressed[secondOffset].tint.x,82.0/255,0.00001,
      "source unlocked next mission cyan")
close(progressed[secondOffset].tint.w,1,0.00001,
      "source selected next mission alpha")
assert(PC602HomeBeacons291.vertices(
    home:home,selected:0,completedMask:0)==nil)
assert(PC602HomeBeacons291.vertices(
    home:home,selected:27,completedMask:0)==nil)
assert(markers.allSatisfy { v in
    v.position.x.isFinite && v.position.y.isFinite &&
    v.position.z.isFinite && v.tint.x.isFinite && v.tint.w.isFinite
})
print("PASS PC602 HomeFlight291: 6 source craft, physical movement, camera/frustum, exact terrain occlusion, drift, aim latch, dock distance and 26 mission unlocks")
