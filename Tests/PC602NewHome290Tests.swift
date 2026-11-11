import Foundation

// Independent PC602 numeric reference (read from the SHA-verified original
// home290.mesh.gz; C# NewHome290.HeightAt / OrbitWorld50.Beacon).
// Tolerances allow only ordinary Float32 vs double intermediate rounding.
func close(_ actual:Float?,_ expected:Float,_ tolerance:Float=0.004,
           _ name:String) {
    guard let value=actual,value.isFinite,abs(value-expected)<tolerance else {
        fatalError("\(name): \(String(describing:actual)) != \(expected)")
    }
}
func closeVector(_ actual:SIMD3<Float>?,_ expected:SIMD3<Float>,
                 _ name:String) {
    guard let value=actual else {fatalError(name+": missing original point")}
    for axis in 0..<3 {
        close(value[axis],expected[axis],0.025,name+" axis \(axis)")
    }
}

guard CommandLine.arguments.count==2 else {
    fatalError("Usage: testPC602NewHome290 <original-heightmap.bin>")
}
let bytes=try Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[1]))
let home=try PC602NewHome290(heightMapBytes:bytes)
close(home.surface(SIMD3<Float>(1,0,0)),135.4348093,0.004,"+X")
close(home.surface(SIMD3<Float>(0,1,0)),131.4668059,0.004,"+Y")
close(home.surface(SIMD3<Float>(-1,0,0)),132.3887348,0.004,"-X")
close(home.surface(SIMD3<Float>(0,-1,0)),131.6562175,0.004,"-Y")
close(home.surface(SIMD3<Float>(0,0,1)),130.5574745,0.004,"+Z")
close(home.surface(SIMD3<Float>(0,0,-1)),133.6559504,0.004,"-Z")
close(home.surface(SIMD3<Float>(0.4,0.5,-0.3)),134.8728895,
      0.004,"off-axis")

closeVector(home.beacon(1),SIMD3<Float>(130.1234480,0,53.8988969),"sector 01")
closeVector(home.beacon(9),SIMD3<Float>(96.1808765,93.1147278,39.8394235),"sector 09")
closeVector(home.beacon(17),SIMD3<Float>(94.8713709,-91.8469679,39.2970085),"sector 17")
closeVector(home.beacon(25),SIMD3<Float>(52.8862140,125.2568227,30.6183344),"sector 25")
closeVector(home.beacon(26),SIMD3<Float>(-65.2274773,118.2248026,-27.1781155),"sector 26")
closeVector(home.wreckPosition(),SIMD3<Float>(65.4419845,9.4645955,134.6732037),"source wreck")
assert(home.beacon(0)==nil && home.beacon(27)==nil)
assert(home.surface(SIMD3<Float>(0,0,0))==nil)
assert(!home.isInMissionArea(SIMD3<Float>(0,0,0),level:1))
if let beacon=home.beacon(1) {
    assert(home.isInMissionArea(beacon,level:1))
}
if let safe=home.safePosition(SIMD3<Float>(120,0,0)),
   let surface=home.surface(safe) {
    close(sqrt(safe.x*safe.x+safe.y*safe.y+safe.z*safe.z),
          surface+8,0.004,"original ground clearance")
} else {fatalError("safe home position missing")}
closeVector(home.spawnPosition(SIMD3<Float>(1,0,0)),
            SIMD3<Float>(150,0,0),"minimum source spawn radius")
do {
    _=try PC602NewHome290(heightMapBytes:Data(repeating:0,count:12))
    fatalError("Truncated source should be rejected")
} catch PC602NewHome290.SourceError.invalidLength {
    // expected
}
print("PASS PC602 original H290 physical surface, 26 atlas beacons, wreck/dock, spawn and collision bounds")
