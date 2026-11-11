import Foundation

func close(_ a:Float,_ b:Float,_ tol:Float,_ label:String) {
    guard a.isFinite,abs(a-b)<=tol else {
        fatalError("\(label): got \(a), original PC602 expected \(b)")
    }
}
func length(_ x:SIMD3<Float>)->Float {
    sqrt(x.x*x.x+x.y*x.y+x.z*x.z)
}
func dot(_ x:SIMD3<Float>,_ y:SIMD3<Float>)->Float {
    x.x*y.x+x.y*y.y+x.z*y.z
}
guard CommandLine.arguments.count==2 else {
    fatalError("Usage: original-home-vanguard-source-test PC602Home290HeightMap.bin")
}
let home=try PC602NewHome290(heightMapBytes:Data(
    contentsOf:URL(fileURLWithPath:CommandLine.arguments[1])))
let equipment=PC602HomeFlight291.Equipment(craft:.vanguard)!
var flight=try PC602HomeFlight291(home:home,equipment:equipment)
guard let pose=PC602HomeShipPose291.vanguard(flight) else {
    fatalError("Original source Vanguard431 must have an orbit pose")
}
assert(pose.basis.count==16)
close(PC602HomeShipPose291.sourceContactRadius,11.2,0.00001,
      "Game.ShipContactRadius")
close(PC602HomeShipPose291.sourceHomeWorldOuterRadius,144.19674,0.00001,
      "GpuPlanetGltf463.HomeWorldOuterRadius523")
close(PC602HomeShipPose291.originalWorldScale,
      (144.19674+15)/(720/Float.pi),0.000001,
      "GpuSphere67.WorldUnitScale")
close(PC602HomeShipPose291.sourceShipScale,6.826792,0.00001,
      "PC602 contact / sphere / orbit factor .65*1.35")
close(pose.basis[12],flight.orbitPosition.x,0.0002,"world position X")
close(pose.basis[13],flight.orbitPosition.y,0.0002,"world position Y")
close(pose.basis[14],flight.orbitPosition.z,0.0002,"world position Z")
let right=SIMD3(pose.basis[0],pose.basis[1],pose.basis[2])
let heading=SIMD3(pose.basis[4],pose.basis[5],pose.basis[6])
let normal=SIMD3(pose.basis[8],pose.basis[9],pose.basis[10])
for axis in [right,heading,normal] {
    close(length(axis),PC602HomeShipPose291.sourceShipScale,
          0.00003,"orthogonal original hull basis scale")
}
close(dot(right,heading),0,0.0001,"wings and nose perpendicular")
close(dot(right,normal),0,0.0001,"wings and dorsal perpendicular")
close(dot(heading,normal),0,0.0001,"nose and dorsal perpendicular")
close(pose.basis[15],1,0.000001,"homogeneous 4x4 matrix")
close(pose.bankDegrees,0,0.000001,"source initial bank")
close(pose.pitchDegrees,0,0.000001,"source initial pitch")
close(PC602HomeShipPose291.vanguard(flight,orbitScale:1.3)!.basis[0],
      pose.basis[0]*1.3,0.00002,"visual orbit scale affects ship basis")
close(PC602HomeShipPose291.vanguard(flight,orbitScale:1.3)!.basis[12],
      pose.basis[12],0.00002,"visual size must never move physics")
assert(PC602HomeShipPose291.vanguard(flight,orbitScale:0)==nil)
assert(PC602HomeShipPose291.vanguard(
    flight,orbitScale:Float.infinity)==nil)
for other in PC602HomeFlight291.Craft.allCases where other != .vanguard {
    let state=try PC602HomeFlight291(home:home,
        equipment:PC602HomeFlight291.Equipment(craft:other)!)
    assert(PC602HomeShipPose291.vanguard(state)==nil,
           "No substitute Vanguard model permitted for \(other)")
}

try flight.step(.init(move:Vec2(x:1,y:0),
                      aim:Vec2(x:0,y:1)),dt:1/60)
guard let moving=PC602HomeShipPose291.vanguard(flight) else {
    fatalError("Vanguard world pose must track live 67 movement")
}
close(moving.bankDegrees,flight.flight.flight.visualBank,
      0.000001,"source banking comes from DirectAttitude298")
close(moving.pitchDegrees,flight.flight.flight.visualPitch,
      0.000001,"source pitch comes from DirectAttitude298")
close(moving.basis[12],flight.orbitPosition.x,0.0002,
      "new flight position X")
close(moving.basis[13],flight.orbitPosition.y,0.0002,
      "new flight position Y")
close(moving.basis[14],flight.orbitPosition.z,0.0002,
      "new flight position Z")
let face=SIMD3(moving.basis[4],moving.basis[5],moving.basis[6])
let expected=Sphere67.vector(flight.flight.position,
    Vec2(x:cos(flight.flight.flight.visualHeading),
         y:sin(flight.flight.flight.visualHeading))).normalized
let expectedWorld=SIMD3(expected.x,expected.y,expected.z) *
    PC602HomeShipPose291.sourceShipScale
close(length(face-expectedWorld),0,0.0002,
    "source fighter direction tracks visual heading rather than raw aim")
print("PASS PC602 original Vanguard431 source orbital pose: original " +
      "11.2m contact radius, 144.19674 shell, Sphere67 tangent basis, " +
      "6.826792 scale, 12m physical altitude, visual bank/pitch, " +
      "live DirectFlight and no false 5-craft substitutions")
