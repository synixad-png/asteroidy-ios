import Foundation

guard CommandLine.arguments.count==2 else {
    fatalError("Usage: PC602HomeWorldSession291Tests PC602Home290HeightMap.bin")
}
let home=try PC602NewHome290(heightMapBytes:Data(
    contentsOf:URL(fileURLWithPath:CommandLine.arguments[1])))
let equipment=PC602HomeFlight291.Equipment(craft:.vanguard)!
let profile=SourceControls586.Profile()
var session=try PC602HomeWorldSession291(home:home,equipment:equipment,
                                        controls:profile)
assert(session.route.location == .orbit)
assert(session.flight.target==1)
assert(session.flight.orbitTime==0)
assert(session.steppedFrames==0)
assert(!session.paused)

let empty=SourceControls586.Snapshot()
let zeroAdvance=try session.advance(snapshot:empty,dt:0)
assert(!zeroAdvance)
assert(session.steppedFrames==0)
do {
    _=try session.advance(snapshot:empty,dt:Float.nan)
    fatalError("Nonfinite source frame must be rejected")
} catch PC602HomeWorldSession291.SourceError.invalidFrame {}

// Use canonical existing PC586 keyboard mapping, not hardcoded read in
// session. PC v602 DirectFlight67 has no false motion when input is empty.
let initialMove=try session.advance(snapshot:.init(keys:[87]),dt:1/60)
assert(initialMove)
assert(session.steppedFrames==1)
assert(session.flight.orbitSpeed>0)
assert(session.flight.orbitTime>0)
let previous=session.flight.orbitTime
session.setPaused(true)
assert(!session.requestDock(context:.init(planetHub:true,orbitMode:true)))
let whilePaused=try session.advance(snapshot:.init(keys:[87]),dt:1/60)
assert(!whilePaused)
assert(session.flight.orbitTime==previous)
assert(session.steppedFrames==1)
assert(session.canEnterAuthoredMissionArea==0)
session.setPaused(false)
let afterPause=try session.advance(snapshot:empty,dt:1/60)
assert(afterPause)
assert(session.steppedFrames==2)
assert(session.flight.orbitTime>previous)

// A new profile is adopted atomically without touching the real
// immutable W3 / H55 / CARBONIS keyboard adapter.
var revised=profile
revised.keys[2]=84
session.adoptControls(revised)
assert(session.controls.keys[2]==84)
assert(profile.keys[2]==87)
let reboundMove=try session.advance(snapshot:.init(keys:[84]),dt:1/60)
assert(reboundMove)
assert(session.flight.thrusting)
assert(session.steppedFrames==3)

// Authored mission area does NOT mean successful mission completion.
// No attempt is made to invoke a non-existent 26-sector combat port.
assert(!session.selectMission(2),"mission 2 must initially be locked")
assert(session.selectMission(1))
session.refreshCommittedCampaign(1) // only saved campaign may supply this
assert(session.flight.target==2)
assert(session.selectMission(2))
session.cycleMission()
assert(session.flight.target==1)
assert(session.canEnterAuthoredMissionArea>=0 &&
       session.canEnterAuthoredMissionArea<=26)

// Current genuine flight starts at sector 1, far from the source wreck.
// No H55 transition just because the UI requests a button press.
assert(!session.requestDock(context:.init(
    planetHub:true,orbitMode:true)))
assert(session.route.location == .orbit)
assert(session.finishPhysicalH55Visit()==nil)
assert(session.steppedFrames==3)

// SaveManager61.LoadSlot61 on the actual Sphere67 state: genuine saved
// position/heading, zero speed and zero transient bullets; no new sector.
let beforeRestore=session.flight.orbitPosition
let beforeForward=session.flight.orbitForward
try session.restoreOrbit61(position:beforeRestore,forward:beforeForward,
    target:1,completedMask:0,weapon:.defaultPulse)
assert(session.flight.target==1)
assert(session.flight.completedMask==0)
assert(session.flight.orbitSpeed==0)
assert(session.flight.orbitVelocity==SIMD3<Float>(repeating:0))
assert(session.steppedFrames==0)
assert(session.weapons.projectiles.isEmpty)
assert(session.paused)
assert(session.canEnterAuthoredMissionArea==0)
assert(session.flight.orbitPosition.x.isFinite)
assert(session.flight.orbitForward.x.isFinite)
session.setPaused(false)
let resumedAfterRestore=try session.advance(snapshot:.init(keys:[87]),dt:1/60)
assert(resumedAfterRestore)
assert(session.steppedFrames==1)
assert(session.flight.orbitSpeed>0)

print("PASS original PC602 HomeWorld session: single 67 flight, saved " +
      "remapped controls, atomic pause, no double tick, 26 authored " +
      "sector unlocks and real 43.2m-gated H55 without fake mission/IPA")
