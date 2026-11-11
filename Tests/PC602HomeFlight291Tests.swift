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
try flight.step(.init(move:Vec2(x:0,y:-1),
                      aim:Vec2(x:0,y:0)),
                dt:1.0/60.0,dockPosition:dock)
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
try flight.step(.init(),dt:1.0/60.0,dockPosition:dock)
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
assert(flight.select(2),"completed mission 1 unlocks sector 2")
assert(flight.target==2)
flight.cycleTarget()
assert(flight.target==1,"source target cycle goes to replayable mission 1")
assert(PC602HomeFlight291.Equipment(craft:.vanguard,engineLevel:-1)==nil)

// PAD AIM latching; source AimX/Y priority cannot be overwritten by motion
// while the right stick is released. Real C# retains the chosen heading.
var aimed=try PC602HomeFlight291(home:home,equipment:equipment(.vanguard))
try aimed.step(.init(move:Vec2(x:0,y:0),
                     aim:Vec2(x:1,y:0),padAimActive:true),
               dt:1/60,dockPosition:dock)
let lockedHeading=aimed.flight.heading
try aimed.step(.init(move:Vec2(x:0,y:-1)),dt:1/60,dockPosition:dock)
close(FlightDynamics556.wrapAngle(aimed.flight.heading-lockedHeading),
      0,0.005,"released right stick holds heading")
try aimed.step(.init(move:Vec2(x:0,y:-1),
                     keyboardMovement:true),
               dt:1/60,dockPosition:dock)
assert(abs(FlightDynamics556.wrapAngle(
    aimed.flight.heading-lockedHeading))>0.1,
    "actual keyboard movement cancels pad heading lock")

print("PASS PC602 HomeFlight291: 6 source craft, upgrades, 400m camera, surface height, geodesic flight, drift, aim latch, dock distance and 26 mission unlocks")
