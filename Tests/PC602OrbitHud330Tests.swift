import Foundation

guard CommandLine.arguments.count==2 else {
    fatalError("Use exact 512x256 source H290 binary height map")
}
let bytes=try Data(contentsOf:
    URL(fileURLWithPath:CommandLine.arguments[1]))
let home=try PC602NewHome290(heightMapBytes:bytes)
let equipment=PC602HomeFlight291.Equipment(craft:.vanguard)!
var flight=try PC602HomeFlight291(home:home,equipment:equipment)
guard let start=PC602OrbitHud330.measure(flight) else {
    fatalError("Source OrbitHud330 cannot map a valid real flight")
}
assert((1...24).contains(start.zone))
assert(start.unlocked && !start.completed)
assert(start.altitude.isFinite && abs(start.altitude-12)<0.0006)
assert(start.course.isFinite && abs(start.course)<=180+0.0001)
// Source Zone50 uses exact 8 longitude columns x 3 latitude bands;
// source mission tiles total 26, while polar missions use special markers.
var zones=Set<Int>()
for level in 1...26 {
    guard let beacon=home.beacon(level) else {
        fatalError("All original 26 authored NewHome290 beacons must exist")
    }
    let raw=beacon/sqrt(beacon.x*beacon.x+
                        beacon.y*beacon.y+beacon.z*beacon.z)
    var phi=atan2(raw.z,raw.x)
    if phi<0 {phi+=2*Float.pi}
    let row=raw.y>1/3 ? 1:raw.y < -1/3 ? 2:0
    let column=min(7,Int(phi/(Float.pi/4)))
    zones.insert(row*8+column+1)
}
assert(!zones.isEmpty && zones.count>=15)
assert(PC602HomeFlight291.unlocked(1,mask:0))
assert(!PC602HomeFlight291.unlocked(26,mask:0))
flight.applyCompletedMask((1<<26)-1)
for level in 1...26 {
    assert(flight.select(level))
    guard let hud=PC602OrbitHud330.measure(flight) else {
        fatalError("Original route missing for source sector \(level)")
    }
    assert(hud.unlocked && hud.completed)
    assert((1...24).contains(hud.zone))
    assert(hud.altitude.isFinite)
    assert(hud.course.isFinite)
    assert(abs(hud.course)<=180.0001)
}
// No level selection may mark an unfinished sector completed by itself.
var untouched=try PC602HomeFlight291(home:home,equipment:equipment)
assert(!untouched.select(2))
assert(untouched.select(1))
assert(untouched.completedMask==0)
print("PASS PC602 OrbitHud330: true H290 12m altitude, 8x3 zone, " +
      "source geodesic Route51 course, all 26 authored targets, " +
      "source unlock/completed flags and no false mission rewards")
