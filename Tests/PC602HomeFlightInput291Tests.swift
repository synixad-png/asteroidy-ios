import Foundation

func same(_ actual:Float,_ expected:Float,_ tolerance:Float=0.0001) {
    assert(actual.isFinite && abs(actual-expected)<=tolerance,
           "Controls misrouted: \(actual) expected \(expected)")
}
var profile=SourceControls586.Profile()
let original=profile
let neutral=PC602HomeFlightInput291.read(
    snapshot:.init(),profile:profile)
same(neutral.move.x,0)
same(neutral.move.y,0)
same(neutral.aim.x,0)
assert(!neutral.keyboardMovement && !neutral.padAimActive)

let arrow=PC602HomeFlightInput291.read(
    snapshot:.init(keys:[87]),profile:profile)
same(arrow.move.x,0)
same(arrow.move.y,-1)
assert(arrow.keyboardMovement)
assert(!arrow.padAimActive)

let externalKeyboard=PC602HomeFlightInput291.read(
    snapshot:.init(keys:[38]),profile:profile)
same(externalKeyboard.move.y,-1,
     "Fallback keyboard arrows preserve source vertical motion")
assert(externalKeyboard.keyboardMovement)

let keyboardAim=PC602HomeFlightInput291.read(
    snapshot:.init(keys:[76]),profile:profile)
same(keyboardAim.aim.x,1)
assert(!keyboardAim.padAimActive)

let pad=PC602HomeFlightInput291.read(
    snapshot:.init(axes:[0,0,0.4,0.6,0,0]),profile:profile)
assert(pad.padAimActive)
same(pad.aim.x,0.4)
same(pad.aim.y,0.6)
assert(!pad.keyboardMovement)

let underDeadzone=PC602HomeFlightInput291.read(
    snapshot:.init(axes:[0,0,0.08,0.08,0,0]),profile:profile)
assert(!underDeadzone.padAimActive)
same(underDeadzone.aim.x,0)
same(underDeadzone.aim.y,0)

// The ORIGINAL 60-action source profile is writable by settings; the
// orbital handler MUST read changed bindings rather than default key IDs.
profile.keys[2]=84
let rebound=PC602HomeFlightInput291.read(
    snapshot:.init(keys:[84]),profile:profile)
same(rebound.move.y,-1)
assert(rebound.keyboardMovement)
let oldKey=PC602HomeFlightInput291.read(
    snapshot:.init(keys:[87]),profile:profile)
same(oldKey.move.y,0)

profile.pad[33]="A0+"
profile.pad[34]="A1+"
let remappedStick=PC602HomeFlightInput291.read(
    snapshot:.init(axes:[0.42,0.63,0,0,0,0]),profile:profile)
same(remappedStick.aim.x,0.42)
same(remappedStick.aim.y,0.63)
assert(remappedStick.padAimActive)

let fromTouch=PC602HomeFlightInput291.read(
    snapshot:.init(axes:[0,0,0.55,0.35,0,0]),profile:original,
    touchMove:Vec2(x:0.25,y:-0.75),
    touchAim:Vec2(x:-0.4,y:0.8))
same(fromTouch.move.x,0.25)
same(fromTouch.move.y,-0.75)
same(fromTouch.aim.x,-0.4)
same(fromTouch.aim.y,0.8)
assert(!fromTouch.padAimActive,
       "Explicit touch aim takes priority over latched physical right stick")
assert(!fromTouch.keyboardMovement)

let keyboardWinsLatch=PC602HomeFlightInput291.read(
    snapshot:.init(keys:[84,76],axes:[0,0,0.55,0.35,0,0]),
    profile:profile)
assert(keyboardWinsLatch.keyboardMovement)
assert(!keyboardWinsLatch.padAimActive)
assert(profile.keys[2]==84 && profile.pad[33]=="A0+")
assert(original.keys[2]==87 && original.pad[33]=="A2+")
print("PASS PC602 orbit flight uses original PC586 active remapped keyboard " +
      "and pad bindings, deadzone, pad-heading latch, touch fallback " +
      "without mutating campaign, W3, H55 or CARBONIS")
